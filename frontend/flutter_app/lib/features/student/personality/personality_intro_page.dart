import 'package:flutter/material.dart';

import '../../../models/personality_test.dart';

class PersonalityIntroPage extends StatelessWidget {
  const PersonalityIntroPage({
    super.key,
    required this.questionCount,
    required this.onStart,
    this.existingResult,
    this.onViewResult,
  });

  final int questionCount;
  final VoidCallback onStart;
  final PersonalityResult? existingResult;
  final VoidCallback? onViewResult;

  @override
  Widget build(BuildContext context) {
    final estimatedMinutes = (questionCount / 4).ceil();
    return Scaffold(
      appBar: AppBar(title: const Text('Personality & Interest Test')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFDBEAFE),
                foregroundColor: Color(0xFF3B82F6),
                child: Icon(Icons.psychology_outlined, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'Discover Your Career Personality',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Answer a few questions to understand your strengths, interests, and suitable career directions.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        icon: Icons.quiz_outlined,
                        label: '$questionCount Questions',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: const Color(0x1A1F2937),
                      ),
                      _StatItem(
                        icon: Icons.timer_outlined,
                        label: '~$estimatedMinutes min',
                      ),
                    ],
                  ),
                ),
              ),
              if (existingResult != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFFDBEAFE),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You already completed this test as "${existingResult!.resultType}".',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: onStart,
                child: Text(
                  existingResult == null ? 'Start Test' : 'Retake Test',
                ),
              ),
              if (onViewResult != null) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onViewResult,
                  child: const Text('View My Result'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: const Color(0xFF3B82F6)),
      const SizedBox(height: 6),
      Text(
        label,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
      ),
    ],
  );
}
