import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/isar/isar_store.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/domain/domain.dart';

final t0 = DateTime(2026, 5, 1, 10);

WorkoutDraft draft(
  String wid, {
  int done = 2,
  DateTime? start,
  DateTime? backdate,
}) => WorkoutDraft(
  workoutId: wid,
  workoutName: 'Snap',
  startedAt: start ?? t0,
  savedAt: t0,
  backdate: backdate,
  exercises: [
    DraftExercise(
      exerciseId: 'lat_pulldown',
      repMin: 8,
      repMax: 12,
      sets: [
        for (var i = 0; i < 3; i++)
          DraftSet(weightKg: 50, reps: 10, done: i < done),
      ],
    ),
  ],
);

AppController newApp() => AppController(store: MemoryStore(SeedData.fresh()));

void main() {
  group('WorkoutLimit', () {
    test('boundaries', () {
      expect(
        WorkoutLimit.isExpired(t0, t0.add(const Duration(hours: 3)), 180),
        isTrue,
      );
      expect(
        WorkoutLimit.isExpired(
          t0,
          t0.add(const Duration(hours: 3, seconds: -1)),
          180,
        ),
        isFalse,
      );
      expect(
        WorkoutLimit.isExpired(t0, t0.add(const Duration(days: 9)), null),
        isFalse,
      );
    });
    test('clock went backwards is not expired and never negative', () {
      final now = t0.subtract(const Duration(hours: 5));
      expect(WorkoutLimit.isExpired(t0, now, 120), isFalse);
      expect(WorkoutLimit.elapsedSeconds(t0, now), 0);
      expect(WorkoutLimit.cappedDuration(t0, now, 120), 0);
    });
    test('capped duration', () {
      expect(
        WorkoutLimit.cappedDuration(t0, t0.add(const Duration(hours: 10)), 180),
        3 * 3600,
      );
      expect(
        WorkoutLimit.cappedDuration(
          t0,
          t0.add(const Duration(minutes: 50)),
          180,
        ),
        3000,
      );
      expect(
        WorkoutLimit.cappedDuration(
          t0,
          t0.add(const Duration(hours: 10)),
          null,
        ),
        36000,
      );
      expect(WorkoutLimit.options, [120, 180, 240, null]);
    });
  });

  group('auto-end', () {
    final late = t0.add(const Duration(hours: 5));
    test(
      'saves one capped session, advances rotation once, clears draft, idempotent',
      () async {
        final app = newApp();
        final cur = app.workouts.currentWorkout!;
        final idx = app.workouts.rotation.currentIndex;
        await app.workoutDraft.save(draft(cur.id));
        final r = (await app.autoEndExpiredWorkout(now: late))!;
        expect(r.savedSession, isTrue);
        expect(r.setsLogged, 2);
        expect(r.endedAfter, const Duration(hours: 3));
        final s = app.sessions.byId(r.sessionId!)!;
        expect(s.durationSeconds, 3 * 3600);
        expect(s.exercises.single.sets.length, 2);
        expect(s.workoutDate, t0);
        expect(s.meta.createdAt, late);
        expect(app.workoutDraft.current, isNull);
        expect(
          app.workouts.rotation.currentIndex,
          (idx + 1) % app.workouts.rotation.length,
        );
        expect(app.pendingAutoEndNotice?.workoutName, 'Snap');
        expect(await app.autoEndExpiredWorkout(now: late), isNull);
        // Same draft completed again (e.g. crash before clear): no duplicate, no second advance.
        final before = app.sessions.sessions.length;
        final rot = app.workouts.rotation.currentIndex;
        await DraftCompletion.complete(
          draft(cur.id),
          now: late,
          maxMinutes: 180,
          sessions: app.sessions,
          workouts: app.workouts,
        );
        expect(app.sessions.sessions.length, before);
        expect(app.workouts.rotation.currentIndex, rot);
        await app.clearAutoEndNotice();
        expect(app.pendingAutoEndNotice, isNull);
      },
    );
    test('concurrent calls are single-flight', () async {
      final app = newApp();
      await app.workoutDraft.save(draft(app.workouts.currentWorkout!.id));
      final before = app.sessions.sessions.length;
      final r = await Future.wait([
        app.autoEndExpiredWorkout(now: late),
        app.autoEndExpiredWorkout(now: late),
      ]);
      expect(r[0], same(r[1]));
      expect(app.sessions.sessions.length, before + 1);
    });
    test(
      'no done sets: discarded, nothing saved, rotation unchanged',
      () async {
        final app = newApp();
        final idx = app.workouts.rotation.currentIndex;
        final before = app.sessions.sessions.length;
        await app.workoutDraft.save(
          draft(app.workouts.currentWorkout!.id, done: 0),
        );
        final r = (await app.autoEndExpiredWorkout(now: late))!;
        expect(r.savedSession, isFalse);
        expect(app.sessions.sessions.length, before);
        expect(app.workouts.rotation.currentIndex, idx);
        expect(app.workoutDraft.current, isNull);
      },
    );
    test('not expired or limit off: nothing happens', () async {
      final app = newApp();
      await app.workoutDraft.save(draft(app.workouts.currentWorkout!.id));
      expect(
        await app.autoEndExpiredWorkout(now: t0.add(const Duration(hours: 2))),
        isNull,
      );
      await app.setMaxWorkoutMinutes(null);
      expect(await app.autoEndExpiredWorkout(now: late), isNull);
      expect(app.workoutDraft.current, isNotNull);
      await app.setMaxWorkoutMinutes(120);
      expect(
        (await app.autoEndExpiredWorkout(now: late))!.endedAfter,
        const Duration(hours: 2),
      );
    });
    test(
      'deleted workout still completes from the snapshot; rotation unchanged',
      () async {
        final app = newApp();
        final idx = app.workouts.rotation.currentIndex;
        await app.workoutDraft.save(draft('gone'));
        final r = (await app.autoEndExpiredWorkout(now: late))!;
        expect(app.sessions.byId(r.sessionId!)!.name, 'Snap');
        expect(app.workouts.rotation.currentIndex, idx);
      },
    );
    test(
      'matches the logger semantics (same session shape as buildSession)',
      () {
        final s = DraftCompletion.toSession(
          draft('w', done: 1),
          now: late,
          durationSeconds: 100,
        )!;
        expect(s.exercises.single.sets.single.weightKg, 50);
        expect(s.workoutId, 'w');
        expect(s.durationSeconds, 100);
        expect(
          DraftCompletion.toSession(draft('w', done: 0), now: late),
          isNull,
        );
      },
    );
  });

  group('setting persistence', () {
    late Directory dir;
    setUpAll(() => Isar.initializeIsarCore(download: true));
    setUp(
      () => dir = Directory.systemTemp.createTempSync('stationx_limit_test'),
    );
    tearDown(() => dir.deleteSync(recursive: true));

    test(
      'default, explicit off, value; wipe keeps; notice survives restart',
      () async {
        var store = await IsarStore.open(directory: dir.path, name: 'lim');
        var app = AppController(store: store);
        expect(app.maxWorkoutMinutes, 180);
        expect(app.maxWorkoutDuration, const Duration(hours: 3));
        await app.setMaxWorkoutMinutes(null);
        await app.close();
        store = await IsarStore.open(directory: dir.path, name: 'lim');
        app = AppController(store: store);
        expect(app.maxWorkoutMinutes, isNull);
        expect(app.maxWorkoutDuration, isNull);
        await app.setMaxWorkoutMinutes(240);
        await app.workoutDraft.save(draft(app.workouts.currentWorkout!.id));
        await app.autoEndExpiredWorkout(now: t0.add(const Duration(hours: 9)));
        await app.close();
        store = await IsarStore.open(directory: dir.path, name: 'lim');
        app = AppController(store: store);
        expect(app.maxWorkoutMinutes, 240);
        expect(app.pendingAutoEndNotice?.endedAfter, const Duration(hours: 4));
        await app.wipeAllData();
        expect(app.maxWorkoutMinutes, 240);
        await app.clearAutoEndNotice();
        await app.close();
        store = await IsarStore.open(directory: dir.path, name: 'lim');
        app = AppController(store: store);
        expect(app.pendingAutoEndNotice, isNull);
        await app.close();
      },
    );
  });
}
