import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/features/career/screens/careers_list_page.dart';
import 'package:flutter_app/models/career.dart';
import 'package:flutter_app/services/api_service.dart';

import 'career_test_fakes.dart';

// Tests for screen 08 - Careers (the list screen).
//
// Covers the four things a student can encounter: data loaded, nothing to
// show, something went wrong, and tapping through to a career.

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  group('CareersListPage', () {
    testWidgets('shows a loading indicator before the careers arrive',
        (tester) async {
      await tester.pumpWidget(wrap(
        CareersListPage(token: 't', careerService: FakeCareerService()),
      ));

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading careers...'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('renders a card per career with title, category and salary',
        (tester) async {
      await tester.pumpWidget(wrap(
        CareersListPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Find your path'), findsOneWidget);
      expect(find.text('3 careers to explore'), findsOneWidget);

      expect(find.text('Software Engineer'), findsOneWidget);
      expect(find.text('Information Technology'), findsOneWidget);
      expect(find.text('Medical Doctor'), findsOneWidget);
      expect(find.text('Agricultural Officer'), findsOneWidget);

      expect(find.text('LKR 150,000 - 500,000 / month'), findsOneWidget);
      expect(find.text('LKR 70,000 - 220,000 / month'), findsOneWidget);
    });

    testWidgets('writes the demand level as text, not colour alone',
        (tester) async {
      await tester.pumpWidget(wrap(
        CareersListPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      // Two "Very High" careers and one "Medium" in the sample data. The level
      // must be readable without relying on the badge colour.
      expect(find.text('Very High demand'), findsNWidgets(2));
      expect(find.text('Medium demand'), findsOneWidget);
    });

    testWidgets('uses singular wording when only one career exists',
        (tester) async {
      await tester.pumpWidget(wrap(CareersListPage(
        token: 't',
        careerService: FakeCareerService(careers: [careerFixture()]),
      )));
      await tester.pumpAndSettle();

      expect(find.text('1 career to explore'), findsOneWidget);
      expect(find.text('1 careers to explore'), findsNothing);
    });

    testWidgets('shows an empty state when there are no careers',
        (tester) async {
      await tester.pumpWidget(wrap(CareersListPage(
        token: 't',
        careerService: FakeCareerService(careers: const []),
      )));
      await tester.pumpAndSettle();

      expect(find.text('No careers yet'), findsOneWidget);
      expect(
        find.text('Careers added by your administrator will appear here.'),
        findsOneWidget,
      );
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('shows the server error message with a retry action',
        (tester) async {
      final service = FakeCareerService(
        error: const ApiException('Invalid or expired token'),
      );
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      // The backend's own wording is shown rather than a generic message.
      expect(find.text('Invalid or expired token'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('retry re-requests the careers and recovers', (tester) async {
      final service = FakeCareerService(
        error: const ApiException('Could not load careers'),
      );
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      // The backend recovers, then the student taps Try again.
      service.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Software Engineer'), findsOneWidget);
      expect(service.getCareersCallCount, 2);
    });

    testWidgets('falls back to a friendly message for a non-API failure',
        (tester) async {
      await tester.pumpWidget(wrap(CareersListPage(
        token: 't',
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

    testWidgets('cards are not tappable when no handler is supplied',
        (tester) async {
      await tester.pumpWidget(wrap(
        CareersListPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('tapping a card reports the selected career', (tester) async {
      Career? selected;
      await tester.pumpWidget(wrap(CareersListPage(
        token: 't',
        careerService: FakeCareerService(),
        onCareerSelected: (career) => selected = career,
      )));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_rounded), findsNWidgets(3));

      await tester.tap(find.text('Medical Doctor'));
      await tester.pumpAndSettle();

      expect(selected?.title, 'Medical Doctor');
      expect(selected?.category, 'Healthcare & Medicine');
    });
  });
}
