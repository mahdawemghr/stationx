import 'enums.dart';
import 'sync_meta.dart';

class Exercise {
  Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    this.movementPattern = '',
    this.instructions = const [],
    this.isCustom = false,
    this.tempo,
    SyncMeta? meta,
  }) : meta = meta ?? SyncMeta();

  final String id;
  final String name;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final Equipment equipment;

  /// e.g. "Vertical pull", "Horizontal pull" — used by Smart Swap.
  final String movementPattern;

  /// Execution steps (title → text), shown on Exercise Details.
  final List<ExerciseStep> instructions;
  final bool isCustom;

  /// Optional tempo prescription, e.g. "3-0-1-0". Shown only when present.
  final String? tempo;
  final SyncMeta meta;
}

class ExerciseStep {
  const ExerciseStep(this.title, this.text);
  final String title;
  final String text;
}
