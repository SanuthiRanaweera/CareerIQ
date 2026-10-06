import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/features/career/screens/career_recommendation_form_page.dart';
import 'package:flutter_app/models/recommendation_input.dart';

// Tests for the career recommendation input form.
//
// The form's job is to collect five answers and refuse to submit until the
// three that matter most are present, so these tests concentrate on
// validation and on what is handed to the caller.

void main() {
  Widget wrap(void Function(RecommendationAnswers) onSubmit) =>
      MaterialApp(home: CareerRecommendationFormPage(onSubmit: onSubmit));

  /// Scrolls the form back to the top.
  ///
  /// `scrollUntilVisible` only searches in one direction, so a target above
  /// the current position would never be found. Resetting first makes every
  /// lookup a predictable downward scan.
  Future<void> scrollToTop(WidgetTester tester) async {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
    await tester.pumpAndSettle();
  }

  /// Brings a widget into view. The form is a lazy ListView and most sections
  /// start below the fold on a phone-sized screen.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      return;
    }
    await scrollToTop(tester);
    await tester.scrollUntilVisible(finder, 150);
    await tester.pumpAndSettle();
  }

  /// Scrolls to an option chip and taps it.
  Future<void> choose(WidgetTester tester, String option) async {
    await scrollTo(tester, find.text(option));
    await tester.tap(find.text(option));
    await tester.pumpAndSettle();
  }

  /// Fills in the three required answers.
  Future<void> completeRequired(WidgetTester tester) async {
    await choose(tester, 'Science');
    await choose(tester, 'healthcare');
    await choose(tester, 'Social');
  }

  Future<void> submit(WidgetTester tester) async {
    await scrollTo(tester, find.text('See my matches'));
    await tester.tap(find.text('See my matches'));
    await tester.pumpAndSettle();
  }

  group('CareerRecommendationFormPage layout', () {
    testWidgets('shows all five questions', (tester) async {
      await tester.pumpWidget(wrap((_) {}));
      await tester.pumpAndSettle();

      expect(find.text('Tell us about you'), findsOneWidget);
      expect(find.text('Your A/L stream'), findsOneWidget);
      await scrollTo(tester, find.text('Your A/L subjects'));
      await scrollTo(tester, find.text('What interests you'));
      await scrollTo(tester, find.text('How you work best'));
      await scrollTo(tester, find.text('Preferred work style'));
      await scrollTo(tester, find.text('See my matches'));
    });

    testWidgets('marks exactly the three required questions', (tester) async {
      await tester.pumpWidget(wrap((_) {}));
      await tester.pumpAndSettle();

      /// Looks for a "Required" badge inside the card belonging to one
      /// section, rather than anywhere on the page.
      Future<void> expectRequired(String sectionTitle, bool required) async {
        await scrollTo(tester, find.text(sectionTitle));
        final card = find
            .ancestor(
              of: find.text(sectionTitle),
              matching: find.byType(Card),
            )
            .first;
        expect(
          find.descendant(of: card, matching: find.text('Required')),
          required ? findsOneWidget : findsNothing,
          reason: '$sectionTitle should '
              '${required ? 'be' : 'not be'} marked required',
        );
      }

      await expectRequired('Your A/L stream', true);
      await expectRequired('What interests you', true);
      await expectRequired('How you work best', true);
      await expectRequired('Your A/L subjects', false);
      await expectRequired('Preferred work style', false);
    });

    testWidgets('offers the A/L streams from the shared option list',
        (tester) async {
      await tester.pumpWidget(wrap((_) {}));
      await tester.pumpAndSettle();

      for (final stream in alStreams) {
        expect(find.widgetWithText(ChoiceChip, stream), findsOneWidget);
      }
    });
  });

  group('CareerRecommendationFormPage validation', () {
    testWidgets('shows no errors before the first submit', (tester) async {
      await tester.pumpWidget(wrap((_) {}));
      await tester.pumpAndSettle();

      expect(find.text('Please select your A/L stream'), findsNothing);
      expect(find.text('Please choose at least one interest'), findsNothing);
    });

    testWidgets('blocks submission and names every missing answer',
        (tester) async {
      var submitted = false;
      await tester.pumpWidget(wrap((_) => submitted = true));
      await tester.pumpAndSettle();

      await submit(tester);

      expect(submitted, isFalse);
      expect(
        find.text('Please complete: A/L stream, interests, personality'),
        findsOneWidget,
      );
    });

    testWidgets('shows an inline message under each incomplete question',
        (tester) async {
      await tester.pumpWidget(wrap((_) {}));
      await tester.pumpAndSettle();

      await submit(tester);

      await scrollTo(tester, find.text('Please select your A/L stream'));
      expect(find.text('Please select your A/L stream'), findsOneWidget);
      await scrollTo(tester, find.text('Please choose at least one interest'));
      expect(find.text('Please choose at least one interest'), findsOneWidget);
      await scrollTo(
        tester,
        find.text('Please select the option that describes you best'),
      );
      expect(
        find.text('Please select the option that describes you best'),
        findsOneWidget,
      );
    });

    testWidgets('an error clears as soon as that question is answered',
        (tester) async {
      await tester.pumpWidget(wrap((_) {}));
      await tester.pumpAndSettle();

      await submit(tester);
      await scrollTo(tester, find.text('Please select your A/L stream'));
      expect(find.text('Please select your A/L stream'), findsOneWidget);

      await choose(tester, 'Science');

      expect(find.text('Please select your A/L stream'), findsNothing);
    });

    testWidgets('does not require subjects or work style', (tester) async {
      RecommendationAnswers? answers;
      await tester.pumpWidget(wrap((a) => answers = a));
      await tester.pumpAndSettle();

      await completeRequired(tester);
      await submit(tester);

      expect(answers, isNotNull);
      expect(answers!.subjects, isEmpty);
      expect(answers!.workStyle, isEmpty);
      // Three of five components answered, matching the backend's count.
      expect(answers!.answeredCount, 3);
    });
  });

  group('CareerRecommendationFormPage answers', () {
    testWidgets('hands over every selected answer', (tester) async {
      RecommendationAnswers? answers;
      await tester.pumpWidget(wrap((a) => answers = a));
      await tester.pumpAndSettle();

      await completeRequired(tester);
      await choose(tester, 'Biology');
      await choose(tester, 'Team-based');
      await submit(tester);

      expect(answers!.stream, 'Science');
      expect(answers!.interests, ['healthcare']);
      expect(answers!.personalityType, 'Social');
      expect(answers!.subjects, ['Biology']);
      expect(answers!.workStyle, 'Team-based');
      expect(answers!.answeredCount, 5);
      expect(answers!.summary, 'Science stream, Social, Team-based');
    });

    testWidgets('collects several interests', (tester) async {
      RecommendationAnswers? answers;
      await tester.pumpWidget(wrap((a) => answers = a));
      await tester.pumpAndSettle();

      await choose(tester, 'Science');
      await choose(tester, 'Social');
      await choose(tester, 'healthcare');
      await choose(tester, 'research');
      await submit(tester);

      expect(answers!.interests, containsAll(['healthcare', 'research']));
      expect(answers!.interests.length, 2);
    });

    testWidgets('tapping a selected interest again removes it',
        (tester) async {
      RecommendationAnswers? answers;
      await tester.pumpWidget(wrap((a) => answers = a));
      await tester.pumpAndSettle();

      await choose(tester, 'Science');
      await choose(tester, 'Social');
      await choose(tester, 'healthcare');
      await choose(tester, 'research');
      // Deselect the first one.
      await choose(tester, 'healthcare');
      await submit(tester);

      expect(answers!.interests, ['research']);
    });

    testWidgets('changing a single-choice answer replaces it', (tester) async {
      RecommendationAnswers? answers;
      await tester.pumpWidget(wrap((a) => answers = a));
      await tester.pumpAndSettle();

      await choose(tester, 'Science');
      await choose(tester, 'Commerce');
      await choose(tester, 'business');
      await choose(tester, 'Organized');
      await submit(tester);

      expect(answers!.stream, 'Commerce');
    });

    testWidgets('an optional single choice can be cleared by tapping it again',
        (tester) async {
      RecommendationAnswers? answers;
      await tester.pumpWidget(wrap((a) => answers = a));
      await tester.pumpAndSettle();

      await completeRequired(tester);
      await choose(tester, 'Remote');
      await choose(tester, 'Remote');
      await submit(tester);

      // Work style is optional, so undoing the choice must be possible.
      expect(answers!.workStyle, isEmpty);
      expect(answers!.answeredCount, 3);
    });
  });
}
