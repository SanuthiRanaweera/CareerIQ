import 'package:flutter/material.dart';

import '../../models/student.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.student, required this.onSave});
  final Student student;
  final Future<void> Function(Student student) onSave;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _name = TextEditingController(text: widget.student.fullName);
  late final TextEditingController _school = TextEditingController(text: widget.student.school);
  late final TextEditingController _district = TextEditingController(text: widget.student.district);
  late final TextEditingController _year = TextEditingController(text: widget.student.alYear?.toString() ?? '');
  late String? _stream = widget.student.stream;
  final List<SubjectResult> _results = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _results.addAll(widget.student.alResults);
  }

  @override
  void dispose() { for (final controller in [_name, _school, _district, _year]) { controller.dispose(); } super.dispose(); }

  Future<void> _save() async {
    setState(() => _saving = true);
    widget.student.fullName = _name.text.trim(); widget.student.school = _school.text.trim(); widget.student.district = _district.text.trim(); widget.student.alYear = int.tryParse(_year.text.trim()); widget.student.stream = _stream; widget.student.alResults = _results;
    try { await widget.onSave(widget.student); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved to MongoDB'))); } finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _addSubject() async {
    final name = TextEditingController(); final grade = TextEditingController();
    final added = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Add subject'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Subject')), TextField(controller: grade, decoration: const InputDecoration(labelText: 'Grade'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (name.text.trim().isNotEmpty && grade.text.trim().isNotEmpty) { _results.add(SubjectResult(id: null, name: name.text.trim(), grade: grade.text.trim())); Navigator.pop(context, true); } }, child: const Text('Add'))]));
    name.dispose(); grade.dispose(); if (added == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('My profile')), body: ListView(padding: const EdgeInsets.all(20), children: [
    Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [CircleAvatar(radius: 30, child: Text(_name.text.isEmpty ? '?' : _name.text[0].toUpperCase())), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_name.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(widget.student.email)]))]))), const SizedBox(height: 16),
    const Text('Personal information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
    TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')), const SizedBox(height: 12), TextField(controller: _school, decoration: const InputDecoration(labelText: 'School')), const SizedBox(height: 12), TextField(controller: _district, decoration: const InputDecoration(labelText: 'District')), const SizedBox(height: 12), TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'A/L year')), const SizedBox(height: 12),
    DropdownButtonFormField<String>(initialValue: _stream, decoration: const InputDecoration(labelText: 'A/L stream'), items: const ['Science', 'Mathematics', 'Commerce', 'Arts', 'Technology'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setState(() => _stream = value)), const SizedBox(height: 24),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('A/L results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), TextButton.icon(onPressed: _addSubject, icon: const Icon(Icons.add), label: const Text('Add subject'))]),
    if (_results.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Add your subjects and grades to improve your profile.'))),
    ..._results.asMap().entries.map((entry) => Card(child: ListTile(title: Text(entry.value.name), subtitle: Text('Grade ${entry.value.grade}'), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _results.removeAt(entry.key))))),),
    const SizedBox(height: 20), FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save changes')),
  ]));
}
