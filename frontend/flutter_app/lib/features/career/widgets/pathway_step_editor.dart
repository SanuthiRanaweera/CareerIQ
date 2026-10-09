import 'package:flutter/material.dart';

import '../../../models/career.dart';

/// Stage names used by the seeded careers, offered as one-tap suggestions so
/// an admin does not have to retype them. The field stays free text, because
/// some careers need a stage of their own such as a professional
/// qualification or a licensing exam.
const List<String> commonPathwayStages = [
  'A/L Stream',
  'Degree',
  'Professional Qualification',
  'Skills',
  'Internship',
  'Entry Job',
  'Senior Role',
];

/// Editor for a career's ordered pathway steps.
///
/// Order is taken from the position in the list rather than typed in, and the
/// `order` field is renumbered from 1 on every change. That makes gaps and
/// duplicates impossible, and matches the pathway screen, which numbers steps
/// by position.
class PathwayStepEditor extends StatelessWidget {
  const PathwayStepEditor({
    super.key,
    required this.steps,
    required this.onChanged,
  });

  final List<CareerPathwayStep> steps;
  final void Function(List<CareerPathwayStep> steps) onChanged;

  /// Renumbers from 1 so stored order always matches displayed order.
  void _commit(List<CareerPathwayStep> next) {
    onChanged([
      for (var i = 0; i < next.length; i++)
        CareerPathwayStep(
          order: i + 1,
          stage: next[i].stage,
          title: next[i].title,
          description: next[i].description,
          durationLabel: next[i].durationLabel,
        ),
    ]);
  }

  void _move(int index, int delta) {
    final next = [...steps];
    final target = index + delta;
    if (target < 0 || target >= next.length) return;
    final step = next.removeAt(index);
    next.insert(target, step);
    _commit(next);
  }

  void _removeAt(int index) => _commit([...steps]..removeAt(index));

  Future<void> _addOrEdit(BuildContext context, {int? index}) async {
    final result = await showDialog<CareerPathwayStep>(
      context: context,
      builder: (_) => _PathwayStepDialog(
        step: index == null ? null : steps[index],
        position: index == null ? steps.length + 1 : index + 1,
      ),
    );
    if (result == null) return;

    final next = [...steps];
    if (index == null) {
      next.add(result);
    } else {
      next[index] = result;
    }
    _commit(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Career pathway', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'The ordered steps from A/L to a senior role. Optional, but it is '
          'what the pathway screen shows.',
          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 14),
        if (steps.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'No steps yet. Add the first step of this pathway.',
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
            ),
          )
        else
          ...steps.asMap().entries.map(
            (entry) => _StepRow(
              position: entry.key + 1,
              step: entry.value,
              isFirst: entry.key == 0,
              isLast: entry.key == steps.length - 1,
              onEdit: () => _addOrEdit(context, index: entry.key),
              onRemove: () => _removeAt(entry.key),
              onMoveUp: () => _move(entry.key, -1),
              onMoveDown: () => _move(entry.key, 1),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _addOrEdit(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add pathway step'),
        ),
      ],
    );
  }
}

/// One step in the editor, with its reorder and remove controls.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.position,
    required this.step,
    required this.isFirst,
    required this.isLast,
    required this.onEdit,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final int position;
  final CareerPathwayStep step;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$position',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.stage,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    Text(
                      step.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    if (step.durationLabel.isNotEmpty)
                      Text(
                        step.durationLabel,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Reorder controls are disabled rather than hidden at the ends
              // of the list, so the row layout stays stable.
              IconButton(
                tooltip: 'Move ${step.title} up',
                onPressed: isFirst ? null : onMoveUp,
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Move ${step.title} down',
                onPressed: isLast ? null : onMoveDown,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Edit ${step.title}',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: const Color(0xFF3B82F6),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Remove ${step.title}',
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: const Color(0xFF64748B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add or edit one pathway step.
class _PathwayStepDialog extends StatefulWidget {
  const _PathwayStepDialog({required this.step, required this.position});

  final CareerPathwayStep? step;
  final int position;

  @override
  State<_PathwayStepDialog> createState() => _PathwayStepDialogState();
}

class _PathwayStepDialogState extends State<_PathwayStepDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stage;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _duration;

  @override
  void initState() {
    super.initState();
    _stage = TextEditingController(text: widget.step?.stage ?? '');
    _title = TextEditingController(text: widget.step?.title ?? '');
    _description = TextEditingController(text: widget.step?.description ?? '');
    _duration = TextEditingController(text: widget.step?.durationLabel ?? '');
  }

  @override
  void dispose() {
    _stage.dispose();
    _title.dispose();
    _description.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      CareerPathwayStep(
        // Renumbered by the editor on commit; this keeps a sensible value in
        // the meantime.
        order: widget.position,
        stage: _stage.text.trim(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        durationLabel: _duration.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.step == null
            ? 'Add step ${widget.position}'
            : 'Edit step ${widget.position}',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stage',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: commonPathwayStages
                    .map(
                      (stage) => ActionChip(
                        label: Text(
                          stage,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => setState(() => _stage.text = stage),
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: const StadiumBorder(
                          side: BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stage,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Stage *',
                  hintText: 'e.g. Degree',
                  counterText: '',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Stage is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Step title *',
                  hintText: 'e.g. BSc in Software Engineering',
                  counterText: '',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Step title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLength: 400,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional detail about this step',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _duration,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  hintText: 'e.g. 3-4 years',
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          child: Text(widget.step == null ? 'Add step' : 'Save step'),
        ),
      ],
    );
  }
}
