import 'package:flutter/material.dart';

class ChestPlacementGraphic extends StatefulWidget {
  const ChestPlacementGraphic({super.key});

  @override
  State<ChestPlacementGraphic> createState() => _ChestPlacementGraphicState();
}

class _ChestPlacementGraphicState extends State<ChestPlacementGraphic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.accessibility_new_rounded,
            size: 190,
            color: scheme.onSurface.withValues(alpha: 0.10),
          ),
          Positioned(
            top: 78,
            child: ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.12).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.12),
                  border: Border.all(color: scheme.primary, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.smartphone_rounded,
                    size: 34,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            child: Text(
              'Place phone at the center of the chest',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
