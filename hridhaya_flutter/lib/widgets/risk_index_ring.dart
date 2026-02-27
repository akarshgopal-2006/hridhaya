import 'dart:math' as math;

import 'package:flutter/material.dart';

class RiskIndexRing extends StatefulWidget {
  final double value; // 0..100
  final String label;
  final bool pulsing;

  const RiskIndexRing({
    super.key,
    required this.value,
    required this.label,
    this.pulsing = true,
  });

  @override
  State<RiskIndexRing> createState() => _RiskIndexRingState();
}

class _RiskIndexRingState extends State<RiskIndexRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
  late final Animation<double> _scale =
      Tween(begin: 0.985, end: 1.02).animate(CurvedAnimation(
    parent: _pulse,
    curve: Curves.easeInOut,
  ));

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant RiskIndexRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
    if (!widget.pulsing && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.value.clamp(0, 100).toDouble();
    final scheme = Theme.of(context).colorScheme;
    final baseColor = Color.lerp(scheme.primary, scheme.error, clamped / 100)!;

    final ring = CustomPaint(
      painter: _RingPainter(
        progress: clamped / 100,
        color: baseColor,
        trackColor: scheme.surfaceContainerHighest,
      ),
      child: SizedBox(
        width: 240,
        height: 240,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${clamped.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!widget.pulsing) return ring;
    return ScaleTransition(scale: _scale, child: ring);
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 14;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    stroke.color = trackColor;
    canvas.drawCircle(center, radius, stroke);

    stroke.color = color;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(rect, start, sweep, false, stroke);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

