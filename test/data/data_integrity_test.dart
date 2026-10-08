import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/data_store.dart';
import 'package:stationx/data/isar/entities.dart';
import 'package:stationx/data/isar/isar_store.dart';
import 'package:stationx/data/isar/isar_sync_store.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/data/sync/sync_local_store.dart';
import 'package:stationx/domain/domain.dart';

Workout wk(String id) => Workout(id: id, name: id, exercises: const []);
WorkoutSession ses(String id, [int day = 1]) =>
    WorkoutSession(id: id, workoutId: 'w1', name: 'A', workoutDate: DateTime(2026, 1, day), exercises: const []);
CardioSession car(String id) => CardioSession(id: id, kind: CardioKind.outdoorRun, workoutDate: DateTime(2026, 1, 3), durationSeconds: 600, distanceKm: 2);

void main() {
  late Directory dir;
  setUpAll(() => Isar.initializeIsarCore(download: true));
  setUp(() => dir = Directory.systemTemp.createTempSync('stationx_integrity'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  SeedData abc(int cur) => SeedData(
        exercises: SeedData.fresh().exercises,
        workouts: [wk('A'), wk('B'), wk('C')],
        rotation: Rotation(workoutIds: const ['A', 'B', 'C'], currentIndex: cur),
        sessions: const [],
        cardio: const [],
        goals: const [],
      );

  // Runs the same scenario on the memory and the Isar workout repositories.
  Future<void> bothStores(String name, Future<void> Function(DataStore s) body) async {
    test('$name (memory)', () async => body(MemoryStore(SeedData.fresh())));
    test('$name (isar)', () async {
      final s = await IsarStore.open(directory: dir.path, name: 'wk');
      try {
        await body(s);
      } finally {
        await s.close();
      }
    });
  }

  Future<DataStore> seeded(DataStore s, int cur) async {
    await s.replaceAll(abc(cur), const UserProfile());
    return s;
  }

  group('deleteWorkout keeps the current workout identity', () {
    bothStores('delete before current shifts the index', (s) async {
      await seeded(s, 2); // current = C
      await s.workouts.deleteWorkout('A');
      expect(s.workouts.rotation.workoutIds, ['B', 'C']);
      expect(s.workouts.rotation.currentWorkoutId, 'C');
      expect(s.workouts.rotation.currentIndex, 1);
      expect(s.workouts.currentWorkout?.id, 'C');
    });
    bothStores('delete after current leaves index', (s) async {
      await seeded(s, 0);
      await s.workouts.deleteWorkout('C');
      expect(s.workouts.rotation.currentWorkoutId, 'A');
      expect(s.workouts.rotation.currentIndex, 0);
    });
    bothStores('deleting the current workout hands over to its successor', (s) async {
      await seeded(s, 1); // B
      await s.workouts.deleteWorkout('B');
      expect(s.workouts.rotation.workoutIds, ['A', 'C']);
      expect(s.workouts.rotation.currentWorkoutId, 'C');
    });
    bothStores('deleting the current LAST workout wraps to the first', (s) async {
      await seeded(s, 2); // C
      await s.workouts.deleteWorkout('C');
      expect(s.workouts.rotation.currentWorkoutId, 'A');
      expect(s.workouts.rotation.currentIndex, 0);
    });
    bothStores('deleting the last remaining workout empties the rotation', (s) async {
      await seeded(s, 1);
      for (final id in ['A', 'B', 'C']) {
        await s.workouts.deleteWorkout(id);
      }
      expect(s.workouts.workouts, isEmpty);
      expect(s.workouts.rotation.workoutIds, isEmpty);
      expect(s.workouts.rotation.currentIndex, 0);
      expect(s.workouts.currentWorkout, isNull);
    });
    bothStores('an archived (not in rotation) workout never moves the pointer', (s) async {
      await s.replaceAll(
        SeedData(
          exercises: SeedData.fresh().exercises,
          workouts: [wk('A'), wk('B'), wk('X')],
          rotation: const Rotation(workoutIds: ['A', 'B'], currentIndex: 1),
          sessions: const [],
          cardio: const [],
          goals: const [],
        ),
        const UserProfile(),
      );
      await s.workouts.deleteWorkout('X');
      expect(s.workouts.workouts.map((w) => w.id), ['A', 'B']);
      expect(s.workouts.rotation.currentWorkoutId, 'B');
      expect(s.workouts.rotation.currentIndex, 1);
    });
  });

  group('Isar persist-first', () {
    test('deleteWorkout persists rotation + tombstone together and survives restart', () async {
      var s = await IsarStore.open(directory: dir.path, name: 'pf');
      await seeded(s, 2);
      await s.workouts.deleteWorkout('A');
      expect(await s.db.syncDeletionEntitys.where().findAll().then((l) => l.map((e) => e.rowId)), ['A']);
      await s.close();
      s = await IsarStore.open(directory: dir.path, name: 'pf');
      expect(s.workouts.rotation.currentWorkoutId, 'C');
      expect(s.workouts.workouts.map((w) => w.id), ['B', 'C']);
      await s.close();
    });

    test('a failed write leaves memory unchanged and notifies nobody', () async {
      final s = await IsarStore.open(directory: dir.path, name: 'fail');
      await seeded(s, 1);
      await s.sessions.add(ses('s1'));
      await s.cardio.add(car('c1'));
      var notified = 0;
      void bump() => notified++;
      s.workouts.addListener(bump);
      s.sessions.addListener(bump);
      s.cardio.addListener(bump);
      s.profile.addListener(bump);
      s.exercises.addListener(bump);
      await s.db.close(); // every following write throws
      await expectLater(s.workouts.deleteWorkout('A'), throwsA(anything));
      await expectLater(s.workouts.saveWorkout(wk('Z')), throwsA(anything));
      await expectLater(s.workouts.setRotation(const Rotation(workoutIds: ['C'])), throwsA(anything));
      await expectLater(s.sessions.delete('s1'), throwsA(anything));
      await expectLater(s.sessions.update(WorkoutSession(id: 's1', workoutId: 'w1', name: 'changed', workoutDate: DateTime(2026, 1, 1), exercises: const [])), throwsA(anything));
      await expectLater(s.cardio.delete('c1'), throwsA(anything));
      await expectLater(s.profile.update(const UserProfile(name: 'Nope')), throwsA(anything));
      expect(s.workouts.workouts.map((w) => w.id), ['A', 'B', 'C']);
      expect(s.workouts.rotation.workoutIds, ['A', 'B', 'C']);
      expect(s.workouts.rotation.currentIndex, 1);
      expect(s.sessions.byId('s1')!.name, 'A');
      expect(s.cardio.byId('c1'), isNotNull);
      expect(s.profile.profile.name, isNot('Nope'));
      expect(notified, 0);
    });

    test('session/cardio delete queues the tombstone in the same transaction (both or neither)', () async {
      final s = await IsarStore.open(directory: dir.path, name: 'tomb');
      await s.sessions.add(ses('real1'));
      await s.cardio.add(car('realc'));
      await s.sessions.delete('real1');
      await s.cardio.delete('realc');
      final ids = (await s.db.syncDeletionEntitys.where().findAll()).map((e) => e.rowId).toSet();
      expect(ids, {'real1', 'realc'});
      await s.close();
    });
  });

  group('update on a missing id is a no-op everywhere', () {
    test('memory', () async {
      final s = MemoryStore(SeedData.fresh());
      var n = 0;
      s.sessions.addListener(() => n++);
      await s.sessions.update(ses('ghost'));
      await s.cardio.update(car('ghost'));
      expect(s.sessions.sessions, isEmpty);
      expect(s.cardio.sessions, isEmpty);
      expect(n, 0);
    });
    test('isar: does not resurrect a deleted session', () async {
      final s = await IsarStore.open(directory: dir.path, name: 'ghost');
      await s.sessions.add(ses('s1'));
      await s.cardio.add(car('c1'));
      await s.sessions.delete('s1');
      await s.cardio.delete('c1');
      await s.sessions.update(ses('s1'));
      await s.cardio.update(car('c1'));
      expect(s.sessions.sessions, isEmpty);
      expect(await s.db.sessionEntitys.count(), 0);
      expect(await s.db.cardioSessionEntitys.count(), 0);
      await s.close();
    });
  });

  group('wipe / account switch', () {
    test('wipeAllData while signed out of cloud resets a stale SyncState but keeps the profile', () async {
      final store = await IsarStore.open(directory: dir.path, name: 'wipe');
      final app = AppController(store: store);
      await app.register(name: 'Sam', email: 'sam@x.io');
      await app.sessions.add(ses('s1'));
      final sync = IsarSyncLocalStore(store);
      await sync.saveState(SyncState(userId: 'user-1', cursors: const {'workout_sessions': '2026-01-01T00:00:00Z'}, lastSyncAt: DateTime(2026, 1, 1)));
      expect(app.cloud.user, isNull);
      await app.wipeAllData();
      final st = await sync.loadState();
      expect(st.userId, isNull);
      expect(st.cursors, isEmpty);
      expect(st.lastSyncAt, isNull);
      expect(app.sessions.sessions, isEmpty);
      expect(app.profile.profile.email, 'sam@x.io');
      await app.close();
    });

    test('resetForAccountSwitch (replace) drops the previous profile and sync link, keeps nothing of the old data', () async {
      final store = await IsarStore.open(directory: dir.path, name: 'sw1');
      await store.profile.update(const UserProfile(name: 'Old', email: 'old@x.io', isGuest: false, weightKg: 99, heightCm: 200, age: 50));
      await store.sessions.add(ses('s1'));
      final sync = IsarSyncLocalStore(store);
      await sync.saveState(const SyncState(userId: 'old', cursors: {'a': 'b'}));
      await sync.resetForAccountSwitch();
      final p = store.profile.profile;
      expect([p.name, p.email, p.weightKg, p.heightCm, p.age, p.isGuest], ['Athlete', '', 74, 175, 25, true]);
      expect(store.sessions.sessions, isEmpty);
      expect((await sync.loadState()).userId, isNull);
      // the blank profile must not be uploaded over the new account's profile
      expect((await store.db.profileEntitys.get(1))!.syncStatus, SyncStatus.synced);
      await store.close();
    });

    test('merge keeps local data but the old profile is not carried to the new account', () async {
      final store = await IsarStore.open(directory: dir.path, name: 'sw2');
      await store.profile.update(const UserProfile(name: 'Old', email: 'old@x.io', isGuest: false, weightKg: 99));
      await store.sessions.add(ses('s1'));
      final sync = IsarSyncLocalStore(store);
      await sync.markAllUserDataDirty();
      expect(store.sessions.sessions.map((s) => s.id), ['s1']); // data policy: merge keeps data
      expect(store.profile.profile.email, '');
      expect(store.profile.profile.weightKg, 74);
      final pe = (await store.db.profileEntitys.get(1))!;
      expect(pe.syncStatus, SyncStatus.synced); // nothing of the old profile is queued for upload
      expect(pe.email, '');
      await store.close();
    });
  });

  group('demo data', () {
    test('demo is marked, ignored by hasUserData, and removable without touching real rows', () async {
      final store = await IsarStore.open(directory: dir.path, name: 'demo');
      final app = AppController(store: store);
      await app.startGuest();
      expect(app.hasDemoData, isFalse);
      expect(await app.loadDemoData(), isTrue);
      expect(app.hasDemoData, isTrue);
      expect(app.hasUserData, isFalse); // demo only
      await IsarSyncLocalStore(store).markSingletonsClean(); // profile/rotation edits count as pending data
      expect(await IsarSyncLocalStore(store).hasUserData(), isFalse);

      await app.sessions.add(ses('real_s'));
      await app.cardio.add(car('real_c'));
      expect(app.hasUserData, isTrue);
      expect(await app.loadDemoData(), isFalse); // refuses over real data
      expect(await IsarSyncLocalStore(store).hasUserData(), isTrue);

      await app.removeDemoData();
      expect(app.hasDemoData, isFalse);
      expect(app.sessions.sessions.map((s) => s.id), ['real_s']);
      expect(app.cardio.sessions.map((c) => c.id), ['real_c']);
      expect(app.workouts.workouts, isNotEmpty); // routines untouched
      // demo rows were never uploaded -> no cloud tombstones for them
      final tomb = (await store.db.syncDeletionEntitys.where().findAll()).map((e) => e.rowId);
      expect(tomb.where(isDemoId), isEmpty);
      // persisted
      await app.close();
      final again = AppController(store: await IsarStore.open(directory: dir.path, name: 'demo'));
      expect(again.hasDemoData, isFalse);
      expect(again.sessions.sessions.map((s) => s.id), ['real_s']);
      await again.close();
    });

    test('memory store: removeDemoData on a controller with no demo is a no-op', () async {
      final app = AppController();
      await app.sessions.add(ses('real'));
      await app.removeDemoData();
      expect(app.sessions.sessions.length, 1);
    });
  });
}
