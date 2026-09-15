import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

String get apiBaseUrl {
  const configuredUrl = String.fromEnvironment('API_BASE_URL');
  if (configuredUrl.isNotEmpty) return configuredUrl;
  if (kIsWeb) return 'http://localhost:3000/api';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000/api';
  return 'http://localhost:3000/api';
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiService {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final request = http.Request(method, Uri.parse('$apiBaseUrl$path'))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final response = await http.Client().send(request);
    final text = await response.stream.bytesToString();
    final data = text.isEmpty ? <String, dynamic>{} : jsonDecode(text) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['message'] as String? ?? 'Request failed');
    }
    return data;
  }
}
