import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Repository contracts. UI + services depend ONLY on these; the in-memory
/// implementations in lib/data/memory are mock and will be replaced by Isar.
/// Every repository is a [Listenable] that notifies after any mutation.

abstract class ExerciseRepository implements Listenable {
  List<Exercise> get all;
  Exercise? byId(String id);
  Future<void> addCustom(Exercise e);
}

abstract class WorkoutRepository implements Listenable {
  List<Workout> get workouts;
  Workout? byId(String id);
  Rotation get rotation;

  /// Workout selected by the rotation index (what "Today" shows).
  Workout? get currentWorkout;
  Workout? get nextWorkout;

  Future<void> saveWorkout(Workout w);

  /// Removes the workout from the list AND the rotation. The rotation keeps pointing at the same
  /// CURRENT workout (index shifts); if the current one is deleted its successor becomes current.
  /// Deleting a workout that is not in the rotation never moves the pointer.
  Future<void> deleteWorkout(String id);
  Future<void> setRotation(Rotation r);

  /// "Change Next Workout": point the rotation at [workoutId].
  Future<void> setCurrentWorkout(String workoutId);

  /// Advance the index by exactly one (wraps). Called on workout completion.
  Future<void> advanceRotation();
}

abstract class SessionRepository implements Listenable {
  /// Newest `workoutDate` first.
  List<WorkoutSession> get sessions;
  WorkoutSession? byId(String id);
  Future<void> add(WorkoutSession s);

  /// Adds many sessions in ONE write (one notification) — used by data import.
  Future<void> addAll(List<WorkoutSession> sessions);

  /// Replaces the session with the same id. A missing id is a silent no-op (never resurrects a
  /// deleted session, never upserts) — identical in every implementation.
  Future<void> update(WorkoutSession s);
  Future<void> delete(String id);

  /// Sessions whose `workoutDate` falls in [from, to).
  List<WorkoutSession> between(DateTime from, DateTime to);

  /// Most recent session that logged [exerciseId], excluding [excludeId].
  WorkoutSession? lastWithExercise(String exerciseId, {String? excludeId});
}

abstract class CardioRepository implements Listenable {
  List<CardioSession> get sessions; // newest workoutDate first
  CardioSession? byId(String id);
  Future<void> add(CardioSession s);

  /// Replaces the session with the same id; a missing id is a no-op (see [SessionRepository.update]).
  Future<void> update(CardioSession s);
  Future<void> delete(String id);
  List<CardioSession> between(DateTime from, DateTime to);

  List<CardioGoal> get goals;
  Future<void> saveGoal(CardioGoal g);
  Future<void> deleteGoal(String id);

  List<CustomCardioActivity> get customActivities;
  Future<void> addCustomActivity(CustomCardioActivity a);
}

abstract class ProfileRepository implements Listenable {
  UserProfile get profile;
  Future<void> update(UserProfile p);
}

/// Optional, opt-in, read-only wearable data (Health Connect on Android).
/// Everything is on-device; failures degrade to "no data", never to errors in UI.
abstract class HealthRepository implements Listenable {
  /// Health Connect (Android), Apple Health (iOS) or none.
  HealthProvider get provider;

  HealthStatus get status;

  /// Latest successful read, or null if not connected / never read.
  HealthSnapshot? get snapshot;

  /// True while a connect/refresh is in flight.
  bool get busy;

  /// Detects availability and, when already granted, loads data. Safe to call repeatedly.
  Future<void> init();

  /// Asks the system for read permission. Returns true when granted.
  Future<bool> connect();

  /// Re-reads data. No-op unless connected; throttled unless [force].
  Future<void> refresh({bool force = false});

  /// Clears cached data and forgets consent. Android: also revokes the
  /// permission (needs an app restart to fully apply). iOS cannot revoke
  /// programmatically — the user removes access in Settings › Health.
  Future<void> disconnect();

  /// Opens the Play Store page for Health Connect (when [HealthStatus.notInstalled]).
  Future<void> installProvider();
}

/// Local-only store for the single in-progress workout draft. Never synced.
/// A corrupt/unreadable stored draft reads as "no draft".
abstract class WorkoutDraftStore implements Listenable {
  WorkoutDraft? get current;
  Future<void> save(WorkoutDraft draft);
  Future<void> clear();
}
