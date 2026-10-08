import 'package:flutter/material.dart';

import '../../../../models/personality_test.dart';
import '../models/admin_personality_question.dart';
import '../services/admin_personality_service.dart';
import '../widgets/admin_question_form_dialog.dart';

class AdminPersonalityQuestionsScreen extends StatefulWidget {
  const AdminPersonalityQuestionsScreen({
    super.key,
    this.onQuestionsUpdated,
  });

  final VoidCallback? onQuestionsUpdated;

  @override
  State<AdminPersonalityQuestionsScreen> createState() =>
      _AdminPersonalityQuestionsScreenState();
}

class _AdminPersonalityQuestionsScreenState
    extends State<AdminPersonalityQuestionsScreen> {
  final AdminPersonalityService _service = AdminPersonalityService();
  final TextEditingController _searchController = TextEditingController();

  List<AdminPersonalityQuestion> _allQuestions = [];
  List<AdminPersonalityQuestion> _filteredQuestions = [];
  AdminPersonalityAnalytics _analytics = const AdminPersonalityAnalytics();

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedType = 'all';
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';

  static const List<String> _typeFilters = [
    'all',
    'personality',
    'interest',
    'skills',
    'work_style',
  ];

  static const List<String> _categoryFilters = [
    'all',
    'analytical',
    'creative',
    'social',
    'leadership',
    'practical',
    'organized',
  ];

  static const List<String> _statusFilters = [
    'all',
    'active',
    'inactive',
  ];

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
      final questions = await _service.getQuestions();
      AdminPersonalityAnalytics analytics;
      try {
        analytics = await _service.getAnalytics();
      } catch (_) {
        final active = questions.where((q) => q.isActive).length;
        analytics = AdminPersonalityAnalytics(
          totalQuestions: questions.length,
          activeQuestions: active,
          inactiveQuestions: questions.length - active,
        );
      }

      if (!mounted) return;
      setState(() {
        _allQuestions = questions;
        _analytics = analytics;
        _applyFilters();
        _isLoading = false;
      });
      widget.onQuestionsUpdated?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('ApiException: ', '');
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final search = _searchController.text.trim().toLowerCase();
    _filteredQuestions = _allQuestions.where((q) {
      // Search
      if (search.isNotEmpty) {
        final matchText = q.questionText.toLowerCase().contains(search);
        final matchCat = q.category.toLowerCase().contains(search);
        final matchType = q.type.toLowerCase().contains(search);
        if (!matchText && !matchCat && !matchType) return false;
      }
      // Type
      if (_selectedType != 'all' &&
          q.type.toLowerCase() != _selectedType.toLowerCase()) {
        return false;
      }
      // Category
      if (_selectedCategory != 'all' &&
          q.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      // Status
      if (_selectedStatus == 'active' && !q.isActive) return false;
      if (_selectedStatus == 'inactive' && q.isActive) return false;

      return true;
    }).toList();
  }

  void _onSearchChanged(String _) {
    setState(() => _applyFilters());
  }

  Future<void> _openCreateDialog() async {
    final nextDisplayOrder = _allQuestions.isEmpty
        ? 1
        : (_allQuestions.map((q) => q.displayOrder).reduce(
                  (a, b) => a > b ? a : b,
                ) +
            1);

    final defaultNew = AdminPersonalityQuestion(
      id: '',
      questionText: '',
      displayOrder: nextDisplayOrder,
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdminQuestionFormDialog(
        question: defaultNew,
        onSave: (data) async {
          await _service.createQuestion(data);
        },
      ),
    );

    if (result == true) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question created successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  Future<void> _openEditDialog(AdminPersonalityQuestion question) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdminQuestionFormDialog(
        question: question,
        onSave: (data) async {
          await _service.updateQuestion(question.id, data);
        },
      ),
    );

    if (result == true) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question updated successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  Future<void> _toggleStatus(AdminPersonalityQuestion question) async {
    final newStatus = !question.isActive;
    try {
      final success = await _service.toggleStatus(question.id, newStatus);
      if (success) {
        setState(() {
          final index = _allQuestions.indexWhere((q) => q.id == question.id);
          if (index != -1) {
            _allQuestions[index] =
                _allQuestions[index].copyWith(isActive: newStatus);
            _applyFilters();
          }
        });
        widget.onQuestionsUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(AdminPersonalityQuestion question) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Delete Question'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove this question?',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${question.questionText}"',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Deactivating will hide it from students while preserving test statistics.\n• Permanent deletion will remove it completely.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (question.isActive)
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'deactivate'),
              child: const Text('Deactivate Instead'),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (result == 'deactivate') {
      await _toggleStatus(question);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question deactivated.')),
        );
      }
    } else if (result == 'delete') {
      try {
        final success = await _service.deleteQuestion(question.id, permanent: true);
        if (success) {
          _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Question deleted permanently.'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete question: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  String _formatChipLabel(String str) {
    if (str == 'all') return 'All';
    return str.split('_').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            // Page Header Banner
            _buildHeaderBanner(),
            const SizedBox(height: 18),

            // Metrics Cards Row
            _buildMetricsOverview(),
            const SizedBox(height: 20),

            // Search Bar & Filter Controls Card
            _buildSearchAndFiltersCard(),
            const SizedBox(height: 20),

            // Question List Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Personality Test Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_filteredQuestions.length}',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _openCreateDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create Question'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content Body
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              _buildErrorState()
            else if (_filteredQuestions.isEmpty)
              _buildEmptyState()
            else
              ..._filteredQuestions.asMap().entries.map((entry) {
                final index = entry.key;
                final q = entry.value;
                return _buildQuestionCard(q, index + 1);
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Question'),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334338CA),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personality Test Management 🧠',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create, update, and manage dynamic personality and interest questions served directly to students from MongoDB.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview() {
    final active = _analytics.totalQuestions > 0
        ? _analytics.activeQuestions
        : _allQuestions.where((q) => q.isActive).length;
    final inactive = _analytics.totalQuestions > 0
        ? _analytics.inactiveQuestions
        : _allQuestions.length - active;
    final total = _analytics.totalQuestions > 0
        ? _analytics.totalQuestions
        : _allQuestions.length;
    final uniqueCats = _analytics.categoryDistribution.isNotEmpty
        ? _analytics.categoryDistribution.length
        : _allQuestions.map((q) => q.category).toSet().length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Total Questions',
            value: '$total',
            icon: Icons.quiz_rounded,
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Active',
            value: '$active',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Inactive',
            value: '$inactive',
            icon: Icons.pause_circle_rounded,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFFBEB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Categories',
            value: '$uniqueCats',
            icon: Icons.category_rounded,
            color: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search input
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search Questions...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF64748B),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Filters Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Type:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              ..._typeFilters.map((t) {
                final isSelected = _selectedType == t;
                return ChoiceChip(
                  label: Text(_formatChipLabel(t)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFDBEAFE),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF475569),
                  ),
                  onSelected: (val) {
                    setState(() {
                      _selectedType = t;
                      _applyFilters();
                    });
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Category:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              ..._categoryFilters.map((c) {
                final isSelected = _selectedCategory == c;
                return ChoiceChip(
                  label: Text(_formatChipLabel(c)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFEDE9FE),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF6D28D9)
                        : const Color(0xFF475569),
                  ),
                  onSelected: (val) {
                    setState(() {
                      _selectedCategory = c;
                      _applyFilters();
                    });
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Status:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              ..._statusFilters.map((s) {
                final isSelected = _selectedStatus == s;
                return ChoiceChip(
                  label: Text(_formatChipLabel(s)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFD1FAE5),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF047857)
                        : const Color(0xFF475569),
                  ),
                  onSelected: (val) {
                    setState(() {
                      _selectedStatus = s;
                      _applyFilters();
                    });
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AdminPersonalityQuestion q, int displayIndex) {
    final catColor = getCategoryColor(q.category);
    final isReverse = q.reverseScoring;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: q.isActive
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFCBD5E1),
          width: q.isActive ? 1 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Question Index badge & Status Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Question ${q.displayOrder}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: q.isActive
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            q.isActive
                                ? Icons.check_circle_rounded
                                : Icons.pause_circle_filled_rounded,
                            size: 13,
                            color: q.isActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            q.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: q.isActive
                                  ? const Color(0xFF047857)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Quick Toggle Switch
                Row(
                  children: [
                    const Text(
                      'Live:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: q.isActive,
                      activeThumbColor: const Color(0xFF10B981),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) => _toggleStatus(q),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Question Statement
            Text(
              '"${q.questionText}"',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: q.isActive
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF64748B),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),

            // Metadata Badges (Type, Category, Reverse Scoring)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Type: ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      Text(
                        _formatChipLabel(q.type),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: catColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Category: ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: catColor,
                        ),
                      ),
                      Text(
                        getCategoryLabel(q.category),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Reverse Scoring indicator
                if (isReverse)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_vert_rounded,
                          size: 13,
                          color: Color(0xFFD97706),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Reverse Scored',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Actions row: [Edit] [Delete]
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openEditDialog(q),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF93C5FD)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(q),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(
              Icons.quiz_outlined,
              size: 54,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 14),
            const Text(
              'No questions found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try adjusting your search keywords or filter selections, or create a new question.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Question'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Failed to load questions',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

