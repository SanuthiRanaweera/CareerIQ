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
}
