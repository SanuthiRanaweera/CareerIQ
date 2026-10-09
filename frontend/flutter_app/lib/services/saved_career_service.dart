import '../models/saved_career.dart';
import 'api_service.dart';

/// API client for the student's career shortlist (`/api/saved-careers`).
///
/// Every call works on the signed-in student's own shortlist. Failures surface
/// as [ApiException], which the screens catch and show as a message.
class SavedCareerService {
  SavedCareerService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  /// The shortlist, most important first. [priority] narrows it to one level.
  Future<List<SavedCareer>> getSavedCareers(
    String token, {
    String priority = '',
  }) async {
    final path = priority.isEmpty
        ? '/saved-careers'
        : '/saved-careers?priority=${Uri.encodeQueryComponent(priority)}';
    final response = await _api.request('GET', path, token: token);
    return ((response['data'] as List?) ?? const [])
        .map((item) => SavedCareer.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Adds a career to the shortlist.
  Future<SavedCareer> saveCareer(
    String token,
    String careerId, {
    String note = '',
    String priority = 'Medium',
  }) async {
    final response = await _api.request(
      'POST',
      '/saved-careers',
      token: token,
      body: {'careerId': careerId, 'note': note, 'priority': priority},
    );
    return SavedCareer.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Changes the note and priority of one shortlist entry.
  Future<SavedCareer> updateSavedCareer(
    String token,
    String id, {
    required String note,
    required String priority,
  }) async {
    final response = await _api.request(
      'PUT',
      '/saved-careers/$id',
      token: token,
      body: {'note': note, 'priority': priority},
    );
    return SavedCareer.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Removes one entry from the shortlist.
  Future<void> deleteSavedCareer(String token, String id) async {
    await _api.request('DELETE', '/saved-careers/$id', token: token);
  }
}
