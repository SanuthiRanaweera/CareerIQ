import 'package:flutter/material.dart';

import '../../../models/career.dart';
import '../../../models/recommendation_input.dart' show alStreams;
import '../../../services/api_service.dart';
import '../../../services/career_service.dart';
import '../widgets/editable_string_list.dart';

/// Demand levels a career can be given, mirroring JOB_OUTLOOKS in
/// backend/data/careerOptions.js. The backend validates the value, so an
/// unknown level is rejected rather than silently stored.
const List<String> jobOutlooks = ['Very High', 'High', 'Medium', 'Low'];

/// Admin - add or edit a career.
///
/// Passing a [career] puts the form in edit mode and pre-fills it; leaving it
/// null creates a new career.
///
/// Every field the Career model requires is here, so a career saved from this
/// form always passes server-side validation: title, category, description,
/// salary range, demand level, recommended A/L streams, day-to-day
/// responsibilities and required skills. The optional fields - industry
/// opportunities, pathway steps and matching tags - are added separately and
/// are preserved untouched when editing.
class AdminCareerFormPage extends StatefulWidget {
  const AdminCareerFormPage({
    super.key,
    required this.token,
    this.career,
    this.onSaved,
    this.careerService,
  });

  final String token;

  /// The career being edited, or null when creating one.
  final Career? career;

  /// Called after a successful save, so the caller can refresh its list and
  /// close this screen.
  final void Function(Career career)? onSaved;

  /// Injectable API client so the screen can be tested without a backend.
  final CareerService? careerService;

  @override
  State<AdminCareerFormPage> createState() => _AdminCareerFormPageState();
}

class _AdminCareerFormPageState extends State<AdminCareerFormPage> {
  late final CareerService _careerService =
      widget.careerService ?? CareerService();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _salaryMin;
  late final TextEditingController _salaryMax;

  late String _jobOutlook;
  late List<String> _streams;
  late List<String> _whatYouDo;
  late List<String> _requiredSkills;

  /// Validation messages for the non-text inputs only appear after a save
  /// attempt, so the form does not flag fields before they are reached.
  bool _submitted = false;
  bool _saving = false;

  bool get _isEditing => widget.career != null;

  @override
  void initState() {
    super.initState();
    final career = widget.career;

    _title = TextEditingController(text: career?.title ?? '');
    _category = TextEditingController(text: career?.category ?? '');
    _description = TextEditingController(text: career?.description ?? '');
    _salaryMin = TextEditingController(
      text: career == null ? '' : career.salaryRange.min.toString(),
    );
    _salaryMax = TextEditingController(
      text: career == null ? '' : career.salaryRange.max.toString(),
    );

    _jobOutlook = career?.jobOutlook ?? '';
    _streams = [...?career?.recommendedStreams];
    _whatYouDo = [...?career?.whatYouDo];
    _requiredSkills = [...?career?.requiredSkills];
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _description.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
    super.dispose();
  }

  // --- Validation ---
  //
  // Every rule is checked against the controllers and the selection state
  // rather than through Form.validate() alone. This form is a lazy ListView,
  // so a field scrolled out of view is unmounted and no longer registered
  // with the Form; validate() would quietly skip it and an empty title could
  // reach the server. The controllers survive scrolling, so they are the
  // source of truth, and the TextFormField validators simply report the same
  // getters for the inline messages.

  String? get _titleError =>
      _title.text.trim().isEmpty ? 'Career title is required' : null;

  String? get _categoryError =>
      _category.text.trim().isEmpty ? 'Category is required' : null;

  String? get _descriptionError =>
      _description.text.trim().isEmpty ? 'Description is required' : null;

  String? get _outlookError =>
      _jobOutlook.isEmpty ? 'Please choose a demand level' : null;

  String? get _streamsError =>
      _streams.isEmpty ? 'Please choose at least one A/L stream' : null;

  String? get _whatYouDoError => _whatYouDo.isEmpty
      ? 'Add at least one day-to-day responsibility'
      : null;

  String? get _skillsError =>
      _requiredSkills.isEmpty ? 'Add at least one required skill' : null;

  /// Plain-language names of everything still outstanding, used for the
  /// summary message.
  List<String> get _missingFields => [
        if (_titleError != null) 'title',
        if (_categoryError != null) 'category',
        if (_descriptionError != null) 'description',
        if (_validateSalaryMin(_salaryMin.text) != null) 'minimum salary',
        if (_validateSalaryMax(_salaryMax.text) != null) 'maximum salary',
        if (_outlookError != null) 'demand level',
        if (_streamsError != null) 'A/L streams',
        if (_whatYouDoError != null) "what you'd do",
        if (_skillsError != null) 'skills',
      ];

  /// Naming nine fields in a snackbar is unreadable, so a long list is
  /// summarised by count and the inline messages do the rest.
  String get _problemMessage {
    final missing = _missingFields;
    return missing.length > 3
        ? 'Please complete the ${missing.length} highlighted fields'
        : 'Please complete: ${missing.join(', ')}';
  }

  Future<void> _save() async {
    setState(() => _submitted = true);

    if (_missingFields.isNotEmpty) {
      // Also runs the Form so any mounted field shows its inline message.
      _formKey.currentState?.validate();
      _showMessage(_problemMessage);
      return;
    }

    setState(() => _saving = true);

    // Optional fields are carried over unchanged when editing, so saving the
    // core fields never discards a pathway or tags set elsewhere.
    final existing = widget.career;
    final career = Career(
      id: existing?.id ?? '',
      title: _title.text.trim(),
      category: _category.text.trim(),
      description: _description.text.trim(),
      salaryRange: SalaryRange(
        min: int.parse(_salaryMin.text.trim()),
        max: int.parse(_salaryMax.text.trim()),
      ),
      jobOutlook: _jobOutlook,
      whatYouDo: _whatYouDo,
      requiredSkills: _requiredSkills,
      recommendedStreams: _streams,
      industryOpportunities: existing?.industryOpportunities ?? const [],
      pathway: existing?.pathway ?? const [],
      interestTags: existing?.interestTags ?? const [],
      alSubjects: existing?.alSubjects ?? const [],
      personalityTypes: existing?.personalityTypes ?? const [],
      workStyles: existing?.workStyles ?? const [],
      relatedCourseKeywords: existing?.relatedCourseKeywords ?? const [],
    );

    try {
      final saved = _isEditing
          ? await _careerService.updateCareer(
              widget.token,
              existing!.id,
              career,
            )
          : await _careerService.createCareer(widget.token, career);

      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(
        _isEditing
            ? '${saved.title} updated successfully'
            : '${saved.title} created successfully',
        success: true,
      );
      widget.onSaved?.call(saved);
    } on ApiException catch (error) {
      // The backend's message is specific and worth showing as-is: a repeated
      // title comes back as "A career with this title already exists".
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              success ? const Color(0xFF15803D) : const Color(0xFF1F2937),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit career' : 'Add career'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          // After the first save attempt every field reports its own state as
          // soon as it is scrolled into view.
          autovalidateMode: _submitted
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const SizedBox(height: 8),
              Text(
                _isEditing ? 'EDITING' : 'NEW CAREER',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isEditing ? widget.career!.title : 'Career details',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 22),

              _FormCard(
                title: 'Basics',
                children: [
                  TextFormField(
                    controller: _title,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Career title *',
                      hintText: 'e.g. Software Engineer',
                      counterText: '',
                    ),
                    validator: (_) => _titleError,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _category,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category or industry *',
                      hintText: 'e.g. Information Technology',
                      counterText: '',
                    ),
                    validator: (_) => _categoryError,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    maxLength: 1000,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'What this career involves, in a few lines',
                      alignLabelWithHint: true,
                    ),
                    validator: (_) => _descriptionError,
                  ),
                ],
              ),

              _FormCard(
                title: 'Salary range (LKR per month)',
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _salaryMin,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minimum *',
                            hintText: 'e.g. 150000',
                          ),
                          validator: (value) => _validateSalaryMin(value ?? ''),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _salaryMax,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Maximum *',
                            hintText: 'e.g. 500000',
                          ),
                          validator: (value) => _validateSalaryMax(value ?? ''),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              _FormCard(
                title: 'Demand level',
                error: _submitted ? _outlookError : null,
                children: [
                  _ChoiceRow(
                    options: jobOutlooks,
                    selected: _jobOutlook,
                    onSelected: (value) =>
                        setState(() => _jobOutlook = value),
                  ),
                ],
              ),

              _FormCard(
                title: 'Recommended A/L streams',
                error: _submitted ? _streamsError : null,
                children: [
                  _MultiChoiceRow(
                    options: alStreams,
                    selected: _streams,
                    onToggle: (value) => setState(() {
                      _streams = _streams.contains(value)
                          ? (_streams.where((s) => s != value).toList())
                          : [..._streams, value];
                    }),
                  ),
                ],
              ),

              _FormCard(
                title: '',
                children: [
                  EditableStringList(
                    label: "What you'd do",
                    helperText: 'Day-to-day responsibilities in this career.',
                    required: true,
                    values: _whatYouDo,
                    hintText: 'e.g. Write and review code',
                    errorText: _submitted ? _whatYouDoError : null,
                    onChanged: (values) =>
                        setState(() => _whatYouDo = values),
                  ),
                ],
              ),

              _FormCard(
                title: '',
                children: [
                  EditableStringList(
                    label: 'Required skills',
                    helperText: 'Skills someone needs to do this job.',
                    required: true,
                    maxLength: 60,
                    values: _requiredSkills,
                    hintText: 'e.g. Problem solving',
                    errorText: _submitted ? _skillsError : null,
                    onChanged: (values) =>
                        setState(() => _requiredSkills = values),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              FilledButton.icon(
                // Disabled while saving, so a double tap cannot create the
                // same career twice.
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : (_isEditing ? 'Save changes' : 'Create career'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateSalaryMin(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Minimum salary is required';
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Enter a whole number';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  String? _validateSalaryMax(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Maximum salary is required';
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Enter a whole number';
    if (parsed < 0) return 'Cannot be negative';

    // Mirrors the model's own rule, so the error is caught here rather than
    // coming back from the server.
    final min = int.tryParse(_salaryMin.text.trim());
    if (min != null && parsed < min) return 'Must be at least the minimum';
    return null;
  }
}

/// A titled card grouping related inputs, with an optional error line.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children, this.error});

  final String title;
  final List<Widget> children;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
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
            if (title.isNotEmpty) ...[
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
            ],
            ...children,
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
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
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

/// Pick any number.
class _MultiChoiceRow extends StatelessWidget {
  const _MultiChoiceRow({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final List<String> selected;
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
