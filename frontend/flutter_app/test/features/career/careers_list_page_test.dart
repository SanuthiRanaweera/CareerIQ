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

  /// Finds a category chip, scrolling the horizontal chip row if the chip is
  /// off screen. At phone width only the first few chips are built, which is
  /// exactly how the row behaves on a real device.
  Future<Finder> categoryChip(WidgetTester tester, String label) async {
    final chip = find.widgetWithText(ChoiceChip, label);
    if (chip.evaluate().isEmpty) {
      await tester.dragUntilVisible(
        chip,
        find.byKey(categoryChipsKey),
        const Offset(-150, 0),
      );
      await tester.pumpAndSettle();
    }
    return chip;
  }

  /// Scrolls to a category chip and taps it.
  Future<void> tapCategory(WidgetTester tester, String label) async {
    await tester.tap(await categoryChip(tester, label));
    await tester.pumpAndSettle();
  }

  /// Types into the search box and waits out the 350ms debounce.
  ///
  /// `pumpAndSettle` alone is not enough: it stops as soon as no frame is
  /// scheduled, which happens well before the debounce timer fires, so the
  /// clock has to be advanced explicitly first.
  Future<void> search(WidgetTester tester, String term) async {
    await tester.enterText(find.byType(TextField), term);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  group('CareersListPage', () {
    testWidgets('shows a loading indicator before the careers arrive', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: FakeCareerService())),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading careers...'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('renders a card per career with title, category and salary', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: FakeCareerService())),
      );
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

    testWidgets('writes the demand level as text, not colour alone', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: FakeCareerService())),
      );
      await tester.pumpAndSettle();

      // Two "Very High" careers and one "Medium" in the sample data. The level
      // must be readable without relying on the badge colour.
      expect(find.text('Very High demand'), findsNWidgets(2));
      expect(find.text('Medium demand'), findsOneWidget);
    });

    testWidgets('uses singular wording when only one career exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CareersListPage(
            token: 't',
            careerService: FakeCareerService(careers: [careerFixture()]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 career to explore'), findsOneWidget);
      expect(find.text('1 careers to explore'), findsNothing);
    });

    testWidgets('shows an empty state when there are no careers', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CareersListPage(
            token: 't',
            careerService: FakeCareerService(careers: const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No careers yet'), findsOneWidget);
      expect(
        find.text('Careers added by your administrator will appear here.'),
        findsOneWidget,
      );
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('shows the server error message with a retry action', (
      tester,
    ) async {
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

    testWidgets('falls back to a friendly message for a non-API failure', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CareersListPage(
            token: 't',
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

    testWidgets('cards are not tappable when no handler is supplied', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: FakeCareerService())),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('tapping a card reports the selected career', (tester) async {
      Career? selected;
      await tester.pumpWidget(
        wrap(
          CareersListPage(
            token: 't',
            careerService: FakeCareerService(),
            onCareerSelected: (career) => selected = career,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_rounded), findsNWidgets(3));

      await tester.tap(find.text('Medical Doctor'));
      await tester.pumpAndSettle();

      expect(selected?.title, 'Medical Doctor');
      expect(selected?.category, 'Healthcare & Medicine');
    });
  });

  group('CareersListPage search and category filter', () {
    testWidgets('shows a search field and a chip per category', (tester) async {
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: FakeCareerService())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search careers, skills or industries'), findsOneWidget);

      // "All" comes first, then one chip per category from the backend. The
      // row scrolls horizontally, so later chips are reached by dragging.
      expect(find.byKey(categoryChipsKey), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(
        await categoryChip(tester, 'Healthcare & Medicine'),
        findsOneWidget,
      );
      expect(
        await categoryChip(tester, 'Information Technology'),
        findsOneWidget,
      );
    });

    testWidgets('"All" is selected by default and sends no category filter', (
      tester,
    ) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      final allChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'All'),
      );
      expect(allChip.selected, isTrue);
      expect(service.lastCategory, 'All');
      expect(find.text('3 careers to explore'), findsOneWidget);
    });

    testWidgets('tapping a category chip filters the list', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await tapCategory(tester, 'Healthcare & Medicine');

      expect(service.lastCategory, 'Healthcare & Medicine');
      expect(find.text('Medical Doctor'), findsOneWidget);
      expect(find.text('Software Engineer'), findsNothing);
      // Wording changes to "found" once a filter is active.
      expect(find.text('1 career found'), findsOneWidget);
    });

    testWidgets('typing searches the backend after the debounce', (
      tester,
    ) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();
      final callsAfterLoad = service.getCareersCallCount;

      await tester.enterText(find.byType(TextField), 'medical');
      await tester.pump();

      // Nothing is sent while the student is still typing.
      expect(service.getCareersCallCount, callsAfterLoad);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(service.getCareersCallCount, callsAfterLoad + 1);
      expect(service.lastSearch, 'medical');
      expect(find.text('Medical Doctor'), findsOneWidget);
      expect(find.text('Software Engineer'), findsNothing);
    });

    testWidgets('rapid typing is debounced into a single request', (
      tester,
    ) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();
      final callsAfterLoad = service.getCareersCallCount;

      for (final term in ['m', 'me', 'med', 'medi']) {
        await tester.enterText(find.byType(TextField), term);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Four keystrokes, one request, carrying the final term.
      expect(service.getCareersCallCount, callsAfterLoad + 1);
      expect(service.lastSearch, 'medi');
    });

    testWidgets('search and category filter combine', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await tapCategory(tester, 'Information Technology');
      await search(tester, 'software');

      expect(service.lastCategory, 'Information Technology');
      expect(service.lastSearch, 'software');
      expect(find.text('Software Engineer'), findsOneWidget);
      expect(find.text('1 career found'), findsOneWidget);
    });

    testWidgets('a search with no matches offers a way to clear the filters', (
      tester,
    ) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await search(tester, 'zzzzz');

      // Distinct from the "No careers yet" state: this one is recoverable.
      expect(find.text('No matching careers'), findsOneWidget);
      expect(find.text('No careers yet'), findsNothing);
      expect(find.text('Clear filters'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(service.lastSearch, '');
      expect(service.lastCategory, 'All');
      expect(find.text('3 careers to explore'), findsOneWidget);
    });

    testWidgets('the clear button resets the search box', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      // No clear button until there is something to clear.
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await search(tester, 'medical');
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(service.lastSearch, '');
      expect(find.text('3 careers to explore'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('filters stay visible while results are reloading', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CareersListPage(
            token: 't',
            careerService: FakeCareerService(
              responseDelay: const Duration(milliseconds: 300),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'medical');
      // Past the 350ms debounce, so the request has started, but not past the
      // 300ms response delay, so it is still in flight.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));

      // Mid-request: the search box and chips remain on screen, and a thin
      // progress bar reports the work instead of blanking the list.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(categoryChipsKey), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('a stale response cannot overwrite newer results', (
      tester,
    ) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      // First search is slow, so it is still in flight when the next one
      // starts.
      service.responseDelay = const Duration(milliseconds: 800);
      await tester.enterText(find.byType(TextField), 'medical');
      await tester.pump(const Duration(milliseconds: 400));

      // Second search is fast and lands first.
      service.responseDelay = const Duration(milliseconds: 10);
      await tester.enterText(find.byType(TextField), 'software');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Software Engineer'), findsOneWidget);

      // Now let the slow first response arrive. It is stale and must be
      // discarded rather than replacing the newer results.
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(service.getCareersCallCount, 3); // initial load + two searches
      expect(find.text('Software Engineer'), findsOneWidget);
      expect(find.text('Medical Doctor'), findsNothing);
    });

    testWidgets('the screen still works when categories fail to load', (
      tester,
    ) async {
      // getCategories failing must not take the whole screen down; the list
      // simply renders without the chip row.
      final service = _CategoriesFailService();
      await tester.pumpWidget(
        wrap(CareersListPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Software Engineer'), findsOneWidget);
      expect(find.text('3 careers to explore'), findsOneWidget);
    });
  });
}

/// Fails only on [getCategories], so the careers list itself still succeeds.
class _CategoriesFailService extends FakeCareerService {
  @override
  Future<List<String>> getCategories(String token) async =>
      throw const ApiException('categories unavailable');
}
