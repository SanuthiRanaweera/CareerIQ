import '../models/course.dart';
import 'api_service.dart';

class CourseService {
  CourseService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<Course>> list({String search = '', String stream = 'All'}) async {
    final query = <String, String>{};
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    if (stream != 'All') query['stream'] = stream;
    final suffix = query.isEmpty
        ? ''
        : '?${query.entries.map((entry) => '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}').join('&')}';
    final response = await _api.request('GET', '/courses$suffix');
    return (response['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Course.fromJson)
        .toList();
  }

        Future<List<Course>> listAdmin(String token) async {
          final response = await _api.request('GET', '/courses/admin', token: token);
          return (response['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Course.fromJson)
          .toList();
        }

  Future<Course> get(String id) async {
    final response = await _api.request('GET', '/courses/${Uri.encodeComponent(id)}');
    return Course.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Course> create(String token, Map<String, dynamic> values) async {
    final response = await _api.request('POST', '/courses', token: token, body: values);
    return Course.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Course> update(String token, String id, Map<String, dynamic> values) async {
    final response = await _api.request('PUT', '/courses/${Uri.encodeComponent(id)}', token: token, body: values);
    return Course.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> archive(String token, String id) async {
    await _api.request('DELETE', '/courses/${Uri.encodeComponent(id)}', token: token);
  }
}