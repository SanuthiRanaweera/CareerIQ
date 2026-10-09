import 'package:flutter/material.dart';

import '../../../models/career.dart';
import '../widgets/career_state_views.dart';

/// Screen 22 - Career pathway.
///
/// Shows the ordered steps from school to a senior role as a vertical
/// timeline: A/L Stream -> Degree -> Skills -> Internship -> Entry Job ->
/// Senior Role. Each step is numbered and joined to the next by a connector
/// line, so the sequence reads as a route rather than a list.
///
/// The career is passed in from the details screen, which has already loaded
/// it, so this screen does not fetch anything and has no loading state. It
/// still handles a career whose pathway has not been filled in yet.
class CareerPathwayPage extends StatelessWidget {
  const CareerPathwayPage({super.key, required this.career});

  final Career career;

  @override
  Widget build(BuildContext context) {
    // Always read through orderedPathway so the timeline is correct even if
    // the steps arrive out of order.
    final steps = career.orderedPathway;

    return Scaffold(
      appBar: AppBar(title: const Text('Career pathway')),
      body: SafeArea(
        child: steps.isEmpty
            ? const CareerEmptyView(
                icon: Icons.timeline_rounded,
                title: 'Pathway coming soon',
                message:
                    'The step-by-step pathway for this career has not been added yet.',
              )
            : _buildTimeline(context, steps),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<CareerPathwayStep> steps) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SizedBox(height: 8),
        Text(
          'YOUR PATH TO',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 6),
        Text(career.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          '${steps.length} ${steps.length == 1 ? 'step' : 'steps'} from A/L to a senior role',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        ...steps.asMap().entries.map(
          (entry) => _TimelineStep(
            step: entry.value,
            number: entry.key + 1,
            // The connector is drawn below every step except the last, so
            // the line stops at the end of the path.
            isLast: entry.key == steps.length - 1,
          ),
        ),
      ],
    );
  }
}

/// One numbered step plus the connector line joining it to the next.
class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.step,
    required this.number,
    required this.isLast,
  });

  final CareerPathwayStep step;
  final int number;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left rail: the numbered marker and the line down to the next step.
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              if (!isLast)
                const Expanded(
                  child: VerticalDivider(
                    width: 36,
                    thickness: 2,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              // Spacing below each card, except the last, so the connector
              // line has somewhere to run.
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _StagePill(label: step.stage)),
                          if (step.durationLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _DurationLabel(label: step.durationLabel),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(step.title, style: theme.textTheme.titleLarge),
                      if (step.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          step.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The kind of step this is, e.g. "Degree" or "Internship".
class _StagePill extends StatelessWidget {
  const _StagePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1D4ED8),
        ),
      ),
    ),
  );
}

/// Roughly how long this step takes, e.g. "3-4 years".
class _DurationLabel extends StatelessWidget {
  const _DurationLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF64748B)),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    ],
  );
}
