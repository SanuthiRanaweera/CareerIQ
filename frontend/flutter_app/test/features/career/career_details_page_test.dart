import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/features/career/screens/career_details_page.dart';
import 'package:flutter_app/models/career.dart';
import 'package:flutter_app/services/api_service.dart';

import 'career_test_fakes.dart';

// Tests for screen 09 - Career details.
//
// The screen is built from optional sections, so the tests cover both a fully
// populated career and a sparse one, plus the course placeholder that stands
// in for the Course module.

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  /// Scrolls a section into view before asserting on it. The details page is
  /// a lazy ListView, so a section below the fold is not built at all until
  /// it is scrolled to.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200);
    await tester.pumpAndSettle();
  }

  /// A career with every section filled in.
  Career fullCareer() => careerFixture(
    id: 'id-se',
    title: 'Software Engineer',
    category: 'Information Technology',
    description: 'Designs, builds and maintains software systems.',
    whatYouDo: const ['Write and review code', 'Debug production issues'],
    requiredSkills: const ['Programming', 'Databases'],
    recommendedStreams: const ['Technology', 'Mathematics'],
    industryOpportunities: const [
      'Software export companies',
      'Banking IT divisions',
    ],
    relatedCourseKeywords: const ['software engineering', 'computer science'],
    pathway: const [
      CareerPathwayStep(
        order: 1,
        stage: 'A/L Stream',
        title: 'Technology stream',
      ),
    ],
  );

  Widget detailsFor(Career career, {void Function(Career)? onViewPathway}) =>
      wrap(
        CareerDetailsPage(
          token: 't',
          careerId: career.id,
          onViewPathway: onViewPathway,
          careerService: FakeCareerService(careers: [career]),
        ),
      );

  group('CareerDetailsPage', () {
    testWidgets('shows a loading indicator while the career is fetched', (
      tester,
    ) async {
      await tester.pumpWidget(detailsFor(fullCareer()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading career details...'), findsOneWidget);
      // Until the career is known the app bar shows a neutral title.
      expect(find.text('Career details'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('shows the heading, category, demand level and salary', (
      tester,
    ) async {
      await tester.pumpWidget(detailsFor(fullCareer()));
      await tester.pumpAndSettle();

      // Title appears twice: once in the app bar, once as the heading.
      expect(find.text('Software Engineer'), findsNWidgets(2));
      expect(find.text('INFORMATION TECHNOLOGY'), findsOneWidget);
      expect(find.text('Very High demand'), findsOneWidget);
      expect(find.text('Typical salary'), findsOneWidget);
      expect(find.text('LKR 150,000 - 500,000 / month'), findsOneWidget);
    });

    testWidgets('renders every content section', (tester) async {
      await tester.pumpWidget(detailsFor(fullCareer()));
      await tester.pumpAndSettle();

      expect(find.text('About this career'), findsOneWidget);
      expect(
        find.text('Designs, builds and maintains software systems.'),
        findsOneWidget,
      );

      await scrollTo(tester, find.text("What you'd do"));
      expect(find.text('Write and review code'), findsOneWidget);
      expect(find.text('Debug production issues'), findsOneWidget);

      await scrollTo(tester, find.text('Skills you need'));
      expect(find.text('Programming'), findsOneWidget);
      expect(find.text('Databases'), findsOneWidget);

      await scrollTo(tester, find.text('Recommended A/L streams'));
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);

      await scrollTo(tester, find.text('Where the opportunities are'));
      expect(find.text('Software export companies'), findsOneWidget);
      expect(find.text('Banking IT divisions'), findsOneWidget);
    });

    testWidgets('hides sections that have no content', (tester) async {
      // A sparse career: only the required fields are set.
      final sparse = careerFixture(
        id: 'sparse',
        title: 'New Career',
        description: '',
        whatYouDo: const [],
        requiredSkills: const [],
        recommendedStreams: const [],
        industryOpportunities: const [],
        relatedCourseKeywords: const [],
      );

      await tester.pumpWidget(detailsFor(sparse));
      await tester.pumpAndSettle();

      expect(find.text('About this career'), findsNothing);
      expect(find.text("What you'd do"), findsNothing);
      expect(find.text('Skills you need'), findsNothing);
      expect(find.text('Recommended A/L streams'), findsNothing);
      expect(find.text('Where the opportunities are'), findsNothing);

      // Salary and the course placeholder are always shown.
      expect(find.text('Typical salary'), findsOneWidget);
      expect(find.text('Recommended courses'), findsOneWidget);
    });
  });

  group('CareerDetailsPage recommended courses', () {
    testWidgets('lists the keywords as tappable course topics', (tester) async {
      await tester.pumpWidget(detailsFor(fullCareer()));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Recommended courses'));

      expect(
        find.text('Tap a topic to find matching courses.'),
        findsOneWidget,
      );
      expect(find.text('Course topics:'), findsOneWidget);
      expect(find.text('software engineering'), findsOneWidget);
      expect(find.text('computer science'), findsOneWidget);
    });

    testWidgets('explains when there are no keywords', (tester) async {
      final career = careerFixture(
        id: 'no-keywords',
        relatedCourseKeywords: const [],
      );
      await tester.pumpWidget(detailsFor(career));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Recommended courses'));

      expect(
        find.text('No course topics have been added for this career yet.'),
        findsOneWidget,
      );
      expect(find.text('Course topics:'), findsNothing);
    });

    testWidgets('tapping a topic opens the course finder with it searched', (
      tester,
    ) async {
      await tester.pumpWidget(detailsFor(fullCareer()));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('software engineering'));
      await tester.tap(find.text('software engineering'));
      await tester.pumpAndSettle();

      expect(find.text('Course finder'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'software engineering',
      );
    });
  });

  group('CareerDetailsPage pathway button', () {
    testWidgets('reports the career when the pathway button is tapped', (
      tester,
    ) async {
      Career? opened;
      final career = fullCareer();
      await tester.pumpWidget(
        detailsFor(career, onViewPathway: (c) => opened = c),
      );
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('View career pathway'));
      await tester.tap(find.text('View career pathway'));
      await tester.pumpAndSettle();

      expect(opened?.title, 'Software Engineer');
    });

    testWidgets('hides the button when no handler is supplied', (tester) async {
      await tester.pumpWidget(detailsFor(fullCareer()));
      await tester.pumpAndSettle();

      expect(find.text('View career pathway'), findsNothing);
    });

    testWidgets('hides the button when the career has no pathway', (
      tester,
    ) async {
      final career = careerFixture(id: 'no-path', pathway: const []);
      await tester.pumpWidget(detailsFor(career, onViewPathway: (_) {}));
      await tester.pumpAndSettle();

      expect(find.text('View career pathway'), findsNothing);
    });
  });

  group('CareerDetailsPage error handling', () {
    testWidgets('shows the server message with a retry action', (tester) async {
      final service = FakeCareerService(
        error: const ApiException('Career not found'),
      );
      await tester.pumpWidget(
        wrap(
          CareerDetailsPage(
            token: 't',
            careerId: 'missing',
            careerService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Career not found'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('retry reloads the career and recovers', (tester) async {
      final service = FakeCareerService(
        careers: [fullCareer()],
        error: const ApiException('Career not found'),
      );
      await tester.pumpWidget(
        wrap(
          CareerDetailsPage(
            token: 't',
            careerId: 'id-se',
            careerService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      service.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Typical salary'), findsOneWidget);
    });

    testWidgets('falls back to a friendly message for a non-API failure', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CareerDetailsPage(
            token: 't',
            careerId: 'id-se',
            careerService: FakeCareerService(error: Exception('socket closed')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Could not reach the server. Check your connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the error state can be pulled down to retry', (tester) async {
      final service = FakeCareerService(
        careers: [fullCareer()],
        error: const ApiException('Career not found'),
      );
      await tester.pumpWidget(
        wrap(
          CareerDetailsPage(
            token: 't',
            careerId: 'id-se',
            careerService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      // Pull to refresh has to work in the error state too, not only when the
      // career loaded: the retry button and the gesture are both offered.
      service.error = null;
      await tester.fling(
        find.text('Something went wrong'),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Typical salary'), findsOneWidget);
    });
  });
}
