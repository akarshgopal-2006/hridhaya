import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, or 127.0.0.1 for web/desktop
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      };
    }
    return {
      'Content-Type': 'application/json',
    };
  }

  // ─── Chatbot ───
  static Future<Map<String, dynamic>> sendMessage(String text) async {
    const userId = 'mock_user_id';
    final response = await http.post(
      Uri.parse('$baseUrl/messages/send'),
      headers: await _getHeaders(),
      body: jsonEncode({'userId': userId, 'text': text}),
    );
    return jsonDecode(response.body);
  }

  // ─── Emergency: Safety Loop ───
  static Future<Map<String, dynamic>> triggerSafetyLoop() async {
    const userId = 'mock_user_id';
    final response = await http.post(
      Uri.parse('$baseUrl/emergency/safety-loop'),
      headers: await _getHeaders(),
      body: jsonEncode({'userId': userId}),
    );
    return jsonDecode(response.body);
  }

  // ─── Emergency: Post-Fall Timer ───
  static Future<Map<String, dynamic>> triggerPostFallTimer() async {
    const userId = 'mock_user_id';
    final response = await http.post(
      Uri.parse('$baseUrl/emergency/post-fall-timer'),
      headers: await _getHeaders(),
      body: jsonEncode({'userId': userId}),
    );
    return jsonDecode(response.body);
  }

  // ─── Emergency: Full SOS Dispatch ───
  static Future<Map<String, dynamic>> dispatchSos(double lat, double lng) async {
    const userId = 'mock_user_id';
    final response = await http.post(
      Uri.parse('$baseUrl/emergency/dispatch-sos'),
      headers: await _getHeaders(),
      body: jsonEncode({'userId': userId, 'lat': lat, 'lng': lng}),
    );
    return jsonDecode(response.body);
  }

  // ─── Emergency: Check Ambulance Availability ───
  static Future<Map<String, dynamic>> checkAmbulance(double lat, double lng) async {
    final response = await http.post(
      Uri.parse('$baseUrl/emergency/ambulance/check'),
      headers: await _getHeaders(),
      body: jsonEncode({'lat': lat, 'lng': lng}),
    );
    return jsonDecode(response.body);
  }

  // ─── Emergency: Dispatch Ambulance ───
  static Future<Map<String, dynamic>> dispatchAmbulance(double lat, double lng, String vehicleId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/emergency/ambulance/dispatch'),
      headers: await _getHeaders(),
      body: jsonEncode({'lat': lat, 'lng': lng, 'vehicleId': vehicleId}),
    );
    return jsonDecode(response.body);
  }

  // ─── Emergency: Doctor Consultation ───
  static Future<Map<String, dynamic>> doctorConsult({String context = 'general'}) async {
    const userId = 'mock_user_id';
    final response = await http.post(
      Uri.parse('$baseUrl/emergency/doctor-consult'),
      headers: await _getHeaders(),
      body: jsonEncode({'userId': userId, 'context': context}),
    );
    return jsonDecode(response.body);
  }

  // ─── Emergency: Bundle Medical Data ───
  static Future<Map<String, dynamic>> getMedicalData() async {
    const userId = 'mock_user_id';
    final response = await http.post(
      Uri.parse('$baseUrl/emergency/medical-data'),
      headers: await _getHeaders(),
      body: jsonEncode({'userId': userId}),
    );
    return jsonDecode(response.body);
  }
}
