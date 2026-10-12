// The saved program is generated ONCE (onboarding or an explicit regeneration) and then only changes
// when the user edits it. Generation, weekly scheduling and rotation are separate concepts.
// Runs against the in-memory Supabase (no network).

import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/remote/remote_exception.dart';
import 'package:stationx/domain/domain.dart';

import '../helpers/online_fakes.dart';

const offline = RemoteException(RemoteFailure.offline);

/// Saves the "Push / Pull / Legs" preset exactly like the onboarding flow does.
Future<List<String>> saveOnboardingProgram(
  OnlineRig r, {
  String stamp = 'one',
  String presetId = 'ppl',
  Set<Equipment>? equipment,
}) async {
  final preset = SplitCatalog.presets.firstWhere((p) => p.id == presetId);
  final days = ProgramEquipmentFit.fit(
    preset.days,
    r.app.exercises.all,
    equipment,
  );
  final res = await ScheduleBuilder.save(
    days,
    workouts: r.app.workouts,
    sessions: r.app.sessions,
    catalog: r.app.exercises.all,
    stamp: stamp,
  );
  return res.workoutIds;
}

/// Every workout as (id, name, [exerciseId sets repMin repMax ...]) in rotation order, plus the rotation list.
List<String> snapshot(AppController app) => [
  for (final id in app.workouts.rotation.workoutIds)
    '$id|${app.workouts.byId(id)!.name}|${[for (final e in app.workouts.byId(id)!.exercises) '${e.exerciseId}:${e.sets}:${e.repMin}-${e.repMax}'].join(',')}',
];

WorkoutSession done(String workoutId, DateTime day, {String? id}) =>
    WorkoutSession(
      id: id ?? 's_${day.toIso8601String()}',
      workoutId: workoutId,
      name: 'x',
      workoutDate: day,
      durationSeconds: 1800,
      exercises: const [
        ExerciseLog(
          exerciseId: 'bench_press',
          sets: [SetLog(weightKg: 60, reps: 8)],
        ),
      ],
    );

void main() {
  group('the saved program does not change on its own', () {
    test(
      'login, restart, refresh and a second device all see exactly the saved program',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        await saveOnboardingProgram(r);
        final saved = snapshot(r.app);
        expect(saved, hasLength(3));

        await r.app.refresh(force: true);
        expect(snapshot(r.app), saved, reason: 'data refresh');

        await r.app.signOut();
        await r.app.signInAccount('sam_1', 'Passw0rdX');
        expect(snapshot(r.app), saved, reason: 'log out and back in');

        final restarted = await r.restart();
        expect(snapshot(restarted), saved, reason: 'app restart');

        // A second device is another controller over the same server data.
        final other = OnlineRig.sharing(r);
        await other.app.signInAccount('sam_1', 'Passw0rdX');
        expect(snapshot(other.app), saved, reason: 'second device');
        expect(
          r.remote.calls.where((c) => c == 'rpc:sx_init_account'),
          hasLength(1),
          reason: 'initialisation never re-runs',
        );
      },
    );

    test(
      'finishing workouts only moves the rotation pointer; exercises stay as saved',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        final ids = await saveOnboardingProgram(r);
        final saved = snapshot(r.app);
        var day = DateTime.utc(2026, 6, 1);
        for (var i = 0; i < 7; i++) {
          final current = r.app.workouts.currentWorkout!;
          expect(
            current.id,
            ids[i % 3],
            reason: 'sequence continues in order and wraps',
          );
          await r.app.completion.complete(done(current.id, day, id: 's$i'));
          day = day.add(const Duration(days: 1));
        }
        expect(snapshot(r.app), saved);
        expect(r.app.workouts.rotation.currentIndex, 7 % 3);
        final fresh = await r.restart();
        expect(snapshot(fresh), saved);
        expect(fresh.workouts.rotation.currentIndex, 7 % 3);
      },
    );

    test(
      'rest days and skipped training days never move the rotation or create sessions',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        final ids = await saveOnboardingProgram(r);
        await r.app.completion.complete(
          done(ids[0], DateTime.utc(2026, 6, 1), id: 'a'),
        );
        expect(r.app.workouts.currentWorkout!.id, ids[1]);
        // Three weeks of nothing: still the next workout, nothing generated.
        await r.app.refresh(force: true);
        expect(r.app.workouts.currentWorkout!.id, ids[1]);
        expect(r.app.sessions.sessions, hasLength(1));
        // The next session happens 25 days later: it simply continues the sequence.
        await r.app.completion.complete(
          done(ids[1], DateTime.utc(2026, 6, 26), id: 'b'),
        );
        expect(r.app.workouts.currentWorkout!.id, ids[2]);
      },
    );

    test('a backdated session never moves the rotation', () async {
      final r = await OnlineRig.signedIn('sam_1', false);
      final ids = await saveOnboardingProgram(r);
      await r.app.completion.complete(
        done(ids[0], DateTime.utc(2026, 1, 1), id: 'old'),
        advanceRotation: false,
      );
      expect(r.app.workouts.currentWorkout!.id, ids[0]);
    });

    test(
      'the weekly goal (training / rest days) is independent of the program and the rotation',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        final ids = await saveOnboardingProgram(r);
        final saved = snapshot(r.app);
        await r.app.profile.update(
          r.app.profile.profile.copyWith(weeklySessionTarget: 2),
        );
        expect(snapshot(r.app), saved);
        expect(r.app.workouts.rotation.currentIndex, 0);
        await r.app.profile.update(
          r.app.profile.profile.copyWith(weeklySessionTarget: 6),
        );
        expect(snapshot(r.app), saved);
        expect(r.app.workouts.currentWorkout!.id, ids[0]);
        expect(WeekPlan.rest(r.app.profile.profile.weeklySessionTarget), 1);
      },
    );

    test(
      'changing the equipment preference later never rewrites the saved program',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        await saveOnboardingProgram(r);
        final saved = snapshot(r.app);
        await r.app.profile.update(
          r.app.profile.profile.copyWith(equipment: <Equipment>{}),
        );
        expect(snapshot(r.app), saved);
        await r.app.refresh(force: true);
        expect(snapshot(r.app), saved);
        expect((await r.restart()).profile.profile.equipment, isEmpty);
      },
    );
  });

  group('experience level and difficulty metadata', () {
    test(
      'changing the experience level never rewrites the saved program, even after restart and refresh',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        await saveOnboardingProgram(r);
        final saved = snapshot(r.app);
        for (final lv in Difficulty.values) {
          await r.app.profile.update(
            r.app.profile.profile.copyWith(experienceLevel: lv),
          );
          expect(snapshot(r.app), saved, reason: lv.name);
        }
        await r.app.refresh(force: true);
        expect(snapshot(r.app), saved);
        final fresh = await r.restart();
        expect(snapshot(fresh), saved);
        expect(
          fresh.profile.profile.experienceLevel,
          Difficulty.advanced,
          reason: 'persisted on the server',
        );
      },
    );

    test(
      'a saved program holds only ids, sets and reps: catalogue difficulty metadata cannot alter it',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        final ids = await saveOnboardingProgram(r);
        final row = r.remote
            .rowsOf('workouts', r.auth.user!.id)
            .firstWhere((w) => w['id'] == ids.first);
        final exercises = row['exercises'] as List;
        for (final e in exercises) {
          expect((e as Map).keys.toSet(), {
            'exerciseId',
            'sets',
            'repMin',
            'repMax',
          });
        }
      },
    );

    test(
      'a beginner who already saved an advanced exercise keeps it until they change it themselves',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        await r.app.workouts.saveSchedule([
          Workout(
            id: 'w_a',
            name: 'Legs',
            exercises: const [
              RoutineExercise(
                exerciseId: 'pistol_squat',
                sets: 3,
                repMin: 5,
                repMax: 8,
              ),
            ],
          ),
        ], const Rotation(workoutIds: ['w_a']));
        await r.app.profile.update(
          r.app.profile.profile.copyWith(experienceLevel: Difficulty.beginner),
        );
        await r.app.refresh(force: true);
        expect(
          r.app.workouts.byId('w_a')!.exercises.single.exerciseId,
          'pistol_squat',
        );
      },
    );
  });

  group('manual changes', () {
    test(
      'replacing one exercise by hand persists, changes only that exercise and survives a restart',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        final ids = await saveOnboardingProgram(r);
        final before = snapshot(r.app);
        final w = r.app.workouts.byId(ids[0])!;
        final swapped = [
          w.exercises.first.copyWith(exerciseId: 'incline_db_press'),
          ...w.exercises.skip(1),
        ];
        await r.app.workouts.saveWorkout(w.copyWith(exercises: swapped));
        final after = snapshot(r.app);
        expect(after[0], isNot(before[0]));
        expect(after.sublist(1), before.sublist(1));
        expect(
          (await r.restart()).workouts.byId(ids[0])!.exercises.first.exerciseId,
          'incline_db_press',
        );
      },
    );
  });

  group('explicit regeneration', () {
    test(
      'creates the new program, archives (never deletes) the old one and keeps all history',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        final oldIds = await saveOnboardingProgram(r, stamp: 'one');
        await r.app.completion.complete(
          done(oldIds[0], DateTime.utc(2026, 6, 1), id: 'h1'),
        );
        await r.app.completion.complete(
          done(oldIds[1], DateTime.utc(2026, 6, 3), id: 'h2'),
        );
        final sessionsBefore = [
          for (final s in r.app.sessions.sessions)
            '${s.id}|${s.workoutId}|${s.workoutDate}|${s.exercises.length}',
        ];

        final newIds = await saveOnboardingProgram(
          r,
          stamp: 'two',
          presetId: 'upper_lower',
        );
        expect(newIds, isNot(oldIds));
        expect(r.app.workouts.rotation.workoutIds, newIds);
        expect(r.app.workouts.rotation.currentIndex, 0);
        for (final id in oldIds) {
          expect(
            r.app.workouts.byId(id),
            isNotNull,
            reason: 'archived, not deleted',
          );
          expect(r.app.workouts.rotation.workoutIds.contains(id), isFalse);
        }
        expect([
          for (final s in r.app.sessions.sessions)
            '${s.id}|${s.workoutId}|${s.workoutDate}|${s.exercises.length}',
        ], sessionsBefore);
        // The same is true on the server after a restart.
        final fresh = await r.restart();
        expect(fresh.sessions.sessions, hasLength(2));
        expect(fresh.workouts.byId(oldIds[0]), isNotNull);
        expect(fresh.workouts.rotation.workoutIds, newIds);
      },
    );

    test(
      'a failed regeneration changes nothing and the same save can be retried',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        await saveOnboardingProgram(r, stamp: 'one');
        final saved = snapshot(r.app);
        r.remote.failNext(offline);
        await expectLater(
          saveOnboardingProgram(r, stamp: 'two', presetId: 'upper_lower'),
          throwsA(isA<RemoteException>()),
        );
        expect(snapshot(r.app), saved);
        expect(
          snapshot(await r.restart()),
          saved,
          reason: 'nothing reached the server either',
        );
        await saveOnboardingProgram(r, stamp: 'two', presetId: 'upper_lower');
        expect(snapshot(r.app), isNot(saved));
      },
    );

    test(
      'editing or deleting a routine never touches the sessions logged with it',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        final ids = await saveOnboardingProgram(r);
        await r.app.completion.complete(
          done(ids[0], DateTime.utc(2026, 6, 1), id: 'h1'),
        );
        final w = r.app.workouts.byId(ids[0])!;
        await r.app.workouts.saveWorkout(
          w.copyWith(name: 'Renamed', exercises: [w.exercises.last]),
        );
        expect(
          r.app.sessions.sessions.single.exercises.single.exerciseId,
          'bench_press',
        );
        await r.app.workouts.deleteWorkout(ids[0]);
        expect(r.app.sessions.sessions.single.workoutId, ids[0]);
        expect((await r.restart()).sessions.sessions, hasLength(1));
      },
    );
  });

  group('network failures and retry', () {
    test(
      'a failed first save leaves the account empty; retry succeeds once, without duplicates',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        r.remote.failNext(offline);
        await expectLater(
          saveOnboardingProgram(r),
          throwsA(isA<RemoteException>()),
        );
        expect(r.app.workouts.workouts, isEmpty);
        await saveOnboardingProgram(r);
        await saveOnboardingProgram(
          r,
        ); // double submit with the same stamp is idempotent
        expect(r.app.workouts.rotation.workoutIds, hasLength(3));
        expect(r.remote.rowsOf('workouts', r.auth.user!.id), hasLength(3));
      },
    );

    test('a refresh that fails keeps the saved program on screen', () async {
      final r = await OnlineRig.signedIn('sam_1', false);
      await saveOnboardingProgram(r);
      final saved = snapshot(r.app);
      r.remote.failAll = offline;
      await r.app.refresh(force: true);
      expect(r.app.refreshFailed, isTrue);
      expect(snapshot(r.app), saved);
    });
  });

  group('account switching and deletion', () {
    test('another account never sees the program and starts empty', () async {
      final r = await OnlineRig.signedIn('sam_1', false);
      await saveOnboardingProgram(r);
      await r.app.signOut();
      expect(r.app.workouts.workouts, isEmpty);
      final res = await r.app.registerAccount('kim_2', 'Passw0rdX');
      expect(res.outcome, AccountOutcome.signedIn);
      expect(r.app.workouts.workouts, isEmpty);
      expect(r.app.workouts.rotation.workoutIds, isEmpty);
      await r.app.signOut();
      await r.app.signInAccount('sam_1', 'Passw0rdX');
      expect(
        r.app.workouts.rotation.workoutIds,
        hasLength(3),
        reason: 'the first account is intact',
      );
    });

    test(
      'deleting the account ends the session, clears memory and the username can start over empty',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        final ids = await saveOnboardingProgram(r);
        await r.app.completion.complete(
          done(ids[0], DateTime.utc(2026, 6, 1), id: 'h1'),
        );
        final uid = r.auth.user!.id;
        final res = await r.app.deleteAccount();
        expect(res.ok, isTrue);
        expect(r.app.phase, SessionPhase.signedOut);
        expect(r.app.workouts.workouts, isEmpty);
        expect(r.app.sessions.sessions, isEmpty);
        r.remote.dropUser(uid); // the server's ON DELETE CASCADE
        expect(
          (await r.app.signInAccount('sam_1', 'Passw0rdX')).outcome,
          AccountOutcome.failed,
        );
        await r.app.registerAccount('sam_1', 'Passw0rdX');
        expect(r.app.workouts.workouts, isEmpty);
        expect(r.app.sessions.sessions, isEmpty);
      },
    );

    test(
      'a failed account deletion keeps the user signed in with their data',
      () async {
        final r = await OnlineRig.signedIn('sam_1', false);
        await saveOnboardingProgram(r);
        r.auth.deleteFails = true;
        final res = await r.app.deleteAccount();
        expect(res.ok, isFalse);
        expect(r.app.phase, SessionPhase.ready);
        expect(r.app.workouts.rotation.workoutIds, hasLength(3));
      },
    );
  });
}
