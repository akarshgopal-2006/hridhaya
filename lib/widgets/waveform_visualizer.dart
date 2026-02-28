import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Renders a real-time scrolling waveform from gyroscope magnitude data.
///
/// When [dataPoints] is provided (live recording mode), draws the actual
/// gyroscope magnitudes as a scrolling ECG-style trace.
/// When empty, falls back to a synthetic idle wave using [intensity] & [phase].
class WaveformVisualizer extends StatelessWidget {
  final double intensity; // 0..1 (used for idle synthetic wave)
  final double phase; // 0..1 (used for idle synthetic wave)
  final Color color;
  final List<double> dataPoints; // live gyroscope magnitudes (0..1 normalized)
  final bool recording;

  const WaveformVisualizer({
    super.key,
    required this.intensity,
    required this.phase,
    required this.color,
    this.dataPoints = const [],
    this.recording = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(14),
        ),
        child: CustomPaint(
          painter: _WavePainter(
            amplitude: 0.12 + intensity * 0.85,
            phase: phase,
            color: color,
            dataPoints: dataPoints,
            recording: recording,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double amplitude;
  final double phase;
  final Color color;
  final List<double> dataPoints;
  final bool recording;

  _WavePainter({
    required this.amplitude,
    required this.phase,
    required this.color,
    required this.dataPoints,
    required this.recording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;

    // Draw grid lines
    _drawGrid(canvas, size);

    if (recording && dataPoints.isNotEmpty) {
      _drawLiveWaveform(canvas, size, midY);
    } else {
      _drawIdleWave(canvas, size, midY);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    // Horizontal grid lines
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid lines
    for (var i = 1; i < 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Center line
    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );
  }

  /// Draw the actual gyroscope data as a scrolling trace.
  void _drawLiveWaveform(Canvas canvas, Size size, double midY) {
    // Show last N points that fit the width
    const maxPoints = 200;
    final visiblePoints = dataPoints.length > maxPoints
        ? dataPoints.sublist(dataPoints.length - maxPoints)
        : dataPoints;

    if (visiblePoints.length < 2) return;

    final dx = size.width / (maxPoints - 1);
    final ampPx = size.height * 0.40;

    final path = Path();
    for (var i = 0; i < visiblePoints.length; i++) {
      final x = i * dx;
      // Center the waveform: values are 0..1 normalized magnitudes
      // Shift so 0.5 is center, scale to fill height
      final val = (visiblePoints[i] - 0.5) * 2; // -1..1
      final y = midY - val * ampPx;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Main line
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    // Glow effect
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = color.withValues(alpha: 0.25),
    );

    // Draw a scanning line at the end
    if (visiblePoints.length < maxPoints) {
      final scanX = visiblePoints.length * dx;
      canvas.drawLine(
        Offset(scanX, 0),
        Offset(scanX, size.height),
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 2,
      );
    }
  }

  /// Idle synthetic wave (no recording).
  void _drawIdleWave(Canvas canvas, Size size, double midY) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.5);

    final path = Path();
    const points = 120;
    final dx = size.width / (points - 1);
    const freq = 2.8;
    final ampPx = (size.height * 0.22) * amplitude;
    final phaseRad = phase * math.pi * 2;

    for (var i = 0; i < points; i++) {
      final x = i * dx;
      final t = i / (points - 1);
      final y = midY +
          math.sin((t * math.pi * 2 * freq) + phaseRad) * ampPx;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Subtle glow
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = color.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
