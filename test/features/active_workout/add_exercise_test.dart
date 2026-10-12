import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/features/active_workout/active_workout_controller.dart';
import 'package:stationx/features/workouts/swap_exercise_sheet.dart';

import '../../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);

  test(
    'addExercise adds a block, saves it in the draft, and refuses duplicates',
    () async {
      final app = AppController()..startDemo();
      final c = ActiveWorkoutController(
        workout: app.workouts.byId('w2')!,
        catalog: app.exercises.all,
        sessions: app.sessions,
        profile: app.profile.profile,
        draftStore: app.workoutDraft,
      );
      final inWorkout = c.drafts.map((d) => d.exercise.id).toSet();
      final extra = app.exercises.all.firstWhere(
        (e) => !inWorkout.contains(e.id),
      );
      final before = c.drafts.length;
      expect(c.addExercise(extra, app.sessions), isTrue);
      expect(c.drafts.length, before + 1);
      expect(
        c.drafts.where((d) => d.exercise.id == extra.id).single.expanded,
        isTrue,
      );
      expect(c.addExercise(extra, app.sessions), isFalse);
      expect(c.drafts.length, before + 1);

      await c.flushDraft();
      expect(
        app.workoutDraft.current!.exercises.map((e) => e.exerciseId),
        contains(extra.id),
      );
      // The added exercise is part of the saved session once a set is done.
      final d = c.drafts.firstWhere((x) => x.exercise.id == extra.id);
      c.toggleSet(d, 0);
      final s = c.buildSession(id: 'x', workoutDate: DateTime(2026, 1, 1));
      expect(s.exercises.map((e) => e.exerciseId), contains(extra.id));
      c.dispose();
    },
  );

  testWidgets('swap sheet: tapping the target chip lists every exercise', (
    t,
  ) async {
    final app = AppController()..startDemo();
    final catalog = app.exercises.all;
    final current = app.exercises.byId('lat_pulldown')!;
    await pumpPage(
      t,
      Scaffold(
        body: SwapExerciseBody(
          current: current,
          catalog: catalog,
          sets: 3,
          repRange: '8-12',
          onClose: () {},
          onReplace: (_) {},
        ),
      ),
      controller: app,
    );
    String count() =>
        (find
                    .byWidgetPredicate(
                      (w) => w is Text && (w.data ?? '').endsWith(' available'),
                    )
                    .evaluate()
                    .single
                    .widget
                as Text)
            .data!;
    final sameOnly = int.parse(count().split(' ').first);
    await t.tap(find.textContaining('Target:').first);
    await t.pump();
    final all = int.parse(count().split(' ').first);
    expect(all, greaterThan(sameOnly));
    expect(all, catalog.length - 1);
    expect(find.text('SEARCH ALL EXERCISES'), findsOneWidget);
    // Tapping again goes back to the filtered list.
    await t.tap(find.textContaining('Target:').first);
    await t.pump();
    expect(int.parse(count().split(' ').first), sameOnly);
  });
}
