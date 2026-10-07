import '../../domain/domain.dart';

/// Built-in starter templates. These are static local presets (no popularity
/// numbers); adding one creates real [Workout]s via the repository.
class TemplateDay {
  const TemplateDay(this.name, this.exercises);
  final String name;
  final List<RoutineExercise> exercises;
}

class WorkoutTemplate {
  const WorkoutTemplate({required this.id, required this.name, required this.blurb, required this.days});
  final String id;
  final String name;
  final String blurb;
  final List<TemplateDay> days;

  int get exerciseCount => days.fold(0, (a, d) => a + d.exercises.length);
}

RoutineExercise _r(String id, [int sets = 3, int min = 8, int max = 12]) =>
    RoutineExercise(exerciseId: id, sets: sets, repMin: min, repMax: max);

final builtInTemplates = <WorkoutTemplate>[
  WorkoutTemplate(
    id: 'ppl',
    name: 'Push / Pull / Legs',
    blurb: 'Classic three-day rotation: pressing, pulling, then legs.',
    days: [
      TemplateDay('Push', [_r('bench_press', 4, 6, 10), _r('overhead_press'), _r('incline_db_press'), _r('lateral_raise', 3, 12, 15), _r('tricep_pushdown', 3, 10, 12)]),
      TemplateDay('Pull', [_r('pullup', 4, 6, 10), _r('barbell_row'), _r('lat_pulldown'), _r('face_pull', 3, 12, 15), _r('barbell_curl', 3, 10, 12)]),
      TemplateDay('Legs', [_r('back_squat', 4, 5, 8), _r('rdl', 3, 8, 10), _r('leg_press'), _r('leg_curl', 3, 10, 12), _r('calf_raise', 4, 12, 15)]),
    ],
  ),
  WorkoutTemplate(
    id: 'upper_lower',
    name: 'Upper / Lower',
    blurb: 'Two alternating days that hit every muscle with heavy compounds.',
    days: [
      TemplateDay('Upper', [_r('bench_press', 4, 6, 10), _r('barbell_row', 4, 6, 10), _r('overhead_press'), _r('lat_pulldown'), _r('barbell_curl', 3, 10, 12), _r('tricep_pushdown', 3, 10, 12)]),
      TemplateDay('Lower', [_r('back_squat', 4, 5, 8), _r('rdl', 3, 8, 10), _r('leg_press'), _r('leg_curl', 3, 10, 12), _r('calf_raise', 4, 12, 15), _r('cable_crunch', 3, 12, 15)]),
    ],
  ),
  WorkoutTemplate(
    id: 'full_body',
    name: 'Full Body',
    blurb: 'One balanced session covering push, pull, legs and core.',
    days: [
      TemplateDay('Full Body', [_r('back_squat', 3, 5, 8), _r('bench_press', 3, 6, 10), _r('barbell_row', 3, 6, 10), _r('overhead_press'), _r('rdl', 3, 8, 10), _r('cable_crunch', 3, 12, 15)]),
    ],
  ),
];
