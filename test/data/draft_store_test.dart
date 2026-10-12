import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/data/isar/isar_device_store.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
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
    DraftExercise(
      exerciseId: 'lat_pulldown',
      repMin: 8,
      repMax: 12,
      expanded: true,
      suggestionUsed: true,
      sets: [
        DraftSet(weightKg: 47.5, reps: 10, done: true),
        DraftSet(weightKg: 50, reps: 8, done: false),
      ],
    ),
  ],
);

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

  test(
    'device storage: the draft survives a restart and is removed by clear() and by clearUserScopedState()',
    () async {
      var s = await IsarDeviceStore.open(directory: dir.path, name: 'draft');
      expect(s.workoutDraft.current, isNull);
      await s.workoutDraft.save(sample());
      await s.close();

      s = await IsarDeviceStore.open(directory: dir.path, name: 'draft');
      final d = s.workoutDraft.current!;
      expect(d.workoutName, 'Back');
      expect(d.exercises.single.sets.length, 2);
      await s.workoutDraft.clear();
      await s.close();

      s = await IsarDeviceStore.open(directory: dir.path, name: 'draft');
      expect(s.workoutDraft.current, isNull);
      await s.workoutDraft.save(sample());
      await s.setOwnerUserId('user-a');
      await s.clearUserScopedState();
      expect(s.workoutDraft.current, isNull);
      expect(s.ownerUserId, isNull);
      await s.close();
      s = await IsarDeviceStore.open(directory: dir.path, name: 'draft');
      expect(s.workoutDraft.current, isNull);
      await s.close();
    },
  );

  test(
    'the device store keeps the health consent when user state is cleared',
    () async {
      final s = await IsarDeviceStore.open(directory: dir.path, name: 'prefs');
      await s.healthConsent.setConnected(true);
      await s.workoutDraft.save(sample());
      await s.clearUserScopedState();
      await s.close();
      final again = await IsarDeviceStore.open(
        directory: dir.path,
        name: 'prefs',
      );
      expect(again.healthConsent.connected, isTrue);
      expect(again.workoutDraft.current, isNull);
      await again.close();
    },
  );

  test(
    'the device database holds no user data: only the AppMeta collection exists',
    () {
      expect(IsarDeviceStore.schemas.map((s) => s.name), ['AppMetaEntity']);
    },
  );
}
