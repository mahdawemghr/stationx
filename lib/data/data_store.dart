import '../domain/domain.dart';
import 'health/health_consent_store.dart';

/// The app's storage backend: a set of repositories for the signed-in user.
///
/// Production is `OnlineStore` (Supabase is the only source of truth; the repositories are a read
/// model of the current user's data). `MemoryStore` (volatile) is used by tests and previews.
/// Repository instances are stable for the store's lifetime, so UI that listens to them survives
/// [load] / [clear].
abstract class DataStore {
  ExerciseRepository get exercises;
  WorkoutRepository get workouts;
  SessionRepository get sessions;
  CardioRepository get cardio;
  ProfileRepository get profile;

  /// Device-local in-progress workout draft (temporary UI state, never uploaded).
  WorkoutDraftStore get workoutDraft;

  /// Device-local live cardio session (survives the app being closed; never uploaded).
  CardioDraftStore get cardioDraft;

  /// Loads everything of the signed-in user ([userId], [username]) from the server. Throws a
  /// `RemoteException` when it cannot; the read model is then left empty. Stores without a server
  /// ignore it.
  Future<void> load({required String userId, required String username});

  /// Drops every piece of user data held in memory (logout, account switch, expired session) and
  /// invalidates any request still in flight, so a late response can never reappear. The in-memory
  /// part happens synchronously; the returned future completes once the device-local, user-scoped
  /// state (the draft) is removed too.
  Future<void> clear();

  /// "Delete all my data": removes the user's training data on the server and The account and its credentials are kept.
  Future<void> resetData();

  Future<void> close();
}

/// Everything persisted on the device (Isar `AppMeta`): preferences, the in-progress workout draft and
/// the Health Connect opt-in. Composed by `OnlineStore`.
abstract class DeviceStore {
  WorkoutDraftStore get workoutDraft;
  CardioDraftStore get cardioDraft;
  HealthConsentStore get healthConsent;

  /// The account whose draft this device currently holds (null = none). When a different
  /// account signs in, the previous one's draft is discarded.
  String? get ownerUserId;
  Future<void> setOwnerUserId(String? id);

  /// Removes the draft (logout / account change / account deletion).
  /// Device preferences (max workout length, health opt-in) are kept.
  Future<void> clearUserScopedState();

  Future<void> close();
}
