import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/career.dart';
import '../../../services/api_service.dart';
import '../../../services/career_service.dart';
import '../widgets/career_card.dart';
import '../widgets/career_state_views.dart';

/// Identifies the horizontal category chip row.
const Key categoryChipsKey = Key('career-category-chips');

/// Screen 08 - Careers.
///
/// A search box and a row of category chips sit above a list of career cards
/// showing title, category, salary and demand level.
///
/// Filtering is done by the backend rather than in the widget, so the list
/// stays correct no matter how many careers exist. The screen owns its own
/// loading, empty and error states so a student always knows what is
/// happening.
class CareersListPage extends StatefulWidget {
  const CareersListPage({
    super.key,
    required this.token,
    this.onCareerSelected,
    this.onOpenShortlist,
    this.careerService,
  });

  final String token;

  /// Called when a career card is tapped. Left null until the career details
  /// screen exists, in which case the cards are not tappable.
  final void Function(Career career)? onCareerSelected;

  /// Opens the student's saved careers. When null the shortlist chip is
  /// hidden rather than shown as a dead control.
  final VoidCallback? onOpenShortlist;

  /// Injectable API client, mirroring how [CareerService] itself accepts an
  /// [ApiService]. The app leaves this null and gets the real service; tests
  /// pass a stub so the screen can be checked without a running backend.
  final CareerService? careerService;

  @override
  State<CareersListPage> createState() => _CareersListPageState();
}

class _CareersListPageState extends State<CareersListPage> {
  /// Chip shown first, meaning "do not filter by category". The backend
  /// understands this value and treats it as no filter.
  static const String _allCategories = 'All';

  /// How long to wait after the last keystroke before searching, so typing a
  /// word sends one request instead of one per letter.
  static const Duration _searchDebounce = Duration(milliseconds: 350);

  late final CareerService _careerService =
      widget.careerService ?? CareerService();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  /// Guards against out-of-order responses: a slow request for an earlier
  /// search term must not overwrite the results of a newer one.
  int _requestId = 0;

  List<Career> _careers = const [];
  List<String> _categories = const [];
  String _selectedCategory = _allCategories;

  /// Full-screen spinner, used only for the very first load.
  bool _initialLoading = true;

  /// Thin progress bar under the filters, used while re-filtering so the
  /// current results stay on screen instead of flashing away.
  bool _filtering = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCareers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedCategory != _allCategories;

  /// Category chips are built from the categories that actually exist in the
  /// database, so the filter row can never offer an empty category.
  Future<void> _loadCategories() async {
    try {
      final categories = await _careerService.getCategories(widget.token);
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
      // A failed category load is not worth blocking the screen for: the
      // careers list still works, just without the chips.
    }
  }

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
        category: _selectedCategory,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _careers = careers;
        _initialLoading = false;
        _filtering = false;
      });
    } on ApiException catch (error) {
      // The backend sends a readable message, so show that rather than a
      // generic failure notice.
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
    // Rebuild immediately so the clear button appears as soon as text is typed.
    setState(() {});
  }

  void _onCategorySelected(String category) {
    if (category == _selectedCategory) return;
    setState(() => _selectedCategory = category);
    _loadCareers();
  }

  void _clearFilters() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _selectedCategory = _allCategories);
    _loadCareers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Careers')),
      body: SafeArea(
        child: _initialLoading
            ? const CareerLoadingView(message: 'Loading careers...')
            : Column(
                children: [
                  _buildHeader(context),
                  // Reserves the same height whether or not a filter request
                  // is running, so the list does not jump up and down.
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
            'EXPLORE CAREERS',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Find your path',
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              // A chip rather than a button: the app theme gives every
              // button an infinite minimum width, which cannot sit in a Row.
              if (widget.onOpenShortlist != null)
                ActionChip(
                  avatar: const Icon(Icons.bookmark_border_rounded, size: 18),
                  label: const Text('My shortlist'),
                  onPressed: widget.onOpenShortlist,
                ),
            ],
          ),
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
              hintText: 'Search careers, skills or industries',
              prefixIcon: const Icon(Icons.search_rounded),
              // Generous tap target for clearing a search on a phone.
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _debounce?.cancel();
                        _searchController.clear();
                        setState(() {});
                        _loadCareers();
                      },
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
            ),
          ),
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildCategoryChips(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final chips = [_allCategories, ..._categories];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        // Named so the chip row can be scrolled independently of the results
        // list, both by tests and by any future scroll-to-selection logic.
        key: categoryChipsKey,
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = chips[index];
          final selected = category == _selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => _onCategorySelected(category),
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF3B82F6),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF64748B),
            ),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFCBD5E1),
            ),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_error != null) {
      return CareerErrorView(message: _error!, onRetry: _loadCareers);
    }

    if (_careers.isEmpty) {
      // Two different empty states: filters that match nothing are the
      // student's own doing and are recoverable, so offer a way out.
      return _hasActiveFilters
          ? CareerEmptyView(
              icon: Icons.search_off_rounded,
              title: 'No matching careers',
              message:
                  'Nothing matches your search and filter. Try a different word or pick another category.',
              onRetry: _clearFilters,
              actionLabel: 'Clear filters',
            )
          : CareerEmptyView(
              icon: Icons.work_outline_rounded,
              title: 'No careers yet',
              message: 'Careers added by your administrator will appear here.',
              onRetry: _loadCareers,
            );
    }

    return ListView(
      // Always scrollable so pull-to-refresh works even on a short list.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          '${_careers.length} ${_careers.length == 1 ? 'career' : 'careers'} '
          '${_hasActiveFilters ? 'found' : 'to explore'}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        ..._careers.map(
          (career) => CareerCard(
            career: career,
            onTap: widget.onCareerSelected == null
                ? null
                : () => widget.onCareerSelected!(career),
          ),
        ),
      ],
    );
  }
}
