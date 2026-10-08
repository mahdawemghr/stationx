import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/data/sync/sync_engine.dart';
import 'package:stationx/data/sync/sync_tables.dart';
import 'package:stationx/domain/domain.dart';
import '../helpers/sync_fakes.dart';

WorkoutSession session(String id, {DateTime? trained, String name = 'Back + Triceps', double kg = 50}) => WorkoutSession(
      id: id,
      workoutId: 'w2',
      name: name,
      workoutDate: trained ?? DateTime.utc(2025, 3, 1, 18, 30),
      durationSeconds: 3000,
      exercises: [
        ExerciseLog(exerciseId: 'lat_pulldown', sets: [SetLog(weightKg: kg, reps: 8), SetLog(weightKg: kg - 2.5, reps: 10, rpe: 8.5)]),
      ],
    );

CardioSession run(String id, {int seconds = 1800}) =>
    CardioSession(id: id, kind: CardioKind.outdoorRun, workoutDate: DateTime.utc(2026, 9, 1, 7), durationSeconds: seconds, distanceKm: 5);

void main() {
  late FakeServer server;
  final devices = <Device>[];
  Future<Device> device({String user = 'user-1', int push = 100, int page = 500}) async {
    final d = await Device.open(server, userId: user, pushBatch: push, pullPage: page, name: 'd${devices.length}');
    devices.add(d);
    return d;
  }

  setUpAll(() => Isar.initializeIsarCore(download: true));
  setUp(() => server = FakeServer());
  tearDown(() async {
    for (final d in devices) {
      await d.close();
    }
    devices.clear();
  });

  test('fresh install uploads nothing: seeded catalogue, default workouts and rotation are clean', () async {
    final a = await device();
    final r = await a.sync();
    expect(r.ok, isTrue);
    expect(r.pushed, 0);
    for (final t in SyncTable.values) {
      expect(server.rows(t, includeDeleted: true), isEmpty, reason: t.name);
    }
  });

  test('a session logged on A arrives on B intact; workout_date stays separate from created_at', () async {
    final a = await device();
    final b = await device();
    final trained = DateTime.utc(2024, 3, 1, 18, 30); // backdated
    await a.store.sessions.add(session('s1', trained: trained));
    final ra = await a.sync();
    expect((ra.ok, ra.pushed), (true, 1));
    final rb = await b.sync();
    expect(rb.ok, isTrue);
    expect(rb.pulled, greaterThanOrEqualTo(1));
    final got = b.store.sessions.byId('s1')!;
    expect(got.workoutDate.isAtSameMomentAs(trained), isTrue);
    expect(got.meta.createdAt.isAfter(DateTime.utc(2025)), isTrue); // entered now, trained in 2024
    expect(got.exercises.single.sets[1].rpe, 8.5);
    expect(got.volume, a.store.sessions.byId('s1')!.volume);
    expect(got.meta.syncStatus, SyncStatus.synced);
    // B did not push it back.
    expect((await b.local.pendingCount()), 0);
  });

  test('sync is idempotent: a second run changes nothing', () async {
    final a = await device();
    await a.store.sessions.add(session('s1'));
    await a.store.cardio.add(run('c1'));
    await a.sync();
    final again = await a.sync();
    expect((again.pushed, again.deleted, again.pulled), (0, 0, 0));
    expect(server.rows(SyncTable.workoutSessions).length, 1);
  });

  test('an edit on A reaches B (newer updated_at wins)', () async {
    final a = await device();
    final b = await device();
    await a.store.cardio.add(run('c1'));
    await a.sync();
    await b.sync();
    expect(b.store.cardio.byId('c1')!.durationSeconds, 1800);
    await a.store.cardio.update(a.store.cardio.byId('c1')!.copyWith(durationSeconds: 2400));
    await a.sync();
    await b.sync();
    expect(b.store.cardio.byId('c1')!.durationSeconds, 2400);
  });

  test('conflict: both edit offline — the later edit wins everywhere', () async {
    final a = await device();
    final b = await device();
    await a.store.cardio.add(run('c1'));
    await a.sync();
    await b.sync();
    await a.store.cardio.update(a.store.cardio.byId('c1')!.copyWith(notes: 'edit from A'));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await b.store.cardio.update(b.store.cardio.byId('c1')!.copyWith(notes: 'edit from B (later)'));
    await b.sync(); // later edit reaches the server first
    await a.sync(); // A's older edit is ignored by the server and replaced locally
    await b.sync();
    expect(a.store.cardio.byId('c1')!.notes, 'edit from B (later)');
    expect(b.store.cardio.byId('c1')!.notes, 'edit from B (later)');
    expect(server.rows(SyncTable.cardioSessions).single['notes'], 'edit from B (later)');
  });

  test('conflict: older edit pushed AFTER a newer one is ignored by the server and corrected on pull', () async {
    final a = await device();
    final b = await device();
    await a.store.cardio.add(run('c1'));
    await a.sync();
    await b.sync();
    await a.store.cardio.update(a.store.cardio.byId('c1')!.copyWith(notes: 'older'));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await b.store.cardio.update(b.store.cardio.byId('c1')!.copyWith(notes: 'newer'));
    await b.sync();
    await a.sync(); // pushes 'older' (rejected as stale), then pulls 'newer'
    expect(a.store.cardio.byId('c1')!.notes, 'newer');
  });

  test('deleting on A deletes on B (tombstone); deleting something never synced is harmless', () async {
    final a = await device();
    final b = await device();
    await a.store.sessions.add(session('s1'));
    await a.sync();
    await b.sync();
    expect(b.store.sessions.byId('s1'), isNotNull);
    await a.store.sessions.delete('s1');
    await a.store.sessions.add(session('never-synced'));
    await a.store.sessions.delete('never-synced');
    final r = await a.sync();
    expect(r.ok, isTrue);
    expect(r.deleted, 2);
    expect((await a.local.pendingDeletions()), isEmpty);
    await b.sync();
    expect(b.store.sessions.byId('s1'), isNull);
    expect(server.rows(SyncTable.workoutSessions), isEmpty);
    expect(server.rows(SyncTable.workoutSessions, includeDeleted: true).length, 1); // tombstone kept
  });

  test('a cloud deletion does not remove a local row the user edited afterwards', () async {
    final a = await device();
    final b = await device();
    await a.store.cardio.add(run('c1'));
    await a.sync();
    await b.sync();
    await a.store.cardio.delete('c1');
    await a.sync();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await b.store.cardio.update(b.store.cardio.byId('c1')!.copyWith(notes: 'edited after the delete'));
    await b.sync(); // push (revives the row: newer updated_at), then pull
    expect(b.store.cardio.byId('c1')!.notes, 'edited after the delete');
    await a.sync();
    expect(a.store.cardio.byId('c1')!.notes, 'edited after the delete'); // resurrected on A too
  });

  test('routine edits + rotation index travel; a fresh device keeps the user\'s version, not its defaults', () async {
    final a = await device();
    final w1 = a.store.workouts.byId('w1')!;
    await a.store.workouts.saveWorkout(w1.copyWith(name: 'Chest Day', exercises: [...w1.exercises, const RoutineExercise(exerciseId: 'pushup', sets: 2, repMin: 15, repMax: 20)]));
    await a.store.workouts.advanceRotation();
    await a.store.workouts.advanceRotation();
    await a.sync();
    final b = await device(); // brand-new phone with the built-in defaults
    expect(b.store.workouts.byId('w1')!.name, 'Chest + Biceps');
    await b.sync();
    expect(b.store.workouts.byId('w1')!.name, 'Chest Day'); // cloud wins over clean defaults
    expect(b.store.workouts.byId('w1')!.exercises.last.exerciseId, 'pushup');
    expect(b.store.workouts.rotation.currentIndex, 2);
    expect((await b.local.pendingCount()), 0);
  });

  test('syncing alone never advances the rotation or changes workout dates', () async {
    final a = await device();
    final b = await device();
    await a.store.sessions.add(session('s1', trained: DateTime.utc(2024, 1, 5)));
    await a.sync();
    final before = b.store.workouts.rotation.currentIndex;
    await b.sync();
    expect(b.store.workouts.rotation.currentIndex, before);
  });

  test('custom exercises, goals and custom activities sync', () async {
    final a = await device();
    final b = await device();
    await a.store.exercises.addCustom(Exercise(id: 'x1', name: 'My Press', primaryMuscle: MuscleGroup.shoulders, equipment: Equipment.dumbbell, isCustom: true));
    await a.store.cardio.saveGoal(CardioGoal(id: 'g1', title: 'Weekly minutes', metric: GoalMetric.durationMinutes, target: 150, isPrimary: true));
    await a.store.cardio.addCustomActivity(CustomCardioActivity(id: 'ca1', name: 'Boxing', fields: const [CardioField.duration], rounds: 5));
    await a.sync();
    await b.sync();
    expect(b.store.exercises.byId('x1')!.name, 'My Press');
    expect(b.store.cardio.goals.map((g) => g.id), contains('g1'));
    expect(b.store.cardio.customActivities.single.rounds, 5);
    // The built-in catalogue is never uploaded.
    expect(server.rows(SyncTable.exercises).map((r) => r['id']), ['x1']);
  });

  test('first link: a locally edited profile beats the cloud default created at signup', () async {
    final a = await device();
    await a.store.profile.update(a.store.profile.profile.copyWith(name: 'Sam', weightKg: 82, unit: WeightUnit.lb, isGuest: false, email: 'sam@x.io'));
    // The server-side signup trigger created a default profile row AFTER the local edit
    // (but before the first sync, which is what bumps the local edit to "now").
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final signupAt = DateTime.now().toUtc().toIso8601String();
    server.seed(SyncTable.profiles, {'user_id': 'user-1', 'name': 'Athlete', 'weight_kg': 74, 'unit': 'kg', 'created_at': signupAt, 'updated_at': signupAt, 'deleted_at': null});
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await a.sync();
    expect(a.store.profile.profile.name, 'Sam');
    expect(server.rows(SyncTable.profiles).single['name'], 'Sam');
    expect(server.rows(SyncTable.profiles).single['weight_kg'], 82);
  });

  test('first link as a guest: the cloud profile wins (new device of an existing account)', () async {
    final a = await device();
    await a.store.profile.update(const UserProfile(name: 'Guest Athlete', isGuest: true)); // what "Continue as Guest" writes
    server.seed(SyncTable.profiles, {'user_id': 'user-1', 'name': 'Sam', 'weight_kg': 82, 'unit': 'lb', 'created_at': '2026-02-01T00:00:00Z', 'updated_at': '2026-02-01T00:00:00Z', 'deleted_at': null});
    final r = await a.sync(preferCloudSingletons: true);
    expect(r.ok, isTrue);
    final p = a.store.profile.profile;
    expect((p.name, p.weightKg, p.unit, p.isGuest), ('Sam', 82.0, WeightUnit.lb, false));
    expect(server.rows(SyncTable.profiles).single['name'], 'Sam'); // not overwritten by "Guest Athlete"
  });

  test('profile edits afterwards sync both ways', () async {
    final a = await device();
    final b = await device();
    await a.sync();
    await b.sync();
    await a.store.profile.update(a.store.profile.profile.copyWith(autoRestSeconds: 150, themeMode: SxThemeMode.oled));
    await a.sync();
    await b.sync();
    expect((b.store.profile.profile.autoRestSeconds, b.store.profile.profile.themeMode), (150, SxThemeMode.oled));
  });

  test('regression: an unchanged profile/rotation is not "pulled" again on every sync (UTC vs local DateTime)', () async {
    final a = await device();
    await a.store.profile.update(a.store.profile.profile.copyWith(name: 'Sam', isGuest: false));
    await a.store.workouts.advanceRotation();
    final first = await a.sync();
    expect(first.ok, isTrue);
    final again = await a.sync();
    expect((again.pushed, again.deleted, again.pulled), (0, 0, 0));
    final third = await a.sync();
    expect(third.pulled, 0);
  });

  test('different account on a device with data: asks; merge uploads to the new account; replace loads the new account', () async {
    final a = await device(user: 'user-1');
    await a.store.sessions.add(session('mine'));
    await a.sync();

    final other = FakeServer(); // account 2's cloud
    final seeded = await Device.open(other, userId: 'user-2', name: 'seed2');
    devices.add(seeded);
    await seeded.store.sessions.add(session('theirs', name: 'Legs'));
    await seeded.sync();

    // Sign A's phone into account 2.
    a.userId = 'user-2';
    a.useGateway(other);
    final ask = await a.sync();
    expect(ask.needsAccountDecision, isTrue);
    expect(ask.pushed, 0);
    expect(other.rows(SyncTable.workoutSessions).map((r) => r['id']), ['theirs']); // nothing uploaded yet

    final merged = await a.sync(decision: AccountSwitch.merge);
    expect(merged.ok, isTrue);
    expect(a.store.sessions.sessions.map((s) => s.id).toSet(), {'mine', 'theirs'});
    expect(other.rows(SyncTable.workoutSessions).map((r) => r['id']).toSet(), {'mine', 'theirs'});
  });

  test('account switch with "replace": local data discarded, only the new account\'s data remains', () async {
    final a = await device(user: 'user-1');
    await a.store.sessions.add(session('mine'));
    await a.sync();
    final other = FakeServer();
    final seeded = await Device.open(other, userId: 'user-2', name: 'seed3');
    devices.add(seeded);
    await seeded.store.sessions.add(session('theirs'));
    await seeded.sync();
    a.userId = 'user-2';
    a.useGateway(other);
    final r = await a.sync(decision: AccountSwitch.replaceWithCloud);
    expect(r.ok, isTrue);
    expect(a.store.sessions.sessions.map((s) => s.id), ['theirs']);
    expect(other.rows(SyncTable.workoutSessions).length, 1); // user 2 did not receive 'mine'
    expect(server.rows(SyncTable.workoutSessions).map((x) => x['id']), ['mine']); // user 1's cloud untouched
  });

  test('a device without data signs into another account without being asked', () async {
    final a = await device(user: 'user-1');
    await a.sync();
    a.userId = 'user-2';
    final r = await a.sync();
    expect(r.needsAccountDecision, isFalse);
    expect(r.ok, isTrue);
  });

  test('network failure mid-push keeps progress; retry finishes with no duplicates', () async {
    final a = await device(push: 2);
    for (var i = 0; i < 5; i++) {
      await a.store.cardio.add(run('c$i'));
    }
    server.failNextUpsertAfter = 2; // 2nd batch fails
    final r1 = await a.sync();
    expect(r1.ok, isFalse);
    expect(r1.error, isNotNull);
    expect(r1.pushed, 2);
    expect(await a.local.pendingCount(), 3);
    final r2 = await a.sync();
    expect(r2.ok, isTrue);
    expect(r2.pushed, 3);
    expect(server.rows(SyncTable.cardioSessions).length, 5);
    expect(await a.local.pendingCount(), 0);
  });

  test('an edit made while a push is in flight stays pending (not wrongly marked synced)', () async {
    final a = await device();
    await a.store.cardio.add(run('c1'));
    server.onUpsert = (table, rows) {
      if (table == SyncTable.cardioSessions) {
        // User edits the row right after the engine read it, before the push completes.
        a.store.cardio.update(a.store.cardio.byId('c1')!.copyWith(notes: 'edited during push'));
      }
    };
    await a.sync();
    server.onUpsert = null;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await a.local.pendingCount(), 1); // still dirty
    await a.sync();
    expect(server.rows(SyncTable.cardioSessions).single['notes'], 'edited during push');
    expect(await a.local.pendingCount(), 0);
  });

  test('pagination: many rows pulled across small pages; large first push in batches', () async {
    final a = await device(push: 50);
    for (var i = 0; i < 130; i++) {
      await a.store.cardio.add(run('c$i'));
    }
    await a.sync();
    expect(server.rows(SyncTable.cardioSessions).length, 130);
    final b = await device(page: 7);
    final r = await b.sync();
    expect(r.ok, isTrue);
    expect(b.store.cardio.sessions.length, 130);
  });

  test('state survives restart: cursor and account link are persisted', () async {
    final a = await device();
    await a.store.cardio.add(run('c1'));
    await a.sync();
    final s = await a.local.loadState();
    expect(s.userId, 'user-1');
    expect(s.lastSyncAt, isNotNull);
    expect(s.cursors.keys, contains('cardio_sessions'));
  });
}
