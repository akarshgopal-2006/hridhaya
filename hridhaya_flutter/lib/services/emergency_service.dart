import 'dart:async';

class SosResult {
  final DateTime sentAt;
  final String incidentId;

  const SosResult({required this.sentAt, required this.incidentId});
}

class EmergencyService {
  Future<SosResult> sendSos({required String reason}) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return SosResult(
      sentAt: DateTime.now(),
      incidentId: 'INC-${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}

