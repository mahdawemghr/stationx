import '../../domain/domain.dart';

/// A personal record set in a session, with the previous best for context.
class PrHighlight {
  const PrHighlight({
    required this.exerciseId,
    required this.weightKg,
    required this.reps,
    required this.previousWeightKg,
    required this.previousReps,
    required this.e1rmDeltaKg,
  });
  final String exerciseId;
  final double weightKg;
  final int reps;
  final double previousWeightKg;
  final int previousReps;
  final double e1rmDeltaKg;

  double get loadDeltaKg => weightKg - previousWeightKg;
  int get repDelta => reps - previousReps;
}

enum ProgressKind { load, reps, maintained, lower, first }

/// How an exercise compares with its previous logged session.
class ExerciseProgress {
  const ExerciseProgress({required this.exerciseId, required this.kind, this.value = 0});
  final String exerciseId;
  final ProgressKind kind;

  /// % for [ProgressKind.load], rep count for [ProgressKind.reps].
  final double value;

  bool get improved => kind == ProgressKind.load || kind == ProgressKind.reps;
}

/// Read-only comparisons of a finished session with earlier history.
/// Builds on [PrService] / [estimateOneRepMax]; contains no progression rules
/// of its own (the recommendation engine stays in ProgressionService).
abstract final class SessionAnalysis {
  /// Sessions strictly before [s] (earlier date, or same date and entered
  /// earlier), newest first, never including [s].
  static List<WorkoutSession> before(WorkoutSession s, List<WorkoutSession> all) {
    bool earlier(WorkoutSession h) {
      if (h.id == s.id) return false;
      if (h.workoutDate != s.workoutDate) return h.workoutDate.isBefore(s.workoutDate);
      return h.meta.createdAt.isBefore(s.meta.createdAt);
    }

    return all.where(earlier).toList()..sort((a, b) => b.workoutDate.compareTo(a.workoutDate));
  }

  /// 1-based position of [s] in chronological order.
  static int sessionNumber(WorkoutSession s, List<WorkoutSession> all) => before(s, all).length + 1;

  static List<PrHighlight> prs(WorkoutSession s, List<WorkoutSession> all) {
    final prior = before(s, all);
    final out = <PrHighlight>[];
    for (final id in PrService.newPrExerciseIds(s, all)) {
      final log = s.exercises.firstWhere((e) => e.exerciseId == id);
      SetLog best = log.doneSets.first;
      for (final set in log.doneSets) {
        if (estimateOneRepMax(set.weightKg, set.reps) > estimateOneRepMax(best.weightKg, best.reps)) best = set;
      }
      final prev = PrService.forExercise(id, prior)[PrType.estimated1Rm];
      if (prev == null) continue;
      out.add(PrHighlight(
        exerciseId: id,
        weightKg: best.weightKg,
        reps: best.reps,
        previousWeightKg: prev.weightKg,
        previousReps: prev.reps,
        e1rmDeltaKg: estimateOneRepMax(best.weightKg, best.reps) - prev.value,
      ));
    }
    return out;
  }

  static List<ExerciseProgress> progression(WorkoutSession s, List<WorkoutSession> all) {
    final prior = before(s, all);
    final out = <ExerciseProgress>[];
    for (final log in s.exercises) {
      final sets = log.doneSets.toList();
      if (sets.isEmpty) continue;
      ExerciseLog? prev;
      for (final p in prior) {
        final hit = p.exercises.where((e) => e.exerciseId == log.exerciseId && e.doneSets.isNotEmpty);
        if (hit.isNotEmpty) {
          prev = hit.first;
          break;
        }
      }
      if (prev == null) {
        out.add(ExerciseProgress(exerciseId: log.exerciseId, kind: ProgressKind.first));
        continue;
      }
      double top(Iterable<SetLog> x) => x.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
      int reps(Iterable<SetLog> x) => x.fold(0, (a, e) => a + e.reps);
      final topNow = top(sets), topPrev = top(prev.doneSets);
      if (topNow > topPrev) {
        out.add(ExerciseProgress(exerciseId: log.exerciseId, kind: ProgressKind.load, value: (topNow - topPrev) / topPrev * 100));
      } else if (topNow == topPrev && reps(sets) > reps(prev.doneSets)) {
        out.add(ExerciseProgress(exerciseId: log.exerciseId, kind: ProgressKind.reps, value: (reps(sets) - reps(prev.doneSets)).toDouble()));
      } else if (topNow == topPrev) {
        out.add(ExerciseProgress(exerciseId: log.exerciseId, kind: ProgressKind.maintained));
      } else {
        out.add(ExerciseProgress(exerciseId: log.exerciseId, kind: ProgressKind.lower));
      }
    }
    return out;
  }
}
