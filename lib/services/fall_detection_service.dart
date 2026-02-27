import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

// ─── Fall Event Model ────────────────────────────────────────

enum FallPhase {
  freeFall,   // ~0g — phone/person in free-fall
  impact,     // spike — hitting the ground
  stillness,  // no movement — person might be unconscious
}

class FallEvent {
  final DateTime at;
  final double impactMagnitude;
  final double freeFallDurationMs;
  final double stillnessDurationMs;
  final double peakJerk;
  final List<FallPhase> phasesDetected;

  const FallEvent({
    required this.at,
    required this.impactMagnitude,
    required this.freeFallDurationMs,
    required this.stillnessDurationMs,
    required this.peakJerk,
    required this.phasesDetected,
  });

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'impactMagnitude': impactMagnitude,
        'freeFallDurationMs': freeFallDurationMs,
        'stillnessDurationMs': stillnessDurationMs,
        'peakJerk': peakJerk,
        'phasesDetected': phasesDetected.map((p) => p.name).toList(),
      };

  @override
  String toString() =>
      'FallEvent(impact=${impactMagnitude.toStringAsFixed(1)}g, '
      'freefall=${freeFallDurationMs.toStringAsFixed(0)}ms, '
      'stillness=${stillnessDurationMs.toStringAsFixed(0)}ms)';
}

// ─── Fall Detection Service ──────────────────────────────────
//
// A cardiac fall typically has 3 phases:
//   1. FREE-FALL  — person collapses, phone experiences near-zero gravity (~0g)
//   2. IMPACT     — person hits the ground, high g-force spike
//   3. STILLNESS  — person is unconscious/unresponsive, very little movement
//
// This service monitors the accelerometer and detects this pattern.

class FallDetectionService {
  // ─── Tunable thresholds ───
  final double freeFallThreshold;   // g below which we consider free-fall (default ~2 m/s²)
  final double impactThreshold;     // g-force above which we consider impact (default ~25 m/s²)
  final double jerkThreshold;       // rate of change threshold
  final double stillnessThreshold;  // maximum magnitude for "not moving" (~10 m/s² ≈ gravity only)
  final Duration stillnessWindow;   // how long stillness must persist after impact
  final Duration cooldown;          // minimum time between events

  StreamSubscription<AccelerometerEvent>? _sub;
  final _controller = StreamController<FallEvent>.broadcast();

  // ─── Internal state ───
  DateTime? _lastEventAt;
  final List<_SensorSnapshot> _buffer = [];
  static const int _bufferSize = 200; // ~2 seconds at 100Hz

  // Phase tracking
  bool _inFreeFall = false;
  DateTime? _freeFallStart;
  DateTime? _impactAt;
  double _impactMag = 0;
  double _peakJerk = 0;
  double? _lastMag;

  FallDetectionService({
    this.freeFallThreshold = 2.5,
    this.impactThreshold = 22.0,
    this.jerkThreshold = 10.0,
    this.stillnessThreshold = 11.0,
    this.stillnessWindow = const Duration(milliseconds: 2000),
    this.cooldown = const Duration(seconds: 10),
  });

  Stream<FallEvent> get events => _controller.stream;

  void start() {
    _sub ??= accelerometerEventStream().listen(_onAccelerometerData);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _resetState();
  }

  void _resetState() {
    _inFreeFall = false;
    _freeFallStart = null;
    _impactAt = null;
    _impactMag = 0;
    _peakJerk = 0;
    _lastMag = null;
    _buffer.clear();
  }

  void _onAccelerometerData(AccelerometerEvent e) {
    final now = DateTime.now();
    final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

    // Calculate jerk (rate of change)
    final jerk = _lastMag != null ? (mag - _lastMag!).abs() : 0.0;
    _lastMag = mag;

    // Add to circular buffer
    _buffer.add(_SensorSnapshot(time: now, magnitude: mag, jerk: jerk));
    if (_buffer.length > _bufferSize) {
      _buffer.removeAt(0);
    }

    // ─── Check cooldown ───
    if (_lastEventAt != null && now.difference(_lastEventAt!) < cooldown) {
      return;
    }

    // ─── Phase 1: Detect FREE-FALL ───
    // During a fall, the phone is in free-fall for ~200-500ms
    // Gravity "disappears" — magnitude drops to near 0
    if (!_inFreeFall && mag < freeFallThreshold) {
      _inFreeFall = true;
      _freeFallStart = now;
      return;
    }

    // ─── Phase 2: Detect IMPACT ───
    // Right after free-fall, there's a sharp spike in acceleration
    if (_inFreeFall && mag >= impactThreshold && jerk >= jerkThreshold) {
      _impactAt = now;
      _impactMag = mag;
      _peakJerk = jerk;
      _inFreeFall = false;

      // Schedule a check for Phase 3 (stillness)
      Future<void>.delayed(stillnessWindow, () {
        _checkStillness(now);
      });
      return;
    }

    // If free-fall has lasted too long (>800ms), it's probably not a real fall
    if (_inFreeFall && _freeFallStart != null) {
      final freeFallDuration = now.difference(_freeFallStart!);
      if (freeFallDuration > const Duration(milliseconds: 800)) {
        _inFreeFall = false;
        _freeFallStart = null;
      }
    }
  }

  void _checkStillness(DateTime impactTime) {
    if (_impactAt == null) return;

    // Look at the last `stillnessWindow` of data in the buffer
    final now = DateTime.now();
    final cutoff = now.subtract(stillnessWindow);
    final recentSamples = _buffer.where((s) => s.time.isAfter(cutoff)).toList();

    if (recentSamples.isEmpty) {
      // No data — fire anyway since we had free-fall + impact
      _fireEvent(includeStillness: false);
      return;
    }

    // Check if the recent samples are relatively still (close to gravity only)
    final avgMag = recentSamples.map((s) => s.magnitude).reduce((a, b) => a + b) /
        recentSamples.length;
    final maxJerkRecent = recentSamples.map((s) => s.jerk).reduce(math.max);

    // Person is "still" if average magnitude is near gravity (9.8) and jerk is low
    final isStill = avgMag < stillnessThreshold && maxJerkRecent < 3.0;

    _fireEvent(includeStillness: isStill);
  }

  void _fireEvent({required bool includeStillness}) {
    final now = DateTime.now();
    final phases = <FallPhase>[FallPhase.freeFall, FallPhase.impact];
    if (includeStillness) phases.add(FallPhase.stillness);

    final freeFallMs = _freeFallStart != null && _impactAt != null
        ? _impactAt!.difference(_freeFallStart!).inMilliseconds.toDouble()
        : 0.0;

    final stillnessMs = includeStillness ? stillnessWindow.inMilliseconds.toDouble() : 0.0;

    final event = FallEvent(
      at: now,
      impactMagnitude: _impactMag,
      freeFallDurationMs: freeFallMs,
      stillnessDurationMs: stillnessMs,
      peakJerk: _peakJerk,
      phasesDetected: phases,
    );

    _lastEventAt = now;
    _controller.add(event);

    // Reset for next detection
    _impactAt = null;
    _impactMag = 0;
    _peakJerk = 0;
    _freeFallStart = null;
  }

  /// Simulate a fall event for testing purposes.
  void simulateFall() {
    final now = DateTime.now();
    _lastEventAt = now;
    _controller.add(FallEvent(
      at: now,
      impactMagnitude: 28.5,
      freeFallDurationMs: 320,
      stillnessDurationMs: 2000,
      peakJerk: 15.2,
      phasesDetected: [FallPhase.freeFall, FallPhase.impact, FallPhase.stillness],
    ));
  }

  Future<void> dispose() async {
    stop();
    await _controller.close();
  }
}

// ─── Internal snapshot ───────────────────────────────────────

class _SensorSnapshot {
  final DateTime time;
  final double magnitude;
  final double jerk;

  const _SensorSnapshot({
    required this.time,
    required this.magnitude,
    required this.jerk,
  });
}
