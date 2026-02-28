import 'dart:convert';
import 'package:http/http.dart' as http;

class FamilyApiService {
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  /// Fetch family members from the backend.
  static Future<List<FamilyMember>> fetchMembers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/family/members'),
      );

      if (response.statusCode != 200) {
        throw Exception('Backend returned ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['members'] as List;
      return list.map((m) => FamilyMember.fromJson(m as Map<String, dynamic>)).toList();
    } catch (e) {
      // Return fallback data if backend is offline
      return _fallbackMembers;
    }
  }

  static final _fallbackMembers = [
    FamilyMember(
      id: 'fam_001',
      name: 'Priya Sharma',
      relation: 'Mother',
      phone: '+91 98765 43210',
      locationLabel: 'Home – Anna Nagar',
      status: 'online',
      avatarColor: 0xFFE91E63,
      emergencyContact: true,
    ),
    FamilyMember(
      id: 'fam_002',
      name: 'Rajesh Sharma',
      relation: 'Father',
      phone: '+91 98765 43211',
      locationLabel: 'Office – T. Nagar',
      status: 'online',
      avatarColor: 0xFF1565C0,
      emergencyContact: true,
    ),
    FamilyMember(
      id: 'fam_003',
      name: 'Ananya Sharma',
      relation: 'Sister',
      phone: '+91 98765 43212',
      locationLabel: 'College – Guindy',
      status: 'away',
      avatarColor: 0xFF7B1FA2,
      emergencyContact: false,
    ),
    FamilyMember(
      id: 'fam_004',
      name: 'Dr. Kumar (Uncle)',
      relation: 'Uncle',
      phone: '+91 98765 43213',
      locationLabel: 'Kauvery Hospital',
      status: 'online',
      avatarColor: 0xFF00695C,
      emergencyContact: true,
    ),
  ];
}

class FamilyMember {
  final String id;
  final String name;
  final String relation;
  final String phone;
  final String locationLabel;
  final String status; // 'online', 'away', 'offline'
  final int avatarColor;
  final bool emergencyContact;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
    required this.locationLabel,
    required this.status,
    required this.avatarColor,
    required this.emergencyContact,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;
    final colorHex = json['avatarColor'] as String;
    // Parse hex color string like '#E91E63' → 0xFFE91E63
    final colorValue = int.parse('FF${colorHex.replaceFirst('#', '')}', radix: 16);

    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      relation: json['relation'] as String,
      phone: json['phone'] as String,
      locationLabel: location['label'] as String,
      status: json['status'] as String,
      avatarColor: colorValue,
      emergencyContact: json['emergencyContact'] as bool,
    );
  }
}
