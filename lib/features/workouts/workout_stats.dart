import '../../domain/domain.dart';

/// Thin feature-side facade over [WorkoutStatsService] (domain) plus UI text
/// helpers (set/rep labels, "yesterday" style ages).
abstract final class WorkoutStats {
  static WorkoutSession? lastSessionOf(
    String workoutId,
    List<WorkoutSession> sessions,
  ) => WorkoutStatsService.lastSessionOf(workoutId, sessions);

  static List<WorkoutSession> sessionsOf(
    String workoutId,
    List<WorkoutSession> sessions,
  ) => WorkoutStatsService.sessionsOf(workoutId, sessions);

  /// Total volume (kg) of this workout over the last [days] days.
  static double recentVolume(
    String workoutId,
    List<WorkoutSession> sessions, {
    int days = 30,
    DateTime? now,
  }) => WorkoutStatsService.recentVolume(
    workoutId,
    sessions,
    days: days,
    now: now,
  );

  /// Average duration in minutes, or null when no timed sessions exist.
  static int? averageMinutes(String workoutId, List<WorkoutSession> sessions) =>
      WorkoutStatsService.averageMinutes(workoutId, sessions);

  /// Heaviest completed set of [exerciseId] in [session] (ties → more reps).
  static SetLog? topSet(WorkoutSession session, String exerciseId) =>
      WorkoutStatsService.topSet(session, exerciseId);

  /// Distinct primary muscles of a workout, in exercise order.
  static List<MuscleGroup> muscles(Workout w, ExerciseRepository exercises) {
    final out = <MuscleGroup>[];
    for (final re in w.exercises) {
      final m = exercises.byId(re.exerciseId)?.primaryMuscle;
      if (m != null && !out.contains(m)) out.add(m);
    }
    return out;
  }

  /// "3 × 8–12"
  static String setsReps(RoutineExercise re) =>
      '${re.sets} × ${re.repMin == re.repMax ? re.repMin : '${re.repMin}–${re.repMax}'}';

  /// "Done 4d ago" style label (the day count comes from the domain).
  static String ago(DateTime d, [DateTime? now]) {
    final days = WorkoutStatsService.daysAgo(d, now);
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 14) return '${days}d ago';
    if (days < 60) return '${days ~/ 7}w ago';
    return '${days ~/ 30}mo ago';
  }
}
