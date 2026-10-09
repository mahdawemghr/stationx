import '../../domain/domain.dart';

/// One picker group inside a muscle's section: [label] is null for the MAIN group (no sub-header).
typedef SetupGroup = ({String? label, String hint, List<Exercise> exercises});

/// The section (broad muscle) an exercise belongs to, exactly as workouts section it.
SectionMuscle sectionOf(Exercise e) => SectionMuscle.of(MuscleProfiles.of(e).primaryRegion);

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

  bool get _defaultGrouped => grouped == SplitCatalog.grouped;
  bool get _defaultSuggest => suggest == SplitCatalog.suggest;

  /// The picker view of ONE section: MAIN exercises first (no sub-header), then the sub-areas in the same
  /// canonical order [WorkoutSections] saves them in. With an injected [grouped] (tests) its groups are used.
  List<SetupGroup> groupedSection(SectionMuscle m, List<Exercise> all) {
    if (!_defaultGrouped) {
      return [
        for (final g in grouped(m.legacy, all))
          if (g.exercises.any((e) => sectionOf(e) == m))
            (
              label: g.section.label,
              hint: g.section.hint,
              exercises: [for (final e in g.exercises) if (sectionOf(e) == m) e],
            ),
      ];
    }
    // Curated order first (so ties inside a sub-area keep it), then anything else that sections here.
    final ordered = <Exercise>[];
    final seen = <String>{};
    for (final g in SplitCatalog.grouped(m.legacy, all)) {
      for (final e in g.exercises) {
        if (seen.add(e.id)) ordered.add(e);
      }
    }
    for (final e in all) {
      if (seen.add(e.id)) ordered.add(e);
    }
    final mine = [for (final e in ordered) if (sectionOf(e) == m) e];
    if (mine.isEmpty) return const [];
    final byId = {for (final e in mine) e.id: e};
    final sections = WorkoutSections.group([for (final e in mine) RoutineExercise(exerciseId: e.id)], all);
    return [
      for (final s in sections)
        if (s.muscle == m)
          for (final g in s.groups)
            (label: g.label, hint: '', exercises: [for (final r in g.items) byId[r.exerciseId]!]),
    ];
  }

  /// The recommended picks for a section's regions (forearms included; may be empty or short).
  List<RoutineExercise> suggestSection(SectionMuscle m, List<Exercise> all) {
    List<RoutineExercise> picks;
    if (m == SectionMuscle.forearms && _defaultSuggest) {
      picks = ExerciseRecommender.forDay(
        regions: const [MuscleRegion.forearms],
        catalog: [for (final e in all) if (sectionOf(e) == m) e],
        daysPerWeek: 3,
        maxExercises: 3,
        minExercises: 1,
      );
    } else {
      picks = suggest(m.legacy, all);
    }
    final byId = {for (final e in all) e.id: e};
    return [
      for (final r in picks)
        if (byId[r.exerciseId] != null && sectionOf(byId[r.exerciseId]!) == m) r,
    ];
  }
}
