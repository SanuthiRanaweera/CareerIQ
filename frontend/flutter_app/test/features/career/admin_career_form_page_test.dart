import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/features/career/screens/admin_career_form_page.dart';
import 'package:flutter_app/models/career.dart';
import 'package:flutter_app/services/api_service.dart';

import 'career_test_fakes.dart';

// Tests for the admin add/edit career form (core fields).
//
// The form must never send a career the backend would reject, so these tests
// concentrate on validation, on what is actually submitted, and on the
// feedback the admin gets back.

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  Future<void> scrollToTop(WidgetTester tester) async {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
    await tester.pumpAndSettle();
  }

  /// Brings a widget into view; the form is a lazy ListView taller than a
  /// phone screen.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      return;
    }
    await scrollToTop(tester);
    // The scrollable must be named explicitly: every TextField contains its
    // own Scrollable, so the default finder matches several widgets.
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> typeIn(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    final field = find.widgetWithText(TextFormField, label);
    await scrollTo(tester, field);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  Future<void> tapChip(WidgetTester tester, String label) async {
    await scrollTo(tester, find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// Adds one value to an [EditableStringList] identified by its add button.
  Future<void> addToList(
    WidgetTester tester,
    String listLabel,
    String value,
  ) async {
    final addButton = find.byTooltip('Add to $listLabel');
    await scrollTo(tester, addButton);
    final input = find.ancestor(
      of: find.byTooltip('Add to $listLabel'),
      matching: find.byType(Row),
    );
    await tester.enterText(
      find.descendant(of: input.first, matching: find.byType(TextField)),
      value,
    );
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester, {bool editing = false}) async {
    final label = editing ? 'Save changes' : 'Create career';
    await scrollTo(tester, find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// Fills every field the Career model requires.
  Future<void> fillRequired(WidgetTester tester) async {
    await typeIn(tester, 'Career title *', 'Data Engineer');
    await typeIn(tester, 'Category or industry *', 'Information Technology');
    await typeIn(tester, 'Description *', 'Builds data pipelines.');
    await typeIn(tester, 'Minimum *', '180000');
    await typeIn(tester, 'Maximum *', '520000');
    await tapChip(tester, 'High');
    await tapChip(tester, 'Technology');
    await addToList(tester, "What you'd do", 'Build data pipelines');
    await addToList(tester, 'Required skills', 'SQL');
  }

  group('AdminCareerFormPage create mode', () {
    testWidgets('shows a create-mode heading and button', (tester) async {
      await tester.pumpWidget(wrap(
        AdminCareerFormPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add career'), findsOneWidget);
      expect(find.text('NEW CAREER'), findsOneWidget);
      await scrollTo(tester, find.text('Create career'));
      expect(find.text('Create career'), findsOneWidget);
    });

    testWidgets('creates a career with every required field', (tester) async {
      final service = FakeCareerService();
      Career? saved;
      await tester.pumpWidget(wrap(AdminCareerFormPage(
        token: 't',
        careerService: service,
        onSaved: (career) => saved = career,
      )));
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await save(tester);

      final sent = service.lastCreated;
      expect(sent, isNotNull);
      expect(sent!.title, 'Data Engineer');
      expect(sent.category, 'Information Technology');
      expect(sent.description, 'Builds data pipelines.');
      expect(sent.salaryRange.min, 180000);
      expect(sent.salaryRange.max, 520000);
      expect(sent.jobOutlook, 'High');
      expect(sent.recommendedStreams, ['Technology']);
      expect(sent.whatYouDo, ['Build data pipelines']);
      expect(sent.requiredSkills, ['SQL']);
      expect(saved?.title, 'Data Engineer');
    });

    testWidgets('confirms the save with a success message', (tester) async {
      await tester.pumpWidget(wrap(
        AdminCareerFormPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await save(tester);

      expect(find.text('Data Engineer created successfully'), findsOneWidget);
    });
  });

  group('AdminCareerFormPage validation', () {
    testWidgets('refuses to save an empty form and says what is missing',
        (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await save(tester);

      expect(service.lastCreated, isNull);
      // Nine outstanding fields is too many to name in a snackbar, so it is
      // summarised and the inline messages identify each one.
      expect(
        find.text('Please complete the 9 highlighted fields'),
        findsOneWidget,
      );
    });

    testWidgets('shows a message for each empty required text field',
        (tester) async {
      await tester.pumpWidget(wrap(
        AdminCareerFormPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      // Saving happens from the bottom of the form, by which point the fields
      // at the top have been unmounted by the lazy list. They must still be
      // validated, and must show their message once scrolled back into view.
      await save(tester);
      await scrollToTop(tester);

      expect(find.text('Career title is required'), findsOneWidget);
      expect(find.text('Category is required'), findsOneWidget);
      expect(find.text('Description is required'), findsOneWidget);
    });

    testWidgets('a field scrolled out of view is still validated',
        (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      // Complete everything except the title, which sits at the very top and
      // is unmounted by the time the save button is reached.
      await typeIn(tester, 'Category or industry *', 'Information Technology');
      await typeIn(tester, 'Description *', 'Builds data pipelines.');
      await typeIn(tester, 'Minimum *', '180000');
      await typeIn(tester, 'Maximum *', '520000');
      await tapChip(tester, 'High');
      await tapChip(tester, 'Technology');
      await addToList(tester, "What you'd do", 'Build data pipelines');
      await addToList(tester, 'Required skills', 'SQL');
      await save(tester);

      expect(service.lastCreated, isNull);
      expect(find.text('Please complete: title'), findsOneWidget);
    });

    testWidgets('requires both list fields the backend insists on',
        (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      // Everything except the two required lists.
      await typeIn(tester, 'Career title *', 'Data Engineer');
      await typeIn(tester, 'Category or industry *', 'Information Technology');
      await typeIn(tester, 'Description *', 'Builds data pipelines.');
      await typeIn(tester, 'Minimum *', '180000');
      await typeIn(tester, 'Maximum *', '520000');
      await tapChip(tester, 'High');
      await tapChip(tester, 'Technology');
      await save(tester);

      // These two are non-empty arrays in the Career model, so the form has to
      // catch them rather than letting the server reject the save.
      expect(service.lastCreated, isNull);
      expect(
        find.text("Please complete: what you'd do, skills"),
        findsOneWidget,
      );
      await scrollTo(
        tester,
        find.text('Add at least one day-to-day responsibility'),
      );
      expect(
        find.text('Add at least one day-to-day responsibility'),
        findsOneWidget,
      );
    });

    testWidgets('rejects a maximum salary below the minimum', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await typeIn(tester, 'Maximum *', '100');
      await save(tester);

      expect(service.lastCreated, isNull);
      await scrollTo(tester, find.text('Must be at least the minimum'));
      expect(find.text('Must be at least the minimum'), findsOneWidget);
    });

    testWidgets('rejects a non-numeric salary', (tester) async {
      await tester.pumpWidget(wrap(
        AdminCareerFormPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await typeIn(tester, 'Minimum *', 'abc');
      await save(tester);

      await scrollTo(tester, find.text('Enter a whole number'));
      expect(find.text('Enter a whole number'), findsOneWidget);
    });
  });

  group('AdminCareerFormPage edit mode', () {
    Career existing() => careerFixture(
          id: 'id-se',
          title: 'Software Engineer',
          category: 'Information Technology',
          description: 'Designs, builds and maintains software systems.',
          whatYouDo: const ['Write and review code'],
          requiredSkills: const ['Programming'],
          recommendedStreams: const ['Technology'],
          industryOpportunities: const ['Software export companies'],
          relatedCourseKeywords: const ['software engineering'],
          pathway: const [
            CareerPathwayStep(
              order: 1,
              stage: 'A/L Stream',
              title: 'Technology stream',
            ),
          ],
        );

    testWidgets('pre-fills the form from the career being edited',
        (tester) async {
      await tester.pumpWidget(wrap(AdminCareerFormPage(
        token: 't',
        career: existing(),
        careerService: FakeCareerService(),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Edit career'), findsOneWidget);
      expect(find.text('EDITING'), findsOneWidget);
      expect(find.text('Software Engineer'), findsNWidgets(2));
      expect(find.text('Information Technology'), findsOneWidget);
      expect(find.text('150000'), findsOneWidget);
      expect(find.text('500000'), findsOneWidget);
      await scrollTo(tester, find.text('Write and review code'));
      expect(find.text('Write and review code'), findsOneWidget);
    });

    testWidgets('saves changes through updateCareer', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(wrap(AdminCareerFormPage(
        token: 't',
        career: existing(),
        careerService: service,
      )));
      await tester.pumpAndSettle();

      await typeIn(tester, 'Career title *', 'Senior Software Engineer');
      await save(tester, editing: true);

      expect(service.lastUpdatedId, 'id-se');
      expect(service.lastUpdated?.title, 'Senior Software Engineer');
      expect(service.lastCreated, isNull);
      expect(
        find.text('Senior Software Engineer updated successfully'),
        findsOneWidget,
      );
    });

    testWidgets('keeps every field when only the title is changed',
        (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(wrap(AdminCareerFormPage(
        token: 't',
        career: existing(),
        careerService: service,
      )));
      await tester.pumpAndSettle();

      await typeIn(tester, 'Career title *', 'Renamed Career');
      await save(tester, editing: true);

      final sent = service.lastUpdated!;
      expect(sent.pathway.length, 1);
      expect(sent.pathway.first.stage, 'A/L Stream');
      expect(sent.industryOpportunities, ['Software export companies']);
      // Course keywords belong to the Course module and this form never
      // edits them, so they must survive a save untouched.
      expect(sent.relatedCourseKeywords, ['software engineering']);
    });

    testWidgets('removing a list entry is saved', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(wrap(AdminCareerFormPage(
        token: 't',
        career: existing(),
        careerService: service,
      )));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byTooltip('Remove Programming'));
      await tester.tap(find.byTooltip('Remove Programming'));
      await tester.pumpAndSettle();

      // Skills is required, so emptying it must block the save.
      await save(tester, editing: true);
      expect(service.lastUpdated, isNull);
      expect(find.text('Please complete: skills'), findsOneWidget);
    });
  });

  group('AdminCareerFormPage server errors', () {
    testWidgets('shows a duplicate title message from the backend',
        (tester) async {
      await tester.pumpWidget(wrap(AdminCareerFormPage(
        token: 't',
        careerService: FakeCareerService(
          error: const ApiException(
            'A career with this title already exists',
          ),
        ),
      )));
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await save(tester);

      expect(
        find.text('A career with this title already exists'),
        findsOneWidget,
      );
    });

    testWidgets('shows a permission message for a non-admin', (tester) async {
      await tester.pumpWidget(wrap(AdminCareerFormPage(
        token: 't',
        careerService: FakeCareerService(
          error: const ApiException('Admin access is required for this action'),
        ),
      )));
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await save(tester);

      expect(
        find.text('Admin access is required for this action'),
        findsOneWidget,
      );
    });

    testWidgets('falls back to a friendly message for a non-API failure',
        (tester) async {
      await tester.pumpWidget(wrap(AdminCareerFormPage(
        token: 't',
        careerService: FakeCareerService(error: Exception('socket closed')),
      )));
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await save(tester);

      expect(
        find.text(
          'Could not reach the server. Check your connection and try again.',
        ),
        findsOneWidget,
      );
    });
  });
}
