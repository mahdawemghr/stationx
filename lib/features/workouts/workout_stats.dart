import '../../domain/domain.dart';

/// Read-only aggregation helpers for the workouts screens (history lookups and
/// simple sums). No strength maths lives here: volume sums go through
/// [VolumeService]; 1RM / progression / PRs are never computed in this feature.
abstract final class WorkoutStats {
  /// Newest session of [workoutId]. [sessions] is newest-first (repository order).
  static WorkoutSession? lastSessionOf(String workoutId, List<WorkoutSession> sessions) {
    for (final s in sessions) {
      if (s.workoutId == workoutId) return s;
    }
    return null;
  }

  static List<WorkoutSession> sessionsOf(String workoutId, List<WorkoutSession> sessions) =>
      sessions.where((s) => s.workoutId == workoutId).toList();

  /// Total volume (kg) of this workout over the last [days] days.
  static double recentVolume(String workoutId, List<WorkoutSession> sessions, {int days = 30, DateTime? now}) {
    final to = (now ?? DateTime.now()).add(const Duration(days: 1));
    final from = to.subtract(Duration(days: days + 1));
    return VolumeService.totalVolume(
        sessionsOf(workoutId, sessions).where((s) => !s.workoutDate.isBefore(from) && s.workoutDate.isBefore(to)));
  }

  /// Average duration in minutes, or null when no timed sessions exist.
  static int? averageMinutes(String workoutId, List<WorkoutSession> sessions) {
    final timed = sessionsOf(workoutId, sessions).where((s) => s.durationSeconds > 0).toList();
    if (timed.isEmpty) return null;
    final total = timed.fold<int>(0, (a, s) => a + s.durationSeconds);
    return (total / timed.length / 60).round();
  }

  /// Heaviest completed set of [exerciseId] in [session] (ties → more reps).
  static SetLog? topSet(WorkoutSession session, String exerciseId) {
    SetLog? best;
    for (final log in session.exercises.where((e) => e.exerciseId == exerciseId)) {
      for (final s in log.doneSets) {
        if (best == null || s.weightKg > best.weightKg || (s.weightKg == best.weightKg && s.reps > best.reps)) {
          best = s;
        }
      }
    }
    return best;
  }

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

  /// "Done 4d ago" style label.
  static String ago(DateTime d, [DateTime? now]) {
    now ??= DateTime.now();
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 14) return '${days}d ago';
    if (days < 60) return '${days ~/ 7}w ago';
    return '${days ~/ 30}mo ago';
  }
}
