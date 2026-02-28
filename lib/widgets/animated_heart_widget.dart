import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A beautiful animated heart widget that pulses like a real heartbeat.
/// Shows the cardiac risk index value inside the heart.
class AnimatedHeartWidget extends StatefulWidget {
  final double riskValue; // 0..100
  final String label;

  const AnimatedHeartWidget({
    super.key,
    required this.riskValue,
    this.label = 'Cardiac Risk Index',
  });

  @override
  State<AnimatedHeartWidget> createState() => _AnimatedHeartWidgetState();
}

class _AnimatedHeartWidgetState extends State<AnimatedHeartWidget>
    with TickerProviderStateMixin {
  // Main heartbeat animation (lub-dub pattern)
  late final AnimationController _beatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  // Glow pulse animation
  late final AnimationController _glowCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  // ECG line animation
  late final AnimationController _ecgCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _startHeartbeat();
  }

  void _startHeartbeat() {
    // Simulate realistic lub-dub heartbeat pattern
    Future.doWhile(() async {
      if (!mounted) return false;
      // LUB (strong beat)
      _beatCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return false;
      _beatCtrl.reverse();
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return false;
      // DUB (softer beat)
      _beatCtrl.forward(from: 0.0);
      await _beatCtrl.animateTo(0.6, duration: const Duration(milliseconds: 100));
      if (!mounted) return false;
      _beatCtrl.reverse();
      // Rest between beats (~72 BPM)
      await Future.delayed(const Duration(milliseconds: 450));
      return mounted;
    });
  }

  @override
  void dispose() {
    _beatCtrl.dispose();
    _glowCtrl.dispose();
    _ecgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heartColor = const Color(0xFFE53935); // Always red
    final screenWidth = MediaQuery.of(context).size.width;
    final heartSize = (screenWidth * 0.42).clamp(130.0, 220.0);

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: heartSize + 40,
            height: heartSize + 40,
            child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow rings
              AnimatedBuilder(
                animation: _glowCtrl,
                builder: (context, child) {
                  final glowOpacity = 0.08 + _glowCtrl.value * 0.12;
                  return Opacity(
                    opacity: glowOpacity,
                    child: child,
                  );
                },
                child: Container(
                  width: heartSize + 36,
                  height: heartSize + 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: heartColor, // Simple static color
                  ),
                ),
              ),

              // Pulsing heart
              AnimatedBuilder(
                animation: _beatCtrl,
                builder: (context, child) {
                  final scale = 1.0 + _beatCtrl.value * 0.08;
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: SizedBox(
                  width: heartSize,
                  height: heartSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                        // Wrap Text in RepaintBoundary to cache the rasterized Emoji
                        RepaintBoundary(
                          child: Text(
                            '🫀',
                            style: TextStyle(
                              fontSize: heartSize * 0.75,
                              height: 1.0,
                            ),
                          ),
                        ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ECG line
        SizedBox(
          height: 30,
          width: heartSize + 30,
          child: AnimatedBuilder(
            animation: _ecgCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _EcgPainter(
                  phase: _ecgCtrl.value,
                  color: Colors.red,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),


      ],
    ),
    );
  }
}

/// Draws a scrolling ECG/heartbeat line.
class _EcgPainter extends CustomPainter {
  final double phase; // 0..1
  final Color color;

  _EcgPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final path = Path();
    // Reduce segments by half for much faster web rendering
    const segments = 50;
    final dx = size.width / (segments - 1);

    for (var i = 0; i < segments; i++) {
      final x = i * dx;
      final t = (i / segments + phase) % 1.0;
      double y = midY;

      // ECG waveform pattern
      if (t > 0.35 && t < 0.42) {
        // P wave (small bump)
        final p = (t - 0.35) / 0.07;
        y = midY - math.sin(p * math.pi) * size.height * 0.1;
      } else if (t > 0.45 && t < 0.48) {
        // Q dip
        final p = (t - 0.45) / 0.03;
        y = midY + math.sin(p * math.pi) * size.height * 0.12;
      } else if (t > 0.48 && t < 0.54) {
        // R peak (sharp)
        final p = (t - 0.48) / 0.06;
        y = midY - math.sin(p * math.pi) * size.height * 0.42;
      } else if (t > 0.54 && t < 0.58) {
        // S dip
        final p = (t - 0.54) / 0.04;
        y = midY + math.sin(p * math.pi) * size.height * 0.18;
      } else if (t > 0.65 && t < 0.75) {
        // T wave (medium bump)
        final p = (t - 0.65) / 0.10;
        y = midY - math.sin(p * math.pi) * size.height * 0.15;
      }

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw ECG line
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.6),
    );

    // Glow (Simplified for web performance - removed MaskFilter.blur)
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.15),
    );
  }

  @override
  bool shouldRepaint(covariant _EcgPainter old) =>
      old.phase != phase || old.color != color;
}
