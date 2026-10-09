import 'package:flutter/material.dart';
import '../models/university_analytics_model.dart';
import '../services/university_service.dart';
import '../widgets/analytics_chart.dart';
import '../widgets/analytics_filter.dart';
import '../widgets/analytics_summary_card.dart';
import '../widgets/course_analytics_card.dart';
import '../widgets/scholarship_analytics_card.dart';
import 'university_courses_screen.dart';

class UniversityAnalyticsScreen extends StatefulWidget {
  const UniversityAnalyticsScreen({super.key, this.universityName});

  final String? universityName;

  @override
  State<UniversityAnalyticsScreen> createState() =>
      _UniversityAnalyticsScreenState();
}

class _UniversityAnalyticsScreenState extends State<UniversityAnalyticsScreen> {
  final _service = UniversityService();

  String _selectedRange = '30d';
  UniversityAnalyticsData? _analytics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _service.getUniversityAnalytics(range: _selectedRange);
      if (!mounted) return;
      setState(() {
        _analytics = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onRangeChanged(String newRange) {
    if (newRange == _selectedRange) return;
    setState(() {
      _selectedRange = newRange;
    });
    _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.universityName != null &&
            widget.universityName!.trim().isNotEmpty
        ? '${widget.universityName} • Analytics'
        : 'University Analytics';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh analytics',
            onPressed: () => _loadAnalytics(showLoading: false),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingSkeleton()
            : _errorMessage != null
            ? _buildErrorView()
            : RefreshIndicator(
                onRefresh: () => _loadAnalytics(showLoading: false),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header & Period Selector
                      _buildPeriodHeader(),
                      const SizedBox(height: 20),

                      // 2. Empty State Notice if zero interactions yet
                      if (_isCompletelyEmpty()) ...[
                        _buildEmptyStateBanner(),
                        const SizedBox(height: 20),
                      ],

                      // 3. Overview Statistics Grid
                      _buildOverviewCards(),
                      const SizedBox(height: 20),

                      // 4. Profile Views Detailed Breakdown
                      _buildProfileViewsBreakdownCard(),
                      const SizedBox(height: 20),

                      // 5. Profile Views Trend Chart
                      AnalyticsTrendBarChart(
                        title: 'Profile Views Trend',
                        subtitle:
                            'Daily student profile views over $_rangeLabel',
                        points: _analytics!.trends.profileViews,
                        barColor: const Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 20),

                      // 6. Student Interest & Favourites Info
                      _buildStudentInterestCard(),
                      const SizedBox(height: 20),

                      // 7. Course Engagement Section
                      CourseAnalyticsCard(
                        coursesData: _analytics!.courses,
                        onViewAllCourses: () {
                          if (widget.universityName != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UniversityCoursesScreen(
                                  universityName: widget.universityName!,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // 8. Course Views Daily Trend
                      AnalyticsTrendBarChart(
                        title: 'Course Views Over Time',
                        subtitle: 'Daily course engagements by students',
                        points: _analytics!.trends.courseViews,
                        barColor: const Color(0xFF0EA5E9),
                      ),
                      const SizedBox(height: 20),

                      // 9. Scholarship Performance & Status
                      ScholarshipAnalyticsCard(
                        scholarshipsData: _analytics!.scholarships,
                        applicationStatus: _analytics!.applicationStatus,
                      ),
                      const SizedBox(height: 20),

                      // 10. Scholarship Applications Daily Trend
                      AnalyticsTrendBarChart(
                        title: 'Scholarship Applications Trend',
                        subtitle: 'Daily submissions received',
                        points: _analytics!.trends.scholarshipApplications,
                        barColor: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 20),

                      // 11. Discovery & Comparison Activity
                      _buildDiscoveryAndComparisonCard(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  bool _isCompletelyEmpty() {
    if (_analytics == null) return false;
    final o = _analytics!.overview;
    return o.profileViews == 0 &&
        o.favourites == 0 &&
        o.courseViews == 0 &&
        o.scholarshipApplications == 0;
  }

  String get _rangeLabel {
    switch (_selectedRange) {
      case '7d':
        return 'the last 7 days';
      case '30d':
        return 'the last 30 days';
      case '90d':
        return 'the last 3 months';
      case '1y':
        return 'the last year';
      default:
        return 'selected period';
    }
  }

  Widget _buildPeriodHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance & Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Live student interaction and engagement data from MongoDB',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        AnalyticsFilterBar(
          selectedRange: _selectedRange,
          onRangeChanged: _onRangeChanged,
        ),
      ],
    );
  }

  Widget _buildEmptyStateBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No analytics data yet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Student interactions will appear here once students start discovering your university profile, degrees, and scholarships.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3B82F6),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final o = _analytics!.overview;
    final pv = _analytics!.profileViews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnalyticsSummaryCard(
                title: 'Profile Views',
                value: '${o.profileViews}',
                icon: Icons.visibility_outlined,
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                trendPercentage: pv.trend,
                subtitle: pv.trend == null && pv.previous == 0
                    ? 'No previous data'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnalyticsSummaryCard(
                title: 'Students Interested',
                value: '${o.studentsInterested}',
                icon: Icons.people_outline_rounded,
                color: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF5F3FF),
                subtitle:
                    '${_analytics!.studentInterest.newThisMonth} this month',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnalyticsSummaryCard(
                title: 'Favourites',
                value: '${o.favourites}',
                icon: Icons.favorite_border_rounded,
                color: const Color(0xFFEC4899),
                bgColor: const Color(0xFFFDF2F8),
                subtitle: '${_analytics!.favourites.newInPeriod} in period',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnalyticsSummaryCard(
                title: 'Course Views',
                value: '${o.courseViews}',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF0EA5E9),
                bgColor: const Color(0xFFF0F9FF),
                subtitle: '${_analytics!.courses.total} courses',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnalyticsSummaryCard(
          title: 'Scholarship Applications',
          value: '${o.scholarshipApplications}',
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFF10B981),
          bgColor: const Color(0xFFECFDF5),
          subtitle:
              '${o.totalApplications} all-time across ${_analytics!.scholarships.total} scholarships',
        ),
      ],
    );
  }

  Widget _buildProfileViewsBreakdownCard() {
    final pv = _analytics!.profileViews;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'University Profile Views',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real view sessions logged from CareerIQ student app',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildBreakdownItem(
                  'Today',
                  '${pv.today}',
                  const Color(0xFF2563EB),
                ),
                _buildBreakdownDivider(),
                _buildBreakdownItem(
                  'This Week',
                  '${pv.thisWeek}',
                  const Color(0xFF0EA5E9),
                ),
                _buildBreakdownDivider(),
                _buildBreakdownItem(
                  'This Month',
                  '${pv.thisMonth}',
                  const Color(0xFF8B5CF6),
                ),
                _buildBreakdownDivider(),
                _buildBreakdownItem(
                  'All Time',
                  '${pv.allTime}',
                  const Color(0xFF0F172A),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownDivider() {
    return Container(height: 28, width: 1, color: const Color(0xFFE2E8F0));
  }

  Widget _buildStudentInterestCard() {
    final fav = _analytics!.favourites;
    final interest = _analytics!.studentInterest;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Student Interest & Favourites',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDF2F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: Color(0xFFEC4899),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (fav.total == 0)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Favourite analytics will be available when students begin favouriting this university.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Favourites:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  Text(
                    '${fav.total}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'New this month:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  Text(
                    '${interest.newThisMonth}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'New this week:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  Text(
                    '${interest.newThisWeek}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryAndComparisonCard() {
    final comp = _analytics!.comparisonActivity;
    final search = _analytics!.searchDiscovery;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'University Discovery & Comparisons',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Visibility and side-by-side comparison activity',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.compare_arrows_rounded,
                          size: 20,
                          color: Color(0xFF8B5CF6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${comp.selectedCount}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Times selected for comparison',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${search.searchAppearances}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Search appearances',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
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

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: Color(0xFF2563EB)),
                SizedBox(height: 12),
                Text(
                  'Loading analytics & insights...',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load analytics',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'An error occurred while connecting to the analytics server.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
