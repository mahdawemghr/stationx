import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/domain/domain.dart';

RoutineExercise r(String id) => RoutineExercise(exerciseId: id);

void main() {
  final seed = SeedData.fresh();
  final catalog = seed.exercises;
  List<String> ids(List<RoutineExercise> l) => [
    for (final e in l) e.exerciseId,
  ];
  List<String> labels(List<WorkoutSection> s) => [for (final x in s) x.label];

  test('Legs + Shoulders is exactly two sections', () {
    final s = WorkoutSections.group([
      r('back_squat'),
      r('leg_press'),
      r('overhead_press'),
      r('lateral_raise'),
      r('face_pull'),
    ], catalog);
    expect(labels(s), ['Legs', 'Shoulders']);
    expect(s[0].items.map((e) => e.exerciseId), ['back_squat', 'leg_press']);
    expect(s[1].items.length, 3);
    expect(s[1].startIndex, 2);
    expect(s[0].sets, 6);
  });

  test('hamstring/glute/calf exercises join the Legs section after quads', () {
    final s = WorkoutSections.group([
      r('back_squat'),
      r('calf_raise'),
      r('rdl'),
    ], catalog);
    expect(labels(s), ['Legs']);
    expect(ids(s.single.items), ['back_squat', 'rdl', 'calf_raise']);
    expect(
      [for (final g in s.single.groups) g.label],
      [null, 'Hamstrings', 'Calves'],
    );
    expect(s.single.groups.first.isMain, isTrue);
  });

  test(
    'legs: squat main, then lunges/quad iso, hamstrings, glutes, calves in order',
    () {
      final a = WorkoutSections.arrange([
        r('calf_raise'),
        r('hip_thrust'),
        r('rdl'),
        r('back_squat'),
      ], catalog);
      expect(ids(a), ['back_squat', 'rdl', 'hip_thrust', 'calf_raise']);
    },
  );

  test('non-contiguous input is merged into one section per muscle', () {
    final input = [r('bench_press'), r('lat_pulldown'), r('incline_db_press')];
    expect(labels(WorkoutSections.groupContiguous(input, catalog)), [
      'Chest',
      'Back',
      'Chest',
    ]);
    expect(labels(WorkoutSections.group(input, catalog)), ['Chest', 'Back']);
    expect(ids(WorkoutSections.arrange(input, catalog)), [
      'bench_press',
      'incline_db_press',
      'lat_pulldown',
    ]);
  });

  test(
    'chest: bench main -> incline (Upper) -> fly (Flyes), first appearance orders sections',
    () {
      final a = WorkoutSections.arrange([
        r('cable_fly'),
        r('incline_db_press'),
        r('bench_press'),
      ], catalog);
      expect(ids(a), ['bench_press', 'incline_db_press', 'cable_fly']);
      final s = WorkoutSections.group(a, catalog).single;
      expect(
        [for (final g in s.groups) g.label],
        [null, 'Upper chest', 'Flyes & isolation'],
      );
    },
  );

  test('chest: decline sits in Lower chest between Upper and Flyes', () {
    final a = WorkoutSections.arrange([
      r('cable_fly'),
      r('decline_bench_press'),
      r('incline_db_press'),
      r('bench_press'),
    ], catalog);
    expect(ids(a), [
      'bench_press',
      'incline_db_press',
      'decline_bench_press',
      'cable_fly',
    ]);
  });

  test(
    'back is ONE section: lats + upper back main, then traps, then lower back',
    () {
      final input = [
        r('back_extension'),
        r('barbell_shrug'),
        r('lat_pulldown'),
        r('seated_cable_row'),
      ];
      final s = WorkoutSections.group(input, catalog);
      expect(labels(s), ['Back']);
      expect(
        [for (final g in s.single.groups) g.label],
        [null, 'Traps', 'Lower back'],
      );
      expect(ids(s.single.groups.first.items), [
        'lat_pulldown',
        'seated_cable_row',
      ]);
    },
  );

  test('sets and startIndex span sub-groups', () {
    final s = WorkoutSections.group([
      r('bench_press'),
      r('squat_dummy_unknown'),
      r('back_squat'),
      r('incline_db_press'),
    ], catalog);
    expect(labels(s), ['Chest', 'Legs']);
    expect(s[1].startIndex, 2);
  });

  test('forearms is its own section (not biceps)', () {
    final s = WorkoutSections.group([
      r('barbell_curl'),
      r('wrist_curl'),
      r('farmers_carry'),
      r('dead_hang'),
    ], catalog);
    expect(labels(s), ['Biceps', 'Forearms']);
    expect(ids(s[1].items), ['wrist_curl', 'farmers_carry', 'dead_hang']);
    expect(s[1].groups.length, 1);
    expect(s[1].groups.single.isMain, isTrue);
  });

  test('muscleOrder wins over first appearance', () {
    final input = [r('barbell_curl'), r('bench_press')];
    expect(ids(WorkoutSections.arrange(input, catalog)), [
      'barbell_curl',
      'bench_press',
    ]);
    expect(
      ids(
        WorkoutSections.arrange(
          input,
          catalog,
          muscleOrder: [SectionMuscle.chest, SectionMuscle.biceps],
        ),
      ),
      ['bench_press', 'barbell_curl'],
    );
  });

  test('arrange is idempotent, stable, never drops or duplicates', () {
    final input = [
      for (final id in [
        'calf_raise',
        'cable_fly',
        'ghost',
        'barbell_curl',
        'bench_press',
        'rdl',
        'face_pull',
        'back_squat',
        'bench_press',
      ])
        r(id),
    ];
    final a = WorkoutSections.arrange(input, catalog);
    expect(a.length, input.length);
    expect(ids(a)..sort(), ids(input)..sort());
    expect(ids(WorkoutSections.arrange(a, catalog)), ids(a));
    expect(WorkoutSections.isArranged(a, catalog), isTrue);
    expect(WorkoutSections.isArranged(input, catalog), isFalse);
    expect(a.last.exerciseId, 'ghost'); // unknown ids last
  });

  test('unknown ids are skipped by group; empty input gives no sections', () {
    expect(WorkoutSections.group([r('nope')], catalog), isEmpty);
    expect(WorkoutSections.group(const [], catalog), isEmpty);
    expect(
      WorkoutSections.arrange([
        r('nope'),
        r('bench_press'),
      ], catalog).map((e) => e.exerciseId),
      ['bench_press', 'nope'],
    );
  });

  test('custom exercises: sectioned by targets, main after built-in mains', () {
    final custom = Exercise.custom(
      id: 'c1',
      name: 'My Wrist Thing',
      equipment: Equipment.dumbbell,
      targets: const [MuscleTarget.primary(MuscleRegion.forearms)],
    );
    final customChest = Exercise.custom(
      id: 'c2',
      name: 'My Press',
      equipment: Equipment.dumbbell,
      targets: const [MuscleTarget.primary(MuscleRegion.chest)],
    );
    final cat = [...catalog, custom, customChest];
    final a = WorkoutSections.arrange([
      r('cable_fly'),
      r('c2'),
      r('incline_db_press'),
      r('c1'),
      r('bench_press'),
    ], cat);
    expect(ids(a), [
      'bench_press',
      'c2',
      'incline_db_press',
      'cable_fly',
      'c1',
    ]);
    expect(labels(WorkoutSections.group(a, cat)), ['Chest', 'Forearms']);
  });

  test('insertionIndex lands in the canonical place', () {
    final cur = [r('bench_press'), r('cable_fly'), r('lat_pulldown')];
    expect(
      WorkoutSections.insertionIndex(cur, r('incline_db_press'), catalog),
      1,
    );
    expect(
      WorkoutSections.insertionIndex(cur, r('chest_dummy_main_press'), catalog),
      3,
    ); // unknown: end
    expect(
      WorkoutSections.insertionIndex(cur, r('db_bench_press'), catalog),
      1,
    ); // end of the chest main group
    expect(
      WorkoutSections.insertionIndex(cur, r('seated_cable_row'), catalog),
      3,
    );
    expect(
      WorkoutSections.insertionIndex(cur, r('barbell_curl'), catalog),
      3,
    ); // new muscle -> after existing
    expect(
      WorkoutSections.insertionIndex(const [], r('bench_press'), catalog),
      0,
    );
  });

  test('groupContiguous never reorders a draft and indexes the input', () {
    final draft = [r('bench_press'), r('lat_pulldown'), r('incline_db_press')];
    final s = WorkoutSections.groupContiguous(draft, catalog);
    expect([for (final x in s) x.startIndex], [0, 1, 2]);
  });

  test('sectionCount and showSectionHeaders', () {
    expect(
      WorkoutSections.sectionCount([
        r('bench_press'),
        r('incline_db_press'),
      ], catalog),
      1,
    );
    expect(
      WorkoutSections.showSectionHeaders(
        WorkoutSections.group([
          r('bench_press'),
          r('incline_db_press'),
        ], catalog),
      ),
      isFalse,
    );
    final five = [
      r('bench_press'),
      r('lat_pulldown'),
      r('overhead_press'),
      r('barbell_curl'),
      r('back_squat'),
    ];
    expect(WorkoutSections.sectionCount(five, catalog), 5);
    expect(
      WorkoutSections.showSectionHeaders(WorkoutSections.group(five, catalog)),
      isTrue,
    );
    final push = [
      r('bench_press'),
      r('overhead_press'),
      r('tricep_pushdown'),
      r('lateral_raise'),
    ];
    expect(WorkoutSections.sectionCount(push, catalog), 3);
  });

  test(
    'seeded workouts: w2 has Back, Triceps and a Shoulders (rear delt) section for Face Pull',
    () {
      final w = {for (final x in seed.workouts) x.id: x};
      expect(labels(WorkoutSections.group(w['w1']!.exercises, catalog)), [
        'Chest',
        'Biceps',
      ]);
      expect(labels(WorkoutSections.group(w['w2']!.exercises, catalog)), [
        'Back',
        'Triceps',
        'Shoulders',
      ]);
      expect(labels(WorkoutSections.group(w['w3']!.exercises, catalog)), [
        'Legs',
        'Shoulders',
      ]);
      final sh = WorkoutSections.group(w['w2']!.exercises, catalog).last;
      expect(sh.groups.single.label, 'Rear delts');
    },
  );

  test(
    'every curated section has a canonical position and main sections match mainSectionIds',
    () {
      for (final m in MuscleGroup.values) {
        for (final s in SplitCatalog.sectionsFor(m)) {
          expect(WorkoutSections.knowsSection(s.id), isTrue, reason: s.id);
        }
      }
      for (final id in WorkoutSections.mainSectionIds) {
        expect(WorkoutSections.knowsSection(id), isTrue, reason: id);
      }
      // For each exercise placed in its profile's own muscle: no sub-header <=> its section is a main one.
      var checked = 0;
      for (final e in catalog) {
        if (e.isCustom) continue;
        final sid = SplitCatalog.sectionIdOf(e);
        final sec = WorkoutSections.group([r(e.id)], catalog).single;
        final profileMuscle = SectionMuscle.of(
          MuscleProfiles.of(e).primaryRegion,
        );
        if (SplitCatalog.sectionsFor(
              e.primaryMuscle,
            ).every((s) => s.id != sid) ||
            profileMuscle.legacy != e.primaryMuscle) {
          continue; // placed by leaf in another muscle (e.g. Face Pull); covered by its own tests
        }
        expect(
          sec.groups.single.isMain,
          WorkoutSections.mainSectionIds.contains(sid),
          reason: '${e.id} / $sid',
        );
        checked++;
      }
      expect(checked, greaterThan(300));
    },
  );

  test(
    'split sub-areas keep ONE sub-header and the canonical order of their sections',
    () {
      final a = WorkoutSections.arrange([
        r('seated_calf_raise'),
        r('tibialis_raise'),
        r('calf_raise'),
        r('donkey_kick'),
        r('hip_thrust'),
        r('clamshell'),
        r('back_squat'),
      ], catalog);
      expect(ids(a), [
        'back_squat',
        'hip_thrust',
        'donkey_kick',
        'clamshell',
        'calf_raise',
        'seated_calf_raise',
        'tibialis_raise',
      ]);
      final s = WorkoutSections.group(a, catalog).single;
      expect([for (final g in s.groups) g.label], [null, 'Glutes', 'Calves']);
    },
  );

  test(
    'back: all lats and upper-back sections are main (no sub-header), traps after',
    () {
      final a = WorkoutSections.group([
        r('barbell_shrug'),
        r('straight_arm_pulldown'),
        r('inverted_row'),
        r('pullup'),
        r('seated_cable_row'),
      ], catalog).single;
      expect([for (final g in a.groups) g.label], [null, 'Traps']);
      expect(a.groups.first.items.length, 4);
    },
  );
}
