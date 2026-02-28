import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotApiService {
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  /// Send a message to the chatbot and get an AI-powered reply.
  /// Falls back to offline demo if the backend is unavailable.
  static Future<ChatbotResponse> sendMessage({
    required String message,
    String sessionId = 'default',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chatbot/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'sessionId': sessionId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorJson['error'] ?? 'Backend error ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatbotResponse(
        reply: json['reply'] as String,
        fromApi: true,
      );
    } catch (e) {
      // Fallback to offline demo response
      return ChatbotResponse(
        reply: _getOfflineResponse(message),
        fromApi: false,
      );
    }
  }

  /// Simple keyword-based offline fallback.
  static String _getOfflineResponse(String message) {
    final lower = message.toLowerCase();

    const responses = <String, String>{
      'chest pain':
          'Chest pain can have many causes. If the pain is sharp, spreading to your arm or jaw, and you feel nauseous or short of breath, press the SOS button immediately. For mild discomfort, rest and monitor — but always consult a doctor.',
      'exercise':
          'Regular moderate exercise (150 min/week) strengthens your heart. Start slow and avoid pushing through chest pain. Walking, swimming and cycling are great cardiac-friendly choices.',
      'diet':
          'A heart-healthy diet includes fruits, vegetables, whole grains, lean proteins and healthy fats. Reduce sodium, sugar and processed foods. The Mediterranean diet is particularly beneficial.',
      'blood pressure':
          'Normal blood pressure is around 120/80 mmHg. High blood pressure (hypertension) often has no symptoms but damages arteries over time. Monitor regularly and consult your doctor about medication if needed.',
      'sos':
          'Press the SOS button if you experience sudden severe chest pain, difficulty breathing, sudden numbness or weakness, or if you witness someone collapse. The Safety Loop gives a 30-second countdown to confirm.',
      'stress':
          'Chronic stress raises cortisol levels, which can increase heart rate and blood pressure. Practice deep breathing, meditation, or yoga. Even 10 minutes of calm daily can help your heart.',
      'sleep':
          'Poor sleep (less than 6 hours) increases the risk of heart disease. Aim for 7–9 hours of quality sleep. Avoid caffeine late in the day and maintain a regular sleep schedule.',
      'smoking':
          'Smoking is a major risk factor for heart disease. It damages blood vessels, raises blood pressure and accelerates arteriosclerosis. Quitting — even after years — rapidly improves heart health.',
    };

    for (final entry in responses.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'I\'m currently in offline mode. I can answer about: chest pain, exercise, diet, blood pressure, SOS, stress, sleep, and smoking. Try asking about one of these topics! For full AI-powered responses, make sure the backend server is running.';
  }
}

class ChatbotResponse {
  final String reply;
  final bool fromApi;

  const ChatbotResponse({required this.reply, required this.fromApi});
}
