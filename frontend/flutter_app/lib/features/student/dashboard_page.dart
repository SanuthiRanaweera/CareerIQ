import 'package:flutter/material.dart';

import 'courses/course_catalog_page.dart';
import 'group_chat_page.dart';
import 'notifications/student_notifications_sheet.dart';
import 'university/screens/student_university_search_page.dart';
import '../../models/career.dart';
import '../../models/student.dart';
import '../../services/notification_service.dart';
import '../career/screens/career_details_page.dart';
import '../career/screens/career_pathway_page.dart';
import '../career/screens/careers_list_page.dart';
import '../career/screens/saved_careers_page.dart';
import '../../services/saved_career_service.dart';
import '../scholarship/screens/scholarship_list_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.student,
    required this.token,
    required this.onProfile,
    required this.onLogout,
    required this.onPersonalityTest,
    required this.onCourses,
    required this.onChatbot,
    required this.onBrowseCareers,
    required this.onCareerRecommendations,
  });
  final Student student;
  final String token;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final VoidCallback onPersonalityTest;
  final VoidCallback onCourses;
  final VoidCallback onChatbot;
  final VoidCallback onBrowseCareers;
  final VoidCallback onCareerRecommendations;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedTab = 0;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshUnreadNotificationCount();
  }

  Future<void> _refreshUnreadNotificationCount() async {
    try {
      final notifications = await NotificationService().listMine(widget.token);
      if (!mounted) return;
      setState(
        () => _unreadNotificationCount = notifications
            .where((notification) => !notification.isRead)
            .length,
      );
    } catch (_) {}
  }

  /// Opens the career details screen, and from there the pathway timeline, so
  /// the Careers tab leads all the way through the Career module.
  Future<void> _openCareerDetails(Career career) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CareerDetailsPage(
          token: widget.token,
          careerId: career.id,
          savedCareerService: SavedCareerService(),
          onViewPathway: (loaded) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CareerPathwayPage(career: loaded),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final firstName = student.fullName.split(' ').first;
    return Scaffold(
      appBar: _selectedTab == 0
          ? AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'Assets/logo.jpeg',
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('CareerIQ'),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: _showNotifications,
                  tooltip: 'Notifications',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: Badge(
                    isLabelVisible: _unreadNotificationCount > 0,
                    label: Text('$_unreadNotificationCount'),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 28,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _openGroupChat,
                  tooltip: 'CareerIQ group chat',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.forum_outlined, size: 27),
                ),
                IconButton(
                  onPressed: widget.onProfile,
                  tooltip: 'Profile',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon:
                      widget.student.profileImage != null &&
                          widget.student.profileImage!.trim().isNotEmpty
                      ? CircleAvatar(
                          radius: 15,
                          backgroundColor: const Color(0xFFDBEAFE),
                          child: ClipOval(
                            child: Image.network(
                              widget.student.profileImage!.trim(),
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.account_circle_outlined,
                                size: 28,
                              ),
                            ),
                          ),
                        )
                      : const Icon(Icons.account_circle_outlined, size: 28),
                ),
              ],
            )
          : null,
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: widget.onChatbot,
              tooltip: 'Ask CareerIQ',
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 5,
              child: const _CareerBotIcon(),
            )
          : null,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildHome(context, firstName),
          StudentUniversitySearchPage(
            token: widget.token,
            student: widget.student,
          ),
          CourseCatalogPage(initialStream: student.stream),
          CareersListPage(
            token: widget.token,
            onCareerSelected: _openCareerDetails,
            onOpenShortlist: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SavedCareersPage(
                  token: widget.token,
                  onCareerSelected: _openCareerDetails,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF3478F6),
        unselectedItemColor: const Color(0xFF6B778C),
        selectedFontSize: 14,
        unselectedFontSize: 14,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined),
            activeIcon: Icon(Icons.account_balance_rounded),
            label: 'Uni',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book_rounded),
            label: 'Course',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline_rounded),
            activeIcon: Icon(Icons.star_rounded),
            label: 'Career',
          ),
        ],
      ),
    );
  }

  Future<void> _showNotifications() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StudentNotificationsSheet(token: widget.token),
    );
    await _refreshUnreadNotificationCount();
  }

  Future<void> _openGroupChat() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => GroupChatPage(
        token: widget.token,
        currentUserId: widget.student.id,
        currentUserName: widget.student.fullName,
        currentUserProfileImage: widget.student.profileImage,
      ),
    ),
  );

  Widget _buildHome(BuildContext context, String firstName) => RefreshIndicator(
    onRefresh: () async => widget.onProfile(),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning,',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hello, $firstName',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            if (widget.student.profileImage != null &&
                widget.student.profileImage!.trim().isNotEmpty)
              InkWell(
                onTap: widget.onProfile,
                borderRadius: BorderRadius.circular(28),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: ClipOval(
                    child: Image.network(
                      widget.student.profileImage!.trim(),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        widget.student.fullName.isNotEmpty
                            ? widget.student.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Continue shaping a career that fits you.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        Text(
          'YOUR PROGRESS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
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
                          Text(
                            'Profile completion',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.student.profileCompletion == 100
                                ? 'You are all set'
                                : 'A few details make recommendations sharper',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${widget.student.profileCompletion}%',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: const Color(0xFF3B82F6)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  value: widget.student.profileCompletion / 100,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: widget.onProfile,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    widget.student.profileCompletion == 100
                        ? 'Review profile'
                        : 'Complete profile',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'YOUR CAREER HUB',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 10),
        _InfoCard(
          icon: Icons.school_outlined,
          title: 'Your A/L results',
          value: widget.student.stream ?? 'Add your stream',
          subtitle: '${widget.student.alResults.length} subjects added',
          onTap: widget.onProfile,
        ),
        _InfoCard(
          icon: Icons.psychology_outlined,
          title: 'Personality & Interest Test',
          value: widget.student.personalityCategory ?? 'Not started',
          subtitle: widget.student.personalityCategory == null
              ? 'Discover your career personality'
              : 'Tap to view your result',
          onTap: widget.onPersonalityTest,
        ),
        _InfoCard(
          icon: Icons.auto_awesome_outlined,
          title: 'Career recommendations',
          value: 'Find your match',
          subtitle: 'Answer a few questions to see ranked careers',
          onTap: widget.onCareerRecommendations,
        ),
        _InfoCard(
          icon: Icons.account_balance_outlined,
          title: 'Universities & Comparison',
          value: 'Compare up to 3 universities',
          subtitle: 'Side-by-side degree, Z-score & criteria comparison',
          onTap: () => setState(() => _selectedTab = 1),
        ),
        _InfoCard(
          icon: Icons.workspace_premium_outlined,
          title: 'Scholarships & Grants',
          value: 'Browse & apply',
          subtitle: 'Merit, need-based, sports & academic funding',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScholarshipListScreen(
                  student: widget.student,
                  token: widget.token,
                ),
              ),
            );
          },
        ),
        _InfoCard(
          icon: Icons.menu_book_outlined,
          title: 'Course recommendations',
          value: widget.student.stream ?? 'All A/L streams',
          subtitle: 'Browse and compare degree programmes',
          onTap: () => setState(() => _selectedTab = 2),
        ),
        _InfoCard(
          icon: Icons.auto_awesome_outlined,
          title: 'CareerIQ AI Assistant',
          value: 'Ask your career mentor',
          subtitle: 'Get personalized guidance on demand',
          onTap: widget.onChatbot,
        ),
      ],
    ),
  );
}

class _CareerBotIcon extends StatelessWidget {
  const _CareerBotIcon();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 34,
    height: 34,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 1,
          child: Container(
            width: 3,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 9,
          child: Container(
            width: 27,
            height: 21,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: 9,
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 14,
          right: 9,
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 7,
          child: Container(
            width: 8,
            height: 2.5,
            decoration: BoxDecoration(
              color: const Color(0xFF60A5FA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          top: 15,
          left: 1,
          child: Container(
            width: 4,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          top: 15,
          right: 1,
          child: Container(
            width: 4,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFFDBEAFE),
        foregroundColor: const Color(0xFF3B82F6),
        child: Icon(icon, size: 24),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          '$value\n$subtitle',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
      isThreeLine: true,
      trailing: onTap == null
          ? const Icon(Icons.lock_outline, size: 20)
          : const Icon(Icons.arrow_forward_rounded),
      onTap: onTap,
    ),
  );
}
