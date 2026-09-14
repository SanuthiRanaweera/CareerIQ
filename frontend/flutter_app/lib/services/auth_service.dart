import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/student.dart';
import 'api_service.dart';

class AuthService {
  AuthService({ApiService? api, FlutterSecureStorage? storage})
    : _api = api ?? ApiService(),
      _storage = storage ?? const FlutterSecureStorage();

  final ApiService _api;
  final FlutterSecureStorage _storage;

  Future<void> register(Map<String, dynamic> payload) async {
    final response = await _api.request(
      'POST',
      '/auth/register',
      body: payload,
    );
    if (response['data'] == null)
      throw const ApiException('Registration did not complete');
  }

  Future<Student> login(String email, String password) async {
    final response = await _api.request(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    await _saveToken(response);
    return Student.fromJson(
      response['data']['student'] as Map<String, dynamic>,
    );
  }

  Future<void> verifyEmail(String email, String otp) async {
    await _api.request(
      'POST',
      '/auth/verify-email',
      body: {'email': email, 'otp': otp},
    );
  }

  Future<void> resendVerificationEmail(String email) async {
    await _api.request(
      'POST',
      '/auth/resend-verification',
      body: {'email': email},
    );
  }

  Future<String?> token() => _storage.read(key: 'career_iq_token');

  Future<void> logout() => _storage.delete(key: 'career_iq_token');

  Future<void> _saveToken(Map<String, dynamic> response) async {
    await _storage.write(
      key: 'career_iq_token',
      value: response['data']['token'] as String,
    );
  }
}
