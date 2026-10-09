import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  final all = AppController().exercises.all;
  final s = ExerciseSearch();
  List<String> names(String q) => [for (final e in s.search(all, q)) e.name];

  Exercise ex(
    String name, {
    MuscleGroup m = MuscleGroup.back,
    Equipment eq = Equipment.barbell,
    String? id,
  }) => Exercise(
    id: id ?? 'custom_${name.hashCode}',
    name: name,
    primaryMuscle: m,
    equipment: eq,
    isCustom: true,
  );

  test('empty query returns everything alphabetically', () {
    final r = names('');
    expect(r.length, all.length);
    final sorted = [...r]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    expect(r, sorted);
  });

  test(
    'case, spaces and hyphens are ignored; skull crusher == skullcrusher',
    () {
      final items = [ex('EZ-Bar Skullcrusher'), ex('Cable Row')];
      expect(s.search(items, 'skull crusher').map((e) => e.name), [
        'EZ-Bar Skullcrusher',
      ]);
      expect(s.search(items, 'SKULLCRUSHER').length, 1);
      expect(s.search(items, 'ez bar').length, 1);
      expect(s.search(items, 'cable-row').length, 1);
    },
  );

  test('every token must match (name, muscle, equipment)', () {
    final items = [
      ex('Row', m: MuscleGroup.back, eq: Equipment.cable),
      ex('Row', m: MuscleGroup.back, eq: Equipment.dumbbell, id: 'c2'),
      ex('Curl', m: MuscleGroup.biceps, eq: Equipment.cable, id: 'c3'),
    ];
    expect(s.search(items, 'cable back').map((e) => e.id), [items[0].id]);
    expect(s.search(items, 'cable dumbbell'), isEmpty);
    expect(s.search(items, 'biceps cable').map((e) => e.id), ['c3']);
  });

  test('synonyms: rdl, ohp, db, bb, kb, pulldown, chin up, skullcrusher', () {
    expect(names('rdl'), contains('Romanian Deadlift'));
    expect(
      names('ohp').any(
        (n) =>
            n.toLowerCase().contains('overhead press') ||
            n.toLowerCase().contains('shoulder press'),
      ),
      isTrue,
    );
    final db = s.search(all, 'db bench');
    expect(db, isNotEmpty);
    expect(
      db.every(
        (e) =>
            e.equipment == Equipment.dumbbell ||
            e.name.toLowerCase().contains('dumbbell'),
      ),
      isTrue,
    );
    expect(
      s
          .search(all, 'bb squat')
          .every(
            (e) =>
                e.equipment == Equipment.barbell ||
                e.name.toLowerCase().contains('barbell'),
          ),
      isTrue,
    );
    expect(s.search(all, 'pulldown'), isNotEmpty);
    final items = [ex('Chin-Up'), ex('Pull-Up', id: 'p')];
    expect(s.search(items, 'pull up').length, 2);
    expect(s.search(items, 'chin up').length, 2);
    final kb = [ex('Swing', eq: Equipment.kettlebell)];
    expect(s.search(kb, 'kb').length, 1);
    final lte = [ex('Lying Triceps Extension', m: MuscleGroup.triceps)];
    expect(s.search(lte, 'skullcrusher').length, 1);
  });

  test(
    'Arabic and transliterated forearm queries surface forearm exercises',
    () {
      final forearm = all
          .where(
            (e) =>
                SectionMuscle.of(MuscleProfiles.of(e).primaryRegion) ==
                SectionMuscle.forearms,
          )
          .toList();
      expect(forearm, isNotEmpty, reason: 'catalog has forearm exercises');
      for (final q in ['سواعد', 'sawaed', 'forearms', 'forearm']) {
        final r = s.search(all, q).toSet();
        expect(r.containsAll(forearm), isTrue, reason: q);
      }
    },
  );

  test(
    'ranking: exact > prefix > word match > muscle/equipment; alphabetical ties',
    () {
      final items = [
        ex('Zottman Curl', m: MuscleGroup.biceps, id: 'a'),
        ex('Hammer Curl', m: MuscleGroup.biceps, id: 'b'),
        ex('Curl', m: MuscleGroup.biceps, id: 'c'),
        ex('Curl Up', m: MuscleGroup.core, id: 'd'),
        ex(
          'Row',
          m: MuscleGroup.biceps,
          id: 'e',
        ), // matches "biceps" via muscle only
        ex('Reverse Curl', m: MuscleGroup.biceps, id: 'f'),
      ];
      expect(s.search(items, 'curl').map((e) => e.id), [
        'c',
        'd',
        'b',
        'f',
        'a',
      ]);
      expect(s.search(items, 'biceps').map((e) => e.id).toSet(), {
        'a',
        'b',
        'c',
        'e',
        'f',
      });
      // Name matches outrank muscle-only matches.
      final mixed = [
        ex('Row', m: MuscleGroup.back, id: 'x'),
        ex('Back Extension', m: MuscleGroup.back, id: 'y'),
      ];
      expect(s.search(mixed, 'back').first.id, 'y');
    },
  );

  test('search keys are memoised per exercise instance', () {
    final fresh = ExerciseSearch();
    final items = [ex('Alpha Row'), ex('Beta Row', id: 'b')];
    fresh.search(items, 'row');
    expect(fresh.keyBuilds, 2);
    fresh.search(items, 'alpha');
    fresh.search(items, 'beta row');
    expect(fresh.keyBuilds, 2);
    fresh.search([ex('Alpha Row', id: items[0].id)], 'row');
    expect(fresh.keyBuilds, 3);
  });

  test('no match returns empty; junk punctuation is tolerated', () {
    expect(s.search(all, 'zzzzqq'), isEmpty);
    expect(s.search(all, '---').length, all.length);
  });
}
