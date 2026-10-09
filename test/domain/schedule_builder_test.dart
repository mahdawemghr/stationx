import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/data/isar/isar_store.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/domain/domain.dart';

WorkoutSession _session(String id, String workoutId) => WorkoutSession(
  id: id,
  workoutId: workoutId,
  name: 'x',
  workoutDate: DateTime(2026, 1, 1),
  exercises: const [],
);

void main() {
  final catalog = seedExercises();
  SplitDayPlan day(String name, [List<String> ids = const ['bench_press']]) =>
      SplitDayPlan(
        name: name,
        muscles: const [MuscleGroup.chest],
        exercises: [for (final i in ids) RoutineExercise(exerciseId: i)],
      );

  group('validate', () {
    test('rejects empty, blank, duplicate and exercise-less days', () {
      expect(ScheduleBuilder.validate(const [], catalog), isNotNull);
      expect(ScheduleBuilder.validate([day('  ')], catalog), contains('name'));
      expect(
        ScheduleBuilder.validate([day('Push'), day('push')], catalog),
        contains('Two days'),
      );
      expect(
        ScheduleBuilder.validate([day('Push', const [])], catalog),
        contains('no exercises'),
      );
      expect(
        ScheduleBuilder.validate([
          day('Push', const ['ghost']),
        ], catalog),
        contains('no exercises'),
      );
      expect(
        ScheduleBuilder.validate([
          day('Push'),
          day('Pull', const ['pullup']),
        ], catalog),
        isNull,
      );
    });
    test('save throws on invalid input', () async {
      final seed = SeedData.fresh();
      expect(
        ScheduleBuilder.save(
          const [],
          workouts: MemoryWorkoutRepository(seed.workouts, seed.rotation),
          sessions: MemorySessionRepository(const []),
          catalog: catalog,
          stamp: 's',
        ),
        throwsArgumentError,
      );
    });
  });

  group('save (memory)', () {
    late MemoryWorkoutRepository workouts;
    late MemorySessionRepository sessions;
    setUp(() {
      final seed = SeedData.fresh();
      workouts = MemoryWorkoutRepository(
        seed.workouts,
        const Rotation(workoutIds: ['w1', 'w2', 'w3'], currentIndex: 2),
      );
      sessions = MemorySessionRepository(const []);
    });

    Future<ScheduleSaveResult> go(
      List<SplitDayPlan> d, {
      String stamp = 's1',
      MemorySessionRepository? s,
    }) => ScheduleBuilder.save(
      d,
      workouts: workouts,
      sessions: s ?? sessions,
      catalog: catalog,
      stamp: stamp,
    );

    test(
      'creates workouts, sets rotation to index 0, archives (never deletes) old ones',
      () async {
        final before = workouts.workouts.map((w) => w.id).toList();
        final oldRotation = [...workouts.rotation.workoutIds];
        final r = await go([
          day('Push'),
          day('Pull', const ['pullup', 'ghost']),
        ]);
        expect(r.workoutIds, ['w_s1_0', 'w_s1_1']);
        expect(r.archivedOld, oldRotation);
        expect(workouts.rotation.workoutIds, r.workoutIds);
        expect(workouts.rotation.currentIndex, 0);
        for (final id in before) {
          expect(workouts.byId(id), isNotNull, reason: id);
        }
        expect(workouts.workouts.length, before.length + 2);
        expect(workouts.byId('w_s1_1')!.exercises.map((e) => e.exerciseId), [
          'pullup',
        ]);
      },
    );

    test(
      'leaves history intact and workouts outside the rotation alone',
      () async {
        final s = MemorySessionRepository([_session('a', 'w1')]);
        final r = await go([day('Push')], s: s);
        expect(s.sessions.map((x) => x.id), ['a']);
        expect(workouts.byId('w1'), isNotNull);
        expect(r.archivedOld, ['w1', 'w2', 'w3']);
        expect(workouts.rotation.workoutIds, ['w_s1_0']);
      },
    );

    test(
      'save arranges each day: merged muscles, main first, chosen muscle order',
      () async {
        await go([
          SplitDayPlan(
            name: 'Mixed',
            muscles: const [MuscleGroup.biceps, MuscleGroup.chest],
            exercises: [
              for (final i in [
                'cable_fly',
                'barbell_curl',
                'incline_db_press',
                'bench_press',
                'hammer_curl',
              ])
                RoutineExercise(exerciseId: i),
            ],
          ),
        ]);
        expect(workouts.byId('w_s1_0')!.exercises.map((e) => e.exerciseId), [
          'barbell_curl',
          'hammer_curl',
          'bench_press',
          'incline_db_press',
          'cable_fly',
        ]);
      },
    );

    test('presets are saved arranged (one section per muscle)', () async {
      final days = [
        for (final p in SplitCatalog.presets)
          for (final d in p.days) d.copyWith(name: '${p.id}/${d.name}'),
      ];
      await go(days);
      for (var i = 0; i < days.length; i++) {
        final saved = workouts.byId('w_s1_$i')!.exercises;
        expect(
          WorkoutSections.isArranged(saved, catalog),
          isTrue,
          reason: days[i].name,
        );
        expect(
          saved.length,
          days[i].exercises
              .where((e) => catalog.any((c) => c.id == e.exerciseId))
              .length,
        );
      }
    });

    test('restore puts an archived workout at the end, once', () async {
      await go([day('Push')]);
      await ScheduleBuilder.restore('w2', workouts);
      expect(workouts.rotation.workoutIds, ['w_s1_0', 'w2']);
      await ScheduleBuilder.restore('w2', workouts);
      await ScheduleBuilder.restore('w_s1_0', workouts);
      await ScheduleBuilder.restore('ghost', workouts);
      expect(workouts.rotation.workoutIds, ['w_s1_0', 'w2']);
      expect(workouts.rotation.currentIndex, 0);
    });

    test('idempotent for the same stamp', () async {
      await go([
        day('Push'),
        day('Pull', const ['pullup']),
      ]);
      final r = await go([
        day('Push'),
        day('Pull', const ['pullup']),
      ]);
      expect(r.archivedOld, isEmpty);
      expect(
        workouts.workouts.map((w) => w.id),
        containsAll(['w_s1_0', 'w_s1_1']),
      );
      expect(workouts.rotation.workoutIds, ['w_s1_0', 'w_s1_1']);
      expect(workouts.rotation.currentIndex, 0);
    });
  });

  group('save (Isar)', () {
    late Directory dir;
    setUpAll(() async => Isar.initializeIsarCore(download: true));
    setUp(
      () => dir = Directory.systemTemp.createTempSync('stationx_sched_test'),
    );
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('persists across a restart', () async {
      var s = await IsarStore.open(directory: dir.path, name: 'sched');
      await ScheduleBuilder.save(
        [
          day('Push'),
          day('Pull', const ['pullup']),
        ],
        workouts: s.workouts,
        sessions: s.sessions,
        catalog: s.exercises.all,
        stamp: 'k',
      );
      await s.close();
      s = await IsarStore.open(directory: dir.path, name: 'sched');
      expect(
        s.workouts.workouts.map((w) => w.id),
        containsAll(['w_k_0', 'w_k_1']),
      );
      expect(s.workouts.rotation.workoutIds, ['w_k_0', 'w_k_1']);
      expect(s.workouts.rotation.currentIndex, 0);
      await s.close();
    });

    test('archived workouts survive a restart and can be restored', () async {
      var s = await IsarStore.open(directory: dir.path, name: 'sched2');
      final oldIds = [...s.workouts.rotation.workoutIds];
      expect(oldIds, isNotEmpty);
      final r = await ScheduleBuilder.save(
        [day('Push')],
        workouts: s.workouts,
        sessions: s.sessions,
        catalog: s.exercises.all,
        stamp: 'k',
      );
      expect(r.archivedOld, oldIds);
      await s.close();
      s = await IsarStore.open(directory: dir.path, name: 'sched2');
      for (final id in oldIds) {
        expect(s.workouts.byId(id), isNotNull, reason: id);
      }
      await ScheduleBuilder.restore(oldIds.first, s.workouts);
      expect(s.workouts.rotation.workoutIds, ['w_k_0', oldIds.first]);
      await s.close();
    });
  });
}
