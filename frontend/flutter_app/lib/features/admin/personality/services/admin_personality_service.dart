import '../../../../services/api_service.dart';
import '../../../../services/auth_service.dart';
import '../models/admin_personality_question.dart';

class AdminPersonalityService {
  AdminPersonalityService({ApiService? api, AuthService? auth})
      : _api = api ?? ApiService(),
        _auth = auth ?? AuthService();

  final ApiService _api;
  final AuthService _auth;

  Future<String> _getToken() async {
    final token = await _auth.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Admin authentication required');
    }
    return token;
  }

  Future<List<AdminPersonalityQuestion>> getQuestions({
    String? search,
    String? type,
    String? category,
    String? status,
  }) async {
    final token = await _getToken();
    final params = <String>[];
    if (search != null && search.trim().isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search.trim())}');
    }
    if (type != null && type.isNotEmpty && type != 'all') {
      params.add('type=${Uri.encodeComponent(type.toLowerCase())}');
    }
    if (category != null && category.isNotEmpty && category != 'all') {
      params.add('category=${Uri.encodeComponent(category.toLowerCase())}');
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      params.add('status=${Uri.encodeComponent(status.toLowerCase())}');
    }

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await _api.request(
      'GET',
      '/admin/personality-questions$query',
      token: token,
    );

    final list = (response['data'] ?? response['questions'] as List?) ?? [];
    return (list as List)
        .map((q) =>
            AdminPersonalityQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  Future<AdminPersonalityQuestion> createQuestion(
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final response = await _api.request(
      'POST',
      '/admin/personality-questions',
      token: token,
      body: data,
    );

    final resData = (response['data'] ?? response['question'])
        as Map<String, dynamic>;
    return AdminPersonalityQuestion.fromJson(resData);
  }

  Future<AdminPersonalityQuestion> updateQuestion(
    String id,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final response = await _api.request(
      'PUT',
      '/admin/personality-questions/$id',
      token: token,
      body: data,
    );

    final resData = (response['data'] ?? response['question'])
        as Map<String, dynamic>;
    return AdminPersonalityQuestion.fromJson(resData);
  }

  Future<bool> deleteQuestion(String id, {bool permanent = false}) async {
    final token = await _getToken();
    final response = await _api.request(
      'DELETE',
      '/admin/personality-questions/$id?permanent=$permanent',
      token: token,
    );
    return response['success'] == true;
  }

  Future<bool> toggleStatus(String id, bool isActive) async {
    final token = await _getToken();
    final response = await _api.request(
      'PATCH',
      '/admin/personality-questions/$id/status',
      token: token,
      body: {'isActive': isActive},
    );
    return response['success'] == true;
  }

  Future<AdminPersonalityAnalytics> getAnalytics() async {
    final token = await _getToken();
    final response = await _api.request(
      'GET',
      '/admin/personality-questions/analytics',
      token: token,
    );
    final data = (response['data'] ?? response) as Map<String, dynamic>;
    return AdminPersonalityAnalytics.fromJson(data);
  }

  Future<int> getQuestionsCount() async {
    try {
      final questions = await getQuestions();
      return questions.length;
    } catch (_) {
      return 0;
    }
  }
}

