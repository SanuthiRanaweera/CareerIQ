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
    this.embedded = false,
    this.onCountChanged,
  });

  final String token;

  /// True when this screen is shown inside another page's content area, such
  /// as a tab of the admin dashboard. The app bar is then left out so the
  /// host page's own header is the only one on screen; the refresh action
  /// lives in the body header, so nothing is lost.
  final bool embedded;

  /// Reports the total number of careers whenever an unfiltered list loads,
  /// so a host page can show the real count. Searches are not reported.
  final ValueChanged<int>? onCountChanged;

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

  /// Id of the career currently being deleted, so that row can show progress
  /// and its controls can be disabled while the request is in flight.
  String? _deletingId;

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
      if (!_isSearching) widget.onCountChanged?.call(careers.length);
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

  /// Asks for confirmation before deleting, then deletes.
  ///
  /// Deleting a career cannot be undone, so the dialog names the career being
  /// removed rather than asking a generic "are you sure". Cancel is the
  /// default-looking action and the destructive one is coloured red.
  Future<void> _confirmAndDelete(Career career) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete career?'),
        content: Text('Delete "${career.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              minimumSize: const Size(100, 44),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _deleteCareer(career);
  }

  Future<void> _deleteCareer(Career career) async {
    setState(() => _deletingId = career.id);

    try {
      await _careerService.deleteCareer(widget.token, career.id);
      if (!mounted) return;
      setState(() => _deletingId = null);
      showCareerMessage(context, '${career.title} deleted', success: true);
      // Reload rather than removing locally, so the list matches the server.
      await _loadCareers();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      showCareerMessage(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      showCareerMessage(
        context,
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Manage careers')),
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
                  const Divider(height: 1),
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

  /// One header serves both modes, with a few conditional differences rather
  /// than two separate layouts.
  ///
  /// Embedded in the admin dashboard it copies the pattern used by the
  /// Students, Universities and Courses tabs: a white band, an emoji title at
  /// 22/w800, a grey count line beneath it, the add action as a filled button
  /// on the right, and their search-field styling. Standalone it keeps its
  /// own heading, because the app bar already names the screen.
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final embedded = widget.embedded;
    final count = _careers.length;

    return Container(
      color: embedded ? Colors.white : null,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                      embedded
                          ? '\u{1F4BC} Careers Management'
                          : 'Career records',
                      style: embedded
                          ? const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            )
                          : theme.textTheme.headlineMedium,
                    ),
                    // Embedded, the subtitle carries the record count the way
                    // the other tabs do, so the body does not repeat it.
                    if (embedded)
                      Text(
                        '$count career ${count == 1 ? 'pathway' : 'pathways'} '
                        'mapped to personality test results',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadCareers,
                icon: const Icon(Icons.refresh_rounded),
              ),
              if (widget.onAddCareer != null) ...[
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: widget.onAddCareer,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add career'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(130, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              _debounce?.cancel();
              _loadCareers();
            },
            decoration: InputDecoration(
              hintText: 'Search careers by title, industry, or demand level...',
              prefixIcon: const Icon(Icons.search_rounded),
              fillColor: const Color(0xFFF1F5F9),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _clearSearch,
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
      // Same list inset as the other admin tabs. No extra bottom padding is
      // needed now that the add action sits in the header rather than in a
      // floating button.
      padding: const EdgeInsets.all(16),
      children: [
        // Embedded, the header subtitle already states the count.
        if (!widget.embedded) ...[
          Text(
            '${_careers.length} ${_careers.length == 1 ? 'career' : 'careers'}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
        ],
        ..._careers.map(
          (career) => _AdminCareerRow(
            career: career,
            embedded: widget.embedded,
            deleting: _deletingId == career.id,
            onEdit: widget.onEditCareer == null
                ? null
                : () => widget.onEditCareer!(career),
            onDelete: () => _confirmAndDelete(career),
          ),
        ),
      ],
    );
  }
}

/// One career row in the admin list, with its management actions.
class _AdminCareerRow extends StatelessWidget {
  const _AdminCareerRow({
    required this.career,
    this.onEdit,
    this.onDelete,
    this.deleting = false,
    this.embedded = false,
  });

  final Career career;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// True while this career's delete request is running.
  final bool deleting;

  /// True inside the admin dashboard, where the row copies the card styling of
  /// the Students, Universities and Courses tabs instead of the student theme.
  final bool embedded;

  // Badge colours per demand level, the same palette as DemandLevelBadge.
  static const Map<String, (Color, Color)> _demandColours = {
    'Very High': (Color(0xFFDCFCE7), Color(0xFF15803D)),
    'High': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    'Medium': (Color(0xFFFEF3C7), Color(0xFFB45309)),
    'Low': (Color(0xFFF1F5F9), Color(0xFF475569)),
  };

  /// Demand badge sized like the admin tabs' badges (11 / w700, radius 8).
  Widget _adminDemandBadge() {
    if (career.jobOutlook.isEmpty) return const SizedBox.shrink();
    final colours =
        _demandColours[career.jobOutlook] ??
        const (Color(0xFFF1F5F9), Color(0xFF475569));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colours.$1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${career.jobOutlook} demand',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colours.$2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: embedded ? 0 : null,
      shape: embedded
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            )
          : null,
      child: InkWell(
        // Tapping the row opens the same editor as the pencil, so the whole
        // card is a usable target rather than just the small icon. Disabled
        // mid-delete so the record cannot be edited while it is going away.
        onTap: deleting ? null : onEdit,
        child: Padding(
          padding: embedded
              ? const EdgeInsets.fromLTRB(16, 16, 10, 16)
              : const EdgeInsets.fromLTRB(18, 14, 10, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      career.title,
                      style: embedded
                          ? const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            )
                          : theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      career.category,
                      style: embedded
                          ? const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            )
                          : theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        embedded
                            ? _adminDemandBadge()
                            : DemandLevelBadge(jobOutlook: career.jobOutlook),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            career.salaryLabel,
                            style: embedded
                                ? const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  )
                                : theme.textTheme.bodyLarge?.copyWith(
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
              if (deleting)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else ...[
                if (onEdit != null)
                  IconButton(
                    // 48x48 minimum, so the action is comfortable to hit.
                    tooltip: 'Edit ${career.title}',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    color: const Color(0xFF3B82F6),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete ${career.title}',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: const Color(0xFFDC2626),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
