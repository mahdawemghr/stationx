import '../models/models.dart';

/// Volume / set-count aggregation. Pure.
abstract final class VolumeService {
  static DateTime startOfWeek(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1)); // Monday
  }

  static double totalVolume(Iterable<WorkoutSession> s) => s.fold(0.0, (a, e) => a + e.volume);
  static int totalSets(Iterable<WorkoutSession> s) => s.fold(0, (a, e) => a + e.doneSets);

  /// Working sets per primary muscle (secondary muscles not counted).
  static Map<MuscleGroup, int> setsByMuscle(Iterable<WorkoutSession> sessions, List<Exercise> catalog) {
    final byId = {for (final e in catalog) e.id: e};
    final out = <MuscleGroup, int>{};
    for (final s in sessions) {
      for (final log in s.exercises) {
        final ex = byId[log.exerciseId];
        if (ex == null) continue;
        out[ex.primaryMuscle] = (out[ex.primaryMuscle] ?? 0) + log.doneSets.length;
      }
    }
    return out;
  }

  /// Weekly set-range guideline used for the "dose" bars (configurable constants).
  static (int min, int max) weeklyRange(MuscleGroup m) => switch (m) {
        MuscleGroup.back => (12, 16),
        MuscleGroup.chest => (10, 14),
        MuscleGroup.legs => (12, 16),
        MuscleGroup.shoulders => (8, 12),
        MuscleGroup.biceps || MuscleGroup.triceps => (6, 10),
        MuscleGroup.core => (6, 10),
      };

  /// Volume (kg) per exercise per session, oldest → newest (for charts).
  static List<(DateTime, double)> volumeSeries(String exerciseId, Iterable<WorkoutSession> sessions) {
    final out = <(DateTime, double)>[];
    for (final s in sessions) {
      for (final l in s.exercises.where((l) => l.exerciseId == exerciseId)) {
        out.add((s.workoutDate, l.volume));
      }
    }
    out.sort((a, b) => a.$1.compareTo(b.$1));
    return out;
  }

  static List<CardioSession> cardioIn(Iterable<CardioSession> all, DateTime from, DateTime to) =>
      all.where((c) => !c.workoutDate.isBefore(from) && c.workoutDate.isBefore(to)).toList();

  static int cardioMinutes(Iterable<CardioSession> s) => s.fold(0, (a, c) => a + c.durationSeconds) ~/ 60;
  static double cardioKm(Iterable<CardioSession> s) => s.fold(0.0, (a, c) => a + (c.distanceKm ?? 0));
}
