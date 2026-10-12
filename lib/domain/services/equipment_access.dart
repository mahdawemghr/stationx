import '../models/models.dart';
import 'exercise_recommender.dart';
import 'muscle_profiles.dart';
import 'smart_swap_service.dart';
import 'split_models.dart';

/// Which equipment the user can train with. `null` means "not chosen yet": nothing is filtered.
/// Bodyweight needs no equipment, so it is always allowed.
abstract final class EquipmentAccess {
  /// What the onboarding question lists (bodyweight is implied).
  static const List<Equipment> choosable = [
    Equipment.barbell,
    Equipment.dumbbell,
    Equipment.machine,
    Equipment.cable,
    Equipment.smithMachine,
    Equipment.kettlebell,
    Equipment.band,
    Equipment.other,
  ];

  static const Set<Equipment> everything = {...Equipment.values};

  /// The set an exercise search must stay inside for [chosen].
  static Set<Equipment> allowed(Set<Equipment>? chosen) =>
      chosen == null ? everything : {...chosen, Equipment.bodyweight};

  static bool permits(Set<Equipment>? chosen, Exercise e) =>
      chosen == null || allowed(chosen).contains(e.equipment);
}

/// What [ProgramEquipmentFit] did to a program.
class FitReport {
  const FitReport({
    required this.days,
    this.leftOut = 0,
    this.advancedFallback = const {},
  });
  final List<SplitDayPlan> days;

  /// Exercises removed because nothing close enough exists for the user's equipment/level.
  final int leftOut;

  /// Advanced exercises a BEGINNER still got because nothing easier covers that movement.
  final Set<String> advancedFallback;
}

/// Makes a hand-picked starting program (a preset) fit the user's equipment and experience level. Only
/// runs when the user builds a program in onboarding; a saved program is never touched by it.
abstract final class ProgramEquipmentFit {
  /// A replacement must match at least this well (0..100, see [ExerciseRecommender.replacements]).
  static const int minReplacementMatch = 60;

  /// How many points a loadable alternative may score below the top one and still be preferred.
  static const int loadedPreferenceMargin = 25;

  /// Keeps every exercise of [day] the user can do. An exercise they cannot do (equipment) or, for a
  /// [level] of beginner, an advanced one (intermediates only avoid advanced REPLACEMENTS), is replaced by the best close alternative from the same muscle
  /// section that is not already in the day. When nothing is close enough: an exercise that is merely
  /// advanced is KEPT and reported as an advanced fallback (never silently dropped, so the muscle stays
  /// covered); one the user lacks the equipment for is left out. Sets and reps are kept.
  static FitReport fitDayReport(
    SplitDayPlan day,
    List<Exercise> catalog,
    Set<Equipment>? chosen, {
    Difficulty? level,
  }) {
    final avoidAdvanced =
        level == Difficulty.beginner || level == Difficulty.intermediate;
    if (chosen == null && level != Difficulty.beginner) {
      return FitReport(days: [day]);
    }
    final byId = {for (final e in catalog) e.id: e};
    final allowed = chosen == null ? null : EquipmentAccess.allowed(chosen);
    final beginner = level == Difficulty.beginner;
    final used = {for (final r in day.exercises) r.exerciseId};
    final out = <RoutineExercise>[];
    final fallback = <String>{};
    var leftOut = 0;

    SwapCandidate? pickFor(Exercise e, {required bool excludeAdvanced}) {
      final section = SectionMuscle.of(MuscleProfiles.of(e).primaryRegion);
      final options = ExerciseRecommender.replacements(
        current: e,
        catalog: catalog,
        allowedEquipment: allowed,
        excludeIds: used,
        excludeAdvanced: excludeAdvanced,
      );
      final close = [
        for (final o in options)
          if (o.matchPercent >= minReplacementMatch &&
              SectionMuscle.of(MuscleProfiles.of(o.exercise).primaryRegion) ==
                  section)
            o,
      ];
      if (close.isEmpty) return null;
      // Prefer something the user can load with the gear they picked over a bodyweight skill move,
      // unless it is clearly a worse match.
      final top = close.first;
      final loaded = close.where(
        (o) =>
            chosen != null &&
            chosen.contains(o.exercise.equipment) &&
            !o.exercise.equipment.isUnloaded &&
            o.matchPercent >= top.matchPercent - loadedPreferenceMargin,
      );
      return loaded.isEmpty ? top : loaded.first;
    }

    for (final r in day.exercises) {
      final e = byId[r.exerciseId];
      final equipmentOk =
          e == null || allowed == null || allowed.contains(e.equipment);
      final tooHard =
          beginner && e != null && e.difficulty == Difficulty.advanced;
      if (e == null || (equipmentOk && !tooHard)) {
        out.add(r);
        continue;
      }
      var pick = pickFor(e, excludeAdvanced: avoidAdvanced);
      if (pick == null && equipmentOk) {
        out.add(
          r,
        ); // only too advanced and nothing easier is close: keep it, say so
        fallback.add(e.id);
        continue;
      }
      pick ??= avoidAdvanced ? pickFor(e, excludeAdvanced: false) : null;
      if (pick == null) {
        leftOut++;
        continue;
      }
      used.add(pick.exercise.id);
      if (avoidAdvanced && pick.exercise.difficulty == Difficulty.advanced) {
        fallback.add(pick.exercise.id);
      }
      out.add(r.copyWith(exerciseId: pick.exercise.id));
    }
    return FitReport(
      days: [day.copyWith(exercises: out)],
      leftOut: leftOut,
      advancedFallback: fallback,
    );
  }

  static SplitDayPlan fitDay(
    SplitDayPlan day,
    List<Exercise> catalog,
    Set<Equipment>? chosen, {
    Difficulty? level,
  }) => fitDayReport(day, catalog, chosen, level: level).days.first;

  static FitReport fitReport(
    List<SplitDayPlan> days,
    List<Exercise> catalog,
    Set<Equipment>? chosen, {
    Difficulty? level,
  }) {
    final parts = [
      for (final d in days) fitDayReport(d, catalog, chosen, level: level),
    ];
    return FitReport(
      days: [for (final p in parts) p.days.first],
      leftOut: parts.fold(0, (a, p) => a + p.leftOut),
      advancedFallback: {for (final p in parts) ...p.advancedFallback},
    );
  }

  static List<SplitDayPlan> fit(
    List<SplitDayPlan> days,
    List<Exercise> catalog,
    Set<Equipment>? chosen, {
    Difficulty? level,
  }) => fitReport(days, catalog, chosen, level: level).days;
}
