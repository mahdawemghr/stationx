import '../models/models.dart';
import 'profile_dsl.dart';

/// Muscle metadata lookup. Built-in exercises have a detailed hand-written profile (keyed by id);
/// everything else (custom exercises, unknown ids) gets a broad, region-level profile derived from the
/// stored [Exercise.primaryMuscle]/[Exercise.secondaryMuscles] — never invented precision.
/// PURE DART.
abstract final class MuscleProfiles {
  /// Detailed profile for a built-in exercise id, or null.
  static ExerciseMuscleProfile? builtIn(String exerciseId) =>
      mergedBuiltInProfiles[exerciseId];

  static ExerciseMuscleProfile of(Exercise e) {
    final b = builtIn(e.id);
    if (b != null) return b;
    final t = MuscleTargetCodec.normalize(e.muscleTargets);
    return t != null ? ExerciseMuscleProfile(t) : derive(e);
  }

  /// Region-level fallback from the legacy broad fields.
  static ExerciseMuscleProfile derive(Exercise e) {
    MuscleRegion region(MuscleGroup g) => switch (g) {
      MuscleGroup.chest => MuscleRegion.chest,
      MuscleGroup.back => MuscleRegion.back,
      MuscleGroup.shoulders => MuscleRegion.shoulders,
      MuscleGroup.biceps => MuscleRegion.biceps,
      MuscleGroup.triceps => MuscleRegion.triceps,
      MuscleGroup.legs => MuscleRegion.quadriceps,
      MuscleGroup.core => MuscleRegion.core,
    };
    return ExerciseMuscleProfile([
      MuscleTarget.primary(region(e.primaryMuscle)),
      for (final s in e.secondaryMuscles) MuscleTarget.secondary(region(s)),
    ]);
  }
}
