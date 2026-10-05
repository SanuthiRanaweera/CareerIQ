import 'package:flutter/material.dart';

import '../../../models/app_notification.dart';
import '../../../services/notification_service.dart';

class StudentNotificationsSheet extends StatefulWidget {
  const StudentNotificationsSheet({super.key, required this.token});

  final String token;

  @override
  State<StudentNotificationsSheet> createState() =>
      _StudentNotificationsSheetState();
}

class _StudentNotificationsSheetState extends State<StudentNotificationsSheet> {
  final _service = NotificationService();
  List<AppNotification> _notifications = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifications = await _service.listMine(widget.token);
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
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

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) return;
    setState(() {
      _notifications = _notifications
          .map(
            (item) => item.id == notification.id
                ? AppNotification(
                    id: item.id,
                    title: item.title,
                    message: item.message,
                    createdAt: item.createdAt,
                    readAt: DateTime.now(),
                  )
                : item,
          )
          .toList();
    });
    try {
      await _service.markRead(widget.token, notification.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update notification: $error')),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh notifications',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _notifications.isEmpty
                  ? 'Updates from CareerIQ appear here.'
                  : '${_notifications.where((item) => !item.isRead).length} unread · ${_notifications.length} total',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    ),
  );

  Widget _buildList() {
    if (_loading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 38),
            const SizedBox(height: 10),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              size: 42,
              color: Color(0xFF6B778C),
            ),
            const SizedBox(height: 10),
            Text(
              'You are all caught up',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'New updates will appear here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 52),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 2,
              vertical: 5,
            ),
            leading: CircleAvatar(
              backgroundColor: notification.isRead
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFFEFF6FF),
              foregroundColor: notification.isRead
                  ? const Color(0xFF64748B)
                  : const Color(0xFF2563EB),
              child: Icon(
                notification.isRead
                    ? Icons.notifications_outlined
                    : Icons.notifications_active_outlined,
                size: 20,
              ),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead
                    ? FontWeight.w500
                    : FontWeight.w700,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.message),
                  const SizedBox(height: 5),
                  Text(
                    _formatDate(notification.createdAt),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            isThreeLine: true,
            onTap: () => _markRead(notification),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
