import 'dart:math' as math;

import 'package:flutter/material.dart';

class WaveformVisualizer extends StatelessWidget {
  final double intensity; // 0..1
  final double phase; // 0..1
  final Color color;

  const WaveformVisualizer({
    super.key,
    required this.intensity,
    required this.phase,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final amp = (0.12 + intensity * 0.85) * t;
        return CustomPaint(
          painter: _WavePainter(
            amplitude: amp,
            phase: phase,
            color: color,
          ),
          child: const SizedBox(height: 120, width: double.infinity),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double amplitude; // ~0..1
  final double phase; // 0..1
  final Color color;

  _WavePainter({
    required this.amplitude,
    required this.phase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;

    final path = Path();
    final points = 120;
    final dx = size.width / (points - 1);
    final freq = 2.8;
    final ampPx = (size.height * 0.38) * amplitude;
    final phaseRad = (phase * math.pi * 2);

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

    canvas.drawPath(
      path,
      paint..color = color.withValues(alpha: 0.95),
    );

    // glow
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color = color.withValues(alpha: 0.20),
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.amplitude != amplitude ||
        oldDelegate.phase != phase ||
        oldDelegate.color != color;
  }
}

