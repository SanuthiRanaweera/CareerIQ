import 'package:flutter/material.dart';

class AnalyticsFilterBar extends StatelessWidget {
  const AnalyticsFilterBar({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  static const List<Map<String, String>> ranges = [
    {'key': '7d', 'label': '7 Days'},
    {'key': '30d', 'label': '30 Days'},
    {'key': '90d', 'label': '3 Months'},
    {'key': '1y', 'label': '1 Year'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: ranges.map((r) {
          final isSelected = r['key'] == selectedRange;
          return Expanded(
            child: InkWell(
              onTap: () => onRangeChanged(r['key']!),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  r['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
