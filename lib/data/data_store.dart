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

  /// Persisted "user is past the landing screen" flag.
  bool get signedIn;
  Future<void> setSignedIn(bool value);

  /// Replace ALL user data with [seed] and set the profile.
  Future<void> replaceAll(SeedData seed, UserProfile profile);

  Future<void> close();
}
