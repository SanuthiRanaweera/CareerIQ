import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/features/career/screens/career_details_page.dart';
import 'package:flutter_app/features/career/screens/saved_careers_page.dart';
import 'package:flutter_app/models/career.dart';
import 'package:flutter_app/models/saved_career.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/saved_career_service.dart';

import 'career_test_fakes.dart';

/// In-memory stand-in for [SavedCareerService].
class FakeSavedCareerService implements SavedCareerService {
  FakeSavedCareerService({List<SavedCareer>? saved, this.error})
    : saved = saved ?? [];

  List<SavedCareer> saved;
  Object? error;

  String? lastPriorityFilter;
  String? lastSavedCareerId;
  String? lastUpdatedId;
  String? lastUpdatedNote;
  String? lastUpdatedPriority;
  String? lastDeletedId;

  Future<T> _respond<T>(T Function() action) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (error != null) throw error!;
    return action();
  }

  @override
  Future<List<SavedCareer>> getSavedCareers(
    String token, {
    String priority = '',
  }) {
    lastPriorityFilter = priority;
    return _respond(
      () => saved
          .where((item) => priority.isEmpty || item.priority == priority)
          .toList(),
    );
  }

  @override
  Future<SavedCareer> saveCareer(
    String token,
    String careerId, {
    String note = '',
    String priority = 'Medium',
  }) {
    lastSavedCareerId = careerId;
    return _respond(() {
      final entry = SavedCareer(
        id: 'saved-$careerId',
        career: careerFixture(id: careerId),
        note: note,
        priority: priority,
      );
      saved = [...saved, entry];
      return entry;
    });
  }

  @override
  Future<SavedCareer> updateSavedCareer(
    String token,
    String id, {
    required String note,
    required String priority,
  }) {
    lastUpdatedId = id;
    lastUpdatedNote = note;
    lastUpdatedPriority = priority;
    return _respond(() {
      final old = saved.firstWhere((item) => item.id == id);
      final updated = SavedCareer(
        id: id,
        career: old.career,
        note: note,
        priority: priority,
      );
      saved = [for (final item in saved) item.id == id ? updated : item];
      return updated;
    });
  }

  @override
  Future<void> deleteSavedCareer(String token, String id) {
    lastDeletedId = id;
    return _respond(() {
      saved = saved.where((item) => item.id != id).toList();
    });
  }
}

SavedCareer savedFixture(
  String id,
  String title, {
  String priority = 'Medium',
  String note = '',
}) => SavedCareer(
  id: id,
  career: careerFixture(id: 'career-$id', title: title),
  priority: priority,
  note: note,
);

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  Widget listPage(
    FakeSavedCareerService service, {
    FutureOr<void> Function(Career)? onCareerSelected,
  }) => wrap(
    SavedCareersPage(
      token: 't',
      savedCareerService: service,
      onCareerSelected: onCareerSelected,
    ),
  );

  group('SavedCareersPage', () {
    testWidgets('lists the saved careers with priority and note', (
      tester,
    ) async {
      final service = FakeSavedCareerService(
        saved: [
          savedFixture(
            '1',
            'Data Scientist',
            priority: 'High',
            note: 'Love maths',
          ),
          savedFixture('2', 'Civil Engineer', priority: 'Low'),
        ],
      );
      await tester.pumpWidget(listPage(service));
      await tester.pumpAndSettle();

      expect(find.text('Data Scientist'), findsOneWidget);
      expect(find.text('Civil Engineer'), findsOneWidget);
      expect(find.text('High priority'), findsWidgets);
      expect(find.text('Love maths'), findsOneWidget);
    });

    testWidgets('shows a helpful empty state', (tester) async {
      await tester.pumpWidget(listPage(FakeSavedCareerService()));
      await tester.pumpAndSettle();

      expect(find.text('No saved careers yet'), findsOneWidget);
    });

    testWidgets('shows the error and offers a retry', (tester) async {
      final service = FakeSavedCareerService(
        error: const ApiException('Server is down'),
      );
      await tester.pumpWidget(listPage(service));
      await tester.pumpAndSettle();

      expect(find.text('Server is down'), findsOneWidget);

      service.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Server is down'), findsNothing);
    });

    testWidgets('filters by priority through the backend', (tester) async {
      final service = FakeSavedCareerService(
        saved: [
          savedFixture('1', 'Data Scientist', priority: 'High'),
          savedFixture('2', 'Civil Engineer', priority: 'Low'),
        ],
      );
      await tester.pumpWidget(listPage(service));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Low priority'));
      await tester.pumpAndSettle();

      expect(service.lastPriorityFilter, 'Low');
      expect(find.text('Civil Engineer'), findsOneWidget);
      expect(find.text('Data Scientist'), findsNothing);
    });

    testWidgets('opening a career reports it and reloads afterwards', (
      tester,
    ) async {
      final service = FakeSavedCareerService(
        saved: [savedFixture('1', 'Data Scientist')],
      );
      Career? opened;
      await tester.pumpWidget(
        listPage(
          service,
          onCareerSelected: (career) {
            opened = career;
            // Simulates the student removing it on the details screen.
            service.saved = [];
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Data Scientist'));
      await tester.pumpAndSettle();

      expect(opened?.title, 'Data Scientist');
      expect(find.text('No saved careers yet'), findsOneWidget);
    });

    testWidgets('editing saves the new note and priority', (tester) async {
      final service = FakeSavedCareerService(
        saved: [savedFixture('1', 'Data Scientist', note: 'old')],
      );
      await tester.pumpWidget(listPage(service));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byTooltip('Edit note and priority for Data Scientist'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'High'));
      await tester.enterText(find.byType(TextField), 'new note');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(service.lastUpdatedId, '1');
      expect(service.lastUpdatedNote, 'new note');
      expect(service.lastUpdatedPriority, 'High');
      expect(find.text('new note'), findsOneWidget);
      expect(find.text('High priority'), findsWidgets);
    });

    testWidgets('delete asks first and cancelling keeps the entry', (
      tester,
    ) async {
      final service = FakeSavedCareerService(
        saved: [savedFixture('1', 'Data Scientist')],
      );
      await tester.pumpWidget(listPage(service));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Remove Data Scientist from shortlist'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from shortlist?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(service.lastDeletedId, isNull);
      expect(find.text('Data Scientist'), findsOneWidget);
    });

    testWidgets('confirming delete removes the entry', (tester) async {
      final service = FakeSavedCareerService(
        saved: [savedFixture('1', 'Data Scientist')],
      );
      await tester.pumpWidget(listPage(service));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Remove Data Scientist from shortlist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(service.lastDeletedId, '1');
      expect(find.text('No saved careers yet'), findsOneWidget);
    });
  });

  group('CareerDetailsPage bookmark', () {
    Widget detailsWith(Career career, FakeSavedCareerService? saved) => wrap(
      CareerDetailsPage(
        token: 't',
        careerId: career.id,
        careerService: FakeCareerService(careers: [career]),
        savedCareerService: saved,
      ),
    );

    testWidgets('is hidden when no shortlist service is supplied', (
      tester,
    ) async {
      await tester.pumpWidget(detailsWith(careerFixture(id: 'c1'), null));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Save to shortlist'), findsNothing);
    });

    testWidgets('saves an unsaved career and then removes it again', (
      tester,
    ) async {
      final service = FakeSavedCareerService();
      await tester.pumpWidget(detailsWith(careerFixture(id: 'c1'), service));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Save to shortlist'));
      await tester.pumpAndSettle();

      expect(service.lastSavedCareerId, 'c1');
      expect(find.byTooltip('Remove from shortlist'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove from shortlist'));
      await tester.pumpAndSettle();

      expect(service.lastDeletedId, 'saved-c1');
      expect(find.byTooltip('Save to shortlist'), findsOneWidget);
    });

    testWidgets('shows as saved when the career is already on the shortlist', (
      tester,
    ) async {
      final service = FakeSavedCareerService(
        saved: [
          SavedCareer(
            id: 's1',
            career: careerFixture(id: 'c1'),
          ),
        ],
      );
      await tester.pumpWidget(detailsWith(careerFixture(id: 'c1'), service));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Remove from shortlist'), findsOneWidget);
    });

    testWidgets('reports a failed save without changing the bookmark', (
      tester,
    ) async {
      final service = FakeSavedCareerService();
      await tester.pumpWidget(detailsWith(careerFixture(id: 'c1'), service));
      await tester.pumpAndSettle();

      service.error = const ApiException(
        'This career is already on your shortlist',
      );
      await tester.tap(find.byTooltip('Save to shortlist'));
      await tester.pumpAndSettle();

      expect(
        find.text('This career is already on your shortlist'),
        findsOneWidget,
      );
      expect(find.byTooltip('Save to shortlist'), findsOneWidget);
    });
  });
}
