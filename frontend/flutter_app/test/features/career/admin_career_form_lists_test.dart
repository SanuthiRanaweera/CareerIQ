import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/features/career/screens/admin_career_form_page.dart';
import 'package:flutter_app/features/career/widgets/editable_string_list.dart';
import 'package:flutter_app/models/career.dart';

import 'career_test_fakes.dart';

// Tests for the optional list fields on the admin career form: industry
// opportunities, the pathway step editor, and the matching tags that feed the
// recommendation scoring.
//
// None of these block a save, so the tests focus on whether what the admin
// enters actually reaches the backend, and on the pathway ordering rules.

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  Future<void> scrollToTop(WidgetTester tester) async {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 6000));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      return;
    }
    await scrollToTop(tester);
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> typeIn(WidgetTester tester, String label, String value) async {
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

  Future<void> addToList(
    WidgetTester tester,
    String listLabel,
    String value,
  ) async {
    final addButton = find.byTooltip('Add to $listLabel');
    await scrollTo(tester, addButton);
    final row = find
        .ancestor(of: addButton, matching: find.byType(Row))
        .first;
    await tester.enterText(
      find.descendant(of: row, matching: find.byType(TextField)),
      value,
    );
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();
  }

  /// Opens the pathway dialog and fills it in.
  Future<void> addPathwayStep(
    WidgetTester tester, {
    required String stage,
    required String title,
    String duration = '',
  }) async {
    await scrollTo(tester, find.text('Add pathway step'));
    await tester.tap(find.text('Add pathway step'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Stage *'),
      stage,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Step title *'),
      title,
    );
    if (duration.isNotEmpty) {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration'),
        duration,
      );
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add step'));
    await tester.pumpAndSettle();
  }

  /// Taps a suggestion chip belonging to an [EditableStringList].
  Future<void> tapSuggestion(WidgetTester tester, String value) async {
    final chip = find.widgetWithText(ActionChip, value);
    await scrollTo(tester, chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester, {bool editing = false}) async {
    final label = editing ? 'Save changes' : 'Create career';
    await scrollTo(tester, find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

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

  group('AdminCareerFormPage optional list fields', () {
    testWidgets('saves without any optional field filled in', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await save(tester);

      // Everything here is optional, so an empty set of lists must still save.
      final sent = service.lastCreated!;
      expect(sent.industryOpportunities, isEmpty);
      expect(sent.pathway, isEmpty);
      expect(sent.interestTags, isEmpty);
      expect(sent.personalityTypes, isEmpty);
      expect(sent.workStyles, isEmpty);
    });

    testWidgets('saves industry opportunities', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await addToList(
        tester,
        'Industry opportunities',
        'Banking IT divisions',
      );
      await addToList(tester, 'Industry opportunities', 'Remote contracts');
      await save(tester);

      expect(service.lastCreated!.industryOpportunities, [
        'Banking IT divisions',
        'Remote contracts',
      ]);
    });

    testWidgets('saves the matching tags used by the scoring', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await addToList(tester, 'Interest tags', 'technology');
      await addToList(tester, 'Relevant A/L subjects', 'Combined Mathematics');
      await tapChip(tester, 'Analytical');
      await tapChip(tester, 'Remote');
      await save(tester);

      final sent = service.lastCreated!;
      expect(sent.interestTags, ['technology']);
      expect(sent.alSubjects, ['Combined Mathematics']);
      expect(sent.personalityTypes, ['Analytical']);
      expect(sent.workStyles, ['Remote']);
    });

    testWidgets('a list entry can be removed again', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await addToList(tester, 'Interest tags', 'technology');
      await addToList(tester, 'Interest tags', 'mistake');

      await scrollTo(tester, find.byTooltip('Remove mistake'));
      await tester.tap(find.byTooltip('Remove mistake'));
      await tester.pumpAndSettle();
      await save(tester);

      expect(service.lastCreated!.interestTags, ['technology']);
    });

    testWidgets('ignores a duplicate list entry', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await addToList(tester, 'Interest tags', 'technology');
      await addToList(tester, 'Interest tags', 'Technology');
      await save(tester);

      // Case-insensitive, so the same tag is not stored twice.
      expect(service.lastCreated!.interestTags, ['technology']);
    });
  });

  group('AdminCareerFormPage pathway editor', () {
    testWidgets('starts with a prompt and no steps', (tester) async {
      await tester.pumpWidget(wrap(
        AdminCareerFormPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Career pathway'));
      expect(
        find.text('No steps yet. Add the first step of this pathway.'),
        findsOneWidget,
      );
    });

    testWidgets('adds steps and numbers them from one', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await addPathwayStep(
        tester,
        stage: 'A/L Stream',
        title: 'Technology stream',
        duration: '2 years',
      );
      await addPathwayStep(
        tester,
        stage: 'Degree',
        title: 'BSc in Software Engineering',
      );
      await save(tester);

      final pathway = service.lastCreated!.pathway;
      expect(pathway.length, 2);
      expect(pathway[0].order, 1);
      expect(pathway[0].stage, 'A/L Stream');
      expect(pathway[0].title, 'Technology stream');
      expect(pathway[0].durationLabel, '2 years');
      expect(pathway[1].order, 2);
      expect(pathway[1].stage, 'Degree');
    });

    testWidgets('requires a stage and a title before adding a step',
        (tester) async {
      await tester.pumpWidget(wrap(
        AdminCareerFormPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Add pathway step'));
      await tester.tap(find.text('Add pathway step'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add step'));
      await tester.pumpAndSettle();

      // The dialog stays open with its messages shown.
      expect(find.text('Stage is required'), findsOneWidget);
      expect(find.text('Step title is required'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('a common stage can be filled in with one tap',
        (tester) async {
      await tester.pumpWidget(wrap(
        AdminCareerFormPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Add pathway step'));
      await tester.tap(find.text('Add pathway step'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ActionChip, 'Internship'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Stage *'),
          matching: find.text('Internship'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('cancelling the dialog adds nothing', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await scrollTo(tester, find.text('Add pathway step'));
      await tester.tap(find.text('Add pathway step'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await save(tester);

      expect(service.lastCreated!.pathway, isEmpty);
    });

    testWidgets('moving a step down renumbers the pathway', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await addPathwayStep(tester, stage: 'Degree', title: 'Second step');
      await addPathwayStep(tester, stage: 'A/L Stream', title: 'First step');

      // Entered in the wrong order, then corrected with the reorder control.
      await scrollTo(tester, find.byTooltip('Move Second step down'));
      await tester.tap(find.byTooltip('Move Second step down'));
      await tester.pumpAndSettle();
      await save(tester);

      final pathway = service.lastCreated!.pathway;
      expect(pathway[0].title, 'First step');
      expect(pathway[0].order, 1);
      expect(pathway[1].title, 'Second step');
      expect(pathway[1].order, 2);
    });

    testWidgets('removing a step renumbers the rest', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await addPathwayStep(tester, stage: 'A/L Stream', title: 'Keep me');
      await addPathwayStep(tester, stage: 'Degree', title: 'Delete me');
      await addPathwayStep(tester, stage: 'Skills', title: 'Keep me too');

      await scrollTo(tester, find.byTooltip('Remove Delete me'));
      await tester.tap(find.byTooltip('Remove Delete me'));
      await tester.pumpAndSettle();
      await save(tester);

      final pathway = service.lastCreated!.pathway;
      expect(pathway.length, 2);
      // No gap is left behind where step 2 used to be.
      expect(pathway.map((s) => s.order), [1, 2]);
      expect(pathway.map((s) => s.title), ['Keep me', 'Keep me too']);
    });

    testWidgets('editing a step keeps its position', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await addPathwayStep(tester, stage: 'A/L Stream', title: 'First step');
      await addPathwayStep(tester, stage: 'Degree', title: 'Needs a fix');

      await scrollTo(tester, find.byTooltip('Edit Needs a fix'));
      await tester.tap(find.byTooltip('Edit Needs a fix'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Step title *'),
        'Fixed title',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save step'));
      await tester.pumpAndSettle();
      await save(tester);

      final pathway = service.lastCreated!.pathway;
      expect(pathway.length, 2);
      expect(pathway[1].title, 'Fixed title');
      expect(pathway[1].order, 2);
    });
  });

  group('AdminCareerFormPage pathway editor in edit mode', () {
    Career seeded() => careerFixture(
          id: 'id-se',
          title: 'Software Engineer',
          industryOpportunities: const ['Software export companies'],
          pathway: const [
            CareerPathwayStep(
              order: 2,
              stage: 'Degree',
              title: 'BSc in IT',
            ),
            CareerPathwayStep(
              order: 1,
              stage: 'A/L Stream',
              title: 'Technology stream',
            ),
          ],
        );

    testWidgets('pre-fills the pathway in order', (tester) async {
      await tester.pumpWidget(wrap(AdminCareerFormPage(
        token: 't',
        career: seeded(),
        careerService: FakeCareerService(),
      )));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Technology stream'));

      // Supplied out of order, shown in pathway order.
      final firstY = tester.getTopLeft(find.text('Technology stream')).dy;
      final secondY = tester.getTopLeft(find.text('BSc in IT')).dy;
      expect(firstY, lessThan(secondY));
    });

    testWidgets('adding a step to an existing pathway continues the numbering',
        (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(wrap(AdminCareerFormPage(
        token: 't',
        career: seeded(),
        careerService: service,
      )));
      await tester.pumpAndSettle();

      await addPathwayStep(tester, stage: 'Internship', title: 'Intern role');
      await save(tester, editing: true);

      final pathway = service.lastUpdated!.pathway;
      expect(pathway.length, 3);
      expect(pathway.map((s) => s.order), [1, 2, 3]);
      expect(pathway.last.title, 'Intern role');
    });
  });

  group('AdminCareerFormPage tag suggestions', () {
    testWidgets('offers suggestions on the tag fields but not the free-form '
        'ones', (tester) async {
      await tester.pumpWidget(wrap(
        AdminCareerFormPage(token: 't', careerService: FakeCareerService()),
      ));
      await tester.pumpAndSettle();

      /// Looks for a Suggestions label inside one field's own subtree.
      Future<void> expectSuggestions(String label, bool expected) async {
        await scrollTo(tester, find.text(label));
        final field = find
            .ancestor(
              of: find.text(label),
              matching: find.byType(EditableStringList),
            )
            .first;
        expect(
          find.descendant(of: field, matching: find.text('Suggestions')),
          expected ? findsOneWidget : findsNothing,
          reason: expected
              ? '$label should offer suggestions'
              : '$label should not offer suggestions',
        );
      }

      await expectSuggestions('Interest tags', true);
      await expectSuggestions('Relevant A/L subjects', true);
      // Free-form sentences with no fixed vocabulary.
      await expectSuggestions("What you'd do", false);
      await expectSuggestions('Required skills', false);
      await expectSuggestions('Industry opportunities', false);
    });

    testWidgets('tapping an interest suggestion adds it', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await tapSuggestion(tester, 'technology');
      await tapSuggestion(tester, 'design');
      await save(tester);

      expect(service.lastCreated!.interestTags, ['technology', 'design']);
    });

    testWidgets('tapping an A/L subject suggestion adds it', (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await tapSuggestion(tester, 'Biology');
      await save(tester);

      expect(service.lastCreated!.alSubjects, ['Biology']);
    });

    testWidgets('an added suggestion is disabled and cannot be added twice',
        (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await tapSuggestion(tester, 'technology');

      // The chip stays on screen but is disabled, so a second tap is a no-op
      // rather than storing the tag twice.
      final chip = find.widgetWithText(ActionChip, 'technology');
      await scrollTo(tester, chip);
      expect(tester.widget<ActionChip>(chip).onPressed, isNull);

      await tester.tap(chip, warnIfMissed: false);
      await tester.pumpAndSettle();
      await save(tester);

      expect(service.lastCreated!.interestTags, ['technology']);
    });

    testWidgets('typing a value that is also a suggestion is not duplicated',
        (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await tapSuggestion(tester, 'technology');
      // Different casing, same tag: the shared duplicate check rejects it.
      await addToList(tester, 'Interest tags', 'Technology');
      await save(tester);

      expect(service.lastCreated!.interestTags, ['technology']);
    });

    testWidgets('free text still works for values outside the suggestions',
        (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      // "infrastructure" and "Statistics" appear on seeded careers but are in
      // neither suggestion list, so nothing already stored becomes
      // unreachable.
      await addToList(tester, 'Interest tags', 'infrastructure');
      await addToList(tester, 'Relevant A/L subjects', 'Statistics');
      await save(tester);

      expect(service.lastCreated!.interestTags, ['infrastructure']);
      expect(service.lastCreated!.alSubjects, ['Statistics']);
    });

    testWidgets('a suggested tag can be removed again with its x control',
        (tester) async {
      final service = FakeCareerService();
      await tester.pumpWidget(
        wrap(AdminCareerFormPage(token: 't', careerService: service)),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await tapSuggestion(tester, 'technology');
      await tapSuggestion(tester, 'design');

      await scrollTo(tester, find.byTooltip('Remove technology'));
      await tester.tap(find.byTooltip('Remove technology'));
      await tester.pumpAndSettle();
      await save(tester);

      expect(service.lastCreated!.interestTags, ['design']);
    });

    testWidgets('editing a career shows its stored tags as already added',
        (tester) async {
      final existing = careerFixture(
        id: 'id-se',
        title: 'Software Engineer',
      );
      await tester.pumpWidget(wrap(AdminCareerFormPage(
        token: 't',
        career: Career(
          id: existing.id,
          title: existing.title,
          category: existing.category,
          description: existing.description,
          salaryRange: existing.salaryRange,
          jobOutlook: existing.jobOutlook,
          whatYouDo: existing.whatYouDo,
          requiredSkills: existing.requiredSkills,
          recommendedStreams: existing.recommendedStreams,
          interestTags: const ['technology'],
        ),
        careerService: FakeCareerService(),
      )));
      await tester.pumpAndSettle();

      final chip = find.widgetWithText(ActionChip, 'technology');
      await scrollTo(tester, chip);
      expect(tester.widget<ActionChip>(chip).onPressed, isNull);

      // One that is not stored stays tappable.
      final other = find.widgetWithText(ActionChip, 'design');
      await scrollTo(tester, other);
      expect(tester.widget<ActionChip>(other).onPressed, isNotNull);
    });
  });
}
