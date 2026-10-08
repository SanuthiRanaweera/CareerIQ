import 'package:flutter/material.dart';

import '../models/admin_personality_question.dart';

class AdminQuestionFormDialog extends StatefulWidget {
  const AdminQuestionFormDialog({
    super.key,
    this.question,
    required this.onSave,
  });

  final AdminPersonalityQuestion? question;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<AdminQuestionFormDialog> createState() =>
      _AdminQuestionFormDialogState();
}

class _AdminQuestionFormDialogState extends State<AdminQuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _textController;
  late final TextEditingController _displayOrderController;
  late final TextEditingController _customCategoryController;

  late String _selectedType;
  late String _selectedCategory;
  late String _selectedAnswerType;
  late bool _reverseScoring;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  static const List<String> _types = [
    'personality',
    'interest',
    'skills',
    'work_style',
  ];

  static const List<String> _standardCategories = [
    'analytical',
    'creative',
    'social',
    'leadership',
    'practical',
    'organized',
    'custom',
  ];

  static const List<String> _answerTypes = [
    '5-Point Likert',
    '3-Point Likert',
  ];

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _textController = TextEditingController(text: q?.questionText ?? '');
    _displayOrderController =
        TextEditingController(text: (q?.displayOrder ?? 1).toString());

    _selectedType = q?.type ?? 'personality';
    if (!_types.contains(_selectedType)) _selectedType = 'personality';

    final cat = q?.category ?? 'analytical';
    if (_standardCategories.contains(cat)) {
      _selectedCategory = cat;
      _customCategoryController = TextEditingController();
    } else {
      _selectedCategory = 'custom';
      _customCategoryController = TextEditingController(text: cat);
    }

    _selectedAnswerType =
        (q?.answerType == 'likert_3' || q?.options.length == 3)
            ? '3-Point Likert'
            : '5-Point Likert';

    _reverseScoring = q?.reverseScoring ?? false;
    _isActive = q?.isActive ?? true;
  }

  @override
  void dispose() {
    _textController.dispose();
    _displayOrderController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  List<AdminQuestionOption> _buildOptions() {
    if (_selectedAnswerType == '3-Point Likert') {
      return const [
        AdminQuestionOption(text: 'Disagree', score: 1),
        AdminQuestionOption(text: 'Neutral', score: 2),
        AdminQuestionOption(text: 'Agree', score: 3),
      ];
    }
    return const [
      AdminQuestionOption(text: 'Strongly Disagree', score: 1),
      AdminQuestionOption(text: 'Disagree', score: 2),
      AdminQuestionOption(text: 'Neutral', score: 3),
      AdminQuestionOption(text: 'Agree', score: 4),
      AdminQuestionOption(text: 'Strongly Agree', score: 5),
    ];
  }

  String _formatLabel(String s) {
    if (s.isEmpty) return s;
    return s.split('_').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final category = _selectedCategory == 'custom'
        ? _customCategoryController.text.trim().toLowerCase()
        : _selectedCategory;

    if (category.isEmpty) {
      setState(() => _errorMessage = 'Please specify a category');
      return;
    }

    final displayOrder = int.tryParse(_displayOrderController.text.trim()) ?? 1;

    final data = <String, dynamic>{
      'questionText': _textController.text.trim(),
      'type': _selectedType,
      'category': category,
      'answerType': _selectedAnswerType == '3-Point Likert' ? 'likert_3' : 'likert_5',
      'options': _buildOptions().map((o) => o.toJson()).toList(),
      'reverseScoring': _reverseScoring,
      'displayOrder': displayOrder,
      'isActive': _isActive,
    };

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.onSave(data);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.question != null && widget.question!.id.isNotEmpty;
    final options = _buildOptions();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_circle_outline_rounded,
                        color: const Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Question' : 'Create Question',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            isEditing
                                ? 'Update personality test statement & attributes'
                                : 'Add a new dynamic question to MongoDB',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFF991B1B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Question Text
                        const Text(
                          'Question / Statement',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _textController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                'e.g., "I enjoy solving complex logical puzzles and analyzing data."',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the question text';
                            }
                            if (value.trim().length < 5) {
                              return 'Question statement is too short';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Question Type & Category Row
                        Row(
                          children: [
                            // Question Type
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Question Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedType,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                    ),
                                    items: _types
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(_formatLabel(t)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedType = val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Category
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Category',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedCategory,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                    ),
                                    items: _standardCategories
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(_formatLabel(c)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedCategory = val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (_selectedCategory == 'custom') ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Custom Category Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _customCategoryController,
                            decoration: InputDecoration(
                              hintText: 'e.g., technical, artistic, strategic',
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (_selectedCategory == 'custom' &&
                                  (val == null || val.trim().isEmpty)) {
                                return 'Please specify custom category';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Answer Type
                        const Text(
                          'Answer Type',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedAnswerType,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          items: _answerTypes
                              .map(
                                (at) => DropdownMenuItem(
                                  value: at,
                                  child: Text(at),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedAnswerType = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Default Options Preview
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.list_alt_rounded,
                                    size: 16,
                                    color: Color(0xFF475569),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Options & Scoring Preview (${options.length} scale)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: options.map((opt) {
                                  final actualScore = _reverseScoring
                                      ? (options.length + 1 - opt.score)
                                      : opt.score;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Text(
                                      '${opt.text} (${actualScore}pt${_reverseScoring ? ' [inv]' : ''})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _reverseScoring
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Allow Reverse Scoring Switch
                        Container(
                          decoration: BoxDecoration(
                            color: _reverseScoring
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _reverseScoring
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            title: const Text(
                              'Allow Reverse Scoring',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            subtitle: const Text(
                              'Invert score calculation (e.g. Strongly Agree = 1, Strongly Disagree = 5)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            value: _reverseScoring,
                            activeThumbColor: const Color(0xFFD97706),
                            onChanged: (val) =>
                                setState(() => _reverseScoring = val),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Display Order & Active Toggle
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Display Order',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _displayOrderController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      prefixIcon: const Icon(
                                        Icons.format_list_numbered_rounded,
                                        size: 18,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (int.tryParse(val.trim()) == null) {
                                        return 'Must be number';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 3,
                              child: Container(
                                margin: const EdgeInsets.only(top: 22),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _isActive
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isActive
                                        ? const Color(0xFFA7F3D0)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: _isActive
                                                  ? const Color(0xFF065F46)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                          Text(
                                            _isActive
                                                ? 'Shown to students'
                                                : 'Hidden from test',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _isActive
                                                  ? const Color(0xFF047857)
                                                  : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _isActive,
                                      activeThumbColor: const Color(0xFF10B981),
                                      onChanged: (val) =>
                                          setState(() => _isActive = val),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : (isEditing ? 'Update Question' : 'Save Question'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

