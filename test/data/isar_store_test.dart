import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/data/isar/isar_store.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/domain/domain.dart';

/// Persistence tests: write → close → reopen the same database → verify.
void main() {
  late Directory dir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() {
    dir = Directory.systemTemp.createTempSync('stationx_isar_test');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<IsarStore> open() => IsarStore.open(directory: dir.path, name: 'test');

  /// Close and reopen to prove data survives an app restart.
  Future<IsarStore> reopen(IsarStore s) async {
    await s.close();
    return open();
  }

  test('first launch seeds catalogue + 3-day rotation with no history', () async {
    final s = await open();
    expect(s.exercises.all.length, greaterThan(30));
    expect(s.workouts.workouts.map((w) => w.name), ['Chest + Biceps', 'Back + Triceps', 'Legs + Shoulders']);
    expect(s.workouts.rotation.currentIndex, 0);
    expect(s.sessions.sessions, isEmpty);
    expect(s.cardio.sessions, isEmpty);
    expect(s.signedIn, isFalse);
    // Re-opening must not re-seed or duplicate.
    final s2 = await reopen(s);
    expect(s2.exercises.all.length, SeedData.fresh().exercises.length);
    expect(s2.workouts.workouts.length, 3);
    await s2.close();
  });

  test('strength session round-trips; workoutDate stays separate from createdAt', () async {
    var s = await open();
    final past = DateTime(2025, 3, 1, 18, 30);
    final created = DateTime(2026, 10, 7, 9, 0);
    await s.sessions.add(WorkoutSession(
      id: 'sess1',
      workoutId: 'w2',
      name: 'Back + Triceps',
      workoutDate: past,
      durationSeconds: 3300,
      notes: 'felt good',
      exercises: const [
        ExerciseLog(exerciseId: 'lat_pulldown', sets: [
          SetLog(weightKg: 50, reps: 8),
          SetLog(weightKg: 47.5, reps: 10, rpe: 8.5),
          SetLog(weightKg: 45, reps: 0, done: false),
        ]),
      ],
      cardio: CardioSession(
        id: 'c_in_s',
        kind: CardioKind.treadmill,
        workoutDate: past,
        durationSeconds: 1200,
        distanceKm: 2.5,
        speedKmh: 7.5,
        inclinePct: 3,
        meta: SyncMeta(createdAt: created),
      ),
      meta: SyncMeta(createdAt: created, syncStatus: SyncStatus.synced),
    ));
    s = await reopen(s);
    final got = s.sessions.byId('sess1')!;
    expect(got.workoutDate, past);
    expect(got.meta.createdAt, created);
    expect(got.meta.createdAt, isNot(got.workoutDate));
    expect(got.meta.syncStatus, SyncStatus.synced);
    expect(got.durationSeconds, 3300);
    expect(got.notes, 'felt good');
    expect(got.exercises.single.sets.length, 3);
    expect(got.exercises.single.sets[1].rpe, 8.5);
    expect(got.exercises.single.sets[2].done, isFalse);
    expect(got.cardio!.kind, CardioKind.treadmill);
    expect(got.cardio!.inclinePct, 3);
    expect(got.volume, 50 * 8 + 47.5 * 10);
    await s.close();
  });

  test('rotation advance persists; reading/other writes never move it', () async {
    var s = await open();
    expect(s.workouts.rotation.currentIndex, 0);
    await s.workouts.advanceRotation();
    await s.profile.update(s.profile.profile.copyWith(name: 'Sam')); // unrelated write
    s = await reopen(s);
    expect(s.workouts.rotation.currentIndex, 1);
    expect(s.workouts.currentWorkout!.name, 'Back + Triceps');
    await s.workouts.setCurrentWorkout('w3');
    s = await reopen(s);
    expect(s.workouts.rotation.currentIndex, 2);
    await s.workouts.advanceRotation(); // wraps
    s = await reopen(s);
    expect(s.workouts.rotation.currentIndex, 0);
    await s.close();
  });

  test('completion service persists the session and advances once', () async {
    var s = await open();
    final session = WorkoutSession(id: 'done1', workoutId: 'w1', name: 'x', workoutDate: DateTime.now(), exercises: const []);
    await WorkoutCompletion(s.sessions, s.workouts).complete(session);
    s = await reopen(s);
    expect(s.sessions.sessions.single.id, 'done1');
    expect(s.workouts.rotation.currentIndex, 1);
    await s.close();
  });

  test('workout edits, order and rotation membership persist', () async {
    var s = await open();
    final w1 = s.workouts.byId('w1')!;
    await s.workouts.saveWorkout(w1.copyWith(
        name: 'Chest Day',
        exercises: [...w1.exercises, const RoutineExercise(exerciseId: 'pushup', sets: 2, repMin: 15, repMax: 20)],
        cardioFinisher: const CardioTarget(kind: CardioKind.stationaryBike, durationMinutes: 15, resistance: 8)));
    await s.workouts.saveWorkout(Workout(id: 'custom1', name: 'Arms', exercises: const [RoutineExercise(exerciseId: 'hammer_curl')]));
    await s.workouts.deleteWorkout('w3');
    s = await reopen(s);
    expect(s.workouts.workouts.map((w) => w.id), ['w1', 'w2', 'custom1']);
    expect(s.workouts.byId('w1')!.name, 'Chest Day');
    expect(s.workouts.byId('w1')!.exercises.last.exerciseId, 'pushup');
    expect(s.workouts.byId('w1')!.cardioFinisher!.kind, CardioKind.stationaryBike);
    expect(s.workouts.byId('w1')!.cardioFinisher!.resistance, 8);
    expect(s.workouts.rotation.workoutIds, ['w1', 'w2', 'custom1']);
    await s.close();
  });

  test('cardio sessions, goals and custom activities persist (add / update / delete)', () async {
    var s = await open();
    final date = DateTime(2026, 9, 10, 7, 15);
    await s.cardio.add(CardioSession(id: 'c1', kind: CardioKind.outdoorRun, workoutDate: date, durationSeconds: 1938, distanceKm: 5.2, calories: 324, avgHeartRate: 144, rpe: 7.5, routeName: 'Loop', notes: 'n'));
    await s.cardio.add(CardioSession(id: 'c2', kind: CardioKind.cycling, workoutDate: DateTime(2026, 9, 12), durationSeconds: 2700));
    await s.cardio.update(s.cardio.byId('c1')!.copyWith(distanceKm: 5.3));
    await s.cardio.delete('c2');
    await s.cardio.saveGoal(CardioGoal(id: 'g1', title: 'Weekly minutes', metric: GoalMetric.durationMinutes, target: 150, isPrimary: true));
    await s.cardio.saveGoal(CardioGoal(id: 'g2', title: 'tmp', metric: GoalMetric.sessions, target: 3));
    await s.cardio.deleteGoal('g2');
    await s.cardio.addCustomActivity(CustomCardioActivity(
        id: 'a1', name: 'Boxing', fields: const [CardioField.duration, CardioField.heartRate], roundSeconds: 180, restSeconds: 60, rounds: 5));
    s = await reopen(s);
    expect(s.cardio.sessions.map((c) => c.id), ['c1']);
    final c = s.cardio.byId('c1')!;
    expect(c.workoutDate, date);
    expect(c.distanceKm, 5.3);
    expect(c.calories, 324);
    expect(c.routeName, 'Loop');
    expect(c.paceSecPerKm, closeTo(1938 / 5.3, 0.001));
    expect(s.cardio.goals.map((g) => g.id), ['g1']);
    expect(s.cardio.goals.single.isPrimary, isTrue);
    expect(s.cardio.customActivities.single.name, 'Boxing');
    expect(s.cardio.customActivities.single.fields, [CardioField.duration, CardioField.heartRate]);
    expect(s.cardio.customActivities.single.rounds, 5);
    await s.close();
  });

  test('profile, settings, sign-in flag and custom exercises persist', () async {
    var s = await open();
    await s.profile.update(const UserProfile(
        name: 'Sam', email: 'sam@mail.com', isGuest: false, weightKg: 80, unit: WeightUnit.lb, themeMode: SxThemeMode.oled, autoRestSeconds: 120, weeklySessionTarget: 5, cardioDistanceUnitKm: false));
    await s.setSignedIn(true);
    await s.exercises.addCustom(Exercise(id: 'custom_x', name: 'My Press', primaryMuscle: MuscleGroup.shoulders, equipment: Equipment.dumbbell, isCustom: true, tempo: '3-0-1-0'));
    s = await reopen(s);
    final p = s.profile.profile;
    expect((p.name, p.email, p.isGuest, p.weightKg, p.unit, p.themeMode, p.autoRestSeconds, p.weeklySessionTarget, p.cardioDistanceUnitKm),
        ('Sam', 'sam@mail.com', false, 80.0, WeightUnit.lb, SxThemeMode.oled, 120, 5, false));
    expect(s.signedIn, isTrue);
    final ex = s.exercises.byId('custom_x')!;
    expect(ex.isCustom, isTrue);
    expect(ex.tempo, '3-0-1-0');
    await s.setSignedIn(false);
    s = await reopen(s);
    expect(s.signedIn, isFalse);
    await s.close();
  });

  test('replaceAll(demo) persists; wipe returns to an empty account keeping the profile', () async {
    var s = await open();
    final demo = SeedData.demo();
    await s.replaceAll(demo, const UserProfile(name: 'Sam', isGuest: false, email: 's@x.io'));
    s = await reopen(s);
    expect(s.sessions.sessions.length, demo.sessions.length);
    expect(s.cardio.sessions.length, demo.cardio.length);
    expect(s.workouts.rotation.currentIndex, 1);
    // Newest first, and dates survived exactly.
    expect(s.sessions.sessions.first.workoutDate, demo.sessions.first.workoutDate);
    expect(s.cardio.goals.length, 3);
    await s.replaceAll(SeedData.fresh(), s.profile.profile);
    s = await reopen(s);
    expect(s.sessions.sessions, isEmpty);
    expect(s.cardio.sessions, isEmpty);
    expect(s.cardio.goals, isEmpty);
    expect(s.exercises.all, isNotEmpty);
    expect(s.workouts.rotation.currentIndex, 0);
    expect(s.profile.profile.name, 'Sam');
    await s.close();
  });

  test('session update and delete persist; listeners fire after the write', () async {
    var s = await open();
    var notified = 0;
    s.sessions.addListener(() => notified++);
    final base = WorkoutSession(id: 's1', workoutId: 'w1', name: 'A', workoutDate: DateTime(2026, 1, 1), exercises: const []);
    await s.sessions.add(base);
    await s.sessions.add(WorkoutSession(id: 's2', workoutId: 'w1', name: 'B', workoutDate: DateTime(2026, 2, 1), exercises: const []));
    expect(notified, 2);
    await s.sessions.update(WorkoutSession(id: 's1', workoutId: 'w1', name: 'A edited', workoutDate: DateTime(2026, 3, 1), exercises: const []));
    await s.sessions.delete('s2');
    s = await reopen(s);
    expect(s.sessions.sessions.map((e) => e.name), ['A edited']);
    expect(s.sessions.sessions.single.workoutDate, DateTime(2026, 3, 1));
    await s.close();
  });

  test('health opt-in consent persists across restart and is independent of sign-in', () async {
    var s = await open();
    expect(s.healthConsent.connected, isFalse);
    await s.healthConsent.setConnected(true);
    await s.setSignedIn(true);
    s = await reopen(s);
    expect(s.healthConsent.connected, isTrue);
    expect(s.signedIn, isTrue);
    await s.setSignedIn(false); // signing out must not drop the consent flag
    s = await reopen(s);
    expect(s.healthConsent.connected, isTrue);
    await s.healthConsent.setConnected(false);
    s = await reopen(s);
    expect(s.healthConsent.connected, isFalse);
    await s.close();
  });
}
