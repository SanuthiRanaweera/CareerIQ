import 'package:flutter/material.dart';

class UniversityStatusBadge extends StatelessWidget {
  const UniversityStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  final String status;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();

    Color textColor;
    Color bgColor;
    String label;

    if (s == 'active') {
      textColor = const Color(0xFF16A34A);
      bgColor = const Color(0xFFDCFCE7);
      label = 'Active';
    } else if (s == 'inactive') {
      textColor = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEE2E2);
      label = 'Inactive';
    } else {
      textColor = const Color(0xFFD97706);
      bgColor = const Color(0xFFFEF3C7);
      label = 'Pending';
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

