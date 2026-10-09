import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/course.dart';
import '../../../services/course_service.dart';

const _streams = [
  'All',
  'Mathematics',
  'Science',
  'Technology',
  'Commerce',
  'Arts',
];

class CourseCatalogPage extends StatefulWidget {
  const CourseCatalogPage({super.key, this.initialStream, this.initialSearch});

  final String? initialStream;

  /// Pre-fills the search box, e.g. a topic opened from a career's details.
  final String? initialSearch;

  @override
  State<CourseCatalogPage> createState() => _CourseCatalogPageState();
}

class _CourseCatalogPageState extends State<CourseCatalogPage> {
  final _service = CourseService();
  final _searchController = TextEditingController();
  Timer? _searchDelay;
  List<Course> _courses = const [];
  String _selectedStream = 'All';
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final stream = widget.initialStream;
    if (stream != null && _streams.contains(stream)) _selectedStream = stream;
    _searchController.text = widget.initialSearch ?? '';
    _loadCourses();
  }

  @override
  void dispose() {
    _searchDelay?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final courses = await _service.list(
        search: _searchController.text,
        stream: _selectedStream,
      );
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _searchChanged(String _) {
    _searchDelay?.cancel();
    _searchDelay = Timer(const Duration(milliseconds: 350), _loadCourses);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Course finder')),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find your next step',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(
                'Compare degree programmes by university and A/L stream.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: _searchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loadCourses(),
                decoration: InputDecoration(
                  hintText: 'Course, university, or career',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            _loadCourses();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _streams.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final stream = _streams[index];
                    return ChoiceChip(
                      label: Text(stream),
                      selected: _selectedStream == stream,
                      onSelected: (_) {
                        setState(() => _selectedStream = stream);
                        _loadCourses();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildResults()),
      ],
    ),
  );

  Widget _buildResults() {
    if (_loading && _courses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: Color(0xFF64748B),
              ),
              const SizedBox(height: 12),
              Text(
                'Courses could not be loaded',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadCourses,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_courses.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCourses,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'No courses found',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Try another stream or search term.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadCourses,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        itemCount: _courses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _CourseTile(
          course: _courses[index],
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => _CourseDetails(course: _courses[index]),
          ),
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFDBEAFE),
                  foregroundColor: Color(0xFF1D4ED8),
                  child: Icon(Icons.school_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.university,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CourseTag(
                  label: course.stream,
                  color: const Color(0xFFDBEAFE),
                  textColor: const Color(0xFF1D4ED8),
                ),
                _CourseTag(
                  label: '${_formatDuration(course.durationYears)} years',
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
          ],
        ),
      ),
    ),
  );
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

class _CourseDetails extends StatelessWidget {
  const _CourseDetails({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            course.university,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: const Color(0xFF2563EB)),
          ),
          const SizedBox(height: 18),
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
                label: '${_formatDuration(course.durationYears)} years',
                color: const Color(0xFFDCFCE7),
                textColor: const Color(0xFF166534),
              ),
            ],
          ),
          if (course.description.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'About this programme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            Text(
              course.description,
              style: Theme.of(context).textTheme.bodyLarge,
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
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(course.subjects.join('  ·  ')),
          ],
          if (course.careerPaths.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Possible career paths',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(course.careerPaths.join('  ·  ')),
          ],
          if (course.website.isNotEmpty ||
              course.applicationUrl.isNotEmpty) ...[
            const SizedBox(height: 24),
            SelectableText(
              course.applicationUrl.isNotEmpty
                  ? course.applicationUrl
                  : course.website,
            ),
          ],
        ],
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
      Icon(icon, color: const Color(0xFFD97706)),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
      Text(value),
    ],
  );
}

String _formatDuration(double years) => years == years.roundToDouble()
    ? years.toStringAsFixed(0)
    : years.toStringAsFixed(1);
