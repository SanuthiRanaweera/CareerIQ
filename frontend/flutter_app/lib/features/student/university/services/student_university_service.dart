import '../../../../models/course.dart';
import '../../../../services/api_service.dart';
import '../models/university_comparison_model.dart';

class StudentUniversityService {
  StudentUniversityService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<UniversityComparisonModel>> getUniversities({
    String? search,
    String? stream,
    String? type,
    required String token,
  }) async {
    final params = <String>[];
    if (search != null && search.trim().isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search.trim())}');
    }
    if (stream != null && stream.trim().isNotEmpty && stream != 'All') {
      params.add('stream=${Uri.encodeComponent(stream.trim())}');
    }
    if (type != null && type.trim().isNotEmpty && type != 'All') {
      params.add('type=${Uri.encodeComponent(type.trim())}');
    }

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await _api.request(
      'GET',
      '/universities$query',
      token: token,
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map(
          (item) =>
              UniversityComparisonModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<UniversityComparisonModel>> getCompareUniversities({
    required List<String> ids,
    required String token,
  }) async {
    if (ids.isEmpty) return [];

    final response = await _api.request(
      'GET',
      '/universities/compare?ids=${ids.join(',')}',
      token: token,
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final list = data['universities'] as List<dynamic>? ?? [];
    return list
        .map(
          (item) =>
              UniversityComparisonModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<UniversityComparisonModel> getUniversityDetails({
    required String id,
    required String token,
  }) async {
    final response = await _api.request(
      'GET',
      '/universities/$id',
      token: token,
    );

    final data = response['data'] as Map<String, dynamic>;
    return UniversityComparisonModel.fromJson(data);
  }

  Future<bool> toggleFavorite({
    required String universityId,
    required String token,
  }) async {
    final response = await _api.request(
      'POST',
      '/students/favorites/universities/$universityId',
      token: token,
    );
    return response['isFavorite'] as bool? ?? false;
  }

  Future<List<String>> getFavoriteIds({required String token}) async {
    final response = await _api.request(
      'GET',
      '/students/favorites/universities',
      token: token,
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map(
          (item) => item is Map
              ? (item['_id'] ?? item['id'] ?? '').toString()
              : item.toString(),
        )
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// Get real courses offered by a university from MongoDB
  Future<List<Course>> getUniversityCourses({
    required String universityId,
    required String token,
    String? search,
    String? stream,
  }) async {
    final params = <String>[];
    if (search != null && search.trim().isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search.trim())}');
    }
    if (stream != null && stream.trim().isNotEmpty && stream != 'All') {
      params.add('stream=${Uri.encodeComponent(stream.trim())}');
    }
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await _api.request(
      'GET',
      '/universities/$universityId/courses$query',
      token: token,
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((item) => Course.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
