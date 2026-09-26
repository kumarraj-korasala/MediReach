// ============================================================
// MediReach — Unified API Client
// Connects to Node.js Express Gateway (:5000) using dart:io
// ============================================================
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miracle/core/session/session_manager.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  // Cloudflare Tunnel URL (allows connection from any Wi-Fi, 4G, or 5G):
  static const String defaultHost = 'https://jeremy-hansen-uniprotkb-ebony.trycloudflare.com';
  static const String localWifiHost = '10.4.10.57';
  static const String emulatorHost = '10.0.2.2';

  // Supabase permanent cloud endpoint for dynamic backend tunnel auto-discovery:
  static const String _supabaseUrl = 'https://rzaakvleazhnulakooeu.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ6YWFrdmxlYXpobnVsYWtvb2V1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5MTY4NjMsImV4cCI6MjEwNTQ5Mjg2M30.A8ZQzTL4HNtaaFGVfSdguDFAoh8K575u4fj6iMfybUE';

  String? _customBaseUrl;
  String _serverHost = defaultHost;

  String get serverHost => _serverHost;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHost = prefs.getString('server_host');
      if (savedHost != null && savedHost.trim().isNotEmpty) {
        _serverHost = savedHost.trim();
      } else {
        _serverHost = defaultHost;
      }
    } catch (_) {}

    // Auto-discover latest live Cloudflare tunnel URL from Supabase config
    await autoDiscoverBackendUrl();
  }

  /// Queries Supabase to fetch the current active backend tunnel URL
  Future<String?> autoDiscoverBackendUrl() async {
    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/users?id=eq.system_config&select=password');
      final request = await _httpClient.getUrl(uri);
      request.headers.set('apikey', _supabaseAnonKey);
      request.headers.set('Authorization', 'Bearer $_supabaseAnonKey');
      final response = await request.close().timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final list = jsonDecode(body) as List<dynamic>;
        if (list.isNotEmpty && list.first['password'] != null) {
          final liveUrl = (list.first['password'] as String).trim();
          if (liveUrl.startsWith('http://') || liveUrl.startsWith('https://')) {
            _serverHost = liveUrl;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('server_host', liveUrl);
            return liveUrl;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> resetToDefault() async {
    _serverHost = defaultHost;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_host', defaultHost);
    } catch (_) {}
  }

  Future<void> updateServerHost(String host) async {
    _serverHost = host.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_host', _serverHost);
    } catch (_) {}
  }

  String get baseUrl {
    if (_customBaseUrl != null) return _customBaseUrl!;
    final host = _serverHost.trim();
    if (host.startsWith('http://') || host.startsWith('https://')) {
      final clean = host.replaceAll(RegExp(r'/+$'), '');
      return clean.endsWith('/api') ? clean : '$clean/api';
    }
    if (host.contains(':')) {
      return 'http://$host/api';
    }
    return 'http://$host:5000/api';
  }

  void setBaseUrl(String url) {
    _customBaseUrl = url;
  }

  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 4);

  Future<Map<String, String>> _getHeaders() async {
    final user = await SessionManager.instance.getSession();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (user != null) 'x-user-id': user.id,
      if (user != null) 'x-user-role': user.role.name,
    };
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = await _httpClient.getUrl(uri);

      final headers = await _getHeaders();
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      final response = await request.close().timeout(const Duration(seconds: 4));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': responseBody,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'isOffline': true};
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = await _httpClient.postUrl(uri);

      final headers = await _getHeaders();
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      final jsonPayload = utf8.encode(jsonEncode(body));
      request.add(jsonPayload);

      final response = await request.close().timeout(const Duration(seconds: 4));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': responseBody,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'isOffline': true};
    }
  }
}
