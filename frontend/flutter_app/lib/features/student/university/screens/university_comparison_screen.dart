import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/student.dart';
import '../models/university_comparison_model.dart';
import '../services/student_university_service.dart';

class UniversityComparisonScreen extends StatefulWidget {
  const UniversityComparisonScreen({
    super.key,
    required this.selectedUniversities,
    required this.token,
    required this.student,
    required this.onRemoveUniversity,
    required this.onClearAll,
    required this.onToggleFavorite,
    required this.favoriteIds,
  });

  final List<UniversityComparisonModel> selectedUniversities;
  final String token;
  final Student student;
  final ValueChanged<String> onRemoveUniversity;
  final VoidCallback onClearAll;
  final ValueChanged<String> onToggleFavorite;
  final Set<String> favoriteIds;

  @override
  State<UniversityComparisonScreen> createState() =>
      _UniversityComparisonScreenState();
}

class _UniversityComparisonScreenState
    extends State<UniversityComparisonScreen> {
  final _service = StudentUniversityService();
  List<UniversityComparisonModel> _universities = [];
  bool _loading = true;
  String? _error;
  late Set<String> _localFavorites;

  // Course level filter
  String _selectedStreamFilter = 'All';

  @override
  void initState() {
    super.initState();
    _localFavorites = Set.from(widget.favoriteIds);
    _loadComparisonData();
  }

  Future<void> _loadComparisonData() async {
    final ids = widget.selectedUniversities.map((u) => u.id).toList();
    if (ids.length < 2) {
      setState(() {
        _universities = List.from(widget.selectedUniversities);
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _service.getCompareUniversities(
        ids: ids,
        token: widget.token,
      );
      if (!mounted) return;
      setState(() {
        _universities = list.isNotEmpty
            ? list
            : List.from(widget.selectedUniversities);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Fallback to local passed list if compare endpoint had transient error
        _universities = List.from(widget.selectedUniversities);
        _loading = false;
      });
    }
  }

  void _remove(String id) {
    widget.onRemoveUniversity(id);
    setState(() {
      _universities.removeWhere((u) => u.id == id);
    });
  }

  Future<void> _toggleFavorite(String universityId) async {
    widget.onToggleFavorite(universityId);
    setState(() {
      if (_localFavorites.contains(universityId)) {
        _localFavorites.remove(universityId);
      } else {
        _localFavorites.add(universityId);
      }
    });

    try {
      await _service.toggleFavorite(
        universityId: universityId,
        token: widget.token,
      );
    } catch (_) {}
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
        title: const Text('Compare Universities'),
        actions: [
          if (_universities.length >= 2) ...[
            TextButton(
              onPressed: () {
                widget.onClearAll();
                setState(() => _universities.clear());
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Clear All'),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading comparison data...',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadComparisonData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _universities.length < 2
                  ? _buildEmptyState(context)
                  : _buildComparisonContent(context, theme, studentStream),
    );
  }

  // ==================================================
  // EMPTY STATE
  // ==================================================
  Widget _buildEmptyState(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  size: 44,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select two or more universities to compare.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add up to 3 universities from the list to see side-by-side details, courses, eligibility criteria, and more.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.school_outlined, size: 18),
                label: const Text('Browse Universities'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ==================================================
  // COMPARISON CONTENT (SIDE BY SIDE)
  // ==================================================
  Widget _buildComparisonContent(
    BuildContext context,
    ThemeData theme,
    String? studentStream,
  ) {
    const double labelColumnWidth = 130.0;
    const double uniColumnWidth = 185.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle and counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comparing ${_universities.length} Universities',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (_universities.length < 3)
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add University'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),

          // Horizontal scrollable table container
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: labelColumnWidth + (_universities.length * uniColumnWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ROW (Cards for each university) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: labelColumnWidth,
                        child: Padding(
                          padding: EdgeInsets.only(top: 24, right: 12),
                          child: Text(
                            'OVERVIEW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ),
                      ..._universities.map(
                        (uni) => SizedBox(
                          width: uniColumnWidth,
                          child: _buildUniversityHeaderCard(
                            uni,
                            studentStream,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- 1. BASIC INFORMATION ---
                  _buildSectionHeader('1. BASIC INFORMATION'),
                  _buildComparisonRow(
                    label: 'University Name',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities.map((u) => u.universityName).toList(),
                    isBold: true,
                  ),
                  _buildComparisonRow(
                    label: 'Location',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities.map((u) => u.location).toList(),
                  ),
                  _buildComparisonRow(
                    label: 'District',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => u.district.isNotEmpty ? u.district : 'N/A')
                        .toList(),
                  ),
                  _buildComparisonRow(
                    label: 'Country',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities.map((u) => u.country).toList(),
                  ),
                  _buildComparisonRow(
                    label: 'University Type',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities.map((u) => u.universityType).toList(),
                    highlightChip: true,
                  ),
                  _buildComparisonRow(
                    label: 'Established Year',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => u.establishedYear != null
                            ? '${u.establishedYear}'
                            : 'Not available')
                        .toList(),
                  ),
                  _buildComparisonRow(
                    label: 'Official Website',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => (u.website != null && u.website!.isNotEmpty)
                            ? u.website!
                            : 'Not available')
                        .toList(),
                    isLink: true,
                    onTapLink: (val) {
                      if (val != 'Not available') {
                        _copyToClipboard(val, 'Website');
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // --- 2. CONTACT INFORMATION ---
                  _buildSectionHeader('2. CONTACT INFORMATION'),
                  _buildComparisonRow(
                    label: 'Official Email',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => u.officialEmail.isNotEmpty
                            ? u.officialEmail
                            : 'Not available')
                        .toList(),
                    onTapLink: (val) {
                      if (val != 'Not available') {
                        _copyToClipboard(val, 'Email');
                      }
                    },
                  ),
                  _buildComparisonRow(
                    label: 'Contact Number',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => u.contactNumber.isNotEmpty
                            ? u.contactNumber
                            : 'Not available')
                        .toList(),
                    onTapLink: (val) {
                      if (val != 'Not available') {
                        _copyToClipboard(val, 'Phone');
                      }
                    },
                  ),
                  _buildComparisonRow(
                    label: 'Address',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => u.address.isNotEmpty
                            ? u.address
                            : 'Not available')
                        .toList(),
                  ),
                  const SizedBox(height: 14),

                  // --- 3. COURSES & DEGREE OPTIONS ---
                  _buildSectionHeader('3. COURSES & DEGREE OPTIONS'),
                  _buildComparisonRow(
                    label: 'Total Courses',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => '${u.courseCount} Programs')
                        .toList(),
                    isBold: true,
                    highlightBadge: true,
                  ),
                  _buildComparisonWidgetRow(
                    label: 'Offered Degrees',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    builder: (index) {
                      final uni = _universities[index];
                      if (uni.degreeTitles.isEmpty) {
                        return const Text(
                          'No courses listed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: uni.degreeTitles.take(4).map<Widget>((title) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF3B82F6))),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList()
                          ..addAll(
                            uni.degreeTitles.length > 4
                                ? [
                                    Text(
                                      '+ ${uni.degreeTitles.length - 4} more',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ]
                                : [],
                          ),
                      );
                    },
                  ),
                  _buildComparisonRow(
                    label: 'Offered Streams',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => u.streams.isNotEmpty
                            ? u.streams.join(', ')
                            : 'Not available')
                        .toList(),
                  ),
                  const SizedBox(height: 14),

                  // --- 4. ELIGIBILITY & ENTRY CRITERIA ---
                  _buildSectionHeader('4. ELIGIBILITY & ENTRY CRITERIA'),
                  _buildComparisonRow(
                    label: 'Min Z-Score',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => u.zScoreDisplay)
                        .toList(),
                    isBold: true,
                  ),
                  _buildComparisonWidgetRow(
                    label: 'Stream Match',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    builder: (index) {
                      final uni = _universities[index];
                      final matches = uni.matchesStream(studentStream);
                      if (studentStream == null || studentStream.isEmpty) {
                        return Text(
                          uni.streams.isNotEmpty
                              ? uni.streams.join(', ')
                              : 'Not available',
                          style: const TextStyle(fontSize: 12),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: matches
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: matches
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          matches
                              ? 'Matches $studentStream'
                              : 'Stream: ${uni.streams.isNotEmpty ? uni.streams.join(', ') : "N/A"}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: matches
                                ? const Color(0xFF047857)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildComparisonWidgetRow(
                    label: 'Subject Requirements',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    builder: (index) {
                      final uni = _universities[index];
                      if (uni.subjects.isEmpty) {
                        return const Text(
                          'Not specified',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        );
                      }
                      return Text(
                        uni.subjects.take(4).join(', '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // --- 5. FEES & STUDY INFO ---
                  _buildSectionHeader('5. FEES & STUDY INFO'),
                  _buildComparisonRow(
                    label: 'Tuition Fees',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities.map((u) => u.feeDisplay).toList(),
                    isBold: true,
                  ),
                  _buildComparisonRow(
                    label: 'Study Duration',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => u.durationDisplay)
                        .toList(),
                  ),
                  _buildComparisonRow(
                    label: 'Degree Types',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => u.degreeTypes.isNotEmpty
                            ? u.degreeTypes.join(', ')
                            : 'Bachelor\'s Degree')
                        .toList(),
                  ),
                  const SizedBox(height: 14),

                  // --- 6. LOCATION DETAILS ---
                  _buildSectionHeader('6. LOCATION DETAILS'),
                  _buildComparisonRow(
                    label: 'City / Town',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => u.city.isNotEmpty ? u.city : u.location)
                        .toList(),
                  ),
                  _buildComparisonRow(
                    label: 'District',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities
                        .map((u) => u.district.isNotEmpty ? u.district : 'N/A')
                        .toList(),
                  ),
                  _buildComparisonRow(
                    label: 'Country',
                    labelWidth: labelColumnWidth,
                    colWidth: uniColumnWidth,
                    values: _universities.map((u) => u.country).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ==================================================
          // COURSE-LEVEL COMPARISON SECTION
          // ==================================================
          _buildCourseLevelComparisonSection(context, theme, studentStream),
        ],
      ),
    );
  }

  // Header Card for top of each university column
  Widget _buildUniversityHeaderCard(
    UniversityComparisonModel uni,
    String? studentStream,
  ) {
    final isFav = _localFavorites.contains(uni.id);

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Favorite button
              IconButton(
                onPressed: () => _toggleFavorite(uni.id),
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF94A3B8),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: isFav ? 'Remove favorite' : 'Add favorite',
              ),
              // Remove button
              IconButton(
                onPressed: () => _remove(uni.id),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Remove',
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Initials Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Center(
              child: Text(
                uni.initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D4ED8),
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            uni.universityName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            uni.location,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              uni.universityType,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Color(0xFF3B82F6),
          ),
        ),
      );

  // Row for plain text values
  Widget _buildComparisonRow({
    required String label,
    required double labelWidth,
    required double colWidth,
    required List<String> values,
    bool isBold = false,
    bool isLink = false,
    bool highlightChip = false,
    bool highlightBadge = false,
    ValueChanged<String>? onTapLink,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            ...values.map(
              (val) => SizedBox(
                width: colWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: onTapLink != null ? () => onTapLink(val) : null,
                    borderRadius: BorderRadius.circular(4),
                    child: highlightChip
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              val,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          )
                        : Text(
                            val,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isBold ? FontWeight.w700 : FontWeight.w500,
                              color: isLink
                                  ? const Color(0xFF2563EB)
                                  : highlightBadge
                                      ? const Color(0xFF0F766E)
                                      : const Color(0xFF1E293B),
                              decoration: isLink
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  // Row for custom widgets per university
  Widget _buildComparisonWidgetRow({
    required String label,
    required double labelWidth,
    required double colWidth,
    required Widget Function(int index) builder,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            for (int i = 0; i < _universities.length; i++)
              SizedBox(
                width: colWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: builder(i),
                ),
              ),
          ],
        ),
      );

  // ==================================================
  // COURSE-LEVEL COMPARISON WIDGET
  // ==================================================
  Widget _buildCourseLevelComparisonSection(
    BuildContext context,
    ThemeData theme,
    String? studentStream,
  ) {
    // Collect all courses from all compared universities
    final allStreams = <String>{'All'};
    for (final uni in _universities) {
      for (final course in uni.courses) {
        if (course.stream.isNotEmpty) allStreams.add(course.stream);
      }
    }

    final hasAnyCourses = _universities.any((u) => u.courses.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 20,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course-by-Course Comparison',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Compare specific degree programs side-by-side',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stream filter chips
          if (allStreams.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allStreams.map((stream) {
                  final selected = _selectedStreamFilter == stream;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(stream),
                      selected: selected,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedStreamFilter = stream);
                        }
                      },
                      selectedColor: const Color(0xFF3B82F6),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : const Color(0xFF334155),
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (!hasAnyCourses)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 36,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No registered courses for these universities yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Courses will appear here once universities publish them.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // Side-by-side course listing for each university
            for (final uni in _universities) ...[
              _buildUniversityCourseBlock(uni, studentStream),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildUniversityCourseBlock(
    UniversityComparisonModel uni,
    String? studentStream,
  ) {
    final filteredCourses = uni.courses.where((c) {
      if (_selectedStreamFilter == 'All') return true;
      return c.stream.toLowerCase() == _selectedStreamFilter.toLowerCase();
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Text(
                    uni.initials,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    uni.universityName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Text(
                  '${filteredCourses.length} ${filteredCourses.length == 1 ? "Course" : "Courses"}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (filteredCourses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No courses matching this stream filter.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...filteredCourses.map((c) {
                final matches = studentStream != null &&
                    studentStream.isNotEmpty &&
                    (c.stream.toLowerCase() == studentStream.toLowerCase() ||
                        c.stream.toLowerCase() == 'any');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              c.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (matches)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Matches Stream',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Stream: ${c.stream}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                          ),
                          Text(
                            'Duration: ${c.durationYears.toInt()} Yrs',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                          ),
                          if (c.minZScore != null)
                            Text(
                              'Min Z: ${c.minZScore!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                        ],
                      ),
                      if (c.subjects.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Subjects: ${c.subjects.join(", ")}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

