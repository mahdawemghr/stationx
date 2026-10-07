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
