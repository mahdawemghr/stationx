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
///
/// [muscles] is the legacy 7-way storage group list; [sectionMuscles] is the 8-way UI list (adds forearms,
/// and legs is one entry). Give either: the other is derived. When both are given they are kept as-is.
class SplitDayPlan {
  const SplitDayPlan({
    required this.name,
    List<MuscleGroup> muscles = const [],
    List<SectionMuscle>? sectionMuscles,
    this.exercises = const [],
  }) : _muscles = muscles,
       _sections = sectionMuscles;
  final String name;
  final List<MuscleGroup> _muscles;
  final List<SectionMuscle>? _sections;
  final List<RoutineExercise> exercises;

  /// Legacy broad groups (distinct, in order). Derived from [sectionMuscles] when only those were given.
  List<MuscleGroup> get muscles {
    final s = _sections;
    if (s == null || _muscles.isNotEmpty) return _muscles;
    return [
      for (final m in s)
        if (s.indexWhere((x) => x.legacy == m.legacy) == s.indexOf(m)) m.legacy,
    ];
  }

  /// The muscles that own this day's sections, in chosen order (the section order).
  List<SectionMuscle> get sectionMuscles {
    final s = _sections;
    if (s != null) return s;
    return [
      for (final m in _muscles)
        if (SectionMuscle.fromLegacy(m) != null) SectionMuscle.fromLegacy(m)!,
    ];
  }

  int get totalSets => exercises.fold(0, (a, e) => a + e.sets);
  int get estimatedMinutes => (totalSets * 3).clamp(0, 600);

  /// Passing only [muscles] re-derives [sectionMuscles] and vice versa.
  SplitDayPlan copyWith({
    String? name,
    List<MuscleGroup>? muscles,
    List<SectionMuscle>? sectionMuscles,
    List<RoutineExercise>? exercises,
  }) => SplitDayPlan(
    name: name ?? this.name,
    muscles: muscles ?? (sectionMuscles != null ? const [] : _muscles),
    sectionMuscles: sectionMuscles ?? (muscles != null ? null : _sections),
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
