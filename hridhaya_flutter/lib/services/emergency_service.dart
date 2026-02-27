import 'dart:async';
import 'api_service.dart';

class SosResult {
  final DateTime sentAt;
  final String incidentId;

  const SosResult({required this.sentAt, required this.incidentId});
}

class EmergencyService {
  Future<SosResult> sendSos({required String reason}) async {
    // ─── 1. Notify backend that Safety Loop has been triggered ───
    try {
      await ApiService.triggerSafetyLoop();
    } catch (e) {
      print('Safety loop backend notification failed: $e');
    }

    // ─── 2. If it's a fall, also trigger post-fall timer on backend ───
    if (reason.contains('thud') || reason.contains('fall')) {
      try {
        await ApiService.triggerPostFallTimer();
      } catch (e) {
        print('Post-fall timer backend notification failed: $e');
      }
    }

    // ─── 3. Full SOS Dispatch (SMS, calls, push notifications) ───
    String incidentId = 'INC-${DateTime.now().millisecondsSinceEpoch}';
    try {
      final sosResponse = await ApiService.dispatchSos(37.7749, -122.4194);
      incidentId = sosResponse['incidentId'] ?? incidentId;
    } catch (e) {
      print('SOS dispatch to backend failed: $e');
    }

    // ─── 4. Check Ambulance Availability ───
    try {
      final ambulanceInfo = await ApiService.checkAmbulance(37.7749, -122.4194);
      if (ambulanceInfo['available'] == true) {
        final vehicleId = ambulanceInfo['vehicle_id'] as String;
        // ─── 5. Dispatch Ambulance ───
        await ApiService.dispatchAmbulance(37.7749, -122.4194, vehicleId);
      }
    } catch (e) {
      print('Ambulance check/dispatch failed: $e');
    }

    // ─── 6. Bundle Medical Data for Paramedics ───
    try {
      await ApiService.getMedicalData();
    } catch (e) {
      print('Medical data bundle failed: $e');
    }

    // ─── 7. Generate Doctor Consultation Link ───
    try {
      await ApiService.doctorConsult(context: reason);
    } catch (e) {
      print('Doctor consult link creation failed: $e');
    }

    return SosResult(sentAt: DateTime.now(), incidentId: incidentId);
  }
}
