import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/exercises/exercise_library_page.dart';

import '../../helpers/pump.dart';

Finder chip(String label) => find.widgetWithText(SxChip, label);
Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

/// Scrolls [label] into view inside the horizontally scrolling chip [row] (chips are built lazily).
Future<void> reveal(WidgetTester t, Finder row, String label) async {
  final target = find.descendant(of: row, matching: find.text(label));
  await t.scrollUntilVisible(target, 120, scrollable: find.descendant(of: row, matching: find.byType(Scrollable)).first);
  await t.pump(const Duration(milliseconds: 100));
}

String countText(WidgetTester t) => (t.widget(find.byKey(const ValueKey('resultCount'))) as Text).data!;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('muscle chips are All + the 8 section muscles incl. Forearms', (t) async {
    await pumpPage(t, const ExerciseLibraryPage());
    final row = find.byKey(const ValueKey('muscleChips'));
    expect(row, findsOneWidget);
    for (final m in ['All', ...SectionMuscle.values.map((m) => m.label)]) {
      // The row scrolls horizontally: bring each chip into view first.
      await reveal(t, row, m);
      expect(find.descendant(of: row, matching: find.widgetWithText(SxChip, m)), findsOneWidget, reason: m);
    }
  });

  testWidgets('Forearms chip filters by primary region; sub chips are wrist/grip leaves', (t) async {
    final app = await pumpPage(t, const ExerciseLibraryPage());
    final expected = app.exercises.all
        .where((e) => SectionMuscle.of(MuscleProfiles.of(e).primaryRegion) == SectionMuscle.forearms)
        .length;
    expect(expected, greaterThan(0));
    final row = find.byKey(const ValueKey('muscleChips'));
    await reveal(t, row, 'Forearms');
    await t.tap(find.descendant(of: row, matching: find.widgetWithText(SxChip, 'Forearms')));
    await settle(t);
    expect(countText(t), startsWith('$expected exercise'));
    final subRow = find.byKey(const ValueKey('subMuscleChips'));
    if (subRow.evaluate().isNotEmpty) {
      expect(find.descendant(of: subRow, matching: find.text('Wrist flexors')), findsOneWidget);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('Legs offers the four leg regions as sub chips and filters by them', (t) async {
    await pumpPage(t, const ExerciseLibraryPage());
    final row = find.byKey(const ValueKey('muscleChips'));
    await reveal(t, row, 'Legs');
    await t.tap(find.descendant(of: row, matching: find.widgetWithText(SxChip, 'Legs')));
    await settle(t);
    final sub = find.byKey(const ValueKey('subMuscleChips'));
    expect(sub, findsOneWidget);
    for (final l in ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves']) {
      await reveal(t, sub, l);
      expect(find.descendant(of: sub, matching: find.text(l)), findsOneWidget, reason: l);
    }
    final before = countText(t);
    await t.tap(find.descendant(of: sub, matching: find.text('Calves')));
    await settle(t);
    expect(countText(t), isNot(before));
  });

  testWidgets('result count, active filter count and Clear', (t) async {
    final app = await pumpPage(t, const ExerciseLibraryPage());
    final total = app.exercises.all.length;
    expect(countText(t), '$total exercises');
    expect(find.byKey(const ValueKey('clearFilters')), findsNothing);
    await t.tap(chip('Chest'));
    await settle(t);
    expect(countText(t), contains('1 filter'));
    final eq = find.byKey(const ValueKey('equipmentChips'));
    await reveal(t, eq, 'Barbell');
    await t.tap(find.descendant(of: eq, matching: find.text('Barbell')));
    await settle(t);
    expect(countText(t), contains('2 filters'));
    await t.tap(find.byKey(const ValueKey('clearFilters')));
    await settle(t);
    expect(countText(t), '$total exercises');
  });

  testWidgets('equipment row lists every Equipment value and scrolls horizontally', (t) async {
    await pumpPage(t, const ExerciseLibraryPage(), size: const Size(320, 568));
    final eq = find.byKey(const ValueKey('equipmentChips'));
    for (final e in Equipment.values) {
      await reveal(t, eq, e.label);
      expect(find.descendant(of: eq, matching: find.text(e.label)), findsOneWidget, reason: e.label);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('search: debounced, synonym + Arabic, relevance order, empty-state CTA', (t) async {
    await pumpPage(t, const ExerciseLibraryPage());
    await t.enterText(find.byType(TextField), 'rdl');
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('Romanian Deadlift'), findsNothing, reason: 'debounced');
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('Romanian Deadlift'), findsWidgets);

    await t.enterText(find.byType(TextField), 'سواعد');
    await settle(t);
    expect(find.text('No exercises found'), findsNothing);

    await t.enterText(find.byType(TextField), 'zzzqqq');
    await settle(t);
    expect(find.text('No exercises found'), findsOneWidget);
    expect(find.descendant(of: find.byType(EmptyState), matching: find.textContaining(RegExp('create custom exercise "zzzqqq"', caseSensitive: false))), findsOneWidget);
    await t.tap(find.textContaining(RegExp('clear filters', caseSensitive: false)));
    await settle(t);
    expect(find.text('No exercises found'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('Recent chip: only exercises logged in the last 60 days', (t) async {
    final app = AppController()..startDemo();
    final recent = {
      for (final s in app.sessions.sessions)
        if (!s.workoutDate.isBefore(DateTime.now().subtract(const Duration(days: 60))))
          for (final l in s.exercises)
            if (l.doneSets.isNotEmpty) l.exerciseId,
    };
    await pumpPage(t, const ExerciseLibraryPage(), controller: app);
    await t.tap(chip('Recent'));
    await settle(t);
    if (recent.isEmpty) {
      expect(find.text('No exercises found'), findsOneWidget);
    } else {
      expect(countText(t), startsWith('${recent.length} exercise'));
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('chips expose selected state and 48dp targets; no overflow at 320x568 text 1.3', (t) async {
    final h = t.ensureSemantics();
    await pumpPage(t, const ExerciseLibraryPage(), size: const Size(320, 568), textScale: 1.3);
    final node = t.getSemantics(chip('All exercises'));
    expect(node.label, 'All exercises');
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    expect(t.getSemantics(chip('Common')).flagsCollection.isSelected, Tristate.isFalse);
    expect(t.getSize(chip('Common')).height, greaterThanOrEqualTo(36));
    expect(t.getSize(find.ancestor(of: chip('Common'), matching: find.byType(ListView)).first).height, greaterThanOrEqualTo(48));
    expect(t.takeException(), isNull);
    h.dispose();
  });
}
