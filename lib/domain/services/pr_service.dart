import '../models/models.dart';
import 'formulas.dart';

/// Strength + cardio personal records computed from history.
abstract final class PrService {
  /// Best value per [PrType] for [exerciseId], with the previous best.
  static Map<PrType, StrengthPr> forExercise(String exerciseId, List<WorkoutSession> sessions) {
    // Only sessions that logged this exercise matter; filtering first keeps the sort cheap
    // (the library screen calls this once per exercise over the whole history).
    final asc = sessions.where((s) => s.exercises.any((e) => e.exerciseId == exerciseId)).toList()
      ..sort((a, b) => a.workoutDate.compareTo(b.workoutDate));
    final best = <PrType, StrengthPr>{};
    for (final s in asc) {
      for (final log in s.exercises.where((e) => e.exerciseId == exerciseId)) {
        double sessionVolume = 0;
        for (final set in log.doneSets) {
          sessionVolume += set.volume;
          _consider(best, PrType.heaviestWeight, set.weightKg, exerciseId, set, s.workoutDate);
          _consider(best, PrType.mostReps, set.reps.toDouble(), exerciseId, set, s.workoutDate);
          _consider(best, PrType.estimated1Rm, estimateOneRepMax(set.weightKg, set.reps), exerciseId, set,
              s.workoutDate);
        }
        if (sessionVolume > 0) {
          final pseudo = SetLog(weightKg: log.doneSets.first.weightKg, reps: log.doneSets.first.reps);
          _consider(best, PrType.highestVolume, sessionVolume, exerciseId, pseudo, s.workoutDate);
        }
      }
    }
    return best;
  }

  static void _consider(Map<PrType, StrengthPr> best, PrType t, double v, String id, SetLog set, DateTime d) {
    final cur = best[t];
    if (cur == null || v > cur.value) {
      best[t] = StrengthPr(
          exerciseId: id,
          type: t,
          weightKg: set.weightKg,
          reps: set.reps,
          value: v,
          date: d,
          previousValue: cur?.value);
    }
  }

  /// All PRs of [type] across every logged exercise, newest first.
  static List<StrengthPr> all(PrType type, List<WorkoutSession> sessions) {
    final ids = {for (final s in sessions) for (final e in s.exercises) e.exerciseId};
    final out = <StrengthPr>[];
    for (final id in ids) {
      final pr = forExercise(id, sessions)[type];
      if (pr != null) out.add(pr);
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  /// PRs that were *set* inside [from, to) (i.e. new records in that window).
  static List<StrengthPr> setBetween(List<WorkoutSession> sessions, DateTime from, DateTime to,
      {PrType type = PrType.estimated1Rm}) {
    return all(type, sessions).where((p) => !p.date.isBefore(from) && p.date.isBefore(to)).toList();
  }

  /// Exercise ids that hit a new e1RM PR *in this session* (strictly better than
  /// everything logged before it).
  static Set<String> newPrExerciseIds(WorkoutSession session, List<WorkoutSession> history) {
    final prior = history.where((h) => h.id != session.id && !h.workoutDate.isAfter(session.workoutDate)).toList();
    final out = <String>{};
    for (final log in session.exercises) {
      final before = forExercise(log.exerciseId, prior)[PrType.estimated1Rm]?.value;
      final now = log.doneSets.map((s) => estimateOneRepMax(s.weightKg, s.reps)).fold(0.0, (a, b) => a > b ? a : b);
      if (before != null && now > before) out.add(log.exerciseId);
    }
    return out;
  }

  static List<CardioPr> cardio(List<CardioSession> sessions) {
    if (sessions.isEmpty) return const [];
    CardioSession longestD = sessions.first, longestK = sessions.first;
    CardioSession? fastest;
    for (final s in sessions) {
      if (s.durationSeconds > longestD.durationSeconds) longestD = s;
      if ((s.distanceKm ?? 0) > (longestK.distanceKm ?? 0)) longestK = s;
      // Only meaningful over a minimum 1 km.
      if ((s.distanceKm ?? 0) >= 1 && (fastest == null || s.paceSecPerKm! < fastest.paceSecPerKm!)) fastest = s;
    }
    return [
      CardioPr(type: CardioPrType.longestDuration, sessionId: longestD.id, value: longestD.durationSeconds.toDouble(), date: longestD.workoutDate, kindLabel: longestD.kind.label),
      if ((longestK.distanceKm ?? 0) > 0)
        CardioPr(type: CardioPrType.longestDistance, sessionId: longestK.id, value: longestK.distanceKm!, date: longestK.workoutDate, kindLabel: longestK.kind.label),
      if (fastest != null)
        CardioPr(type: CardioPrType.fastestPace, sessionId: fastest.id, value: fastest.paceSecPerKm!, date: fastest.workoutDate, kindLabel: fastest.kind.label),
    ];
  }
}
