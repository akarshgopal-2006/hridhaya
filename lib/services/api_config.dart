import 'package:flutter/foundation.dart' show kIsWeb;

/// Central configuration for API endpoints.
///
/// On web: uses 127.0.0.1 (same machine).
/// On mobile: uses the computer's local network IP.
class ApiConfig {
  ApiConfig._();

  // ─── Change this to your computer's local IP ───
  // Find it with: ipconfig (Windows) or ifconfig (Mac/Linux)
  static const String _localNetworkIp = '172.20.25.194';

  /// Base URL for all API calls.
  /// Automatically switches between localhost (web) and LAN IP (mobile).
  static String get baseUrl {
    final host = kIsWeb ? '127.0.0.1' : _localNetworkIp;
    return 'http://$host:5000/api';
  }
}
