import 'package:flutter/material.dart';

import '../../models/group_message.dart';
import '../../services/group_chat_service.dart';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({
    super.key,
    required this.token,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserProfileImage,
    this.isAdmin = false,
  });

  final String token;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserProfileImage;
  final bool isAdmin;

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final _service = GroupChatService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  List<GroupMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await _service.getMessages(widget.token);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('ApiException: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final newMessage = await _service.sendMessage(widget.token, text);
      if (!mounted) return;
      _inputController.clear();
      setState(() {
        _messages.add(newMessage);
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString().replaceFirst('ApiException: ', '')}')),
      );
    }
  }

  Future<void> _editMessage(GroupMessage message) async {
    final editController = TextEditingController(text: message.message);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Update your message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final newText = editController.text.trim();
    if (newText.isEmpty || newText == message.message) return;

    try {
      final updated = await _service.updateMessage(widget.token, message.id, newText);
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = updated;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update message: ${e.toString().replaceFirst('ApiException: ', '')}')),
      );
    }
  }

  Future<void> _deleteMessage(GroupMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteMessage(widget.token, message.id);
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == message.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message: ${e.toString().replaceFirst('ApiException: ', '')}')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isMe(GroupMessage message) {
    return message.senderId == widget.currentUserId ||
        message.senderStudentId == widget.currentUserId ||
        message.senderName == widget.currentUserName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareerIQ Group Chat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh messages',
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadMessages, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.forum_outlined, size: 64, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 12),
                                Text('No messages yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF64748B))),
                                const SizedBox(height: 4),
                                const Text('Be the first student to start the conversation!', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMessages,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isMe = _isMe(message);
                                final profileImage = message.senderProfileImage.trim();

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe) ...[
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: const Color(0xFFDBEAFE),
                                          backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                                          onBackgroundImageError: profileImage.isNotEmpty ? (_, __) {} : null,
                                          child: profileImage.isEmpty
                                              ? Text(
                                                  message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                                                  style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            if (!isMe)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 4, bottom: 4),
                                                child: Text(
                                                  message.senderName,
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                                ),
                                              ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isMe || widget.isAdmin)
                                                  PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF94A3B8)),
                                                    onSelected: (value) {
                                                      if (value == 'edit') {
                                                        _editMessage(message);
                                                      } else if (value == 'delete') {
                                                        _deleteMessage(message);
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      if (isMe)
                                                        const PopupMenuItem(
                                                          value: 'edit',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.edit_outlined, size: 16),
                                                              SizedBox(width: 8),
                                                              Text('Edit'),
                                                            ],
                                                          ),
                                                        ),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                                            SizedBox(width: 8),
                                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                Flexible(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: isMe ? const Color(0xFF3B82F6) : Colors.white,
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                                                      boxShadow: const [BoxShadow(color: Color(0x0A1F2937), blurRadius: 8, offset: Offset(0, 2))],
                                                    ),
                                                    child: Text(
                                                      message.message,
                                                      style: TextStyle(
                                                        color: isMe ? Colors.white : const Color(0xFF1F2937),
                                                        fontSize: 14,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: const Color(0xFFDBEAFE),
                                          backgroundImage: profileImage.isNotEmpty
                                              ? NetworkImage(profileImage)
                                              : (widget.currentUserProfileImage != null && widget.currentUserProfileImage!.trim().isNotEmpty)
                                                  ? NetworkImage(widget.currentUserProfileImage!.trim())
                                                  : null,
                                          child: profileImage.isEmpty && (widget.currentUserProfileImage == null || widget.currentUserProfileImage!.trim().isEmpty)
                                              ? Text(
                                                  widget.currentUserName.isNotEmpty ? widget.currentUserName[0].toUpperCase() : 'U',
                                                  style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                                                )
                                              : null,
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
          if (!widget.isAdmin)
            SafeArea(
              top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color(0x0F1F2937), blurRadius: 4, offset: Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type a message to group...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
