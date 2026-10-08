import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/domain/domain.dart';

WorkoutSession _ws(String id, String workoutId, DateTime d, List<SetLog> sets, {String ex = 'bench_press'}) =>
    WorkoutSession(
      id: id,
      workoutId: workoutId,
      name: 'x',
      workoutDate: d,
      exercises: [ExerciseLog(exerciseId: ex, sets: sets)],
    );

CardioSession _c(String id, CardioKind k, int sec, double? km, DateTime d) =>
    CardioSession(id: id, kind: k, workoutDate: d, durationSeconds: sec, distanceKm: km);

void main() {
  group('rotation after completion', () {
    Future<MemoryStore> storeAt(List<String> ids, int index) async {
      final s = MemoryStore(SeedData.demo());
      await s.workouts.setRotation(Rotation(workoutIds: ids, currentIndex: index));
      return s;
    }

    WorkoutSession done(String workoutId, {DateTime? date}) =>
        _ws('s_${workoutId}_${date?.year}', workoutId, date ?? DateTime.now(), const []);

    test('RotationService.afterCompleting is pure', () {
      const r = Rotation(workoutIds: ['a', 'b', 'c'], currentIndex: 0);
      expect(RotationService.afterCompleting(r, 'a').currentIndex, 1);
      expect(RotationService.afterCompleting(r, 'c').currentIndex, 0); // wraps
      expect(RotationService.afterCompleting(r, 'zzz').currentIndex, 0);
      expect(r.currentIndex, 0);
      expect(RotationService.afterCompleting(const Rotation(workoutIds: []), 'a').length, 0);
    });

    test('current workout: index+1 with wrap', () async {
      final s = await storeAt(['a', 'b', 'c'], 2);
      await WorkoutCompletion(s.sessions, s.workouts).complete(done('c'));
      expect(s.workouts.rotation.currentIndex, 0);
    });

    test('non-current workout in rotation: pointer goes to the position after it', () async {
      final s = await storeAt(['a', 'b', 'c'], 0);
      await WorkoutCompletion(s.sessions, s.workouts).complete(done('b'));
      expect(s.workouts.rotation.currentWorkoutId, 'c');
    });

    test('non-current workout that is last wraps to the first', () async {
      final s = await storeAt(['a', 'b', 'c'], 0);
      await WorkoutCompletion(s.sessions, s.workouts).complete(done('c'));
      expect(s.workouts.rotation.currentWorkoutId, 'a');
    });

    test('workout not in the rotation (archived / ad-hoc) never changes it', () async {
      final s = await storeAt(['a', 'b', 'c'], 1);
      await WorkoutCompletion(s.sessions, s.workouts).complete(done('archived'));
      expect(s.workouts.rotation.currentIndex, 1);
      expect(s.workouts.rotation.workoutIds, ['a', 'b', 'c']);
    });

    test('single-workout rotation stays at 0', () async {
      final s = await storeAt(['a'], 0);
      await WorkoutCompletion(s.sessions, s.workouts).complete(done('a'));
      expect(s.workouts.rotation.currentIndex, 0);
    });

    test('backdated sessions never touch the rotation (current, other, archived)', () async {
      final s = await storeAt(['a', 'b', 'c'], 1);
      final wc = WorkoutCompletion(s.sessions, s.workouts);
      await wc.complete(done('b', date: DateTime(2020, 1, 1)), advanceRotation: false);
      await wc.complete(done('a', date: DateTime(2021, 1, 1)), advanceRotation: false);
      await wc.complete(done('zz', date: DateTime(2022, 1, 1)), advanceRotation: false);
      expect(s.workouts.rotation.currentIndex, 1);
    });

    test('the session is saved even when the rotation does not move', () async {
      final s = await storeAt(['a', 'b'], 0);
      final before = s.sessions.sessions.length;
      await WorkoutCompletion(s.sessions, s.workouts).complete(done('archived'));
      expect(s.sessions.sessions.length, before + 1);
    });
  });

  group('e1RM and strength PRs', () {
    test('estimateOneRepMax: no estimate above 12 reps, 1 rep = weight', () {
      expect(estimateOneRepMax(100, 30), 0);
      expect(estimateOneRepMax(100, 13), 0);
      expect(estimateOneRepMax(100, 12), closeTo(140, 1e-9));
      expect(estimateOneRepMax(100, 1), 100);
      expect(estimateOneRepMax(0, 10), 0);
      expect(estimateOneRepMax(100, 0), 0);
    });

    test('bodyweight (0 kg) sets only produce a most-reps PR; no 0-valued PR', () {
      final pr = PrService.forExercise('pushup', [
        _ws('a', 'w', DateTime(2026, 1, 1), const [SetLog(weightKg: 0, reps: 15), SetLog(weightKg: 0, reps: 20)], ex: 'pushup'),
      ]);
      expect(pr.keys, [PrType.mostReps]);
      expect(pr[PrType.mostReps]!.value, 20);
    });

    test('high-rep weighted set: weight PR yes, e1RM PR no', () {
      final pr = PrService.forExercise('bench_press', [
        _ws('a', 'w', DateTime(2026, 1, 1), const [SetLog(weightKg: 40, reps: 25)]),
      ]);
      expect(pr[PrType.heaviestWeight]!.value, 40);
      expect(pr.containsKey(PrType.estimated1Rm), isFalse);
      expect(pr.values.every((p) => p.value > 0), isTrue);
    });

    test('mixed session: volume ignores zero-weight sets and uses the heaviest set', () {
      final pr = PrService.forExercise('dips', [
        _ws('a', 'w', DateTime(2026, 1, 1),
            const [SetLog(weightKg: 0, reps: 12), SetLog(weightKg: 20, reps: 8)], ex: 'dips'),
      ]);
      expect(pr[PrType.highestVolume]!.value, 160);
      expect(pr[PrType.highestVolume]!.weightKg, 20);
    });

    test('ties keep the earliest record', () {
      final pr = PrService.forExercise('bench_press', [
        _ws('late', 'w', DateTime(2026, 3, 1), const [SetLog(weightKg: 100, reps: 5)]),
        _ws('early', 'w', DateTime(2026, 1, 1), const [SetLog(weightKg: 100, reps: 5)]),
      ]);
      expect(pr[PrType.heaviestWeight]!.date, DateTime(2026, 1, 1));
      expect(pr[PrType.estimated1Rm]!.date, DateTime(2026, 1, 1));
    });
  });

  group('cardio per kind', () {
    final d = DateTime(2026, 2, 1);
    test('a faster/longer bike ride never beats a run', () {
      final prs = PrService.cardio([
        _c('run', CardioKind.outdoorRun, 1800, 5, d),
        _c('bike', CardioKind.cycling, 3600, 30, d.add(const Duration(days: 1))),
      ]);
      final dist = prs.where((p) => p.type == CardioPrType.longestDistance).toList();
      final pace = prs.where((p) => p.type == CardioPrType.fastestPace).toList();
      expect(dist.map((p) => (p.sessionId, p.kindLabel)),
          containsAll([('run', 'Outdoor Run'), ('bike', 'Cycling')]));
      expect(pace.length, 2);
      expect(pace.firstWhere((p) => p.sessionId == 'run').value, 360);
      expect(prs.where((p) => p.type == CardioPrType.longestDuration).single.sessionId, 'bike');
    });

    test('no distance PR from zero distance; pace needs 1 km; ties keep earliest', () {
      final prs = PrService.cardio([
        _c('a', CardioKind.outdoorRun, 600, 0.5, d),
        _c('b', CardioKind.outdoorRun, 600, null, d),
        _c('t2', CardioKind.treadmill, 3000, 10, d.add(const Duration(days: 5))),
        _c('t1', CardioKind.treadmill, 3000, 10, d),
      ]);
      final run = prs.where((p) => p.kindLabel == 'Outdoor Run' && p.type != CardioPrType.longestDuration);
      expect(run.map((p) => (p.type, p.sessionId)), [(CardioPrType.longestDistance, 'a')]); // 0.5 km: no pace PR
      final t = prs.where((p) => p.kindLabel == 'Treadmill');
      expect(t.every((p) => p.sessionId == 't1' || p.type == CardioPrType.longestDuration), isTrue);
    });

    test('goalValue honours an optional kind filter', () {
      final g = CardioGoal(id: 'g', title: 'Weekly Running Distance', metric: GoalMetric.distanceKm, target: 20);
      final s = [
        _c('run', CardioKind.outdoorRun, 1800, 5, d),
        _c('bike', CardioKind.cycling, 3600, 30, d),
      ];
      expect(CardioMetrics.goalValue(g, s), 35);
      expect(CardioMetrics.goalValue(g, s, kinds: {CardioKind.outdoorRun, CardioKind.treadmill}), 5);
      expect(CardioMetrics.goalValue(
          CardioGoal(id: 'n', title: 'n', metric: GoalMetric.sessions, target: 3), s, kinds: {CardioKind.cycling}), 1);
    });

    test('custom cardio keeps distance when the session has one', () {
      final custom = CustomCardioActivity(id: 'c', name: 'Hike', fields: const [CardioField.duration]);
      expect(CardioFieldResolver.fieldsFor(CardioKind.custom, custom: custom), [CardioField.duration]);
      expect(CardioFieldResolver.fieldsFor(CardioKind.custom, custom: custom, existingDistanceKm: 4),
          contains(CardioField.distance));
      expect(CardioFieldResolver.fieldsFor(CardioKind.custom, existingDistanceKm: 4), contains(CardioField.distance));
      final withDist = CustomCardioActivity(id: 'd', name: 'Hike', fields: const [CardioField.duration, CardioField.distance]);
      expect(CardioFieldResolver.fieldsFor(CardioKind.custom, custom: withDist), withDist.fields);
      expect(CardioFieldResolver.fieldsFor(CardioKind.cycling), CardioKind.cycling.fields);
    });
  });

  group('MuscleTargetCodec weights', () {
    test('weights must be in (0, 1]; others fall back to the role default', () {
      final t = MuscleTargetCodec.fromJson([
        {'region': 'chest', 'role': 'primary', 'weight': 1.5},
        {'region': 'back', 'role': 'secondary', 'weight': 1.01},
        {'region': 'core', 'role': 'secondary', 'weight': 0},
        {'region': 'biceps', 'role': 'secondary', 'weight': 1.0},
        {'region': 'triceps', 'role': 'secondary', 'weight': 0.3},
      ])!;
      expect(t.map((x) => x.weight), [null, null, null, 1.0, 0.3]);
      final j = MuscleTargetCodec.toJson(const [
        MuscleTarget(MuscleRegion.chest, role: TargetRole.primary, weight: 3),
      ])!;
      expect(j.single.containsKey('weight'), isFalse);
    });
  });

  group('VolumeService', () {
    test('startOfWeek is a Monday at local midnight, DST-safe', () {
      for (final d in [
        DateTime(2026, 3, 29, 12), // EU DST switch Sunday
        DateTime(2026, 3, 8, 23, 59), // US DST switch Sunday
        DateTime(2026, 11, 1, 8),
        DateTime(2026, 10, 25, 3),
        DateTime(2026, 1, 1), // year boundary
        DateTime(2026, 3, 2), // already Monday
      ]) {
        final w = VolumeService.startOfWeek(d);
        expect(w.weekday, DateTime.monday, reason: '$d');
        expect((w.hour, w.minute, w.second), (0, 0, 0), reason: '$d');
        expect(w.isAfter(d), isFalse);
        expect(d.difference(w).inDays, lessThan(7));
      }
    });

    final all = seedExercises();
    ExerciseLog log(String id, int n) =>
        ExerciseLog(exerciseId: id, sets: [for (var i = 0; i < n; i++) const SetLog(weightKg: 50, reps: 8)]);
    WorkoutSession sess(List<ExerciseLog> l) =>
        WorkoutSession(id: 's', workoutId: 'w', name: 'x', workoutDate: DateTime(2026, 1, 1), exercises: l);

    test('setsByMuscle uses direct (primary) sets from the muscle profiles', () {
      final m = VolumeService.setsByMuscle([
        sess([log('bench_press', 4), log('lateral_raise', 3), log('deadlift', 2), log('back_squat', 5)]),
      ], all);
      expect(m[MuscleGroup.chest], 4);
      expect(m[MuscleGroup.triceps], isNull); // secondary only
      expect(m[MuscleGroup.shoulders], 3);
      expect(m[MuscleGroup.back], 2);
      expect(m[MuscleGroup.legs], 2 + 5); // once per exercise even with several leg regions
    });

    test('forearm-primary custom exercise is not shown as Biceps', () {
      final fa = Exercise.custom(
        id: 'wrist',
        name: 'Wrist curl',
        targets: const [MuscleTarget.primary(MuscleRegion.forearms, muscle: Muscle.wristFlexors)],
        equipment: Equipment.dumbbell,
      );
      final m = VolumeService.setsByMuscle([sess([log('wrist', 4)])], [...all, fa]);
      expect(m[MuscleGroup.biceps], isNull);
      expect(m.values.fold(0, (a, b) => a + b), 0);
    });

    test('matches MuscleCoverage direct sets for the same history', () {
      final s = sess([log('incline_db_press', 3), log('pullup', 4)]);
      final cov = MuscleCoverage.ofHistory([s], all, from: DateTime(2025, 12, 29), to: DateTime(2026, 1, 5));
      final m = VolumeService.setsByMuscle([s], all);
      expect(m[MuscleGroup.chest], cov.directByRegion[MuscleRegion.chest]!.round());
      expect(m[MuscleGroup.back], cov.directByRegion[MuscleRegion.back]!.round());
    });
  });
}
