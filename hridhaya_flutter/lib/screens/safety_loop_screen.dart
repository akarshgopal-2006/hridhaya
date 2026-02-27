import 'dart:async';

import 'package:flutter/material.dart';

import '../models/emergency_flow_args.dart';
import '../routes.dart';
import '../services/emergency_service.dart';
import '../services/haptics_service.dart';

class SafetyLoopScreen extends StatefulWidget {
  final SafetyLoopArgs args;
  const SafetyLoopScreen({super.key, required this.args});

  @override
  State<SafetyLoopScreen> createState() => _SafetyLoopScreenState();
}

class _SafetyLoopScreenState extends State<SafetyLoopScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 30;

  final HapticsService _haptics = HapticsService();
  final EmergencyService _emergency = EmergencyService();

  Timer? _timer;
  int _remaining = _totalSeconds;
  bool _sending = false;

  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 720))
        ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _haptics.startSafetyLoopHaptics();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = (_remaining - 1).clamp(0, _totalSeconds));
      if (_remaining <= 0) {
        _timer?.cancel();
        _timer = null;
        _sendSos();
      }
    });
  }

  Color _bgColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = 1 - (_remaining / _totalSeconds); // 0..1
    final yellow = const Color(0xFFFFEB3B);
    final deepRed = const Color(0xFFB71C1C);
    final base = Color.lerp(yellow, deepRed, Curves.easeIn.transform(t))!;
    return Color.lerp(base, scheme.surface, 0.08)!;
  }

  Future<void> _cancelFalseAlarm() async {
    _timer?.cancel();
    _timer = null;
    await _haptics.stop();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _sendSos() async {
    if (_sending) return;
    setState(() => _sending = true);
    await _haptics.stop();
    final result = await _emergency.sendSos(
      reason: 'Safety Loop expired (${widget.args.trigger})',
    );
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.bystander,
      (r) => r.settings.name == Routes.dashboard,
      arguments: BystanderArgs(incidentId: result.incidentId),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    _haptics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = _bgColor(context);
    final t = 1 - (_remaining / _totalSeconds); // 0..1

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _sending ? null : _cancelFalseAlarm,
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Text(
                          widget.args.trigger == 'auto_thud' ? 'AUTO: THUD' : 'SAFETY LOOP',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ScaleTransition(
                    scale: Tween(begin: 0.98, end: 1.04).animate(
                      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                    ),
                    child: Text(
                      '$_remaining',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 140,
                            height: 0.9,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                            letterSpacing: -6,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _sending
                        ? 'Sending SOS...'
                        : 'If this is a false alarm, tap the button below.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 90,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: _sending ? null : _cancelFalseAlarm,
                      child: Text(
                        "I'M OK",
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: t.clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFB71C1C)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vibrating at maximum intensity during countdown',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            if (_sending)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.25),
                  child: const Center(
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(strokeWidth: 6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

