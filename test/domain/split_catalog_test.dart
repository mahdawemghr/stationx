import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  final all = seedExercises();
  final ids = {for (final e in all) e.id};

  test('common exercises exist, are unique and cover every muscle', () {
    final ids2 = SplitCatalog.commonExerciseIds;
    expect(ids2.toSet().length, ids2.length);
    expect(ids2.length, inInclusiveRange(20, 40));
    for (final id in ids2) {
      expect(ids, contains(id));
      expect(SplitCatalog.isCommon(id), isTrue);
    }
    expect(SplitCatalog.isCommon('ghost'), isFalse);
    final muscles = {
      for (final e in all)
        if (SplitCatalog.isCommon(e.id)) e.primaryMuscle,
    };
    expect(muscles, containsAll(MuscleGroup.values));
    // Every library section muscle (incl. Forearms, which shares MuscleGroup.biceps) has a common lift.
    final sections = {
      for (final e in all)
        if (SplitCatalog.isCommon(e.id))
          SectionMuscle.of(MuscleProfiles.of(e).primaryRegion),
    };
    expect(sections, containsAll(SectionMuscle.values));
  });

  test('seed ids are unique', () => expect(ids.length, all.length));

  test('seed names are unique (case/spacing/punctuation-insensitive)', () {
    final names = [
      for (final e in all)
        e.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''),
    ];
    expect(names.toSet().length, names.length);
  });

  test('no built-in section is overcrowded (sub-sections stay usable)', () {
    for (final m in MuscleGroup.values) {
      for (final g in SplitCatalog.grouped(m, all)) {
        expect(g.exercises.length, lessThanOrEqualTo(13), reason: g.section.id);
      }
    }
  });

  test(
    'every preset exercise exists, matches its day muscles, and days are valid',
    () {
      for (final p in SplitCatalog.presets) {
        expect(p.days, isNotEmpty, reason: p.id);
        expect(ScheduleBuilder.validate(p.days, all), isNull, reason: p.id);
        for (final d in p.days) {
          for (final r in d.exercises) {
            expect(ids, contains(r.exerciseId), reason: '${p.id}/${d.name}');
            final e = all.firstWhere((x) => x.id == r.exerciseId);
            expect(
              d.muscles,
              contains(e.primaryMuscle),
              reason: '${p.id}/${d.name}/${e.id}',
            );
            expect(r.sets, inInclusiveRange(2, 5));
            expect(r.repMin, lessThanOrEqualTo(r.repMax));
          }
        }
      }
      expect(
        SplitCatalog.presets.map((p) => p.id).toSet().length,
        SplitCatalog.presets.length,
      );
    },
  );

  test(
    'no empty section; each seeded exercise lands in exactly one section',
    () {
      for (final m in MuscleGroup.values) {
        final secs = SplitCatalog.sectionsFor(m);
        expect(secs, isNotEmpty);
        final g = SplitCatalog.grouped(m, all);
        expect(g.length, secs.length, reason: '${m.name} has an empty section');
        for (final s in g) {
          expect(
            s.exercises.length,
            greaterThanOrEqualTo(2),
            reason: s.section.id,
          );
          for (final e in s.exercises) {
            expect(SplitCatalog.sectionIdOf(e), s.section.id);
          }
        }
        final grouped = [for (final s in g) ...s.exercises.map((e) => e.id)];
        final expected = all
            .where((e) => e.primaryMuscle == m)
            .map((e) => e.id)
            .toList();
        expect(grouped.toSet().length, grouped.length);
        expect(grouped.toSet(), expected.toSet());
      }
    },
  );

  test(
    'custom exercises go last in "Your exercises"; unmapped built-ins fall back, never dropped',
    () {
      final custom = Exercise(
        id: 'c1',
        name: 'Mine',
        primaryMuscle: MuscleGroup.back,
        equipment: Equipment.cable,
        isCustom: true,
      );
      final odd = Exercise(
        id: 'new_back_thing',
        name: 'Odd',
        primaryMuscle: MuscleGroup.back,
        equipment: Equipment.cable,
      );
      final g = SplitCatalog.grouped(MuscleGroup.back, [custom, odd, ...all]);
      expect(g.last.section.id, SplitCatalog.mineSectionId(MuscleGroup.back));
      expect(g.last.section.label, 'Your exercises');
      expect(g.last.exercises.map((e) => e.id), ['c1']);
      expect(
        SplitCatalog.sectionIdOf(custom),
        SplitCatalog.mineSectionId(MuscleGroup.back),
      );
      final lastBuiltIn = SplitCatalog.sectionsFor(MuscleGroup.back).last.id;
      expect(SplitCatalog.sectionIdOf(odd), lastBuiltIn);
      expect(
        g.expand((s) => s.exercises).map((e) => e.id),
        contains('new_back_thing'),
      );
      // Only custom exercises -> only the mine section.
      expect(SplitCatalog.grouped(MuscleGroup.core, [custom]), isEmpty);
    },
  );

  test(
    'suggest returns 2-4 existing picks per muscle with reasons, in order',
    () {
      for (final m in MuscleGroup.values) {
        final s = SplitCatalog.suggest(m, all);
        expect(s.length, inInclusiveRange(2, 4), reason: m.name);
        for (final r in s) {
          expect(all.firstWhere((e) => e.id == r.exerciseId).primaryMuscle, m);
          expect(
            SplitCatalog.reasonFor(r.exerciseId),
            isNotNull,
            reason: r.exerciseId,
          );
        }
        expect(SplitCatalog.suggest(m, const []), isEmpty);
      }
      expect(
        SplitCatalog.suggest(MuscleGroup.legs, all).first.exerciseId,
        'back_squat',
      );
    },
  );

  test(
    'reasonFor is null for unknown ids',
    () => expect(SplitCatalog.reasonFor('nope'), isNull),
  );
}
