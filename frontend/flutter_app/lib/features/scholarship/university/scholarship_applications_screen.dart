import 'package:flutter/material.dart';

import '../models/scholarship_application_model.dart';
import '../services/scholarship_service.dart';
import '../widgets/application_status_badge.dart';

class ScholarshipApplicationsScreen extends StatefulWidget {
  const ScholarshipApplicationsScreen({
    super.key,
    this.scholarshipId,
    this.scholarshipTitle,
  });

  final String? scholarshipId;
  final String? scholarshipTitle;

  @override
  State<ScholarshipApplicationsScreen> createState() =>
      _ScholarshipApplicationsScreenState();
}

class _ScholarshipApplicationsScreenState
    extends State<ScholarshipApplicationsScreen> {
  final _service = ScholarshipService();

  List<ScholarshipApplicationModel> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all'; // all, pending, under_review, shortlisted, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statusParam = _selectedStatus == 'all' ? null : _selectedStatus;
      final apps = await _service.getUniversityApplications(
        scholarshipId: widget.scholarshipId,
        status: statusParam,
      );

      if (!mounted) return;
      setState(() {
        _applications = apps;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showReviewBottomSheet(ScholarshipApplicationModel app) {
    String currentStatus = app.status;
    final notesController = TextEditingController(text: app.reviewNotes);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text(
                                  app.studentName.isNotEmpty
                                      ? app.studentName[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2563EB),
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.studentName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      app.scholarshipTitle,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ApplicationStatusBadge(status: currentStatus),
                            ],
                          ),
                          const Divider(height: 28),

                          // Academic details
                          const Text(
                            'Student Academic Profile',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow('Email', app.studentEmail),
                                if (app.studentPhone != null &&
                                    app.studentPhone!.isNotEmpty)
                                  _buildInfoRow('Phone', app.studentPhone!),
                                if (app.school.isNotEmpty)
                                  _buildInfoRow('School', app.school),
                                if (app.district.isNotEmpty)
                                  _buildInfoRow('District', app.district),
                                _buildInfoRow(
                                  'A/L Stream',
                                  app.stream.isNotEmpty
                                      ? app.stream
                                      : 'Not specified',
                                ),
                                if (app.zScore != null)
                                  _buildInfoRow(
                                    'Z-Score',
                                    app.zScore!.toStringAsFixed(4),
                                  ),
                              ],
                            ),
                          ),

                          // AL Results
                          if (app.alResults.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'G.C.E. A/L Examination Results',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: app.alResults.map((r) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Text(
                                    '${r.name}: ${r.grade}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          // Personal Statement
                          const SizedBox(height: 20),
                          const Text(
                            'Personal Statement',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              app.personalStatement.isNotEmpty
                                  ? app.personalStatement
                                  : 'No personal statement provided.',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),

                          // Career Goal
                          if (app.careerGoal.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Career Goal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                app.careerGoal,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],

                          // Status Update Controls
                          const Divider(height: 32),
                          const Text(
                            'Review Decision & Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildStatusChip(
                                label: 'Under Review',
                                value: 'under_review',
                                color: const Color(0xFF0284C7),
                                current: currentStatus,
                                onSelect: () => setSheetState(
                                    () => currentStatus = 'under_review'),
                              ),
                              _buildStatusChip(
                                label: 'Shortlisted',
                                value: 'shortlisted',
                                color: const Color(0xFF8B5CF6),
                                current: currentStatus,
                                onSelect: () => setSheetState(
                                    () => currentStatus = 'shortlisted'),
                              ),
                              _buildStatusChip(
                                label: 'Approved',
                                value: 'approved',
                                color: const Color(0xFF10B981),
                                current: currentStatus,
                                onSelect: () => setSheetState(
                                    () => currentStatus = 'approved'),
                              ),
                              _buildStatusChip(
                                label: 'Rejected',
                                value: 'rejected',
                                color: const Color(0xFFEF4444),
                                current: currentStatus,
                                onSelect: () => setSheetState(
                                    () => currentStatus = 'rejected'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Review Notes & Feedback for Student',
                              hintText:
                                  'E.g. Congratulations! Please submit your identity documents by Friday.',
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setSheetState(() => isSaving = true);
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      await _service.updateApplicationStatus(
                                        applicationId: app.id,
                                        status: currentStatus,
                                        reviewNotes:
                                            notesController.text.trim().isNotEmpty
                                                ? notesController.text.trim()
                                                : null,
                                      );
                                      if (sheetCtx.mounted) {
                                        Navigator.pop(sheetCtx);
                                      }
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Application updated & student notified.',
                                          ),
                                          backgroundColor: Color(0xFF10B981),
                                        ),
                                      );
                                      _loadApplications();
                                    } catch (err) {
                                      setSheetState(() => isSaving = false);
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Update failed: ${err.toString().replaceAll('Exception: ', '')}',
                                          ),
                                          backgroundColor:
                                              const Color(0xFFEF4444),
                                        ),
                                      );
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Update Application Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip({
    required String label,
    required String value,
    required Color color,
    required String current,
    required VoidCallback onSelect,
  }) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(),
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? color : const Color(0xFF64748B),
      ),
      side: BorderSide(
        color: isSelected ? color : const Color(0xFFCBD5E1),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'under_review', 'label': 'Under Review'},
      {'key': 'shortlisted', 'label': 'Shortlisted'},
      {'key': 'approved', 'label': 'Approved'},
      {'key': 'rejected', 'label': 'Rejected'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStatus == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedStatus = f['key']!);
                _loadApplications();
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFEFF6FF),
              checkmarkColor: const Color(0xFF2563EB),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.scholarshipTitle != null
        ? '${widget.scholarshipTitle} - Applications'
        : 'Scholarship Applications';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _loadApplications,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _applications.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.assignment_outlined,
                                      size: 40,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No Applications Received',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Student applications will appear here once submitted.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadApplications,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _applications.length,
                              itemBuilder: (context, index) {
                                final app = _applications[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _showReviewBottomSheet(app),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor:
                                                    const Color(0xFFEFF6FF),
                                                child: Text(
                                                  app.studentName.isNotEmpty
                                                      ? app.studentName[0]
                                                          .toUpperCase()
                                                      : 'S',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      app.studentName,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                    if (widget.scholarshipId ==
                                                        null) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        app.scholarshipTitle,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Color(0xFF2563EB),
                                                        ),
                                                      ),
                                                    ],
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${app.stream} Stream'
                                                      '${app.zScore != null ? ' • Z: ${app.zScore!.toStringAsFixed(4)}' : ''}'
                                                      '${app.district.isNotEmpty ? ' • ${app.district}' : ''}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              ApplicationStatusBadge(
                                                status: app.status,
                                              ),
                                            ],
                                          ),
                                          if (app.personalStatement
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Text(
                                              app.personalStatement,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF475569),
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Applied: ${app.createdAt.day}/${app.createdAt.month}/${app.createdAt.year}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              ),
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  side: const BorderSide(
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                                onPressed: () =>
                                                    _showReviewBottomSheet(app),
                                                icon: const Icon(
                                                  Icons.rate_review_outlined,
                                                  size: 16,
                                                  color: Color(0xFF2563EB),
                                                ),
                                                label: const Text(
                                                  'Review',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
