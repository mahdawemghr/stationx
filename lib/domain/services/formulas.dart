/// Estimated one-rep max. Epley: W × (1 + R/30). Single source of truth —
/// widgets must call this (or PrService), never re-implement it.
double estimateOneRepMax(double weightKg, int reps) {
  if (weightKg <= 0 || reps <= 0) return 0;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30);
}
