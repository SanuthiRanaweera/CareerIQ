import 'package:flutter/material.dart';

import '../models/admin_university_model.dart';
import '../services/university_admin_service.dart';
import '../widgets/university_card.dart';
import 'add_university_screen.dart';
import 'edit_university_screen.dart';
import 'university_details_screen.dart';

class UniversityListScreen extends StatefulWidget {
  const UniversityListScreen({
    super.key,
    this.embedded = false,
    this.onCountChanged,
  });

  final bool embedded;
  final ValueChanged<int>? onCountChanged;

  @override
  State<UniversityListScreen> createState() => _UniversityListScreenState();
}

class _UniversityListScreenState extends State<UniversityListScreen> {
  final _service = UniversityAdminService();
  final _searchController = TextEditingController();

  List<AdminUniversityModel> _universities = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUniversities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getUniversities();
      if (!mounted) return;
      setState(() {
        _universities = list;
        _isLoading = false;
      });
      widget.onCountChanged?.call(list.length);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<AdminUniversityModel> get _filteredUniversities {
    final query = _searchController.text.trim().toLowerCase();
    return _universities.where((u) {
      // Filter by status
      if (_selectedStatusFilter != 'All') {
        final targetStatus = _selectedStatusFilter.toLowerCase().replaceAll(' ', '_');
        if (targetStatus == 'active' && !u.isActive) return false;
        if (targetStatus == 'inactive' && !u.isInactive) return false;
        if (targetStatus.contains('pending') && !u.isPendingVerification) return false;
      }

      // Filter by search query
      if (query.isNotEmpty) {
        final matchesName = u.universityName.toLowerCase().contains(query);
        final matchesLoc = u.location.toLowerCase().contains(query);
        final matchesEmail = u.officialEmail.toLowerCase().contains(query);
        final matchesRep = u.representativeName.toLowerCase().contains(query);
        if (!matchesName && !matchesLoc && !matchesEmail && !matchesRep) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _navigateToAddUniversity() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddUniversityScreen()),
    );
    if (result == true && mounted) {
      _loadUniversities();
    }
  }

  Future<void> _navigateToDetails(AdminUniversityModel uni) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => UniversityDetailsScreen(university: uni)),
    );
    if (result == true && mounted) {
      _loadUniversities();
    }
  }

  Future<void> _navigateToEdit(AdminUniversityModel uni) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditUniversityScreen(university: uni)),
    );
    if (result == true && mounted) {
      _loadUniversities();
    }
  }

  Future<void> _toggleStatus(AdminUniversityModel uni) async {
    final newStatus = uni.isActive ? 'inactive' : 'active';
    try {
      final updated = await _service.updateUniversityStatus(uni.id, newStatus);
      if (!mounted) return;
      setState(() {
        final index = _universities.indexWhere((u) => u.id == uni.id);
        if (index != -1) {
          _universities[index] = updated;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${uni.universityName} ${newStatus == 'active' ? 'activated' : 'deactivated'} successfully.',
          ),
          backgroundColor: newStatus == 'active'
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(AdminUniversityModel uni) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete University'),
        content: Text(
          'Are you sure you want to delete "${uni.universityName}"? This will delete the university profile and linked user account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.deleteUniversity(uni.id);
        if (!mounted) return;
        setState(() {
          _universities.removeWhere((u) => u.id == uni.id);
        });
        widget.onCountChanged?.call(_universities.length);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('University deleted successfully.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFilterChips() {
    final options = ['All', 'Active', 'Inactive', 'Pending Verification'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isSelected = _selectedStatusFilter == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(opt),
              selected: isSelected,
              showCheckmark: false,
              backgroundColor: const Color(0xFFF1F5F9),
              selectedColor: const Color(0xFFDBEAFE),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF475569),
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (_) {
                setState(() => _selectedStatusFilter = opt);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearchingOrFiltering =
        _searchController.text.isNotEmpty || _selectedStatusFilter != 'All';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                size: 56,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No universities found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearchingOrFiltering
                  ? 'No university records match your search or filter criteria.'
                  : 'There are no registered universities in the database yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _navigateToAddUniversity,
              icon: const Icon(Icons.add_business_rounded, size: 18),
              label: const Text('Add University'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2563EB)),
            SizedBox(height: 16),
            Text(
              'Loading universities...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load universities',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadUniversities,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredUniversities;

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🏫 Universities Management',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_universities.length} registered universities',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _navigateToAddUniversity,
                    icon: const Icon(Icons.add_business_rounded, size: 18),
                    label: const Text('Add University'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      minimumSize: const Size(140, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name, location, or email...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildFilterChips(),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadUniversities,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final uni = filtered[index];
                      return UniversityCard(
                        university: uni,
                        onTap: () => _navigateToDetails(uni),
                        onEdit: () => _navigateToEdit(uni),
                        onDelete: () => _confirmDelete(uni),
                        onToggleStatus: () => _toggleStatus(uni),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Container(
        color: const Color(0xFFF8FAFC),
        child: _buildBody(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'University Management',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: _buildBody(),
    );
  }
}

