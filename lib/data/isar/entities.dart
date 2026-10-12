import 'package:isar_community/isar.dart';

part 'entities.g.dart';

// Device-local storage (Isar). StationX is online-first: ALL user data (workouts, sessions, cardio,
// profile…) lives in Supabase and is NOT stored here. This single collection only holds state that
// belongs to the device or to the app run itself:
//   * the in-progress workout draft (temporary UI state, wiped on logout / account change),
//   * the Health Connect opt-in,
//   * which account the draft belongs to.
// (Older builds also stored a maximum-workout-length preference and an auto-end notice; both features
// were removed and Isar ignores those leftover fields when it opens an old file.)
//
// Older builds also stored every user table here (and sync bookkeeping). Those collections are no
// longer part of the schema, so Isar drops them when it opens an old file.

/// Singleton (id = 1): app-level flags that are not user data.
@collection
class AppMetaEntity {
  Id id = 1;
  int schemaVersion = 2;

  /// User opted in to the platform health store (needed on iOS, where the OS
  /// cannot report read access).
  bool healthConnected = false;

  /// JSON of the in-progress workout draft (see WorkoutDraft). Device-local: never uploaded.
  String? workoutDraftJson;

  /// Supabase user id the draft/notice above belong to.
  String? ownerUserId;
}
