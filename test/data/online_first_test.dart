// Online-first behaviour against an in-memory Supabase (test/helpers/online_fakes.dart). No network.
// Covers: registration + init, login/restore, logout/account switch, reads, creates, edits, deletes,
// network failure, double submit, expired session, cross-user isolation, empty data, stale responses.

import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/remote/auth_service.dart';
import 'package:stationx/data/remote/remote_exception.dart';
import 'package:stationx/data/remote/remote_gateway.dart';
import 'package:stationx/data/remote/row_mappers.dart';
import 'package:stationx/domain/domain.dart';

import '../helpers/online_fakes.dart';

const offline = RemoteException(RemoteFailure.offline);
const expired = RemoteException(RemoteFailure.authExpired, code: 'PGRST301');

WorkoutSession session(String id, {String workoutId = 'w1', DateTime? date}) =>
    WorkoutSession(
      id: id,
      workoutId: workoutId,
      name: 'Chest',
      workoutDate: date ?? DateTime.utc(2026, 5, 1),
      durationSeconds: 3000,
      exercises: [
        ExerciseLog(
          exerciseId: 'bench_press',
          sets: [const SetLog(weightKg: 60, reps: 8)],
        ),
      ],
    );

Future<OnlineRig> signedInRig({
  String user = 'sam_1',
  bool program = true,
}) async {
  final r = OnlineRig();
  final res = await r.app.registerAccount(user, 'Passw0rdX');
  expect(res.outcome, AccountOutcome.signedIn);
  if (program) await r.saveThreeDayProgram();
  return r;
}

void main() {
  group('A. registration', () {
    test(
      'creates the profile on the server and starts with NO routines (the program is chosen in onboarding)',
      () async {
        final r = await signedInRig(program: false);
        final uid = r.auth.user!.id;
        expect(r.app.phase, SessionPhase.ready);
        expect(r.app.profile.profile.email, 'sam_1');
        expect(r.remote.rowsOf('workouts', uid), isEmpty);
        expect(r.app.workouts.workouts, isEmpty);
        expect(r.app.workouts.currentWorkout, isNull);
        expect(
          r.remote.rowOf('profiles', uid, '_')!['initialized_at'],
          isNotNull,
        );
        expect(
          r.remote.calls.where((c) => c == 'rpc:sx_init_account'),
          hasLength(1),
        );
      },
    );

    test(
      'a taken username or weak password creates nothing and does not sign in',
      () async {
        final r = await signedInRig();
        await r.app.signOut();
        final dup = await r.app.registerAccount('sam_1', 'Passw0rdX');
        expect(dup.outcome, AccountOutcome.failed);
        expect(dup.status, CloudAuthStatus.userExists);
        final weak = await r.app.registerAccount('new_one', 'weak');
        expect(weak.status, CloudAuthStatus.weakPassword);
        expect(r.app.phase, SessionPhase.signedOut);
        expect(r.auth.user, isNull);
      },
    );

    test(
      'initialisation is idempotent: a second sign-in neither re-creates nor changes the saved program',
      () async {
        final r = await signedInRig();
        final uid = r.auth.user!.id;
        await r.app.signOut();
        final res = await r.app.signInAccount('sam_1', 'Passw0rdX');
        expect(res.outcome, AccountOutcome.signedIn);
        expect(r.remote.rowsOf('workouts', uid), hasLength(3));
        expect(r.app.workouts.workouts, hasLength(3));
      },
    );

    test(
      'if loading fails after sign-up the user is not left half signed in',
      () async {
        final r = OnlineRig();
        r.remote.failAll = offline;
        final res = await r.app.registerAccount('sam_1', 'Passw0rdX');
        expect(res.outcome, AccountOutcome.failed);
        expect(res.status, CloudAuthStatus.network);
        expect(r.app.phase, SessionPhase.signedOut);
      },
    );
  });

  group('B. login and session restore', () {
    test('wrong password fails and loads nothing', () async {
      final r = OnlineRig()..auth.seedUser('sam_1', 'Passw0rdX');
      final res = await r.app.signInAccount('sam_1', 'nope');
      expect(res.status, CloudAuthStatus.invalidCredentials);
      expect(r.remote.calls, isEmpty);
    });

    test(
      'a saved session is restored at start-up and the data is loaded',
      () async {
        final r = OnlineRig();
        r.auth.seedUser('sam_1', 'Passw0rdX');
        final uid = r.auth.user?.id ?? 'uid-sam_1';
        r.remote.plant('workout_sessions', uid, sessionToRow(session('s1')));
        r.auth.restoreSession('sam_1');
        await r.app.init();
        expect(r.app.phase, SessionPhase.ready);
        expect(r.app.sessions.sessions.map((s) => s.id), ['s1']);
      },
    );

    test('no saved session shows the signed-out screen', () async {
      final r = OnlineRig();
      await r.app.init();
      expect(r.app.phase, SessionPhase.signedOut);
    });

    test(
      'load failure is reported with a retry, never as an empty app',
      () async {
        final r = OnlineRig()..auth.seedUser('sam_1', 'Passw0rdX');
        r.auth.restoreSession('sam_1');
        r.remote.failAll = offline;
        await r.app.init();
        expect(r.app.phase, SessionPhase.loadFailed);
        expect(r.app.loadError!.kind, RemoteFailure.offline);
        r.remote.failAll = null;
        await r.app.retryLoad();
        expect(r.app.phase, SessionPhase.ready);
        expect(
          r.app.workouts.workouts,
          isEmpty,
          reason: 'a new account has no program until onboarding saves one',
        );
      },
    );
  });

  group('C. logout and account switching', () {
    test('logout empties every repository and the device draft', () async {
      final r = await signedInRig();
      await r.app.sessions.add(session('s1'));
      await r.app.workoutDraft.save(
        WorkoutDraft(
          workoutId: 'w1',
          workoutName: 'Chest',
          startedAt: DateTime.now(),
          savedAt: DateTime.now(),
          exercises: const [],
        ),
      );
      await r.app.signOut();
      expect(r.app.phase, SessionPhase.signedOut);
      expect(r.app.sessions.sessions, isEmpty);
      expect(r.app.workouts.workouts, isEmpty);
      expect(r.app.profile.profile.email, isEmpty);
      expect(r.app.workoutDraft.current, isNull);
      expect(r.auth.user, isNull);
    });

    test("another account never sees the previous user's data", () async {
      final r = await signedInRig(user: 'alice');
      await r.app.sessions.add(session('alice_s'));
      await r.app.signOut();
      await r.app.registerAccount('bob', 'Passw0rdX');
      expect(r.app.sessions.sessions, isEmpty);
      expect(r.app.profile.profile.email, 'bob');
      await r.app.sessions.add(session('bob_s'));
      expect(
        r.remote.rowsOf('workout_sessions', 'uid-alice').map((x) => x['id']),
        ['alice_s'],
      );
      expect(
        r.remote.rowsOf('workout_sessions', 'uid-bob').map((x) => x['id']),
        ['bob_s'],
      );
      await r.app.signOut();
      await r.app.signInAccount('alice', 'Passw0rdX');
      expect(r.app.sessions.sessions.map((s) => s.id), ['alice_s']);
    });

    test("a different account's draft is discarded when it signs in", () async {
      final r = await signedInRig(user: 'alice');
      await r.app.workoutDraft.save(
        WorkoutDraft(
          workoutId: 'w1',
          workoutName: 'Chest',
          startedAt: DateTime.now(),
          savedAt: DateTime.now(),
          exercises: const [],
        ),
      );
      // the device still holds alice's draft when bob signs in directly (no clean logout)
      r.auth.seedUser('bob', 'Passw0rdX');
      await r.auth.signIn('bob', 'Passw0rdX');
      await Future<void>.delayed(Duration.zero);
      for (var i = 0; i < 20 && r.app.phase != SessionPhase.ready; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(r.app.profile.profile.email, 'bob');
      expect(r.app.workoutDraft.current, isNull);
      expect(r.app.sessions.sessions, isEmpty);
    });
  });

  group('D/M. reading', () {
    test(
      'sessions, cardio, goals, custom exercises and activities load; an empty account is fine',
      () async {
        final r = await signedInRig();
        final uid = r.auth.user!.id;
        var empty = true;
        expect(r.app.sessions.sessions, isEmpty);
        expect(r.app.cardio.sessions, isEmpty);
        expect(r.app.cardio.goals, isEmpty);
        r.remote.plant('workout_sessions', uid, sessionToRow(session('s1')));
        r.remote.plant(
          'cardio_sessions',
          uid,
          cardioToRow(
            CardioSession(
              id: 'c1',
              kind: CardioKind.treadmill,
              workoutDate: DateTime.utc(2026, 5, 2),
              durationSeconds: 1200,
            ),
          ),
        );
        r.remote.plant(
          'cardio_goals',
          uid,
          goalToRow(
            CardioGoal(
              id: 'g1',
              title: 'Run',
              metric: GoalMetric.distanceKm,
              target: 20,
            ),
          ),
        );
        r.remote.plant(
          'exercises',
          uid,
          exerciseToRow(
            Exercise.custom(
              id: 'custom_1',
              name: 'My Curl',
              equipment: Equipment.dumbbell,
              targets: [MuscleTarget.primary(MuscleRegion.biceps)],
            ),
          ),
        );
        await r.app.refresh(force: true);
        empty = false;
        expect(empty, isFalse);
        expect(r.app.sessions.sessions, hasLength(1));
        expect(r.app.cardio.sessions, hasLength(1));
        expect(r.app.cardio.goals.single.title, 'Run');
        expect(r.app.exercises.byId('custom_1')!.name, 'My Curl');
        expect(
          r.app.exercises.byId('bench_press'),
          isNotNull,
          reason: 'built-in catalogue is always present',
        );
      },
    );

    test(
      'a corrupt row is skipped instead of making the whole account unloadable',
      () async {
        final r = await signedInRig();
        final uid = r.auth.user!.id;
        r.remote.plant('workout_sessions', uid, {
          'id': 'bad',
          'exercises': 'not a list',
          'workout_date': 'garbage',
        });
        r.remote.plant('workout_sessions', uid, sessionToRow(session('ok')));
        await r.app.refresh(force: true);
        expect(r.app.sessions.sessions.map((s) => s.id), ['ok']);
        expect(r.store.skippedRows, 1);
      },
    );
  });

  group('E/F/G/H. writes are confirmed by the server first', () {
    test('create workout: stored on the server and in the rotation', () async {
      final r = await signedInRig();
      final uid = r.auth.user!.id;
      await r.app.workouts.saveWorkout(
        Workout(id: 'w_new', name: 'Legs', exercises: const []),
      );
      expect(r.remote.rowOf('workouts', uid, 'w_new')!['name'], 'Legs');
      expect(
        (r.remote.rowOf('rotations', uid, '_')!['workout_ids'] as List),
        contains('w_new'),
      );
      expect(r.app.workouts.byId('w_new'), isNotNull);
    });

    test(
      'finishing a workout saves the session AND moves the rotation in ONE server call',
      () async {
        final r = await signedInRig();
        final uid = r.auth.user!.id;
        r.remote.calls.clear();
        final cur = r.app.workouts.currentWorkout!;
        await r.app.completion.complete(session('s_done', workoutId: cur.id));
        expect(r.remote.calls, ['rpc:sx_finish_workout']);
        expect(r.remote.rowOf('workout_sessions', uid, 's_done'), isNotNull);
        expect(r.remote.rowOf('rotations', uid, '_')!['current_index'], 1);
        expect(r.app.sessions.byId('s_done'), isNotNull);
        expect(r.app.workouts.rotation.currentIndex, 1);
      },
    );

    test(
      'a failed finish changes nothing anywhere and can be retried without duplicates',
      () async {
        final r = await signedInRig();
        final uid = r.auth.user!.id;
        final cur = r.app.workouts.currentWorkout!;
        r.remote.failNext(offline);
        await expectLater(
          r.app.completion.complete(session('s_done', workoutId: cur.id)),
          throwsA(isA<RemoteException>()),
        );
        expect(r.app.sessions.sessions, isEmpty);
        expect(r.app.workouts.rotation.currentIndex, 0);
        expect(r.remote.rowsOf('workout_sessions', uid), isEmpty);
        expect(r.remote.rowOf('rotations', uid, '_')!['current_index'], 0);
        await r.app.completion.complete(session('s_done', workoutId: cur.id));
        await r.app.completion.complete(
          session('s_done', workoutId: cur.id),
        ); // lost-response retry
        expect(r.app.sessions.sessions, hasLength(1));
        expect(r.remote.rowsOf('workout_sessions', uid), hasLength(1));
      },
    );

    test(
      'a server rejection (constraint) is reported and nothing is shown as saved',
      () async {
        final r = await signedInRig();
        r.remote.failNext(
          const RemoteException(RemoteFailure.rejected, code: '23514'),
        );
        await expectLater(
          r.app.sessions.add(session('x')),
          throwsA(
            isA<RemoteException>().having(
              (e) => e.kind,
              'kind',
              RemoteFailure.rejected,
            ),
          ),
        );
        expect(r.app.sessions.sessions, isEmpty);
      },
    );

    test(
      'edit and delete a session update the server and the screen only after success',
      () async {
        final r = await signedInRig();
        final uid = r.auth.user!.id;
        await r.app.sessions.add(session('s1'));
        final edited = WorkoutSession(
          id: 's1',
          workoutId: 'w1',
          name: 'Renamed',
          workoutDate: DateTime.utc(2026, 5, 1),
          exercises: const [],
          durationSeconds: 10,
        );
        r.remote.failNext(offline);
        await expectLater(
          r.app.sessions.update(edited),
          throwsA(isA<RemoteException>()),
        );
        expect(
          r.app.sessions.byId('s1')!.name,
          'Chest',
          reason: 'failed edit leaves the old value',
        );
        await r.app.sessions.update(edited);
        expect(r.app.sessions.byId('s1')!.name, 'Renamed');
        expect(
          r.remote.rowOf('workout_sessions', uid, 's1')!['name'],
          'Renamed',
        );

        r.remote.failNext(offline);
        await expectLater(
          r.app.sessions.delete('s1'),
          throwsA(isA<RemoteException>()),
        );
        expect(
          r.app.sessions.byId('s1'),
          isNotNull,
          reason: 'failed delete keeps the row on screen',
        );
        await r.app.sessions.delete('s1');
        expect(r.app.sessions.byId('s1'), isNull);
        expect(r.remote.rowOf('workout_sessions', uid, 's1'), isNull);
      },
    );

    test(
      'updating a session that no longer exists never resurrects it',
      () async {
        final r = await signedInRig();
        await r.app.sessions.update(session('ghost'));
        expect(r.remote.rowsOf('workout_sessions', r.auth.user!.id), isEmpty);
      },
    );

    test(
      'deleting a workout keeps the rotation pointing at the same current workout, atomically',
      () async {
        final r = await signedInRig();
        final uid = r.auth.user!.id;
        final ids = r.app.workouts.rotation.workoutIds;
        await r.app.workouts.setCurrentWorkout(ids[2]);
        r.remote.calls.clear();
        await r.app.workouts.deleteWorkout(ids[0]);
        expect(r.remote.calls, ['rpc:sx_save_workouts']);
        expect(r.remote.rowOf('workouts', uid, ids[0]), isNull);
        expect(r.app.workouts.rotation.currentWorkoutId, ids[2]);
        expect(
          r.remote.rowOf('rotations', uid, '_')!['workout_ids'],
          isNot(contains(ids[0])),
        );
        // history of the deleted routine stays
      },
    );

    test('profile, goals and custom activities round-trip', () async {
      final r = await signedInRig();
      final uid = r.auth.user!.id;
      await r.app.profile.update(
        r.app.profile.profile.copyWith(weightKg: 81.5, unit: WeightUnit.lb),
      );
      expect(r.remote.rowOf('profiles', uid, '_')!['weight_kg'], 81.5);
      r.remote.failNext(offline);
      await expectLater(
        r.app.profile.update(r.app.profile.profile.copyWith(weightKg: 99)),
        throwsA(isA<RemoteException>()),
      );
      expect(r.app.profile.profile.weightKg, 81.5);
      await r.app.cardio.saveGoal(
        CardioGoal(
          id: 'g1',
          title: 'Run',
          metric: GoalMetric.distanceKm,
          target: 20,
        ),
      );
      await r.app.cardio.deleteGoal('g1');
      expect(r.app.cardio.goals, isEmpty);
      await r.app.cardio.addCustomActivity(
        CustomCardioActivity(id: 'a1', name: 'Boxing'),
      );
      await r.app.cardio.addCustomActivity(
        CustomCardioActivity(id: 'a1', name: 'Boxing'),
      ); // retry
      expect(r.app.cardio.customActivities, hasLength(1));
    });

    test(
      '"delete all my data" empties the account on the server, including the program',
      () async {
        final r = await signedInRig();
        final uid = r.auth.user!.id;
        await r.app.sessions.add(session('s1'));
        await r.app.deleteAllData();
        expect(r.remote.rowsOf('workout_sessions', uid), isEmpty);
        expect(r.app.sessions.sessions, isEmpty);
        expect(
          r.app.workouts.workouts,
          isEmpty,
          reason: 'nothing is generated behind the user\'s back',
        );
      },
    );
  });

  group('I/J/O. failures and duplicate submissions', () {
    test('every kind of failure leaves the read model untouched', () async {
      final r = await signedInRig();
      for (final f in [
        offline,
        const RemoteException(RemoteFailure.server),
        const RemoteException(RemoteFailure.unknown),
      ]) {
        r.remote.failNext(f);
        await expectLater(
          r.app.cardio.add(
            CardioSession(
              id: 'c',
              kind: CardioKind.treadmill,
              workoutDate: DateTime.utc(2026),
              durationSeconds: 5,
            ),
          ),
          throwsA(isA<RemoteException>()),
        );
        expect(r.app.cardio.sessions, isEmpty);
      }
    });

    test(
      'double tap: the same session sent twice produces one row, in order',
      () async {
        final r = await signedInRig();
        final f1 = r.app.sessions.add(session('s1'));
        final f2 = r.app.sessions.add(session('s1'));
        await Future.wait([f1, f2]);
        expect(r.app.sessions.sessions, hasLength(1));
        expect(
          r.remote.rowsOf('workout_sessions', r.auth.user!.id),
          hasLength(1),
        );
      },
    );

    test(
      'writes run one at a time, in the order they were requested',
      () async {
        final r = await signedInRig();
        final release = r.remote.hold((op) => op == 'upsert:workout_sessions');
        final first = r.app.sessions.add(session('s1'));
        final second = r.app.cardio.add(
          CardioSession(
            id: 'c1',
            kind: CardioKind.treadmill,
            workoutDate: DateTime.utc(2026),
            durationSeconds: 5,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(
          r.app.cardio.sessions,
          isEmpty,
          reason: 'second write waits for the first',
        );
        release();
        await Future.wait([first, second]);
        expect(r.app.sessions.sessions, hasLength(1));
        expect(r.app.cardio.sessions, hasLength(1));
      },
    );
  });

  group('K. expired sessions', () {
    test(
      'the server rejecting the token ends the session once and shows the login with a notice',
      () async {
        final r = await signedInRig();
        await r.app.sessions.add(session('s1'));
        r.remote.failNext(expired);
        await expectLater(
          r.app.sessions.add(session('s2')),
          throwsA(isA<RemoteException>()),
        );
        await Future<void>.delayed(Duration.zero);
        expect(r.app.phase, SessionPhase.signedOut);
        expect(r.app.sessionNotice, contains('expired'));
        expect(r.app.sessions.sessions, isEmpty);
        expect(r.auth.user, isNull);
      },
    );

    test(
      'the auth service dropping the session (failed refresh) logs the app out',
      () async {
        final r = await signedInRig();
        r.auth.expireSession();
        await Future<void>.delayed(Duration.zero);
        expect(r.app.phase, SessionPhase.signedOut);
        expect(r.app.workouts.workouts, isEmpty);
      },
    );

    test(
      'an expired session while loading goes to login instead of retrying forever',
      () async {
        final r = OnlineRig()..auth.seedUser('sam_1', 'Passw0rdX');
        r.auth.restoreSession('sam_1');
        r.remote.failAll = expired;
        await r.app.init();
        expect(r.app.phase, SessionPhase.signedOut);
        expect(r.remote.calls.length, lessThan(12), reason: 'no retry loop');
      },
    );
  });

  group('L/P. isolation, stale responses and races', () {
    test('a slow load for user A never lands in user B session', () async {
      final r = OnlineRig();
      r.auth.seedUser('alice', 'Passw0rdX');
      r.auth.seedUser('bob', 'Passw0rdX');
      r.remote.plant(
        'workout_sessions',
        'uid-alice',
        sessionToRow(session('alice_s')),
      );
      r.remote.plant(
        'workouts',
        'uid-alice',
        workoutToRow(Workout(id: 'a_w', name: 'Alice', exercises: const []), 0),
      );
      r.remote.plant('profiles', 'uid-alice', {
        'initialized_at': '2026-01-01T00:00:00Z',
      });
      final release = r.remote.hold((op) => op == 'fetchAll:workout_sessions');
      final alice = r.app.signInAccount(
        'alice',
        'Passw0rdX',
      ); // stuck on the sessions fetch
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await r.app.signOut(); // alice abandoned
      release();
      await alice;
      final bob = await r.app.signInAccount('bob', 'Passw0rdX');
      expect(bob.outcome, AccountOutcome.signedIn);
      expect(r.app.sessions.sessions, isEmpty);
      expect(r.app.workouts.byId('a_w'), isNull);
      expect(r.app.profile.profile.email, 'bob');
    });

    test(
      'a write that finishes after logout does not appear for the next user',
      () async {
        final r = await signedInRig(user: 'alice');
        final release = r.remote.hold((op) => op == 'upsert:workout_sessions');
        final pending = r.app.sessions.add(session('late'));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await r.app.signOut();
        await r.app.registerAccount('bob', 'Passw0rdX');
        release();
        await pending.catchError((_) {});
        expect(r.app.sessions.sessions, isEmpty);
      },
    );

    test(
      'a refresh that was in flight during a save does not undo the save',
      () async {
        final r = await signedInRig();
        final release = r.remote.hold(
          (op) => op == 'fetchAll:workout_sessions',
        );
        final refresh = r.app.refresh(force: true);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        release();
        // the save starts while the (older) snapshot is arriving
        await r.app.sessions.add(session('fresh'));
        await refresh;
        expect(r.app.sessions.byId('fresh'), isNotNull);
      },
    );

    test(
      'a failed refresh keeps the data and raises the stale flag; the next one clears it',
      () async {
        final r = await signedInRig();
        await r.app.sessions.add(session('s1'));
        r.remote.failNext(offline);
        await r.app.refresh(force: true);
        expect(r.app.refreshFailed, isTrue);
        expect(r.app.sessions.sessions, hasLength(1));
        expect(r.app.phase, SessionPhase.ready);
        await r.app.refresh(force: true);
        expect(r.app.refreshFailed, isFalse);
      },
    );

    test(
      'FakeRemote only ever serves the signed-in user (RLS stand-in)',
      () async {
        final r = await signedInRig(user: 'alice');
        await r.app.sessions.add(session('alice_s'));
        await r.app.signOut();
        r.auth.seedUser('bob', 'Passw0rdX');
        await r.auth.signIn('bob', 'Passw0rdX');
        expect(await r.remote.fetchAll(RemoteTable.workoutSessions), isEmpty);
        r.auth.expireSession();
        await expectLater(
          r.remote.fetchAll(RemoteTable.workoutSessions),
          throwsA(isA<RemoteException>()),
        );
      },
    );
  });
}
