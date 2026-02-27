import 'package:flutter/material.dart';

import '../services/hospital_api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Hospital>? _hospitals;
  bool _loading = true;
  String? _error;
  String _sortBy = 'distance';

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final hospitals = await HospitalApiService.fetchNearby(sortBy: _sortBy);
      if (!mounted) return;
      setState(() {
        _hospitals = hospitals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ───
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nearby Hospitals',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    // Sort toggle
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'distance',
                          icon: Icon(Icons.near_me_rounded, size: 16),
                          label: Text('Near'),
                        ),
                        ButtonSegment(
                          value: 'rating',
                          icon: Icon(Icons.star_rounded, size: 16),
                          label: Text('Top'),
                        ),
                      ],
                      selected: {_sortBy},
                      onSelectionChanged: (v) {
                        _sortBy = v.first;
                        _loadHospitals();
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: scheme.primary.withValues(alpha: 0.12),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // ─── Emergency banner ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency? Call 108',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            Text(
                              'All hospitals below have 24/7 cardiac emergency care.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ─── Hospital list ───
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Could not load hospitals.\n$_error',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : _hospitals == null || _hospitals!.isEmpty
                            ? const Center(child: Text('No hospitals found.'))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                                itemCount: _hospitals!.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return _HospitalCard(
                                    hospital: _hospitals![index],
                                    rank: index + 1,
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hospital Card ───────────────────────────────────────────

class _HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final int rank;

  const _HospitalCard({required this.hospital, required this.rank});

  Color _typeColor(String type) {
    switch (type) {
      case 'Cardiac Specialty':
      case 'Heart Specialty':
        return const Color(0xFFD32F2F);
      case 'Government':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typeColor = _typeColor(hospital.type);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showDetail(context),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: name + distance
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(Icons.local_hospital_rounded, color: typeColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hospital.type,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: typeColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          if (hospital.is24x7) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '24/7',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${hospital.distanceKm} km',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                    ),
                    Text(
                      '~${hospital.driveMins} min drive',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Address
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hospital.address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.star_rounded,
                  label: '${hospital.rating}',
                  color: const Color(0xFFFF8F00),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.bed_rounded,
                  label: '${hospital.availableBeds} beds free',
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.emergency_rounded,
                  label: '${hospital.erBeds} ER',
                  color: const Color(0xFFD32F2F),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.airport_shuttle_rounded,
                  label: '${hospital.ambulanceCount}',
                  color: const Color(0xFF1565C0),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Specialties
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: hospital.specialties
                  .map((s) => Chip(
                        label: Text(s),
                        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: scheme.outlineVariant),
                        backgroundColor: scheme.surfaceContainerLowest,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              children: [
                Text(
                  hospital.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  hospital.type,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _typeColor(hospital.type),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                _DetailRow(icon: Icons.location_on_rounded, label: 'Address', value: hospital.address),
                _DetailRow(icon: Icons.phone_rounded, label: 'Phone', value: hospital.phone),
                _DetailRow(icon: Icons.emergency_rounded, label: 'Emergency', value: hospital.emergencyPhone),
                _DetailRow(icon: Icons.near_me_rounded, label: 'Distance', value: '${hospital.distanceKm} km (~${hospital.driveMins} min drive)'),
                _DetailRow(icon: Icons.star_rounded, label: 'Rating', value: '${hospital.rating} / 5.0'),
                _DetailRow(icon: Icons.verified_rounded, label: 'Accreditation', value: hospital.accreditation.join(', ')),
                const SizedBox(height: 16),
                Text(
                  'Emergency Department',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'ER Beds',
                        value: '${hospital.erBeds}',
                        icon: Icons.bed_rounded,
                        color: const Color(0xFFD32F2F),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Ambulances',
                        value: '${hospital.ambulanceCount}',
                        icon: Icons.airport_shuttle_rounded,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Status',
                        value: hospital.erAvailable ? 'OPEN' : 'FULL',
                        icon: Icons.check_circle_rounded,
                        color: hospital.erAvailable ? const Color(0xFF2E7D32) : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Bed Availability',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${hospital.availableBeds} available',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2E7D32),
                                  )),
                          Text('of ${hospital.totalBeds} total',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: hospital.availableBeds / hospital.totalBeds,
                        minHeight: 10,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF2E7D32)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Specialties',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: hospital.specialties
                      .map((s) => Chip(
                            label: Text(s),
                            avatar: const Icon(Icons.check_circle_rounded, size: 16),
                            side: BorderSide(color: scheme.outlineVariant),
                            backgroundColor: scheme.surfaceContainerLowest,
                          ))
                      .toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
