import '../domain/domain.dart';
import 'seed/seed_data.dart';

/// The app's storage backend: a set of repositories + session flags.
/// Implemented by `IsarStore` (production, persistent) and `MemoryStore`
/// (tests/previews). Repository instances are stable for the store's lifetime,
/// so UI that listens to them survives [replaceAll].
abstract class DataStore {
  ExerciseRepository get exercises;
  WorkoutRepository get workouts;
  SessionRepository get sessions;
  CardioRepository get cardio;
  ProfileRepository get profile;

  /// Local-only in-progress workout draft (never synced). Cleared by [replaceAll].
  WorkoutDraftStore get workoutDraft;

  /// Persisted "user is past the landing screen" flag.
  bool get signedIn;
  Future<void> setSignedIn(bool value);

  /// Replace ALL user data with [seed] and set the profile.
  Future<void> replaceAll(SeedData seed, UserProfile profile);

  Future<void> close();
}

/// Device-local preferences (never synced; kept across "Delete all data" / [DataStore.replaceAll]).
/// Optional interface so existing [DataStore] fakes keep compiling; `AppController` falls back to
/// in-memory values when a store does not implement it.
abstract class LocalSettingsStore {
  /// Raw maximum workout length: null = never chosen (default applies), 0 = explicitly off.
  int? get maxWorkoutMinutesRaw;
  Future<void> setMaxWorkoutMinutesRaw(int? raw);

  /// JSON of the pending auto-end notice, until the user has seen it.
  String? get autoEndNoticeJson;
  Future<void> setAutoEndNoticeJson(String? json);
}
