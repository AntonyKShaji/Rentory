import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/notification_item.dart';
import '../models/property.dart';

class ApiService {
  ApiService({http.Client? client}) : _httpClient = client ?? http.Client();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  final http.Client _httpClient;
  static String? _accessToken;
  String get baseUrl => _resolveBaseUrls().first;

  List<String> _resolveBaseUrls() {
    if (_configuredBaseUrl.trim().isNotEmpty) {
      return [_configuredBaseUrl.trim()];
    }
    return const [
      'http://10.0.2.2:8000',
      'http://127.0.0.1:8000',
      'http://localhost:8000',
    ];
  }

  static void setAccessToken(String? token) {
    _accessToken = token;
  }

  Future<WebSocket> openChatSocket(String propertyId) async {
    final errors = <String>[];
    for (final candidate in _resolveBaseUrls()) {
      final uri = _buildWebSocketUri(candidate, '/properties/$propertyId/chat/ws');
      try {
        return await WebSocket.connect(uri.toString(), headers: _authHeaders()).timeout(const Duration(seconds: 12));
      } on SocketException catch (error) {
        errors.add('$candidate: ${error.message}');
      } on TimeoutException {
        errors.add('$candidate: request timed out');
      }
    }

    throw Exception('Unable to connect to chat server. Tried ${_resolveBaseUrls().join(', ')}. Errors: ${errors.join(' | ')}');
  }

  Future<bool> healthCheck() async {
    final response = await _get('/health');
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> ownerSignup({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/owners/signup', {
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'password': password,
    });
    if (response.statusCode != 201) {
      throw Exception('Owner signup failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> tenantRegister({
    required String qrCode,
    required String fullName,
    required int age,
    required String phone,
    required String email,
    required String documents,
    required String password,
  }) async {
    final response = await _post('/auth/tenants/register', {
      'qr_code': qrCode,
      'full_name': fullName,
      'age': age,
      'phone': phone,
      'email': email,
      'documents': documents,
      'password': password,
    });
    if (response.statusCode != 201) {
      throw Exception('Tenant registration failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    required String role,
  }) async {
    final response = await _post('/auth/login', {
      'identifier': identifier,
      'password': password,
      'role': role,
    });

    if (response.statusCode != 200) {
      throw Exception('Login failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }


  Future<Map<String, dynamic>> getOwnerProfile(String ownerId) async {
    final response = await _get('/owners/$ownerId/profile');
    if (response.statusCode != 200) {
      throw Exception('Failed to load owner profile (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Property>> listOwnerProperties(String ownerId) async {
    final response = await _get('/owners/$ownerId/properties');
    if (response.statusCode != 200) {
      throw Exception('Failed to load properties (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((item) => Property.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> ownerAnalytics(String ownerId) async {
    final response = await _get('/owners/$ownerId/analytics');
    if (response.statusCode != 200) {
      throw Exception('Failed to load analytics (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Property> createProperty({
    required String ownerId,
    required String location,
    required String name,
    required String unitType,
    required int capacity,
    required double rent,
    required String imageUrl,
    required String description,
    required bool isActive,
    int? areaSqft,
    String? parkingDetails,
    String? preferredResidents,
    required double advanceAmount,
    String? fullAddress,
    required bool caretakerEnabled,
    String? caretakerName,
    String? caretakerContact,
    String? propertyReference,
  }) async {
    final response = await _post('/owners/$ownerId/properties', {
      'location': location,
      'name': name,
      'unit_type': unitType,
      'capacity': capacity,
      'rent': rent,
      'image_url': imageUrl,
      'description': description,
      'is_active': isActive,
      'area_sqft': areaSqft,
      'parking_details': parkingDetails,
      'preferred_residents': preferredResidents,
      'advance_amount': advanceAmount,
      'full_address': fullAddress,
      'caretaker_enabled': caretakerEnabled,
      'caretaker_name': caretakerName,
      'caretaker_contact': caretakerContact,
      'property_reference': propertyReference,
    });

    if (response.statusCode != 201) {
      throw Exception('Failed to create property (${response.statusCode}): ${response.body}');
    }

    return Property.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Property> updateProperty({
    required String propertyId,
    required String location,
    required String name,
    required String unitType,
    required int capacity,
    required double rent,
    required String imageUrl,
    required String description,
    required bool isActive,
    int? areaSqft,
    String? parkingDetails,
    String? preferredResidents,
    required double advanceAmount,
    String? fullAddress,
    required bool caretakerEnabled,
    String? caretakerName,
    String? caretakerContact,
    String? propertyReference,
  }) async {
    final response = await _patch('/properties/$propertyId', {
      'location': location,
      'name': name,
      'unit_type': unitType,
      'capacity': capacity,
      'rent': rent,
      'image_url': imageUrl,
      'description': description,
      'is_active': isActive,
      'area_sqft': areaSqft,
      'parking_details': parkingDetails,
      'preferred_residents': preferredResidents,
      'advance_amount': advanceAmount,
      'full_address': fullAddress,
      'caretaker_enabled': caretakerEnabled,
      'caretaker_name': caretakerName,
      'caretaker_contact': caretakerContact,
      'property_reference': propertyReference,
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to update property (${response.statusCode}): ${response.body}');
    }

    return Property.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }



  Future<Map<String, dynamic>> getOwnerNotifications({
    required String ownerId,
    String? propertyId,
    String category = 'all',
    String? search,
  }) async {
    final query = <String, String>{'category': category};
    if (propertyId != null && propertyId.isNotEmpty) query['property_id'] = propertyId;
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    final response = await _get('/owners/$ownerId/notifications', query: query);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch notifications (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<NotificationItem>> listOwnerNotifications({
    required String ownerId,
    String? propertyId,
    String category = 'all',
    String? search,
  }) async {
    final payload = await getOwnerNotifications(
      ownerId: ownerId,
      propertyId: propertyId,
      category: category,
      search: search,
    );
    final items = (payload['items'] as List<dynamic>? ?? const []);
    return items.map((item) => NotificationItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<int> markOwnerNotificationsRead({required String ownerId, String? propertyId}) async {
    final query = <String, String>{};
    if (propertyId != null && propertyId.isNotEmpty) query['property_id'] = propertyId;
    final response = await _patch('/owners/$ownerId/notifications/mark-read', const {}, query: query);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark notifications read (${response.statusCode})');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['updated'] as int? ?? 0;
  }

  Future<Map<String, dynamic>> getPropertyDetails(String propertyId) async {
    final response = await _get('/properties/$propertyId');
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch property details (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTenantDetails(String tenantId) async {
    final response = await _get('/tenants/$tenantId');
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch tenant details (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTenantDashboard(String tenantId) async {
    final response = await _get('/tenants/$tenantId/dashboard');
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch tenant dashboard (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateWaterBillStatus({required String propertyId, required String status}) async {
    final response = await _patch('/properties/$propertyId/water-bill', {'status': status});
    if (response.statusCode != 200) {
      throw Exception('Failed to update water bill (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String propertyId) async {
    final response = await _get('/properties/$propertyId/chat');
    if (response.statusCode != 200) {
      throw Exception('Failed to load chat (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> sendChatMessage({
    required String propertyId,
    required String senderId,
    String? text,
    String? imageUrl,
  }) async {
    final response = await _post('/properties/$propertyId/chat', {
      'sender_id': senderId,
      'text': text,
      'image_url': imageUrl,
    });
    if (response.statusCode != 201) {
      throw Exception('Failed to send message (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }


  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Map<String, String> _authHeaders() {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      return {'Authorization': 'Bearer $_accessToken'};
    }
    return const {};
  }

  Uri _buildWebSocketUri(String baseUrl, String path) {
    final base = Uri.parse(baseUrl);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: wsScheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
      queryParameters: _accessToken == null || _accessToken!.isEmpty ? null : {'token': _accessToken!},
    );
  }

  Future<_ApiResponse> _get(String path, {Map<String, String>? query}) async {
    return _withBaseUrlFallback(
      path: path,
      query: query,
      perform: (uri) => _httpClient.get(uri, headers: _headers()),
    );
  }

  Future<_ApiResponse> _post(String path, Map<String, Object?> payload, {Map<String, String>? query}) async {
    return _withBaseUrlFallback(
      path: path,
      query: query,
      perform: (uri) => _httpClient.post(
        uri,
        headers: _headers(),
        body: jsonEncode(payload),
      ),
    );
  }

  Future<_ApiResponse> _patch(String path, Map<String, Object?> payload, {Map<String, String>? query}) async {
    return _withBaseUrlFallback(
      path: path,
      query: query,
      perform: (uri) => _httpClient.patch(
        uri,
        headers: _headers(),
        body: jsonEncode(payload),
      ),
    );
  }

  Future<_ApiResponse> _withBaseUrlFallback({
    required String path,
    Map<String, String>? query,
    required Future<http.Response> Function(Uri uri) perform,
  }) async {
    final errors = <String>[];
    for (final candidate in _resolveBaseUrls()) {
      final uri = Uri.parse('$candidate$path').replace(queryParameters: query == null || query.isEmpty ? null : query);
      try {
        final response = await perform(uri).timeout(const Duration(seconds: 12));
        return _ApiResponse(statusCode: response.statusCode, body: response.body);
      } on SocketException catch (error) {
        errors.add('$candidate: ${error.message}');
      } on TimeoutException {
        errors.add('$candidate: request timed out');
      }
    }

    throw Exception(
      'Unable to reach API server. Tried ${_resolveBaseUrls().join(', ')}. '
      'For a real phone, run with --dart-define=API_BASE_URL=http://<your-computer-lan-ip>:8000. '
      'Connection errors: ${errors.join(' | ')}',
    );
  }
}

class _ApiResponse {
  const _ApiResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
