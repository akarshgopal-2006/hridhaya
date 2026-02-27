import 'package:flutter/material.dart';

class DoctorConsultScreen extends StatelessWidget {
  const DoctorConsultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E9)],
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
                      'Doctor Consult',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Talk to a cardiologist',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your recent Safety Loop events and Digital Stethoscope recordings with a verified doctor.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      _DoctorCard(
                        name: 'Dr. Ananya Iyer',
                        speciality: 'Interventional Cardiologist',
                        status: 'Available now',
                        accent: scheme.primary,
                      ),
                      const SizedBox(height: 12),
                      _DoctorCard(
                        name: 'Dr. Rohan Menon',
                        speciality: 'Heart Failure Specialist',
                        status: 'Online today',
                        accent: scheme.tertiary,
                      ),
                    ],
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

class _DoctorCard extends StatelessWidget {
  final String name;
  final String speciality;
  final String status;
  final Color accent;

  const _DoctorCard({
    required this.name,
    required this.speciality,
    required this.status,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.white, accent.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: accent.withValues(alpha: 0.18),
            child: Icon(Icons.person_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  speciality,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonalIcon(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confirm video consult',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          speciality,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Recommended slot: Today, 5:30 PM (15 min)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Consult booked with $name (demo booking).',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Confirm'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.video_call_rounded),
            label: const Text('Book'),
          ),
        ],
      ),
    );
  }
}

