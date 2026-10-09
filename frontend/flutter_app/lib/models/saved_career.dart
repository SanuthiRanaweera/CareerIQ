import 'career.dart';

/// Priorities a student can give a saved career, most important first.
/// Mirrors `PRIORITIES` in backend/models/SavedCareer.js.
const List<String> savedCareerPriorities = ['High', 'Medium', 'Low'];

/// One career on the student's shortlist, with their own note and priority.
class SavedCareer {
  const SavedCareer({
    required this.id,
    required this.career,
    this.note = '',
    this.priority = 'Medium',
  });

  factory SavedCareer.fromJson(Map<String, dynamic> json) => SavedCareer(
    id: json['_id'] as String? ?? '',
    career: Career.fromJson(
      (json['career'] as Map<String, dynamic>?) ?? const {},
    ),
    note: json['note'] as String? ?? '',
    priority: json['priority'] as String? ?? 'Medium',
  );

  final String id;
  final Career career;
  final String note;
  final String priority;
}
