import '../models/group_message.dart';
import 'api_service.dart';

class GroupChatService {
  GroupChatService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<GroupMessage>> listMessages(String token) async {
    final response = await _api.request(
      'GET',
      '/group-chat/messages',
      token: token,
    );
    return (response['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GroupMessage.fromJson)
        .toList();
  }

  Future<GroupMessage> sendMessage(String token, String message) async {
    final response = await _api.request(
      'POST',
      '/group-chat/messages',
      token: token,
      body: {'message': message},
    );
    return GroupMessage.fromJson(response['data'] as Map<String, dynamic>);
  }
}
