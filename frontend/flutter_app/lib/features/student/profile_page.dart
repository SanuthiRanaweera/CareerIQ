import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/student.dart';

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
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
          _profileImage.clear();
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  static const List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=256&q=80',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=256&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=256&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=256&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=256&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=256&q=80',
  ];

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
    final name = TextEditingController();
    final grade = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            TextField(
              controller: grade,
              decoration: const InputDecoration(labelText: 'Grade'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isNotEmpty && grade.text.trim().isNotEmpty) {
                _results.add(
                  SubjectResult(
                    id: null,
                    name: name.text.trim(),
                    grade: grade.text.trim(),
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    name.dispose();
    grade.dispose();
    if (added == true && mounted) setState(() {});
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
                  child: _pickedImage != null
                      ? ClipOval(
                          child: Image.file(
                            _pickedImage!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        )
                      : (_profileImage.text.trim().isEmpty
                            ? _profileInitial()
                            : ClipOval(
                                child: Image.network(
                                  _profileImage.text.trim(),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _profileInitial(),
                                ),
                              )),
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _profileImage,
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Profile photo URL',
            hintText: 'https://example.com/photo.jpg',
            prefixIcon: const Icon(Icons.image_outlined),
            suffixIcon: _profileImage.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      setState(() {
                        _profileImage.clear();
                      });
                    },
                  )
                : null,
            helperText: 'Pick an avatar below or paste a direct image link.',
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final avatarUrl in _presetAvatars)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      setState(() {
                        if (_profileImage.text == avatarUrl) {
                          _profileImage.clear();
                        } else {
                          _profileImage.text = avatarUrl;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _profileImage.text == avatarUrl
                              ? const Color(0xFF3B82F6)
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFE2E8F0),
                        child: ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
