import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/career.dart';
import '../../../services/api_service.dart';
import '../../../services/career_service.dart';
import '../widgets/career_card.dart' show DemandLevelBadge;
import '../widgets/career_state_views.dart';

/// Admin - Manage careers.
///
/// A compact, dense list built for an administrator rather than a student:
/// every row shows what is needed to recognise a career and act on it, with
/// editing reachable in one tap.
///
/// This screen is deliberately separate from the existing admin dashboard. It
/// talks to the real careers API, while the dashboard's careers tab is owned
/// by another member and left untouched.
class AdminManageCareersPage extends StatefulWidget {
  const AdminManageCareersPage({
    super.key,
    required this.token,
    this.onAddCareer,
    this.onEditCareer,
    this.careerService,
  });

  final String token;

  /// Opens the create form. Null until that screen is wired up.
  final VoidCallback? onAddCareer;

  /// Opens the edit form for one career.
  final void Function(Career career)? onEditCareer;

  /// Injectable API client so the screen can be tested without a backend.
  final CareerService? careerService;

  @override
  State<AdminManageCareersPage> createState() => _AdminManageCareersPageState();
}

class _AdminManageCareersPageState extends State<AdminManageCareersPage> {
  static const Duration _searchDebounce = Duration(milliseconds: 350);

  late final CareerService _careerService =
      widget.careerService ?? CareerService();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  /// Guards against a slow response for an older search term overwriting the
  /// results of a newer one.
  int _requestId = 0;

  List<Career> _careers = const [];
  bool _initialLoading = true;
  bool _filtering = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCareers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  Future<void> _loadCareers() async {
    final requestId = ++_requestId;

    setState(() {
      _error = null;
      if (!_initialLoading) _filtering = true;
    });

    try {
      final careers = await _careerService.getCareers(
        widget.token,
        search: _searchController.text.trim(),
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _careers = careers;
        _initialLoading = false;
        _filtering = false;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error.message;
        _initialLoading = false;
        _filtering = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error =
            'Could not reach the server. Check your connection and try again.';
        _initialLoading = false;
        _filtering = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, _loadCareers);
    setState(() {});
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    _loadCareers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage careers'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadCareers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: widget.onAddCareer == null
          ? null
          : FloatingActionButton.extended(
              onPressed: widget.onAddCareer,
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add career'),
            ),
      body: SafeArea(
        child: _initialLoading
            ? const CareerLoadingView(message: 'Loading careers...')
            : Column(
                children: [
                  _buildHeader(context),
                  SizedBox(
                    height: 3,
                    child: _filtering
                        ? const LinearProgressIndicator(minHeight: 3)
                        : null,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadCareers,
                      child: _buildResults(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADMIN',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 6),
          Text('Career records', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              _debounce?.cancel();
              _loadCareers();
            },
            decoration: InputDecoration(
              hintText: 'Search careers by title or industry',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _clearSearch,
                    ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_error != null) {
      return CareerErrorView(message: _error!, onRetry: _loadCareers);
    }

    if (_careers.isEmpty) {
      return _isSearching
          ? CareerEmptyView(
              icon: Icons.search_off_rounded,
              title: 'No matching careers',
              message: 'No career matches that search. Try another word.',
              onRetry: _clearSearch,
              actionLabel: 'Clear search',
            )
          : CareerEmptyView(
              icon: Icons.work_outline_rounded,
              title: 'No careers yet',
              message: 'Add the first career to get started.',
              onRetry: _loadCareers,
            );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Extra bottom padding so the floating action button never covers the
      // last row's actions.
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      children: [
        Text(
          '${_careers.length} ${_careers.length == 1 ? 'career' : 'careers'}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        ..._careers.map(
          (career) => _AdminCareerRow(
            career: career,
            onEdit: widget.onEditCareer == null
                ? null
                : () => widget.onEditCareer!(career),
          ),
        ),
      ],
    );
  }
}

/// One career row in the admin list, with its management actions.
class _AdminCareerRow extends StatelessWidget {
  const _AdminCareerRow({required this.career, this.onEdit});

  final Career career;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Tapping the row opens the same editor as the pencil, so the whole
        // card is a usable target rather than just the small icon.
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(career.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      career.category,
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        DemandLevelBadge(jobOutlook: career.jobOutlook),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            career.salaryLabel,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  // 48x48 minimum, so the action is comfortable to hit.
                  tooltip: 'Edit ${career.title}',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: const Color(0xFF3B82F6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
