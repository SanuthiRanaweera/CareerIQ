import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/features/career/screens/career_pathway_page.dart';
import 'package:flutter_app/models/career.dart';

import 'career_test_fakes.dart';

// Tests for screen 22 - Career pathway.
//
// The point of this screen is order: the steps must read as a route from
// school to a senior role, numbered and in sequence.

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  /// Scrolls a step into view; the timeline is a lazy ListView, so later
  /// steps are not built until reached.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200);
    await tester.pumpAndSettle();
  }

  const sixStepPathway = [
    CareerPathwayStep(
      order: 1,
      stage: 'A/L Stream',
      title: 'Technology or Mathematics stream',
      description: 'Take Combined Mathematics, Physics or ICT at A/L.',
      durationLabel: '2 years',
    ),
    CareerPathwayStep(
      order: 2,
      stage: 'Degree',
      title: 'BSc in Software Engineering',
      description:
          'State universities such as Moratuwa, or a private institute.',
      durationLabel: '3-4 years',
    ),
    CareerPathwayStep(
      order: 3,
      stage: 'Skills',
      title: 'Build practical coding skills',
      durationLabel: 'Ongoing',
    ),
    CareerPathwayStep(
      order: 4,
      stage: 'Internship',
      title: 'Software engineering intern',
      durationLabel: '6 months',
    ),
    CareerPathwayStep(
      order: 5,
      stage: 'Entry Job',
      title: 'Associate Software Engineer',
      durationLabel: '1-2 years',
    ),
    CareerPathwayStep(
      order: 6,
      stage: 'Senior Role',
      title: 'Senior Engineer or Tech Lead',
      durationLabel: '5+ years',
    ),
  ];

  group('CareerPathwayPage', () {
    testWidgets('shows the career name and the number of steps', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CareerPathwayPage(
            career: careerFixture(
              title: 'Software Engineer',
              pathway: sixStepPathway,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Career pathway'), findsOneWidget);
      expect(find.text('YOUR PATH TO'), findsOneWidget);
      expect(find.text('Software Engineer'), findsOneWidget);
      expect(find.text('6 steps from A/L to a senior role'), findsOneWidget);
    });

    testWidgets('numbers each step and shows its stage, title and duration', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(CareerPathwayPage(career: careerFixture(pathway: sixStepPathway))),
      );
      await tester.pumpAndSettle();

      // First step, visible without scrolling.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('A/L Stream'), findsOneWidget);
      expect(find.text('Technology or Mathematics stream'), findsOneWidget);
      expect(find.text('2 years'), findsOneWidget);
      expect(
        find.text('Take Combined Mathematics, Physics or ICT at A/L.'),
        findsOneWidget,
      );

      // Last step, after scrolling the timeline.
      await scrollTo(tester, find.text('Senior Role'));
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Senior Engineer or Tech Lead'), findsOneWidget);
      expect(find.text('5+ years'), findsOneWidget);
    });

    testWidgets('renders steps in pathway order even when supplied jumbled', (
      tester,
    ) async {
      // The backend sorts on save, but the screen must not depend on that.
      await tester.pumpWidget(
        wrap(
          CareerPathwayPage(
            career: careerFixture(
              pathway: const [
                CareerPathwayStep(
                  order: 3,
                  stage: 'Skills',
                  title: 'Third step',
                ),
                CareerPathwayStep(
                  order: 1,
                  stage: 'A/L Stream',
                  title: 'First step',
                ),
                CareerPathwayStep(
                  order: 2,
                  stage: 'Degree',
                  title: 'Second step',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstY = tester.getTopLeft(find.text('First step')).dy;
      final secondY = tester.getTopLeft(find.text('Second step')).dy;
      final thirdY = tester.getTopLeft(find.text('Third step')).dy;

      expect(firstY, lessThan(secondY));
      expect(secondY, lessThan(thirdY));
    });

    testWidgets('numbers steps by position, not by their stored order value', (
      tester,
    ) async {
      // A pathway whose order values start at 5 should still read 1, 2, 3.
      await tester.pumpWidget(
        wrap(
          CareerPathwayPage(
            career: careerFixture(
              pathway: const [
                CareerPathwayStep(order: 5, stage: 'Degree', title: 'Step A'),
                CareerPathwayStep(
                  order: 9,
                  stage: 'Entry Job',
                  title: 'Step B',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('5'), findsNothing);
      expect(find.text('9'), findsNothing);
    });

    testWidgets('draws a connector between steps but not after the last', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CareerPathwayPage(
            career: careerFixture(
              pathway: const [
                CareerPathwayStep(order: 1, stage: 'A/L Stream', title: 'One'),
                CareerPathwayStep(order: 2, stage: 'Degree', title: 'Two'),
                CareerPathwayStep(order: 3, stage: 'Skills', title: 'Three'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Three steps, two connectors: the line stops at the end of the path.
      expect(find.byType(VerticalDivider), findsNWidgets(2));
    });

    testWidgets('uses singular wording for a one-step pathway', (tester) async {
      await tester.pumpWidget(
        wrap(
          CareerPathwayPage(
            career: careerFixture(
              pathway: const [
                CareerPathwayStep(
                  order: 1,
                  stage: 'Degree',
                  title: 'Only step',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 step from A/L to a senior role'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNothing);
    });

    testWidgets('omits the duration when a step has none', (tester) async {
      await tester.pumpWidget(
        wrap(
          CareerPathwayPage(
            career: careerFixture(
              pathway: const [
                CareerPathwayStep(
                  order: 1,
                  stage: 'Skills',
                  title: 'Keep learning',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keep learning'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsNothing);
    });

    testWidgets('shows an empty state when no pathway has been added', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(CareerPathwayPage(career: careerFixture(pathway: const []))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pathway coming soon'), findsOneWidget);
      expect(
        find.text(
          'The step-by-step pathway for this career has not been added yet.',
        ),
        findsOneWidget,
      );
      // Nothing to retry: the data simply is not there yet.
      expect(find.text('Refresh'), findsNothing);
    });
  });
}
