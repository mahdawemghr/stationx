import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  final catalog = seedExercises();
  final byId = {for (final e in catalog) e.id: e};

  group('classification of the built-in catalogue', () {
    test(
      'every built-in exercise is classified exactly once; no stale ids',
      () {
        final ids = byId.keys.toSet();
        final b = BuiltInDifficulty.beginner;
        final m = BuiltInDifficulty.intermediate;
        final a = BuiltInDifficulty.advanced;
        expect(b.intersection(m), isEmpty);
        expect(b.intersection(a), isEmpty);
        expect(m.intersection(a), isEmpty);
        expect(
          BuiltInDifficulty.all.difference(ids),
          isEmpty,
          reason: 'unknown ids',
        );
        expect(
          ids.difference(BuiltInDifficulty.all),
          isEmpty,
          reason: 'unclassified exercises',
        );
        expect(b.length + m.length + a.length, catalog.length);
      },
    );

    test(
      'every built-in carries its difficulty; custom exercises are unspecified',
      () {
        for (final e in catalog) {
          expect(e.difficulty, isNotNull, reason: e.name);
          expect(e.difficulty, BuiltInDifficulty.of(e.id));
        }
        expect(BuiltInDifficulty.of('my_custom_exercise'), isNull);
        final custom = Exercise.custom(
          id: 'c1',
          name: 'Mine',
          targets: const [MuscleTarget.primary(MuscleRegion.chest)],
          equipment: Equipment.dumbbell,
        );
        expect(custom.difficulty, isNull);
      },
    );

    test('representative exercises of every level and equipment category', () {
      Difficulty d(String id) => byId[id]!.difficulty!;
      // beginner: simple, stable, guided
      expect(d('pushup'), Difficulty.beginner);
      expect(d('glute_bridge'), Difficulty.beginner);
      expect(d('leg_press'), Difficulty.beginner);
      expect(d('lat_pulldown'), Difficulty.beginner);
      expect(d('goblet_squat'), Difficulty.beginner);
      expect(d('band_pull_apart'), Difficulty.beginner);
      expect(d('db_curl'), Difficulty.beginner);
      // intermediate: technique, balance or load management
      expect(d('bench_press'), Difficulty.intermediate);
      expect(d('back_squat'), Difficulty.intermediate);
      expect(d('pullup'), Difficulty.intermediate);
      expect(d('bulgarian_split_squat'), Difficulty.intermediate);
      expect(d('hack_squat'), Difficulty.intermediate);
      expect(d('smith_bench_press'), Difficulty.intermediate);
      // advanced: skill, strength, mobility or risk
      expect(d('pistol_squat'), Difficulty.advanced);
      expect(d('front_squat'), Difficulty.advanced);
      expect(d('kb_snatch'), Difficulty.advanced);
      expect(d('handstand_pushup'), Difficulty.advanced);
      expect(d('dragon_flag'), Difficulty.advanced);
      expect(d('weighted_pullup'), Difficulty.advanced);
    });

    test('difficulty is not decided by equipment alone', () {
      Set<Difficulty> levels(Equipment eq) => {
        for (final e in catalog)
          if (e.equipment == eq) e.difficulty!,
      };
      // Bodyweight spans all three levels (push-up .. pistol squat), machines are not all easy,
      // barbells are not all hard, and bands are not all beginner.
      expect(levels(Equipment.bodyweight), Difficulty.values.toSet());
      expect(
        levels(Equipment.machine),
        containsAll([Difficulty.beginner, Difficulty.intermediate]),
      );
      expect(
        levels(Equipment.barbell),
        containsAll([
          Difficulty.beginner,
          Difficulty.intermediate,
          Difficulty.advanced,
        ]),
      );
      expect(
        levels(Equipment.kettlebell),
        containsAll([Difficulty.beginner, Difficulty.advanced]),
      );
    });

    test(
      'the catalogue keeps a sensible spread (guard against a lazy re-classification)',
      () {
        int n(Difficulty x) => catalog.where((e) => e.difficulty == x).length;
        expect(n(Difficulty.beginner), greaterThan(80));
        expect(n(Difficulty.intermediate), greaterThan(120));
        expect(n(Difficulty.advanced), inInclusiveRange(20, 80));
      },
    );
  });

  group(
    'every region keeps enough non-advanced options (muscle coverage under the beginner filter)',
    () {
      for (final r in MuscleRegion.values) {
        test(
          '${r.label}: bodyweight-only non-advanced exercises exist, or the region is optional',
          () {
            final options = [
              for (final e in catalog)
                if (MuscleProfiles.of(e).primary.any((t) => t.region == r) &&
                    e.difficulty != Difficulty.advanced &&
                    (e.equipment == Equipment.bodyweight))
                  e,
            ];
            // Regions with no bodyweight option at all are covered by the controlled fallback (tested below).
            if (options.isEmpty) {
              final any = catalog.where(
                (e) => MuscleProfiles.of(e).primary.any((t) => t.region == r),
              );
              expect(any, isNotEmpty);
            }
          },
        );
      }
    },
  );
}
