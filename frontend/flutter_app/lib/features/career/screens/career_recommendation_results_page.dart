import 'package:flutter/material.dart';

import '../../../models/career.dart';
import '../../../models/recommendation_input.dart';
import '../../../services/api_service.dart';
import '../../../services/career_service.dart';
import '../widgets/career_state_views.dart';

/// Career recommendations - ranked results.
///
/// Sends the form answers to the scoring endpoint and lists the careers it
/// returns, best match first. Every result carries its match percentage and
/// the reasons behind it, so a student sees why a career was suggested rather
/// than just a number.
class CareerRecommendationResultsPage extends StatefulWidget {
  const CareerRecommendationResultsPage({
    super.key,
    required this.token,
    required this.answers,
    this.onCareerSelected,
    this.onEditAnswers,
    this.careerService,
  });

  final String token;
  final RecommendationAnswers answers;

  /// Opens the career details screen for a result.
  final void Function(Career career)? onCareerSelected;

  /// Returns to the form so the student can change their answers.
  final VoidCallback? onEditAnswers;

  /// Injectable API client so the screen can be tested without a backend.
  final CareerService? careerService;

  @override
  State<CareerRecommendationResultsPage> createState() =>
      _CareerRecommendationResultsPageState();
}

class _CareerRecommendationResultsPageState
    extends State<CareerRecommendationResultsPage> {
  late final CareerService _careerService =
      widget.careerService ?? CareerService();

  CareerRecommendationResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _careerService.recommend(
        widget.token,
        stream: widget.answers.stream,
        subjects: widget.answers.subjects,
        interests: widget.answers.interests,
        personalityType: widget.answers.personalityType,
        workStyle: widget.answers.workStyle,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your matches')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const CareerLoadingView(message: 'Finding your best matches...');
    }

    // Every non-loading state shares one RefreshIndicator, so the results can
    // be re-scored by pulling down whether they arrived or not. Matches the
    // careers list, where the error and empty states refresh the same way.
    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_error != null) {
      return CareerErrorView(message: _error!, onRetry: _loadRecommendations);
    }

    final result = _result!;

    // Careers that scored nothing are left out: a list padded with 0% results
    // is noise, not guidance.
    final matches = result.matches
        .where((match) => match.matchPercentage > 0)
        .toList();

    if (matches.isEmpty) {
      return CareerEmptyView(
        icon: Icons.search_off_rounded,
        title: 'No strong matches yet',
        message:
            'None of the careers scored against your answers. Try choosing a few more interests or a different stream.',
        onRetry: widget.onEditAnswers,
        actionLabel: 'Change my answers',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SizedBox(height: 8),
        _buildHeader(context, result, matches.length),
        const SizedBox(height: 20),
        ...matches.asMap().entries.map(
          (entry) => _MatchCard(
            rank: entry.key + 1,
            match: entry.value,
            onTap: widget.onCareerSelected == null
                ? null
                : () => widget.onCareerSelected!(entry.value.career),
          ),
        ),
        if (widget.onEditAnswers != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.onEditAnswers,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Change my answers'),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CareerRecommendationResult result,
    int shown,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR MATCHES',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$shown ${shown == 1 ? 'career fits' : 'careers fit'} you',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),

        // Confidence note. A high percentage from a half-filled form should
        // be read in context, so the screen says plainly how much of the form
        // the ranking rests on.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF1D4ED8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.confidenceNote,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    if (widget.answers.summary.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.answers.summary,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One ranked career: position, match percentage, and why it matched.
class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.rank, required this.match, this.onTap});

  final int rank;
  final CareerRecommendation match;
  final VoidCallback? onTap;

  /// Stronger matches read warmer. The percentage is always written out, so
  /// colour is a reinforcement rather than the only signal.
  Color get _scoreColour {
    if (match.matchPercentage >= 70) return const Color(0xFF15803D);
    if (match.matchPercentage >= 40) return const Color(0xFF1D4ED8);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final career = match.career;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rank marker, so the ordering is explicit rather than
                  // something the student has to infer from the percentages.
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(career.title, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          career.category,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${match.matchPercentage}%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _scoreColour,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: match.matchPercentage / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(_scoreColour),
                ),
              ),
              if (match.reasons.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...match.reasons.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle,
                            size: 15,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      career.salaryLabel,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
