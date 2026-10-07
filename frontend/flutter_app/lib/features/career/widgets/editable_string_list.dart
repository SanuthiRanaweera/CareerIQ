import 'package:flutter/material.dart';

/// A labelled list of short text values that an admin can add to and remove
/// from, used for fields the Career model stores as arrays.
///
/// Values are typed into one box and committed with the add button or the
/// keyboard's done key, then listed beneath with a remove control each. That
/// keeps a long list readable, which matters for entries like "Write and
/// review code" that are full sentences rather than single words.
class EditableStringList extends StatefulWidget {
  const EditableStringList({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.hintText = 'Type and press add',
    this.helperText,
    this.required = false,
    this.errorText,
    this.maxLength = 200,
  });

  final String label;
  final List<String> values;
  final void Function(List<String> values) onChanged;
  final String hintText;
  final String? helperText;
  final bool required;
  final String? errorText;
  final int maxLength;

  @override
  State<EditableStringList> createState() => _EditableStringListState();
}

class _EditableStringListState extends State<EditableStringList> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;

    // Silently ignore an exact duplicate rather than storing it twice.
    if (widget.values.any((existing) => existing.toLowerCase() == value.toLowerCase())) {
      _controller.clear();
      return;
    }

    widget.onChanged([...widget.values, value]);
    _controller.clear();
  }

  void _removeAt(int index) {
    final next = [...widget.values]..removeAt(index);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.label, style: theme.textTheme.titleLarge),
            ),
            if (widget.required)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLength: widget.maxLength,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  // The character counter would add noise to a field used
                  // repeatedly; the limit still applies.
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Add to ${widget.label}',
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                minimumSize: const Size(52, 52),
              ),
            ),
          ],
        ),
        if (widget.values.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...widget.values.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 15,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove ${entry.value}',
                          onPressed: () => _removeAt(entry.key),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: const Color(0xFF64748B),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
        if (hasError) ...[
          const SizedBox(height: 6),
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
                  widget.errorText!,
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
    );
  }
}
