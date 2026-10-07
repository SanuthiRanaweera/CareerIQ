import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/features/career/screens/career_recommendation_results_page.dart';
import 'package:flutter_app/models/career.dart';
import 'package:flutter_app/models/recommendation_input.dart';
import 'package:flutter_app/services/api_service.dart';

import 'career_test_fakes.dart';

// Tests for the career recommendation results screen.
//
// The screen has to do three things honestly: rank the careers, explain each
// score, and be clear about how much of the form the ranking rests on.

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200);
    await tester.pumpAndSettle();
  }

  const answers = RecommendationAnswers(
    stream: 'Science',
    interests: ['healthcare'],
    personalityType: 'Social',
  );

  CareerRecommendation match(
    String title,
    int percentage, {
    List<String> reasons = const [],
    String category = 'Healthcare & Medicine',
  }) =>
      CareerRecommendation(
        career: careerFixture(
          id: title,
          title: title,
          category: category,
          salaryMin: 150000,
          salaryMax: 600000,
        ),
        matchPercentage: percentage,
        reasons: reasons,
      );

  CareerRecommendationResult resultOf(
    List<CareerRecommendation> matches, {
    int answered = 3,
  }) =>
      CareerRecommendationResult(
        matches: matches,
        answeredComponents: answered,
        totalComponents: 5,
      );

  Widget resultsFor(
    CareerRecommendationResult result, {
    void Function(Career)? onCareerSelected,
    VoidCallback? onEditAnswers,
  }) =>
      wrap(CareerRecommendationResultsPage(
        token: 't',
        answers: answers,
        onCareerSelected: onCareerSelected,
        onEditAnswers: onEditAnswers,
        careerService: FakeCareerService(recommendation: result),
      ));

  group('CareerRecommendationResultsPage', () {
    testWidgets('shows a loading message while scoring', (tester) async {
      await tester.pumpWidget(resultsFor(resultOf([match('Medical Doctor', 100)])));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Finding your best matches...'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('sends the form answers to the scoring endpoint',
        (tester) async {
      final service = FakeCareerService(
        recommendation: resultOf([match('Medical Doctor', 100)]),
      );
      await tester.pumpWidget(wrap(CareerRecommendationResultsPage(
        token: 't',
        answers: const RecommendationAnswers(
          stream: 'Science',
          subjects: ['Biology'],
          interests: ['healthcare', 'research'],
          personalityType: 'Social',
          workStyle: 'Team-based',
        ),
        careerService: service,
      )));
      await tester.pumpAndSettle();

      expect(service.lastRecommendBody, {
        'stream': 'Science',
        'subjects': ['Biology'],
        'interests': ['healthcare', 'research'],
        'personalityType': 'Social',
        'workStyle': 'Team-based',
        'limit': null,
      });
    });

    testWidgets('lists matches with rank, percentage and category',
        (tester) async {
      await tester.pumpWidget(resultsFor(resultOf([
        match('Medical Doctor', 100),
        match('Agricultural Officer', 53,
            category: 'Agriculture & Environment'),
      ])));
      await tester.pumpAndSettle();

      expect(find.text('2 careers fit you'), findsOneWidget);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('Medical Doctor'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      expect(find.text('2'), findsOneWidget);
      expect(find.text('Agricultural Officer'), findsOneWidget);
      expect(find.text('53%'), findsOneWidget);
      expect(find.text('Agriculture & Environment'), findsOneWidget);
    });

    testWidgets('keeps the ranking order given by the backend', (tester) async {
      await tester.pumpWidget(resultsFor(resultOf([
        match('Medical Doctor', 100),
        match('Agricultural Officer', 53),
        match('Attorney-at-Law', 27),
      ])));
      await tester.pumpAndSettle();

      final first = tester.getTopLeft(find.text('Medical Doctor')).dy;
      final second = tester.getTopLeft(find.text('Agricultural Officer')).dy;
      final third = tester.getTopLeft(find.text('Attorney-at-Law')).dy;

      expect(first, lessThan(second));
      expect(second, lessThan(third));
    });

    testWidgets('explains why each career matched', (tester) async {
      await tester.pumpWidget(resultsFor(resultOf([
        match('Medical Doctor', 100, reasons: [
          'Matches 1 of your interests',
          'Suits the Science stream',
          'Matches your Social personality type',
        ]),
      ])));
      await tester.pumpAndSettle();

      expect(find.text('Matches 1 of your interests'), findsOneWidget);
      expect(find.text('Suits the Science stream'), findsOneWidget);
      expect(find.text('Matches your Social personality type'), findsOneWidget);
    });

    testWidgets('shows the salary for each match', (tester) async {
      await tester.pumpWidget(resultsFor(resultOf([match('Medical Doctor', 100)])));
      await tester.pumpAndSettle();

      expect(find.text('LKR 150,000 - 600,000 / month'), findsOneWidget);
    });

    testWidgets('uses singular wording for a single match', (tester) async {
      await tester.pumpWidget(resultsFor(resultOf([match('Medical Doctor', 100)])));
      await tester.pumpAndSettle();

      expect(find.text('1 career fits you'), findsOneWidget);
    });
  });

  group('CareerRecommendationResultsPage confidence note', () {
    testWidgets('states how many answers the ranking rests on', (tester) async {
      await tester.pumpWidget(resultsFor(
        resultOf([match('Medical Doctor', 100)], answered: 3),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Based on 3 of 5 answers'), findsOneWidget);
      // Also echoes what was actually answered.
      expect(find.text('Science stream, Social'), findsOneWidget);
    });

    testWidgets('reflects a fully completed form', (tester) async {
      await tester.pumpWidget(resultsFor(
        resultOf([match('Medical Doctor', 100)], answered: 5),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Based on 5 of 5 answers'), findsOneWidget);
    });
  });

  group('CareerRecommendationResultsPage filtering and empty states', () {
    testWidgets('hides careers that scored nothing', (tester) async {
      await tester.pumpWidget(resultsFor(resultOf([
        match('Medical Doctor', 100),
        match('Attorney-at-Law', 0),
        match('Civil Engineer', 0),
      ])));
      await tester.pumpAndSettle();

      // A list padded with 0% results is noise, so only real matches show.
      expect(find.text('Medical Doctor'), findsOneWidget);
      expect(find.text('Attorney-at-Law'), findsNothing);
      expect(find.text('Civil Engineer'), findsNothing);
      expect(find.text('1 career fits you'), findsOneWidget);
    });

    testWidgets('offers a way back to the form when nothing matched',
        (tester) async {
      var edited = false;
      await tester.pumpWidget(resultsFor(
        resultOf([match('Attorney-at-Law', 0)]),
        onEditAnswers: () => edited = true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No strong matches yet'), findsOneWidget);
      await tester.tap(find.text('Change my answers'));
      await tester.pumpAndSettle();

      expect(edited, isTrue);
    });

    testWidgets('handles an entirely empty response', (tester) async {
      await tester.pumpWidget(resultsFor(resultOf(const [])));
      await tester.pumpAndSettle();

      expect(find.text('No strong matches yet'), findsOneWidget);
    });
  });

  group('CareerRecommendationResultsPage actions', () {
    testWidgets('tapping a match reports the career', (tester) async {
      Career? opened;
      await tester.pumpWidget(resultsFor(
        resultOf([match('Medical Doctor', 100)]),
        onCareerSelected: (career) => opened = career,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medical Doctor'));
      await tester.pumpAndSettle();

      expect(opened?.title, 'Medical Doctor');
    });

    testWidgets('matches are not tappable without a handler', (tester) async {
      await tester.pumpWidget(resultsFor(resultOf([match('Medical Doctor', 100)])));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('offers a change-answers button below the results',
        (tester) async {
      var edited = false;
      await tester.pumpWidget(resultsFor(
        resultOf([match('Medical Doctor', 100)]),
        onEditAnswers: () => edited = true,
      ));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Change my answers'));
      await tester.tap(find.text('Change my answers'));
      await tester.pumpAndSettle();

      expect(edited, isTrue);
    });
  });

  group('CareerRecommendationResultsPage error handling', () {
    testWidgets('shows the server message with a retry action', (tester) async {
      await tester.pumpWidget(wrap(CareerRecommendationResultsPage(
        token: 't',
        answers: answers,
        careerService: FakeCareerService(
          error: const ApiException(
            'Please answer at least one question to get recommendations',
          ),
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(
        find.text('Please answer at least one question to get recommendations'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('retry re-scores and recovers', (tester) async {
      final service = FakeCareerService(
        recommendation: resultOf([match('Medical Doctor', 100)]),
        error: const ApiException('Request failed'),
      );
      await tester.pumpWidget(wrap(CareerRecommendationResultsPage(
        token: 't',
        answers: answers,
        careerService: service,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      service.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Medical Doctor'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('falls back to a friendly message for a non-API failure',
        (tester) async {
      await tester.pumpWidget(wrap(CareerRecommendationResultsPage(
        token: 't',
        answers: answers,
        careerService: FakeCareerService(error: Exception('socket closed')),
      )));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Could not reach the server. Check your connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the error state can be pulled down to re-score',
        (tester) async {
      final service = FakeCareerService(
        recommendation: resultOf([match('Medical Doctor', 100)]),
        error: const ApiException('Request failed'),
      );
      await tester.pumpWidget(wrap(CareerRecommendationResultsPage(
        token: 't',
        answers: answers,
        careerService: service,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      service.error = null;
      await tester.fling(
        find.text('Something went wrong'),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Medical Doctor'), findsOneWidget);
    });
  });
}
