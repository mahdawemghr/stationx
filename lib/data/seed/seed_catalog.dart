import '../../domain/domain.dart';

// MOCK DATA — exercise catalog. Replace with the Isar-backed catalog.
const _chest = MuscleGroup.chest, _back = MuscleGroup.back, _sh = MuscleGroup.shoulders;
const _bi = MuscleGroup.biceps, _tri = MuscleGroup.triceps, _legs = MuscleGroup.legs, _core = MuscleGroup.core;

Exercise _e(String id, String name, MuscleGroup p, Equipment eq, String pattern,
        {List<MuscleGroup> sec = const []}) =>
    Exercise(
      id: id,
      name: name,
      primaryMuscle: p,
      secondaryMuscles: sec,
      equipment: eq,
      movementPattern: pattern,
      instructions: _steps,
    );

const _steps = [
  ExerciseStep('Grip & Setup', 'Set the station to your body, take a stable grip and brace your core before the first rep.'),
  ExerciseStep('The Drive', 'Initiate the movement with the target muscle, keeping the joint path smooth and controlled.'),
  ExerciseStep('Peak Contraction', 'Pause briefly at full contraction without letting the torso swing or the shoulders roll forward.'),
  ExerciseStep('Controlled Eccentric', 'Return over 2–3 seconds, resisting the load until the muscle is fully lengthened.'),
];

List<Exercise> seedExercises() => [
      _e('bench_press', 'Barbell Bench Press', _chest, Equipment.barbell, 'Horizontal push', sec: [_tri, _sh]),
      _e('incline_db_press', 'Incline DB Press', _chest, Equipment.dumbbell, 'Incline push', sec: [_sh, _tri]),
      _e('cable_fly', 'Cable Flyes', _chest, Equipment.cable, 'Fly', sec: [_sh]),
      _e('pec_deck', 'Pec Deck', _chest, Equipment.machine, 'Fly', sec: [_sh]),
      _e('pushup', 'Push-Up', _chest, Equipment.bodyweight, 'Horizontal push', sec: [_tri, _sh]),
      _e('dips', 'Chest Dips', _chest, Equipment.bodyweight, 'Vertical push', sec: [_tri]),
      _e('lat_pulldown', 'Lat Pulldown', _back, Equipment.cable, 'Vertical pull', sec: [_bi]),
      _e('seated_cable_row', 'Seated Cable Row', _back, Equipment.cable, 'Horizontal pull', sec: [_bi]),
      _e('one_arm_cable_row', 'One Arm Cable Row', _back, Equipment.cable, 'Horizontal pull', sec: [_bi]),
      _e('single_arm_pulldown', 'Single-Arm Lat Pulldown', _back, Equipment.cable, 'Vertical pull', sec: [_bi]),
      _e('straight_arm_pulldown', 'Straight-Arm Pulldown', _back, Equipment.cable, 'Pullover'),
      _e('assisted_pullup', 'Assisted Pull-Up', _back, Equipment.machine, 'Vertical pull', sec: [_bi]),
      _e('pullup', 'Pull-Up', _back, Equipment.bodyweight, 'Vertical pull', sec: [_bi]),
      _e('db_row', 'One-Arm Dumbbell Row', _back, Equipment.dumbbell, 'Horizontal pull', sec: [_bi]),
      _e('barbell_row', 'Barbell Row', _back, Equipment.barbell, 'Horizontal pull', sec: [_bi]),
      _e('deadlift', 'Barbell Deadlift', _back, Equipment.barbell, 'Hinge', sec: [_legs, _core]),
      _e('face_pull', 'Face Pull', _sh, Equipment.cable, 'Rear delt', sec: [_back]),
      _e('overhead_press', 'Overhead Press', _sh, Equipment.barbell, 'Vertical push', sec: [_tri]),
      _e('db_shoulder_press', 'DB Shoulder Press', _sh, Equipment.dumbbell, 'Vertical push', sec: [_tri]),
      _e('lateral_raise', 'Lateral Raise', _sh, Equipment.dumbbell, 'Raise'),
      _e('cable_lateral_raise', 'Cable Lateral Raise', _sh, Equipment.cable, 'Raise'),
      _e('barbell_curl', 'Barbell Curl', _bi, Equipment.barbell, 'Curl'),
      _e('hammer_curl', 'Hammer Curl', _bi, Equipment.dumbbell, 'Curl'),
      _e('cable_curl', 'Cable Curl', _bi, Equipment.cable, 'Curl'),
      _e('preacher_curl', 'Preacher Curl', _bi, Equipment.machine, 'Curl'),
      _e('tricep_pushdown', 'Tricep Pushdown', _tri, Equipment.cable, 'Extension'),
      _e('overhead_tri_ext', 'Overhead Triceps Extension', _tri, Equipment.dumbbell, 'Overhead extension'),
      _e('cable_oh_tri_ext', 'Cable Overhead Extension', _tri, Equipment.cable, 'Overhead extension'),
      _e('skullcrusher', 'Skull Crusher', _tri, Equipment.barbell, 'Extension'),
      _e('back_squat', 'Barbell Back Squat', _legs, Equipment.barbell, 'Squat', sec: [_core]),
      _e('leg_press', 'Leg Press', _legs, Equipment.machine, 'Squat'),
      _e('rdl', 'Romanian Deadlift', _legs, Equipment.barbell, 'Hinge', sec: [_back]),
      _e('leg_extension', 'Leg Extension', _legs, Equipment.machine, 'Extension'),
      _e('leg_curl', 'Leg Curl', _legs, Equipment.machine, 'Curl'),
      _e('calf_raise', 'Standing Calf Raise', _legs, Equipment.machine, 'Raise'),
      _e('goblet_squat', 'Goblet Squat', _legs, Equipment.dumbbell, 'Squat'),
      _e('plank', 'Plank', _core, Equipment.bodyweight, 'Isometric'),
      _e('cable_crunch', 'Cable Crunch', _core, Equipment.cable, 'Crunch'),
    ];
