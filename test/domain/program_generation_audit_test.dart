import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

/// Measured checks of the automatic program generation against the REAL exercise catalogue.
void main() {
  final catalog = seedExercises();
  final byId = {for (final e in catalog) e.id: e};

  final equipmentSets = <String, Set<Equipment>?>{
    'not chosen': null,
    'bodyweight only': <Equipment>{},
    'dumbbells': {Equipment.dumbbell},
    'dumbbells + bands': {Equipment.dumbbell, Equipment.band},
    'machines + cables': {Equipment.machine, Equipment.cable},
    'barbell + dumbbells': {Equipment.barbell, Equipment.dumbbell},
  };

  SectionMuscle sectionOf(String id) =>
      SectionMuscle.of(MuscleProfiles.of(byId[id]!).primaryRegion);

  group('suggestions for a muscle (custom split path)', () {
    for (final m in SectionMuscle.values) {
      test(
        '${m.label}: no duplicates, sane sets and rep ranges, no pattern used 3 times',
        () {
          final picks = [
            for (final r in SplitCatalog.suggest(m.legacy, catalog))
              if (sectionOf(r.exerciseId) == m) r,
          ];
          final ids = picks.map((r) => r.exerciseId).toList();
          expect(ids.toSet().length, ids.length, reason: 'duplicate exercise');
          final patterns = <String, int>{};
          for (final r in picks) {
            expect(r.sets, inInclusiveRange(2, 4));
            expect(r.repMin, lessThan(r.repMax));
            expect(r.repMin, inInclusiveRange(5, 60));
            final p = byId[r.exerciseId]!.movementPattern.toLowerCase();
            patterns[p] = (patterns[p] ?? 0) + 1;
          }
          expect(
            patterns.values.every((n) => n <= 2),
            isTrue,
            reason: 'patterns: $patterns',
          );
        },
      );
    }

    test('calves are not filled with two calf-raise variants', () {
      final picks = SplitCatalog.suggest(MuscleGroup.legs, catalog);
      final raises = picks.where(
        (r) => byId[r.exerciseId]!.movementPattern.toLowerCase() == 'raise',
      );
      expect(raises.length, lessThanOrEqualTo(1));
    });
  });

  group('equipment fit of curated presets', () {
    for (final entry in equipmentSets.entries) {
      for (final preset in SplitCatalog.presets) {
        test(
          '${preset.name} with ${entry.key}: only allowed equipment, no duplicates, sets/reps kept',
          () {
            final fitted = ProgramEquipmentFit.fit(
              preset.days,
              catalog,
              entry.value,
            );
            expect(fitted.length, preset.days.length);
            final allowed = EquipmentAccess.allowed(entry.value);
            for (var i = 0; i < fitted.length; i++) {
              final ids = fitted[i].exercises.map((r) => r.exerciseId).toList();
              expect(
                ids.toSet().length,
                ids.length,
                reason: 'duplicate in ${fitted[i].name}',
              );
              expect(
                ids,
                isNotEmpty,
                reason: '${fitted[i].name} lost every exercise',
              );
              for (final r in fitted[i].exercises) {
                expect(
                  allowed.contains(byId[r.exerciseId]!.equipment),
                  isTrue,
                  reason: '${r.exerciseId} is not allowed',
                );
              }
              // A fitted exercise keeps the position, sets and reps of the one it replaced.
              final before = preset.days[i].exercises;
              for (final r in fitted[i].exercises) {
                final same = before.where(
                  (b) =>
                      b.sets == r.sets &&
                      b.repMin == r.repMin &&
                      b.repMax == r.repMax,
                );
                expect(same, isNotEmpty);
              }
            }
          },
        );
      }
    }

    test(
      'not chosen leaves the preset untouched; a full-gym choice changes nothing',
      () {
        final p = SplitCatalog.presets.first;
        expect(
          identical(
            ProgramEquipmentFit.fitDay(p.days.first, catalog, null),
            p.days.first,
          ),
          isTrue,
        );
        final all = {...EquipmentAccess.choosable};
        for (var i = 0; i < p.days.length; i++) {
          expect(
            ProgramEquipmentFit.fitDay(
              p.days[i],
              catalog,
              all,
            ).exercises.map((r) => r.exerciseId),
            p.days[i].exercises.map((r) => r.exerciseId),
          );
        }
      },
    );

    test(
      'a replacement trains the same muscle section as the exercise it replaces',
      () {
        final p = SplitCatalog.presets.firstWhere((x) => x.id == 'ppl');
        final fitted = ProgramEquipmentFit.fit(p.days, catalog, {
          Equipment.dumbbell,
        });
        for (var d = 0; d < p.days.length; d++) {
          final orig = p.days[d].exercises;
          final now = fitted[d].exercises;
          expect(now.length, lessThanOrEqualTo(orig.length));
          final origSections = orig.map((r) => sectionOf(r.exerciseId)).toSet();
          for (final r in now) {
            expect(origSections.contains(sectionOf(r.exerciseId)), isTrue);
          }
        }
      },
    );

    test(
      'an equipment-limited program leaves out what has no close match instead of faking it',
      () {
        final p = SplitCatalog.presets.firstWhere((x) => x.id == 'bro_split');
        final arms = p.days.firstWhere((d) => d.name == 'Arms');
        final fitted = ProgramEquipmentFit.fitDay(arms, catalog, <Equipment>{});
        expect(fitted.exercises.length, lessThan(arms.exercises.length));
        expect(fitted.exercises, isNotEmpty);
      },
    );
  });

  group('forDay respects equipment and does not touch the input', () {
    for (final entry in equipmentSets.entries) {
      test('chest/back/legs days with ${entry.key}', () {
        final allowed = entry.value == null
            ? null
            : EquipmentAccess.allowed(entry.value);
        for (final regions in [
          [MuscleRegion.chest, MuscleRegion.triceps],
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
            allowedEquipment: allowed,
          );
          for (final r in picks) {
            if (allowed != null) {
              expect(allowed.contains(byId[r.exerciseId]!.equipment), isTrue);
            }
          }
          final ids = picks.map((r) => r.exerciseId).toList();
          expect(ids.toSet().length, ids.length);
        }
      });
    }
  });

  test('every equipment value can be stored and read back by name', () {
    for (final e in Equipment.values) {
      expect(Equipment.values.byName(e.name), e);
    }
    expect(EquipmentAccess.allowed(<Equipment>{}), {Equipment.bodyweight});
    expect(EquipmentAccess.allowed(null), Equipment.values.toSet());
  });
}
