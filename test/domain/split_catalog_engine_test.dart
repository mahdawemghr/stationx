import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  final all = seedExercises();
  Exercise ex(String id) => all.firstWhere((e) => e.id == id);

  test(
    'sections are consistent with the muscle profiles (derived == curated, except documented overrides)',
    () {
      for (final e in all) {
        final derived = SplitCatalog.derivedSectionIdOf(e);
        if (derived == null) {
          continue; // not derivable defensibly (region-level profile) -> curated only
        }
        if (SplitCatalog.isSectionOverride(e)) continue;
        // Derivation is family-level: split sub-areas (e.g. mid / mid_cable) share one lead section.
        expect(
          derived,
          SplitCatalog.familyLeadOf(SplitCatalog.sectionIdOf(e)),
          reason: e.id,
        );
      }
      // Every override really differs (otherwise it should not be listed).
      for (final id in SplitCatalog.sectionOverrideIds) {
        final e = ex(id);
        expect(
          SplitCatalog.derivedSectionIdOf(e),
          isNot(SplitCatalog.familyLeadOf(SplitCatalog.sectionIdOf(e))),
          reason: id,
        );
      }
    },
  );

  test('every per-section override really contains a differing exercise', () {
    for (final sid in SplitCatalog.sectionOverrideSectionIds) {
      final differs = all.where((e) {
        final d = SplitCatalog.derivedSectionIdOf(e);
        return SplitCatalog.sectionIdOf(e) == sid &&
            d != null &&
            d != SplitCatalog.familyLeadOf(sid);
      });
      expect(differs, isNotEmpty, reason: sid);
    }
  });

  test(
    'uncurated built-in ids derive their section from the profile; unknown ids keep the fallback',
    () {
      // A curated id's section comes from the curated map even if the exercise object is a different one.
      final lastBack = SplitCatalog.sectionsFor(MuscleGroup.back).last.id;
      final unknown = Exercise(
        id: 'zzz',
        name: 'Zzz',
        primaryMuscle: MuscleGroup.back,
        equipment: Equipment.cable,
      );
      expect(SplitCatalog.derivedSectionIdOf(unknown), isNull);
      expect(SplitCatalog.sectionIdOf(unknown), lastBack);
    },
  );

  test('every preset day has no region with absurd overlap', () {
    // Documented caps (sets per day per region): a single-region high-volume day (bro-split back, 17 direct /
    // ~27 weighted) is fine; anything beyond ~1.5x of that would be absurd stacking.
    const maxDirect = 20.0, maxWeighted = 30.0;
    for (final p in SplitCatalog.presets) {
      for (final d in p.days) {
        final direct = <MuscleRegion, double>{},
            weighted = <MuscleRegion, double>{};
        for (final r in d.exercises) {
          for (final t in MuscleProfiles.of(ex(r.exerciseId)).targets) {
            weighted[t.region] =
                (weighted[t.region] ?? 0) + r.sets * t.effectiveWeight;
            if (t.role == TargetRole.primary) {
              direct[t.region] = (direct[t.region] ?? 0) + r.sets;
            }
          }
        }
        for (final e in direct.entries) {
          expect(
            e.value,
            lessThanOrEqualTo(maxDirect),
            reason: '${p.id}/${d.name}/${e.key.name}',
          );
        }
        for (final e in weighted.entries) {
          expect(
            e.value,
            lessThanOrEqualTo(maxWeighted),
            reason: '${p.id}/${d.name}/${e.key.name}',
          );
        }
      }
    }
  });

  test(
    'suggest does not over-stack: bounded count and per-region direct sets',
    () {
      for (final m in MuscleGroup.values) {
        final s = SplitCatalog.suggest(m, all);
        expect(s.length, inInclusiveRange(2, 4), reason: m.name);
        final direct = <MuscleRegion, int>{};
        for (final r in s) {
          for (final t in MuscleProfiles.of(ex(r.exerciseId)).primary) {
            direct[t.region] = (direct[t.region] ?? 0) + r.sets;
          }
        }
        for (final e in direct.entries) {
          expect(
            e.value,
            lessThanOrEqualTo(14),
            reason: '${m.name}/${e.key.name}',
          );
        }
        expect(s.map((r) => r.exerciseId).toSet().length, s.length);
      }
    },
  );

  test(
    'suggest is a single-region recommender call and stays deterministic',
    () {
      final a = SplitCatalog.suggest(MuscleGroup.chest, all);
      final b = SplitCatalog.suggest(MuscleGroup.chest, all);
      expect(a.map((r) => r.exerciseId), b.map((r) => r.exerciseId));
      expect(a.first.exerciseId, 'bench_press');
      // Subset catalog: only what's there.
      final sub = all
          .where((e) => {'dips', 'cable_fly'}.contains(e.id))
          .toList();
      expect(
        SplitCatalog.suggest(
          MuscleGroup.chest,
          sub,
        ).map((r) => r.exerciseId).toSet(),
        {'dips', 'cable_fly'},
      );
    },
  );

  test(
    'reasonFor: curated lines win, other built-ins get a derived line, unknown is null',
    () {
      expect(
        SplitCatalog.reasonFor('bench_press'),
        startsWith('The main flat press'),
      );
      expect(SplitCatalog.reasonFor('pec_deck'), contains('mid chest'));
      expect(SplitCatalog.reasonFor('ghost'), isNull);
      for (final e in all) {
        expect(SplitCatalog.reasonFor(e.id), isNotNull, reason: e.id);
      }
    },
  );
}
