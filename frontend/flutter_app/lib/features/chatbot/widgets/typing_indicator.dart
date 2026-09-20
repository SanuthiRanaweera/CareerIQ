import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 8, height: 8, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle))),
              SizedBox(width: 5),
              SizedBox(width: 8, height: 8, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF60A5FA), shape: BoxShape.circle))),
              SizedBox(width: 5),
              SizedBox(width: 8, height: 8, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF93C5FD), shape: BoxShape.circle))),
              SizedBox(width: 10),
              Text('CareerIQ AI is thinking...', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
