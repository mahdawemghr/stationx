import '../models/models.dart';

abstract final class CardioMetrics {
  static double? paceSecPerKm(int durationSeconds, double? distanceKm) =>
      (distanceKm != null && distanceKm > 0)
      ? durationSeconds / distanceKm
      : null;

  static double? speedKmh(int durationSeconds, double? distanceKm) =>
      (distanceKm != null && distanceKm > 0 && durationSeconds > 0)
      ? distanceKm / (durationSeconds / 3600)
      : null;

  /// Progress (0..1+) of [goal] given sessions inside the goal's current period.
  /// [kinds] optionally restricts the sessions counted to those activity kinds (null = all).
  /// [CardioGoal] has no kind field yet (needs a storage/schema change), so callers that know a
  /// goal's kind scope pass it here.
  static double goalValue(
    CardioGoal goal,
    Iterable<CardioSession> inPeriod, {
    Set<CardioKind>? kinds,
  }) {
    if (kinds != null) inPeriod = inPeriod.where((c) => kinds.contains(c.kind));
    switch (goal.metric) {
      case GoalMetric.durationMinutes:
        return inPeriod.fold(0, (a, c) => a + c.durationSeconds) / 60;
      case GoalMetric.distanceKm:
        return inPeriod.fold(0.0, (a, c) => a + (c.distanceKm ?? 0));
      case GoalMetric.sessions:
        return inPeriod.length.toDouble();
      case GoalMetric.calories:
        return inPeriod.fold(0, (a, c) => a + (c.calories ?? 0)).toDouble();
    }
  }
}
