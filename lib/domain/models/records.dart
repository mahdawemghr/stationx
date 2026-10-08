/// Strength PR categories (Personal Records filters).
enum PrType { heaviestWeight, mostReps, estimated1Rm, highestVolume }

class StrengthPr {
  const StrengthPr({
    required this.exerciseId,
    required this.type,
    required this.weightKg,
    required this.reps,
    required this.value,
    required this.date,
    this.previousValue,
  });

  final String exerciseId;
  final PrType type;
  final double weightKg;
  final int reps;

  /// Value in the PR's own measure (kg for weight/1RM/volume, reps for mostReps).
  final double value;

  /// `workoutDate` of the session that set the PR.
  final DateTime date;

  /// Previous best in the same measure, when one exists (for "+5 kg" deltas).
  final double? previousValue;

  double? get delta => previousValue == null ? null : value - previousValue!;
}

/// Output of ProgressionService — what the UI shows as "Recommended: …".
class ProgressionRecommendation {
  const ProgressionRecommendation({
    required this.weightKg,
    required this.repMin,
    required this.repMax,
    required this.reason,
    this.isIncrease = false,
  });
  final double weightKg;
  final int repMin;
  final int repMax;
  final String reason;
  final bool isIncrease;
}

enum CardioPrType { longestDuration, longestDistance, fastestPace }

class CardioPr {
  const CardioPr({
    required this.type,
    required this.sessionId,
    required this.value,
    required this.date,
    required this.kindLabel,
  });
  final CardioPrType type;
  final String sessionId;

  /// Seconds (duration), km (distance) or sec/km (pace).
  final double value;
  final DateTime date;
  final String kindLabel;
}
