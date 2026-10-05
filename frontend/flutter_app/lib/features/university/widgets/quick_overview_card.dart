import 'package:flutter/material.dart';

class QuickOverviewCard extends StatelessWidget {
  const QuickOverviewCard({
    super.key,
    required this.completionPercentage,
    required this.courseCount,
    required this.status,
    required this.onCoursesTap,
    required this.onProfileTap,
  });

  final int completionPercentage;
  final int courseCount;
  final String status;
  final VoidCallback onCoursesTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                title: 'Profile',
                value: '$completionPercentage%',
                subtext: 'Completed',
                icon: Icons.person_outline_rounded,
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                onTap: onProfileTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricItem(
                title: 'Courses',
                value: courseCount > 0 ? '$courseCount' : '0',
                subtext: courseCount > 0 ? 'Associated' : 'None yet',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF0EA5E9),
                bgColor: const Color(0xFFF0F9FF),
                onTap: onCoursesTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

