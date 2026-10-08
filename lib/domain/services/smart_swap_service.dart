import '../models/models.dart';
import 'exercise_recommender.dart';

class SwapCandidate {
  const SwapCandidate({
    required this.exercise,
    required this.matchPercent,
    required this.reason,
  });
  final Exercise exercise;

  /// 0–100, computed from muscle / movement / purpose / equipment similarity (see ExerciseRecommender).
  final int matchPercent;
  final String reason;
}

/// Ranks catalog alternatives for an exercise (e.g. when its equipment is unavailable).
/// DELEGATES to [ExerciseRecommender.replacements] (muscle subgroup > movement > purpose > equipment >
/// history); this class only keeps the long-standing public API. Computed, never static.
abstract final class SmartSwapService {
  static List<SwapCandidate> alternatives({
    required Exercise current,
    required List<Exercise> catalog,
    Set<Equipment>? allowedEquipment,
    Set<String> excludeIds = const {},
    Iterable<WorkoutSession> history = const [],
  }) => ExerciseRecommender.replacements(
    current: current,
    catalog: catalog,
    history: history,
    allowedEquipment: allowedEquipment,
    excludeIds: excludeIds,
  );
}
