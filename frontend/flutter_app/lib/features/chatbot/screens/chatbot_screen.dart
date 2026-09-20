import 'package:flutter/material.dart';

import '../services/chatbot_service.dart';
import '../widgets/chat_message.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({
    super.key,
    required this.token,
    required this.studentName,
  });

  final String token;
  final String studentName;

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _service = ChatbotService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  String _mode = 'general';
  bool _loading = true;
  bool _sending = false;
  String? _error;

  static const _modes = <String, String>{
    'general': 'Ask anything',
    'career': 'Career advisor',
    'course': 'Course advisor',
    'interview': 'Interview prep',
    'cv': 'CV guidance',
    'roadmap': 'Learning roadmap',
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _service.history(widget.token);
      if (!mounted) return;
      setState(() {
        _messages.addAll(history);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final local = ChatMessage(
      id: 'student-${DateTime.now().microsecondsSinceEpoch}',
      sender: 'student',
      message: text,
      mode: _mode,
      createdAt: DateTime.now().toIso8601String(),
    );
    _input.clear();
    setState(() {
      _messages.add(local);
      _sending = true;
      _error = null;
    });
    _jumpToBottom();
    try {
      final reply = await _service.send(widget.token, text, mode: _mode);
      if (mounted) setState(() => _messages.add(reply));
    } catch (error) {
      if (mounted) {
        final message = error.toString().replaceFirst('ApiException: ', '');
        setState(() => _error = message.isEmpty
            ? 'Sorry, I could not process your request. Please try again.'
            : message);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _jumpToBottom();
      }
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          titleSpacing: 20,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CareerIQ AI Assistant', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('Your career guidance companion', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _ModeSelector(mode: _mode, onChanged: (mode) => setState(() => _mode = mode)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      children: [
                        if (_messages.isEmpty) _WelcomeMessage(name: widget.studentName),
                        ..._messages.map((message) => ChatMessageBubble(message: message)),
                        if (_sending) const TypingIndicator(),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                          ),
                      ],
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: MessageInput(controller: _input, onSend: _send, enabled: !_sending),
              ),
            ),
          ],
        ),
      );
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});
  final String mode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          scrollDirection: Axis.horizontal,
          itemCount: _ChatbotScreenState._modes.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final entry = _ChatbotScreenState._modes.entries.elementAt(index);
            final selected = entry.key == mode;
            return ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onChanged(entry.key),
              selectedColor: const Color(0xFFDBEAFE),
              labelStyle: TextStyle(color: selected ? const Color(0xFF1F2937) : const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12),
              side: BorderSide(color: selected ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
            );
          },
        ),
      );
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFDBEAFE), Color(0xFFF8FAFC)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          'Hello ${name.split(' ').first}, I am your CareerIQ AI Assistant. I can help you explore careers, understand courses, plan your next steps, and prepare for opportunities.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF1F2937), height: 1.45),
        ),
      );
}
