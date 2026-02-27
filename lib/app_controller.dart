import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/app_settings.dart';
import 'services/app_settings_store.dart';
import 'services/fall_detection_service.dart';
import 'services/fall_detection_api_service.dart';

class AppController {
  final ValueNotifier<AppSettings> settings =
      ValueNotifier(AppSettings.defaults());
  late final AppSettingsStore _store;
  final FallDetectionService fallDetection = FallDetectionService();

  StreamSubscription<FallEvent>? _fallSub;

  final _fallController = StreamController<FallEvent>.broadcast();
  Stream<FallEvent> get fallEvents => _fallController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _store = AppSettingsStore(prefs);
    final loaded = _store.load();
    settings.value = loaded;
    _applyFallSubscription(loaded);
  }

  Future<void> updateSettings(AppSettings next) async {
    settings.value = next;
    await _store.save(next);
    _applyFallSubscription(next);
  }

  Future<void> eraseHealthData() async {
    await _store.eraseAllHealthData();
    final current = settings.value;
    await updateSettings(
      current.copyWith(
        abhaId: AppSettings.defaults().abhaId,
        bloodGroup: AppSettings.defaults().bloodGroup,
      ),
    );
  }

  void _applyFallSubscription(AppSettings s) {
    final shouldMonitor = s.backgroundMonitoring && s.fallDetection;
    if (!shouldMonitor) {
      fallDetection.stop();
      _fallSub?.cancel();
      _fallSub = null;
      return;
    }

    fallDetection.start();
    _fallSub ??= fallDetection.events.listen((event) {
      // Broadcast the event locally (triggers Safety Loop UI)
      _fallController.add(event);

      // Report to backend (fire-and-forget, won't crash if backend is offline)
      final s = settings.value;
      FallDetectionApiService.reportFall(
        event: event,
        abhaId: s.abhaId,
        bloodGroup: s.bloodGroup,
      );
    });
  }

  Future<void> dispose() async {
    _fallSub?.cancel();
    await _fallController.close();
    await fallDetection.dispose();
    settings.dispose();
  }
}
