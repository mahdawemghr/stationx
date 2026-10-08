import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  final all = seedExercises();
  final byId = {for (final e in all) e.id: e};

  test('every seed exercise has a profile and builtIn has no stray ids', () {
    for (final e in all) {
      expect(MuscleProfiles.builtIn(e.id), isNotNull, reason: e.id);
    }
  });

  test('profile invariants hold for all built-ins', () {
    for (final e in all) {
      final p = MuscleProfiles.builtIn(e.id)!;
      expect(p.primary, isNotEmpty, reason: e.id);
      expect(p.primaryRegion.legacy, e.primaryMuscle, reason: '${e.id} primary');
      // leaf must belong to its region
      for (final t in p.targets) {
        if (t.muscle != null) expect(t.muscle!.region, t.region, reason: e.id);
      }
      // no duplicate targets (same region + leaf)
      final keys = p.targets.map((t) => '${t.region.name}/${t.muscle?.name}').toList();
      expect(keys.toSet().length, keys.length, reason: '${e.id} duplicates');
      // rule: every legacy secondary group is represented by a secondary-target region
      final secLegacy = p.secondary.map((t) => t.region.legacy).toSet();
      for (final g in e.secondaryMuscles) {
        expect(secLegacy, contains(g), reason: '${e.id} legacy secondary $g');
      }
    }
  });

  test('spec examples', () {
    MuscleTarget? find(String id, Muscle m) =>
        MuscleProfiles.builtIn(id)!.targets.where((t) => t.muscle == m).firstOrNull;
    expect(find('bench_press', Muscle.midChest)!.role, TargetRole.primary);
    expect(find('incline_db_press', Muscle.upperChest)!.role, TargetRole.primary);
    expect(find('lat_pulldown', Muscle.lats)!.role, TargetRole.primary);
    expect(find('seated_cable_row', Muscle.upperBack)!.role, TargetRole.primary);
    expect(MuscleProfiles.builtIn('rdl')!.primaryRegion, MuscleRegion.hamstrings);
    expect(MuscleWeights.primary, 1.0);
    expect(MuscleWeights.secondary, 0.5);
  });

  test('custom exercise falls back to region-level profile', () {
    final e = byId['bench_press']!;
    final custom = Exercise(
      id: 'custom_x', name: 'X', primaryMuscle: e.primaryMuscle, secondaryMuscles: const [MuscleGroup.triceps],
      equipment: Equipment.cable, movementPattern: 'x', instructions: const [],
    );
    final p = MuscleProfiles.of(custom);
    expect(p.targets.every((t) => t.muscle == null), isTrue);
    expect(p.primaryRegion, MuscleRegion.chest);
  });
}
