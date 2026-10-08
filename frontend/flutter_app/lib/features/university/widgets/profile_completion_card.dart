import 'package:flutter/material.dart';

class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({
    super.key,
    required this.completionPercentage,
    required this.completedFields,
    required this.totalFields,
    required this.onCompleteProfile,
  });

  final int completionPercentage;
  final int completedFields;
  final int totalFields;
  final VoidCallback onCompleteProfile;

  @override
  Widget build(BuildContext context) {
    final isComplete = completionPercentage >= 100;
    final progress = (completionPercentage / 100).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'University Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isComplete ? 'Complete' : '$completionPercentage%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isComplete
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Completion',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                Text(
                  '$completionPercentage% ($completedFields of $totalFields fields)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete
                      ? const Color(0xFF10B981)
                      : const Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isComplete
                  ? 'Your university profile is completely filled out.'
                  : 'Complete your profile to improve your university presence and attract students.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCompleteProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: isComplete
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  isComplete ? Icons.edit_outlined : Icons.check_circle_outline,
                  size: 18,
                ),
                label: Text(
                  isComplete ? 'Edit Profile' : 'Complete Profile',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

