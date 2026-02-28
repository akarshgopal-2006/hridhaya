
import 'package:flutter/material.dart';

import '../app.dart';
import '../models/emergency_flow_args.dart';
import '../routes.dart';
import '../services/family_api_service.dart';
import '../services/hospital_api_service.dart';
import '../widgets/animated_heart_widget.dart';
import '../widgets/connected_status_row.dart';
import '../widgets/hold_to_sos_fab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Static cardiac risk index value.
  // In production this would come from real sensor data / ML model output.
  static const double _risk = 28;

  void _showFamilySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<FamilyMember>>(
              future: FamilyApiService.fetchMembers(),
              builder: (context, snap) {
                final scheme = Theme.of(context).colorScheme;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.groups_rounded, color: scheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Family Circle',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your emergency contacts & family members',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (snap.connectionState == ConnectionState.waiting)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: (snap.data ?? []).length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final m = snap.data![i];
                              return _FamilyMemberTile(member: m);
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showHospitalSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<Hospital>>(
              future: HospitalApiService.fetchNearby(),
              builder: (context, snap) {
                final scheme = Theme.of(context).colorScheme;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_hospital_rounded, color: scheme.error),
                          const SizedBox(width: 10),
                          Text(
                            'Nearby Hospitals',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hospitals with cardiac care near you',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (snap.connectionState == ConnectionState.waiting)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: (snap.data ?? []).length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final h = snap.data![i];
                              return _HospitalTile(hospital: h);
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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
                  Center(
                    child: AnimatedHeartWidget(
                      riskValue: _risk,
                      label: 'Cardiac Risk Index',
                    ),
                  ),
                  Center(
                    child: ConnectedStatusRow(
                      familySynced: settings.familySynced,
                      hospitalSynced: settings.hospitalSynced,
                      onFamilyTap: () => _showFamilySheet(context),
                      onHospitalTap: () => _showHospitalSheet(context),
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
                        'Full-screen 30s countdown with max vibration + giant "I\'M OK".',
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
                          'Auto Fall Detection',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          settings.backgroundMonitoring && settings.fallDetection
                              ? 'Monitoring is ON. If the phone detects a fall (free-fall → impact → stillness), Safety Loop opens automatically.'
                              : 'Monitoring is OFF. Enable "Background Monitoring" + "Fall Detection" in Settings.',
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
                              Navigator.of(context).pushNamed(
                                Routes.safetyLoop,
                                arguments: const SafetyLoopArgs.testFall(),
                              );
                            },
                            icon: const Icon(Icons.bolt_rounded),
                            label: const Text('Simulate fall'),
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



class _FamilyMemberTile extends StatelessWidget {
  final FamilyMember member;

  const _FamilyMemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarColor = Color(member.avatarColor);
    final isOnline = member.status == 'online';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with status dot
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: avatarColor.withValues(alpha: 0.15),
                child: Text(
                  member.name.split(' ').map((w) => w[0]).take(2).join(),
                  style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFFFA000),
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (member.emergencyContact) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SOS',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: scheme.error,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.relation} · ${member.locationLabel}',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.phone,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Call button
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${member.name}...'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.call_rounded,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HospitalTile extends StatelessWidget {
  final Hospital hospital;

  const _HospitalTile({required this.hospital});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + distance row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  color: scheme.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${hospital.type} · ${hospital.distanceKm} km · ${hospital.driveMins} min drive',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA000).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFA000)),
                    const SizedBox(width: 2),
                    Text(
                      hospital.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF57F17),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Status chips row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatusChip(
                icon: Icons.emergency_rounded,
                label: hospital.erAvailable ? 'ER Open' : 'ER Closed',
                color: hospital.erAvailable
                    ? const Color(0xFF2E7D32)
                    : scheme.error,
              ),
              _StatusChip(
                icon: Icons.bed_rounded,
                label: '${hospital.availableBeds} beds free',
                color: scheme.primary,
              ),
              if (hospital.is24x7)
                _StatusChip(
                  icon: Icons.access_time_filled_rounded,
                  label: '24/7',
                  color: const Color(0xFF0277BD),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Specialties
          Text(
            hospital.specialties.take(3).join(' · '),
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 10),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling ${hospital.name} Emergency...'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Call ER'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Navigating to ${hospital.name}...'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: const Text('Navigate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
