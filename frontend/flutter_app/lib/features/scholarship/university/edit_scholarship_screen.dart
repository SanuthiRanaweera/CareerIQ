import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../models/scholarship_model.dart';
import '../services/scholarship_service.dart';

class EditScholarshipScreen extends StatefulWidget {
  const EditScholarshipScreen({super.key, required this.scholarship});

  final ScholarshipModel scholarship;

  @override
  State<EditScholarshipScreen> createState() => _EditScholarshipScreenState();
}

class _EditScholarshipScreenState extends State<EditScholarshipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ScholarshipService();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _amountController;
  late TextEditingController _numController;
  late TextEditingController _academicReqController;
  late TextEditingController _ageReqController;
  late TextEditingController _districtReqController;
  late TextEditingController _otherReqController;
  late TextEditingController _instructionsController;

  late String _selectedType;
  late String _selectedStream;
  late String _selectedStatus;

  late DateTime _deadline;
  DateTime? _startDate;
  DateTime? _endDate;

  late Set<String> _selectedCoverage;
  late Set<String> _selectedDocs;
  late List<RequiredSubjectModel> _minimumResults;

  bool _isSubmitting = false;

  final List<String> _types = [
    'Merit',
    'Need Based',
    'Academic',
    'Sports',
    'Special Category',
    'Other',
  ];

  final List<String> _streams = [
    'Any',
    'Physical Science',
    'Biological Science',
    'Commerce',
    'Arts',
    'Technology',
  ];

  final List<String> _coverageOptions = [
    'Tuition Fees',
    'Accommodation',
    'Books',
    'Living Expenses',
    'Transport',
    'Other',
  ];

  final List<String> _documentOptions = [
    'A/L Result Sheet',
    'School Leaving Certificate',
    'NIC',
    'Recommendation Letter',
    'Income Certificate',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.scholarship;
    _titleController = TextEditingController(text: s.title);
    _descController = TextEditingController(text: s.description);
    _amountController = TextEditingController(text: s.amount);
    _numController = TextEditingController(
      text: s.numberOfScholarships.toString(),
    );
    _academicReqController = TextEditingController(
      text: s.eligibility.academicRequirement,
    );
    _ageReqController = TextEditingController(
      text: s.eligibility.ageRequirement,
    );
    _districtReqController = TextEditingController(
      text: s.eligibility.districtRequirement,
    );
    _otherReqController = TextEditingController(
      text: s.eligibility.otherRequirements,
    );
    _instructionsController = TextEditingController(
      text: s.applicationInstructions,
    );

    _selectedType = s.scholarshipType;
    _selectedStream = s.eligibility.stream;
    _selectedStatus = s.status[0].toUpperCase() + s.status.substring(1);

    _deadline = s.applicationDeadline;
    _startDate = s.startDate;
    _endDate = s.endDate;

    _selectedCoverage = Set.from(s.coverage);
    _selectedDocs = Set.from(s.requiredDocuments);
    _minimumResults = List.from(s.eligibility.minimumResults);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    _numController.dispose();
    _academicReqController.dispose();
    _ageReqController.dispose();
    _districtReqController.dispose();
    _otherReqController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  void _addSubjectRequirementDialog() {
    final subjectCtrl = TextEditingController();
    String selectedGrade = 'A';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Required Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject Name *',
                  hintText: 'e.g. Combined Mathematics',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                decoration: const InputDecoration(labelText: 'Minimum Grade *'),
                items: ['A', 'B', 'C', 'S'].map((g) {
                  return DropdownMenuItem(value: g, child: Text('Grade $g'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedGrade = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final sub = subjectCtrl.text.trim();
                if (sub.isNotEmpty) {
                  setState(() {
                    _minimumResults.add(
                      RequiredSubjectModel(subject: sub, grade: selectedGrade),
                    );
                  });
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCoverage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one Coverage benefit.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await AuthService().token();
      if (token == null) throw Exception('Authentication session expired.');

      final payload = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'scholarshipType': _selectedType,
        'amount': _amountController.text.trim(),
        'coverage': _selectedCoverage.toList(),
        'numberOfScholarships': int.tryParse(_numController.text.trim()) ?? 1,
        'applicationDeadline': _deadline.toIso8601String(),
        if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
        if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
        'eligibility': {
          'stream': _selectedStream,
          'minimumResults': _minimumResults.map((r) => r.toJson()).toList(),
          'academicRequirement': _academicReqController.text.trim(),
          'ageRequirement': _ageReqController.text.trim(),
          'districtRequirement': _districtReqController.text.trim(),
          'otherRequirements': _otherReqController.text.trim(),
        },
        'applicationInstructions': _instructionsController.text.trim(),
        'requiredDocuments': _selectedDocs.toList(),
        'status': _selectedStatus.toLowerCase(),
      };

      await _service.updateScholarship(widget.scholarship.id, payload, token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scholarship updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Scholarship')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            _buildSectionHeader('BASIC INFORMATION'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Scholarship Name *',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Scholarship Name is required'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Scholarship Type *',
              ),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount / Benefit *',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Amount is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _numController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Scholarships *',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return 'Must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('COVERAGE *'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _coverageOptions.map((opt) {
                final isSelected = _selectedCoverage.contains(opt);
                return FilterChip(
                  label: Text(opt),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedCoverage.add(opt);
                      } else {
                        _selectedCoverage.remove(opt);
                      }
                    });
                  },
                  selectedColor: const Color(0xFFEFF6FF),
                  checkmarkColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF475569),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('DATES & DEADLINES'),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Application Deadline *',
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(
                  '${_deadline.day}/${_deadline.month}/${_deadline.year}',
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('ELIGIBILITY REQUIREMENTS'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedStream,
              decoration: const InputDecoration(labelText: 'A/L Stream *'),
              items: _streams
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStream = val);
              },
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Minimum Subject Results',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSubjectRequirementDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Subject'),
                ),
              ],
            ),
            if (_minimumResults.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'No subject grade requirements specified.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ..._minimumResults.map(
                (req) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${req.subject}: Grade ${req.grade}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () {
                          setState(() => _minimumResults.remove(req));
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _academicReqController,
              decoration: const InputDecoration(
                labelText: 'Minimum Academic Requirement',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _districtReqController,
              decoration: const InputDecoration(
                labelText: 'District / Location Requirement',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _otherReqController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Other Requirements',
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('APPLICATION INSTRUCTIONS & DOCUMENTS'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructionsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Application Instructions',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Required Documents',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _documentOptions.map((doc) {
                final isSelected = _selectedDocs.contains(doc);
                return FilterChip(
                  label: Text(doc),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedDocs.add(doc);
                      } else {
                        _selectedDocs.remove(doc);
                      }
                    });
                  },
                  selectedColor: const Color(0xFFEFF6FF),
                  checkmarkColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF475569),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('SCHOLARSHIP STATUS'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status *'),
              items: [
                'Active',
                'Draft',
                'Closed',
                'Expired',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 30),

            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      color: Color(0xFF3B82F6),
    ),
  );
}
