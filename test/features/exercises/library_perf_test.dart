import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/exercises/exercise_library_page.dart';
import 'package:stationx/features/exercises/exercise_history_page.dart';

import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/seed/seed_data.dart';

import '../../helpers/pump.dart';

int prs(WidgetTester t) => (t.state(find.byType(ExerciseLibraryPage)) as dynamic).prComputations as int;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('400-exercise catalog + many sessions: PRs <= visible rows, filters never recompute PRs', (t) async {
    final base = SeedData.fresh();
    final now = DateTime.now();
    final exercises = [
      for (var i = 0; i < 400; i++)
        Exercise(
          id: 'syn_$i',
          name: 'Synthetic Lift ${i.toString().padLeft(3, '0')}',
          primaryMuscle: MuscleGroup.values[i % MuscleGroup.values.length],
          equipment: Equipment.values[i % Equipment.values.length],
          isCustom: true,
        ),
    ];
    final sessions = [
      for (var i = 0; i < 600; i++)
        WorkoutSession(
          id: 'syn_s$i',
          workoutId: base.workouts.first.id,
          name: 'S$i',
          workoutDate: now.subtract(Duration(days: i)),
          exercises: [
            for (var k = 0; k < 4; k++)
              ExerciseLog(exerciseId: 'syn_${(i * 4 + k) % 400}', sets: [SetLog(weightKg: 40.0 + i % 30, reps: 8)]),
          ],
        ),
    ];
    final app = AppController(
      store: MemoryStore(SeedData(exercises: exercises, workouts: base.workouts, rotation: base.rotation, sessions: sessions, cardio: base.cardio, goals: base.goals)),
    );
    await pumpPage(t, const ExerciseLibraryPage(), controller: app, size: const Size(390, 844));
    await t.pump(const Duration(milliseconds: 500));
    expect(app.exercises.all.length, 400);
    final visible = find.byType(SxCard).evaluate().length;
    expect(visible, greaterThan(0));
    final first = prs(t);
    expect(first, lessThanOrEqualTo(visible + 6), reason: 'PRs only for built (visible + cache extent) rows');
    expect(first, lessThan(100));

    // Filter / mode / equipment changes reuse cached PRs for rows already computed.
    await t.tap(find.widgetWithText(SxChip, 'Recent'));
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.widgetWithText(SxChip, 'All exercises'));
    await t.pump(const Duration(milliseconds: 500));
    expect(prs(t), first, reason: 'returning to the same rows recomputes nothing');
    await t.enterText(find.byType(TextField), 'lift 00');
    await t.pump(const Duration(milliseconds: 300));
    final afterSearch = prs(t);
    expect(afterSearch - first, lessThanOrEqualTo(visible + 6));
    await t.enterText(find.byType(TextField), '');
    await t.pump(const Duration(milliseconds: 300));
    expect(prs(t), lessThanOrEqualTo(afterSearch + 2), reason: 'back to the original rows: cached');
  });

  testWidgets('library: PRs are computed lazily per visible row and memoized', (t) async {
    final app = await pumpPage(t, const ExerciseLibraryPage());
    await t.pump(const Duration(milliseconds: 500));
    final total = app.exercises.all.length;
    expect(total, greaterThan(150));
    expect(app.sessions.sessions, isNotEmpty);
    final first = prs(t);
    expect(first, lessThan(total ~/ 3), reason: 'only visible rows may compute a PR');
    // Unrelated rebuilds (typing a filter that keeps the same rows, re-pumping) do not recompute.
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.widgetWithText(SxChip, 'All exercises'));
    await t.pump(const Duration(milliseconds: 500));
    expect(prs(t), first);
    // Real data change invalidates the cache.
    await app.sessions.update(app.sessions.sessions.first);
    await t.pump(const Duration(milliseconds: 500));
    expect(prs(t), greaterThanOrEqualTo(first));
  });

  test('0 estimate (more than 12 reps) is "no estimate", never a real e1RM', () {
    expect(estimateOneRepMax(100, 20), 0);
    expect(estimateOneRepMax(100, 5), greaterThan(100));
  });

  testWidgets('history e1RM chart ignores sessions without a reliable estimate', (t) async {
    final app = await pumpPage(t, const ExerciseHistoryPage(exerciseId: 'bench_press'));
    await t.tap(find.widgetWithText(SxChip, 'Est. 1RM'));
    await t.pump(const Duration(milliseconds: 500));
    expect(t.takeException(), isNull);
    expect(find.textContaining('NaN'), findsNothing);
    expect(find.textContaining('-100'), findsNothing);
    expect(app, isNotNull);
  });
}
