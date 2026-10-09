import 'package:flutter/material.dart';

class UniversityStatusBadge extends StatelessWidget {
  const UniversityStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();
    Color bg;
    Color fg;
    Color dot;
    String label;

    if (s == 'active') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
      dot = const Color(0xFF10B981);
      label = 'Active';
    } else if (s == 'inactive') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
      dot = const Color(0xFFEF4444);
      label = 'Inactive';
    } else {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
      dot = const Color(0xFFF59E0B);
      label = 'Pending Verification';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dot.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
