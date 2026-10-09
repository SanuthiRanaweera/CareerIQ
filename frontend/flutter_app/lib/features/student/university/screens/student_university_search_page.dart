import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../models/student.dart';
import '../models/university_comparison_model.dart';
import '../services/student_university_service.dart';
import '../widgets/compare_selection_bar.dart';
import '../widgets/student_university_card.dart';
import 'student_university_details_page.dart';
import 'university_comparison_screen.dart';
import '../../../university/services/university_service.dart';

class StudentUniversitySearchPage extends StatefulWidget {
  const StudentUniversitySearchPage({
    super.key,
    required this.token,
    required this.student,
  });

  final String token;
  final Student student;

  @override
  State<StudentUniversitySearchPage> createState() =>
      _StudentUniversitySearchPageState();
}

class _StudentUniversitySearchPageState
    extends State<StudentUniversitySearchPage> {
  final _service = StudentUniversityService();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<UniversityComparisonModel> _universities = [];
  final List<UniversityComparisonModel> _selectedForCompare = [];
  final Set<String> _favoriteIds = {};

  bool _loading = true;
  String? _error;
  String _selectedTypeFilter = 'All';
  bool _onlyFavorites = false;

  final List<String> _typeFilters = [
    'All',
    'State University',
    'Private University',
    'Non-State University',
    'Higher Educational Institute',
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await Future.wait([_loadFavorites(), _loadUniversities()]);
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await _service.getFavoriteIds(token: widget.token);
      if (!mounted) return;
      setState(() {
        _favoriteIds.clear();
        _favoriteIds.addAll(favs);
        // Also sync student.favoriteUniversities
        _favoriteIds.addAll(widget.student.favoriteUniversities);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _favoriteIds.addAll(widget.student.favoriteUniversities);
        });
      }
    }
  }

  Future<void> _loadUniversities() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _service.getUniversities(
        search: _searchController.text,
        type: _selectedTypeFilter,
        token: widget.token,
      );
      if (!mounted) return;
      setState(() {
        _universities = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      _loadUniversities,
    );
  }

  void _toggleCompare(UniversityComparisonModel uni) {
    final isAlreadySelected = _selectedForCompare.any((u) => u.id == uni.id);

    if (isAlreadySelected) {
      setState(() {
        _selectedForCompare.removeWhere((u) => u.id == uni.id);
      });
    } else {
      if (_selectedForCompare.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compare up to 3 universities at a time.'),
            backgroundColor: Color(0xFFDC2626),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      setState(() {
        _selectedForCompare.add(uni);
      });
      UniversityService().trackEvent(
        eventType: 'comparison',
        universityId: uni.id,
      );
    }
  }

  Future<void> _toggleFavorite(String universityId) async {
    final willBeFavorite = !_favoriteIds.contains(universityId);
    setState(() {
      if (willBeFavorite) {
        _favoriteIds.add(universityId);
      } else {
        _favoriteIds.remove(universityId);
      }
    });

    try {
      final isFav = await _service.toggleFavorite(
        universityId: universityId,
        token: widget.token,
      );
      if (!mounted) return;
      setState(() {
        if (isFav) {
          _favoriteIds.add(universityId);
        } else {
          _favoriteIds.remove(universityId);
        }
      });
    } catch (_) {}
  }

  void _openDetails(UniversityComparisonModel uni) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentUniversityDetailsPage(
          university: uni,
          token: widget.token,
          student: widget.student,
          isSelectedForCompare: _selectedForCompare.any((u) => u.id == uni.id),
          isFavorite: _favoriteIds.contains(uni.id),
          onToggleCompare: () => _toggleCompare(uni),
          onToggleFavorite: () => _toggleFavorite(uni.id),
        ),
      ),
    );
  }

  void _openComparisonScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniversityComparisonScreen(
          selectedUniversities: _selectedForCompare,
          token: widget.token,
          student: widget.student,
          favoriteIds: _favoriteIds,
          onRemoveUniversity: (id) {
            setState(() {
              _selectedForCompare.removeWhere((u) => u.id == id);
            });
          },
          onClearAll: () {
            setState(() {
              _selectedForCompare.clear();
            });
          },
          onToggleFavorite: (id) => _toggleFavorite(id),
        ),
      ),
    );
  }

  List<UniversityComparisonModel> get _displayedUniversities {
    var result = _universities;
    if (_onlyFavorites) {
      result = result.where((u) => _favoriteIds.contains(u.id)).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayed = _displayedUniversities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Universities'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _onlyFavorites = !_onlyFavorites);
            },
            icon: Icon(
              _onlyFavorites
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _onlyFavorites
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF64748B),
            ),
            tooltip: _onlyFavorites ? 'Show all' : 'Show favorites only',
          ),
        ],
      ),
      bottomNavigationBar: CompareSelectionBar(
        selectedUniversities: _selectedForCompare,
        onRemove: (uni) {
          setState(() {
            _selectedForCompare.removeWhere((u) => u.id == uni.id);
          });
        },
        onClearAll: () {
          setState(() {
            _selectedForCompare.clear();
          });
        },
        onCompareNow: _openComparisonScreen,
      ),
      body: RefreshIndicator(
        onRefresh: _initData,
        child: Column(
          children: [
            // Search and filters header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore & Compare Universities',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select up to 3 universities to compare programs, eligibility criteria, and options side-by-side.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search universities, locations, districts...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _loadUniversities();
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Type filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _typeFilters.map((type) {
                        final isSelected = _selectedTypeFilter == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedTypeFilter = type);
                                _loadUniversities();
                              }
                            },
                            selectedColor: const Color(0xFF3B82F6),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // University List Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 44,
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loadUniversities,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : displayed.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              size: 52,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No universities found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _onlyFavorites
                                  ? 'You have not added any universities to your favorites yet.'
                                  : _searchController.text.isNotEmpty
                                  ? 'No universities match your search query.'
                                  : 'No universities currently listed.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                            if (_onlyFavorites) ...[
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () {
                                  setState(() => _onlyFavorites = false);
                                },
                                child: const Text('Show all universities'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                      itemCount: displayed.length,
                      itemBuilder: (context, index) {
                        final uni = displayed[index];
                        final isSelected = _selectedForCompare.any(
                          (u) => u.id == uni.id,
                        );
                        final isFav = _favoriteIds.contains(uni.id);

                        return StudentUniversityCard(
                          university: uni,
                          isSelectedForCompare: isSelected,
                          isFavorite: isFav,
                          studentStream: widget.student.stream,
                          onView: () => _openDetails(uni),
                          onToggleCompare: () => _toggleCompare(uni),
                          onToggleFavorite: () => _toggleFavorite(uni.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
