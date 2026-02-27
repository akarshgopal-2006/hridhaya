import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/emergency_flow_args.dart';
import '../routes.dart';
import '../widgets/connected_status_row.dart';
import '../widgets/hold_to_sos_fab.dart';
import '../widgets/risk_index_ring.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _riskTimer;
  double _risk = 28;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _riskTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      _t += 0.17;
      final wave = (math.sin(_t) + 1) / 2; // 0..1
      final next = 18 + wave * 38;
      if (mounted) setState(() => _risk = next);
    });
  }

  @override
  void dispose() {
    _riskTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return ValueListenableBuilder(
      valueListenable: controller.settings,
      builder: (context, settings, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('Hridhaya'),
            actions: [
              IconButton(
                tooltip: 'Settings & Privacy',
                onPressed: () => Navigator.of(context).pushNamed(Routes.settings),
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          floatingActionButton: HoldToSosFab(
            onTriggered: () {
              Navigator.of(context).pushNamed(
                Routes.safetyLoop,
                arguments: const SafetyLoopArgs.manual(),
              );
            },
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFFDE7), Color(0xFFFFEBEE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                children: [
                  const SizedBox(height: 6),
                  Center(
                    child: RiskIndexRing(
                      value: _risk,
                      label: 'Cardiac Risk Index',
                      pulsing: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ConnectedStatusRow(
                      familySynced: settings.familySynced,
                      hospitalSynced: settings.hospitalSynced,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PrimaryCard(
                    title: 'SOS Button',
                    subtitle: 'Tap to open Safety Loop immediately.',
                    icon: Icons.sos_rounded,
                    onTap: () => Navigator.of(context).pushNamed(Routes.sos),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryCard(
                    title: 'Digital Stethoscope',
                    subtitle:
                        'Capture micro-vibrations and analyze heart mechanics (15s).',
                    icon: Icons.graphic_eq_rounded,
                    onTap: () => Navigator.of(context).pushNamed(Routes.stethoscope),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryCard(
                    title: 'Safety Loop',
                    subtitle:
                        'Full-screen 30s countdown with max vibration + giant “I’M OK”.',
                    icon: Icons.warning_rounded,
                    onTap: () => Navigator.of(context).pushNamed(
                      Routes.safetyLoop,
                      arguments: const SafetyLoopArgs.manual(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryCard(
                    title: 'Bystander Command Center',
                    subtitle:
                        'Demo the post-SOS guidance screen + CPR metronome.',
                    icon: Icons.record_voice_over_rounded,
                    onTap: () => Navigator.of(context).pushNamed(Routes.bystander),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'More tools',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  _PrimaryCard(
                    title: 'Doctor Consult',
                    subtitle: 'Connect with a cardiologist.',
                    icon: Icons.medical_information_rounded,
                    onTap: () =>
                        Navigator.of(context).pushNamed(Routes.doctorConsult),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryCard(
                    title: 'Hridhaya Chatbot',
                    subtitle:
                        'Ask about symptoms, lifestyle and when to press SOS (demo).',
                    icon: Icons.smart_toy_rounded,
                    onTap: () => Navigator.of(context).pushNamed(Routes.chatbot),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryCard(
                    title: 'Nearby Care Map',
                    subtitle: 'Prototype view of hospitals & family on a map.',
                    icon: Icons.map_rounded,
                    onTap: () => Navigator.of(context).pushNamed(Routes.map),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryCard(
                    title: 'Payments',
                    subtitle:
                        'Manage subscriptions and saved payment methods (prototype).',
                    icon: Icons.payments_rounded,
                    onTap: () => Navigator.of(context).pushNamed(Routes.payment),
                  ),
                  const SizedBox(height: 18),
                  Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Trigger (Thud)',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        settings.backgroundMonitoring && settings.fallDetection
                            ? 'Monitoring is ON. A strong acceleration spike will open Safety Loop automatically.'
                            : 'Monitoring is OFF. Enable “Background Monitoring” + “Fall Detection” in Settings.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            // Demo shortcut for judges.
                            Navigator.of(context).pushNamed(
                              Routes.safetyLoop,
                              arguments: const SafetyLoopArgs.testThud(),
                            );
                          },
                          icon: const Icon(Icons.bolt_rounded),
                          label: const Text('Simulate thud'),
                        ),
                      ),
                    ],
                  ),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrimaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              scheme.surface,
              scheme.surfaceContainerLowest,
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

