import 'dart:convert';
import 'package:http/http.dart' as http;

class StethoscopeApiService {
  // Use 10.0.2.2 for Android emulator, or 127.0.0.1 for web/desktop
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  /// Send captured gyroscope samples to the backend for analysis.
  ///
  /// [samples] — list of maps like { "timestamp": int, "x": double, "y": double, "z": double }
  /// [durationMs] — total capture duration in milliseconds
  ///
  /// Returns the parsed analysis report or throws on failure.
  static Future<StethoscopeReport> analyze({
    required List<Map<String, dynamic>> samples,
    required int durationMs,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stethoscope/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'samples': samples,
        'durationMs': durationMs,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Backend returned ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return StethoscopeReport.fromJson(json);
  }
}

// ─── Report Model ──────────────────────────────────────────────

class StethoscopeReport {
  final int bpm;
  final String heartRateClassification;
  final String rhythmRegularity;
  final int peaksDetected;
  final String signalQuality;
  final String riskLevel;
  final List<String> riskFactors;
  final String disclaimer;

  const StethoscopeReport({
    required this.bpm,
    required this.heartRateClassification,
    required this.rhythmRegularity,
    required this.peaksDetected,
    required this.signalQuality,
    required this.riskLevel,
    required this.riskFactors,
    required this.disclaimer,
  });

  factory StethoscopeReport.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>;
    final heartRate = analysis['heartRate'] as Map<String, dynamic>;
    final rhythm = analysis['rhythm'] as Map<String, dynamic>;
    final signal = analysis['signal'] as Map<String, dynamic>;
    final risk = analysis['risk'] as Map<String, dynamic>;

    return StethoscopeReport(
      bpm: heartRate['bpm'] as int,
      heartRateClassification: heartRate['classification'] as String,
      rhythmRegularity: rhythm['regularity'] as String,
      peaksDetected: rhythm['peaksDetected'] as int,
      signalQuality: signal['quality'] as String,
      riskLevel: risk['level'] as String,
      riskFactors: (risk['factors'] as List).cast<String>(),
      disclaimer: json['disclaimer'] as String,
    );
  }
}
