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
    final response = await _api.request(
      'GET',
      '/personality/questions',
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>;
    final questions = (data['questions'] as List)
        .map((q) => PersonalityQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
    final options = (data['options'] as List)
        .map((o) => PersonalityAnswerOption.fromJson(o as Map<String, dynamic>))
        .toList();
    return (questions: questions, options: options);
  }

  Future<PersonalityResult> submit(
    String token,
    String studentId,
    Map<String, String> answers,
  ) async {
    final response = await _api.request(
      'POST',
      '/personality/submit',
      token: token,
      body: {
        'studentId': studentId,
        'answers': answers.entries
            .map((entry) => {'questionId': entry.key, 'answer': entry.value})
            .toList(),
      },
    );
    return PersonalityResult.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<PersonalityResult?> getResult(String token, String studentId) async {
    try {
      final response = await _api.request(
        'GET',
        '/personality/result/$studentId',
        token: token,
      );
      return PersonalityResult.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    } on ApiException {
      return null;
    }
  }
}
