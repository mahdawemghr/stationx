import '../models/models.dart';
import 'muscle_profiles.dart';

/// Volume / set-count aggregation. Pure.
abstract final class VolumeService {
  static DateTime startOfWeek(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    // Calendar arithmetic (not Duration) so a DST change inside the week cannot land on 23:00/01:00.
    return DateTime(day.year, day.month, day.day - (day.weekday - 1)); // Monday
  }

  static double totalVolume(Iterable<WorkoutSession> s) =>
      s.fold(0.0, (a, e) => a + e.volume);
  static int totalSets(Iterable<WorkoutSession> s) =>
      s.fold(0, (a, e) => a + e.doneSets);

  /// Direct working sets per broad [MuscleGroup], derived from the same muscle profiles as
  /// [MuscleCoverage] (single dose model): an exercise counts its done sets once for every broad group
  /// in which it has a PRIMARY target (secondary work is never counted; e.g. a deadlift counts for
  /// back and legs, one exercise never counts twice in the same group). Forearms are not one of the
  /// seven broad groups, so forearm-primary work is not shown as Biceps (see [MuscleCoverage] for the
  /// detailed view).
  static Map<MuscleGroup, int> setsByMuscle(
    Iterable<WorkoutSession> sessions,
    List<Exercise> catalog,
  ) {
    final byId = {for (final e in catalog) e.id: e};
    final out = <MuscleGroup, int>{};
    for (final s in sessions) {
      for (final log in s.exercises) {
        final ex = byId[log.exerciseId];
        if (ex == null) continue;
        final n = log.doneSets.length;
        if (n == 0) continue;
        final groups = {
          for (final t in MuscleProfiles.of(ex).primary)
            if (t.region != MuscleRegion.forearms) t.region.legacy,
        };
        for (final g in groups) {
          out[g] = (out[g] ?? 0) + n;
        }
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
  static List<(DateTime, double)> volumeSeries(
    String exerciseId,
    Iterable<WorkoutSession> sessions,
  ) {
    final out = <(DateTime, double)>[];
    for (final s in sessions) {
      for (final l in s.exercises.where((l) => l.exerciseId == exerciseId)) {
        out.add((s.workoutDate, l.volume));
      }
    }
    out.sort((a, b) => a.$1.compareTo(b.$1));
    return out;
  }

  static List<CardioSession> cardioIn(
    Iterable<CardioSession> all,
    DateTime from,
    DateTime to,
  ) => all
      .where((c) => !c.workoutDate.isBefore(from) && c.workoutDate.isBefore(to))
      .toList();

  static int cardioMinutes(Iterable<CardioSession> s) =>
      s.fold(0, (a, c) => a + c.durationSeconds) ~/ 60;
  static double cardioKm(Iterable<CardioSession> s) =>
      s.fold(0.0, (a, c) => a + (c.distanceKm ?? 0));
}
