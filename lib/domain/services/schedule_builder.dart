import '../models/models.dart';
import '../repositories/repositories.dart';
import 'split_models.dart';
import 'workout_sections.dart';

class ScheduleSaveResult {
  const ScheduleSaveResult({
    required this.workoutIds,
    required this.archivedOld,
  });
  final List<String> workoutIds;

  /// Ids that were in the old rotation and are not in the new one. They are kept (never deleted),
  /// just out of the rotation, and can be put back with [ScheduleBuilder.restore].
  final List<String> archivedOld;
}

/// Turns the designed days into real [Workout]s + a fresh rotation. Idempotent per [stamp].
abstract final class ScheduleBuilder {
  /// A day is valid when it has a name and at least one exercise that exists in [catalog].
  static String? validate(List<SplitDayPlan> days, List<Exercise> catalog) {
    if (days.isEmpty) return 'Add at least one day.';
    final ids = {for (final e in catalog) e.id};
    final names = <String>{};
    for (final d in days) {
      final n = d.name.trim();
      if (n.isEmpty) return 'Every day needs a name.';
      if (!names.add(n.toLowerCase())) return 'Two days are called "$n".';
      if (!d.exercises.any((e) => ids.contains(e.exerciseId))) {
        return '"$n" has no exercises.';
      }
    }
    return null;
  }

  /// Saves the days as workouts (ids `w_<stamp>_<i>`), makes them the rotation (starting at day 1) and
  /// archives the previous rotation. [mode] is `full` (canonical order) for the setup flow; pass
  /// `musclesOnly` when re-saving days whose manual sub-area order must be kept. NEVER deletes anything: archived workouts simply leave the
  /// rotation, and workouts that were never in it stay untouched. Sessions are never modified.
  static Future<ScheduleSaveResult> save(
    List<SplitDayPlan> days, {
    required WorkoutRepository workouts,
    SessionRepository? sessions,
    required List<Exercise> catalog,
    required String stamp,
    String description = 'My schedule',
    ArrangeMode mode = ArrangeMode.full,
  }) async {
    final error = validate(days, catalog);
    if (error != null) throw ArgumentError(error);
    final known = {for (final e in catalog) e.id};
    final old = [...workouts.rotation.workoutIds];
    final ids = <String>[];
    final built = <Workout>[];
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      final id = 'w_${stamp}_$i';
      ids.add(id);
      built.add(
        Workout(
          id: id,
          name: d.name.trim(),
          description: description,
          exercises: WorkoutSections.arrange(
            [
              for (final e in d.exercises)
                if (known.contains(e.exerciseId)) e,
            ],
            catalog,
            muscleOrder: d.sectionMuscles,
            mode: mode,
          ),
        ),
      );
    }
    // One atomic save: the new days and the rotation that points at them are stored together.
    await workouts.saveSchedule(
      built,
      Rotation(workoutIds: ids, currentIndex: 0),
    );
    final archived = [
      for (final id in old)
        if (!ids.contains(id)) id,
    ];
    return ScheduleSaveResult(workoutIds: ids, archivedOld: archived);
  }

  /// Puts an archived workout back at the END of the rotation. No-op when it is already in the
  /// rotation or does not exist.
  static Future<void> restore(
    String workoutId,
    WorkoutRepository workouts,
  ) async {
    final rot = workouts.rotation;
    if (rot.workoutIds.contains(workoutId)) return;
    if (workouts.byId(workoutId) == null) return;
    await workouts.setRotation(
      Rotation(
        workoutIds: [...rot.workoutIds, workoutId],
        currentIndex: rot.currentIndex,
      ),
    );
  }
}
