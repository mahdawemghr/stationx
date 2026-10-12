import '../models/models.dart';
import 'formulas.dart';

/// One session's worth of an exercise: top weight, top reps, best e1RM, RPE.
class ExerciseSessionStat {
  ExerciseSessionStat({required this.session, required this.log});
  final WorkoutSession session;
  final ExerciseLog log;

  DateTime get date => session.workoutDate;
  List<SetLog> get sets => log.doneSets.toList();
  double get topWeight =>
      sets.fold(0.0, (a, s) => s.weightKg > a ? s.weightKg : a);
  int get topReps => sets.fold(0, (a, s) => s.reps > a ? s.reps : a);
  double get volume => log.volume;

  /// Best estimated 1RM of the session; 0 = no reliable estimate (every set above 12 reps / no weight).
  double get e1rm => sets.fold(0.0, (a, s) {
    final v = estimateOneRepMax(s.weightKg, s.reps);
    return v > a ? v : a;
  });
  bool get hasE1rm => e1rm > 0;

  /// Highest RPE among done sets, null when none was recorded.
  double? get rpe {
    final r = sets.where((s) => s.rpe != null).map((s) => s.rpe!).toList();
    return r.isEmpty ? null : r.reduce((a, b) => a > b ? a : b);
  }
}

abstract final class ExerciseHistoryService {
  /// Sessions containing [exerciseId] (with at least one done set), oldest -> newest
  /// (ties on workoutDate broken by createdAt).
  static List<ExerciseSessionStat> statsFor(
    String exerciseId,
    List<WorkoutSession> sessions,
  ) {
    final out = <ExerciseSessionStat>[];
    for (final s in sessions) {
      for (final l in s.exercises) {
        if (l.exerciseId == exerciseId && l.doneSets.isNotEmpty) {
          out.add(ExerciseSessionStat(session: s, log: l));
        }
      }
    }
    out.sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0
          ? c
          : a.session.meta.createdAt.compareTo(b.session.meta.createdAt);
    });
    return out;
  }

  static double totalVolume(List<ExerciseSessionStat> stats) =>
      stats.fold(0.0, (a, s) => a + s.volume);

  static int totalReps(List<ExerciseSessionStat> stats) =>
      stats.fold(0, (a, s) => a + s.sets.fold(0, (b, x) => b + x.reps));
}
