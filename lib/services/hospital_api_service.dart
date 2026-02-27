import 'dart:convert';
import 'package:http/http.dart' as http;

class HospitalApiService {
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  /// Fetch nearby hospitals from the backend.
  static Future<List<Hospital>> fetchNearby({String sortBy = 'distance'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hospitals/nearby?sort=$sortBy'),
      );

      if (response.statusCode != 200) {
        throw Exception('Backend returned ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['hospitals'] as List;
      return list.map((h) => Hospital.fromJson(h as Map<String, dynamic>)).toList();
    } catch (e) {
      // Return hardcoded fallback if backend is offline
      return _fallbackHospitals;
    }
  }

  static final _fallbackHospitals = [
    Hospital(
      id: 'hosp_001', name: 'Apollo Hospitals', type: 'Multi-Specialty',
      address: '21, Greams Lane, Chennai 600006', phone: '+91 44 2829 3333',
      emergencyPhone: '108', distanceKm: 1.2, driveMins: 4,
      specialties: ['Cardiology', 'Cardiac Surgery', 'Emergency Medicine'],
      erAvailable: true, ambulanceCount: 5, erBeds: 12,
      totalBeds: 600, availableBeds: 42, rating: 4.5, is24x7: true,
      accreditation: ['NABH', 'JCI'],
    ),
  ];
}

class Hospital {
  final String id;
  final String name;
  final String type;
  final String address;
  final String phone;
  final String emergencyPhone;
  final double distanceKm;
  final int driveMins;
  final List<String> specialties;
  final bool erAvailable;
  final int ambulanceCount;
  final int erBeds;
  final int totalBeds;
  final int availableBeds;
  final double rating;
  final bool is24x7;
  final List<String> accreditation;

  const Hospital({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.emergencyPhone,
    required this.distanceKm,
    required this.driveMins,
    required this.specialties,
    required this.erAvailable,
    required this.ambulanceCount,
    required this.erBeds,
    required this.totalBeds,
    required this.availableBeds,
    required this.rating,
    required this.is24x7,
    required this.accreditation,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    final distance = json['distance'] as Map<String, dynamic>;
    final emergency = json['emergency'] as Map<String, dynamic>;
    final beds = json['beds'] as Map<String, dynamic>;

    return Hospital(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      emergencyPhone: json['emergencyPhone'] as String,
      distanceKm: (distance['km'] as num).toDouble(),
      driveMins: (distance['driveMins'] as num).toInt(),
      specialties: (json['specialties'] as List).cast<String>(),
      erAvailable: emergency['available'] as bool,
      ambulanceCount: (emergency['ambulanceCount'] as num).toInt(),
      erBeds: (emergency['erBeds'] as num).toInt(),
      totalBeds: (beds['total'] as num).toInt(),
      availableBeds: (beds['available'] as num).toInt(),
      rating: (json['rating'] as num).toDouble(),
      is24x7: json['is24x7'] as bool,
      accreditation: (json['accreditation'] as List).cast<String>(),
    );
  }
}
