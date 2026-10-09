import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../models/scholarship_application_model.dart';
import '../models/scholarship_model.dart';

class UniversityScholarshipStats {
  const UniversityScholarshipStats({
    this.totalScholarships = 0,
    this.activeScholarships = 0,
    this.closedScholarships = 0,
    this.expiredScholarships = 0,
    this.totalApplications = 0,
    this.pendingApplications = 0,
  });

  final int totalScholarships;
  final int activeScholarships;
  final int closedScholarships;
  final int expiredScholarships;
  final int totalApplications;
  final int pendingApplications;

  factory UniversityScholarshipStats.fromJson(
    Map<String, dynamic> data,
  ) => UniversityScholarshipStats(
    totalScholarships: (data['totalScholarships'] as num?)?.toInt() ?? 0,
    activeScholarships: (data['activeScholarships'] as num?)?.toInt() ?? 0,
    closedScholarships: (data['closedScholarships'] as num?)?.toInt() ?? 0,
    expiredScholarships: (data['expiredScholarships'] as num?)?.toInt() ?? 0,
    totalApplications:
        (data['applicationsReceived'] as num?)?.toInt() ??
        (data['totalApplications'] as num?)?.toInt() ??
        0,
    pendingApplications: (data['pendingApplications'] as num?)?.toInt() ?? 0,
  );
}

class ScholarshipService {
  ScholarshipService({ApiService? api, AuthService? auth})
    : _api = api ?? ApiService(),
      _auth = auth ?? AuthService();

  final ApiService _api;
  final AuthService _auth;

  Future<String> _getToken([String? explicitToken]) async {
    if (explicitToken != null && explicitToken.isNotEmpty) {
      return explicitToken;
    }
    final stored = await _auth.token();
    if (stored == null || stored.isEmpty) {
      throw const ApiException('Authentication required. Please log in.');
    }
    return stored;
  }

  // ==================================================
  // UNIVERSITY SCHOLARSHIP APIs
  // ==================================================

  Future<ScholarshipModel> createScholarship(
    Map<String, dynamic> data, [
    String? token,
  ]) async {
    final effectiveToken = await _getToken(token);
    final response = await _api.request(
      'POST',
      '/university/scholarships',
      token: effectiveToken,
      body: data,
    );
    return ScholarshipModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<ScholarshipModel>> getUniversityScholarships({
    String? status,
    String? type,
    String? search,
    String? token,
  }) async {
    final effectiveToken = await _getToken(token);
    final params = <String>[];
    if (status != null &&
        status.isNotEmpty &&
        status != 'all' &&
        status != 'All') {
      params.add('status=${Uri.encodeComponent(status.toLowerCase())}');
    }
    if (type != null && type.isNotEmpty && type != 'all' && type != 'All') {
      params.add('type=${Uri.encodeComponent(type)}');
    }
    if (search != null && search.trim().isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search.trim())}');
    }

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await _api.request(
      'GET',
      '/university/scholarships$query',
      token: effectiveToken,
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((item) => ScholarshipModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UniversityScholarshipStats> getUniversityScholarshipStats([
    String? token,
  ]) async {
    final effectiveToken = await _getToken(token);
    final response = await _api.request(
      'GET',
      '/university/scholarships/statistics',
      token: effectiveToken,
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};
    return UniversityScholarshipStats.fromJson(data);
  }

  Future<UniversityScholarshipStats> getUniversityStats([String? token]) =>
      getUniversityScholarshipStats(token);

  Future<ScholarshipModel> getUniversityScholarshipById(
    String id, [
    String? token,
  ]) async {
    final effectiveToken = await _getToken(token);
    final response = await _api.request(
      'GET',
      '/university/scholarships/$id',
      token: effectiveToken,
    );
    return ScholarshipModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ScholarshipModel> updateScholarship(
    String id,
    Map<String, dynamic> data, [
    String? token,
  ]) async {
    final effectiveToken = await _getToken(token);
    final response = await _api.request(
      'PUT',
      '/university/scholarships/$id',
      token: effectiveToken,
      body: data,
    );
    return ScholarshipModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteScholarship(String id, [String? token]) async {
    final effectiveToken = await _getToken(token);
    await _api.request(
      'DELETE',
      '/university/scholarships/$id',
      token: effectiveToken,
    );
  }

  Future<ScholarshipModel> updateScholarshipStatus(
    String id,
    String status, [
    String? token,
  ]) async {
    final effectiveToken = await _getToken(token);
    final response = await _api.request(
      'PATCH',
      '/university/scholarships/$id/status',
      token: effectiveToken,
      body: {'status': status.toLowerCase().trim()},
    );
    return ScholarshipModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<ScholarshipApplicationModel>> getUniversityApplications({
    String? scholarshipId,
    String? status,
    String? token,
  }) async {
    final effectiveToken = await _getToken(token);
    final params = <String>[];
    if (scholarshipId != null && scholarshipId.isNotEmpty) {
      params.add('scholarshipId=${Uri.encodeComponent(scholarshipId)}');
    }
    if (status != null &&
        status.isNotEmpty &&
        status != 'all' &&
        status != 'All') {
      params.add(
        'status=${Uri.encodeComponent(status.toLowerCase().replaceAll(' ', '_'))}',
      );
    }

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await _api.request(
      'GET',
      '/university/applications$query',
      token: effectiveToken,
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map(
          (item) => ScholarshipApplicationModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<ScholarshipApplicationModel> getUniversityApplicationById(
    String id, [
    String? token,
  ]) async {
    final effectiveToken = await _getToken(token);
    final response = await _api.request(
      'GET',
      '/university/applications/$id',
      token: effectiveToken,
    );
    return ScholarshipApplicationModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<ScholarshipApplicationModel> updateApplicationStatus({
    required String applicationId,
    required String status,
    String? reviewNotes,
    String? token,
  }) async {
    final effectiveToken = await _getToken(token);
    final response = await _api.request(
      'PATCH',
      '/university/applications/$applicationId/status',
      token: effectiveToken,
      body: {
        'status': status.toLowerCase().replaceAll(' ', '_'),
        if (reviewNotes != null) 'reviewNotes': reviewNotes,
      },
    );
    return ScholarshipApplicationModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  // ==================================================
  // STUDENT SCHOLARSHIP APIs
  // ==================================================

  Future<List<ScholarshipModel>> getPublicScholarships({
    String? search,
    String? type,
    String? stream,
    String? universityId,
    String? token,
  }) async {
    final effectiveToken = await _getToken(token);
    final params = <String>[];
    if (search != null && search.trim().isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search.trim())}');
    }
    if (type != null && type.isNotEmpty && type != 'all' && type != 'All') {
      params.add('type=${Uri.encodeComponent(type)}');
    }
    if (stream != null &&
        stream.isNotEmpty &&
        stream != 'all' &&
        stream != 'All') {
      params.add('stream=${Uri.encodeComponent(stream)}');
    }
    if (universityId != null && universityId.isNotEmpty) {
      params.add('universityId=${Uri.encodeComponent(universityId)}');
    }

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await _api.request(
      'GET',
      '/scholarships$query',
      token: effectiveToken,
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((item) => ScholarshipModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ScholarshipModel>> listScholarships({
    String? search,
    String? scholarshipType,
    String? stream,
    String? universityId,
    String? token,
  }) => getPublicScholarships(
    search: search,
    type: scholarshipType,
    stream: stream,
    universityId: universityId,
    token: token,
  );

  Future<ScholarshipModel> getScholarshipDetails(
    String id, [
    String? token,
  ]) async {
    final effectiveToken = await _getToken(token);
    final response = await _api.request(
      'GET',
      '/scholarships/$id',
      token: effectiveToken,
    );
    return ScholarshipModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ScholarshipModel> getScholarshipById(String id, {String? token}) =>
      getScholarshipDetails(id, token);

  Future<ScholarshipApplicationModel> applyForScholarship({
    required String scholarshipId,
    required String personalStatement,
    required String careerGoal,
    String? additionalNotes,
    String? token,
  }) async {
    final effectiveToken = await _getToken(token);
    final response = await _api.request(
      'POST',
      '/scholarships/$scholarshipId/apply',
      token: effectiveToken,
      body: {
        'personalStatement': personalStatement,
        'careerGoal': careerGoal,
        if (additionalNotes != null && additionalNotes.isNotEmpty)
          'additionalInfo': additionalNotes,
      },
    );
    return ScholarshipApplicationModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<List<ScholarshipApplicationModel>> getMyApplications([
    String? token,
  ]) async {
    final effectiveToken = await _getToken(token);
    final response = await _api.request(
      'GET',
      '/student/scholarship-applications',
      token: effectiveToken,
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map(
          (item) => ScholarshipApplicationModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<ScholarshipApplicationModel>> getStudentApplications([
    String? token,
  ]) => getMyApplications(token);

  Future<ScholarshipApplicationModel> getMyApplicationById(
    String id, [
    String? token,
  ]) async {
    final effectiveToken = await _getToken(token);
    final response = await _api.request(
      'GET',
      '/student/scholarship-applications/$id',
      token: effectiveToken,
    );
    return ScholarshipApplicationModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }
}
