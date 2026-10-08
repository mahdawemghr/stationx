import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  group('MuscleTargetCodec', () {
    test('round-trips region, leaf, role, emphasis and weight', () {
      const src = [
        MuscleTarget.primary(MuscleRegion.back, muscle: Muscle.lats, emphasis: 'Stretch'),
        MuscleTarget.secondary(MuscleRegion.biceps),
        MuscleTarget(MuscleRegion.core, role: TargetRole.secondary, weight: 0.25),
      ];
      final back = MuscleTargetCodec.decode(MuscleTargetCodec.encode(src));
      expect(back!.map((t) => (t.region, t.muscle, t.role, t.emphasis, t.weight)),
          src.map((t) => (t.region, t.muscle, t.role, t.emphasis, t.weight)));
    });

    test('null/empty/no-primary encode to null', () {
      expect(MuscleTargetCodec.encode(null), isNull);
      expect(MuscleTargetCodec.encode(const []), isNull);
      expect(MuscleTargetCodec.encode(const [MuscleTarget.secondary(MuscleRegion.biceps)]), isNull);
    });

    test('garbage is tolerated: bad entries dropped, bad JSON -> null', () {
      expect(MuscleTargetCodec.decode('not json'), isNull);
      expect(MuscleTargetCodec.decode('{"a":1}'), isNull);
      expect(MuscleTargetCodec.decode(''), isNull);
      final t = MuscleTargetCodec.fromJson([
        42,
        {'region': 'nope', 'role': 'primary'},
        {'region': 'back', 'muscle': 'upperChest', 'role': 'primary'}, // leaf not in region
        {'region': 'back', 'muscle': 'lats', 'role': 'bogus'},
        {'region': 'back', 'muscle': 'lats', 'role': 'primary', 'weight': 'x', 'emphasis': '  '},
        {'region': 'back', 'muscle': 'lats', 'role': 'secondary'}, // duplicate of the above
        {'region': 'biceps', 'role': 'secondary', 'weight': 99},
      ])!;
      expect(t.length, 2);
      expect(t[0].weight, isNull);
      expect(t[0].emphasis, isNull);
      expect(t[1].weight, isNull);
    });
  });

  group('Exercise.custom', () {
    test('derives consistent legacy fields from targets', () {
      final e = Exercise.custom(
        id: 'c',
        name: 'X',
        equipment: Equipment.cable,
        targets: const [
          MuscleTarget.secondary(MuscleRegion.biceps),
          MuscleTarget.primary(MuscleRegion.hamstrings),
          MuscleTarget.primary(MuscleRegion.glutes),
          MuscleTarget.secondary(MuscleRegion.forearms),
        ],
      );
      expect(e.isCustom, isTrue);
      expect(e.primaryMuscle, MuscleGroup.legs); // first PRIMARY target, not first row
      expect(e.secondaryMuscles, [MuscleGroup.biceps]); // forearms->biceps deduped, legs removed
    });

    test('requires a primary target', () {
      expect(() => Exercise.custom(id: 'c', name: 'X', equipment: Equipment.cable, targets: const [MuscleTarget.secondary(MuscleRegion.core)]),
          throwsArgumentError);
    });
  });

  group('MuscleProfiles.of for custom exercises', () {
    final withTargets = Exercise.custom(
      id: 'custom_lat',
      name: 'Lat Pulldown Variation',
      equipment: Equipment.cable,
      targets: const [
        MuscleTarget.primary(MuscleRegion.back, muscle: Muscle.lats),
        MuscleTarget.secondary(MuscleRegion.biceps),
        MuscleTarget.secondary(MuscleRegion.back, muscle: Muscle.upperBack),
      ],
    );
    final without = Exercise(id: 'custom_old', name: 'Old', primaryMuscle: MuscleGroup.back, secondaryMuscles: const [MuscleGroup.biceps], equipment: Equipment.cable, isCustom: true);

    test('uses stored targets (leaf-level) when present', () {
      final p = MuscleProfiles.of(withTargets);
      expect(p.lead.muscle, Muscle.lats);
      expect(p.targets.length, 3);
    });

    test('1.0 / 0.5 weights apply through MuscleCoverage', () {
      final r = MuscleCoverage.ofSlots([(withTargets, 4)]);
      expect(r.directByMuscle[Muscle.lats], 4.0);
      expect(r.weightedByMuscle[Muscle.lats], 4.0);
      expect(r.weightedByMuscle[Muscle.upperBack], 2.0);
      expect(r.directByMuscle[Muscle.upperBack], isNull);
      expect(r.weightedByRegion[MuscleRegion.biceps], 2.0);
    });

    test('without targets falls back to the region-level derived profile', () {
      final p = MuscleProfiles.of(without);
      expect(p.lead.muscle, isNull);
      expect(p.primaryRegion, MuscleRegion.back);
      expect(p.secondary.single.region, MuscleRegion.biceps);
    });

    test('built-in id always wins over any stored targets', () {
      final fake = Exercise(id: 'lat_pulldown', name: 'x', primaryMuscle: MuscleGroup.chest, equipment: Equipment.cable,
          muscleTargets: const [MuscleTarget.primary(MuscleRegion.chest)]);
      expect(MuscleProfiles.of(fake).primaryRegion, MuscleRegion.back);
    });

    test('recommender: custom exercise with Back->Lats primary is a replacement for Lat Pulldown', () {
      final catalog = [...seedExercises(), withTargets];
      final cur = catalog.firstWhere((e) => e.id == 'lat_pulldown');
      final res = ExerciseRecommender.replacements(current: cur, catalog: catalog);
      final hit = res.where((c) => c.exercise.id == 'custom_lat').toList();
      expect(hit, isNotEmpty);
      expect(hit.single.matchPercent, greaterThan(60)); // same leaf
      // The same exercise WITHOUT targets is only a region-level match, so it ranks lower.
      final coarse = Exercise(id: 'custom_coarse', name: 'Coarse', primaryMuscle: MuscleGroup.back, equipment: Equipment.cable, isCustom: true);
      final res2 = ExerciseRecommender.replacements(current: cur, catalog: [...seedExercises(), coarse]);
      expect(res2.firstWhere((c) => c.exercise.id == 'custom_coarse').matchPercent, lessThan(hit.single.matchPercent));
    });
  });
}
