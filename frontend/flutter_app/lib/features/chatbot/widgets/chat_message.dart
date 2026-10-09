import 'package:flutter/material.dart';

import '../services/chatbot_service.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: message.isStudent
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: message.isStudent ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isStudent ? 18 : 5),
            bottomRight: Radius.circular(message.isStudent ? 5 : 18),
          ),
          border: message.isStudent
              ? null
              : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A1F2937),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message.message,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: message.isStudent ? Colors.white : const Color(0xFF1F2937),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
