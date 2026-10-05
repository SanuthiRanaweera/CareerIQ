import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _service = NotificationService();
  final _selectedStudentIds = <String>{};
  final _selectedStudents = <String, NotificationRecipient>{};
  Timer? _searchDebounce;
  List<NotificationRecipient> _recipients = const [];
  String? _token;
  String? _loadError;
  bool _toAll = true;
  bool _loadingRecipients = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients({String? search}) async {
    setState(() {
      _loadingRecipients = true;
      _loadError = null;
    });
    try {
      _token ??= await AuthService().token();
      if (_token == null) throw StateError('Please sign in again.');
      final recipients = await _service.listRecipients(
        _token!,
        search: search ?? _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _recipients = recipients;
        for (final recipient in recipients) {
          if (_selectedStudentIds.contains(recipient.id)) {
            _selectedStudents[recipient.id] = recipient;
          }
        }
        _loadingRecipients = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _loadingRecipients = false;
      });
    }
  }

  void _searchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _loadRecipients(search: value),
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_toAll && _selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one student.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      _token ??= await AuthService().token();
      if (_token == null) throw StateError('Please sign in again.');
      final recipientCount = await _service.send(
        token: _token!,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        toAll: _toAll,
        studentIds: _selectedStudentIds.toList(),
      );
      if (!mounted) return;
      _titleController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification sent to $recipientCount students.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send notification: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: ListView(
      key: const ValueKey('admin_notifications'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          'Send a notification',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 5),
        Text(
          'Share an update with all students or choose specific recipients.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        TextFormField(
          controller: _titleController,
          maxLength: 100,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'e.g. Application deadline reminder',
            prefixIcon: Icon(Icons.short_text_rounded),
            counterText: '',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter a notification title.'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _messageController,
          minLines: 4,
          maxLines: 6,
          maxLength: 2000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Message',
            hintText: 'Write the information students need to know.',
            alignLabelWithHint: true,
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter a message.' : null,
        ),
        const SizedBox(height: 8),
        Text('Recipients', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: true,
              icon: Icon(Icons.groups_outlined),
              label: Text('All students'),
            ),
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.person_search_outlined),
              label: Text('Selected'),
            ),
          ],
          selected: {_toAll},
          onSelectionChanged: (selection) =>
              setState(() => _toAll = selection.first),
        ),
        if (_toAll) ...[
          const SizedBox(height: 12),
          const _RecipientNote(
            icon: Icons.campaign_outlined,
            text: 'This will be delivered to every student account.',
          ),
        ] else ...[
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _searchChanged,
            decoration: InputDecoration(
              hintText: 'Find by name, email, or school',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        _loadRecipients(search: '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_selectedStudentIds.length} selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              TextButton(
                onPressed: _selectedStudentIds.isEmpty
                    ? null
                    : () => setState(() {
                        _selectedStudentIds.clear();
                        _selectedStudents.clear();
                      }),
                child: const Text('Clear'),
              ),
            ],
          ),
          _buildRecipientList(context),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _sending ? null : _send,
          icon: _sending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_sending ? 'Sending...' : 'Send notification'),
        ),
      ],
    ),
  );

  Widget _buildRecipientList(BuildContext context) {
    if (_loadingRecipients) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return _RecipientNote(
        icon: Icons.error_outline_rounded,
        text: _loadError!,
        action: TextButton(
          onPressed: _loadRecipients,
          child: const Text('Retry'),
        ),
      );
    }
    if (_recipients.isEmpty) {
      return const _RecipientNote(
        icon: Icons.person_off_outlined,
        text: 'No student accounts match this search.',
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _recipients.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 60),
        itemBuilder: (context, index) {
          final student = _recipients[index];
          return CheckboxListTile(
            value: _selectedStudentIds.contains(student.id),
            onChanged: (selected) => setState(() {
              if (selected == true) {
                _selectedStudentIds.add(student.id);
                _selectedStudents[student.id] = student;
              } else {
                _selectedStudentIds.remove(student.id);
                _selectedStudents.remove(student.id);
              }
            }),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              student.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                student.email,
                student.school,
              ].where((item) => item.isNotEmpty).join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }
}

class _RecipientNote extends StatelessWidget {
  const _RecipientNote({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F6FC),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF3478F6), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
        ?action,
      ],
    ),
  );
}
