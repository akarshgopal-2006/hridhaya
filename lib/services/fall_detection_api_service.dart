import 'dart:convert';
import 'package:http/http.dart' as http;

import 'fall_detection_service.dart';

class FallDetectionApiService {
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  /// Report a detected fall event to the backend.
  ///
  /// Returns the incident ID and severity, or null if the report fails.
  static Future<FallIncidentResponse?> reportFall({
    required FallEvent event,
    String? abhaId,
    String? bloodGroup,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fall-detection/report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fallEvent': event.toJson(),
          'userSettings': {
            'abhaId': abhaId ?? 'Unknown',
            'bloodGroup': bloodGroup ?? 'Unknown',
          },
        }),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return FallIncidentResponse.fromJson(json);
    } catch (_) {
      // Backend might be offline — fall detection still works locally
      return null;
    }
  }
}

class FallIncidentResponse {
  final String incidentId;
  final String severity;
  final String message;
  final List<FallAction> actions;

  const FallIncidentResponse({
    required this.incidentId,
    required this.severity,
    required this.message,
    required this.actions,
  });

  factory FallIncidentResponse.fromJson(Map<String, dynamic> json) {
    final actionsList = (json['actions'] as List)
        .map((a) => FallAction(
              action: a['action'] as String,
              detail: a['detail'] as String,
            ))
        .toList();

    return FallIncidentResponse(
      incidentId: json['incidentId'] as String,
      severity: json['severity'] as String,
      message: json['message'] as String,
      actions: actionsList,
    );
  }
}

class FallAction {
  final String action;
  final String detail;

  const FallAction({required this.action, required this.detail});
}
