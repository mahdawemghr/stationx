import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/domain/domain.dart';

RoutineExercise r(String id) => RoutineExercise(exerciseId: id);

void main() {
  final catalog = SeedData.fresh().exercises;

  test('groups consecutive exercises by muscle and keeps the order', () {
    final s = WorkoutSections.group([r('back_squat'), r('leg_press'), r('overhead_press'), r('lateral_raise'), r('face_pull')], catalog);
    expect(s.map((x) => x.label), ['Legs', 'Shoulders']);
    expect(s[0].items.map((e) => e.exerciseId), ['back_squat', 'leg_press']);
    expect(s[1].items.length, 3);
    expect(s[1].startIndex, 2);
    expect(s[0].sets, 6);
  });

  test('hamstring/glute/calf exercises join the Legs section', () {
    final s = WorkoutSections.group([r('back_squat'), r('rdl'), r('calf_raise')], catalog);
    expect(s.map((x) => x.label), ['Legs']);
    expect(s.single.items.length, 3);
  });

  test('an interleaved workout makes separate sections instead of reordering', () {
    final s = WorkoutSections.group([r('bench_press'), r('lat_pulldown'), r('incline_db_press')], catalog);
    expect(s.map((x) => x.label), ['Chest', 'Back', 'Chest']);
  });

  test('unknown ids are skipped; empty input gives no sections', () {
    expect(WorkoutSections.group([r('nope')], catalog), isEmpty);
    expect(WorkoutSections.group(const [], catalog), isEmpty);
  });
}
