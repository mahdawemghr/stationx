import '../models/models.dart';
import 'muscle_profiles.dart';

/// One visual section of a workout: consecutive exercises that train the same [region]
/// (e.g. "Legs", "Shoulders"). [startIndex] is the position of its first exercise in the workout.
class WorkoutSection {
  const WorkoutSection({required this.region, required this.startIndex, required this.items});
  final MuscleRegion region;
  final int startIndex;
  final List<RoutineExercise> items;

  int get sets => items.fold(0, (a, e) => a + e.sets);

  /// Broad label for headers: "Legs" for quadriceps/hamstrings/glutes/calves, otherwise the region label.
  String get label => sectionLabel(region);
}

/// Header label shared by every screen: lower-body regions read as "Legs", forearms as "Arms"-less "Forearms".
String sectionLabel(MuscleRegion r) => switch (r) {
      MuscleRegion.quadriceps || MuscleRegion.hamstrings || MuscleRegion.glutes || MuscleRegion.calves => 'Legs',
      _ => r.label,
    };

/// Groups a workout's exercises into muscle sections WITHOUT changing their order: a new section starts
/// whenever the (broad) muscle changes. Uses the same muscle metadata as the rest of the app
/// (built-in profiles and custom targets), never a screen-local rule. Unknown exercises are skipped.
abstract final class WorkoutSections {
  static List<WorkoutSection> group(List<RoutineExercise> exercises, List<Exercise> catalog) {
    final byId = {for (final e in catalog) e.id: e};
    final out = <WorkoutSection>[];
    var current = <RoutineExercise>[];
    String? currentLabel;
    MuscleRegion? currentRegion;
    var start = 0;
    for (var i = 0; i < exercises.length; i++) {
      final ex = byId[exercises[i].exerciseId];
      if (ex == null) continue;
      final region = MuscleProfiles.of(ex).primaryRegion;
      final label = sectionLabel(region);
      if (currentLabel != label) {
        if (current.isNotEmpty) out.add(WorkoutSection(region: currentRegion!, startIndex: start, items: current));
        current = [];
        currentLabel = label;
        currentRegion = region;
        start = i;
      }
      current.add(exercises[i]);
    }
    if (current.isNotEmpty) out.add(WorkoutSection(region: currentRegion!, startIndex: start, items: current));
    return out;
  }
}
