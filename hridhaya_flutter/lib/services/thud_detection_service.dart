import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

class ThudEvent {
  final DateTime at;
  final double magnitude;
  final double jerk;

  const ThudEvent({
    required this.at,
    required this.magnitude,
    required this.jerk,
  });
}

class ThudDetectionService {
  final Duration cooldown;
  final double magnitudeThreshold;
  final double jerkThreshold;

  StreamSubscription<AccelerometerEvent>? _sub;
  final _controller = StreamController<ThudEvent>.broadcast();

  DateTime? _lastThudAt;
  double? _lastMagnitude;

  ThudDetectionService({
    this.cooldown = const Duration(seconds: 8),
    this.magnitudeThreshold = 22.0,
    this.jerkThreshold = 10.0,
  });

  Stream<ThudEvent> get events => _controller.stream;

  void start() {
    _sub ??= accelerometerEventStream().listen((e) {
      final magnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      final lastMag = _lastMagnitude;
      _lastMagnitude = magnitude;

      if (lastMag == null) return;

      final jerk = (magnitude - lastMag).abs();
      final now = DateTime.now();

      final lastThudAt = _lastThudAt;
      final inCooldown =
          lastThudAt != null && now.difference(lastThudAt) < cooldown;

      if (inCooldown) return;

      if (magnitude >= magnitudeThreshold && jerk >= jerkThreshold) {
        _lastThudAt = now;
        _controller.add(ThudEvent(at: now, magnitude: magnitude, jerk: jerk));
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _lastMagnitude = null;
  }

  void simulateThud() {
    final now = DateTime.now();
    _lastThudAt = now;
    _controller.add(ThudEvent(at: now, magnitude: 30, jerk: 18));
  }

  Future<void> dispose() async {
    stop();
    await _controller.close();
  }
}

