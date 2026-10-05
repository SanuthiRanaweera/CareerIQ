import '../models/app_notification.dart';
import 'api_service.dart';

class NotificationService {
  NotificationService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<AppNotification>> listMine(String token) async {
    final response = await _api.request('GET', '/notifications', token: token);
    return (response['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  Future<void> markRead(String token, String notificationId) async {
    await _api.request(
      'PATCH',
      '/notifications/$notificationId/read',
      token: token,
    );
  }

  Future<List<NotificationRecipient>> listRecipients(
    String token, {
    String search = '',
  }) async {
    final suffix = search.trim().isEmpty
        ? ''
        : '?search=${Uri.encodeQueryComponent(search.trim())}';
    final response = await _api.request(
      'GET',
      '/notifications/admin/students$suffix',
      token: token,
    );
    return (response['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(NotificationRecipient.fromJson)
        .toList();
  }

  Future<int> send({
    required String token,
    required String title,
    required String message,
    required bool toAll,
    List<String> studentIds = const [],
  }) async {
    final response = await _api.request(
      'POST',
      '/notifications/admin/send',
      token: token,
      body: {
        'title': title,
        'message': message,
        'recipientType': toAll ? 'all' : 'selected',
        if (!toAll) 'studentIds': studentIds,
      },
    );
    return (response['recipientCount'] as num?)?.toInt() ?? 0;
  }
}
