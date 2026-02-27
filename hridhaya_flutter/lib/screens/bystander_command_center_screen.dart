import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/emergency_flow_args.dart';
import '../services/metronome_service.dart';

class BystanderCommandCenterScreen extends StatefulWidget {
  final BystanderArgs args;
  const BystanderCommandCenterScreen({super.key, required this.args});

  @override
  State<BystanderCommandCenterScreen> createState() =>
      _BystanderCommandCenterScreenState();
}

class _BystanderCommandCenterScreenState extends State<BystanderCommandCenterScreen>
    with SingleTickerProviderStateMixin {
  final MetronomeService _metronome = MetronomeService();
  StreamSubscription<MetronomeTick>? _sub;

  int _bpm = 110;
  bool _flash = false;

  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450))
        ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _startMetronome();
  }

  void _startMetronome() {
    _metronome.start(bpm: _bpm);
    _sub?.cancel();
    _sub = _metronome.ticks.listen((tick) {
      if (!mounted) return;
      setState(() => _flash = !_flash);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _metronome.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _showResponderInfo() {
    final controller = AppScope.of(context);
    final s = controller.settings.value;

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
                'First Responder Info',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              _InfoRow(label: 'ABHA ID', value: s.abhaId),
              const SizedBox(height: 10),
              _InfoRow(label: 'Blood Group', value: s.bloodGroup),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = _flash ? const Color(0xFF111318) : const Color(0xFF0A0B0E);
    final bar = _flash ? scheme.error : scheme.primary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  if (widget.args.incidentId != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: Text(
                        widget.args.incidentId!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'STAY CALM.\nHELP IS ON THE WAY.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
              ),
              const SizedBox(height: 14),
              Text(
                'Place hands at the center of the chest.\nFollow the beat for compressions.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 0.95, end: 1.05).animate(
                          CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                        ),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bar.withValues(alpha: 0.18),
                            border: Border.all(color: bar, width: 3),
                          ),
                          child: Center(
                            child: Text(
                              'BEEP',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'CPR Metronome',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_bpm BPM (target 100–120)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Slider(
                        value: _bpm.toDouble(),
                        min: 100,
                        max: 120,
                        divisions: 20,
                        onChanged: (v) => setState(() => _bpm = v.round()),
                        onChangeEnd: (_) => _startMetronome(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _showResponderInfo,
                  icon: const Icon(Icons.badge_rounded),
                  label: const Text('Show ABHA ID & Blood Group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

