import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/domain/domain.dart';

Exercise ex(
  String name, {
  Equipment eq = Equipment.machine,
  String pattern = '',
}) => Exercise(
  id: name,
  name: name,
  primaryMuscle: MuscleGroup.chest,
  equipment: eq,
  movementPattern: pattern,
);

List<SetLog> sets(double w, List<int> reps) => [
  for (final r in reps) SetLog(weightKg: w, reps: r),
];

ProgressionRecommendation? rec(
  List<SetLog> last, {
  int repMin = 8,
  int repMax = 12,
  double inc = 2.5,
  WeightUnit unit = WeightUnit.kg,
  int sessions = 3,
  DateTime? lastDate,
  Exercise? exercise,
}) => ProgressionService.recommend(
  lastSets: last,
  repMin: repMin,
  repMax: repMax,
  increment: inc,
  unit: unit,
  priorSessions: sessions,
  lastSessionDate: lastDate,
  now: DateTime(2026, 6, 1),
  exercise: exercise,
);

void main() {
  group('ProgressionService', () {
    test('increases when every set hit the top of the range', () {
      final r = rec(sets(50, [12, 12, 12]))!;
      expect(r.weightKg, 52.5);
      expect(r.isIncrease, isTrue);
      expect(r.reason, contains('50 kg'));
    });

    test('holds the weight and adds a rep otherwise', () {
      final r = rec(sets(50, [9, 8]))!;
      expect(r.weightKg, 50);
      expect(r.repMin, 10);
      expect(r.isIncrease, isFalse);
    });

    test('null with no history', () => expect(rec([]), isNull));

    test(
      'thin history is never confident: <2 done sets or <2 sessions gives no number',
      () {
        expect(rec(sets(50, [12])), isNull);
        expect(rec(sets(50, [12, 12]), sessions: 1), isNull);
        expect(
          rec([
            const SetLog(weightKg: 50, reps: 12),
            const SetLog(weightKg: 50, reps: 12, done: false),
          ]),
          isNull,
        );
      },
    );

    test(
      'stale history (>21 days) restarts from the last weight, never increases',
      () {
        final r = rec(sets(50, [12, 12, 12]), lastDate: DateTime(2026, 4, 1))!;
        expect(r.isIncrease, isFalse);
        expect(r.weightKg, 50);
        expect(r.repMin, 8);
        expect(r.reason, contains('Start again from 50 kg'));
        // 21 days exactly is still fresh.
        expect(
          rec(sets(50, [12, 12]), lastDate: DateTime(2026, 5, 11))!.isIncrease,
          isTrue,
        );
      },
    );

    test('reason text is unit-aware and lb increments are clean', () {
      const w = 100 / 2.2046226218; // 100 lb stored as kg
      final r = rec(sets(w, [12, 12]), unit: WeightUnit.lb, inc: 5)!;
      expect(r.isIncrease, isTrue);
      expect(r.reason, contains('100 lb'));
      expect(r.reason, isNot(contains('kg')));
      expect(r.weightKg * 2.2046226218, closeTo(105, 0.001));
    });

    test('no numeric recommendation for a 0 load', () {
      expect(rec(sets(0, [12, 12])), isNull);
    });

    test(
      'no numeric recommendation for bodyweight / isometric / timed work',
      () {
        expect(
          rec(
            sets(10, [12, 12]),
            exercise: ex('Pull-Up', eq: Equipment.bodyweight),
          ),
          isNull,
        );
        expect(
          rec(
            sets(10, [12, 12]),
            exercise: ex('Push-Up', eq: Equipment.bodyweight),
          ),
          isNull,
        );
        expect(
          rec(sets(10, [12, 12]), exercise: ex('Plank', eq: Equipment.machine)),
          isNull,
        );
        expect(rec(sets(10, [12, 12]), exercise: ex('Dead Hang')), isNull);
        expect(
          rec(
            sets(10, [12, 12]),
            exercise: ex('Bench Press', eq: Equipment.barbell),
          ),
          isNotNull,
        );
      },
    );

    test(
      'rep target never exceeds best + 1 (3 reps on an 8-12 range stays near 4)',
      () {
        final r = rec(sets(80, [3, 3, 2]))!;
        expect(r.weightKg, 80);
        expect(r.repMin, 4);
      },
    );

    test('a lone heavy outlier does not dictate the weight', () {
      final last = [
        ...sets(100, [12, 12, 12]),
        const SetLog(weightKg: 105, reps: 1),
      ];
      final r = rec(last)!;
      expect(
        r.weightKg,
        102.5,
      ); // 100 x 12 x3 -> increase from the working weight, not from 105
      expect(r.isIncrease, isTrue);
      // A top set that reached repMin counts as a real working set.
      final r2 = rec([
        ...sets(100, [10, 10]),
        const SetLog(weightKg: 105, reps: 8),
      ])!;
      expect(r2.weightKg, 105);
    });

    test('outlier fallback uses the modal weight', () {
      final r = rec([
        const SetLog(weightKg: 60, reps: 2),
        ...sets(50, [5, 5, 5]),
      ])!;
      expect(r.weightKg, 50);
    });

    test('increments are per exercise and unit-aware', () {
      expect(
        ProgressionService.incrementFor(
          ex('Barbell Squat', eq: Equipment.barbell),
        ),
        5,
      );
      expect(ProgressionService.incrementFor(ex('Leg Press')), 2.5);
      expect(
        ProgressionService.incrementFor(
          ex('Lateral Raise', eq: Equipment.dumbbell),
        ),
        1,
      );
      expect(
        ProgressionService.incrementFor(ex('Cable Curl', eq: Equipment.cable)),
        2.5,
      );
      expect(
        ProgressionService.incrementFor(ex('Leg Press'), WeightUnit.lb),
        5,
      );
      expect(
        ProgressionService.incrementFor(
          ex('Lateral Raise', eq: Equipment.dumbbell),
          WeightUnit.lb,
        ),
        2.5,
      );
    });
  });
}
