import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

WorkoutSession _session(String exerciseId, {bool done = true}) =>
    WorkoutSession(
      id: 's_$exerciseId',
      workoutId: 'w',
      name: 'x',
      workoutDate: DateTime(2026, 1, 1),
      exercises: [
        ExerciseLog(
          exerciseId: exerciseId,
          sets: [SetLog(weightKg: 50, reps: 10, done: done)],
        ),
      ],
    );

void main() {
  final all = seedExercises();
  Exercise ex(String id) => all.firstWhere((e) => e.id == id);
  bool primaryLeaf(Exercise e, Muscle m) =>
      MuscleProfiles.of(e).primary.any((t) => t.muscle == m);

  group('replacements', () {
    test(
      'Lat Pulldown: Lats-primary exercises rank above generic back rows',
      () {
        final r = ExerciseRecommender.replacements(
          current: ex('lat_pulldown'),
          catalog: all,
        );
        final firstRow = r.indexWhere(
          (c) => !primaryLeaf(c.exercise, Muscle.lats),
        );
        final lastLats = r.lastIndexWhere(
          (c) => primaryLeaf(c.exercise, Muscle.lats),
        );
        expect(lastLats, lessThan(firstRow));
        expect(primaryLeaf(r.first.exercise, Muscle.lats), isTrue);
        expect(r.first.reason, contains('Lats'));
        expect(r.first.reason, contains('vertical pull'));
      },
    );

    test('Seated Cable Row: upper-back rows first', () {
      final r = ExerciseRecommender.replacements(
        current: ex('seated_cable_row'),
        catalog: all,
      );
      for (final c in r.take(4)) {
        expect(
          primaryLeaf(c.exercise, Muscle.upperBack),
          isTrue,
          reason: c.exercise.id,
        );
      }
      expect(r.first.exercise.movementPattern, 'Horizontal pull');
    });

    test('sorted, bounded 0-100, never the current or other broad groups', () {
      final cur = ex('bench_press');
      final r = ExerciseRecommender.replacements(current: cur, catalog: all);
      expect(r, isNotEmpty);
      for (var i = 0; i < r.length; i++) {
        expect(r[i].matchPercent, inInclusiveRange(0, 100));
        expect(r[i].exercise.id, isNot(cur.id));
        expect(r[i].exercise.primaryMuscle, cur.primaryMuscle);
        if (i > 0) {
          expect(
            r[i - 1].matchPercent,
            greaterThanOrEqualTo(r[i].matchPercent),
          );
        }
      }
    });

    test('equipment filter (null = all) and excludeIds', () {
      final cur = ex('lat_pulldown');
      final cable = ExerciseRecommender.replacements(
        current: cur,
        catalog: all,
        allowedEquipment: {Equipment.cable},
      );
      expect(cable, isNotEmpty);
      expect(
        cable.every((c) => c.exercise.equipment == Equipment.cable),
        isTrue,
      );
      final none = ExerciseRecommender.replacements(
        current: cur,
        catalog: all,
        allowedEquipment: <Equipment>{},
      );
      expect(none, isEmpty);
      final all1 = ExerciseRecommender.replacements(current: cur, catalog: all);
      final ex1 = ExerciseRecommender.replacements(
        current: cur,
        catalog: all,
        excludeIds: {all1.first.exercise.id},
      );
      expect(
        ex1.map((c) => c.exercise.id),
        isNot(contains(all1.first.exercise.id)),
      );
      expect(ex1.length, all1.length - 1);
    });

    test(
      'history gives a minor bonus: breaks a tie but cannot beat a better muscle match',
      () {
        final cur = ex('bench_press');
        final base = ExerciseRecommender.replacements(
          current: cur,
          catalog: all,
        );
        // The largest group of candidates sharing one (non-unique) match percent below the top: with the
        // catalogue's near-duplicate presses there are many equal scores (e.g. every other horizontal press).
        final counts = <int, int>{};
        for (final c in base) {
          counts[c.matchPercent] = (counts[c.matchPercent] ?? 0) + 1;
        }
        final tieScore = counts.entries
            .where((e) => e.value > 1)
            .map((e) => e.key)
            .reduce((a, b) => a > b ? a : b);
        final tied = base.where((c) => c.matchPercent == tieScore).toList();
        expect(tied.length, greaterThan(1));
        final target =
            tied.last.exercise.id; // normally NOT the first of its tie group
        final withHist = ExerciseRecommender.replacements(
          current: cur,
          catalog: all,
          history: [_session(target)],
        );
        final hit = withHist.firstWhere((c) => c.exercise.id == target);
        expect(hit.reason, contains("you've done this before"));
        expect(hit.matchPercent, tieScore + 5);
        // Breaks the tie: ahead of everything that scored the same as it did before the bonus ...
        final order = [for (final c in withHist) c.exercise.id];
        for (final c in tied.where((c) => c.exercise.id != target)) {
          expect(order.indexOf(target), lessThan(order.indexOf(c.exercise.id)));
        }
        // ... and with an equal final score the familiar one is listed first (deterministic tie-break).
        final sameFinal = withHist
            .where((c) => c.matchPercent == hit.matchPercent)
            .toList();
        expect(sameFinal.first.exercise.id, target);
        // Minor: it never beats a candidate that matched clearly better (more than the 5-point bonus).
        for (final c in base.where((c) => c.matchPercent > tieScore + 5)) {
          expect(order.indexOf(c.exercise.id), lessThan(order.indexOf(target)));
        }
        // Not-done (skipped) sets do not count.
        final skipped = ExerciseRecommender.replacements(
          current: cur,
          catalog: all,
          history: [_session(target, done: false)],
        );
        expect(skipped.first.exercise.id, base.first.exercise.id);
        // Same-leaf candidates still beat a familiar different-leaf one.
        final cable = ExerciseRecommender.replacements(
          current: ex('lat_pulldown'),
          catalog: all,
          history: [_session('seated_cable_row')],
        );
        expect(primaryLeaf(cable.first.exercise, Muscle.lats), isTrue);
      },
    );

    test('works for custom exercises (region-level profile only)', () {
      final custom = Exercise(
        id: 'c',
        name: 'Mine',
        primaryMuscle: MuscleGroup.back,
        equipment: Equipment.cable,
        isCustom: true,
      );
      final r = ExerciseRecommender.replacements(current: custom, catalog: all);
      expect(r, isNotEmpty);
      expect(
        r.every((c) => c.exercise.primaryMuscle == MuscleGroup.back),
        isTrue,
      );
    });
  });

  group('forDay', () {
    int chestSets(List<RoutineExercise> rs) => rs.fold(0, (a, r) => a + r.sets);

    test(
      'does not stack chest on top of Bench + Incline (at most ONE lower-chest leaf filler)',
      () {
        final added = ExerciseRecommender.forDay(
          regions: [MuscleRegion.chest],
          catalog: all,
          existing: const [
            RoutineExercise(exerciseId: 'bench_press', sets: 4),
            RoutineExercise(exerciseId: 'incline_db_press', sets: 3),
          ],
        );
        expect(added.length, lessThanOrEqualTo(1));
        expect(
          added.map((r) => r.exerciseId).toSet().intersection({
            'bench_press',
            'incline_db_press',
          }),
          isEmpty,
        );
        for (final r in added) {
          expect(
            primaryLeaf(ex(r.exerciseId), Muscle.lowerChest),
            isTrue,
            reason: r.exerciseId,
          );
        }
      },
    );

    Set<Muscle> leaves(Iterable<RoutineExercise> rs) => {
      for (final r in rs)
        for (final t in MuscleProfiles.of(ex(r.exerciseId)).primary)
          if (t.muscle != null) t.muscle!,
    };

    List<RoutineExercise> day(
      MuscleRegion r,
      List<String> existing, {
      int max = 6,
    }) => ExerciseRecommender.forDay(
      regions: [r],
      catalog: all,
      existing: [
        for (final id in existing) RoutineExercise(exerciseId: id, sets: 4),
      ],
      maxExercises: max,
    );

    test('Bench only: offers upper and lower chest', () {
      final l = leaves(day(MuscleRegion.chest, ['bench_press']));
      expect(l, containsAll([Muscle.upperChest, Muscle.lowerChest]));
    });

    test(
      'Bench + DB bench + machine press + push-up: still offers upper and lower chest',
      () {
        final added = day(MuscleRegion.chest, [
          'bench_press',
          'db_bench_press',
          'machine_chest_press',
          'pushup',
        ]);
        expect(
          leaves(added),
          containsAll([Muscle.upperChest, Muscle.lowerChest]),
        );
        expect(
          added.length,
          lessThanOrEqualTo(3),
        ); // no pile of mid-chest repeats
      },
    );

    test(
      'Lat pulldown + cable row: adds a traps / lower-back option, not another row',
      () {
        final added = day(MuscleRegion.back, [
          'lat_pulldown',
          'seated_cable_row',
        ]);
        expect(added, isNotEmpty);
        expect(
          leaves(added).intersection({Muscle.traps, Muscle.lowerBack}),
          isNotEmpty,
        );
        expect(added.map((r) => r.exerciseId), isNot(contains('deadlift')));
        expect(added.map((r) => r.exerciseId), isNot(contains('barbell_row')));
      },
    );

    test('deadlift is only a lower-back filler when nothing else can cover it', () {
      // "Simple" fillers are derived from the profiles (not a hardcoded id list): any exercise whose primary
      // leaf is lower back / traps and whose primary work stays in ONE region. Heavy multi-region hinges
      // (deadlift and its variants) are the only lower-back / traps options left without them.
      bool isSimpleFiller(Exercise e) {
        final p = MuscleProfiles.of(e);
        final leaf = p.lead.muscle;
        return (leaf == Muscle.lowerBack || leaf == Muscle.traps) &&
            {for (final t in p.primary) t.region}.length == 1;
      }

      expect(all.where(isSimpleFiller).length, greaterThan(10));
      final noSimple = all.where((e) => !isSimpleFiller(e)).toList();
      final withSimple = ExerciseRecommender.forDay(
        regions: [MuscleRegion.back],
        catalog: all,
        existing: const [
          RoutineExercise(exerciseId: 'lat_pulldown', sets: 4),
          RoutineExercise(exerciseId: 'seated_cable_row', sets: 4),
        ],
      );
      expect(withSimple.map((r) => r.exerciseId), isNot(contains('deadlift')));
      final without = ExerciseRecommender.forDay(
        regions: [MuscleRegion.back],
        catalog: noSimple,
        existing: const [
          RoutineExercise(exerciseId: 'lat_pulldown', sets: 4),
          RoutineExercise(exerciseId: 'seated_cable_row', sets: 4),
        ],
      );
      expect(without.map((r) => r.exerciseId), contains('deadlift'));
    });

    test('OHP only: adds side delts; OHP + DB press: side and rear delts', () {
      expect(
        leaves(day(MuscleRegion.shoulders, ['overhead_press'])),
        contains(Muscle.sideDelts),
      );
      final l = leaves(
        day(MuscleRegion.shoulders, ['overhead_press', 'db_shoulder_press']),
      );
      expect(l, containsAll([Muscle.sideDelts, Muscle.rearDelts]));
    });

    test(
      'leaf fillers respect maxExercises, and a leaf with no primary exercise is skipped',
      () {
        expect(day(MuscleRegion.chest, ['bench_press'], max: 1).length, 1);
        final noRear = all
            .where((e) => !primaryLeaf(e, Muscle.rearDelts))
            .toList();
        final added = ExerciseRecommender.forDay(
          regions: [MuscleRegion.shoulders],
          catalog: noRear,
          existing: const [
            RoutineExercise(exerciseId: 'overhead_press', sets: 4),
          ],
        );
        expect(leaves(added), contains(Muscle.sideDelts));
        expect(leaves(added), isNot(contains(Muscle.rearDelts)));
      },
    );

    test('regions without required leaves behave as before (region-level)', () {
      expect(
        ExerciseRecommender.requiredLeaves.containsKey(MuscleRegion.biceps),
        isFalse,
      );
      final added = ExerciseRecommender.forDay(
        regions: [MuscleRegion.biceps],
        catalog: all,
        existing: const [
          RoutineExercise(exerciseId: 'barbell_curl', sets: 4),
          RoutineExercise(exerciseId: 'db_curl', sets: 4),
        ],
      );
      expect(added, isEmpty);
    });

    test(
      'fresh chest day: compound first, bounded, valid rep ranges, deterministic',
      () {
        final a = ExerciseRecommender.forDay(
          regions: [MuscleRegion.chest],
          catalog: all,
        );
        final b = ExerciseRecommender.forDay(
          regions: [MuscleRegion.chest],
          catalog: all,
        );
        expect(
          a.map((r) => '${r.exerciseId}${r.sets}'),
          b.map((r) => '${r.exerciseId}${r.sets}'),
        );
        expect(a.length, inInclusiveRange(2, 4));
        expect(ExerciseRecommender.isCompound(ex(a.first.exerciseId)), isTrue);
        for (final r in a) {
          final compound = ExerciseRecommender.isCompound(ex(r.exerciseId));
          expect(r.sets, inInclusiveRange(2, 4));
          if (compound) {
            expect((r.repMin, r.repMax), (6, 10));
          } else {
            expect((r.repMin, r.repMax), (10, 15));
          }
          expect(ex(r.exerciseId).primaryMuscle, MuscleGroup.chest);
        }
        expect(a.map((r) => r.exerciseId).toSet().length, a.length);
      },
    );

    test('more days per week => fewer sets per day', () {
      int total(int days) => chestSets(
        ExerciseRecommender.forDay(
          regions: [MuscleRegion.chest],
          catalog: all,
          daysPerWeek: days,
          maxExercises: 8,
        ),
      );
      expect(total(2), greaterThan(total(6)));
      expect(
        ExerciseRecommender.dayTargetSets(MuscleRegion.chest, daysPerWeek: 2),
        greaterThan(
          ExerciseRecommender.dayTargetSets(MuscleRegion.chest, daysPerWeek: 6),
        ),
      );
    });

    test('a pressing day already hits triceps: fewer extra triceps sets', () {
      int sets(List<RoutineExercise> existing) => chestSets(
        ExerciseRecommender.forDay(
          regions: [MuscleRegion.triceps],
          catalog: all,
          existing: existing,
          daysPerWeek: 3,
        ),
      );
      final alone = sets(const []);
      final afterPress = sets(const [
        RoutineExercise(exerciseId: 'bench_press', sets: 4),
        RoutineExercise(exerciseId: 'overhead_press', sets: 4),
      ]);
      expect(afterPress, lessThan(alone));
    });

    test('respects equipment, maxExercises, existing ids, empty regions', () {
      final db = ExerciseRecommender.forDay(
        regions: [MuscleRegion.back],
        catalog: all,
        allowedEquipment: {Equipment.dumbbell},
      );
      expect(db, isNotEmpty);
      expect(
        db.every((r) => ex(r.exerciseId).equipment == Equipment.dumbbell),
        isTrue,
      );
      expect(
        ExerciseRecommender.forDay(
          regions: MuscleRegion.values,
          catalog: all,
          maxExercises: 3,
        ).length,
        lessThanOrEqualTo(3),
      );
      final withEx = ExerciseRecommender.forDay(
        regions: [MuscleRegion.chest],
        catalog: all,
        existing: const [RoutineExercise(exerciseId: 'dips', sets: 3)],
      );
      expect(withEx.map((r) => r.exerciseId), isNot(contains('dips')));
      expect(
        ExerciseRecommender.forDay(regions: const [], catalog: all),
        isEmpty,
      );
      expect(
        ExerciseRecommender.forDay(
          regions: [MuscleRegion.chest],
          catalog: const [],
        ),
        isEmpty,
      );
    });

    test(
      'history familiarity breaks near-ties and minExercises forces picks',
      () {
        final forced = ExerciseRecommender.forDay(
          regions: [MuscleRegion.chest],
          catalog: all,
          existing: const [
            RoutineExercise(exerciseId: 'bench_press', sets: 4),
            RoutineExercise(exerciseId: 'incline_db_press', sets: 3),
            RoutineExercise(exerciseId: 'dips', sets: 3),
          ],
          minExercises: 2,
        );
        expect(forced.length, 2);
      },
    );
  });

  group('gaps', () {
    CoverageReport report({
      Map<MuscleRegion, double> region = const {},
      Map<Muscle, double> leaf = const {},
    }) => CoverageReport(
      directByRegion: region,
      weightedByRegion: region,
      directByMuscle: leaf,
      weightedByMuscle: leaf,
    );
    final fine = {for (final r in MuscleRegion.values) r: 14.0};

    test('empty when nothing is under-trained or the report is empty', () {
      expect(ExerciseRecommender.gaps(report(region: fine)), isEmpty);
      expect(ExerciseRecommender.gaps(const CoverageReport()), isEmpty);
    });

    test('flags a thin region with a calm, optional note (never "need")', () {
      final r = Map.of(fine)..[MuscleRegion.calves] = 1.0;
      final g = ExerciseRecommender.gaps(report(region: r));
      expect(g.map((x) => x.region), [MuscleRegion.calves]);
      expect(g.single.level, CoverageLevel.low);
      expect(g.single.note, contains('optional'));
      expect(g.single.note.toLowerCase(), isNot(contains('need')));
      final none = Map.of(fine)..[MuscleRegion.core] = 0.0;
      final g2 = ExerciseRecommender.gaps(report(region: none));
      expect(g2.single.level, CoverageLevel.none);
    });

    test(
      'rear delts leaf gap only when the region is otherwise fine; forearms never flagged',
      () {
        final r = Map.of(fine)..[MuscleRegion.forearms] = 0.0;
        final g = ExerciseRecommender.gaps(
          report(
            region: r,
            leaf: {
              Muscle.frontDelts: 8,
              Muscle.sideDelts: 6,
              Muscle.rearDelts: 0.5,
            },
          ),
        );
        expect(g.length, 1);
        expect(g.single.muscle, Muscle.rearDelts);
        expect(
          g.single.note,
          'Rear delts get little direct work in this program — optional to add.',
        );
      },
    );

    test('frequency: a lower-frequency program is judged more leniently', () {
      final r = Map.of(fine)
        ..[MuscleRegion.chest] =
            4.0; // between the 0.75x and 1x versions of the 40% line (3.6 vs 4.8)
      expect(
        ExerciseRecommender.gaps(
          report(region: r),
          daysPerWeek: 5,
        ).map((g) => g.region),
        contains(MuscleRegion.chest),
      );
      expect(
        ExerciseRecommender.gaps(report(region: r), daysPerWeek: 2),
        isEmpty,
      );
    });

    test('weeks are respected (per-week judgement)', () {
      final r = {
        for (final k in MuscleRegion.values) k: 56.0,
      }; // 14/week over 4 weeks
      final rep = CoverageReport(
        directByRegion: r,
        weightedByRegion: r,
        weeks: 4,
      );
      expect(ExerciseRecommender.gaps(rep), isEmpty);
    });
  });
}
