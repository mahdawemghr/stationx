/// Cloud tables that sync (see supabase/migrations). Order matters: dependencies
/// first (a workout session may reference custom exercises / workouts).
enum SyncTable {
  profiles('profiles', singleton: true),
  exercises('exercises'),
  workouts('workouts'),
  rotations('rotations', singleton: true),
  workoutSessions('workout_sessions'),
  cardioSessions('cardio_sessions'),
  cardioGoals('cardio_goals'),
  customCardioActivities('custom_cardio_activities');

  const SyncTable(this.name, {this.singleton = false});

  /// Postgres table name.
  final String name;

  /// One row per user keyed by `user_id` (no `id` column): profile and rotation.
  final bool singleton;

  /// Fixed local id used for singleton rows.
  String get singletonId => name == 'profiles' ? 'profile' : 'rotation';

  /// `on_conflict` columns for upserts.
  String get conflictTarget => singleton ? 'user_id' : 'user_id,id';

  static SyncTable? byName(String n) {
    for (final t in values) {
      if (t.name == n) return t;
    }
    return null;
  }
}
