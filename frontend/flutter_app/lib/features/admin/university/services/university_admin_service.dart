import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/auth_service.dart';
import '../models/admin_university_model.dart';

class UniversityAdminService {
  UniversityAdminService({ApiService? api, AuthService? auth})
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

  // 1. GET ALL UNIVERSITIES
  Future<List<AdminUniversityModel>> getUniversities({
    String? search,
    String? status,
  }) async {
    final token = await _getToken();
    final queryParams = <String>[];
    if (search != null && search.trim().isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search.trim())}');
    }
    if (status != null && status.trim().isNotEmpty && status.toLowerCase() != 'all') {
      queryParams.add('status=${Uri.encodeComponent(status.trim().toLowerCase())}');
    }

    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final response = await _api.request(
      'GET',
      '/universities$queryString',
      token: token,
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((item) => AdminUniversityModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // 2. GET SINGLE UNIVERSITY BY ID
  Future<AdminUniversityModel> getUniversityById(String id) async {
    final token = await _getToken();
    final response = await _api.request(
      'GET',
      '/universities/$id',
      token: token,
    );
    return AdminUniversityModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  // 3. CREATE UNIVERSITY (triggers OTP email from backend)
  Future<Map<String, dynamic>> createUniversity(
      Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await _api.request(
      'POST',
      '/universities',
      token: token,
      body: data,
    );
    return response['data'] as Map<String, dynamic>? ?? response;
  }

  // 4. VERIFY UNIVERSITY REGISTRATION OTP
  Future<AdminUniversityModel> verifyUniversityOtp(
      Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await _api.request(
      'POST',
      '/universities/verify-otp',
      token: token,
      body: data,
    );
    return AdminUniversityModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  // 5. RESEND UNIVERSITY OTP
  Future<Map<String, dynamic>> resendUniversityOtp(
      Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await _api.request(
      'POST',
      '/universities/resend-otp',
      token: token,
      body: data,
    );
    return response['data'] as Map<String, dynamic>? ?? response;
  }

  // 6. UPDATE UNIVERSITY INFORMATION
  Future<AdminUniversityModel> updateUniversity(
    String id,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final response = await _api.request(
      'PUT',
      '/universities/$id',
      token: token,
      body: data,
    );
    return AdminUniversityModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  // 7. DELETE UNIVERSITY
  Future<void> deleteUniversity(String id) async {
    final token = await _getToken();
    await _api.request(
      'DELETE',
      '/universities/$id',
      token: token,
    );
  }

  // 8. UPDATE UNIVERSITY STATUS (Activate / Deactivate)
  Future<AdminUniversityModel> updateUniversityStatus(
    String id,
    String status,
  ) async {
    final token = await _getToken();
    final response = await _api.request(
      'PATCH',
      '/universities/$id/status',
      token: token,
      body: {'status': status.toLowerCase().trim()},
    );
    return AdminUniversityModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  // 9. GET REAL STATISTICS
  Future<AdminUniversityStats> getStatistics() async {
    final token = await _getToken();
    try {
      final response = await _api.request(
        'GET',
        '/universities/statistics',
        token: token,
      );
      if (response['data'] != null) {
        return AdminUniversityStats.fromJson(
            response['data'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback: calculate from list if statistics endpoint has issue
      final list = await getUniversities();
      return AdminUniversityStats(
        totalUniversities: list.length,
        activeUniversities: list.where((u) => u.isActive).length,
        inactiveUniversities: list.where((u) => u.status == 'inactive').length,
        pendingVerification: list.where((u) => u.isPending).length,
      );
    }
    return const AdminUniversityStats();
  }
}

