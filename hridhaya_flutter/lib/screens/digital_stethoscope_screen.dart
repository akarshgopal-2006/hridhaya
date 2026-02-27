import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../widgets/chest_placement_graphic.dart';
import '../widgets/waveform_visualizer.dart';

class DigitalStethoscopeScreen extends StatefulWidget {
  const DigitalStethoscopeScreen({super.key});

  @override
  State<DigitalStethoscopeScreen> createState() => _DigitalStethoscopeScreenState();
}

class _DigitalStethoscopeScreenState extends State<DigitalStethoscopeScreen> {
  static const _total = Duration(seconds: 15);

  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _timer;

  bool _recording = false;
  Duration _remaining = _total;
  double _intensity = 0.12;
  double _phase = 0;
  double _smooth = 0;

  void _start() {
    if (_recording) return;
    setState(() {
      _recording = true;
      _remaining = _total;
    });

    _gyroSub?.cancel();
    _gyroSub = gyroscopeEventStream().listen((e) {
      final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      // Convert magnitude to a 0..1-ish intensity (heuristic).
      final normalized = (mag / (1 + mag)).clamp(0.0, 1.0);
      _smooth = (_smooth * 0.80) + (normalized * 0.20);
    });

    _timer?.cancel();
    final startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      final elapsed = DateTime.now().difference(startedAt);
      final left = _total - elapsed;
      if (!mounted) return;

      setState(() {
        _remaining = left.isNegative ? Duration.zero : left;
        _phase = (_phase + 0.035) % 1.0;
        // If gyro is quiet / unavailable, add subtle synthetic motion.
        final synth = 0.08 + 0.14 * (math.sin(_phase * math.pi * 2) + 1) / 2;
        _intensity = (_smooth > 0 ? _smooth : synth).clamp(0.0, 1.0);
      });

      if (_remaining == Duration.zero) {
        _stop();
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _gyroSub?.cancel();
    _gyroSub = null;
    if (mounted) setState(() => _recording = false);
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final secondsLeft = (_remaining.inMilliseconds / 1000).ceil().clamp(0, 15);
    final progress = 1 - (_remaining.inMilliseconds / _total.inMilliseconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Stethoscope'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            const ChestPlacementGraphic(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.graphic_eq_rounded, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _recording
                              ? 'Listening...'
                              : 'Ready to capture heart mechanics',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  WaveformVisualizer(
                    intensity: _intensity,
                    phase: _phase,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _recording
                        ? 'Analyzing Heart Mechanics... ${secondsLeft}s remaining.'
                        : 'Tap “Start” and keep the phone still for 15 seconds.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _recording ? progress.clamp(0, 1) : 0,
                    minHeight: 10,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _recording ? _stop : _start,
                      icon: Icon(_recording ? Icons.stop_rounded : Icons.play_arrow_rounded),
                      label: Text(_recording ? 'Stop' : 'Start'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

