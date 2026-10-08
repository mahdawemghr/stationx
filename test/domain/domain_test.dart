import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  group('Rotation', () {
    test('advances by one and wraps', () {
      var r = const Rotation(workoutIds: ['a', 'b', 'c']);
      r = RotationService.advance(r);
      expect(r.currentWorkoutId, 'b');
      r = RotationService.advance(RotationService.advance(r));
      expect(r.currentWorkoutId, 'a');
    });

    test(
      'completion advances exactly once; reading never changes it',
      () async {
        final store = MemoryStore(SeedData.demo());
        final before = store.workouts.rotation.currentIndex;
        // Time passing / skipped days have no input into the rotation.
        expect(store.workouts.rotation.currentIndex, before);
        final s = WorkoutSession(
          id: 'x',
          workoutId: 'w2',
          name: 'Back + Triceps',
          workoutDate: DateTime.now(),
          exercises: [],
        );
        await WorkoutCompletion(store.sessions, store.workouts).complete(s);
        expect(store.workouts.rotation.currentIndex, (before + 1) % 3);
      },
    );

    test('backdated entry can skip rotation advance', () async {
      final store = MemoryStore(SeedData.demo());
      final before = store.workouts.rotation.currentIndex;
      final s = WorkoutSession(
        id: 'y',
        workoutId: 'w1',
        name: 'x',
        workoutDate: DateTime(2020, 1, 1),
        exercises: [],
      );
      await WorkoutCompletion(
        store.sessions,
        store.workouts,
      ).complete(s, advanceRotation: false);
      expect(store.workouts.rotation.currentIndex, before);
    });

    test('workoutDate and createdAt stay separate', () {
      final past = DateTime(2024, 3, 1);
      final s = WorkoutSession(
        id: 'z',
        workoutId: 'w1',
        name: 'x',
        workoutDate: past,
        exercises: [],
      );
      expect(s.workoutDate, past);
      expect(s.meta.createdAt.isAfter(past), isTrue);
    });
  });

  group('Formulas', () {
    test('Epley 1RM', () {
      expect(estimateOneRepMax(50, 8), closeTo(63.33, 0.01));
      expect(estimateOneRepMax(100, 1), 100);
      expect(estimateOneRepMax(0, 5), 0);
    });
  });

  group('PR + volume + swap', () {
    final seed = SeedData.demo();
    test('PR service finds e1RM for logged exercise', () {
      final pr = PrService.forExercise(
        'lat_pulldown',
        seed.sessions,
      )[PrType.estimated1Rm];
      expect(pr, isNotNull);
      expect(pr!.value, greaterThan(0));
    });
    test('smart swap returns same-muscle alternatives, ranked', () {
      final cur = seed.exercises.firstWhere((e) => e.id == 'lat_pulldown');
      final alts = SmartSwapService.alternatives(
        current: cur,
        catalog: seed.exercises,
      );
      expect(alts, isNotEmpty);
      expect(
        alts.every((a) => a.exercise.primaryMuscle == cur.primaryMuscle),
        isTrue,
      );
      for (var i = 1; i < alts.length; i++) {
        expect(alts[i - 1].matchPercent >= alts[i].matchPercent, isTrue);
      }
    });
    test('plate calculator', () {
      final p = PlateCalculator.plan(targetKg: 100);
      expect(p.perSide, [25, 15]);
      expect(p.remainderKg, 0);
    });
  });
}
