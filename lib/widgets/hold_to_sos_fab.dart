import 'dart:async';

import 'package:flutter/material.dart';

class HoldToSosFab extends StatefulWidget {
  final Duration holdDuration;
  final VoidCallback onTriggered;

  const HoldToSosFab({
    super.key,
    this.holdDuration = const Duration(seconds: 3),
    required this.onTriggered,
  });

  @override
  State<HoldToSosFab> createState() => _HoldToSosFabState();
}

class _HoldToSosFabState extends State<HoldToSosFab> {
  Timer? _timer;
  double _progress = 0;
  DateTime? _startedAt;
  bool _armed = false;

  void _startHold() {
    if (_armed) return;
    _armed = true;
    _startedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      final startedAt = _startedAt;
      if (!_armed || startedAt == null) return;

      final elapsed = DateTime.now().difference(startedAt);
      final p = (elapsed.inMilliseconds / widget.holdDuration.inMilliseconds)
          .clamp(0, 1)
          .toDouble();
      if (mounted) setState(() => _progress = p);

      if (p >= 1) {
        _stopHold(trigger: true);
      }
    });
  }

  void _stopHold({required bool trigger}) {
    _timer?.cancel();
    _timer = null;
    final shouldTrigger = trigger && _armed;
    _armed = false;
    _startedAt = null;
    if (mounted) setState(() => _progress = 0);
    if (shouldTrigger) widget.onTriggered();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _stopHold(trigger: false),
      onTapCancel: () => _stopHold(trigger: false),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_progress > 0)
            SizedBox(
              width: 78,
              height: 78,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(scheme.error),
              ),
            ),
          FloatingActionButton.extended(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            onPressed: () {},
            label: const Text('HOLD SOS'),
            icon: const Icon(Icons.sos_rounded),
          ),
        ],
      ),
    );
  }
}
