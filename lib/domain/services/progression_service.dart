import '../models/models.dart';

/// Provisional double-progression engine (no prior engine existed in repo).
/// Rule: if every working set of the last session reached [repMax] at the
/// same weight, add one increment and restart at [repMin]; otherwise keep the
/// weight and aim for +1 rep. Replace here when the real engine lands — the UI
/// only consumes [ProgressionRecommendation].
abstract final class ProgressionService {
  static ProgressionRecommendation? recommend({
    required List<SetLog> lastSets,
    required int repMin,
    required int repMax,
    required double incrementKg,
  }) {
    final done = lastSets.where((s) => s.done && s.reps > 0).toList();
    if (done.isEmpty) return null;
    final top = done.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
    final atTop = done.where((s) => s.weightKg == top).toList();
    final hitAll = atTop.every((s) => s.reps >= repMax);
    if (hitAll) {
      return ProgressionRecommendation(
        weightKg: top + incrementKg,
        repMin: repMin,
        repMax: repMax,
        isIncrease: true,
        reason: 'You reached $repMax reps on every set at ${_fmt(top)} kg.',
      );
    }
    final best = atTop.map((s) => s.reps).reduce((a, b) => a > b ? a : b);
    return ProgressionRecommendation(
      weightKg: top,
      repMin: (best + 1).clamp(repMin, repMax),
      repMax: repMax,
      reason: 'Keep ${_fmt(top)} kg and add a rep — best last time was $best.',
    );
  }

  /// Smallest sensible jump: 2.5 kg for isolation/cable/dumbbell, 5 kg for barbell.
  static double incrementFor(Exercise e) => e.equipment == Equipment.barbell ? 5 : 2.5;

  static String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
