import 'package:isar_community/isar.dart';

import '../../domain/domain.dart';
import '../data_store.dart';
import '../health/health_consent_store.dart';
import '../memory/memory_repositories.dart';
import '../seed/seed_data.dart';
import 'entities.dart';
import 'mappers.dart';

/// Persistent [DataStore] backed by Isar.
///
/// Design: each repository is the in-memory repository (read cache, so UI
/// getters stay synchronous and cheap) plus write-through persistence. Every
/// mutation is written to Isar FIRST; the cache/listeners update only after the
/// write succeeded, so a failed write never leaves the UI ahead of the disk.
/// All data is loaded once at [open].
class IsarStore implements DataStore {
  IsarStore._(this._db, this.exercises, this.workouts, this.sessions, this.cardio, this.profile, this._signedIn, bool healthConnected)
      : healthConsent = _IsarHealthConsent(_db, healthConnected);

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
  ];

  /// Opens (creating if needed) the database in [directory].
  /// First launch seeds the exercise catalogue + default 3-day rotation (no
  /// history). Pass [name] to isolate databases (tests).
  static Future<IsarStore> open({required String directory, String name = 'stationx'}) async {
    final db = await Isar.open(schemas, directory: directory, name: name);
    final meta = await db.appMetaEntitys.get(1);
    if (meta == null) {
      await db.writeTxn(() => db.appMetaEntitys.put(AppMetaEntity()));
    }

    if (await db.exerciseEntitys.count() == 0 && await db.workoutEntitys.count() == 0) {
      final seed = SeedData.fresh();
      await db.writeTxn(() async {
        await _putAll(db, seed, const UserProfile(), keepProfile: true);
      });
    }

    final exercises = (await db.exerciseEntitys.where().findAll()).map(exerciseFromEntity).toList();
    final wEntities = await db.workoutEntitys.where().findAll()
      ..sort((a, b) => a.position.compareTo(b.position));
    final rot = await db.rotationEntitys.get(1);
    final sessions = (await db.sessionEntitys.where().findAll()).map(sessionFromEntity).toList();
    final cardio = (await db.cardioSessionEntitys.where().findAll()).map(cardioFromEntity).toList();
    final goals = (await db.cardioGoalEntitys.where().findAll()).map(goalFromEntity).toList();
    final custom = (await db.customActivityEntitys.where().findAll()).map(customActivityFromEntity).toList();
    final profile = await db.profileEntitys.get(1);

    final workouts = wEntities.map(workoutFromEntity).toList();
    final rotation = rot == null ? Rotation(workoutIds: [for (final w in workouts) w.id]) : rotationFromEntity(rot);

    final cardioRepo = IsarCardioRepository(db, cardio, goals)..seedCustom(custom);
    return IsarStore._(
      db,
      IsarExerciseRepository(db, exercises),
      IsarWorkoutRepository(db, workouts, rotation),
      IsarSessionRepository(db, sessions),
      cardioRepo,
      IsarProfileRepository(db, profile == null ? const UserProfile() : profileFromEntity(profile)),
      (await db.appMetaEntitys.get(1))?.signedIn ?? false,
      (await db.appMetaEntitys.get(1))?.healthConnected ?? false,
    );
  }

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

  /// Persisted opt-in for the platform health store.
  final HealthConsentStore healthConsent;

  bool _signedIn;
  @override
  bool get signedIn => _signedIn;

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
      await _putAll(_db, seed, profile);
    });
    exercises.reset(seed.exercises);
    workouts.reset(seed.workouts, seed.rotation);
    sessions.reset(seed.sessions);
    cardio.reset(seed.cardio, seed.goals, const []);
    this.profile.reset(profile);
  }

  static Future<void> _putAll(Isar db, SeedData seed, UserProfile profile, {bool keepProfile = false}) async {
    await db.exerciseEntitys.putAll([for (final e in seed.exercises) exerciseToEntity(e)]);
    await db.workoutEntitys.putAll([for (var i = 0; i < seed.workouts.length; i++) workoutToEntity(seed.workouts[i], i)]);
    await db.rotationEntitys.put(rotationToEntity(seed.rotation));
    await db.sessionEntitys.putAll([for (final s in seed.sessions) sessionToEntity(s)]);
    await db.cardioSessionEntitys.putAll([for (final c in seed.cardio) cardioToEntity(c)]);
    await db.cardioGoalEntitys.putAll([for (final g in seed.goals) goalToEntity(g)]);
    if (!keepProfile) await db.profileEntitys.put(profileToEntity(profile));
  }

  @override
  Future<void> close() => _db.close();
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

  Future<void> _persistAll() => _db.writeTxn(() async {
        await _db.workoutEntitys.clear();
        await _db.workoutEntitys.putAll([for (var i = 0; i < workouts.length; i++) workoutToEntity(workouts[i], i)]);
        await _db.rotationEntitys.put(rotationToEntity(rotation));
      });

  @override
  Future<void> saveWorkout(Workout w) async {
    await super.saveWorkout(w);
    await _persistAll();
  }

  @override
  Future<void> deleteWorkout(String id) async {
    await super.deleteWorkout(id);
    await _persistAll();
  }

  @override
  Future<void> setRotation(Rotation r) async {
    await _db.writeTxn(() => _db.rotationEntitys.put(rotationToEntity(r)));
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
  Future<void> update(WorkoutSession s) async {
    await _db.writeTxn(() => _db.sessionEntitys.putByUid(sessionToEntity(s)));
    await super.update(s);
  }

  @override
  Future<void> delete(String id) async {
    await _db.writeTxn(() => _db.sessionEntitys.deleteByUid(id));
    await super.delete(id);
  }
}

class IsarCardioRepository extends MemoryCardioRepository {
  IsarCardioRepository(this._db, List<CardioSession> sessions, List<CardioGoal> goals) : super(sessions, goals);
  final Isar _db;

  /// Initial load of custom activities (the base constructor takes none).
  void seedCustom(List<CustomCardioActivity> custom) => reset(sessions, goals, custom);

  @override
  Future<void> add(CardioSession s) async {
    await _db.writeTxn(() => _db.cardioSessionEntitys.putByUid(cardioToEntity(s)));
    await super.add(s);
  }

  @override
  Future<void> update(CardioSession s) async {
    await _db.writeTxn(() => _db.cardioSessionEntitys.putByUid(cardioToEntity(s)));
    await super.update(s);
  }

  @override
  Future<void> delete(String id) async {
    await _db.writeTxn(() => _db.cardioSessionEntitys.deleteByUid(id));
    await super.delete(id);
  }

  @override
  Future<void> saveGoal(CardioGoal g) async {
    await _db.writeTxn(() => _db.cardioGoalEntitys.putByUid(goalToEntity(g)));
    await super.saveGoal(g);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _db.writeTxn(() => _db.cardioGoalEntitys.deleteByUid(id));
    await super.deleteGoal(id);
  }

  @override
  Future<void> addCustomActivity(CustomCardioActivity a) async {
    await _db.writeTxn(() => _db.customActivityEntitys.putByUid(customActivityToEntity(a)));
    await super.addCustomActivity(a);
  }
}

class IsarProfileRepository extends MemoryProfileRepository {
  IsarProfileRepository(this._db, super.profile);
  final Isar _db;

  @override
  Future<void> update(UserProfile p) async {
    await _db.writeTxn(() => _db.profileEntitys.put(profileToEntity(p)));
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
