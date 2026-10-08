import '../models/models.dart';

/// A sub-section of a muscle group used by the schedule setup (e.g. Back → Lats / Upper back / Lower back).
class SplitSection {
  const SplitSection({
    required this.id,
    required this.label,
    required this.muscle,
    this.hint = '',
  });
  final String id;
  final String label;
  final MuscleGroup muscle;

  /// One short line explaining what the section trains.
  final String hint;
}

/// One training day being designed: a name, the muscles it trains and its exercises.
class SplitDayPlan {
  const SplitDayPlan({
    required this.name,
    required this.muscles,
    this.exercises = const [],
  });
  final String name;
  final List<MuscleGroup> muscles;
  final List<RoutineExercise> exercises;

  int get totalSets => exercises.fold(0, (a, e) => a + e.sets);
  int get estimatedMinutes => (totalSets * 3).clamp(0, 600);

  SplitDayPlan copyWith({
    String? name,
    List<MuscleGroup>? muscles,
    List<RoutineExercise>? exercises,
  }) => SplitDayPlan(
    name: name ?? this.name,
    muscles: muscles ?? this.muscles,
    exercises: exercises ?? this.exercises,
  );
}

/// A ready-made schedule the user can start from (or edit).
class SplitPreset {
  const SplitPreset({
    required this.id,
    required this.name,
    required this.blurb,
    required this.days,
    this.suggestedDaysPerWeek = '',
  });
  final String id;
  final String name;
  final String blurb;

  /// e.g. "3–6 days / week" (text only; the rotation is index-based, never calendar-based).
  final String suggestedDaysPerWeek;
  final List<SplitDayPlan> days;
}
