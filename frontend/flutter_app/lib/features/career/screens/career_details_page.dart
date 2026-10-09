import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/career.dart';
import '../../../services/api_service.dart';
import '../../../models/saved_career.dart';
import '../../../services/career_service.dart';
import '../../../services/saved_career_service.dart';
import '../widgets/career_card.dart' show DemandLevelBadge;
import '../widgets/career_state_views.dart';

/// Screen 09 - Career details.
///
/// Loads one career by id and lays it out as a set of cards: what the job
/// pays, what you would actually do, the skills and A/L streams it needs,
/// where the opportunities are, and a placeholder for recommended courses.
///
/// The career is fetched here rather than passed in from the list, so the
/// screen stands on its own and always shows current data.
class CareerDetailsPage extends StatefulWidget {
  const CareerDetailsPage({
    super.key,
    required this.token,
    required this.careerId,
    this.onViewPathway,
    this.careerService,
    this.savedCareerService,
  });

  final String token;
  final String careerId;

  /// Opens the career pathway screen. Null until that screen is wired up, in
  /// which case the pathway button is hidden rather than shown as dead.
  final void Function(Career career)? onViewPathway;

  /// Injectable API client so the screen can be tested without a backend.
  final CareerService? careerService;

  /// Client for the student's shortlist. When null the bookmark button is
  /// hidden, so a host that has no shortlist does not show a dead control.
  final SavedCareerService? savedCareerService;

  @override
  State<CareerDetailsPage> createState() => _CareerDetailsPageState();
}

class _CareerDetailsPageState extends State<CareerDetailsPage> {
  late final CareerService _careerService =
      widget.careerService ?? CareerService();

  Career? _career;
  bool _loading = true;
  String? _error;

  /// This career's shortlist entry, or null when it is not saved.
  SavedCareer? _saved;
  bool _savingBusy = false;

  @override
  void initState() {
    super.initState();
    _loadCareer();
  }

  Future<void> _loadCareer() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final career = await _careerService.getCareerById(
        widget.token,
        widget.careerId,
      );
      if (!mounted) return;
      setState(() {
        _career = career;
        _loading = false;
      });
      unawaited(_loadSavedState(career));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Could not reach the server. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  /// Finds out whether this career is already on the shortlist. A failure
  /// here is not worth an error screen: the bookmark simply shows as unsaved.
  Future<void> _loadSavedState(Career career) async {
    final service = widget.savedCareerService;
    if (service == null) return;
    try {
      final all = await service.getSavedCareers(widget.token);
      if (!mounted) return;
      SavedCareer? match;
      for (final item in all) {
        if (item.career.id == career.id) match = item;
      }
      setState(() => _saved = match);
    } catch (_) {}
  }

  Future<void> _toggleSaved(Career career) async {
    final service = widget.savedCareerService;
    if (service == null || _savingBusy) return;
    setState(() => _savingBusy = true);

    try {
      final existing = _saved;
      if (existing == null) {
        final saved = await service.saveCareer(widget.token, career.id);
        if (!mounted) return;
        setState(() => _saved = saved);
        showCareerMessage(context, 'Saved to your shortlist', success: true);
      } else {
        await service.deleteSavedCareer(widget.token, existing.id);
        if (!mounted) return;
        setState(() => _saved = null);
        showCareerMessage(
          context,
          'Removed from your shortlist',
          success: true,
        );
      }
    } on ApiException catch (error) {
      if (mounted) showCareerMessage(context, error.message);
    } catch (_) {
      if (mounted) {
        showCareerMessage(
          context,
          'Could not reach the server. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _savingBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final career = _career;

    return Scaffold(
      appBar: AppBar(
        // The title doubles as a breadcrumb once the career is known.
        title: Text(career?.title ?? 'Career details'),
        actions: [
          if (career != null && widget.savedCareerService != null)
            IconButton(
              tooltip: _saved == null
                  ? 'Save to shortlist'
                  : 'Remove from shortlist',
              onPressed: _savingBusy ? null : () => _toggleSaved(career),
              icon: Icon(
                _saved == null
                    ? Icons.bookmark_border_rounded
                    : Icons.bookmark_rounded,
                color: _saved == null ? null : const Color(0xFF3B82F6),
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, career)),
    );
  }

  Widget _buildBody(BuildContext context, Career? career) {
    if (_loading) {
      return const CareerLoadingView(message: 'Loading career details...');
    }

    // Every non-loading state sits inside the same RefreshIndicator, so pull
    // to refresh works whether the career loaded or not. The error and empty
    // views are built scrollable for exactly this reason.
    return RefreshIndicator(
      onRefresh: _loadCareer,
      child: _buildContent(context, career),
    );
  }

  Widget _buildContent(BuildContext context, Career? career) {
    if (_error != null) {
      return CareerErrorView(message: _error!, onRetry: _loadCareer);
    }
    if (career == null) {
      return CareerEmptyView(
        icon: Icons.work_outline_rounded,
        title: 'Career not available',
        message: 'This career could not be found. It may have been removed.',
        onRetry: _loadCareer,
      );
    }
    return _buildDetails(context, career);
  }

  Widget _buildDetails(BuildContext context, Career career) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SizedBox(height: 8),
        Text(
          career.category.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 6),
        Text(career.title, style: theme.textTheme.headlineMedium),
        if (career.jobOutlook.isNotEmpty) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: DemandLevelBadge(jobOutlook: career.jobOutlook),
          ),
        ],
        const SizedBox(height: 20),

        // Salary gets its own highlighted card: it is the single fact most
        // students look for first.
        _SalaryCard(label: career.salaryLabel),

        if (career.description.isNotEmpty)
          _SectionCard(
            icon: Icons.info_outline_rounded,
            title: 'About this career',
            child: Text(career.description, style: theme.textTheme.bodyLarge),
          ),

        if (career.whatYouDo.isNotEmpty)
          _SectionCard(
            icon: Icons.checklist_rounded,
            title: "What you'd do",
            child: _BulletList(items: career.whatYouDo),
          ),

        if (career.requiredSkills.isNotEmpty)
          _SectionCard(
            icon: Icons.psychology_outlined,
            title: 'Skills you need',
            child: _TagWrap(
              values: career.requiredSkills,
              background: Color(0xFFDBEAFE),
              foreground: Color(0xFF1D4ED8),
            ),
          ),

        if (career.recommendedStreams.isNotEmpty)
          _SectionCard(
            icon: Icons.school_outlined,
            title: 'Recommended A/L streams',
            child: _TagWrap(
              values: career.recommendedStreams,
              background: Color(0xFFDCFCE7),
              foreground: Color(0xFF15803D),
            ),
          ),

        if (career.industryOpportunities.isNotEmpty)
          _SectionCard(
            icon: Icons.business_center_outlined,
            title: 'Where the opportunities are',
            child: _BulletList(items: career.industryOpportunities),
          ),

        _RecommendedCoursesSection(keywords: career.relatedCourseKeywords),

        if (widget.onViewPathway != null && career.pathway.isNotEmpty) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => widget.onViewPathway!(career),
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('View career pathway'),
          ),
        ],
      ],
    );
  }
}

/// Highlighted salary band.
class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFDBEAFE),
            foregroundColor: Color(0xFF3B82F6),
            child: Icon(Icons.payments_outlined),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Typical salary',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(label, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// A titled card, so every section on the screen looks the same.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

/// Tick-marked list, matching the style already used on the personality
/// result screen.
class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF3B82F6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

/// Wrapped pills, used for skills and A/L streams.
class _TagWrap extends StatelessWidget {
  const _TagWrap({
    required this.values,
    required this.background,
    required this.foreground,
  });

  final List<String> values;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: values
        .map(
          (value) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        )
        .toList(),
  );
}

/// Recommended courses.
///
/// Course data is owned by the Course module, which is built separately. This
/// career only stores keywords describing the kind of course that fits, so the
/// section shows those keywords and says plainly that the course listings are
/// still to come, rather than pretending to have data it does not have.
class _RecommendedCoursesSection extends StatelessWidget {
  const _RecommendedCoursesSection({required this.keywords});

  final List<String> keywords;

  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.menu_book_outlined,
    title: 'Recommended courses',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Course listings are coming soon.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
        if (keywords.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Look for courses in:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 10),
          _TagWrap(
            values: keywords,
            background: const Color(0xFFF1F5F9),
            foreground: const Color(0xFF475569),
          ),
        ],
      ],
    ),
  );
}
