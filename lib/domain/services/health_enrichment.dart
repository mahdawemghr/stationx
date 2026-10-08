import '../models/models.dart';

/// Decides what the health store can add to a cardio session. Never overwrites a value the user
/// typed and never returns a value for a field that is already set.
abstract final class HealthEnrichmentService {
  static const minBpm = 30.0;
  static const maxBpm = 230.0;
  static const maxCalories = 20000;

  static HealthEnrichment suggest(CardioSession s, HealthMetrics m) {
    int? hr;
    if (s.avgHeartRate == null) {
      final ok = [
        for (final b in m.heartRates)
          if (b.isFinite && b >= minBpm && b <= maxBpm) b,
      ];
      if (ok.isNotEmpty) {
        hr = (ok.reduce((a, b) => a + b) / ok.length).round();
      }
    }
    int? kcal;
    if (s.calories == null) {
      // Active energy is what a workout "burned"; total includes resting metabolism.
      final v = (m.activeKcal != null && m.activeKcal! > 0)
          ? m.activeKcal
          : m.totalKcal;
      if (v != null && v.isFinite && v >= 1 && v <= maxCalories) {
        kcal = v.round();
      }
    }
    return HealthEnrichment(avgHeartRate: hr, calories: kcal);
  }

  /// Applies a confirmed suggestion; still only fills fields that are empty at apply time.
  static CardioSession apply(CardioSession s, HealthEnrichment e) => s.copyWith(
    avgHeartRate: s.avgHeartRate == null ? e.avgHeartRate : null,
    calories: s.calories == null ? e.calories : null,
  );
}
