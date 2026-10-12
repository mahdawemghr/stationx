import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  final cat = seedExercises();
  Exercise ex(String id) => cat.firstWhere((e) => e.id == id);
  ExerciseMuscleProfile prof(String id) => MuscleProfiles.of(ex(id));

  const adductorRows = [
    'hip_adduction_machine',
    'cable_hip_adduction',
    'band_hip_adduction',
    'side_lying_hip_adduction',
  ];
  const tibialisRows = [
    'tibialis_raise',
    'band_tibialis_raise',
    'weighted_tibialis_raise',
  ];

  test('taxonomy: new region and leaves', () {
    expect(MuscleRegion.adductors.legacy, MuscleGroup.legs);
    expect(MuscleRegion.adductors.muscles, [Muscle.adductors]);
    expect(Muscle.tibialisAnterior.region, MuscleRegion.calves);
    expect(MuscleRegion.calves.muscles, contains(Muscle.tibialisAnterior));
    expect(SectionMuscle.legs.regions.length, 5);
  });

  test(
    'legacy<->profile invariant: every profile primary region legacy == seed primaryMuscle',
    () {
      for (final e in cat) {
        final p = MuscleProfiles.builtIn(e.id);
        if (p == null) continue;
        expect(p.primaryRegion.legacy, e.primaryMuscle, reason: e.id);
      }
    },
  );

  test('adductor isolation rows credit adductors, never glutes', () {
    for (final id in adductorRows) {
      final p = prof(id);
      expect(p.primary.single.muscle, Muscle.adductors, reason: id);
      expect(
        p.targets.any((t) => t.region == MuscleRegion.glutes),
        isFalse,
        reason: id,
      );
      expect(p.primaryRegion, MuscleRegion.adductors);
    }
  });

  test('Copenhagen plank: adductors and obliques are co-primary', () {
    final p = prof('copenhagen_plank');
    expect(
      {for (final t in p.primary) t.muscle},
      {Muscle.obliques, Muscle.adductors},
    );
    expect(p.primary.any((t) => t.region == MuscleRegion.glutes), isFalse);
  });

  test('tibialis rows credit tibialis, not gastrocnemius/soleus', () {
    for (final id in tibialisRows) {
      final p = prof(id);
      expect(p.primary.single.muscle, Muscle.tibialisAnterior, reason: id);
      expect(
        p.targets.any(
          (t) => t.muscle == Muscle.gastrocnemius || t.muscle == Muscle.soleus,
        ),
        isFalse,
      );
    }
  });

  test('squat variants keep quads primary and assist the adductors at 0.5', () {
    for (final id in [
      'db_sumo_squat',
      'kb_sumo_squat',
      'kb_cossack_squat',
      'cossack_squat',
      'sumo_deadlift',
      'kb_sumo_deadlift',
      'lateral_lunge',
    ]) {
      final p = prof(id);
      expect(
        p.primary.any((t) => t.region == MuscleRegion.adductors),
        isFalse,
        reason: id,
      );
      final a = p.targets.singleWhere((t) => t.muscle == Muscle.adductors);
      expect(
        (a.role, a.effectiveWeight),
        (TargetRole.secondary, 0.5),
        reason: id,
      );
    }
  });

  test('coverage by hand: Legs day with a hip-adduction set', () {
    final w = Workout(
      id: 'w',
      name: 'Legs',
      exercises: [
        const RoutineExercise(exerciseId: 'hip_adduction_machine', sets: 3),
        const RoutineExercise(exerciseId: 'db_sumo_squat', sets: 4),
      ],
    );
    final r = MuscleCoverage.ofWorkout(w, cat);
    // adductors region: 3 (primary, x1.0) + 4 (assist, x0.5) = 5 weighted, 3 direct.
    expect(r.weightedByRegion[MuscleRegion.adductors], 5);
    expect(r.directByRegion[MuscleRegion.adductors], 3);
    expect(r.weightedByMuscle[Muscle.adductors], 5);
    expect(r.directByMuscle[Muscle.adductors], 3);
    // glutes only from the sumo squat (gluteus maximus assists at 0.5): 2 weighted, 0 direct.
    expect(r.weightedByRegion[MuscleRegion.glutes], 2);
    expect(r.directByRegion[MuscleRegion.glutes], isNull);
    // adductor thresholds: moderate >= 2, high >= 6 weighted per week.
    expect(r.levelOfRegion(MuscleRegion.adductors), CoverageLevel.moderate);
    final two = MuscleCoverage.ofSlots([(ex('hip_adduction_machine'), 6)]);
    expect(two.levelOfRegion(MuscleRegion.adductors), CoverageLevel.high);
    expect(two.levelOfRegion(MuscleRegion.glutes), CoverageLevel.none);
  });

  test('VolumeService counts adductor work under the legacy legs group', () {
    final s = WorkoutSession(
      id: 's',
      workoutId: 'w',
      name: 'Legs',
      workoutDate: DateTime(2026, 1, 1),
      exercises: [
        ExerciseLog(
          exerciseId: 'hip_adduction_machine',
          sets: [
            for (var i = 0; i < 3; i++)
              const SetLog(weightKg: 40, reps: 12, done: true),
          ],
        ),
      ],
    );
    expect(VolumeService.setsByMuscle([s], cat), {MuscleGroup.legs: 3});
  });

  test(
    'codec: new names round-trip, old payloads decode, unknown names are dropped',
    () {
      const targets = [
        MuscleTarget.primary(MuscleRegion.adductors, muscle: Muscle.adductors),
        MuscleTarget.secondary(
          MuscleRegion.calves,
          muscle: Muscle.tibialisAnterior,
        ),
      ];
      final back = MuscleTargetCodec.decode(MuscleTargetCodec.encode(targets));
      expect(back!.map((t) => (t.region, t.muscle, t.role)), [
        (MuscleRegion.adductors, Muscle.adductors, TargetRole.primary),
        (MuscleRegion.calves, Muscle.tibialisAnterior, TargetRole.secondary),
      ]);
      final old = MuscleTargetCodec.fromJson([
        {'region': 'glutes', 'muscle': 'gluteusMaximus', 'role': 'primary'},
      ]);
      expect(old!.single.muscle, Muscle.gluteusMaximus);
      final unk = MuscleTargetCodec.fromJson([
        {'region': 'chest', 'role': 'primary'},
        {'region': 'hipFlexors', 'role': 'primary'},
        {'region': 'adductors', 'muscle': 'notAMuscle', 'role': 'secondary'},
        {
          'region': 'adductors',
          'muscle': 'gluteusMaximus',
          'role': 'secondary',
        },
      ]);
      expect(unk!.length, 1);
    },
  );

  test('Exercise.custom derives legs for adductors and tibialis', () {
    final e = Exercise.custom(
      id: 'c1',
      name: 'Zz',
      equipment: Equipment.cable,
      targets: const [
        MuscleTarget.primary(MuscleRegion.adductors, muscle: Muscle.adductors),
      ],
    );
    expect(e.primaryMuscle, MuscleGroup.legs);
  });

  test('section derivation: new leaves map to their own curated sections', () {
    for (final id in adductorRows) {
      expect(
        SplitCatalog.derivedSectionIdOf(ex(id)),
        'legs_glutes_adduct',
        reason: id,
      );
      expect(SplitCatalog.sectionIdOf(ex(id)), 'legs_glutes_adduct');
    }
    for (final id in tibialisRows) {
      expect(
        SplitCatalog.derivedSectionIdOf(ex(id)),
        'legs_calves_tibialis',
        reason: id,
      );
    }
  });

  test(
    'recommender never builds a legs/calves day from tibialis and does not flag adductor gaps',
    () {
      final legs = ExerciseRecommender.forDay(
        regions: [MuscleRegion.calves, MuscleRegion.glutes],
        catalog: cat,
        maxExercises: 8,
      );
      final ids = legs.map((r) => r.exerciseId).toSet();
      expect(
        ids.any((i) => tibialisRows.contains(i) || adductorRows.contains(i)),
        isFalse,
      );
      final rep = MuscleCoverage.ofSlots([
        (ex('back_squat'), 4),
        (ex('calf_raise'), 4),
      ]);
      expect(
        ExerciseRecommender.gaps(
          rep,
        ).where((g) => g.region == MuscleRegion.adductors),
        isEmpty,
      );
    },
  );
}
