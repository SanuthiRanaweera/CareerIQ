import 'package:flutter/material.dart';

import '../../../models/career.dart';
import '../../../services/api_service.dart';
import '../../../services/career_service.dart';
import '../widgets/career_card.dart';
import '../widgets/career_state_views.dart';

/// Screen 08 - Careers.
///
/// Lists every career as a card showing title, category, salary and demand
/// level. Search and category filtering are added on top of this screen in the
/// next step; this version loads the full list.
///
/// The screen owns its own loading, empty and error states so a student always
/// knows what is happening: a spinner while loading, a short explanation with a
/// retry button if the request fails, and a friendly message when there is
/// nothing to show.
class CareersListPage extends StatefulWidget {
  const CareersListPage({
    super.key,
    required this.token,
    this.onCareerSelected,
    this.careerService,
  });

  final String token;

  /// Called when a career card is tapped. Left null until the career details
  /// screen exists, in which case the cards are not tappable.
  final void Function(Career career)? onCareerSelected;

  /// Injectable API client, mirroring how [CareerService] itself accepts an
  /// [ApiService]. The app leaves this null and gets the real service; tests
  /// pass a stub so the screen can be checked without a running backend.
  final CareerService? careerService;

  @override
  State<CareersListPage> createState() => _CareersListPageState();
}

class _CareersListPageState extends State<CareersListPage> {
  late final CareerService _careerService =
      widget.careerService ?? CareerService();

  List<Career> _careers = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCareers();
  }

  /// Loads the careers list. [showSpinner] is false for pull-to-refresh, where
  /// the refresh indicator is already giving the user feedback.
  Future<void> _loadCareers({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);
    setState(() => _error = null);

    try {
      final careers = await _careerService.getCareers(widget.token);
      if (!mounted) return;
      setState(() {
        _careers = careers;
        _loading = false;
      });
    } on ApiException catch (error) {
      // The backend sends a readable message, so show that rather than a
      // generic failure notice.
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach the server. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Careers')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadCareers(showSpinner: false),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const CareerLoadingView(message: 'Loading careers...');
    }

    if (_error != null) {
      return CareerErrorView(
        message: _error!,
        onRetry: _loadCareers,
      );
    }

    if (_careers.isEmpty) {
      return CareerEmptyView(
        icon: Icons.work_outline_rounded,
        title: 'No careers yet',
        message: 'Careers added by your administrator will appear here.',
        onRetry: _loadCareers,
      );
    }

    return ListView(
      // Always scrollable so pull-to-refresh works even on a short list.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SizedBox(height: 8),
        Text(
          'EXPLORE CAREERS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3B82F6),
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Find your path',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '${_careers.length} ${_careers.length == 1 ? 'career' : 'careers'} to explore',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
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
