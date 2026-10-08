import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  final cat = seedExercises();
  Exercise ex(String id) => cat.firstWhere((e) => e.id == id);
  Workout wk(String id, Map<String, int> sets) => Workout(
    id: id, name: id,
    exercises: [for (final e in sets.entries) RoutineExercise(exerciseId: e.key, sets: e.value)],
  );

  test('empty inputs', () {
    final r = MuscleCoverage.ofSlots(const []);
    expect(r.weightedByRegion, isEmpty);
    expect(r.levelOfRegion(MuscleRegion.chest), CoverageLevel.none);
    expect(r.levelOfMuscle(Muscle.lats), CoverageLevel.none);
    expect(MuscleCoverage.ofProgram(const [], cat).weightedByRegion, isEmpty);
    expect(MuscleCoverage.ofWorkout(wk('e', {}), cat).weightedByMuscle, isEmpty);
    final t = DateTime(2026, 1, 1);
    expect(MuscleCoverage.ofHistory(const [], cat, from: t, to: t.add(const Duration(days: 7))).weightedByRegion, isEmpty);
  });

  test('bench vs incline: mid vs upper chest; triceps secondary only', () {
    final b = MuscleCoverage.ofSlots([(ex('bench_press'), 3)]);
    expect(b.directByMuscle[Muscle.midChest], 3);
    expect(b.directByMuscle[Muscle.upperChest], isNull);
    expect(b.directByRegion[MuscleRegion.chest], 3);
    expect(b.directByRegion[MuscleRegion.triceps], isNull); // NOT direct
    expect(b.weightedByRegion[MuscleRegion.triceps], 1.5); // 3 x 0.5
    expect(b.weightedByMuscle[Muscle.frontDelts], 1.5);
    expect(b.weightedByRegion[MuscleRegion.shoulders], 1.5);
    final i = MuscleCoverage.ofSlots([(ex('incline_db_press'), 4)]);
    expect(i.directByMuscle[Muscle.upperChest], 4);
    expect(i.directByMuscle[Muscle.midChest], isNull);
  });

  test('pulldown + seated row cover lats and upper back; region-level target only hits region', () {
    final r = MuscleCoverage.ofSlots([(ex('lat_pulldown'), 3), (ex('seated_cable_row'), 3)]);
    expect(r.directByMuscle[Muscle.lats], 3);
    expect(r.weightedByMuscle[Muscle.lats], 3 + 1.5);
    expect(r.directByMuscle[Muscle.upperBack], 3);
    expect(r.weightedByMuscle[Muscle.upperBack], 3 + 1.5);
    // Biceps are region-level in both: 6 sets x 0.5, no leaf entries.
    expect(r.weightedByRegion[MuscleRegion.biceps], 3.0);
    expect(r.weightedByMuscle.keys.where((m) => m.region == MuscleRegion.biceps), isEmpty);
    // Back region counted once per set: 6 sets, plus 1.5 secondary-only nothing extra -> 6.
    expect(r.weightedByRegion[MuscleRegion.back], 6.0);
  });

  test('two primary leaves in one region count once for the region', () {
    final r = MuscleCoverage.ofSlots([(ex('db_row'), 2)]);
    expect(r.directByRegion[MuscleRegion.back], 2);
    expect(r.directByMuscle[Muscle.lats], 2);
    expect(r.directByMuscle[Muscle.upperBack], 2);
  });

  test('workout, program cycle and history maths', () {
    final a = wk('a', {'bench_press': 3});
    final b = wk('b', {'lat_pulldown': 4});
    expect(MuscleCoverage.ofWorkout(a, cat).directByRegion[MuscleRegion.chest], 3);
    // 3 days over a 2-day rotation: a, b, a
    final p = MuscleCoverage.ofProgram([a, b], cat, daysPerWeek: 3);
    expect(p.directByRegion[MuscleRegion.chest], 6);
    expect(p.directByRegion[MuscleRegion.back], 4);
    expect(p.weeks, 1);
    // 1 day over a 2-day rotation: only a
    expect(MuscleCoverage.ofProgram([a, b], cat, daysPerWeek: 1).directByRegion[MuscleRegion.back], isNull);

    final from = DateTime(2026, 1, 1);
    SetLog s(bool done) => SetLog(weightKg: 50, reps: 8, done: done);
    WorkoutSession sess(DateTime d, List<SetLog> sets) => WorkoutSession(
      id: d.toIso8601String(), workoutId: 'a', name: 'a', workoutDate: d,
      exercises: [ExerciseLog(exerciseId: 'bench_press', sets: sets)],
    );
    final h = MuscleCoverage.ofHistory(
      [
        sess(from, [s(true), s(true), s(false)]), // 2 done, in range (inclusive from)
        sess(from.add(const Duration(days: 13)), [s(true)]), // 1, in range
        sess(from.add(const Duration(days: 14)), [s(true)]), // excluded (to is exclusive)
        sess(from.subtract(const Duration(days: 1)), [s(true)]), // before
      ],
      cat, from: from, to: from.add(const Duration(days: 14)),
    );
    expect(h.weeks, closeTo(2, 1e-9));
    expect(h.directByMuscle[Muscle.midChest], 3);
    expect(h.weightedByRegion[MuscleRegion.triceps], 1.5);
  });

  test('level boundaries (per week, weighted)', () {
    CoverageReport rep(double chest, double weeks) =>
        CoverageReport(weightedByRegion: {MuscleRegion.chest: chest}, weightedByMuscle: {Muscle.midChest: chest}, weeks: weeks);
    expect(rep(0, 1).levelOfRegion(MuscleRegion.chest), CoverageLevel.none);
    expect(rep(3.9, 1).levelOfRegion(MuscleRegion.chest), CoverageLevel.low);
    expect(rep(4, 1).levelOfRegion(MuscleRegion.chest), CoverageLevel.moderate);
    expect(rep(9.9, 1).levelOfRegion(MuscleRegion.chest), CoverageLevel.moderate);
    expect(rep(10, 1).levelOfRegion(MuscleRegion.chest), CoverageLevel.high);
    expect(rep(20, 2).levelOfRegion(MuscleRegion.chest), CoverageLevel.high); // 10/week
    expect(rep(8, 2).levelOfRegion(MuscleRegion.chest), CoverageLevel.moderate); // 4/week
    expect(rep(1.9, 1).levelOfMuscle(Muscle.midChest), CoverageLevel.low);
    expect(rep(2, 1).levelOfMuscle(Muscle.midChest), CoverageLevel.moderate);
    expect(rep(5, 1).levelOfMuscle(Muscle.midChest), CoverageLevel.high);
    expect(rep(5, 1).levelOfMuscle(Muscle.lats), CoverageLevel.none);
  });
}
