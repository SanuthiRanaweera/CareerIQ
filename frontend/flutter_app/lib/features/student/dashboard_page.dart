import 'package:flutter/material.dart';

import 'courses/course_catalog_page.dart';
import '../../models/student.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.student,
    required this.onProfile,
    required this.onLogout,
    required this.onPersonalityTest,
    required this.onCourses,
    required this.onChatbot,
  });
  final Student student;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final VoidCallback onPersonalityTest;
  final VoidCallback onCourses;
  final VoidCallback onChatbot;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedTab = 0;

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
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                IconButton(
                  onPressed: widget.onProfile,
                  tooltip: 'Profile',
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ],
            )
          : null,
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: widget.onChatbot,
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 5,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Ask CareerIQ'),
            )
          : null,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildHome(context, firstName),
          const _StudentModulePlaceholder(
            title: 'Universities',
            description:
                'University information will appear here when that module is connected.',
            icon: Icons.account_balance_outlined,
          ),
          CourseCatalogPage(initialStream: student.stream),
          const _StudentModulePlaceholder(
            title: 'Careers',
            description:
                'Career pathways will appear here when that module is connected.',
            icon: Icons.star_outline_rounded,
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

  Future<void> _showNotifications() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.notifications_off_outlined,
              size: 42,
              color: Color(0xFF6B778C),
            ),
            const SizedBox(height: 10),
            Text(
              'You are all caught up',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'New updates will appear here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildHome(BuildContext context, String firstName) => RefreshIndicator(
    onRefresh: () async => widget.onProfile(),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SizedBox(height: 8),
        Text('Good morning,', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          'Hello, $firstName',
          style: Theme.of(context).textTheme.headlineMedium,
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
          value: 'Coming soon',
          subtitle: 'Your matched careers will appear here',
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

class _StudentModulePlaceholder extends StatelessWidget {
  const _StudentModulePlaceholder({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: const Color(0xFF3478F6)),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
          ],
        ),
      ),
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
