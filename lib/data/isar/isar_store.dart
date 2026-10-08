import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../domain/domain.dart';
import '../data_store.dart';
import '../health/health_consent_store.dart';
import '../memory/memory_repositories.dart';
import '../seed/seed_catalog.dart';
import '../seed/seed_data.dart';
import '../sync/sync_tables.dart';
import 'entities.dart';
import 'mappers.dart';

/// Persistent [DataStore] backed by Isar.
///
/// Design: each repository is the in-memory repository (read cache, so UI
/// getters stay synchronous and cheap) plus write-through persistence. Every
/// mutation is written to Isar FIRST; the cache/listeners update only after the
/// write succeeded, so a failed write never leaves the UI ahead of the disk.
/// All data is loaded once at [open].
class IsarStore implements DataStore, LocalSettingsStore {
  IsarStore._(
    this._db,
    this.exercises,
    this.workouts,
    this.sessions,
    this.cardio,
    this.profile,
    this._signedIn,
    bool healthConnected,
    String? draftJson,
    this._maxRaw,
    this._noticeJson,
  )   : healthConsent = _IsarHealthConsent(_db, healthConnected),
        workoutDraft = IsarWorkoutDraftStore(_db, draftJson);

  static const schemas = [
    ExerciseEntitySchema,
    WorkoutEntitySchema,
    RotationEntitySchema,
    SessionEntitySchema,
    CardioSessionEntitySchema,
    CardioGoalEntitySchema,
    CustomActivityEntitySchema,
    ProfileEntitySchema,
    AppMetaEntitySchema,
    SyncStateEntitySchema,
    SyncDeletionEntitySchema,
  ];

  /// Opens (creating if needed) the database in [directory].
  /// First launch seeds the exercise catalogue + default 3-day rotation (no
  /// history). Pass [name] to isolate databases (tests).
  static Future<IsarStore> open({
    required String directory,
    String name = 'stationx',
  }) async {
    final db = await Isar.open(schemas, directory: directory, name: name);
    final meta = await db.appMetaEntitys.get(1);
    if (meta == null) {
      await db.writeTxn(() => db.appMetaEntitys.put(AppMetaEntity()));
    }

    if (await db.exerciseEntitys.count() == 0 &&
        await db.workoutEntitys.count() == 0) {
      final seed = SeedData.fresh();
      await db.writeTxn(() async {
        await _putAll(db, seed, const UserProfile(), keepProfile: true);
      });
    }

    await topUpCatalog(db);

    final d = await _loadAll(db);
    final cardioRepo = IsarCardioRepository(db, d.cardio, d.goals)
      ..seedCustom(d.custom);
    return IsarStore._(
      db,
      IsarExerciseRepository(db, d.exercises),
      IsarWorkoutRepository(db, d.workouts, d.rotation),
      IsarSessionRepository(db, d.sessions),
      cardioRepo,
      IsarProfileRepository(db, d.profile),
      (await db.appMetaEntitys.get(1))?.signedIn ?? false,
      (await db.appMetaEntitys.get(1))?.healthConnected ?? false,
      (await db.appMetaEntitys.get(1))?.workoutDraftJson,
      (await db.appMetaEntitys.get(1))?.maxWorkoutMinutesRaw,
      (await db.appMetaEntitys.get(1))?.autoEndNoticeJson,
    );
  }

  /// Inserts built-in exercises added in newer app versions: only ids that are missing, so existing rows
  /// (edited, custom, or already seeded) are never overwritten or removed. Seed rows are marked synced
  /// (and are not custom), so they never trigger a sync upload. Returns how many were added.
  static Future<int> topUpCatalog(Isar db) async {
    final have = (await db.exerciseEntitys.where().findAll())
        .map((e) => e.uid)
        .toSet();
    final missing = [
      for (final e in seedExercises())
        if (!have.contains(e.id)) e,
    ];
    if (missing.isEmpty) return 0;
    final now = DateTime.now();
    await db.writeTxn(() async {
      await db.exerciseEntitys.putAllByUid([
        for (final e in missing)
          exerciseToEntity(e)
            ..meta = (MetaEmb()
              ..createdAt = now
              ..updatedAt = now
              ..syncStatus = SyncStatus.synced),
      ]);
    });
    return missing.length;
  }

  /// Reads every collection into domain objects (the in-memory read caches).
  static Future<_Loaded> _loadAll(Isar db) async {
    final exercises = (await db.exerciseEntitys.where().findAll())
        .map(exerciseFromEntity)
        .toList();
    final wEntities = await db.workoutEntitys.where().findAll()
      ..sort((a, b) => a.position.compareTo(b.position));
    final rot = await db.rotationEntitys.get(1);
    final sessions = (await db.sessionEntitys.where().findAll())
        .map(sessionFromEntity)
        .toList();
    final cardio = (await db.cardioSessionEntitys.where().findAll())
        .map(cardioFromEntity)
        .toList();
    final goals = (await db.cardioGoalEntitys.where().findAll())
        .map(goalFromEntity)
        .toList();
    final custom = (await db.customActivityEntitys.where().findAll())
        .map(customActivityFromEntity)
        .toList();
    final profile = await db.profileEntitys.get(1);
    final workouts = wEntities.map(workoutFromEntity).toList();
    return _Loaded(
      exercises: exercises,
      workouts: workouts,
      rotation: rot == null
          ? Rotation(workoutIds: [for (final w in workouts) w.id])
          : rotationFromEntity(rot),
      sessions: sessions,
      cardio: cardio,
      goals: goals,
      custom: custom,
      profile: profile == null
          ? const UserProfile()
          : profileFromEntity(profile),
    );
  }

  /// Re-reads the database into the repository caches and notifies listeners.
  /// Used by cloud sync after it changed rows behind the repositories' backs.
  Future<void> reloadCaches() async {
    final d = await _loadAll(_db);
    exercises.reset(d.exercises);
    workouts.reset(d.workouts, d.rotation);
    sessions.reset(d.sessions);
    cardio.reset(d.cardio, d.goals, d.custom);
    profile.reset(d.profile);
  }

  /// The underlying database (sync layer only — the UI never touches Isar).
  Isar get db => _db;

  final Isar _db;
  @override
  final IsarExerciseRepository exercises;
  @override
  final IsarWorkoutRepository workouts;
  @override
  final IsarSessionRepository sessions;
  @override
  final IsarCardioRepository cardio;
  @override
  final IsarProfileRepository profile;

  @override
  final IsarWorkoutDraftStore workoutDraft;

  /// Persisted opt-in for the platform health store.
  final HealthConsentStore healthConsent;

  bool _signedIn;
  @override
  bool get signedIn => _signedIn;

  // Device preferences: kept by replaceAll (a wipe never resets them).
  int? _maxRaw;
  String? _noticeJson;
  @override
  int? get maxWorkoutMinutesRaw => _maxRaw;
  @override
  String? get autoEndNoticeJson => _noticeJson;

  @override
  Future<void> setMaxWorkoutMinutesRaw(int? raw) async {
    await _db.writeTxn(() async {
      final m = (await _db.appMetaEntitys.get(1)) ?? AppMetaEntity();
      m.maxWorkoutMinutesRaw = raw;
      await _db.appMetaEntitys.put(m);
    });
    _maxRaw = raw;
  }

  @override
  Future<void> setAutoEndNoticeJson(String? json) async {
    await _db.writeTxn(() async {
      final m = (await _db.appMetaEntitys.get(1)) ?? AppMetaEntity();
      m.autoEndNoticeJson = json;
      await _db.appMetaEntitys.put(m);
    });
    _noticeJson = json;
  }

  @override
  Future<void> setSignedIn(bool value) async {
    await _db.writeTxn(() async {
      final m = (await _db.appMetaEntitys.get(1)) ?? AppMetaEntity();
      m.signedIn = value;
      await _db.appMetaEntitys.put(m);
    });
    _signedIn = value;
  }

  @override
  Future<void> replaceAll(SeedData seed, UserProfile profile) async {
    await _db.writeTxn(() async {
      await _db.exerciseEntitys.clear();
      await _db.workoutEntitys.clear();
      await _db.rotationEntitys.clear();
      await _db.sessionEntitys.clear();
      await _db.cardioSessionEntitys.clear();
      await _db.cardioGoalEntitys.clear();
      await _db.customActivityEntitys.clear();
      await _db.syncDeletionEntitys
          .clear(); // queued tombstones refer to rows that no longer exist
      // Cursors/account link describe rows that are being thrown away: a stale cursor would make
      // the next sync skip them forever (and never re-pull what a wipe/replace removed).
      await _db.syncStateEntitys.put(SyncStateEntity());
      await _putAll(_db, seed, profile);
      final m = (await _db.appMetaEntitys.get(1)) ?? AppMetaEntity();
      m.workoutDraftJson = null;
      await _db.appMetaEntitys.put(m);
    });
    workoutDraft.resetCache();
    exercises.reset(seed.exercises);
    workouts.reset(seed.workouts, seed.rotation);
    sessions.reset(seed.sessions);
    cardio.reset(seed.cardio, seed.goals, const []);
    this.profile.reset(profile);
  }

  static Future<void> _putAll(
    Isar db,
    SeedData seed,
    UserProfile profile, {
    bool keepProfile = false,
  }) async {
    await db.exerciseEntitys.putAll([
      for (final e in seed.exercises) exerciseToEntity(e),
    ]);
    await db.workoutEntitys.putAll([
      for (var i = 0; i < seed.workouts.length; i++)
        workoutToEntity(seed.workouts[i], i),
    ]);
    await db.rotationEntitys.put(rotationToEntity(seed.rotation));
    await db.sessionEntitys.putAll([
      for (final s in seed.sessions) sessionToEntity(s),
    ]);
    await db.cardioSessionEntitys.putAll([
      for (final c in seed.cardio) cardioToEntity(c),
    ]);
    await db.cardioGoalEntitys.putAll([
      for (final g in seed.goals) goalToEntity(g),
    ]);
    if (!keepProfile) {
      // An explicit profile write is a real edit → needs to sync.
      await db.profileEntitys.put(
        profileToEntity(profile)
          ..updatedAt = DateTime.now()
          ..syncStatus = SyncStatus.pending,
      );
    }
  }

  @override
  Future<void> close() => _db.close();
}

/// A local edit to the rotation: stamp it so it syncs (and wins over older cloud copies).
RotationEntity _pendingRotation(Rotation r) => rotationToEntity(r)
  ..updatedAt = DateTime.now()
  ..syncStatus = SyncStatus.pending;

/// Remember a local deletion until it has been sent to the cloud. Call inside a write txn.
Future<void> _queueDeletion(Isar db, SyncTable table, String id) async {
  if (isDemoId(id)) return; // demo rows were never uploaded: nothing to tombstone in the cloud
  await db.syncDeletionEntitys.putByTableRowId(
    SyncDeletionEntity()
      ..table = table.name
      ..rowId = id
      ..deletedAt = DateTime.now(),
  );
}

class _Loaded {
  _Loaded({
    required this.exercises,
    required this.workouts,
    required this.rotation,
    required this.sessions,
    required this.cardio,
    required this.goals,
    required this.custom,
    required this.profile,
  });
  final List<Exercise> exercises;
  final List<Workout> workouts;
  final Rotation rotation;
  final List<WorkoutSession> sessions;
  final List<CardioSession> cardio;
  final List<CardioGoal> goals;
  final List<CustomCardioActivity> custom;
  final UserProfile profile;
}

class IsarExerciseRepository extends MemoryExerciseRepository {
  IsarExerciseRepository(this._db, super.seed);
  final Isar _db;

  @override
  Future<void> addCustom(Exercise e) async {
    await _db.writeTxn(() => _db.exerciseEntitys.putByUid(exerciseToEntity(e)));
    await super.addCustom(e);
  }
}

class IsarWorkoutRepository extends MemoryWorkoutRepository {
  IsarWorkoutRepository(this._db, super.workouts, super.rotation);
  final Isar _db;

  /// Writes [items] + [rot] (and [tombstone], if any) in ONE transaction. The cache and listeners
  /// change only after it committed, so a failed write leaves memory untouched.
  Future<void> _commit(List<Workout> items, Rotation rot, {String? tombstone}) async {
    await _db.writeTxn(() async {
      await _db.workoutEntitys.clear();
      await _db.workoutEntitys.putAll([
        for (var i = 0; i < items.length; i++) workoutToEntity(items[i], i),
      ]);
      await _db.rotationEntitys.put(_pendingRotation(rot));
      if (tombstone != null) await _queueDeletion(_db, SyncTable.workouts, tombstone);
    });
    reset(items, rot);
  }

  @override
  Future<void> saveWorkout(Workout w) {
    final (items, rot) = planSave(w);
    return _commit(items, rot);
  }

  @override
  Future<void> deleteWorkout(String id) {
    final (items, rot) = planDelete(id);
    return _commit(items, rot, tombstone: id);
  }

  @override
  Future<void> setRotation(Rotation r) async {
    await _db.writeTxn(() => _db.rotationEntitys.put(_pendingRotation(r)));
    await super.setRotation(r);
  }
}

class IsarSessionRepository extends MemorySessionRepository {
  IsarSessionRepository(this._db, super.seed);
  final Isar _db;

  @override
  Future<void> add(WorkoutSession s) async {
    await _db.writeTxn(() => _db.sessionEntitys.putByUid(sessionToEntity(s)));
    await super.add(s);
  }

  @override
  Future<void> addAll(List<WorkoutSession> sessions) async {
    await _db.writeTxn(
      () => _db.sessionEntitys.putAllByUid([
        for (final s in sessions) sessionToEntity(s),
      ]),
    );
    await super.addAll(sessions);
  }

  @override
  Future<void> update(WorkoutSession s) async {
    if (byId(s.id) == null) return; // missing row: no-op (never resurrect a deleted session)
    await _db.writeTxn(() => _db.sessionEntitys.putByUid(sessionToEntity(s)));
    await super.update(s);
  }

  @override
  Future<void> delete(String id) async {
    await _db.writeTxn(() async {
      await _db.sessionEntitys.deleteByUid(id);
      await _queueDeletion(_db, SyncTable.workoutSessions, id);
    });
    await super.delete(id);
  }
}

class IsarCardioRepository extends MemoryCardioRepository {
  IsarCardioRepository(
    this._db,
    List<CardioSession> sessions,
    List<CardioGoal> goals,
  ) : super(sessions, goals);
  final Isar _db;

  /// Initial load of custom activities (the base constructor takes none).
  void seedCustom(List<CustomCardioActivity> custom) =>
      reset(sessions, goals, custom);

  @override
  Future<void> add(CardioSession s) async {
    await _db.writeTxn(
      () => _db.cardioSessionEntitys.putByUid(cardioToEntity(s)),
    );
    await super.add(s);
  }

  @override
  Future<void> update(CardioSession s) async {
    if (byId(s.id) == null) return; // missing row: no-op (never resurrect a deleted session)
    await _db.writeTxn(
      () => _db.cardioSessionEntitys.putByUid(cardioToEntity(s)),
    );
    await super.update(s);
  }

  @override
  Future<void> delete(String id) async {
    await _db.writeTxn(() async {
      await _db.cardioSessionEntitys.deleteByUid(id);
      await _queueDeletion(_db, SyncTable.cardioSessions, id);
    });
    await super.delete(id);
  }

  @override
  Future<void> saveGoal(CardioGoal g) async {
    await _db.writeTxn(() => _db.cardioGoalEntitys.putByUid(goalToEntity(g)));
    await super.saveGoal(g);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _db.writeTxn(() async {
      await _db.cardioGoalEntitys.deleteByUid(id);
      await _queueDeletion(_db, SyncTable.cardioGoals, id);
    });
    await super.deleteGoal(id);
  }

  @override
  Future<void> addCustomActivity(CustomCardioActivity a) async {
    await _db.writeTxn(
      () => _db.customActivityEntitys.putByUid(customActivityToEntity(a)),
    );
    await super.addCustomActivity(a);
  }
}

class IsarProfileRepository extends MemoryProfileRepository {
  IsarProfileRepository(this._db, super.profile);
  final Isar _db;

  @override
  Future<void> update(UserProfile p) async {
    await _db.writeTxn(
      () => _db.profileEntitys.put(
        profileToEntity(p)
          ..updatedAt = DateTime.now()
          ..syncStatus = SyncStatus.pending,
      ),
    );
    await super.update(p);
  }
}

class _IsarHealthConsent implements HealthConsentStore {
  _IsarHealthConsent(this._db, this._connected);
  final Isar _db;
  bool _connected;

  @override
  bool get connected => _connected;

  @override
  Future<void> setConnected(bool value) async {
    await _db.writeTxn(() async {
      final m = (await _db.appMetaEntitys.get(1)) ?? AppMetaEntity();
      m.healthConnected = value;
      await _db.appMetaEntitys.put(m);
    });
    _connected = value;
  }
}

/// Draft persisted as one JSON string on the AppMeta singleton (local-only; the sync
/// engine never reads AppMeta). Write-through: the cache updates after the disk write.
class IsarWorkoutDraftStore extends MemoryWorkoutDraftStore {
  IsarWorkoutDraftStore(this._db, String? initial) : super(initial);
  final Isar _db;

  Future<void> _persist(String? json) => _db.writeTxn(() async {
        final m = (await _db.appMetaEntitys.get(1)) ?? AppMetaEntity();
        m.workoutDraftJson = json;
        await _db.appMetaEntitys.put(m);
      });

  @override
  Future<void> save(WorkoutDraft draft) async {
    await _persist(jsonEncode(draft.toJson()));
    await super.save(draft);
  }

  @override
  Future<void> clear() async {
    if (rawJson == null) return;
    await _persist(null);
    await super.clear();
  }

  /// Called by replaceAll (which already nulled the column inside its transaction).
  void resetCache() => super.clear();
}
