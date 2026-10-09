import 'package:flutter/material.dart';

import '../../../models/student.dart';
import '../models/scholarship_application_model.dart';
import '../models/scholarship_model.dart';
import '../services/scholarship_service.dart';
import '../widgets/application_status_badge.dart';
import '../widgets/scholarship_card.dart';
import 'scholarship_details_screen.dart';

class ScholarshipListScreen extends StatefulWidget {
  const ScholarshipListScreen({
    super.key,
    required this.student,
    required this.token,
  });

  final Student student;
  final String token;

  @override
  State<ScholarshipListScreen> createState() => _ScholarshipListScreenState();
}

class _ScholarshipListScreenState extends State<ScholarshipListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = ScholarshipService();
  final _searchController = TextEditingController();

  List<ScholarshipModel> _scholarships = [];
  List<ScholarshipApplicationModel> _myApplications = [];
  bool _isLoadingScholarships = true;
  bool _isLoadingApplications = true;
  String? _scholarshipsError;
  String? _applicationsError;

  String _selectedType =
      'all'; // all, Merit, Need Based, Academic, Sports, Special Category, Other
  bool _filterByMyStream = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadScholarships();
    _loadMyApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadScholarships() async {
    setState(() {
      _isLoadingScholarships = true;
      _scholarshipsError = null;
    });

    try {
      final typeParam = _selectedType == 'all' ? null : _selectedType;
      final streamParam = _filterByMyStream && widget.student.stream != null
          ? widget.student.stream
          : null;
      final query = _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null;

      final items = await _service.listScholarships(
        token: widget.token,
        scholarshipType: typeParam,
        stream: streamParam,
        search: query,
      );

      if (!mounted) return;
      setState(() {
        _scholarships = items;
        _isLoadingScholarships = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scholarshipsError = e.toString().replaceAll('Exception: ', '');
        _isLoadingScholarships = false;
      });
    }
  }

  Future<void> _loadMyApplications() async {
    setState(() {
      _isLoadingApplications = true;
      _applicationsError = null;
    });

    try {
      final apps = await _service.getStudentApplications(widget.token);
      if (!mounted) return;
      setState(() {
        _myApplications = apps;
        _isLoadingApplications = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applicationsError = e.toString().replaceAll('Exception: ', '');
        _isLoadingApplications = false;
      });
    }
  }

  void _showApplicationDetailsDialog(ScholarshipApplicationModel app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.scholarshipTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.universityName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
            ApplicationStatusBadge(status: app.status),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (app.reviewNotes.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'University Feedback / Review Notes:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.reviewNotes,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                'Submitted on: ${app.createdAt.day}/${app.createdAt.month}/${app.createdAt.year}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const Divider(height: 20),
              const Text(
                'Personal Statement Submitted',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                app.personalStatement,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Career Goal Submitted',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                app.careerGoal,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
              ),
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

  Widget _buildTypeChips() {
    final types = [
      'all',
      'Merit',
      'Need Based',
      'Academic',
      'Sports',
      'Special Category',
      'Other',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Stream filter toggle
          if (widget.student.stream != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('My Stream (${widget.student.stream})'),
                selected: _filterByMyStream,
                onSelected: (selected) {
                  setState(() => _filterByMyStream = selected);
                  _loadScholarships();
                },
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFFDBEAFE),
                checkmarkColor: const Color(0xFF1D4ED8),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: _filterByMyStream
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: _filterByMyStream
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF475569),
                ),
                side: BorderSide(
                  color: _filterByMyStream
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ],
          ...types.map((type) {
            final isSelected = _selectedType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type == 'all' ? 'All Types' : type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedType = type);
                  _loadScholarships();
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
          }),
        ],
      ),
    );
  }

  Widget _buildScholarshipsTab() {
    return Column(
      children: [
        // Search Input
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search scholarships or universities...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadScholarships();
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
            onSubmitted: (_) => _loadScholarships(),
          ),
        ),
        _buildTypeChips(),
        Expanded(
          child: _isLoadingScholarships
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                )
              : _scholarshipsError != null
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
                          _scholarshipsError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadScholarships,
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
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
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
                          'No Scholarships Available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'There are no active scholarships matching your criteria right now. Check back soon!',
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
                  onRefresh: _loadScholarships,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _scholarships.length,
                    itemBuilder: (context, index) {
                      final s = _scholarships[index];
                      return ScholarshipCard(
                        scholarship: s,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScholarshipDetailsScreen(
                                scholarship: s,
                                student: widget.student,
                                token: widget.token,
                              ),
                            ),
                          );
                          _loadScholarships();
                          _loadMyApplications();
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildApplicationsTab() {
    if (_isLoadingApplications) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (_applicationsError != null) {
      return Center(
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
                _applicationsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadMyApplications,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_myApplications.isEmpty) {
      return Center(
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
                'No Applications Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You haven\'t applied for any scholarships yet. Explore open scholarships and apply now!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _tabController.animateTo(0),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Explore Scholarships'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyApplications,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _myApplications.length,
        itemBuilder: (context, index) {
          final app = _myApplications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showApplicationDetailsDialog(app),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.scholarshipTitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                app.universityName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ApplicationStatusBadge(status: app.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (app.reviewNotes.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.feedback_outlined,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                app.reviewNotes,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Applied: ${app.createdAt.day}/${app.createdAt.month}/${app.createdAt.year}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const Row(
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: Color(0xFF2563EB),
                            ),
                          ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Scholarships & Grants',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Available Scholarships'),
            Tab(text: 'My Applications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildScholarshipsTab(), _buildApplicationsTab()],
      ),
    );
  }
}
