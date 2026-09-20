import '../../../services/api_service.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.mode,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['_id'] as String? ?? '${json['sender']}-${json['createdAt']}',
        sender: json['sender'] as String? ?? 'ai',
        message: json['message'] as String? ?? '',
        mode: json['mode'] as String? ?? 'general',
        createdAt: json['createdAt'] as String?,
      );

  final String id;
  final String sender;
  final String message;
  final String mode;
  final String? createdAt;

  bool get isStudent => sender == 'student';
}

class ChatbotService {
  ChatbotService({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;

  Future<List<ChatMessage>> history(String token) async {
    final response = await _api.request('GET', '/chatbot/history', token: token);
    return (response['data'] as List? ?? const [])
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> send(
    String token,
    String message, {
    String mode = 'general',
  }) async {
    final response = await _api.request(
      'POST',
      '/chatbot/messages',
      token: token,
      body: {'message': message, 'mode': mode},
    );
    final data = response['data'] as Map<String, dynamic>;
    return ChatMessage.fromJson({
      '_id': 'ai-${DateTime.now().microsecondsSinceEpoch}',
      'sender': 'ai',
      'message': data['message'],
      'mode': data['mode'],
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
