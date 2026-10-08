/// Highest rep count for which [estimateOneRepMax] is considered a usable estimate.
const int maxReliableE1rmReps = 12;

/// Estimated one-rep max. Epley: W × (1 + R/30). Single source of truth —
/// widgets must call this (or PrService), never re-implement it.
///
/// Returns 0 ("no reliable estimate") for non-positive weight/reps and for
/// more than [maxReliableE1rmReps] reps: Epley extrapolates absurdly far
/// (100 kg × 30 would claim 200 kg). A single rep returns the weight itself.
double estimateOneRepMax(double weightKg, int reps) {
  if (weightKg <= 0 || reps <= 0) return 0;
  if (reps > maxReliableE1rmReps) return 0;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30);
}
