import 'enums.dart';
import 'muscle.dart';
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
    this.muscleTargets,
    SyncMeta? meta,
  }) : meta = meta ?? SyncMeta();

  /// Builds a CUSTOM exercise whose broad legacy fields are DERIVED from [targets] so every screen/filter/sync
  /// consumer that only knows the 7-way [MuscleGroup] stays consistent: primary = first primary target's
  /// region.legacy; secondaries = the other targets' distinct legacy groups minus the primary.
  /// [targets] are normalised (deduped, >=1 primary required, else [ArgumentError]).
  factory Exercise.custom({
    required String id,
    required String name,
    required List<MuscleTarget> targets,
    required Equipment equipment,
    String movementPattern = '',
    List<ExerciseStep> instructions = const [],
    String? tempo,
    SyncMeta? meta,
  }) {
    final t = MuscleTargetCodec.normalize(targets);
    if (t == null) throw ArgumentError('A custom exercise needs at least one primary muscle target');
    final primary = t.firstWhere((x) => x.role == TargetRole.primary).region.legacy;
    final secondary = <MuscleGroup>[];
    for (final x in t) {
      final g = x.region.legacy;
      if (g != primary && !secondary.contains(g)) secondary.add(g);
    }
    return Exercise(
      id: id,
      name: name,
      primaryMuscle: primary,
      secondaryMuscles: secondary,
      equipment: equipment,
      movementPattern: movementPattern,
      instructions: instructions,
      isCustom: true,
      tempo: tempo,
      muscleTargets: List.unmodifiable(t),
      meta: meta,
    );
  }

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

  /// Structured muscle targets of a CUSTOM exercise (null = none stored; built-ins use
  /// `MuscleProfiles.builtIn`). When present, [primaryMuscle]/[secondaryMuscles] are derived from it.
  final List<MuscleTarget>? muscleTargets;
  final SyncMeta meta;
}

class ExerciseStep {
  const ExerciseStep(this.title, this.text);
  final String title;
  final String text;
}
