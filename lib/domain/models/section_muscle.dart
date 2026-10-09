import 'enums.dart';
import 'muscle.dart';

/// The eight broad muscles that own a workout SECTION and that UI-level pickers/filters use. Declaration
/// order is the canonical section order. Storage keeps the 7-way [MuscleGroup] ([legacy]); there is no
/// schema change: forearms map to [MuscleGroup.biceps] exactly like [MuscleRegion.forearms] does.
enum SectionMuscle {
  chest('Chest', [MuscleRegion.chest], MuscleGroup.chest),
  back('Back', [MuscleRegion.back], MuscleGroup.back),
  shoulders('Shoulders', [MuscleRegion.shoulders], MuscleGroup.shoulders),
  biceps('Biceps', [MuscleRegion.biceps], MuscleGroup.biceps),
  triceps('Triceps', [MuscleRegion.triceps], MuscleGroup.triceps),
  forearms('Forearms', [MuscleRegion.forearms], MuscleGroup.biceps),
  legs('Legs', [
    MuscleRegion.quadriceps,
    MuscleRegion.hamstrings,
    MuscleRegion.glutes,
    MuscleRegion.calves,
  ], MuscleGroup.legs),
  core('Core', [MuscleRegion.core], MuscleGroup.core);

  const SectionMuscle(this.label, this.regions, this.legacy);
  final String label;
  final List<MuscleRegion> regions;

  /// Broad storage group (forearms -> biceps so legacy consumers keep working).
  final MuscleGroup legacy;

  /// The section a detailed region belongs to (total).
  static SectionMuscle of(MuscleRegion r) => switch (r) {
    MuscleRegion.chest => chest,
    MuscleRegion.back => back,
    MuscleRegion.shoulders => shoulders,
    MuscleRegion.biceps => biceps,
    MuscleRegion.triceps => triceps,
    MuscleRegion.forearms => forearms,
    MuscleRegion.quadriceps ||
    MuscleRegion.hamstrings ||
    MuscleRegion.glutes ||
    MuscleRegion.calves => legs,
    MuscleRegion.core => core,
  };

  /// The section for a stored broad group (biceps -> biceps; forearms can never come from storage).
  static SectionMuscle? fromLegacy(MuscleGroup g) => switch (g) {
    MuscleGroup.chest => chest,
    MuscleGroup.back => back,
    MuscleGroup.shoulders => shoulders,
    MuscleGroup.biceps => biceps,
    MuscleGroup.triceps => triceps,
    MuscleGroup.legs => legs,
    MuscleGroup.core => core,
  };
}
