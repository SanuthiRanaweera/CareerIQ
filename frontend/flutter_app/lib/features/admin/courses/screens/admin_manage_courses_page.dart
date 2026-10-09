import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../models/course.dart';
import '../../../../services/course_service.dart';
import '../../university/models/admin_university_model.dart';
import 'admin_course_form_page.dart';

class AdminManageCoursesPage extends StatefulWidget {
  const AdminManageCoursesPage({
    super.key,
    required this.token,
    this.embedded = false,
    this.onCountChanged,
    required this.universities,
  });

  final String token;
  final bool embedded;
  final ValueChanged<int>? onCountChanged;
  final List<AdminUniversityModel> universities;

  @override
  State<AdminManageCoursesPage> createState() => _AdminManageCoursesPageState();
}

class _AdminManageCoursesPageState extends State<AdminManageCoursesPage> {
  final CourseService _courseService = CourseService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _initialLoading = true;
  bool _filtering = false;
  List<Course> _courses = [];
  Timer? _debounce;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;
    setState(() {
      if (_courses.isEmpty) _initialLoading = true;
      else _filtering = true;
    });

    try {
      final courses = await _courseService.listAdmin(widget.token);
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _initialLoading = false;
        _filtering = false;
      });
      widget.onCountChanged?.call(courses.length);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _filtering = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load courses: $e')),
      );
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _filtering = true);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _filtering = false);
    });
  }

  Future<void> _deleteCourse(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text('Delete "${course.title}"? It will no longer be visible to students.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              minimumSize: const Size(100, 44),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deletingId = course.id);
    try {
      await _courseService.archive(widget.token, course.id);
      if (!mounted) return;
      setState(() => _deletingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${course.title} deleted')),
      );
      await _loadCourses();
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete course: $e')),
      );
    }
  }

  void _openCourseForm({Course? course}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCourseFormPage(
          token: widget.token,
          course: course,
          universities: widget.universities,
          onSaved: (saved) {
            Navigator.pop(context);
            _loadCourses();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: widget.embedded ? Colors.white : null,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📚 Courses Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!widget.embedded)
                      Text(
                        '${_courses.length} degree programs cataloged',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openCourseForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Course'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(130, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search courses by title, stream, or university...',
              prefixIcon: Icon(Icons.search_rounded),
              fillColor: Color(0xFFF1F5F9),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _courses.where((c) {
      return query.isEmpty ||
          c.title.toLowerCase().contains(query) ||
          c.university.toLowerCase().contains(query) ||
          c.stream.toLowerCase().contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No courses found. Add a course to start the catalog.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final course = filtered[index];
        final deleting = _deletingId == course.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: widget.embedded ? 0 : null,
          shape: widget.embedded
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        course.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.stream,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    if (deleting)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else ...[
                      IconButton(
                        tooltip: 'Edit course',
                        onPressed: () => _openCourseForm(course: course),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete course',
                        onPressed: () => _deleteCourse(course),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  course.university,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${course.durationYears.toStringAsFixed(0)} Years Duration',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (course.minZScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Min Z-Score: ${course.minZScore}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Manage courses')),
      body: SafeArea(
        child: _initialLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(context),
                  SizedBox(
                    height: 3,
                    child: _filtering ? const LinearProgressIndicator(minHeight: 3) : null,
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadCourses,
                      child: _buildResults(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
