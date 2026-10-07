import 'package:flutter/material.dart';

import '../models/scholarship_model.dart';
import '../services/scholarship_service.dart';
import '../widgets/university_scholarship_card.dart';
import 'add_scholarship_screen.dart';
import 'edit_scholarship_screen.dart';
import 'scholarship_applications_screen.dart';

class UniversityScholarshipsScreen extends StatefulWidget {
  const UniversityScholarshipsScreen({super.key});

  @override
  State<UniversityScholarshipsScreen> createState() =>
      _UniversityScholarshipsScreenState();
}

class _UniversityScholarshipsScreenState
    extends State<UniversityScholarshipsScreen> {
  final _service = ScholarshipService();
  final _searchController = TextEditingController();

  List<ScholarshipModel> _scholarships = [];
  UniversityScholarshipStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // all, active, closed, expired, draft

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statusParam = _selectedFilter == 'all' ? null : _selectedFilter;
      final query = _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null;

      final results = await Future.wait([
        _service.getUniversityScholarships(status: statusParam, search: query),
        _service.getUniversityStats(),
      ]);

      if (!mounted) return;
      setState(() {
        _scholarships = results[0] as List<ScholarshipModel>;
        _stats = results[1] as UniversityScholarshipStats;
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

  Future<void> _deleteScholarship(ScholarshipModel scholarship) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Delete Scholarship'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${scholarship.title}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.deleteScholarship(scholarship.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scholarship deleted successfully.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _toggleStatus(ScholarshipModel scholarship) async {
    final statuses = ['active', 'closed', 'draft'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Scholarship Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scholarship.title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                ...statuses.map((status) {
                  final isCurrent = scholarship.status.toLowerCase() == status;
                  return ListTile(
                    leading: Icon(
                      status == 'active'
                          ? Icons.check_circle_rounded
                          : status == 'closed'
                              ? Icons.lock_rounded
                              : Icons.edit_note_rounded,
                      color: status == 'active'
                          ? const Color(0xFF10B981)
                          : status == 'closed'
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF64748B),
                    ),
                    title: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                      ),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check, color: Color(0xFF2563EB))
                        : null,
                    onTap: () => Navigator.pop(sheetCtx, status),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected != scholarship.status.toLowerCase() && mounted) {
      try {
        await _service.updateScholarshipStatus(scholarship.id, selected);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scholarship set to ${selected[0].toUpperCase() + selected.substring(1)}.'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showDetailsDialog(ScholarshipModel s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                s.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Scholarship Type', s.scholarshipType),
              _buildDetailRow('Amount / Benefit', s.amount),
              _buildDetailRow('Total Awards', '${s.numberOfScholarships}'),
              _buildDetailRow(
                'Deadline',
                '${s.applicationDeadline.day}/${s.applicationDeadline.month}/${s.applicationDeadline.year}',
              ),
              _buildDetailRow('Status', s.status.toUpperCase()),
              if (s.coverage.isNotEmpty)
                _buildDetailRow('Coverage', s.coverage.join(', ')),
              const Divider(height: 24),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.description,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Eligibility Criteria',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Stream: ${s.eligibility.stream.isNotEmpty ? s.eligibility.stream : "All Streams"}\n'
                '• Min Results: ${s.eligibility.minimumResults.isNotEmpty ? s.eligibility.minimumResults.map((r) => '${r.subject}: ${r.grade}').join(', ') : "Any"}'
                '${s.eligibility.district != null && s.eligibility.district!.isNotEmpty ? "\n• District: ${s.eligibility.district}" : ""}'
                '${s.eligibility.other != null && s.eligibility.other!.isNotEmpty ? "\n• Other: ${s.eligibility.other}" : ""}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
              if (s.eligibility.academicRequirement.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '• Requirement: ${s.eligibility.academicRequirement}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                ),
              ],
              if (s.eligibility.minimumResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Subject Requirements:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                ...s.eligibility.minimumResults.map(
                  (req) => Text(
                    '  - ${req.subject}: Min Grade ${req.grade}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                  ),
                ),
              ],
              if (s.requiredDocuments.isNotEmpty) ...[
                const Divider(height: 24),
                const Text(
                  'Required Documents',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: s.requiredDocuments
                      .map(
                        (doc) => Chip(
                          label: Text(
                            doc,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
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

  Widget _buildStatsHeader() {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Total',
            '${_stats!.totalScholarships}',
            Icons.school_outlined,
            const Color(0xFF2563EB),
            const Color(0xFFEFF6FF),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          _buildStatItem(
            'Active',
            '${_stats!.activeScholarships}',
            Icons.verified_outlined,
            const Color(0xFF10B981),
            const Color(0xFFECFDF5),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          _buildStatItem(
            'Applications',
            '${_stats!.totalApplications}',
            Icons.assignment_outlined,
            const Color(0xFF8B5CF6),
            const Color(0xFFF5F3FF),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'active', 'label': 'Active'},
      {'key': 'closed', 'label': 'Closed'},
      {'key': 'expired', 'label': 'Expired'},
      {'key': 'draft', 'label': 'Draft'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = f['key']!);
                _loadData();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'University Scholarships',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'All Applications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScholarshipApplicationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const AddScholarshipScreen(),
            ),
          );
          if (created == true) {
            _loadData();
          }
        },
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Scholarship',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Search box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search scholarships...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadData();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _loadData(),
            ),
          ),
          _buildStatsHeader(),
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                    ),
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
                                onPressed: _loadData,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _scholarships.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.school_outlined,
                                      size: 40,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No Scholarships Found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Create your first scholarship to support students and attract top applicants.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  FilledButton.icon(
                                    onPressed: () async {
                                      final created = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AddScholarshipScreen(),
                                        ),
                                      );
                                      if (created == true) {
                                        _loadData();
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                    ),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Create Scholarship'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: _scholarships.length,
                              itemBuilder: (context, index) {
                                final s = _scholarships[index];
                                return UniversityScholarshipCard(
                                  scholarship: s,
                                  onView: () => _showDetailsDialog(s),
                                  onEdit: () async {
                                    final updated = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditScholarshipScreen(
                                          scholarship: s,
                                        ),
                                      ),
                                    );
                                    if (updated == true) {
                                      _loadData();
                                    }
                                  },
                                  onDelete: () => _deleteScholarship(s),
                                  onViewApplications: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ScholarshipApplicationsScreen(
                                          scholarshipId: s.id,
                                          scholarshipTitle: s.title,
                                        ),
                                      ),
                                    );
                                  },
                                  onToggleStatus: () => _toggleStatus(s),
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
