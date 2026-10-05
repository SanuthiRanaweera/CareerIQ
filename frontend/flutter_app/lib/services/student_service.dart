import '../models/student.dart';
import 'api_service.dart';

class StudentService {
  StudentService({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;

  Future<Student> getMe(String token) async {
    final response = await _api.request('GET', '/students/me', token: token);
    return Student.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Student> update(String token, Student student) async {
    final response = await _api.request(
      'PUT',
      '/students/${student.id}',
      token: token,
      body: student.toJson(),
    );
    return Student.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> toggleFavoriteUniversity(
    String token,
    String universityId,
  ) async {
    final response = await _api.request(
      'POST',
      '/students/favorites/universities/$universityId',
      token: token,
    );
    return response;
  }

  Future<List<String>> getFavoriteUniversityIds(String token) async {
    final response = await _api.request(
      'GET',
      '/students/favorites/universities',
      token: token,
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((item) =>
            item is Map ? (item['_id'] ?? item['id'] ?? '').toString() : item.toString())
        .where((id) => id.isNotEmpty)
        .toList();
  }
}
