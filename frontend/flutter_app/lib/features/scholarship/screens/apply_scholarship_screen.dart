import 'package:flutter/material.dart';

import '../../../models/student.dart';
import '../models/scholarship_model.dart';
import '../services/scholarship_service.dart';

class ApplyScholarshipScreen extends StatefulWidget {
  const ApplyScholarshipScreen({
    super.key,
    required this.scholarship,
    required this.student,
    required this.token,
  });

  final ScholarshipModel scholarship;
  final Student student;
  final String token;

  @override
  State<ApplyScholarshipScreen> createState() => _ApplyScholarshipScreenState();
}

class _ApplyScholarshipScreenState extends State<ApplyScholarshipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _statementController = TextEditingController();
  final _careerGoalController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  final _service = ScholarshipService();

  bool _isSubmitting = false;
  bool _confirmedAccuracy = false;

  @override
  void dispose() {
    _statementController.dispose();
    _careerGoalController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_confirmedAccuracy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm that your provided information is accurate.',
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Submit Application?'),
          ],
        ),
        content: Text(
          'Are you sure you want to submit your application for '
          '"${widget.scholarship.title}" to ${widget.scholarship.universityName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Review Again'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      await _service.applyForScholarship(
        scholarshipId: widget.scholarship.id,
        token: widget.token,
        personalStatement: _statementController.text.trim(),
        careerGoal: _careerGoalController.text.trim(),
        additionalNotes: _additionalNotesController.text.trim().isNotEmpty
            ? _additionalNotesController.text.trim()
            : null,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Application Submitted!'),
            ],
          ),
          content: Text(
            'Your application for "${widget.scholarship.title}" has been successfully submitted to ${widget.scholarship.universityName}. '
            'You can track its status under "My Applications".',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $errorMsg'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Apply for Scholarship',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _isSubmitting ? null : _submitApplication,
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Submit Scholarship Application',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scholarship info header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.scholarship.universityName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.scholarship.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Value: ${widget.scholarship.amount}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Student Profile Snapshot
              const Text(
                '1. Verified Profile Snapshot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'The following verified academic information will be attached with your application.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSnapshotRow('Applicant Name', student.fullName),
                    _buildSnapshotRow('Email Address', student.email),
                    if (student.school.isNotEmpty)
                      _buildSnapshotRow('School', student.school),
                    if (student.district.isNotEmpty)
                      _buildSnapshotRow('District', student.district),
                    if (student.alYear != null)
                      _buildSnapshotRow('A/L Year', '${student.alYear}'),
                    _buildSnapshotRow(
                      'A/L Stream',
                      student.stream ?? 'Not specified',
                    ),
                    if (student.alResults.isNotEmpty) ...[
                      const Divider(height: 20),
                      const Text(
                        'Subject Grades:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: student.alResults.map((r) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${r.name}: ${r.grade}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Application Details
              const Text(
                '2. Application Statement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              // Personal Statement
              TextFormField(
                controller: _statementController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Personal Statement *',
                  hintText:
                      'Explain your financial need, academic achievements, extracurriculars, and why you are an ideal candidate for this scholarship...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please provide a personal statement.';
                  }
                  if (val.trim().length < 20) {
                    return 'Personal statement should be at least 20 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Career Goal
              TextFormField(
                controller: _careerGoalController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Career Goal *',
                  hintText:
                      'Describe your intended professional career pathway and how this scholarship supports your ambitions...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please describe your career goal.';
                  }
                  if (val.trim().length < 10) {
                    return 'Career goal should be at least 10 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Additional Notes (optional)
              TextFormField(
                controller: _additionalNotesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  hintText: 'Any extra information you wish to mention...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Required Documents Notice
              if (widget.scholarship.requiredDocuments.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Required Supporting Documents',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'The university may ask you to verify the following:\n'
                              '${widget.scholarship.requiredDocuments.map((d) => '• $d').join('\n')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB45309),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Accuracy Confirmation
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: CheckboxListTile(
                  value: _confirmedAccuracy,
                  onChanged: (val) {
                    setState(() => _confirmedAccuracy = val ?? false);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  activeColor: const Color(0xFF2563EB),
                  title: const Text(
                    'I certify that all details in my profile and in this application are accurate and complete.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSnapshotRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
