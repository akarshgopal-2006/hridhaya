import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFE1F5FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nearby Care Map',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Visual prototype – shows how we’d locate the nearest hospital and family.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB3E5FC), Color(0xFF80CBC4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: const Alignment(0.1, 0.3),
                          child: _Pin(
                            icon: Icons.local_hospital_rounded,
                            label: 'Nearest Hospital',
                            color: Colors.red[700]!,
                          ),
                        ),
                        Align(
                          alignment: const Alignment(-0.6, -0.1),
                          child: _Pin(
                            icon: Icons.home_rounded,
                            label: 'Family',
                            color: Colors.indigo,
                          ),
                        ),
                        Align(
                          alignment: const Alignment(0.0, 0.85),
                          child: _Pin(
                            icon: Icons.person_pin_circle_rounded,
                            label: 'You',
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pin({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: Colors.white),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

