import 'dart:convert';
import 'dart:io';

import '../models/property.dart';

class ApiService {
  ApiService({HttpClient? httpClient}) : _httpClient = httpClient ?? HttpClient();

  // Android emulator: http://10.0.2.2:8000
  // iOS simulator / desktop: http://127.0.0.1:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  final HttpClient _httpClient;

  Future<bool> healthCheck() async {
    final response = await _get('/health');
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> login({required String identifier, required String otp}) async {
    final response = await _post('/auth/login', {'identifier': identifier, 'otp': otp});
    if (response.statusCode != 200) {
      throw Exception('Login failed (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Property>> listOwnerProperties(String ownerId) async {
    final response = await _get('/owners/$ownerId/properties');
    if (response.statusCode != 200) {
      throw Exception('Failed to load properties (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Property.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Property> createProperty({
    required String ownerId,
    required String location,
    required String name,
    required String unitType,
    required int capacity,
  }) async {
    final response = await _post(
      '/owners/$ownerId/properties',
      {
        'location': location,
        'name': name,
        'unit_type': unitType,
        'capacity': capacity,
      },
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create property (${response.statusCode})');
    }

    return Property.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getPropertyDetails(String propertyId) async {
    final response = await _get('/properties/$propertyId');
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch property details (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> requestTenantJoin({required String propertyId, required String tenantId}) async {
    final response = await _post('/properties/$propertyId/tenants/join-requests', {'tenant_id': tenantId});
    if (response.statusCode != 201) {
      throw Exception('Join request failed (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPayment({
    required String propertyId,
    required String tenantId,
    required String billType,
    required double amount,
  }) async {
    final response = await _post('/payments', {
      'property_id': propertyId,
      'tenant_id': tenantId,
      'bill_type': billType,
      'amount': amount,
    });
    if (response.statusCode != 201) {
      throw Exception('Payment failed (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendBroadcast({
    required String ownerId,
    required String title,
    required String body,
    List<String> propertyIds = const [],
  }) async {
    final response = await _post('/notifications/broadcast', {
      'owner_id': ownerId,
      'title': title,
      'body': body,
      'property_ids': propertyIds,
    });
    if (response.statusCode != 202) {
      throw Exception('Broadcast failed (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createMaintenance({
    required String propertyId,
    required String tenantId,
    required String issueTitle,
    String? issueDescription,
  }) async {
    final response = await _post('/maintenance-tickets', {
      'property_id': propertyId,
      'tenant_id': tenantId,
      'issue_title': issueTitle,
      'issue_description': issueDescription,
    });
    if (response.statusCode != 201) {
      throw Exception('Maintenance ticket failed (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<_ApiResponse> _get(String path) async {
    final request = await _httpClient.getUrl(Uri.parse('$baseUrl$path'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return _ApiResponse(statusCode: response.statusCode, body: body);
  }

  Future<_ApiResponse> _post(String path, Map<String, Object?> payload) async {
    final request = await _httpClient.postUrl(Uri.parse('$baseUrl$path'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(payload));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return _ApiResponse(statusCode: response.statusCode, body: body);
  }
}

class _ApiResponse {
  const _ApiResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
