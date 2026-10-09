import 'package:flutter/material.dart';

import '../../../../models/course.dart';
import '../../../../models/student.dart';
import '../../../university/services/university_service.dart';

Future<void> showCourseDetailsModal(
  BuildContext context,
  Course course, {
  Student? student,
}) {
  if (course.universityId != null && course.universityId!.isNotEmpty) {
    UniversityService().trackEvent(
      eventType: 'course_view',
      universityId: course.universityId!,
      courseId: course.id,
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => CourseDetailsModal(course: course, student: student),
  );
}

class CourseDetailsModal extends StatelessWidget {
  const CourseDetailsModal({super.key, required this.course, this.student});

  final Course course;
  final Student? student;

  static String formatDuration(double years) => years == years.roundToDouble()
      ? years.toStringAsFixed(0)
      : years.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Academic eligibility checks
    final hasStudent = student != null;
    final studentStream = student?.stream ?? '';
    final studentZScore = student?.zScore;

    final isStreamEligible =
        !hasStudent ||
        course.stream.toLowerCase() == 'any' ||
        (studentStream.isNotEmpty &&
            course.stream.toLowerCase() == studentStream.toLowerCase());

    final hasZScore = course.minZScore != null;
    final isZScoreEligible =
        !hasZScore ||
        studentZScore == null ||
        studentZScore >= course.minZScore!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              course.university,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CourseTag(
                  label: course.degreeType,
                  color: const Color(0xFFE0F2FE),
                  textColor: const Color(0xFF075985),
                ),
                _CourseTag(
                  label: course.stream,
                  color: const Color(0xFFDBEAFE),
                  textColor: const Color(0xFF1D4ED8),
                ),
                _CourseTag(
                  label: '${formatDuration(course.durationYears)} years',
                  color: const Color(0xFFDCFCE7),
                  textColor: const Color(0xFF166534),
                ),
                if (course.minZScore != null)
                  _CourseTag(
                    label: 'Min Z ${course.minZScore!.toStringAsFixed(2)}',
                    color: const Color(0xFFFEF3C7),
                    textColor: const Color(0xFF92400E),
                  ),
              ],
            ),

            // Student Eligibility Feedback banner
            if (hasStudent) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isStreamEligible && isZScoreEligible
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isStreamEligible && isZScoreEligible
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isStreamEligible && isZScoreEligible
                              ? Icons.verified_user_rounded
                              : Icons.info_outline_rounded,
                          size: 18,
                          color: isStreamEligible && isZScoreEligible
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isStreamEligible && isZScoreEligible
                              ? 'Academic Eligibility: Likely Eligible'
                              : 'Academic Eligibility Check',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isStreamEligible && isZScoreEligible
                                ? const Color(0xFF166534)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isStreamEligible
                          ? '• A/L Stream: Matches your ${studentStream.isNotEmpty ? studentStream : "stream"} criteria.'
                          : '• A/L Stream: Course requires ${course.stream} (Your stream: $studentStream).',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                      ),
                    ),
                    if (course.minZScore != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        studentZScore != null
                            ? (studentZScore >= course.minZScore!
                                  ? '• Z-Score: Your score (${studentZScore.toStringAsFixed(2)}) meets the minimum requirement (${course.minZScore!.toStringAsFixed(2)}).'
                                  : '• Z-Score: Your score (${studentZScore.toStringAsFixed(2)}) is below the required cutoff (${course.minZScore!.toStringAsFixed(2)}).')
                            : '• Z-Score: Required cutoff is ${course.minZScore!.toStringAsFixed(2)}.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // About
            if (course.description.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                'About this programme',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                course.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF334155),
                  height: 1.5,
                ),
              ),
            ],

            if (course.minZScore != null) ...[
              const SizedBox(height: 18),
              _DetailLine(
                icon: Icons.stars_outlined,
                label: 'Minimum Z-score',
                value: course.minZScore!.toStringAsFixed(2),
              ),
            ],

            if (course.subjects.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Relevant subjects',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                course.subjects.join('  ·  '),
                style: const TextStyle(color: Color(0xFF475569)),
              ),
            ],

            if (course.careerPaths.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Possible career paths',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                course.careerPaths.join('  ·  '),
                style: const TextStyle(color: Color(0xFF475569)),
              ),
            ],

            if (course.website.isNotEmpty ||
                course.applicationUrl.isNotEmpty) ...[
              const SizedBox(height: 24),
              SelectableText(
                course.applicationUrl.isNotEmpty
                    ? course.applicationUrl
                    : course.website,
                style: const TextStyle(color: Color(0xFF2563EB)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CourseTag extends StatelessWidget {
  const _CourseTag({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFFD97706), size: 18),
      const SizedBox(width: 8),
      Text(
        '$label: ',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
        ),
      ),
      Text(value, style: const TextStyle(color: Color(0xFF475569))),
    ],
  );
}
