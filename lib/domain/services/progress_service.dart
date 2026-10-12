import '../models/models.dart';
import 'volume_service.dart';

/// Top weight of one exercise went from [from] to [to] over a window.
class StrengthChange {
  const StrengthChange({
    required this.exerciseId,
    required this.from,
    required this.to,
  });
  final String exerciseId;
  final double from;
  final double to;

  double get delta => to - from;

  /// Relative gain in percent (from is always > 0 for results of [ProgressService.strengthChanges]).
  double get percent => delta / from * 100;
}

enum PushPullCategory { balanced, pullDominant, pushDominant }

/// Pull sets (back + biceps) vs push sets (chest + shoulders + triceps).
class PushPullBalance {
  const PushPullBalance({required this.pull, required this.push});
  final int pull;
  final int push;

  double get ratio => pull / push;

  /// 0.8 .. 1.25 (inclusive) is balanced.
  PushPullCategory get category => (ratio >= 0.8 && ratio <= 1.25)
      ? PushPullCategory.balanced
      : (ratio > 1.25
            ? PushPullCategory.pullDominant
            : PushPullCategory.pushDominant);
}

abstract final class ProgressService {
  static double _topWeight(WorkoutSession s, String id) {
    var best = 0.0;
    for (final l in s.exercises.where((l) => l.exerciseId == id)) {
      for (final st in l.doneSets) {
        if (st.weightKg > best) best = st.weightKg;
      }
    }
    return best;
  }

  /// Exercises trained in [from, to) whose top weight rose, biggest relative
  /// gain first. The baseline is the top weight of the latest session before
  /// [from] (or the first in-window session when there is none); the end value
  /// is the top weight of the latest in-window session. Rows need from > 0 and to > from.
  /// [limit] <= 0 means no limit.
  static List<StrengthChange> strengthChanges(
    List<WorkoutSession> all, {
    required DateTime from,
    required DateTime to,
    int limit = 3,
  }) {
    final inW = all
        .where(
          (s) => !s.workoutDate.isBefore(from) && s.workoutDate.isBefore(to),
        )
        .toList();
    final ids = {
      for (final s in inW)
        for (final l in s.exercises) l.exerciseId,
    };
    final rows = <StrengthChange>[];
    for (final id in ids) {
      final within =
          inW
              .where(
                (s) => s.exercises.any(
                  (l) => l.exerciseId == id && l.doneSets.isNotEmpty,
                ),
              )
              .toList()
            ..sort((a, b) => a.workoutDate.compareTo(b.workoutDate));
      if (within.isEmpty) continue;
      final before =
          all
              .where(
                (s) =>
                    s.workoutDate.isBefore(from) &&
                    s.exercises.any(
                      (l) => l.exerciseId == id && l.doneSets.isNotEmpty,
                    ),
              )
              .toList()
            ..sort((a, b) => b.workoutDate.compareTo(a.workoutDate));
      final start = before.isNotEmpty
          ? _topWeight(before.first, id)
          : _topWeight(within.first, id);
      final end = _topWeight(within.last, id);
      if (start > 0 && end > start) {
        rows.add(StrengthChange(exerciseId: id, from: start, to: end));
      }
    }
    rows.sort(
      (a, b) => ((b.to - b.from) / b.from).compareTo((a.to - a.from) / a.from),
    );
    return limit > 0 ? rows.take(limit).toList() : rows;
  }

  /// Push/pull set balance of [sessions]; null unless both sides have sets.
  static PushPullBalance? pushPull(
    List<WorkoutSession> sessions,
    List<Exercise> catalog,
  ) {
    final m = VolumeService.setsByMuscle(sessions, catalog);
    final pull = (m[MuscleGroup.back] ?? 0) + (m[MuscleGroup.biceps] ?? 0);
    final push =
        (m[MuscleGroup.chest] ?? 0) +
        (m[MuscleGroup.shoulders] ?? 0) +
        (m[MuscleGroup.triceps] ?? 0);
    if (pull == 0 || push == 0) return null;
    return PushPullBalance(pull: pull, push: push);
  }
}
