import '../../domain/domain.dart';

/// The catalog functions the setup flow needs. Defaults to [SplitCatalog];
/// tests inject small fixtures instead.
class SetupCatalog {
  SetupCatalog({
    List<SplitPreset>? presets,
    this.grouped = SplitCatalog.grouped,
    this.reasonFor = SplitCatalog.reasonFor,
    this.suggest = SplitCatalog.suggest,
  }) : presets = presets ?? SplitCatalog.presets;

  final List<SplitPreset> presets;
  final List<({SplitSection section, List<Exercise> exercises})> Function(MuscleGroup, List<Exercise>) grouped;
  final String? Function(String exerciseId) reasonFor;
  final List<RoutineExercise> Function(MuscleGroup, List<Exercise>) suggest;
}
