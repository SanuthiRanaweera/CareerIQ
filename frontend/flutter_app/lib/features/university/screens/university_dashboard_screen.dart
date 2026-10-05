import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../models/university_dashboard_data.dart';
import '../services/university_service.dart';
import '../widgets/profile_completion_card.dart';
import '../widgets/quick_overview_card.dart';
import '../widgets/university_status_badge.dart';
import 'edit_university_profile_screen.dart';
import 'university_courses_screen.dart';
import 'university_notifications_screen.dart';
import 'university_profile_screen.dart';

class UniversityDashboardScreen extends StatefulWidget {
  const UniversityDashboardScreen({
    super.key,
    this.onLogout,
  });

  final VoidCallback? onLogout;

  @override
  State<UniversityDashboardScreen> createState() =>
      _UniversityDashboardScreenState();
}

class _UniversityDashboardScreenState extends State<UniversityDashboardScreen> {
  final _service = UniversityService();

  UniversityDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getUniversityDashboard();
      if (!mounted) return;
      setState(() {
        _dashboardData = data;
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

  Future<void> _confirmLogout() async {
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
          'Are you sure you want to log out of CareerIQ University Portal?',
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

    if (confirmed == true && mounted) {
      await AuthService().logout();
      if (!mounted) return;
      if (widget.onLogout != null) {
        widget.onLogout!();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _navigateToProfile() async {
    if (_dashboardData == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniversityProfileScreen(
          initialProfile: _dashboardData!.university,
        ),
      ),
    );
    _loadDashboard();
  }

  Future<void> _navigateToEditProfile() async {
    if (_dashboardData == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditUniversityProfileScreen(
          profile: _dashboardData!.university,
        ),
      ),
    );
    if (updated == true) {
      _loadDashboard();
    }
  }

  void _navigateToCourses() {
    if (_dashboardData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniversityCoursesScreen(
          universityName: _dashboardData!.university.universityName,
        ),
      ),
    );
  }

  void _navigateToNotifications() {
    if (_dashboardData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniversityNotificationsScreen(
          notifications: _dashboardData!.notifications,
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: Color(0xFF2563EB)),
                SizedBox(height: 12),
                Text(
                  'Loading university dashboard...',
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
              'Unable to load your university profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An error occurred while communicating with the server.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(UniversityProfileModel university) {
    final displayName = university.universityName.trim().isNotEmpty
        ? university.universityName.trim()
        : 'University';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
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
              Text(
                'Welcome,',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              UniversityStatusBadge(
                status: university.status,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$displayName 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${university.universityType ?? 'Higher Education Institute'} • Partner Portal',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFBFDBFE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniversityInfoCard(UniversityProfileModel university) {
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
                  'University Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: _navigateToProfile,
                  child: const Text('View Profile'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildContactItem(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: university.location.isNotEmpty
                  ? university.location
                  : 'Not specified',
            ),
            const SizedBox(height: 10),
            _buildContactItem(
              icon: Icons.email_outlined,
              label: 'Official Email',
              value: university.officialEmail,
            ),
            const SizedBox(height: 10),
            _buildContactItem(
              icon: Icons.phone_outlined,
              label: 'Contact Number',
              value: university.contactNumber.isNotEmpty
                  ? university.contactNumber
                  : 'Not specified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF475569)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.account_balance_outlined,
                title: 'University Profile',
                subtitle: 'Manage profile info',
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                onTap: _navigateToProfile,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                icon: Icons.menu_book_rounded,
                title: 'View Courses',
                subtitle: 'Degree programs',
                color: const Color(0xFF0EA5E9),
                bgColor: const Color(0xFFF0F9FF),
                onTap: _navigateToCourses,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications & Notices',
          subtitle: 'Account updates & CareerIQ alerts',
          color: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFF5F3FF),
          onTap: _navigateToNotifications,
          badgeCount: _dashboardData?.notifications.length ?? 0,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(
      List<UniversityActivityModel> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 36, color: Color(0xFF94A3B8)),
                    SizedBox(height: 8),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: activities.map((act) {
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    title: Text(
                      act.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      act.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    trailing: act.timestamp != null
                        ? Text(
                            '${act.timestamp!.month}/${act.timestamp!.day}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        : null,
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'University Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: _navigateToNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Log Out',
            onPressed: _confirmLogout,
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
                    onRefresh: _loadDashboard,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGreetingHeader(_dashboardData!.university),
                          const SizedBox(height: 20),
                          ProfileCompletionCard(
                            completionPercentage: _dashboardData!
                                .statistics.profileCompletion,
                            completedFields: _dashboardData!
                                .statistics.completedFields,
                            totalFields:
                                _dashboardData!.statistics.totalFields,
                            onCompleteProfile: _navigateToEditProfile,
                          ),
                          const SizedBox(height: 20),
                          QuickOverviewCard(
                            completionPercentage: _dashboardData!
                                .statistics.profileCompletion,
                            courseCount:
                                _dashboardData!.statistics.courseCount,
                            status: _dashboardData!.university.status,
                            onCoursesTap: _navigateToCourses,
                            onProfileTap: _navigateToProfile,
                          ),
                          const SizedBox(height: 20),
                          _buildUniversityInfoCard(
                              _dashboardData!.university),
                          const SizedBox(height: 20),
                          _buildAvailableActions(),
                          const SizedBox(height: 20),
                          _buildRecentActivitySection(
                              _dashboardData!.recentActivity),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
