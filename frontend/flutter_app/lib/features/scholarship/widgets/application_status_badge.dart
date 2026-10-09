import 'package:flutter/material.dart';

class ApplicationStatusBadge extends StatelessWidget {
  const ApplicationStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        border = const Color(0xFFA7F3D0);
        label = 'Approved';
        icon = Icons.check_circle_rounded;
        break;
      case 'shortlisted':
        bg = const Color(0xFFF5F3FF);
        fg = const Color(0xFF7C3AED);
        border = const Color(0xFFDDD6FE);
        label = 'Shortlisted';
        icon = Icons.star_rounded;
        break;
      case 'under_review':
      case 'under review':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        border = const Color(0xFFBFDBFE);
        label = 'Under Review';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'rejected':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        border = const Color(0xFFFECACA);
        label = 'Rejected';
        icon = Icons.cancel_rounded;
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        border = const Color(0xFFFDE68A);
        label = 'Pending';
        icon = Icons.access_time_rounded;
        break;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
