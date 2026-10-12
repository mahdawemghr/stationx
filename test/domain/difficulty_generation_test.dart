import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

Exercise ex(
  String id,
  MuscleRegion region, {
  Difficulty? difficulty,
  Equipment equipment = Equipment.bodyweight,
  String pattern = 'Press',
}) => Exercise(
  id: id,
  name: id,
  primaryMuscle: region.legacy,
  equipment: equipment,
  movementPattern: pattern,
  muscleTargets: [MuscleTarget.primary(region)],
  difficulty: difficulty,
);

void main() {
  final catalog = seedExercises();
  final byId = {for (final e in catalog) e.id: e};
  final bodyweight = EquipmentAccess.allowed(<Equipment>{});

  group('beginner: hard filter with a controlled fallback', () {
    test(
      'never gets an advanced exercise while an easier one covers the muscle',
      () {
        for (final regions in [
          [MuscleRegion.chest, MuscleRegion.shoulders, MuscleRegion.triceps],
          [MuscleRegion.back, MuscleRegion.biceps],
          [
            MuscleRegion.quadriceps,
            MuscleRegion.hamstrings,
            MuscleRegion.glutes,
            MuscleRegion.calves,
          ],
          [MuscleRegion.core],
        ]) {
          for (final eq in <Set<Equipment>?>[null, bodyweight]) {
            final r = ExerciseRecommender.forDayDetailed(
              regions: regions,
              catalog: catalog,
              allowedEquipment: eq,
              level: Difficulty.beginner,
            );
            for (final p in r.picks) {
              final e = byId[p.exerciseId]!;
              if (e.difficulty == Difficulty.advanced) {
                expect(
                  r.advancedFallback,
                  contains(e.id),
                  reason: 'advanced ${e.name} must be a reported fallback',
                );
              }
            }
            expect(
              r.advancedFallback,
              isEmpty,
              reason:
                  'the real catalogue always has an easier option: $regions',
            );
          }
        }
      },
    );

    test(
      'bodyweight-only beginner legs: no pistol squat, still covers quads, hamstrings and calves',
      () {
        final r = ExerciseRecommender.forDayDetailed(
          regions: [
            MuscleRegion.quadriceps,
            MuscleRegion.hamstrings,
            MuscleRegion.glutes,
            MuscleRegion.calves,
          ],
          catalog: catalog,
          allowedEquipment: bodyweight,
          level: Difficulty.beginner,
        );
        final ids = r.picks.map((p) => p.exerciseId).toList();
        expect(ids, isNot(contains('pistol_squat')));
        expect(ids, isNot(contains('shrimp_squat')));
        final regions = {
          for (final p in r.picks)
            for (final t in MuscleProfiles.of(byId[p.exerciseId]!).primary)
              t.region,
        };
        expect(
          regions,
          containsAll([MuscleRegion.quadriceps, MuscleRegion.calves]),
        );
        expect(ids.toSet().length, ids.length);
      },
    );

    test(
      'the custom-split suggestion for a bodyweight-only beginner has no advanced exercise',
      () {
        final pool = [
          for (final e in catalog)
            if (bodyweight.contains(e.equipment)) e,
        ];
        for (final m in MuscleGroup.values) {
          final picks = SplitCatalog.suggest(
            m,
            pool,
            level: Difficulty.beginner,
          );
          for (final p in picks) {
            expect(
              byId[p.exerciseId]!.difficulty,
              isNot(Difficulty.advanced),
              reason: '${m.label}: ${p.exerciseId}',
            );
          }
        }
      },
    );

    test(
      'a preset fitted for a bodyweight-only beginner replaces pistol squats (pistol case)',
      () {
        final legs = SplitCatalog.presets
            .firstWhere((p) => p.id == 'ppl')
            .days
            .firstWhere((d) => d.name == 'Legs');
        final r = ProgramEquipmentFit.fitReport(
          [legs],
          catalog,
          <Equipment>{},
          level: Difficulty.beginner,
        );
        final ids = r.days.first.exercises.map((e) => e.exerciseId).toSet();
        expect(ids, isNot(contains('pistol_squat')));
        expect(r.advancedFallback, isEmpty);
        expect(
          ids.every((id) => byId[id]!.equipment == Equipment.bodyweight),
          isTrue,
        );
        expect(ids, isNotEmpty);
        // The same day for an advanced user keeps the closest match, advanced or not.
        final adv = ProgramEquipmentFit.fitReport(
          [legs],
          catalog,
          <Equipment>{},
          level: Difficulty.advanced,
        );
        expect(adv.advancedFallback, isEmpty);
      },
    );

    test(
      'controlled fallback: with nothing easier available an advanced exercise is used and reported',
      () {
        final only = [
          ex('hard_press', MuscleRegion.chest, difficulty: Difficulty.advanced),
        ];
        final r = ExerciseRecommender.forDayDetailed(
          regions: [MuscleRegion.chest],
          catalog: only,
          level: Difficulty.beginner,
        );
        expect(r.picks.map((p) => p.exerciseId), ['hard_press']);
        expect(r.advancedFallback, {'hard_press'});
      },
    );

    test(
      'fallback is per uncovered region: easy chest exercises do not let an advanced back one in',
      () {
        final tiny = [
          ex('easy_press', MuscleRegion.chest, difficulty: Difficulty.beginner),
          ex(
            'hard_row',
            MuscleRegion.back,
            difficulty: Difficulty.advanced,
            pattern: 'Row',
          ),
        ];
        final r = ExerciseRecommender.forDayDetailed(
          regions: [MuscleRegion.chest, MuscleRegion.back],
          catalog: tiny,
          level: Difficulty.beginner,
        );
        expect(r.picks.map((p) => p.exerciseId).toSet(), {
          'easy_press',
          'hard_row',
        }, reason: 'back is still covered');
        expect(r.advancedFallback, {'hard_row'});
      },
    );

    test(
      'a fitted program day keeps an advanced exercise only when nothing easier is close, and says so',
      () {
        final tiny = [
          ex('hard_press', MuscleRegion.chest, difficulty: Difficulty.advanced),
          ex(
            'far_row',
            MuscleRegion.back,
            difficulty: Difficulty.beginner,
            pattern: 'Row',
          ),
        ];
        final day = SplitDayPlan(
          name: 'Push',
          muscles: const [MuscleGroup.chest],
          exercises: const [RoutineExercise(exerciseId: 'hard_press')],
        );
        final r = ProgramEquipmentFit.fitReport(
          [day],
          tiny,
          null,
          level: Difficulty.beginner,
        );
        expect(r.days.first.exercises.map((e) => e.exerciseId), ['hard_press']);
        expect(r.advancedFallback, {'hard_press'});
        expect(r.leftOut, 0);
      },
    );
  });

  group('intermediate and advanced', () {
    test(
      'intermediate: advanced exercises are not chosen when anything else fills the need',
      () {
        for (final regions in [
          [MuscleRegion.chest, MuscleRegion.shoulders, MuscleRegion.triceps],
          [MuscleRegion.back, MuscleRegion.biceps],
          [
            MuscleRegion.quadriceps,
            MuscleRegion.hamstrings,
            MuscleRegion.calves,
          ],
        ]) {
          final picks = ExerciseRecommender.forDay(
            regions: regions,
            catalog: catalog,
            level: Difficulty.intermediate,
          );
          for (final p in picks) {
            expect(
              byId[p.exerciseId]!.difficulty,
              isNot(Difficulty.advanced),
              reason: p.exerciseId,
            );
          }
        }
      },
    );

    test(
      'intermediate: an advanced exercise IS used when it is the only way to cover a muscle',
      () {
        final only = [
          ex('hard_press', MuscleRegion.chest, difficulty: Difficulty.advanced),
        ];
        final picks = ExerciseRecommender.forDay(
          regions: [MuscleRegion.chest],
          catalog: only,
          level: Difficulty.intermediate,
        );
        expect(picks.map((p) => p.exerciseId), ['hard_press']);
      },
    );

    test(
      'intermediate prefers an easier alternative over an advanced one for the same muscle',
      () {
        final both = [
          ex('hard_press', MuscleRegion.chest, difficulty: Difficulty.advanced),
          ex(
            'mid_press',
            MuscleRegion.chest,
            difficulty: Difficulty.intermediate,
          ),
        ];
        final picks = ExerciseRecommender.forDay(
          regions: [MuscleRegion.chest],
          catalog: both,
          level: Difficulty.intermediate,
          maxExercises: 1,
        );
        expect(picks.single.exerciseId, 'mid_press');
      },
    );

    test(
      'advanced users may get any level; a null level ignores difficulty (legacy behaviour)',
      () {
        final both = [
          ex('hard_press', MuscleRegion.chest, difficulty: Difficulty.advanced),
          ex('easy_press', MuscleRegion.chest, difficulty: Difficulty.beginner),
        ];
        final adv = ExerciseRecommender.forDay(
          regions: [MuscleRegion.chest],
          catalog: both,
          level: Difficulty.advanced,
          maxExercises: 2,
          minExercises: 2,
        );
        expect(adv.map((p) => p.exerciseId).toSet(), {
          'hard_press',
          'easy_press',
        });
        final legacy = ExerciseRecommender.forDay(
          regions: [MuscleRegion.chest],
          catalog: both,
          maxExercises: 2,
          minExercises: 2,
        );
        expect(legacy.map((p) => p.exerciseId).toSet(), {
          'hard_press',
          'easy_press',
        });
      },
    );
  });

  group('custom exercises (unspecified difficulty) and manual choice', () {
    test(
      'an exercise with unknown difficulty is never filtered out for a beginner',
      () {
        final tiny = [
          ex('my_move', MuscleRegion.chest, difficulty: null),
          ex('hard_press', MuscleRegion.chest, difficulty: Difficulty.advanced),
        ];
        final r = ExerciseRecommender.forDayDetailed(
          regions: [MuscleRegion.chest],
          catalog: tiny,
          level: Difficulty.beginner,
        );
        expect(r.picks.map((p) => p.exerciseId), contains('my_move'));
        expect(r.advancedFallback, isEmpty);
      },
    );

    test(
      'the swap list for a manual replacement is unrestricted (advanced exercises stay selectable)',
      () {
        final current = byId['pushup']!;
        final swaps = ExerciseRecommender.replacements(
          current: current,
          catalog: catalog,
        );
        expect(
          swaps.any((c) => c.exercise.difficulty == Difficulty.advanced),
          isTrue,
        );
        final auto = ExerciseRecommender.replacements(
          current: current,
          catalog: catalog,
          excludeAdvanced: true,
        );
        expect(
          auto.any((c) => c.exercise.difficulty == Difficulty.advanced),
          isFalse,
        );
      },
    );

    test(
      'setting a level never changes an existing saved day (fit works on a copy only)',
      () {
        final day = SplitDayPlan(
          name: 'Legs',
          muscles: const [MuscleGroup.legs],
          exercises: const [
            RoutineExercise(
              exerciseId: 'pistol_squat',
              sets: 3,
              repMin: 5,
              repMax: 8,
            ),
          ],
        );
        ProgramEquipmentFit.fitReport(
          [day],
          catalog,
          <Equipment>{},
          level: Difficulty.beginner,
        );
        expect(day.exercises.single.exerciseId, 'pistol_squat');
      },
    );
  });

  group('muscle coverage is not sacrificed for the filter', () {
    test(
      'beginner picks cover as many regions as intermediate picks for full-gym and bodyweight days',
      () {
        Set<MuscleRegion> covered(
          Difficulty lv,
          Set<Equipment>? eq,
          List<MuscleRegion> rs,
        ) => {
          for (final p in ExerciseRecommender.forDay(
            regions: rs,
            catalog: catalog,
            allowedEquipment: eq,
            level: lv,
          ))
            for (final t in MuscleProfiles.of(byId[p.exerciseId]!).primary)
              t.region,
        };
        for (final rs in [
          [MuscleRegion.chest, MuscleRegion.shoulders, MuscleRegion.triceps],
          [MuscleRegion.back, MuscleRegion.biceps],
          [
            MuscleRegion.quadriceps,
            MuscleRegion.hamstrings,
            MuscleRegion.glutes,
            MuscleRegion.calves,
          ],
        ]) {
          for (final eq in <Set<Equipment>?>[null, bodyweight]) {
            final b = covered(
              Difficulty.beginner,
              eq,
              rs,
            ).where(rs.contains).toSet();
            final i = covered(
              Difficulty.intermediate,
              eq,
              rs,
            ).where(rs.contains).toSet();
            expect(
              b.containsAll(i),
              isTrue,
              reason:
                  'beginner lost ${i.difference(b)} for $rs / ${eq == null ? 'all gear' : 'bodyweight'}',
            );
          }
        }
      },
    );
  });
}
