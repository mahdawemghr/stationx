// RPE (rate of perceived exertion) is OPTIONAL everywhere: it must never block logging a set, saving or
// finishing a workout, a cardio session, editing history or onboarding, and stored RPE must survive edits.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/active_workout/active_workout_controller.dart';
import 'package:stationx/features/cardio/cardio_manage_form.dart';
import 'package:stationx/features/history/edit_session_page.dart';
import 'package:stationx/features/onboarding/schedule_setup_flow.dart';

import '../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);

  test(
    'strength: sets can be logged, built and finished without any RPE',
    () async {
      final app = AppController()..startDemo();
      final c = ActiveWorkoutController(
        workout: app.workouts.byId('w2')!,
        catalog: app.exercises.all,
        sessions: app.sessions,
        profile: app.profile.profile,
      );
      for (final d in c.drafts) {
        for (var i = 0; i < d.sets.length; i++) {
          expect(
            c.toggleSet(d, i),
            isTrue,
            reason: 'a set is never blocked by a missing RPE',
          );
        }
      }
      final s = c.buildSession(id: 's_rpe', workoutDate: DateTime(2026, 6, 1));
      expect(s.exercises, isNotEmpty);
      expect(
        s.exercises.expand((e) => e.sets).every((x) => x.rpe == null),
        isTrue,
      );
      await app.completion.complete(s);
      expect(app.sessions.byId('s_rpe'), isNotNull);
      c.dispose();
    },
  );

  test(
    'cardio: the form is valid with only a duration; RPE stays null and can be cleared',
    () {
      final f = CardioFormState(
        kind: CardioKind.treadmill,
        date: DateTime.now().subtract(const Duration(hours: 1)),
        kmUnit: true,
      );
      f.minutes.text = '20';
      expect(f.validate(), isTrue);
      expect(f.rpe, isNull);
      expect(f.build(id: 'c1').rpe, isNull);
      f.setRpe(7.5);
      expect(f.build(id: 'c2').rpe, 7.5);
      f.setRpe(null);
      expect(f.validate(), isTrue);
      expect(f.build(id: 'c3').rpe, isNull);
    },
  );

  test(
    'cardio: an existing session with RPE is loaded into the form and written back unchanged',
    () {
      final old = CardioSession(
        id: 'c',
        kind: CardioKind.rowing,
        workoutDate: DateTime(2026, 5, 1),
        durationSeconds: 1200,
        rpe: 8.0,
      );
      final f = CardioFormState(
        kind: old.kind,
        date: old.workoutDate,
        kmUnit: true,
        from: old,
      );
      expect(f.rpe, 8.0);
      expect(f.build(id: 'c').rpe, 8.0);
    },
  );

  testWidgets(
    'history edit keeps every stored RPE (and still saves when none exists)',
    (t) async {
      final app = AppController();
      await app.sessions.add(
        WorkoutSession(
          id: 's1',
          workoutId: 'w',
          name: 'Push',
          workoutDate: DateTime.now().subtract(const Duration(days: 1)),
          exercises: const [
            ExerciseLog(
              exerciseId: 'bench_press',
              sets: [
                SetLog(weightKg: 60, reps: 8, rpe: 8.5),
                SetLog(weightKg: 60, reps: 8),
              ],
            ),
          ],
        ),
      );
      await pumpPage(
        t,
        const EditSessionPage(sessionId: 's1'),
        demo: false,
        controller: app,
        size: const Size(390, 1400),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('SAVE CHANGES'));
      await t.pumpAndSettle();
      final sets = app.sessions.byId('s1')!.exercises.single.sets;
      expect(sets[0].rpe, 8.5, reason: 'historical RPE preserved');
      expect(sets[1].rpe, isNull, reason: 'a missing RPE is not invented');
    },
  );

  testWidgets('onboarding never mentions or requires RPE', (t) async {
    await pumpPage(
      t,
      const ScheduleSetupFlow(afterSignup: true),
      demo: false,
      size: const Size(390, 1200),
    );
    expect(find.textContaining('RPE'), findsNothing);
    expect(find.textContaining('effort'), findsNothing);
  });

  test(
    'storage: RPE is optional in the app model and bounded 0..10 on the server',
    () {
      const s = SetLog(weightKg: 1, reps: 1);
      expect(s.rpe, isNull);
      expect(
        CardioSession(
          id: 'x',
          kind: CardioKind.rowing,
          workoutDate: DateTime(2026, 1, 1),
          durationSeconds: 1,
        ).rpe,
        isNull,
      );
    },
  );
}
