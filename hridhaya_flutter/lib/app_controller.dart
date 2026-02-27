import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/app_settings.dart';
import 'services/app_settings_store.dart';
import 'services/thud_detection_service.dart';

class AppController {
  final ValueNotifier<AppSettings> settings = ValueNotifier(AppSettings.defaults());
  late final AppSettingsStore _store;
  final ThudDetectionService thudDetection = ThudDetectionService();

  StreamSubscription<ThudEvent>? _thudSub;

  final _thudController = StreamController<ThudEvent>.broadcast();
  Stream<ThudEvent> get thudEvents => _thudController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _store = AppSettingsStore(prefs);
    final loaded = _store.load();
    settings.value = loaded;
    _applyThudSubscription(loaded);
  }

  Future<void> updateSettings(AppSettings next) async {
    settings.value = next;
    await _store.save(next);
    _applyThudSubscription(next);
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

  void _applyThudSubscription(AppSettings s) {
    final shouldMonitor = s.backgroundMonitoring && s.fallDetection;
    if (!shouldMonitor) {
      thudDetection.stop();
      _thudSub?.cancel();
      _thudSub = null;
      return;
    }

    thudDetection.start();
    _thudSub ??= thudDetection.events.listen(_thudController.add);
  }

  Future<void> dispose() async {
    _thudSub?.cancel();
    await _thudController.close();
    await thudDetection.dispose();
    settings.dispose();
  }
}

