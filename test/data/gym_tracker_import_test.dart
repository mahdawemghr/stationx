import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/data/import/exercise_aliases.dart';
import 'package:stationx/data/import/gym_tracker_import.dart';
import 'package:stationx/data/isar/isar_store.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/domain/domain.dart';

/// The fixture was produced by Gym Tracker's REAL exporter (see gym_tracker/docs/EXPORT_FORMAT.md):
/// 21 sessions (19 completed + 1 abandoned + 1 in progress), 374 sets, 23 exercises, a custom exercise,
/// notes, one PR, unit = lb, next workout day = 2.
final fixtureText = File('test/fixtures/gym_tracker_export_sample.json').readAsStringSync();
final fixture = jsonDecode(fixtureText) as Map<String, dynamic>;

GymTrackerImportPlan planFor(String text, {MemoryStore? store}) {
  final s = store ?? MemoryStore(SeedData.fresh());
  return GymTrackerImport.plan(
    text,
    existingSessionIds: {for (final x in s.sessions.sessions) x.id},
    catalog: s.exercises.all,
    workouts: s.workouts.workouts,
    now: DateTime.utc(2026, 10, 8, 14),
  );
}

void main() {
  group('plan (nothing is changed)', () {
    test('real export: 19 completed workouts, all sets, unfinished ones skipped, exercises matched', () {
      final p = planFor(fixtureText);
      expect(p.sessions.length, 19);
      expect(p.sets, 374);
      expect(p.skippedNotCompleted, 2); // abandoned + in progress
      expect((p.skippedAlreadyImported, p.skippedInvalid), (0, 0));
      expect(p.firstDate!.isAtSameMomentAs(DateTime.utc(2026, 8, 3, 7, 30)), isTrue);
      expect(p.lastDate!.isAtSameMomentAs(DateTime.utc(2026, 9, 20, 9)), isTrue);
      expect(p.achievementsInFile, 1);
      // Same movements under different names are matched, not duplicated.
      // 18 since the catalogue grew to 212: "EZ-Bar Preacher Curl", "Hip Abduction
      // Machine" and "Seated Calf Raise" are now exact built-in names (some were custom/aliased).
      expect(p.matchedExercises, 18);
      expect(p.newExercises.map((e) => e.name).toSet(), {
        'Chest Press Machine', 'Dumbbell Chest Fly', 'Dumbbell Bicep Curl', 'Chest-Supported Row Machine',
        'Zercher Squat',
      });
    });

    test('exercise matching: exact names, curated aliases, and sensible custom exercises', () {
      final p = planFor(fixtureText);
      final ids = {for (final s in p.sessions) for (final l in s.exercises) l.exerciseId};
      for (final id in ['bench_press', 'incline_db_press', 'ez_preacher_curl', 'hip_abduction_machine', 'hammer_curl', 'lat_pulldown', 'seated_cable_row', 'straight_arm_pulldown', 'face_pull', 'tricep_pushdown', 'cable_oh_tri_ext', 'leg_press', 'leg_extension', 'leg_curl', 'lateral_raise']) {
        expect(ids, contains(id), reason: id);
      }
      final zercher = p.newExercises.singleWhere((e) => e.name == 'Zercher Squat');
      expect(zercher.id, 'gt_x_zerchersquat');
      expect(zercher.isCustom, isTrue);
      expect(zercher.primaryMuscle, MuscleGroup.legs); // "Quads"
      expect(zercher.secondaryMuscles, [MuscleGroup.back]); // "Glutes, Back" minus the primary group
      expect(zercher.equipment, Equipment.barbell);
      // Built-in now: matched to the catalogue id, not created as a custom exercise.
      expect(p.newExercises.where((e) => e.name == 'Hip Abduction Machine'), isEmpty);
      expect(p.newExercises.singleWhere((e) => e.name == 'Dumbbell Bicep Curl').primaryMuscle, MuscleGroup.biceps);
    });

    test('workouts map to StationX days by template name; rotation pointer is carried (Day 2)', () {
      final p = planFor(fixtureText);
      expect(p.sessions.where((s) => s.name == 'Chest + Biceps').every((s) => s.workoutId == 'w1'), isTrue);
      expect(p.sessions.where((s) => s.name == 'Back + Triceps').every((s) => s.workoutId == 'w2'), isTrue);
      expect(p.sessions.where((s) => s.name == 'Legs + Shoulders').every((s) => s.workoutId == 'w3'), isTrue);
      expect((p.rotationDay, p.rotationWorkoutId), (2, 'w2'));
    });

    test('dates: workoutDate = when it was started; createdAt = now; duration from start→finish; ids are stable', () {
      final first = planFor(fixtureText).sessions.first;
      expect(first.workoutDate.isAtSameMomentAs(DateTime.utc(2026, 8, 3, 7, 30)), isTrue);
      expect(first.meta.createdAt.isAtSameMomentAs(DateTime.utc(2026, 10, 8, 14)), isTrue);
      expect(first.meta.createdAt.isAtSameMomentAs(first.workoutDate), isFalse);
      expect(first.durationSeconds, 50 * 60);
      expect(first.id, matches(RegExp(r'^gt_s\d+$')));
      expect(first.meta.syncStatus, SyncStatus.pending); // will sync if the user has cloud sync on
    });

    test('sets: order, weights (kg, no unit conversion even though the file says lb) and reps are faithful', () {
      final raw = (fixture['sessions'] as List).cast<Map>().firstWhere((s) => s['status'] == 'completed');
      final firstEx = (raw['exercises'] as List).cast<Map>().first;
      final firstSets = (firstEx['sets'] as List).cast<Map>();
      final imported = planFor(fixtureText).sessions.firstWhere((s) => s.id == 'gt_s${raw['id']}');
      final log = imported.exercises.first;
      expect(log.sets.map((s) => s.weightKg), [for (final s in firstSets) (s['weightKg'] as num).toDouble()]);
      expect(log.sets.map((s) => s.reps), [for (final s in firstSets) s['reps']]);
      expect(log.sets.every((s) => s.done), isTrue);
      expect((fixture['settings'] as Map)['weightUnit'], 'lb'); // display preference only
    });

    test('exercise notes are kept in the workout notes', () {
      final withNote = planFor(fixtureText).sessions.where((s) => s.notes.contains('felt strong')).toList();
      expect(withNote, isNotEmpty);
      expect(withNote.first.notes, startsWith('Imported from Gym Tracker'));
    });

    test('planning never changes the app data', () {
      final store = MemoryStore(SeedData.fresh());
      planFor(fixtureText, store: store);
      expect(store.sessions.sessions, isEmpty);
      expect(store.exercises.all.every((e) => !e.isCustom), isTrue);
      expect(store.workouts.rotation.currentIndex, 0);
    });
  });

  group('aliases', () {
    final catalog = SeedData.fresh().exercises;
    final ids = {for (final e in catalog) e.id};

    test('every alias targets an exercise that exists in the built-in catalogue', () {
      gymTrackerAliases.forEach((name, id) => expect(ids, contains(id), reason: '$name -> $id'));
    });

    test('keys are normalised and no alias shadows an exact built-in name', () {
      final exact = {for (final e in catalog) normalizeExerciseName(e.name): e.id};
      expect(gymTrackerAliases.keys.where((k) => normalizeExerciseName(k) != k), isEmpty, reason: 'keys not normalised');
      expect(gymTrackerAliases.keys.where(exact.containsKey), isEmpty, reason: 'redundant aliases (exact name exists)');
    });

    test('exact match wins over alias; new aliases resolve', () {
      expect(planFor(_oneExercise('EZ-Bar Preacher Curl')).sessions.single.exercises.single.exerciseId, 'ez_preacher_curl');
      expect(planFor(_oneExercise('Reverse Hyper')).sessions.single.exercises.single.exerciseId, 'reverse_hyperextension');
      expect(planFor(_oneExercise('Woodchopper')).sessions.single.exercises.single.exerciseId, 'cable_woodchop');
    });
  });

  group('apply', () {
    test('adds the workouts and custom exercises; history, volume and PRs show up', () async {
      final store = MemoryStore(SeedData.fresh());
      final plan = planFor(fixtureText, store: store);
      final r = await GymTrackerImport.apply(plan, exercises: store.exercises, sessions: store.sessions, workouts: store.workouts);
      expect((r.sessionsAdded, r.exercisesCreated, r.rotationApplied), (19, 5, false));
      expect(store.sessions.sessions.length, 19);
      expect(store.exercises.all.where((e) => e.isCustom).length, 5);
    for (final e in store.exercises.all.where((e) => e.isCustom)) {
      expect(e.muscleTargets, isNotNull, reason: e.name);
      expect(e.muscleTargets!.first.role, TargetRole.primary);
    }
      expect(store.sessions.sessions.first.workoutDate.isAfter(store.sessions.sessions.last.workoutDate), isTrue); // newest first
      expect(VolumeService.totalSets(store.sessions.sessions), 374);
      // PRs/e1RM come from the existing domain services over the imported history.
      final pr = PrService.forExercise('bench_press', store.sessions.sessions)[PrType.estimated1Rm];
      expect(pr, isNotNull);
      expect(pr!.value, greaterThan(0));
      expect(store.sessions.lastWithExercise('lat_pulldown'), isNotNull); // "previous performance" works
    });

    test('is idempotent: importing the same file again adds nothing', () async {
      final store = MemoryStore(SeedData.fresh());
      await GymTrackerImport.apply(planFor(fixtureText, store: store), exercises: store.exercises, sessions: store.sessions, workouts: store.workouts);
      final again = planFor(fixtureText, store: store);
      expect(again.sessions, isEmpty);
      expect(again.skippedAlreadyImported, 19);
      expect(again.newExercises, isEmpty); // custom exercises from the first run are found again
      final r = await GymTrackerImport.apply(again, exercises: store.exercises, sessions: store.sessions, workouts: store.workouts);
      expect((r.sessionsAdded, r.exercisesCreated), (0, 0));
      expect(store.sessions.sessions.length, 19);
    });

    test('never touches existing data; sessions already in StationX stay exactly as they were', () async {
      final store = MemoryStore(SeedData.demo());
      final before = store.sessions.sessions.length;
      final beforeIds = store.sessions.sessions.map((s) => s.id).toSet();
      final workoutsBefore = store.workouts.workouts.map((w) => w.name).toList();
      final r = await GymTrackerImport.apply(planFor(fixtureText, store: store), exercises: store.exercises, sessions: store.sessions, workouts: store.workouts);
      expect(store.sessions.sessions.length, before + 19);
      expect(beforeIds.every((id) => store.sessions.byId(id) != null), isTrue);
      expect(store.workouts.workouts.map((w) => w.name).toList(), workoutsBefore);
      expect(r.sessionsAdded, 19);
    });

    test('rotation only changes when asked (Day 2 → StationX "Back + Triceps")', () async {
      final a = MemoryStore(SeedData.fresh());
      await GymTrackerImport.apply(planFor(fixtureText, store: a), exercises: a.exercises, sessions: a.sessions, workouts: a.workouts);
      expect(a.workouts.rotation.currentIndex, 0);
      final b = MemoryStore(SeedData.fresh());
      final r = await GymTrackerImport.apply(planFor(fixtureText, store: b), exercises: b.exercises, sessions: b.sessions, workouts: b.workouts, applyRotation: true);
      expect(r.rotationApplied, isTrue);
      expect(b.workouts.rotation.currentIndex, 1);
      expect(b.workouts.currentWorkout!.name, 'Back + Triceps');
    });

    test('notifies listeners once for the whole batch, not once per workout', () async {
      final store = MemoryStore(SeedData.fresh());
      var n = 0;
      store.sessions.addListener(() => n++);
      await GymTrackerImport.apply(planFor(fixtureText, store: store), exercises: store.exercises, sessions: store.sessions, workouts: store.workouts);
      expect(n, 1);
    });
  });

  group('bad input', () {
    test('not JSON', () => expect(() => planFor('this is not json'), throwsA(isA<ImportException>().having((e) => e.problem, 'problem', ImportProblem.notJson))));
    test('JSON but not a Gym Tracker export', () {
      expect(() => planFor('{"hello":"world"}'), throwsA(isA<ImportException>().having((e) => e.problem, 'problem', ImportProblem.wrongFormat)));
      expect(() => planFor('[1,2,3]'), throwsA(isA<ImportException>().having((e) => e.problem, 'problem', ImportProblem.wrongFormat)));
      // A StationX/other export must not be mistaken for it.
      expect(() => planFor('{"format":"stationx_export","version":1}'), throwsA(isA<ImportException>().having((e) => e.problem, 'problem', ImportProblem.wrongFormat)));
    });
    test('newer or missing version is refused with a clear reason', () {
      expect(() => planFor('{"format":"gym_tracker_export","version":2}'), throwsA(isA<ImportException>().having((e) => e.problem, 'problem', ImportProblem.unsupportedVersion)));
      expect(() => planFor('{"format":"gym_tracker_export"}'), throwsA(isA<ImportException>().having((e) => e.problem, 'problem', ImportProblem.unsupportedVersion)));
      expect(() => planFor('{"format":"gym_tracker_export","version":"1"}'), throwsA(isA<ImportException>().having((e) => e.problem, 'problem', ImportProblem.unsupportedVersion)));
    });
    test('oversized input is refused', () {
      expect(() => planFor('x' * (GymTrackerImport.maxBytes + 1)), throwsA(isA<ImportException>().having((e) => e.problem, 'problem', ImportProblem.tooLarge)));
    });
    test('limit is 10 MB measured in UTF-8 bytes (multi-byte text counts for what it weighs)', () {
      expect(GymTrackerImport.maxBytes, 10 * 1024 * 1024);
      // 2.5M chars of 4-byte emoji = 10M bytes + a little: shorter than maxBytes in chars, larger in bytes.
      final big = '\u{1F600}' * 2700000;
      expect(big.length, lessThan(GymTrackerImport.maxBytes));
      expect(GymTrackerImport.exceedsLimit(big), isTrue);
      expect(GymTrackerImport.exceedsLimit('{"a":1}'), isFalse);
      expect(() => planFor(big), throwsA(isA<ImportException>().having((e) => e.problem, 'problem', ImportProblem.tooLarge)));
    });

    test('planAsync matches plan, refuses oversize, and decodes large input off the UI isolate', () async {
      final store = MemoryStore(SeedData.fresh());
      Future<GymTrackerImportPlan> go(String t) => GymTrackerImport.planAsync(t,
          existingSessionIds: const {}, catalog: store.exercises.all, workouts: store.workouts.workouts, now: DateTime.utc(2026, 10, 8, 14));
      final small = await go(fixtureText);
      expect(small.sessions.length, 19);
      await expectLater(go('x' * (GymTrackerImport.maxBytes + 1)), throwsA(isA<ImportException>()));
      // Above the isolate threshold: pad with a large ignored field. Same result, computed in an isolate.
      final padded = jsonEncode({...fixture, 'padding': 'p' * (GymTrackerImport.isolateThresholdChars + 10)});
      final viaIsolate = await go(padded);
      expect(viaIsolate.sessions.length, 19);
      expect(viaIsolate.sets, 374);
      await expectLater(go('{not json' * 40000), throwsA(isA<ImportException>().having((e) => e.problem, 'problem', ImportProblem.notJson)));
    });

    test('hostile input is clamped to the server limits and never throws', () {
      final long = 'N' * 100000;
      final doc = {
        'format': 'gym_tracker_export',
        'version': 1,
        'exercises': [
          {'name': long, 'primaryMuscles': 'Chest' * 5000, 'secondaryMuscles': 'Back,' * 5000},
        ],
        'sessions': [
          {
            'id': 1,
            'status': 'completed',
            'startedAt': '2026-09-01T10:00:00Z',
            'templateName': long,
            'exercises': [
              for (var i = 0; i < 150; i++)
                {
                  'orderIndex': i,
                  'exerciseName': i == 0 ? long : 'Exercise number $i ${'z' * 400}',
                  'note': 'n' * 20000,
                  'sets': [
                    for (var k = 0; k < 60; k++) {'setNumber': k, 'weightKg': 20.0, 'reps': 5},
                    {'weightKg': 1e300, 'reps': 5}, // absurd weight: dropped
                    {'weightKg': 20, 'reps': 99999999}, // absurd reps: dropped
                  ],
                },
            ],
          },
          {'id': 2, 'status': 'completed', 'startedAt': '+275760-09-13T00:00:00Z', 'exercises': []}, // unrepresentable date
          {'id': 3, 'status': 'completed', 'startedAt': '0001-01-01T00:00:00Z', 'exercises': []},
          {'id': 4, 'status': 'completed', 'startedAt': '2026-09-02T10:00:00Z', 'templateName': 7, 'exercises': [{'exerciseName': 5, 'sets': 'nope'}]},
          'garbage',
        ],
      };
      final p = planFor(jsonEncode(doc));
      expect(p.sessions.length, 1);
      final s = p.sessions.single;
      expect(s.name.length, lessThanOrEqualTo(GymTrackerImport.maxNameLength));
      expect(s.notes.length, lessThanOrEqualTo(GymTrackerImport.maxNotesLength));
      expect(s.exercises.length, GymTrackerImport.maxExercisesPerSession);
      expect(s.exercises.every((l) => l.sets.length == GymTrackerImport.maxSetsPerExercise), isTrue);
      expect(p.newExercises, isNotEmpty);
      for (final e in p.newExercises) {
        expect(e.name.length, lessThanOrEqualTo(GymTrackerImport.maxNameLength));
        expect(e.id.length, lessThanOrEqualTo(100), reason: 'server id limit');
      }
      for (final l in s.exercises) {
        expect(l.exerciseId.length, lessThanOrEqualTo(100));
      }
      expect(p.skippedInvalid, 4); // two bad dates, the junk-typed one, and 'garbage'
    });

    test('wrongly typed structure is a friendly ImportException, not a crash', () {
      for (final doc in [
        '{"format":"gym_tracker_export","version":1,"sessions":{"a":1}}',
        '{"format":"gym_tracker_export","version":1,"sessions":[{"id":1,"status":"completed","startedAt":"2026-09-01T10:00:00Z","exercises":[{"exerciseName":"Bench Press","orderIndex":"x","sets":[{"weightKg":"5","reps":3}]}]}]}',
        '{"format":"gym_tracker_export","version":1,"exercises":"nope","settings":5,"achievements":{}}',
      ]) {
        expect(() => planFor(doc), returnsNormally, reason: doc);
      }
      expect('['.padLeft(200000, '[').length, 200000);
      expect(() => planFor('['.padLeft(200000, '[')), throwsA(isA<ImportException>()));
    });

    test('a valid file with no completed workouts yields an empty plan (not an error)', () {
      final p = planFor(jsonEncode({'format': 'gym_tracker_export', 'version': 1, 'sessions': [], 'exercises': []}));
      expect(p.isEmpty, isTrue);
    });

    test('damaged entries are skipped individually; the rest still import', () {
      final doc = {
        'format': 'gym_tracker_export',
        'version': 1,
        'exercises': [],
        'sessions': [
          'garbage',
          {'id': 1, 'status': 'completed', 'startedAt': 'not a date', 'exercises': []},
          {'id': 2, 'status': 'completed', 'startedAt': '2026-01-01T10:00:00Z', 'exercises': []}, // no sets at all
          {
            'id': 3, 'status': 'completed', 'startedAt': '2026-01-02T10:00:00Z', 'completedAt': '2026-01-02T11:00:00Z', 'templateDay': 9, 'templateName': 'Mystery Day',
            'exercises': [
              {'exerciseName': 'Bench Press', 'orderIndex': 1, 'sets': [
                {'setNumber': 1, 'weightKg': -5, 'reps': 8}, // negative weight
                {'setNumber': 2, 'weightKg': 60, 'reps': 0}, // zero reps
                {'setNumber': 3, 'weightKg': 'heavy', 'reps': 8}, // wrong type
                {'setNumber': 4, 'weightKg': 62.5, 'reps': 6}, // the only valid set
                {'setNumber': 5, 'weightKg': 0, 'reps': 12}, // bodyweight set is valid
              ]},
              {'exerciseName': '   ', 'sets': [{'setNumber': 1, 'weightKg': 10, 'reps': 10}]}, // unnamed exercise
              'also garbage',
            ],
          },
          {'id': 'x', 'status': 'completed', 'startedAt': '2026-01-03T10:00:00Z'},
          {'id': 5, 'status': 'completed', 'startedAt': '2026-01-04T10:00:00Z', 'completedAt': '2025-01-01T00:00:00Z',
            'exercises': [{'exerciseName': 'Lat Pulldown', 'sets': [{'setNumber': 1, 'weightKg': 40, 'reps': 10}]}]}, // finish before start
        ],
      };
      final p = planFor(jsonEncode(doc));
      expect(p.sessions.map((s) => s.id), ['gt_s3', 'gt_s5']);
      expect(p.skippedInvalid, 4); // 'garbage', bad date, no sets, non-numeric id (counted, never thrown)
      final s3 = p.sessions.first;
      expect(s3.exercises.single.sets.map((s) => (s.weightKg, s.reps)), [(62.5, 6), (0.0, 12)]);
      expect(s3.workoutId, 'w1'); // unknown day/name falls back to the first workout
      expect(s3.name, 'Mystery Day');
      expect(p.sessions.last.durationSeconds, 0); // impossible duration dropped
    });

    test('custom exercises get real muscle targets (hamstring/glute/calf/quad), unknown ones are flagged', () {
      Map<String, Object?> ex(String name, [String? primary, String? secondary]) =>
          {'name': name, 'primaryMuscles': ?primary, 'secondaryMuscles': ?secondary};
      final names = ['Seated Leg Curl Zz', 'Hip Thrust Zz', 'Standing Calf Raise Zz', 'Zz Quad Thing', 'Rear Delt Zz', 'Mystery Move Zz'];
      final doc = {
        'format': 'gym_tracker_export', 'version': 1,
        'exercises': [
          ex(names[0]), ex(names[1]), ex(names[2]), ex(names[3], 'Quads', 'Glutes'),
          ex(names[4], 'Rear Delts, Traps'), ex(names[5]),
        ],
        'sessions': [
          {'id': 1, 'status': 'completed', 'startedAt': '2026-01-01T10:00:00Z', 'exercises': [
            for (final n in names) {'exerciseName': n, 'sets': [{'setNumber': 1, 'weightKg': 10, 'reps': 5}]},
          ]},
        ],
      };
      final p = planFor(jsonEncode(doc));
      MuscleTarget primaryOf(String n) =>
          p.newExercises.singleWhere((e) => e.name == n).muscleTargets!.firstWhere((t) => t.role == TargetRole.primary);
      expect(primaryOf(names[0]).region, MuscleRegion.hamstrings);
      expect(primaryOf(names[1]).region, MuscleRegion.glutes);
      expect(primaryOf(names[2]).region, MuscleRegion.calves);
      expect(primaryOf(names[3]).region, MuscleRegion.quadriceps);
      expect(p.newExercises.singleWhere((e) => e.name == names[3]).muscleTargets!.last.region, MuscleRegion.glutes);
      expect(primaryOf(names[4]).muscle, Muscle.rearDelts);
      expect(p.newExercises.singleWhere((e) => e.name == names[4]).muscleTargets!.last.muscle, Muscle.traps);
      expect(p.needsReview, [names[5]]);
      // Idempotent: second plan with the new exercises in the catalog creates nothing and flags nothing.
      final store = MemoryStore(SeedData.fresh());
      final again = GymTrackerImport.plan(jsonEncode(doc),
          existingSessionIds: {}, catalog: [...store.exercises.all, ...p.newExercises], workouts: store.workouts.workouts);
      expect(again.newExercises, isEmpty);
    });

    test('a hostile name cannot create an invalid id or crash', () {
      final doc = {
        'format': 'gym_tracker_export', 'version': 1,
        'exercises': [{'name': '../../etc/passwd <script>', 'primaryMuscles': 'Chest'}],
        'sessions': [
          {'id': 1, 'status': 'completed', 'startedAt': '2026-01-01T10:00:00Z',
            'exercises': [{'exerciseName': '../../etc/passwd <script>', 'sets': [{'setNumber': 1, 'weightKg': 10, 'reps': 5}]}]},
        ],
      };
      final p = planFor(jsonEncode(doc));
      expect(p.newExercises.single.id, 'gt_x_etcpasswdscript');
      expect(p.newExercises.single.primaryMuscle, MuscleGroup.chest);
    });
  });

  test('persistence: an import into the real Isar store survives a restart, in one batched write', () async {
    await Isar.initializeIsarCore(download: true);
    final dir = Directory.systemTemp.createTempSync('stationx_import');
    addTearDown(() => dir.deleteSync(recursive: true));
    var store = await IsarStore.open(directory: dir.path, name: 'imp');
    final plan = GymTrackerImport.plan(fixtureText,
        existingSessionIds: {for (final s in store.sessions.sessions) s.id}, catalog: store.exercises.all, workouts: store.workouts.workouts);
    final r = await GymTrackerImport.apply(plan, exercises: store.exercises, sessions: store.sessions, workouts: store.workouts, applyRotation: true);
    expect((r.sessionsAdded, r.exercisesCreated), (19, 5));
    await store.close();
    store = await IsarStore.open(directory: dir.path, name: 'imp');
    expect(store.sessions.sessions.length, 19);
    expect(store.exercises.all.where((e) => e.isCustom).length, 5);
    expect(store.workouts.rotation.currentIndex, 1);
    final s = store.sessions.byId(plan.sessions.first.id)!;
    expect(s.workoutDate.isAtSameMomentAs(DateTime.utc(2026, 8, 3, 7, 30)), isTrue);
    expect(s.meta.createdAt.isAfter(DateTime.utc(2026, 10)), isTrue); // entered now ≠ trained in August
    expect(s.exercises.isNotEmpty && s.exercises.first.sets.isNotEmpty, isTrue);
    // Re-import after restart: still idempotent.
    final again = GymTrackerImport.plan(fixtureText,
        existingSessionIds: {for (final x in store.sessions.sessions) x.id}, catalog: store.exercises.all, workouts: store.workouts.workouts);
    expect(again.sessions, isEmpty);
    await store.close();
  });
}

String _oneExercise(String name) => jsonEncode({
      'format': 'gym_tracker_export',
      'version': 1,
      'sessions': [
        {
          'id': 1, 'status': 'completed', 'startedAt': '2026-09-01T10:00:00Z', 'completedAt': '2026-09-01T11:00:00Z',
          'exercises': [
            {'exerciseName': name, 'orderIndex': 0, 'sets': [{'setNumber': 1, 'weightKg': 10, 'reps': 5}]},
          ],
        },
      ],
    });
