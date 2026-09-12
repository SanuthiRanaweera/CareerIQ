import 'package:flutter/material.dart';

import '../../models/student.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.student, required this.onProfile, required this.onLogout});
  final Student student;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final firstName = student.fullName.split(' ').first;
    return Scaffold(
      appBar: AppBar(title: const Text('CareerIQ'), actions: [IconButton(onPressed: onLogout, tooltip: 'Log out', icon: const Icon(Icons.logout))]),
      body: RefreshIndicator(onRefresh: () async => onProfile(), child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [
        Text('Hello, $firstName', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const Text('Continue your career journey'), const SizedBox(height: 24),
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Profile completion', style: TextStyle(fontWeight: FontWeight.bold)), Text('${student.profileCompletion}%')]),
          const SizedBox(height: 12), LinearProgressIndicator(value: student.profileCompletion / 100, minHeight: 9, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 14), OutlinedButton.icon(onPressed: onProfile, icon: const Icon(Icons.edit_outlined), label: const Text('Complete profile')),
        ]))), const SizedBox(height: 16),
        _InfoCard(icon: Icons.school_outlined, title: 'Your A/L results', value: student.stream ?? 'Add your stream', subtitle: '${student.alResults.length} subjects added', onTap: onProfile),
        _InfoCard(icon: Icons.auto_awesome_outlined, title: 'Career recommendations', value: 'Coming soon', subtitle: 'Your matched careers will appear here'),
        _InfoCard(icon: Icons.menu_book_outlined, title: 'Course recommendations', value: 'Coming soon', subtitle: 'Explore courses that fit your goals'),
      ])),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.value, required this.subtitle, this.onTap});
  final IconData icon; final String title; final String value; final String subtitle; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(icon)),
          title: Text(title),
          subtitle: Text('$value\n$subtitle'),
          isThreeLine: true,
          trailing: onTap == null ? null : const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
