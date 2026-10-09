import 'package:flutter/material.dart';

import '../../../models/recommendation_input.dart';
import '../widgets/career_state_views.dart';

/// Career recommendations - input form.
///
/// Collects the five things the scoring service weighs: A/L stream, A/L
/// subjects, interests, personality type and preferred work style.
///
/// Stream, interests and personality are required; subjects and work style
/// are optional. That floor is deliberate. The scoring shares its weights out
/// across whichever components were answered, so a single answer would rank
/// several careers at a meaningless 100%. Requiring three keeps every result
/// built on a reasonable spread without changing the algorithm.
class CareerRecommendationFormPage extends StatefulWidget {
  const CareerRecommendationFormPage({super.key, required this.onSubmit});

  /// Receives the completed answers. The caller decides what to do next,
  /// which keeps this screen free of navigation and API concerns.
  final void Function(RecommendationAnswers answers) onSubmit;

  @override
  State<CareerRecommendationFormPage> createState() =>
      _CareerRecommendationFormPageState();
}

class _CareerRecommendationFormPageState
    extends State<CareerRecommendationFormPage> {
  String _stream = '';
  String _personalityType = '';
  String _workStyle = '';
  final Set<String> _subjects = {};
  final Set<String> _interests = {};

  /// Validation messages only appear after the first submit attempt, so the
  /// form does not scold a student for fields they have not reached yet.
  bool _submitted = false;

  String? get _streamError =>
      _stream.isEmpty ? 'Please select your A/L stream' : null;

  String? get _interestsError =>
      _interests.isEmpty ? 'Please choose at least one interest' : null;

  String? get _personalityError => _personalityType.isEmpty
      ? 'Please select the option that describes you best'
      : null;

  bool get _isValid =>
      _streamError == null &&
      _interestsError == null &&
      _personalityError == null;

  void _submit() {
    setState(() => _submitted = true);

    if (!_isValid) {
      // Tell the student what is missing rather than leaving a dead button.
      final missing = [
        if (_streamError != null) 'A/L stream',
        if (_interestsError != null) 'interests',
        if (_personalityError != null) 'personality',
      ].join(', ');

      showCareerMessage(context, 'Please complete: $missing');
      return;
    }

    widget.onSubmit(
      RecommendationAnswers(
        stream: _stream,
        subjects: _subjects.toList(),
        interests: _interests.toList(),
        personalityType: _personalityType,
        workStyle: _workStyle,
      ),
    );
  }

  void _toggle(Set<String> target, String value) {
    setState(() {
      if (!target.remove(value)) target.add(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Career recommendations')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const SizedBox(height: 8),
            Text(
              'FIND YOUR MATCH',
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 6),
            Text('Tell us about you', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Your answers are scored against every career to rank the ones that fit you best.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 22),

            _FormSection(
              title: 'Your A/L stream',
              subtitle: 'Pick the stream you are following.',
              required: true,
              error: _submitted ? _streamError : null,
              child: _SingleChoiceChips(
                options: alStreams,
                selected: _stream,
                onSelected: (value) => setState(() => _stream = value),
              ),
            ),

            _FormSection(
              title: 'Your A/L subjects',
              subtitle: 'Optional. Choose any that apply.',
              child: _MultiChoiceChips(
                options: alSubjectOptions,
                selected: _subjects,
                onToggle: (value) => _toggle(_subjects, value),
              ),
            ),

            _FormSection(
              title: 'What interests you',
              subtitle: 'Choose everything that sounds appealing.',
              required: true,
              error: _submitted ? _interestsError : null,
              child: _MultiChoiceChips(
                options: interestOptions,
                selected: _interests,
                onToggle: (value) => _toggle(_interests, value),
              ),
            ),

            _FormSection(
              title: 'How you work best',
              subtitle: 'Which one describes you most of the time?',
              required: true,
              error: _submitted ? _personalityError : null,
              child: _SingleChoiceChips(
                options: personalityTypes,
                selected: _personalityType,
                onSelected: (value) => setState(() => _personalityType = value),
              ),
            ),

            _FormSection(
              title: 'Preferred work style',
              subtitle: 'Optional. Where would you like to spend your day?',
              child: _SingleChoiceChips(
                options: workStyles,
                selected: _workStyle,
                // Tapping the selected chip again clears it, since this
                // question is optional and should be undoable.
                onSelected: (value) => setState(
                  () => _workStyle = _workStyle == value ? '' : value,
                ),
              ),
            ),

            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('See my matches'),
            ),
            const SizedBox(height: 12),
            Text(
              'Answer more questions for a sharper match.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled block of the form, with an optional "Required" marker and an
/// error message shown beneath it.
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.required = false,
    this.error,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool required;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = error != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        // A red outline makes the problem section findable at a glance,
        // alongside the message itself.
        side: BorderSide(
          color: hasError ? const Color(0xFFDC2626) : const Color(0x12E2E8F0),
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                if (required)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 14),
            child,
            if (hasError) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pick one.
class _SingleChoiceChips extends StatelessWidget {
  const _SingleChoiceChips({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final void Function(String value) onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: options
        .map(
          (option) => ChoiceChip(
            label: Text(option),
            selected: selected == option,
            onSelected: (_) => onSelected(option),
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF3B82F6),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected == option
                  ? Colors.white
                  : const Color(0xFF64748B),
            ),
            side: BorderSide(
              color: selected == option
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFCBD5E1),
            ),
            shape: const StadiumBorder(),
          ),
        )
        .toList(),
  );
}

/// Pick as many as you like.
class _MultiChoiceChips extends StatelessWidget {
  const _MultiChoiceChips({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selected;
  final void Function(String value) onToggle;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: options
        .map(
          (option) => FilterChip(
            label: Text(option),
            selected: selected.contains(option),
            onSelected: (_) => onToggle(option),
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFFDBEAFE),
            checkmarkColor: const Color(0xFF1D4ED8),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected.contains(option)
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF64748B),
            ),
            side: BorderSide(
              color: selected.contains(option)
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFCBD5E1),
            ),
            shape: const StadiumBorder(),
          ),
        )
        .toList(),
  );
}
