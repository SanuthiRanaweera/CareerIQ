import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/features/career/screens/admin_manage_careers_page.dart';
import 'package:flutter_app/models/career.dart';
import 'package:flutter_app/services/api_service.dart';

import 'career_test_fakes.dart';

// Tests for the admin "Manage careers" list.
//
// This screen is the administrator's way into the career records, so the
// tests focus on finding a career and getting to its editor.

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  /// Types into the search box and waits out the 350ms debounce, which
  /// `pumpAndSettle` on its own does not advance past.
  Future<void> search(WidgetTester tester, String term) async {
    await tester.enterText(find.byType(TextField), term);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  group('AdminManageCareersPage', () {
    testWidgets('shows a loading indicator before the careers arrive',
        (tester) async {
      await tester.pumpWidget(wrap(
        AdminManageCareersPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pump();

      expect(find.text('Loading careers...'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('lists each career with category, demand and salary',
        (tester) async {
      await tester.pumpWidget(wrap(
        AdminManageCareersPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Career records'), findsOneWidget);
      expect(find.text('3 careers'), findsOneWidget);

      expect(find.text('Software Engineer'), findsOneWidget);
      expect(find.text('Information Technology'), findsOneWidget);
      expect(find.text('Very High demand'), findsNWidgets(2));
      expect(find.text('Medium demand'), findsOneWidget);
      expect(find.text('LKR 70,000 - 220,000 / month'), findsOneWidget);
    });

    testWidgets('uses singular wording for a single career', (tester) async {
      await tester.pumpWidget(wrap(AdminManageCareersPage(
        token: 't',
        careerService: FakeCareerService(careers: [careerFixture()]),
      )));
      await tester.pumpAndSettle();

      expect(find.text('1 career'), findsOneWidget);
    });

    testWidgets('refresh action reloads the list', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminManageCareersPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();
      expect(service.getCareersCallCount, 1);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      expect(service.getCareersCallCount, 2);
    });
  });

  group('AdminManageCareersPage add and edit', () {
    testWidgets('offers an add button that reports the request',
        (tester) async {
      var addPressed = false;
      await tester.pumpWidget(wrap(AdminManageCareersPage(
        token: 't',
        careerService: FakeCareerService(),
        onAddCareer: () => addPressed = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add career'));
      await tester.pumpAndSettle();

      expect(addPressed, isTrue);
    });

    testWidgets('hides the add button when no handler is supplied',
        (tester) async {
      await tester.pumpWidget(wrap(
        AdminManageCareersPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add career'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('the edit icon reports the career to edit', (tester) async {
      Career? editing;
      await tester.pumpWidget(wrap(AdminManageCareersPage(
        token: 't',
        careerService: FakeCareerService(),
        onEditCareer: (career) => editing = career,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit Medical Doctor'));
      await tester.pumpAndSettle();

      expect(editing?.title, 'Medical Doctor');
    });

    testWidgets('tapping the row opens the same editor as the icon',
        (tester) async {
      Career? editing;
      await tester.pumpWidget(wrap(AdminManageCareersPage(
        token: 't',
        careerService: FakeCareerService(),
        onEditCareer: (career) => editing = career,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Software Engineer'));
      await tester.pumpAndSettle();

      expect(editing?.title, 'Software Engineer');
    });

    testWidgets('hides the edit icon when no handler is supplied',
        (tester) async {
      await tester.pumpWidget(wrap(
        AdminManageCareersPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });
  });

  group('AdminManageCareersPage search', () {
    testWidgets('searching narrows the list through the backend',
        (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminManageCareersPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await search(tester, 'medical');

      expect(service.lastSearch, 'medical');
      expect(find.text('Medical Doctor'), findsOneWidget);
      expect(find.text('Software Engineer'), findsNothing);
      expect(find.text('1 career'), findsOneWidget);
    });

    testWidgets('rapid typing is debounced into a single request',
        (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminManageCareersPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();
      final before = service.getCareersCallCount;

      for (final term in ['m', 'me', 'med']) {
        await tester.enterText(find.byType(TextField), term);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(service.getCareersCallCount, before + 1);
      expect(service.lastSearch, 'med');
    });

    testWidgets('an unmatched search offers a way to clear it', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminManageCareersPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await search(tester, 'zzzzz');

      expect(find.text('No matching careers'), findsOneWidget);
      expect(find.text('No careers yet'), findsNothing);

      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();

      expect(service.lastSearch, '');
      expect(find.text('3 careers'), findsOneWidget);
    });

    testWidgets('the clear button resets the search box', (tester) async {
      await tester.pumpWidget(wrap(
        AdminManageCareersPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsNothing);
      await search(tester, 'medical');
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('3 careers'), findsOneWidget);
    });
  });

  group('AdminManageCareersPage empty and error states', () {
    testWidgets('prompts to add the first career when none exist',
        (tester) async {
      await tester.pumpWidget(wrap(AdminManageCareersPage(
        token: 't',
        careerService: FakeCareerService(careers: const []),
      )));
      await tester.pumpAndSettle();

      expect(find.text('No careers yet'), findsOneWidget);
      expect(find.text('Add the first career to get started.'), findsOneWidget);
    });

    testWidgets('shows the server message with a retry action', (tester) async {
      await tester.pumpWidget(wrap(AdminManageCareersPage(
        token: 't',
        careerService: FakeCareerService(
          error: const ApiException('Admin access is required for this action'),
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(
        find.text('Admin access is required for this action'),
        findsOneWidget,
      );
    });

    testWidgets('retry reloads and recovers', (tester) async {
      final service = FakeCareerService(
        error: const ApiException('Request failed'),
      );
      await tester.pumpWidget(
        wrap(AdminManageCareersPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      service.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('3 careers'), findsOneWidget);
    });
  });
}
