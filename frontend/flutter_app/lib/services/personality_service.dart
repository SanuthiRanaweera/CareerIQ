import '../models/personality_test.dart';
import 'api_service.dart';

class PersonalityService {
  PersonalityService({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;

  Future<
    ({
      List<PersonalityQuestion> questions,
      List<PersonalityAnswerOption> options,
    })
  >
  getQuestions(String token) async {
    Map<String, dynamic> response;
    try {
      response = await _api.request(
        'GET',
        '/personality-test/questions',
        token: token,
      );
    } catch (_) {
      response = await _api.request(
        'GET',
        '/personality/questions',
        token: token,
      );
    }

    final data = (response['data'] as Map<String, dynamic>?) ?? response;
    final questionsList = (data['questions'] as List?) ?? [];
    final optionsList = (data['options'] as List?) ?? [];

    final questions = questionsList
        .map((q) => PersonalityQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
    final options = optionsList
        .map((o) => PersonalityAnswerOption.fromJson(o as Map<String, dynamic>))
        .toList();

    return (questions: questions, options: options);
  }

  Future<PersonalityResult> submit(
    String token,
    String studentId,
    Map<String, String> answers,
  ) async {
    final body = {
      'studentId': studentId,
      'answers': answers.entries
          .map((entry) => {'questionId': entry.key, 'answer': entry.value})
          .toList(),
    };

    Map<String, dynamic> response;
    try {
      response = await _api.request(
        'POST',
        '/personality-test/submit',
        token: token,
        body: body,
      );
    } catch (_) {
      response = await _api.request(
        'POST',
        '/personality/submit',
        token: token,
        body: body,
      );
    }

    final data = (response['data'] ?? response['result'] ?? response)
        as Map<String, dynamic>;
    return PersonalityResult.fromJson(data);
  }

  Future<PersonalityResult?> getResult(String token, String studentId) async {
    try {
      Map<String, dynamic> response;
      try {
        response = await _api.request(
          'GET',
          '/personality-test/result/$studentId',
          token: token,
        );
      } catch (_) {
        response = await _api.request(
          'GET',
          '/personality/result/$studentId',
          token: token,
        );
      }

      final data = (response['data'] ?? response['result'])
          as Map<String, dynamic>?;
      if (data == null) return null;
      return PersonalityResult.fromJson(data);
    } on ApiException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(
    String token,
    String studentId,
  ) async {
    try {
      final response = await _api.request(
        'GET',
        '/personality-test/history/$studentId',
        token: token,
      );
      final list = (response['data'] as List?) ?? [];
      return list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
