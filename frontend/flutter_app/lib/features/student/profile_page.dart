import 'package:flutter/material.dart';

import '../../models/student.dart';

const _subjectsByStream = <String, List<String>>{
  'Mathematics': [
    'Combined Mathematics',
    'Physics',
    'Chemistry',
    'Information & Communication Technology',
    'Higher Mathematics',
  ],
  'Science': [
    'Biology',
    'Chemistry',
    'Physics',
    'Agricultural Science',
    'Information & Communication Technology',
  ],
  'Commerce': [
    'Accounting',
    'Business Studies',
    'Economics',
    'Information & Communication Technology',
    'Business Statistics',
  ],
  'Arts': [
    'Sinhala',
    'Geography',
    'Political Science',
    'Logic & Scientific Method',
    'Economics',
    'Communication & Media Studies',
  ],
  'Technology': [
    'Engineering Technology',
    'Science for Technology',
    'Information & Communication Technology',
    'Economics',
    'Geography',
  ],
};

class _SubjectBatch {
  const _SubjectBatch({required this.stream, required this.results});

  final String stream;
  final List<SubjectResult> results;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.student,
    required this.onSave,
    required this.onLogout,
  });
  final Student student;
  final Future<void> Function(Student student) onSave;
  final Future<void> Function() onLogout;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _name = TextEditingController(
    text: widget.student.fullName,
  );
  late final TextEditingController _profileImage = TextEditingController(
    text: widget.student.profileImage ?? '',
  );
  late final TextEditingController _school = TextEditingController(
    text: widget.student.school,
  );
  late final TextEditingController _district = TextEditingController(
    text: widget.student.district,
  );
  late final TextEditingController _year = TextEditingController(
    text: widget.student.alYear?.toString() ?? '',
  );
  late String? _stream = widget.student.stream;
  final List<SubjectResult> _results = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _results.addAll(widget.student.alResults);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _profileImage,
      _school,
      _district,
      _year,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    widget.student.fullName = _name.text.trim();
    widget.student.profileImage = _profileImage.text.trim().isEmpty
        ? null
        : _profileImage.text.trim();
    widget.student.school = _school.text.trim();
    widget.student.district = _district.text.trim();
    widget.student.alYear = int.tryParse(_year.text.trim());
    widget.student.stream = _stream;
    widget.student.alResults = _results;
    try {
      await widget.onSave(widget.student);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved to MongoDB')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _profileInitial() => Text(
    _name.text.trim().isEmpty ? '?' : _name.text.trim()[0].toUpperCase(),
    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
  );

  Future<void> _addSubject() async {
    var selectedStream = _stream ?? 'Mathematics';
    final subjects = List<String?>.filled(3, null);
    final grades = List<String?>.filled(3, null);
    String? formError;

    final batch = await showDialog<_SubjectBatch>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add A/L results'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedStream,
                    decoration: const InputDecoration(
                      labelText: 'Main A/L stream',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    items: _subjectsByStream.keys
                        .map(
                          (stream) => DropdownMenuItem(
                            value: stream,
                            child: Text(stream),
                          ),
                        )
                        .toList(),
                    onChanged: (stream) {
                      if (stream == null) return;
                      setDialogState(() {
                        selectedStream = stream;
                        subjects.fillRange(0, subjects.length, null);
                        grades.fillRange(0, grades.length, null);
                        formError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Select 3 subjects and enter each grade',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(3, (index) {
                    final availableSubjects = _subjectsByStream[selectedStream]!
                        .where(
                          (subject) => !subjects.asMap().entries.any(
                            (entry) =>
                                entry.key != index && entry.value == subject,
                          ),
                        )
                        .toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: subjects[index],
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Subject ${index + 1}',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              items: availableSubjects
                                  .map(
                                    (subject) => DropdownMenuItem(
                                      value: subject,
                                      child: Text(
                                        subject,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (subject) => setDialogState(
                                () => subjects[index] = subject,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 92,
                            child: DropdownButtonFormField<String>(
                              initialValue: grades[index],
                              decoration: const InputDecoration(
                                labelText: 'Grade',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                              ),
                              items: const ['A', 'B', 'C', 'S', 'F']
                                  .map(
                                    (grade) => DropdownMenuItem(
                                      value: grade,
                                      child: Text(grade),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (grade) =>
                                  setDialogState(() => grades[index] = grade),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (formError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      formError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final complete = List.generate(
                  3,
                  (index) => subjects[index] != null && grades[index] != null,
                ).every((value) => value);
                final alreadyAdded = subjects.whereType<String>().any(
                  (subject) => _results.any(
                    (result) =>
                        result.name.toLowerCase() == subject.toLowerCase(),
                  ),
                );
                if (!complete) {
                  setDialogState(() {
                    formError = 'Choose a subject and grade for all 3 rows.';
                  });
                  return;
                }
                if (alreadyAdded) {
                  setDialogState(() {
                    formError = 'One or more subjects have already been added.';
                  });
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  _SubjectBatch(
                    stream: selectedStream,
                    results: List.generate(
                      3,
                      (index) => SubjectResult(
                        id: null,
                        name: subjects[index]!,
                        grade: grades[index]!,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add 3 subjects'),
            ),
          ],
        ),
      ),
    );
    if (batch != null && mounted) {
      setState(() {
        _stream = batch.stream;
        _results.addAll(batch.results);
      });
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final logout = widget.onLogout;
    Navigator.pop(context);
    await logout();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My profile')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFDBEAFE),
                  foregroundColor: const Color(0xFF3B82F6),
                  child: _profileImage.text.trim().isEmpty
                      ? _profileInitial()
                      : ClipOval(
                          child: Image.network(
                            _profileImage.text.trim(),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _profileInitial(),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name.text.isEmpty ? 'Your profile' : _name.text,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.student.email,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: widget.student.profileCompletion / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'PERSONAL INFORMATION',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _profileImage,
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Profile photo URL',
            hintText: 'https://example.com/photo.jpg',
            prefixIcon: Icon(Icons.image_outlined),
            helperText: 'Use a direct HTTPS link to an image.',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _school,
          decoration: const InputDecoration(labelText: 'School'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _district,
          decoration: const InputDecoration(labelText: 'District'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _year,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'A/L year'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _stream,
          decoration: const InputDecoration(labelText: 'A/L stream'),
          items:
              const ['Science', 'Mathematics', 'Commerce', 'Arts', 'Technology']
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          onChanged: (value) => setState(() => _stream = value),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'A/L RESULTS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addSubject,
              icon: const Icon(Icons.add),
              label: const Text('Add subject'),
            ),
          ],
        ),
        if (_results.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Add your subjects and grades to improve your profile.',
              ),
            ),
          ),
        ..._results.asMap().entries.map(
          (entry) => Card(
            child: ListTile(
              title: Text(entry.value.name),
              subtitle: Text('Grade ${entry.value.grade}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _results.removeAt(entry.key)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving...' : 'Save changes'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB42318),
            side: const BorderSide(color: Color(0xFFFDA29B)),
          ),
        ),
      ],
    ),
  );
}
