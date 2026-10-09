import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  test('canonical order and labels', () {
    expect(SectionMuscle.values.map((m) => m.label), [
      'Chest',
      'Back',
      'Shoulders',
      'Biceps',
      'Triceps',
      'Forearms',
      'Legs',
      'Core',
    ]);
  });
  test('every region maps to exactly one section and regions round-trip', () {
    for (final r in MuscleRegion.values) {
      expect(SectionMuscle.of(r).regions, contains(r));
    }
    final all = [for (final m in SectionMuscle.values) ...m.regions];
    expect(all.toSet().length, MuscleRegion.values.length);
    expect(all.length, MuscleRegion.values.length);
    expect(SectionMuscle.legs.regions.length, 4);
  });
  test('legacy storage mapping', () {
    expect(SectionMuscle.forearms.legacy, MuscleGroup.biceps);
    expect(SectionMuscle.legs.legacy, MuscleGroup.legs);
    for (final g in MuscleGroup.values) {
      expect(SectionMuscle.fromLegacy(g)!.legacy, g);
    }
    expect(SectionMuscle.fromLegacy(MuscleGroup.biceps), SectionMuscle.biceps);
  });
  test('sectionLabel wrapper', () {
    expect(sectionLabel(MuscleRegion.calves), 'Legs');
    expect(sectionLabel(MuscleRegion.forearms), 'Forearms');
  });
}
