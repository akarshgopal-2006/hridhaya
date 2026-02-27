import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/stethoscope_api_service.dart';
import '../widgets/chest_placement_graphic.dart';
import '../widgets/waveform_visualizer.dart';

class DigitalStethoscopeScreen extends StatefulWidget {
  const DigitalStethoscopeScreen({super.key});

  @override
  State<DigitalStethoscopeScreen> createState() =>
      _DigitalStethoscopeScreenState();
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

  // ─── Collected samples for backend ───
  final List<Map<String, dynamic>> _samples = [];
  DateTime? _recordStart;

  // ─── Analysis results ───
  bool _analyzing = false;
  StethoscopeReport? _report;
  String? _error;

  void _start() {
    if (_recording) return;
    setState(() {
      _recording = true;
      _remaining = _total;
      _report = null;
      _error = null;
      _samples.clear();
    });

    _recordStart = DateTime.now();

    _gyroSub?.cancel();
    _gyroSub = gyroscopeEventStream().listen((e) {
      final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      final normalized = (mag / (1 + mag)).clamp(0.0, 1.0);
      _smooth = (_smooth * 0.80) + (normalized * 0.20);

      // Collect sample for backend
      _samples.add({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'x': e.x,
        'y': e.y,
        'z': e.z,
      });
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
        final synth = 0.08 + 0.14 * (math.sin(_phase * math.pi * 2) + 1) / 2;
        _intensity = (_smooth > 0 ? _smooth : synth).clamp(0.0, 1.0);
      });

      if (_remaining == Duration.zero) {
        _stop(autoComplete: true);
      }
    });
  }

  void _stop({bool autoComplete = false}) {
    _timer?.cancel();
    _timer = null;
    _gyroSub?.cancel();
    _gyroSub = null;
    if (mounted) setState(() => _recording = false);

    if (autoComplete && _samples.isNotEmpty) {
      _analyzeData();
    }
  }

  Future<void> _analyzeData() async {
    setState(() {
      _analyzing = true;
      _error = null;
    });

    final durationMs = _recordStart != null
        ? DateTime.now().difference(_recordStart!).inMilliseconds
        : 15000;

    try {
      final report = await StethoscopeApiService.analyze(
        samples: _samples,
        durationMs: durationMs,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _analyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _analyzing = false;
      });
    }
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

            // ─── Capture Card ───
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
                              : _analyzing
                                  ? 'Analyzing with Hridhaya Engine...'
                                  : 'Ready to capture heart mechanics',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        ? 'Capturing... ${secondsLeft}s remaining  (${_samples.length} samples)'
                        : _analyzing
                            ? 'Sending ${_samples.length} samples to Hridhaya backend...'
                            : 'Tap "Start" and keep the phone still for 15 seconds.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _recording
                        ? progress.clamp(0, 1)
                        : _analyzing
                            ? null
                            : 0,
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
                      onPressed:
                          _analyzing ? null : (_recording ? () => _stop() : _start),
                      icon: Icon(_recording
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded),
                      label: Text(_recording ? 'Stop' : 'Start'),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Error Card ───
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: scheme.errorContainer,
                  border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: scheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analysis failed',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onErrorContainer,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Make sure the backend is running on localhost:5000.\n$_error',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onErrorContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ─── Results Card ───
            if (_report != null) ...[
              const SizedBox(height: 16),
              _ResultsCard(report: _report!),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Results Card Widget ─────────────────────────────────────

class _ResultsCard extends StatelessWidget {
  final StethoscopeReport report;

  const _ResultsCard({required this.report});

  Color _riskColor(String level) {
    switch (level) {
      case 'high':
        return const Color(0xFFD32F2F);
      case 'moderate':
        return const Color(0xFFFF8F00);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  IconData _qualityIcon(String quality) {
    switch (quality) {
      case 'good':
        return Icons.check_circle_rounded;
      case 'fair':
        return Icons.info_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  String _formatRhythm(String regularity) {
    switch (regularity) {
      case 'regular':
        return 'Regular';
      case 'mostly_regular':
        return 'Mostly Regular';
      case 'irregular':
        return 'Irregular';
      case 'insufficient_data':
        return 'Insufficient Data';
      default:
        return regularity;
    }
  }

  String _formatClassification(String c) {
    switch (c) {
      case 'bradycardia':
        return 'Bradycardia (slow)';
      case 'low_normal':
        return 'Low Normal';
      case 'normal':
        return 'Normal';
      case 'elevated':
        return 'Elevated';
      case 'tachycardia':
        return 'Tachycardia (fast)';
      default:
        return c;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final riskColor = _riskColor(report.riskLevel);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            scheme.surface,
            riskColor.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
              Icon(Icons.monitor_heart_rounded, color: riskColor, size: 28),
              const SizedBox(width: 10),
              Text(
                'Analysis Results',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ─── BPM Hero ───
          Center(
            child: Column(
              children: [
                Text(
                  '${report.bpm}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: riskColor,
                        letterSpacing: -3,
                        height: 0.95,
                      ),
                ),
                Text(
                  'BPM',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _formatClassification(report.heartRateClassification),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: riskColor,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ─── Metrics Grid ───
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Rhythm',
                  value: _formatRhythm(report.rhythmRegularity),
                  icon: Icons.timeline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Signal Quality',
                  value: report.signalQuality.toUpperCase(),
                  icon: _qualityIcon(report.signalQuality),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Peaks Detected',
                  value: '${report.peaksDetected}',
                  icon: Icons.show_chart_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Risk Level',
                  value: report.riskLevel.toUpperCase(),
                  icon: Icons.shield_rounded,
                  valueColor: riskColor,
                ),
              ),
            ],
          ),

          // ─── Risk Factors ───
          if (report.riskFactors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Observations',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            ...report.riskFactors.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6, color: riskColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // ─── Disclaimer ───
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.disclaimer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
