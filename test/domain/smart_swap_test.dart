import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  final all = seedExercises();
  Exercise ex(String id) => all.firstWhere((e) => e.id == id);

  test('SmartSwapService delegates to the recommender (same ranking)', () {
    final cur = ex('seated_cable_row');
    final a = SmartSwapService.alternatives(current: cur, catalog: all);
    final b = ExerciseRecommender.replacements(current: cur, catalog: all);
    expect(
      a.map((c) => '${c.exercise.id}:${c.matchPercent}'),
      b.map((c) => '${c.exercise.id}:${c.matchPercent}'),
    );
  });

  test(
    'legacy contract: same broad muscle, sorted desc, equipment + exclude filters',
    () {
      final cur = ex('lat_pulldown');
      final alts = SmartSwapService.alternatives(
        current: cur,
        catalog: all,
        allowedEquipment: {Equipment.cable, Equipment.bodyweight},
        excludeIds: {'pullup'},
      );
      expect(alts, isNotEmpty);
      expect(
        alts.every((a) => a.exercise.primaryMuscle == cur.primaryMuscle),
        isTrue,
      );
      expect(alts.map((a) => a.exercise.id), isNot(contains('pullup')));
      expect(
        alts.every(
          (a) => {
            Equipment.cable,
            Equipment.bodyweight,
          }.contains(a.exercise.equipment),
        ),
        isTrue,
      );
      for (var i = 1; i < alts.length; i++) {
        expect(
          alts[i - 1].matchPercent,
          greaterThanOrEqualTo(alts[i].matchPercent),
        );
      }
      expect(alts.first.reason, isNotEmpty);
    },
  );

  test('optional history is forwarded', () {
    final s = WorkoutSession(
      id: 's',
      workoutId: 'w',
      name: 'x',
      workoutDate: DateTime(2026, 1, 1),
      exercises: const [
        ExerciseLog(exerciseId: 'chinup', sets: [SetLog(weightKg: 0, reps: 8)]),
      ],
    );
    final alts = SmartSwapService.alternatives(
      current: ex('lat_pulldown'),
      catalog: all,
      history: [s],
    );
    final chin = alts.firstWhere((a) => a.exercise.id == 'chinup');
    expect(chin.reason, contains("you've done this before"));
  });
}
