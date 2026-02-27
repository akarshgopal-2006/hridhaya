import 'package:flutter/material.dart';

import '../models/emergency_flow_args.dart';
import '../routes.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFCDD2)],
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
                      'SOS',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'One-tap emergency help',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use this when you feel unwell or unsafe before a fall happens.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 230,
                      height: 230,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(28),
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                          elevation: 10,
                        ),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            Routes.safetyLoop,
                            arguments: const SafetyLoopArgs.manual(),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sos_rounded, size: 60),
                            const SizedBox(height: 10),
                            Text(
                              'PRESS SOS',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tip: the floating “HOLD SOS” button on the dashboard works even faster.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
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

