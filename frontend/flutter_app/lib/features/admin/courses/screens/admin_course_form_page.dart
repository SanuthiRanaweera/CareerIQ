import 'package:flutter/material.dart';

import '../../../../models/course.dart';
import '../../../../services/course_service.dart';
import '../../university/models/admin_university_model.dart';
import '../../../career/widgets/editable_string_list.dart';

class AdminCourseFormPage extends StatefulWidget {
  const AdminCourseFormPage({
    super.key,
    required this.token,
    this.course,
    this.onSaved,
    required this.universities,
  });

  final String token;
  final Course? course;
  final void Function(Course course)? onSaved;
  final List<AdminUniversityModel> universities;

  @override
  State<AdminCourseFormPage> createState() => _AdminCourseFormPageState();
}

class _AdminCourseFormPageState extends State<AdminCourseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final CourseService _courseService = CourseService();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _uniCtrl;
  late final TextEditingController _degreeTypeCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _zScoreCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _applicationUrlCtrl;

  String? _selectedUniId;
  String _stream = 'Mathematics';
  List<String> _subjects = [];
  List<String> _careerPaths = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final course = widget.course;

    _titleCtrl = TextEditingController(text: course?.title ?? '');
    _uniCtrl = TextEditingController(text: course?.university ?? '');
    _degreeTypeCtrl = TextEditingController(text: course?.degreeType ?? "Bachelor's Degree");
    _durationCtrl = TextEditingController(text: course?.durationYears.toStringAsFixed(1) ?? '4.0');
    _zScoreCtrl = TextEditingController(
      text: course == null || course.minZScore == null || course.minZScore == 0
          ? ''
          : course.minZScore.toString(),
    );
    _descriptionCtrl = TextEditingController(text: course?.description ?? '');
    _websiteCtrl = TextEditingController(text: course?.website ?? '');
    _applicationUrlCtrl = TextEditingController(text: course?.applicationUrl ?? '');
    
    _stream = course?.stream ?? 'Mathematics';
    if (!['Mathematics', 'Science', 'Technology', 'Commerce', 'Arts', 'Any'].contains(_stream)) {
      _stream = 'Any';
    }
    
    if (course != null) {
      _subjects = List.of(course.subjects);
      _careerPaths = List.of(course.careerPaths);
    }

    _selectedUniId = course?.universityId;
    if (_selectedUniId == null && course != null && widget.universities.isNotEmpty) {
      final match = widget.universities.firstWhere(
        (u) => u.universityName.toLowerCase().trim() == course.university.toLowerCase().trim(),
        orElse: () => const AdminUniversityModel(
          id: '', userId: '', universityName: '', location: '', officialEmail: '',
          address: '', contactNumber: '', representativeName: '',
          representativeContactNumber: '', status: '',
        ),
      );
      if (match.id.isNotEmpty) _selectedUniId = match.id;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _uniCtrl.dispose();
    _degreeTypeCtrl.dispose();
    _durationCtrl.dispose();
    _zScoreCtrl.dispose();
    _descriptionCtrl.dispose();
    _websiteCtrl.dispose();
    _applicationUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final duration = double.tryParse(_durationCtrl.text);
    final zScore = _zScoreCtrl.text.trim().isEmpty ? null : double.tryParse(_zScoreCtrl.text);

    final values = {
      'title': _titleCtrl.text.trim(),
      'university': _uniCtrl.text.trim(),
      if (_selectedUniId != null && _selectedUniId!.isNotEmpty)
        'universityId': _selectedUniId,
      'stream': _stream,
      'degreeType': _degreeTypeCtrl.text.trim(),
      'durationYears': duration,
      'minZScore': zScore,
      'description': _descriptionCtrl.text.trim(),
      'subjects': _subjects,
      'careerPaths': _careerPaths,
      'website': _websiteCtrl.text.trim(),
      'applicationUrl': _applicationUrlCtrl.text.trim(),
    };

    try {
      final saved = widget.course == null
          ? await _courseService.create(widget.token, values)
          : await _courseService.update(widget.token, widget.course!.id, values);

      if (!mounted) return;
      widget.onSaved?.call(saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save course: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course == null ? 'Add Course' : 'Edit Course'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Degree Title *'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              if (widget.universities.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  value: widget.universities.any((u) => u.id == _selectedUniId)
                      ? _selectedUniId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Assign University (from Database)',
                  ),
                  hint: const Text('Select registered university'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Custom / Manual Entry'),
                    ),
                    ...widget.universities.map(
                      (u) => DropdownMenuItem<String?>(
                        value: u.id,
                        child: Text(
                          u.universityName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedUniId = val;
                      if (val != null) {
                        final found = widget.universities.firstWhere((u) => u.id == val);
                        _uniCtrl.text = found.universityName;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _uniCtrl,
                decoration: const InputDecoration(labelText: 'Awarding University Name *'),
                validator: (val) => val == null || val.trim().isEmpty ? 'University is required' : null,
                onChanged: (text) {
                  if (_selectedUniId != null) {
                    final found = widget.universities.where((u) => u.id == _selectedUniId).toList();
                    if (found.isEmpty || found.first.universityName != text) {
                      setState(() => _selectedUniId = null);
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _stream,
                decoration: const InputDecoration(labelText: 'A/L Stream *'),
                items: const [
                  'Mathematics',
                  'Science',
                  'Technology',
                  'Commerce',
                  'Arts',
                  'Any',
                ].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: (val) => setState(() => _stream = val ?? _stream),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _degreeTypeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Degree Type',
                  hintText: 'e.g. Bachelor\'s Degree',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Duration (Years) *'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        final num = double.tryParse(val);
                        if (num == null || num <= 0) return 'Invalid duration';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _zScoreCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Min Z-Score'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Description & Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              Text(
                'Lists',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'These are useful for career recommendations and matching.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              EditableStringList(
                label: 'Covered Subjects',
                values: _subjects,
                onChanged: (vals) => setState(() => _subjects = vals),
                hintText: 'Add a subject...',
              ),
              const SizedBox(height: 24),
              EditableStringList(
                label: 'Career Paths',
                values: _careerPaths,
                onChanged: (vals) => setState(() => _careerPaths = vals),
                hintText: 'Add a career path...',
              ),
              const SizedBox(height: 24),
              Text(
                'External Links',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteCtrl,
                decoration: const InputDecoration(labelText: 'Official Website URL'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _applicationUrlCtrl,
                decoration: const InputDecoration(labelText: 'Application URL'),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
