import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticsService {
  Timer? _timer;
  bool _running = false;

  Future<void> startSafetyLoopHaptics() async {
    if (_running) return;
    _running = true;

    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) {
      _timer = Timer.periodic(const Duration(milliseconds: 450), (_) {
        HapticFeedback.heavyImpact();
      });
      return;
    }

    final hasAmp = await Vibration.hasAmplitudeControl();
    final hasCustom = await Vibration.hasCustomVibrationsSupport();

    if (hasCustom) {
      if (hasAmp) {
        await Vibration.vibrate(
          pattern: const [0, 900, 120, 900, 120, 900, 120],
          intensities: const [255, 255, 255, 255, 255, 255, 255],
          repeat: 1,
        );
      } else {
        await Vibration.vibrate(
          pattern: const [0, 900, 120, 900, 120, 900, 120],
          repeat: 1,
        );
      }
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 950), (_) async {
      if (!_running) return;
      await Vibration.vibrate(duration: 900, amplitude: hasAmp ? 255 : -1);
    });
  }

  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
    try {
      await Vibration.cancel();
    } catch (_) {
      // ignore
    }
  }

  void dispose() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }
}
