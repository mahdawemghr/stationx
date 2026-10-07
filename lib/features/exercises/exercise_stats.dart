import '../../domain/domain.dart';

/// One session's worth of an exercise (presentation-side aggregation of
/// existing domain values; no new formulas — 1RM comes from estimateOneRepMax).
class ExerciseSessionStat {
  ExerciseSessionStat({required this.session, required this.log});
  final WorkoutSession session;
  final ExerciseLog log;

  DateTime get date => session.workoutDate;
  List<SetLog> get sets => log.doneSets.toList();
  double get topWeight => sets.fold(0.0, (a, s) => s.weightKg > a ? s.weightKg : a);
  int get topReps => sets.fold(0, (a, s) => s.reps > a ? s.reps : a);
  double get volume => log.volume;
  double get e1rm => sets.fold(0.0, (a, s) {
        final v = estimateOneRepMax(s.weightKg, s.reps);
        return v > a ? v : a;
      });
  double? get rpe {
    final r = sets.where((s) => s.rpe != null).map((s) => s.rpe!).toList();
    return r.isEmpty ? null : r.reduce((a, b) => a > b ? a : b);
  }
}

/// Sessions containing [exerciseId], oldest → newest.
List<ExerciseSessionStat> statsFor(String exerciseId, List<WorkoutSession> sessions) {
  final out = <ExerciseSessionStat>[];
  for (final s in sessions) {
    for (final l in s.exercises) {
      if (l.exerciseId == exerciseId && l.doneSets.isNotEmpty) out.add(ExerciseSessionStat(session: s, log: l));
    }
  }
  out.sort((a, b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : a.session.meta.createdAt.compareTo(b.session.meta.createdAt);
  });
  return out;
}
