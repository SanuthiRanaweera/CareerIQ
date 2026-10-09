import '../models/group_message.dart';
import 'api_service.dart';

class GroupChatService {
  GroupChatService({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;

  Future<List<GroupMessage>> getMessages(String token) async {
    final response = await _api.request('GET', '/group-chat', token: token);
    final list =
        response['data'] as List? ?? response['messages'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(GroupMessage.fromJson)
        .toList();
  }

  Future<GroupMessage> sendMessage(String token, String message) async {
    final response = await _api.request(
      'POST',
      '/group-chat',
      token: token,
      body: {'message': message},
    );
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return GroupMessage.fromJson(data);
  }

  Future<GroupMessage> updateMessage(
    String token,
    String messageId,
    String newMessage,
  ) async {
    final response = await _api.request(
      'PUT',
      '/group-chat/$messageId',
      token: token,
      body: {'message': newMessage},
    );
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return GroupMessage.fromJson(data);
  }

  Future<void> deleteMessage(String token, String messageId) async {
    await _api.request('DELETE', '/group-chat/$messageId', token: token);
  }
}
