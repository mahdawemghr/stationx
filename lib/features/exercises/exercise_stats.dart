import '../../domain/domain.dart';

/// Sessions containing [exerciseId], oldest → newest.
/// The aggregation lives in [ExerciseHistoryService] (domain); this keeps the
/// short feature-side name.
List<ExerciseSessionStat> statsFor(
  String exerciseId,
  List<WorkoutSession> sessions,
) => ExerciseHistoryService.statsFor(exerciseId, sessions);
