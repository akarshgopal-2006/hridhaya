class AppSettings {
  final bool backgroundMonitoring;
  final bool fallDetection;
  final String abhaId;
  final String bloodGroup;
  final bool familySynced;
  final bool hospitalSynced;

  const AppSettings({
    required this.backgroundMonitoring,
    required this.fallDetection,
    required this.abhaId,
    required this.bloodGroup,
    required this.familySynced,
    required this.hospitalSynced,
  });

  factory AppSettings.defaults() => const AppSettings(
        backgroundMonitoring: true,
        fallDetection: true,
        abhaId: 'XX-XXXX-XXXX-XXXX',
        bloodGroup: 'O+',
        familySynced: true,
        hospitalSynced: true,
      );

  AppSettings copyWith({
    bool? backgroundMonitoring,
    bool? fallDetection,
    String? abhaId,
    String? bloodGroup,
    bool? familySynced,
    bool? hospitalSynced,
  }) {
    return AppSettings(
      backgroundMonitoring: backgroundMonitoring ?? this.backgroundMonitoring,
      fallDetection: fallDetection ?? this.fallDetection,
      abhaId: abhaId ?? this.abhaId,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      familySynced: familySynced ?? this.familySynced,
      hospitalSynced: hospitalSynced ?? this.hospitalSynced,
    );
  }
}

