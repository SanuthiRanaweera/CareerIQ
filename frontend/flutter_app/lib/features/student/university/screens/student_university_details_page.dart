import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/student.dart';
import '../models/university_comparison_model.dart';
import '../services/student_university_service.dart';

class StudentUniversityDetailsPage extends StatefulWidget {
  const StudentUniversityDetailsPage({
    super.key,
    required this.university,
    required this.token,
    required this.student,
    required this.isSelectedForCompare,
    required this.isFavorite,
    required this.onToggleCompare,
    required this.onToggleFavorite,
  });

  final UniversityComparisonModel university;
  final String token;
  final Student student;
  final bool isSelectedForCompare;
  final bool isFavorite;
  final VoidCallback onToggleCompare;
  final VoidCallback onToggleFavorite;

  @override
  State<StudentUniversityDetailsPage> createState() =>
      _StudentUniversityDetailsPageState();
}

class _StudentUniversityDetailsPageState
    extends State<StudentUniversityDetailsPage> {
  final _service = StudentUniversityService();
  late UniversityComparisonModel _university;
  late bool _isSelected;
  late bool _isFavorite;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _university = widget.university;
    _isSelected = widget.isSelectedForCompare;
    _isFavorite = widget.isFavorite;
    _loadFullDetails();
  }

  Future<void> _loadFullDetails() async {
    try {
      final details = await _service.getUniversityDetails(
        id: _university.id,
        token: widget.token,
      );
      if (!mounted) return;
      setState(() {
        _university = details;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentStream = widget.student.stream;

    return Scaffold(
      appBar: AppBar(
        title: Text(_university.universityName),
        actions: [
          IconButton(
            onPressed: () {
              widget.onToggleFavorite();
              setState(() => _isFavorite = !_isFavorite);
            },
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? const Color(0xFFEF4444) : const Color(0xFF64748B),
            ),
            tooltip: _isFavorite ? 'Remove favorite' : 'Add favorite',
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: FilledButton.icon(
          onPressed: () {
            widget.onToggleCompare();
            setState(() => _isSelected = !_isSelected);
          },
          style: FilledButton.styleFrom(
            backgroundColor: _isSelected
                ? const Color(0xFF10B981)
                : const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(
            _isSelected ? Icons.check_circle_rounded : Icons.compare_arrows_rounded,
          ),
          label: Text(
            _isSelected ? 'Added to Comparison' : '+ Add to Comparison',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                // Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
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
                                  _university.initials,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1D4ED8),
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _university.universityName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 15,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _university.location,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _university.universityType,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_university.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),
                          Text(
                            _university.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Key Information
                Text(
                  'BASIC INFORMATION',
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Established Year',
                          value: _university.establishedYear != null
                              ? '${_university.establishedYear}'
                              : 'Not available',
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _DetailRow(
                          icon: Icons.map_outlined,
                          label: 'District & Country',
                          value: _university.district.isNotEmpty
                              ? '${_university.district}, ${_university.country}'
                              : _university.country,
                        ),
                        if (_university.address.isNotEmpty) ...[
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _DetailRow(
                            icon: Icons.place_outlined,
                            label: 'Full Address',
                            value: _university.address,
                          ),
                        ],
                        if (_university.website != null &&
                            _university.website!.isNotEmpty) ...[
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _DetailRow(
                            icon: Icons.language_outlined,
                            label: 'Official Website',
                            value: _university.website!,
                            isLink: true,
                            onTap: () => _copyToClipboard(
                              _university.website!,
                              'Website',
                            ),
                          ),
                        ],
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _DetailRow(
                          icon: Icons.email_outlined,
                          label: 'Official Email',
                          value: _university.officialEmail,
                          onTap: () => _copyToClipboard(
                            _university.officialEmail,
                            'Email',
                          ),
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _DetailRow(
                          icon: Icons.phone_outlined,
                          label: 'Contact Number',
                          value: _university.contactNumber,
                          onTap: () => _copyToClipboard(
                            _university.contactNumber,
                            'Phone number',
                          ),
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _DetailRow(
                          icon: Icons.payments_outlined,
                          label: 'Tuition Fees',
                          value: _university.feeDisplay,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Courses Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'OFFERED COURSES (${_university.courses.length})',
                      style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_university.courses.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              size: 40,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'No courses currently listed',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Course details will appear when programs are registered.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ..._university.courses.map((course) {
                    final matches = studentStream != null &&
                        studentStream.isNotEmpty &&
                        (course.stream.toLowerCase() ==
                                studentStream.toLowerCase() ||
                            course.stream.toLowerCase() == 'any');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        course.degreeType,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (matches)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFA7F3D0),
                                      ),
                                    ),
                                    child: const Text(
                                      'Stream Match',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                _CoursePill(
                                  icon: Icons.layers_outlined,
                                  label: 'Stream: ${course.stream}',
                                ),
                                _CoursePill(
                                  icon: Icons.schedule_outlined,
                                  label:
                                      '${course.durationYears.toInt()} Years',
                                ),
                                if (course.minZScore != null)
                                  _CoursePill(
                                    icon: Icons.grade_outlined,
                                    label:
                                        'Min Z-Score: ${course.minZScore!.toStringAsFixed(2)}',
                                  ),
                              ],
                            ),
                            if (course.subjects.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Subject Requirements: ${course.subjects.join(', ')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isLink
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF1E293B),
                        decoration:
                            isLink ? TextDecoration.underline : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      );
}

class _CoursePill extends StatelessWidget {
  const _CoursePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      );
}

