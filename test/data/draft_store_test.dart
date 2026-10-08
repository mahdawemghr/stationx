import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/isar/isar_store.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/sync/cloud_auth.dart';
import 'package:stationx/data/sync/cloud_sync_controller.dart';
import 'package:stationx/domain/domain.dart';

WorkoutDraft sample() => WorkoutDraft(
      workoutId: 'w2',
      workoutName: 'Back',
      startedAt: DateTime(2026, 5, 1, 10),
      savedAt: DateTime(2026, 5, 1, 10, 20),
      currentIndex: 1,
      notes: 'felt good',
      backdate: DateTime(2026, 4, 30),
      exercises: const [
        DraftExercise(exerciseId: 'lat_pulldown', repMin: 8, repMax: 12, expanded: true, suggestionUsed: true, sets: [
          DraftSet(weightKg: 47.5, reps: 10, done: true),
          DraftSet(weightKg: 50, reps: 8, done: false),
        ]),
      ],
    );

class SignedInAuth extends NoCloudAuth {
  @override
  CloudUser? get user => const CloudUser(id: 'u', email: 'a@b.co');
}

void main() {
  late Directory dir;
  setUpAll(() => Isar.initializeIsarCore(download: true));
  setUp(() => dir = Directory.systemTemp.createTempSync('stationx_draft_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('draft JSON round-trips every field', () {
    final store = MemoryWorkoutDraftStore();
    store.save(sample());
    final d = store.current!;
    expect(d.workoutId, 'w2');
    expect(d.startedAt, DateTime(2026, 5, 1, 10));
    expect(d.backdate, DateTime(2026, 4, 30));
    expect(d.currentIndex, 1);
    expect(d.notes, 'felt good');
    expect(d.exercises.single.sets[0].done, isTrue);
    expect(d.exercises.single.sets[1].weightKg, 50);
    expect(d.exercises.single.suggestionUsed, isTrue);
    expect(d.doneSets, 1);
    expect(d.totalSets, 2);
  });

  test('corrupt stored JSON reads as no draft', () {
    expect(MemoryWorkoutDraftStore('{not json').current, isNull);
    expect(MemoryWorkoutDraftStore('{"wid": 5}').current, isNull);
  });

  test('Isar: the draft survives a restart, is cleared by clear() and by replaceAll', () async {
    var s = await IsarStore.open(directory: dir.path, name: 'draft');
    expect(s.workoutDraft.current, isNull);
    await s.workoutDraft.save(sample());
    await s.close();

    s = await IsarStore.open(directory: dir.path, name: 'draft');
    final d = s.workoutDraft.current!;
    expect(d.workoutName, 'Back');
    expect(d.exercises.single.sets.length, 2);
    await s.workoutDraft.clear();
    await s.close();

    s = await IsarStore.open(directory: dir.path, name: 'draft');
    expect(s.workoutDraft.current, isNull);
    await s.workoutDraft.save(sample());
    await s.replaceAll(SeedData.fresh(), const UserProfile());
    expect(s.workoutDraft.current, isNull);
    await s.close();
    s = await IsarStore.open(directory: dir.path, name: 'draft');
    expect(s.workoutDraft.current, isNull);
    await s.close();
  });

  test('draft lives on AppMeta only: it never touches synced rows', () async {
    final s = await IsarStore.open(directory: dir.path, name: 'draft2');
    final pendingBefore = s.profile.profile;
    await s.workoutDraft.save(sample());
    expect(s.profile.profile.name, pendingBefore.name);
    await s.close();
  });

  group('demo data guards', () {
    test('refused while signed in to cloud (no change, returns false)', () async {
      final app = AppController(cloud: CloudSyncController(auth: SignedInAuth()));
      expect(app.canLoadDemo, isFalse);
      final before = app.sessions.sessions.length;
      expect(await app.loadDemoData(replaceExisting: true), isFalse);
      expect(app.sessions.sessions.length, before);
      app.dispose();
    });

    test('refused when real sessions exist unless explicitly replacing', () async {
      final app = AppController();
      expect(await app.loadDemoData(), isTrue); // empty install: fine
      expect(app.sessions.sessions, isNotEmpty);
      expect(await app.loadDemoData(), isTrue); // demo over demo only: nothing real to lose
      await app.sessions.add(WorkoutSession(id: 'real', workoutId: 'w1', name: 'A', workoutDate: DateTime(2026, 1, 2), exercises: const []));
      expect(await app.loadDemoData(), isFalse); // now there is REAL data
      expect(await app.loadDemoData(replaceExisting: true), isTrue);
      app.dispose();
    });
  });
}
