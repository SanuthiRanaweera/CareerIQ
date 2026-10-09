import 'package:flutter/material.dart';

import '../../../models/personality_test.dart';
import '../../../services/personality_service.dart';
import 'personality_intro_page.dart';
import 'personality_question_page.dart';
import 'personality_result_page.dart';

enum _Phase { loading, intro, question, submitting, result, error }

class PersonalityTestPage extends StatefulWidget {
  const PersonalityTestPage({
    super.key,
    required this.token,
    required this.studentId,
    this.onCompleted,
  });

  final String token;
  final String studentId;
  final VoidCallback? onCompleted;

  @override
  State<PersonalityTestPage> createState() => _PersonalityTestPageState();
}

class _PersonalityTestPageState extends State<PersonalityTestPage> {
  final _service = PersonalityService();

  _Phase _phase = _Phase.loading;
  List<PersonalityQuestion> _questions = [];
  List<PersonalityAnswerOption> _options = [];
  PersonalityResult? _existingResult;
  PersonalityResult? _result;
  final Map<String, String> _answers = {};
  int _currentIndex = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    try {
      final data = await _service.getQuestions(widget.token);
      final existing = await _service.getResult(widget.token, widget.studentId);
      if (!mounted) return;
      setState(() {
        _questions = data.questions;
        _options = data.options;
        _existingResult = existing;
        _phase = _Phase.intro;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _phase = _Phase.error;
      });
    }
  }

  void _startTest() {
    setState(() {
      _answers.clear();
      _currentIndex = 0;
      _phase = _Phase.question;
    });
  }

  void _goNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _submit();
    }
  }

  void _goPrevious() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  Future<void> _submit() async {
    setState(() => _phase = _Phase.submitting);
    try {
      final result = await _service.submit(
        widget.token,
        widget.studentId,
        _answers,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _phase = _Phase.result;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _phase = _Phase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _Phase.error:
        return Scaffold(
          appBar: AppBar(title: const Text('Personality & Interest Test')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error ?? 'Something went wrong',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        );
      case _Phase.intro:
        return PersonalityIntroPage(
          questionCount: _questions.length,
          existingResult: _existingResult,
          onStart: _startTest,
          onViewResult: _existingResult == null
              ? null
              : () => setState(() {
                  _result = _existingResult;
                  _phase = _Phase.result;
                }),
        );
      case _Phase.question:
        final question = _questions[_currentIndex];
        return PersonalityQuestionPage(
          question: question,
          options: _options,
          questionNumber: _currentIndex + 1,
          totalQuestions: _questions.length,
          selectedAnswer: _answers[question.id],
          onSelect: (answer) => setState(() => _answers[question.id] = answer),
          onNext: _goNext,
          onPrevious: _currentIndex == 0 ? null : _goPrevious,
          isLastQuestion: _currentIndex == _questions.length - 1,
        );
      case _Phase.submitting:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Calculating your results...'),
              ],
            ),
          ),
        );
      case _Phase.result:
        return PersonalityResultPage(
          result: _result!,
          onDone: () {
            if (widget.onCompleted != null) {
              widget.onCompleted!();
            } else {
              Navigator.of(context).pop();
            }
          },
          onRetake: _startTest,
        );
    }
  }
}
