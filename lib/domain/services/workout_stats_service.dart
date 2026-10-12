import '../models/models.dart';
import 'volume_service.dart';

/// History lookups and sums for one routine ([Workout]) - no UI text.
abstract final class WorkoutStatsService {
  /// Newest session of [workoutId]; [sessions] is newest-first (repository order).
  static WorkoutSession? lastSessionOf(
    String workoutId,
    List<WorkoutSession> sessions,
  ) {
    for (final s in sessions) {
      if (s.workoutId == workoutId) return s;
    }
    return null;
  }

  static List<WorkoutSession> sessionsOf(
    String workoutId,
    List<WorkoutSession> sessions,
  ) => sessions.where((s) => s.workoutId == workoutId).toList();

  /// Total volume (kg) of this workout over the last [days] days (window is
  /// [now+1d-(days+1)d, now+1d), kept exactly as the screens always used).
  static double recentVolume(
    String workoutId,
    List<WorkoutSession> sessions, {
    int days = 30,
    DateTime? now,
  }) {
    final to = (now ?? DateTime.now()).add(const Duration(days: 1));
    final from = to.subtract(Duration(days: days + 1));
    return VolumeService.totalVolume(
      sessionsOf(workoutId, sessions).where(
        (s) => !s.workoutDate.isBefore(from) && s.workoutDate.isBefore(to),
      ),
    );
  }

  /// Average duration in minutes over timed sessions, or null when none.
  static int? averageMinutes(String workoutId, List<WorkoutSession> sessions) {
    final timed = sessionsOf(
      workoutId,
      sessions,
    ).where((s) => s.durationSeconds > 0).toList();
    if (timed.isEmpty) return null;
    final total = timed.fold<int>(0, (a, s) => a + s.durationSeconds);
    return (total / timed.length / 60).round();
  }

  /// Heaviest completed set of [exerciseId] in [session] (ties -> more reps).
  static SetLog? topSet(WorkoutSession session, String exerciseId) {
    SetLog? best;
    for (final log in session.exercises.where(
      (e) => e.exerciseId == exerciseId,
    )) {
      for (final s in log.doneSets) {
        if (best == null ||
            s.weightKg > best.weightKg ||
            (s.weightKg == best.weightKg && s.reps > best.reps)) {
          best = s;
        }
      }
    }
    return best;
  }

  /// Whole calendar days from [d] to [now] (0 = today, negative = future).
  static int daysAgo(DateTime d, [DateTime? now]) {
    now ??= DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(d.year, d.month, d.day)).inDays;
  }
}
