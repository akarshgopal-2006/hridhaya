import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class AppSettingsStore {
  static const _kBackgroundMonitoring = 'backgroundMonitoring';
  static const _kFallDetection = 'fallDetection';
  static const _kAbhaId = 'abhaId';
  static const _kBloodGroup = 'bloodGroup';
  static const _kFamilySynced = 'familySynced';
  static const _kHospitalSynced = 'hospitalSynced';

  final SharedPreferences _prefs;

  AppSettingsStore(this._prefs);

  AppSettings load() {
    final defaults = AppSettings.defaults();
    return defaults.copyWith(
      backgroundMonitoring:
          _prefs.getBool(_kBackgroundMonitoring) ?? defaults.backgroundMonitoring,
      fallDetection: _prefs.getBool(_kFallDetection) ?? defaults.fallDetection,
      abhaId: _prefs.getString(_kAbhaId) ?? defaults.abhaId,
      bloodGroup: _prefs.getString(_kBloodGroup) ?? defaults.bloodGroup,
      familySynced: _prefs.getBool(_kFamilySynced) ?? defaults.familySynced,
      hospitalSynced: _prefs.getBool(_kHospitalSynced) ?? defaults.hospitalSynced,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setBool(_kBackgroundMonitoring, settings.backgroundMonitoring);
    await _prefs.setBool(_kFallDetection, settings.fallDetection);
    await _prefs.setString(_kAbhaId, settings.abhaId);
    await _prefs.setString(_kBloodGroup, settings.bloodGroup);
    await _prefs.setBool(_kFamilySynced, settings.familySynced);
    await _prefs.setBool(_kHospitalSynced, settings.hospitalSynced);
  }

  Future<void> eraseAllHealthData() async {
    await _prefs.remove(_kAbhaId);
    await _prefs.remove(_kBloodGroup);
  }
}
