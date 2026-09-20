import 'package:flutter/material.dart';

import '../../../models/personality_test.dart';

class PersonalityResultPage extends StatelessWidget {
  const PersonalityResultPage({
    super.key,
    required this.result,
    required this.onDone,
    required this.onRetake,
  });

  final PersonalityResult result;
  final VoidCallback onDone;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your Result')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(
            'YOUR CAREER PERSONALITY',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.resultType,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Strengths',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...result.strengths.map(
                    (strength) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              strength,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personality Scores',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...personalityCategoryLabels.entries.map((entry) {
                    final score = result.scores[entry.key] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.value,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                '$score%',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: score / 100,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Career Fields',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.careers
                        .map(
                          (career) => Chip(
                            label: Text(career),
                            backgroundColor: const Color(0xFFDBEAFE),
                            side: BorderSide.none,
                            labelStyle: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Your detailed career recommendations will be generated based on your personality and academic results.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(onPressed: onDone, child: const Text('Done')),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRetake, child: const Text('Retake Test')),
        ],
      ),
    ),
  );
}
