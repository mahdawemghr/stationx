part of '../profile_dsl.dart';

// Muscle profiles: core. Add new entries at the END of the map (keys unique across ALL parts).
// Helpers (_p, _pr, _s, _sr, _x, _stab, region aliases) live in profile_dsl.dart.
final Map<String, ExerciseMuscleProfile> profilesCore = {
  'plank': _x([_p(Muscle.transverseAbdominis), _p(Muscle.rectusAbdominis)]),
  'cable_crunch': _x([_p(Muscle.rectusAbdominis)]),
  'crunch': _x([_p(Muscle.rectusAbdominis)]),
  'hanging_leg_raise': _x([_p(Muscle.rectusAbdominis)], [_s(Muscle.obliques)]),
  'ab_wheel': _x(
    [_p(Muscle.rectusAbdominis)],
    [_s(Muscle.transverseAbdominis)],
  ),
  'side_plank': _x([_p(Muscle.obliques)], [_s(Muscle.transverseAbdominis)]),
  'russian_twist': _x([_p(Muscle.obliques)], [_s(Muscle.rectusAbdominis)]),
  'decline_situp': _x([_p(Muscle.rectusAbdominis)]),
  'reverse_crunch': _x([_p(Muscle.rectusAbdominis)]),
  'hanging_knee_raise': _x([_p(Muscle.rectusAbdominis)], [_s(Muscle.obliques)]),
  'machine_crunch': _x([_p(Muscle.rectusAbdominis)]),
  'bicycle_crunch': _x([_p(Muscle.rectusAbdominis), _p(Muscle.obliques)]),
  'v_up': _x([_p(Muscle.rectusAbdominis)]),
  'toes_to_bar': _x(
    [_p(Muscle.rectusAbdominis)],
    [_s(Muscle.obliques), _s(Muscle.lats)],
  ),
  'lying_leg_raise': _x([_p(Muscle.rectusAbdominis)]),
  'dragon_flag': _x(
    [_p(Muscle.rectusAbdominis)],
    [_s(Muscle.transverseAbdominis)],
  ),
  'pallof_press': _x(
    [_p(Muscle.obliques, 'Anti-rotation')],
    [_s(Muscle.transverseAbdominis)],
  ),
  'cable_woodchop': _x([_p(Muscle.obliques)], [_s(Muscle.rectusAbdominis)]),
  'suitcase_carry': _x(
    [_p(Muscle.obliques, 'Anti-lateral flexion')],
    [_s(Muscle.transverseAbdominis), _s(Muscle.wristFlexors)],
  ),
  'dead_bug': _x([_p(Muscle.transverseAbdominis), _p(Muscle.rectusAbdominis)]),
  'bird_dog': _x(
    [_p(Muscle.transverseAbdominis)],
    [_s(Muscle.lowerBack), _s(Muscle.gluteusMaximus)],
  ),
  'hollow_hold': _x([
    _p(Muscle.transverseAbdominis),
    _p(Muscle.rectusAbdominis),
  ]),
  'stir_the_pot': _x(
    [_p(Muscle.transverseAbdominis), _p(Muscle.rectusAbdominis)],
    [_s(Muscle.obliques)],
  ),
  'side_bend': _x([_p(Muscle.obliques)]),
  'sit_up': _x([_p(Muscle.rectusAbdominis)]),
  'ab_coaster': _x([_p(Muscle.rectusAbdominis)]),
  'captains_chair_knee_raise': _x(
    [_p(Muscle.rectusAbdominis)],
    [_s(Muscle.obliques)],
  ),
  'flutter_kicks': _x([_p(Muscle.rectusAbdominis)]),
  'l_sit_hold': _x(
    [_p(Muscle.rectusAbdominis)],
    [_sr(_tri), _sr(MuscleRegion.shoulders)],
  ),
  'barbell_rollout': _x(
    [_p(Muscle.rectusAbdominis)],
    [_s(Muscle.transverseAbdominis)],
  ),
  'mountain_climber': _x(
    [_p(Muscle.rectusAbdominis)],
    [_sr(MuscleRegion.shoulders), _sr(_quad)],
  ),
  'torso_rotation_machine': _x(
    [_p(Muscle.obliques)],
    [_s(Muscle.rectusAbdominis)],
  ),
  'cable_oblique_crunch': _x(
    [_p(Muscle.obliques)],
    [_s(Muscle.rectusAbdominis)],
  ),
  'cable_side_bend': _x([_p(Muscle.obliques)]),
  'overhead_pallof_press': _x(
    [_p(Muscle.obliques, 'Anti-rotation')],
    [_s(Muscle.transverseAbdominis), _sr(MuscleRegion.shoulders)],
  ),
  'half_kneeling_cable_chop': _x(
    [_p(Muscle.obliques)],
    [_s(Muscle.rectusAbdominis)],
  ),
  'band_pallof_press': _x(
    [_p(Muscle.obliques, 'Anti-rotation')],
    [_s(Muscle.transverseAbdominis)],
  ),
  // Sources: StrengthLog / Sole — the exercise exists to load the inner thigh; obliques are co-primary.
  'copenhagen_plank': _x(
    [_p(Muscle.obliques), _pr(_glu, 'Inner thigh (adductors)')],
    [_s(Muscle.transverseAbdominis), _s(Muscle.gluteusMedius)],
  ),
  'side_plank_hip_dip': _x(
    [_p(Muscle.obliques)],
    [_s(Muscle.transverseAbdominis)],
  ),
  'kb_windmill': _x([_p(Muscle.obliques)], [_sr(MuscleRegion.shoulders), _s(Muscle.gluteusMaximus), _sr(_ham)]),
  'turkish_get_up': _x([_pr(_core)], [_sr(MuscleRegion.shoulders), _sr(_glu)]),
  'db_overhead_carry': _x(
    [_pr(_core)],
    [_sr(MuscleRegion.shoulders), _s(Muscle.traps)],
  ),
  'landmine_twist': _x(
    [_p(Muscle.obliques)],
    [_s(Muscle.rectusAbdominis), _sr(MuscleRegion.shoulders)],
  ),
};
