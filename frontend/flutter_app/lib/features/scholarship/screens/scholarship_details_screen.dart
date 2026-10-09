import 'package:flutter/material.dart';

import '../../../models/student.dart';
import '../models/scholarship_model.dart';
import '../services/scholarship_service.dart';
import '../widgets/eligibility_badge.dart';
import 'apply_scholarship_screen.dart';
import '../../university/services/university_service.dart';

class ScholarshipDetailsScreen extends StatefulWidget {
  const ScholarshipDetailsScreen({
    super.key,
    required this.scholarship,
    required this.student,
    required this.token,
  });

  final ScholarshipModel scholarship;
  final Student student;
  final String token;

  @override
  State<ScholarshipDetailsScreen> createState() =>
      _ScholarshipDetailsScreenState();
}

class _ScholarshipDetailsScreenState extends State<ScholarshipDetailsScreen> {
  final _service = ScholarshipService();
  late ScholarshipModel _scholarship;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scholarship = widget.scholarship;
    _trackScholarshipView();
    _refreshDetails();
  }

  void _trackScholarshipView() {
    UniversityService().trackEvent(
      eventType: 'scholarship_view',
      universityId: widget.scholarship.universityId,
      scholarshipId: widget.scholarship.id,
    );
  }

  Future<void> _refreshDetails() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _service.getScholarshipById(
        _scholarship.id,
        token: widget.token,
      );
      if (!mounted) return;
      setState(() {
        _scholarship = updated;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final eligibilityResult = _scholarship.checkEligibility(widget.student);
    final isExpired =
        _scholarship.isExpired ||
        _scholarship.status.toLowerCase() == 'closed' ||
        _scholarship.status.toLowerCase() == 'expired';
    final hasApplied = _scholarship.hasApplied;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Scholarship Details',
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: isExpired
            ? FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_clock_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Applications Closed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : hasApplied
            ? FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  disabledBackgroundColor: const Color(0xFFD1FAE5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: Color(0xFF047857),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Application Submitted',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              )
            : FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final applied = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApplyScholarshipScreen(
                        scholarship: _scholarship,
                        student: widget.student,
                        token: widget.token,
                      ),
                    ),
                  );

                  if (applied == true) {
                    _refreshDetails();
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Apply for Scholarship',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : RefreshIndicator(
              onRefresh: _refreshDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // University & Title header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Center(
                            child: Text(
                              _scholarship.initials,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1D4ED8),
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _scholarship.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _scholarship.universityName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Type tag & Awards
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            _scholarship.scholarshipType,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            '${_scholarship.numberOfScholarships} Awards Available',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Highlight card: Amount & Coverage
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x332563EB),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SCHOLARSHIP VALUE / BENEFIT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Color(0xFFBFDBFE),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _scholarship.amount,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (_scholarship.coverage.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _scholarship.coverage.map((c) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Deadline banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isExpired
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isExpired
                                ? Icons.timer_off_rounded
                                : Icons.access_time_filled_rounded,
                            color: isExpired
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFD97706),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isExpired
                                      ? 'Application Deadline Expired'
                                      : 'Application Deadline',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isExpired
                                        ? const Color(0xFF991B1B)
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(_scholarship.applicationDeadline),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isExpired
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Real-time Academic Eligibility Verification
                    const Text(
                      'Your Eligibility Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    EligibilityBadge(
                      result: eligibilityResult,
                      initiallyExpanded: true,
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'About This Scholarship',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _scholarship.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Eligibility Criteria breakdown card
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
                          const Text(
                            'Eligibility Criteria',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Divider(height: 20),
                          _buildCriteriaRow(
                            'Target Stream',
                            _scholarship.eligibility.stream.isNotEmpty
                                ? _scholarship.eligibility.stream
                                : 'Open to All Streams',
                          ),
                          if (_scholarship
                              .eligibility
                              .academicRequirement
                              .isNotEmpty)
                            _buildCriteriaRow(
                              'Academic Requirement',
                              _scholarship.eligibility.academicRequirement,
                            ),
                          if (_scholarship.eligibility.district != null &&
                              _scholarship.eligibility.district!.isNotEmpty)
                            _buildCriteriaRow(
                              'District Restriction',
                              _scholarship.eligibility.district!,
                            ),
                          if (_scholarship
                              .eligibility
                              .minimumResults
                              .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Required Subject Grades:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ..._scholarship.eligibility.minimumResults.map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  bottom: 4,
                                ),
                                child: Text(
                                  '• ${r.subject} (Min grade ${r.grade})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (_scholarship.eligibility.other != null &&
                              _scholarship.eligibility.other!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildCriteriaRow(
                              'Other Requirements',
                              _scholarship.eligibility.other!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Required documents
                    if (_scholarship.requiredDocuments.isNotEmpty) ...[
                      const Text(
                        'Required Documents',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._scholarship.requiredDocuments.map((doc) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  size: 16,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  doc,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCriteriaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
