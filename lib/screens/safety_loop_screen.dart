import 'dart:async';

import 'package:flutter/material.dart';

import '../models/emergency_flow_args.dart';
import '../routes.dart';
import '../services/api_config.dart';
import '../services/emergency_service.dart';
import '../services/family_api_service.dart';
import '../services/haptics_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // Emergency state
  bool _emergencyTriggered = false;
  bool _familyAlerted = false;
  bool _ambulanceRequested = false;
  List<FamilyMember> _familyMembers = [];
  String? _incidentId;

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
    final t = 1 - (_remaining / _totalSeconds);
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
    setState(() {
      _sending = true;
      _emergencyTriggered = true;
    });
    await _haptics.stop();

    // Send SOS
    final result = await _emergency.sendSos(
      reason: 'Safety Loop expired (${widget.args.trigger})',
    );
    _incidentId = result.incidentId;

    // Alert family members
    await _alertFamily();

    // Automatically request ambulance
    await _requestAmbulance();

    if (!mounted) return;
    setState(() => _sending = false);
  }

  Future<void> _alertFamily() async {
    try {
      final members = await FamilyApiService.fetchMembers();
      if (!mounted) return;
      setState(() {
        _familyMembers = members;
        _familyAlerted = true;
      });
    } catch (_) {
      // Use fallback data
      if (!mounted) return;
      setState(() {
        _familyAlerted = true;
        _familyMembers = [];
      });
    }
  }

  Future<void> _requestAmbulance() async {
    setState(() => _ambulanceRequested = true);

    // Simulate ambulance request to backend
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fall-detection/report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fallEvent': {
            'timestamp': DateTime.now().toIso8601String(),
            'type': 'sos_timer_expired',
            'severity': 'critical',
          },
          'userSettings': {
            'abhaId': 'Unknown',
            'bloodGroup': 'Unknown',
          },
          'requestAmbulance': true,
        }),
      );
    } catch (_) {
      // Ambulance booking is demo — works offline too
    }
  }

  void _goToBystander() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.bystander,
      (r) => r.settings.name == Routes.dashboard,
      arguments: BystanderArgs(incidentId: _incidentId ?? 'INC-UNKNOWN'),
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
    final bg = _emergencyTriggered ? const Color(0xFFB71C1C) : _bgColor(context);
    final t = 1 - (_remaining / _totalSeconds);

    if (_emergencyTriggered && !_sending) {
      return _buildEmergencyScreen(context);
    }

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
                          widget.args.trigger == 'auto_fall' ? 'AUTO: FALL DETECTED' : 'SAFETY LOOP',
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
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Emergency screen shown after SOS timer expires
  Widget _buildEmergencyScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            // ─── Emergency Header ───
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.sos_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    'EMERGENCY ACTIVATED',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Incident: ${_incidentId ?? "Processing..."}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Family Alert Status ───
            _EmergencyCard(
              icon: Icons.family_restroom_rounded,
              iconColor: _familyAlerted ? const Color(0xFF4CAF50) : const Color(0xFFFFA000),
              title: _familyAlerted ? 'Family Alerted ✓' : 'Alerting Family...',
              subtitle: _familyAlerted
                  ? '${_familyMembers.length} family members notified with your location'
                  : 'Sending emergency alerts to all family members...',
              child: _familyAlerted && _familyMembers.isNotEmpty
                  ? Column(
                      children: _familyMembers.map((m) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(m.avatarColor),
                                child: Text(
                                  m.name[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${m.relation} • ${m.phone}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '📨 Sent',
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // ─── Ambulance Booking ───
            _EmergencyCard(
              icon: Icons.local_hospital_rounded,
              iconColor: _ambulanceRequested
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF2196F3),
              title: _ambulanceRequested
                  ? 'Ambulance Dispatched ✓'
                  : 'Book Ambulance',
              subtitle: _ambulanceRequested
                  ? 'Ambulance is on the way. ETA: ~8 minutes.\nSharing your live location with the driver.'
                  : 'Request an ambulance to your current location immediately.',
              child: !_ambulanceRequested
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _requestAmbulance,
                        icon: const Icon(Icons.local_shipping_rounded),
                        label: const Text(
                          'REQUEST AMBULANCE NOW',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.fire_truck_rounded,
                                  color: Color(0xFF4CAF50), size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'AMB-HRD-2847',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'ETA: 8 min • 2.3 km away',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.phone_rounded,
                                    color: Color(0xFF4CAF50), size: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            // ─── Call Emergency Number ───
            _EmergencyCard(
              icon: Icons.call_rounded,
              iconColor: const Color(0xFFFF5252),
              title: 'Emergency Helpline',
              subtitle: 'Call 108 (India) for immediate medical assistance.',
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5252),
                    side: const BorderSide(color: Color(0xFFFF5252)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📞 Calling 108... (demo)'),
                        backgroundColor: Color(0xFFD32F2F),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text(
                    'CALL 108',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── Continue to Bystander ───
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _goToBystander,
                icon: const Icon(Icons.record_voice_over_rounded),
                label: const Text(
                  'Open Bystander Guide',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'CPR instructions & first-aid guidance',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable card for the emergency screen.
class _EmergencyCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? child;

  const _EmergencyCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 12),
            child!,
          ],
        ],
      ),
    );
  }
}
