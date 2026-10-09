import '../models/career.dart';
import 'api_service.dart';

/// API client for the Career module.
///
/// Wraps [ApiService] the same way `PersonalityService` and `StudentService`
/// do, so every screen in this module talks to one place instead of building
/// requests itself. Failures surface as [ApiException], which the screens
/// catch and show as an error message.
class CareerService {
  CareerService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  /// Careers list, optionally narrowed by a search term and a category.
  ///
  /// Both filters are applied by the backend so the list stays correct even
  /// when more careers exist than the screen has loaded.
  Future<List<Career>> getCareers(
    String token, {
    String search = '',
    String category = '',
  }) async {
    final query = <String, String>{};
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    if (category.trim().isNotEmpty) query['category'] = category.trim();

    final path = query.isEmpty
        ? '/careers'
        : '/careers?${query.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';

    final response = await _api.request('GET', path, token: token);
    return ((response['data'] as List?) ?? const [])
        .map((item) => Career.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Distinct category names, used to build the filter chips from real data
  /// rather than a hardcoded list that could drift out of date.
  Future<List<String>> getCategories(String token) async {
    final response = await _api.request(
      'GET',
      '/careers/categories',
      token: token,
    );
    return ((response['data'] as List?) ?? const [])
        .whereType<String>()
        .toList();
  }

  /// A single career with its full detail, including the pathway steps.
  Future<Career> getCareerById(String token, String id) async {
    final response = await _api.request('GET', '/careers/$id', token: token);
    return Career.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Creates a career. Admin only: a student token receives a 403, which
  /// arrives here as an [ApiException] carrying the server's message.
  Future<Career> createCareer(String token, Career career) async {
    final response = await _api.request(
      'POST',
      '/careers',
      token: token,
      body: career.toJson(),
    );
    return Career.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Updates an existing career. Admin only.
  Future<Career> updateCareer(String token, String id, Career career) async {
    final response = await _api.request(
      'PUT',
      '/careers/$id',
      token: token,
      body: career.toJson(),
    );
    return Career.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Deletes a career. Admin only. The confirmation dialog lives in the UI, so
  /// by the time this is called the deletion has already been confirmed.
  Future<void> deleteCareer(String token, String id) async {
    await _api.request('DELETE', '/careers/$id', token: token);
  }

  /// Ranks careers against a student's answers.
  ///
  /// The answers are passed as plain values and sent as a plain JSON object,
  /// exactly as the backend expects. When the Student module is ready these
  /// arguments can be filled from a real student profile instead of the
  /// recommendation form, without changing this method or the backend.
  Future<CareerRecommendationResult> recommend(
    String token, {
    String? stream,
    List<String> subjects = const [],
    List<String> interests = const [],
    String? personalityType,
    String? workStyle,
    int? limit,
  }) async {
    final body = <String, dynamic>{
      if (stream != null && stream.isNotEmpty) 'stream': stream,
      if (subjects.isNotEmpty) 'subjects': subjects,
      if (interests.isNotEmpty) 'interests': interests,
      if (personalityType != null && personalityType.isNotEmpty)
        'personalityType': personalityType,
      if (workStyle != null && workStyle.isNotEmpty) 'workStyle': workStyle,
      'limit': ?limit,
    };

    final response = await _api.request(
      'POST',
      '/careers/recommend',
      token: token,
      body: body,
    );
    return CareerRecommendationResult.fromJson(response);
  }
}
