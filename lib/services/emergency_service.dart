import 'dart:async';

class SosResult {
  final DateTime sentAt;
  final String incidentId;

  const SosResult({required this.sentAt, required this.incidentId});
}

/// Offline-capable emergency service.
/// When a real backend is available, replace the stubs below with HTTP calls.
class EmergencyService {
  Future<SosResult> sendSos({required String reason}) async {
    // Simulate network latency for demo feel.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final incidentId = 'INC-${DateTime.now().millisecondsSinceEpoch}';
    return SosResult(sentAt: DateTime.now(), incidentId: incidentId);
  }
}
