import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: TextField(
          controller: controller,
          enabled: enabled,
          minLines: 1,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          onSubmitted: (_) => onSend(),
          decoration: const InputDecoration(
            hintText: 'Ask about careers, courses, or your next step...',
            prefixIcon: Icon(Icons.auto_awesome_outlined),
          ),
        ),
      ),
      const SizedBox(width: 10),
      IconButton.filled(
        onPressed: enabled ? onSend : null,
        tooltip: 'Send message',
        icon: const Icon(Icons.arrow_upward_rounded),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          minimumSize: const Size(54, 54),
        ),
      ),
    ],
  );
}
