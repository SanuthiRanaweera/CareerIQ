import 'package:flutter/material.dart';

import '../../app.dart';
import '../../services/auth_service.dart';
import '../../models/course.dart';
import '../../services/career_service.dart';
import '../../services/course_service.dart';
import '../../models/career.dart';
import '../career/screens/admin_career_form_page.dart';
import '../career/screens/admin_manage_careers_page.dart';
import 'admin_notifications_page.dart';
import 'models/admin_models.dart';
import 'university/screens/university_list_screen.dart';
import 'university/services/university_admin_service.dart';
import 'university/models/admin_university_model.dart';

enum AdminNavSection {
  overview,
  students,
  universities,
  courses,
  careers,
  notifications,
  settings,
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    this.onReturnToApp,
    this.onLogout,
    this.initialSection = AdminNavSection.overview,
  });

  final VoidCallback? onReturnToApp;
  final VoidCallback? onLogout;
  final AdminNavSection initialSection;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late AdminNavSection _currentSection;
  final AdminOverviewStats _stats = const AdminOverviewStats();

  late List<AdminStudent> _students;
  int _universityCount = 0;
  List<AdminUniversityModel> _adminUniversities = [];
  late List<AdminCourse> _courses;
  int _careerCount = 0;
  final Map<String, Course> _courseRecords = {};

  // Search & Filter controllers
  final TextEditingController _studentSearchController =
      TextEditingController();
  String _selectedStreamFilter = 'All';
  String _selectedStatusFilter = 'All';

  final TextEditingController _courseSearchController = TextEditingController();
  final _courseService = CourseService();
  bool _coursesLoading = false;

  /// Auth token for the Career module's admin screens, read once.
  late final Future<String?> _careerAdminToken = AuthService().token();

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSection;
    _students = AdminMockData.getInitialStudents();
    _courses = [];
    _loadAdminCourses();
    _loadCareerCount();
    _loadUniversityCount();
  }

  @override
  void dispose() {
    _studentSearchController.dispose();
    _courseSearchController.dispose();
    super.dispose();
  }

  void _selectSection(AdminNavSection section) {
    setState(() => _currentSection = section);
    if (section == AdminNavSection.courses) _loadAdminCourses();
    if (section == AdminNavSection.universities ||
        section == AdminNavSection.overview) {
      _loadUniversityCount();
    }
    Navigator.of(context).maybePop(); // Close drawer if open
  }

  /// Real career total for the sidebar badge and overview card, so they show
  /// the count before the Careers tab is opened. The tab keeps it current.
  Future<void> _loadCareerCount() async {
    try {
      final token = await _careerAdminToken;
      if (token == null) return;
      final careers = await CareerService().getCareers(token);
      if (mounted) setState(() => _careerCount = careers.length);
    } catch (_) {}
  }

  Future<void> _loadUniversityCount() async {
    try {
      final list = await UniversityAdminService().getUniversities();
      if (mounted) {
        setState(() {
          _adminUniversities = list;
          _universityCount = list.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAdminCourses() async {
    final token = await AuthService().token();
    if (token == null) return;
    if (mounted) setState(() => _coursesLoading = true);
    try {
      final courses = await _courseService.listAdmin(token);
      if (!mounted) return;
      setState(() {
        _courseRecords
          ..clear()
          ..addEntries(courses.map((course) => MapEntry(course.id, course)));
        _courses = courses.map(_toAdminCourse).toList();
        _coursesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _coursesLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load courses: $error')));
    }
  }

  AdminCourse _toAdminCourse(Course course) => AdminCourse(
    id: course.id,
    title: course.title,
    university: course.university,
    stream: course.stream,
    durationYears: course.durationYears,
    minZScore: course.minZScore ?? 0,
  );

  Future<void> _archiveCourse(AdminCourse course) async {
    final token = await AuthService().token();
    if (token == null) return;
    try {
      await _courseService.archive(token, course.id);
      await _loadAdminCourses();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Course archived')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not archive course: $error')),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Log Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of CareerIQ Admin?',
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
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await AuthService().logout();
      } catch (_) {}

      if (widget.onLogout != null) {
        widget.onLogout!();
      } else if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'Assets/logo.jpeg',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'CareerIQ Admin',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Log Out',
            icon: const Icon(
              Icons.logout_rounded,
              size: 20,
              color: Color(0xFFDC2626),
            ),
            onPressed: () => _confirmLogout(context),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Send student notifications',
            icon: const Badge(
              isLabelVisible: false,
              child: Icon(Icons.campaign_outlined, size: 20),
            ),
            onPressed: () => _selectSection(AdminNavSection.notifications),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, right: 12),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFDBEAFE),
              child: Text(
                'AD',
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(width: 270, child: _buildDrawerContent(isPermanent: true)),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildActiveTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() =>
      Drawer(child: _buildDrawerContent(isPermanent: false));

  Widget _buildDrawerContent({required bool isPermanent}) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'Assets/logo.jpeg',
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CareerIQ Admin 👋',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Portal & Operations',
                            style: TextStyle(
                              color: Color(0xFFBFDBFE),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'admin@careeriq.lk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _buildNavItem(
                  section: AdminNavSection.overview,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard Overview',
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 20, 14, 8),
                  child: Text(
                    'MANAGEMENT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                _buildNavItem(
                  section: AdminNavSection.students,
                  icon: Icons.school_rounded,
                  label: '👨‍🎓 Students',
                  badge: '${_stats.totalStudents}',
                ),
                _buildNavItem(
                  section: AdminNavSection.universities,
                  icon: Icons.account_balance_rounded,
                  label: '🏫 Universities',
                  badge: '$_universityCount',
                ),
                _buildNavItem(
                  section: AdminNavSection.courses,
                  icon: Icons.menu_book_rounded,
                  label: '📚 Courses',
                  badge: '${_courses.length}',
                ),
                _buildNavItem(
                  section: AdminNavSection.careers,
                  icon: Icons.work_rounded,
                  label: '💼 Careers',
                  badge: '$_careerCount',
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 20, 14, 8),
                  child: Text(
                    'COMMUNICATIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                _buildNavItem(
                  section: AdminNavSection.notifications,
                  icon: Icons.campaign_outlined,
                  label: 'Notifications',
                ),
                _buildNavItem(
                  section: AdminNavSection.settings,
                  icon: Icons.settings_rounded,
                  label: '⚙ Settings',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    if (widget.onReturnToApp != null) {
                      widget.onReturnToApp!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to Student App'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Log Out'),
                  style: FilledButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    backgroundColor: const Color(0xFFFEE2E2),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required AdminNavSection section,
    required IconData icon,
    required String label,
    String? badge,
  }) {
    final isSelected = _currentSection == section;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFF64748B),
            size: 22,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFF334155),
              fontSize: 14,
            ),
          ),
          trailing: badge != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF475569),
                    ),
                  ),
                )
              : null,
          onTap: () => _selectSection(section),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_currentSection) {
      case AdminNavSection.overview:
        return _buildOverviewTab();
      case AdminNavSection.students:
        return _buildStudentsTab();
      case AdminNavSection.universities:
        return _buildUniversitiesTab();
      case AdminNavSection.courses:
        return _buildCoursesTab();
      case AdminNavSection.careers:
        return _buildCareersTab();
      case AdminNavSection.notifications:
        return const AdminNotificationsPage();
      case AdminNavSection.settings:
        return _buildSettingsTab();
    }
  }

  // ---------------------------------------------------------------------------
  // 1. OVERVIEW TAB
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab() {
    return ListView(
      key: const ValueKey('overview_tab'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // Greeting Banner
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332563EB),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
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
                          'CareerIQ Admin 👋',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Platform overview, engagement statistics, and central management.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // KEY STATS HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PLATFORM HIGHLIGHTS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3B82F6),
              ),
            ),
            Text(
              'Real-time metrics',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3 MAIN STAT CARDS (Students, Active Students, Personality Tests)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Students',
                      value: '1,250',
                      subtext: '+12.5% this month',
                      icon: Icons.people_alt_rounded,
                      accentColor: const Color(0xFF3B82F6),
                      bgColor: const Color(0xFFEFF6FF),
                      onTap: () => _selectSection(AdminNavSection.students),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active Students',
                      value: '1,100',
                      subtext: '88% active rate',
                      icon: Icons.how_to_reg_rounded,
                      accentColor: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                      onTap: () => _selectSection(AdminNavSection.students),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Personality Tests',
                      value: '850',
                      subtext: '68% completion rate',
                      icon: Icons.psychology_rounded,
                      accentColor: const Color(0xFF8B5CF6),
                      bgColor: const Color(0xFFF5F3FF),
                      onTap: () => _selectSection(AdminNavSection.students),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildMetricCard(
                    title: 'Students',
                    value: '1,250',
                    subtext: '+12.5% this month',
                    icon: Icons.people_alt_rounded,
                    accentColor: const Color(0xFF3B82F6),
                    bgColor: const Color(0xFFEFF6FF),
                    onTap: () => _selectSection(AdminNavSection.students),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    title: 'Active Students',
                    value: '1,100',
                    subtext: '88% active rate',
                    icon: Icons.how_to_reg_rounded,
                    accentColor: const Color(0xFF10B981),
                    bgColor: const Color(0xFFECFDF5),
                    onTap: () => _selectSection(AdminNavSection.students),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    title: 'Personality Tests',
                    value: '850',
                    subtext: '68% completion rate',
                    icon: Icons.psychology_rounded,
                    accentColor: const Color(0xFF8B5CF6),
                    bgColor: const Color(0xFFF5F3FF),
                    onTap: () => _selectSection(AdminNavSection.students),
                  ),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 32),

        // MANAGEMENT SECTION HEADER
        Text(
          'Management',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quick access to core administrative operational modules.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        // MANAGEMENT QUICK TILES
        _buildManagementRow(
          title: '👨‍🎓 Students',
          subtitle:
              'Browse all 1,250 registered students, manage accounts & A/L data',
          countLabel: '1,250 Total',
          color: const Color(0xFF3B82F6),
          onTap: () => _selectSection(AdminNavSection.students),
        ),
        _buildManagementRow(
          title: '🏫 Universities',
          subtitle:
              'Higher education institutes & partner universities',
          countLabel: '$_universityCount Registered',
          color: const Color(0xFF0EA5E9),
          onTap: () => _selectSection(AdminNavSection.universities),
        ),
        _buildManagementRow(
          title: '📚 Courses',
          subtitle:
              'Undergraduate degree programs, entry requirements & minimum Z-scores',
          countLabel: '${_courses.length} Degrees',
          color: const Color(0xFFF59E0B),
          onTap: () => _selectSection(AdminNavSection.courses),
        ),
        _buildManagementRow(
          title: '💼 Careers',
          subtitle:
              'Industry career pathways, future market demand & personality compatibility',
          countLabel: '$_careerCount Pathways',
          color: const Color(0xFF10B981),
          onTap: () => _selectSection(AdminNavSection.careers),
        ),
        _buildManagementRow(
          title: '⚙ Settings',
          subtitle:
              'System configurations, database connections, and operational preferences',
          countLabel: 'Preferences',
          color: const Color(0xFF64748B),
          onTap: () => _selectSection(AdminNavSection.settings),
        ),

        const SizedBox(height: 28),

        // RECENT REGISTRATIONS PREVIEW
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Registrations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            TextButton(
              onPressed: () => _selectSection(AdminNavSection.students),
              child: const Text('View all students'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._students.take(3).map((std) => _buildStudentListCard(std)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, size: 16, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    subtext,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementRow({
    required String title,
    required String subtitle,
    required String countLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                countLabel,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. STUDENTS MANAGEMENT TAB
  // ---------------------------------------------------------------------------
  Widget _buildStudentsTab() {
    final query = _studentSearchController.text.trim().toLowerCase();
    final filtered = _students.where((s) {
      final matchesQuery =
          query.isEmpty ||
          s.fullName.toLowerCase().contains(query) ||
          s.email.toLowerCase().contains(query) ||
          s.school.toLowerCase().contains(query) ||
          s.district.toLowerCase().contains(query);

      final matchesStream =
          _selectedStreamFilter == 'All' || s.stream == _selectedStreamFilter;
      final matchesStatus =
          _selectedStatusFilter == 'All' ||
          (_selectedStatusFilter == 'Active' && s.isActive) ||
          (_selectedStatusFilter == 'Inactive' && !s.isActive);

      return matchesQuery && matchesStream && matchesStatus;
    }).toList();

    return Column(
      children: [
        // Tab Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '👨‍🎓 Students Management',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${_stats.totalStudents} enrolled • ${_stats.activeStudents} active',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddStudentDialog(context),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Add Student'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(130, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _studentSearchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      'Search by student name, school, email, or district...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _studentSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _studentSearchController.clear();
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Stream: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    ...[
                      'All',
                      'Mathematics',
                      'Science',
                      'Technology',
                      'Commerce',
                      'Arts',
                    ].map((stream) {
                      final isSelected = _selectedStreamFilter == stream;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(stream),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedStreamFilter = stream),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    const Text(
                      'Status: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    ...['All', 'Active', 'Inactive'].map((status) {
                      final isSelected = _selectedStatusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedStatusFilter = status),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No students matched your search criteria.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildStudentListCard(filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildStudentListCard(AdminStudent student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: student.isActive
              ? const Color(0xFFDBEAFE)
              : const Color(0xFFF1F5F9),
          child: Text(
            student.fullName.isNotEmpty ? student.fullName[0] : 'S',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: student.isActive
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
              fontSize: 18,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                student.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: student.isActive
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                student.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: student.isActive
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${student.school} • ${student.district} (${student.alYear})'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Chip(
                  labelPadding: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    student.stream,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: const Color(0xFFEFF6FF),
                  side: BorderSide.none,
                ),
                if (student.hasCompletedTest)
                  Chip(
                    avatar: const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFF7C3AED),
                    ),
                    labelPadding: EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      student.personalityCategory ?? 'Personality Done',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                    backgroundColor: const Color(0xFFF5F3FF),
                    side: BorderSide.none,
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (action) {
            if (action == 'toggle') {
              setState(() => student.isActive = !student.isActive);
            } else if (action == 'details') {
              _showStudentDetailSheet(context, student);
            } else if (action == 'delete') {
              setState(() => _students.removeWhere((s) => s.id == student.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removed ${student.fullName}')),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'details', child: Text('View Details')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(student.isActive ? 'Mark Inactive' : 'Mark Active'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text(
                'Delete Student',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        onTap: () => _showStudentDetailSheet(context, student),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. UNIVERSITIES MANAGEMENT TAB
  // ---------------------------------------------------------------------------
  Widget _buildUniversitiesTab() {
    return UniversityListScreen(
      embedded: true,
      onCountChanged: (count) {
        if (mounted) setState(() => _universityCount = count);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 4. COURSES MANAGEMENT TAB
  // ---------------------------------------------------------------------------
  Widget _buildCoursesTab() {
    final query = _courseSearchController.text.trim().toLowerCase();
    final filtered = _courses.where((c) {
      return query.isEmpty ||
          c.title.toLowerCase().contains(query) ||
          c.university.toLowerCase().contains(query) ||
          c.stream.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📚 Courses Management',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${_courses.length} degree programs cataloged',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _showCourseDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Course'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(130, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _courseSearchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText:
                      'Search courses by degree title, stream, or university...',
                  prefixIcon: Icon(Icons.search_rounded),
                  fillColor: Color(0xFFF1F5F9),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _coursesLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No courses found. Add a course to start the catalog.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final course = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    course.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    course.stream,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Edit course',
                                  onPressed: () => _showCourseDialog(
                                    context,
                                    course: course,
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Archive course',
                                  onPressed: () => _archiveCourse(course),
                                  icon: const Icon(Icons.archive_outlined),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              course.university,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 14,
                                        color: Color(0xFF475569),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${course.durationYears.toStringAsFixed(0)} Years Duration',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: Color(0xFFD97706),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Min Z-Score: ${course.minZScore}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. CAREERS MANAGEMENT TAB
  // ---------------------------------------------------------------------------
  /// The Career module's own admin screen, which reads and writes the real
  /// /api/careers endpoints instead of a local mock list.
  ///
  /// Shown embedded so this dashboard's header stays the only one on screen.
  /// The token is read from secure storage the same way the courses tab does.
  Widget _buildCareersTab() {
    return FutureBuilder<String?>(
      future: _careerAdminToken,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final token = snapshot.data;
        if (token == null) {
          return const Center(
            child: Text('Please sign in again to manage careers.'),
          );
        }

        return AdminManageCareersPage(
          token: token,
          embedded: true,
          onCountChanged: (count) {
            if (count != _careerCount) setState(() => _careerCount = count);
          },
          onAddCareer: () => _openCareerForm(context, token),
          onEditCareer: (career) =>
              _openCareerForm(context, token, career: career),
        );
      },
    );
  }

  /// Opens the career add/edit form, closing it once a save succeeds.
  void _openCareerForm(
    BuildContext context,
    String token, {
    Career? career,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCareerFormPage(
          token: token,
          career: career,
          onSaved: (_) => Navigator.pop(context),
        ),
      ),
    );
  }
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '⚙ Settings & System Status',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage CareerIQ backend configurations, operational health, and admin credentials.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 20),

        // System Services Status Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SYSTEM HEALTH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 14),
                _buildHealthItem(
                  'MongoDB Atlas Database',
                  'Connected',
                  Colors.green,
                ),
                _buildHealthItem(
                  'CareerIQ REST API (/api)',
                  'Active :3000',
                  Colors.green,
                ),
                _buildHealthItem(
                  'Personality Scoring Engine',
                  'Operational',
                  Colors.green,
                ),
                _buildHealthItem('AI Assistant Service', 'Ready', Colors.green),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Administration Preferences Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(
                  'Student Self-Registration',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Allow new A/L students to sign up via mobile app',
                ),
                value: true,
                onChanged: (_) {},
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text(
                  'Maintenance Mode',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Temporarily pause mobile access for scheduled maintenance',
                ),
                value: false,
                onChanged: (_) {},
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text(
                  'Automated Email Verification',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Require 6-digit OTP verification upon student signup',
                ),
                value: true,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        FilledButton.icon(
          onPressed: () {
            if (widget.onReturnToApp != null) {
              widget.onReturnToApp!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
          icon: const Icon(Icons.exit_to_app_rounded),
          label: const Text('Switch to Student Portal'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
          label: const Text(
            'Log Out of CareerIQ Admin',
            style: TextStyle(color: Color(0xFFDC2626)),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFCA5A5)),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthItem(String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MODALS & DIALOGS
  // ---------------------------------------------------------------------------
  void _showStudentDetailSheet(BuildContext context, AdminStudent student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFDBEAFE),
                    child: Text(
                      student.fullName[0],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          student.email,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _buildDetailRow('A/L Stream', student.stream),
              _buildDetailRow('A/L Examination Year', '${student.alYear}'),
              _buildDetailRow('School', student.school),
              _buildDetailRow('District', student.district),
              _buildDetailRow(
                'Account Status',
                student.isActive ? 'Active' : 'Inactive',
              ),
              _buildDetailRow(
                'Personality Test',
                student.hasCompletedTest
                    ? (student.personalityCategory ?? 'Completed')
                    : 'Pending',
              ),
              _buildDetailRow('Registered', student.joinedDate),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final schoolCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    String selectedStream = 'Mathematics';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Student'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: schoolCtrl,
                      decoration: const InputDecoration(labelText: 'School'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: districtCtrl,
                      decoration: const InputDecoration(labelText: 'District'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStream,
                      decoration: const InputDecoration(
                        labelText: 'A/L Stream',
                      ),
                      items:
                          [
                                'Mathematics',
                                'Science',
                                'Technology',
                                'Commerce',
                                'Arts',
                              ]
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStream = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                      setState(() {
                        _students.insert(
                          0,
                          AdminStudent(
                            id: 'std_${DateTime.now().millisecondsSinceEpoch}',
                            fullName: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            school: schoolCtrl.text.trim().isEmpty
                                ? 'Not specified'
                                : schoolCtrl.text.trim(),
                            district: districtCtrl.text.trim().isEmpty
                                ? 'Colombo'
                                : districtCtrl.text.trim(),
                            stream: selectedStream,
                            alYear: 2025,
                            isActive: true,
                            hasCompletedTest: false,
                            joinedDate: 'Just now',
                          ),
                        );
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${nameCtrl.text.trim()}'),
                        ),
                      );
                    }
                  },
                  child: const Text('Create Student'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCourseDialog(BuildContext context, {AdminCourse? course}) {
    final titleCtrl = TextEditingController(text: course?.title ?? '');
    final uniCtrl = TextEditingController(text: course?.university ?? '');
    final zScoreCtrl = TextEditingController(
      text: course == null || course.minZScore == 0
          ? ''
          : course.minZScore.toString(),
    );
    final durationCtrl = TextEditingController(
      text: course?.durationYears.toStringAsFixed(1) ?? '4',
    );
    final descriptionCtrl = TextEditingController(
      text: _courseRecords[course?.id]?.description ?? '',
    );
    const streams = [
      'Mathematics',
      'Science',
      'Technology',
      'Commerce',
      'Arts',
      'Any',
    ];
    String stream = streams.contains(course?.stream)
        ? course!.stream
        : 'Mathematics';

    String? selectedUniId = _courseRecords[course?.id]?.universityId;
    if (selectedUniId == null && course != null && _adminUniversities.isNotEmpty) {
      final match = _adminUniversities.firstWhere(
        (u) =>
            u.universityName.toLowerCase().trim() ==
            course.university.toLowerCase().trim(),
        orElse: () => const AdminUniversityModel(
          id: '',
          userId: '',
          universityName: '',
          location: '',
          officialEmail: '',
          address: '',
          contactNumber: '',
          representativeName: '',
          representativeContactNumber: '',
          status: '',
        ),
      );
      if (match.id.isNotEmpty) selectedUniId = match.id;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            course == null ? 'Add Academic Course' : 'Edit Academic Course',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Degree Title'),
                ),
                const SizedBox(height: 10),
                if (_adminUniversities.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    initialValue: _adminUniversities.any((u) => u.id == selectedUniId)
                        ? selectedUniId
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Assign University (from Database)',
                    ),
                    hint: const Text('Select registered university'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Custom / Manual Entry'),
                      ),
                      ..._adminUniversities.map(
                        (u) => DropdownMenuItem<String?>(
                          value: u.id,
                          child: Text(
                            u.universityName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        selectedUniId = val;
                        if (val != null) {
                          final found =
                              _adminUniversities.firstWhere((u) => u.id == val);
                          uniCtrl.text = found.universityName;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: uniCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Awarding University Name',
                  ),
                  onChanged: (text) {
                    if (selectedUniId != null) {
                      final found = _adminUniversities
                          .where((u) => u.id == selectedUniId)
                          .toList();
                      if (found.isEmpty || found.first.universityName != text) {
                        setDialogState(() => selectedUniId = null);
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: stream,
                  decoration: const InputDecoration(labelText: 'A/L stream'),
                  items:
                      const [
                            'Mathematics',
                            'Science',
                            'Technology',
                            'Commerce',
                            'Arts',
                            'Any',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setDialogState(() => stream = value ?? stream),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (years)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: zScoreCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Minimum Z-Score (optional)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final duration = double.tryParse(durationCtrl.text);
                if (titleCtrl.text.trim().isEmpty ||
                    uniCtrl.text.trim().isEmpty ||
                    duration == null ||
                    duration <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a title, university, and valid duration.',
                      ),
                    ),
                  );
                  return;
                }
                final token = await AuthService().token();
                if (token == null) return;
                try {
                  final values = {
                    'title': titleCtrl.text.trim(),
                    'university': uniCtrl.text.trim(),
                    if (selectedUniId != null && selectedUniId!.isNotEmpty)
                      'universityId': selectedUniId,
                    'stream': stream,
                    'durationYears': duration,
                    'minZScore': zScoreCtrl.text.trim().isEmpty
                        ? null
                        : double.tryParse(zScoreCtrl.text),
                    'description': descriptionCtrl.text.trim(),
                  };
                  final saved = course == null
                      ? await _courseService.create(token, values)
                      : await _courseService.update(token, course.id, values);
                  if (!mounted || !dialogContext.mounted) return;
                  setState(() {
                    _courseRecords[saved.id] = saved;
                    final index = _courses.indexWhere(
                      (item) => item.id == saved.id,
                    );
                    if (index == -1) {
                      _courses.insert(0, _toAdminCourse(saved));
                    } else {
                      _courses[index] = _toAdminCourse(saved);
                    }
                  });
                  Navigator.pop(dialogContext);
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Could not save course: $error')),
                    );
                  }
                }
              },
              child: const Text('Save Course'),
            ),
          ],
        ),
      ),
    );
  }

}
