import 'package:flutter/material.dart';

import '../../models/student.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.student,
    required this.onProfile,
    required this.onLogout,
  });
  final Student student;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final firstName = student.fullName.split(' ').first;
    return Scaffold(
      appBar: AppBar(
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
            onPressed: onLogout,
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => onProfile(),
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
                color: const Color(0xFF087F78),
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
                                student.profileCompletion == 100
                                    ? 'You are all set'
                                    : 'A few details make recommendations sharper',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${student.profileCompletion}%',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: const Color(0xFF087F78)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    LinearProgressIndicator(
                      value: student.profileCompletion / 100,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: onProfile,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(
                        student.profileCompletion == 100
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
                color: const Color(0xFF087F78),
              ),
            ),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.school_outlined,
              title: 'Your A/L results',
              value: student.stream ?? 'Add your stream',
              subtitle: '${student.alResults.length} subjects added',
              onTap: onProfile,
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
              value: 'Coming soon',
              subtitle: 'Explore courses that fit your goals',
            ),
          ],
        ),
      ),
    );
  }
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
        backgroundColor: const Color(0xFFCCF3EF),
        foregroundColor: const Color(0xFF087F78),
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
