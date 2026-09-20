import 'package:flutter/material.dart';

import '../../../models/personality_test.dart';

class PersonalityQuestionPage extends StatelessWidget {
  const PersonalityQuestionPage({
    super.key,
    required this.question,
    required this.options,
    required this.questionNumber,
    required this.totalQuestions,
    required this.selectedAnswer,
    required this.onSelect,
    required this.onNext,
    required this.onPrevious,
    required this.isLastQuestion,
  });

  final PersonalityQuestion question;
  final List<PersonalityAnswerOption> options;
  final int questionNumber;
  final int totalQuestions;
  final String? selectedAnswer;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;
  final VoidCallback? onPrevious;
  final bool isLastQuestion;

  @override
  Widget build(BuildContext context) {
    final progress = questionNumber / totalQuestions;
    return Scaffold(
      appBar: AppBar(title: const Text('Personality & Interest Test')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question $questionNumber / $totalQuestions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: progress, minHeight: 10),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        question.text,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      ...options.map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnswerOptionTile(
                            option: option,
                            selected: selectedAnswer == option.label,
                            onTap: () => onSelect(option.label),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onPrevious != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onPrevious,
                        child: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: selectedAnswer == null ? null : onNext,
                      child: Text(isLastQuestion ? 'Finish' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerOptionTile extends StatelessWidget {
  const _AnswerOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PersonalityAnswerOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFDBEAFE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 14),
          Text(
            option.label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    ),
  );
}
