import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/auth_service.dart';

import '../models/university_dashboard_data.dart';

class UniversityService {
  UniversityService({ApiService? api, AuthService? auth})
      : _api = api ?? ApiService(),
        _auth = auth ?? AuthService();

  final ApiService _api;
  final AuthService _auth;

  Future<String> _getToken() async {
    final token = await _auth.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Authentication required. Please log in again.');
    }
    return token;
  }

  /// Get the dynamic dashboard data (Profile, Statistics, Notifications, Activity)
  Future<UniversityDashboardData> getUniversityDashboard() async {
    final token = await _getToken();
    final response = await _api.request(
      'GET',
      '/university/dashboard',
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return UniversityDashboardData.fromJson(data);
  }

  /// Get currently authenticated university profile
  Future<UniversityProfileModel> getUniversityProfile() async {
    final token = await _getToken();
    final response = await _api.request(
      'GET',
      '/university/profile',
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return UniversityProfileModel.fromJson(data);
  }

  /// Update editable university profile fields
  Future<UniversityProfileModel> updateUniversityProfile(
    Map<String, dynamic> payload,
  ) async {
    final token = await _getToken();
    final response = await _api.request(
      'PUT',
      '/university/profile',
      token: token,
      body: payload,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return UniversityProfileModel.fromJson(data);
  }

  /// Get courses associated with this university
  Future<List<UniversityCourseItem>> getUniversityCourses() async {
    final token = await _getToken();
    final response = await _api.request(
      'GET',
      '/university/courses',
      token: token,
    );
    final list = response['data'] as List? ?? [];
    return list
        .map((c) => UniversityCourseItem.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// University login (initiates OTP flow if enabled)
  Future<Map<String, dynamic>> login(String email, String password) =>
      _auth.universityLogin(email, password);

  /// Verify 6-digit university login OTP
  Future<Map<String, dynamic>> verifyLoginOtp(String email, String otp) =>
      _auth.verifyUniversityLoginOtp(email, otp);

  /// Resend 6-digit login OTP
  Future<void> resendLoginOtp(String email) =>
      _auth.resendUniversityLoginOtp(email);

  /// University logout
  Future<void> logout() => _auth.logout();
}

