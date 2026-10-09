part of '../profile_dsl.dart';

// Muscle profiles: quads. Add new entries at the END of the map (keys unique across ALL parts).
// Helpers (_p, _pr, _s, _sr, _x, _stab, region aliases) live in profile_dsl.dart.
final Map<String, ExerciseMuscleProfile> profilesQuads = {
  'back_squat': _x([_pr(_quad), _p(Muscle.gluteusMaximus)], [_sr(_ham), _stab]),
  'hack_squat': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus)]),
  'leg_press': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus)]),
  'goblet_squat': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus)]),
  'bulgarian_split_squat': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _stab],
  ),
  'walking_lunge': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _stab],
  ),
  'leg_extension': _x([_pr(_quad, 'Isolates all quad heads')]),
  'front_squat': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus), _stab]),
  'smith_machine_squat': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus)]),
  'pendulum_squat': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus)]),
  'belt_squat': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus)]),
  'single_leg_press': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus)]),
  'leg_press_feet_low': _x(
    [_pr(_quad, 'Low foot placement')],
    [_s(Muscle.gluteusMaximus)],
  ),
  'trap_bar_deadlift': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [
      _sr(_ham),
      _s(Muscle.lowerBack),
      _s(Muscle.traps),
      _s(Muscle.brachioradialis),
    ],
  ),
  'sumo_deadlift': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _s(Muscle.lowerBack), _s(Muscle.traps)],
  ),
  'reverse_lunge': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _stab],
  ),
  'forward_lunge': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _stab],
  ),
  'db_step_up': _x([_pr(_quad), _p(Muscle.gluteusMaximus)], [_sr(_ham), _stab]),
  'lateral_lunge': _x(
    [_pr(_quad)],
    [_s(Muscle.gluteusMaximus), _s(Muscle.gluteusMedius)],
  ),
  'cossack_squat': _x(
    [_pr(_quad)],
    [_s(Muscle.gluteusMaximus), _s(Muscle.gluteusMedius)],
  ),
  'smith_split_squat': _x([_pr(_quad), _p(Muscle.gluteusMaximus)], [_sr(_ham)]),
  'single_leg_extension': _x([_pr(_quad)]),
  'sissy_squat': _x([_pr(_quad, 'Deep knee-dominant stretch')]),
  'reverse_nordic_curl': _x([_pr(_quad, 'Stretch under load')]),
  'wall_sit': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus)]),
  'bodyweight_squat': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus)]),
  'low_bar_squat': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _s(Muscle.lowerBack), _stab],
  ),
  'pause_squat': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _stab],
  ),
  'box_squat': _x([_pr(_quad), _p(Muscle.gluteusMaximus)], [_sr(_ham), _stab]),
  'safety_bar_squat': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _stab],
  ),
  'zercher_squat': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _s(Muscle.upperBack), _stab],
  ),
  'landmine_squat': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus), _stab]),
  'kb_front_rack_squat': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus), _stab]),
  'kb_thruster': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_s(Muscle.frontDelts), _s(Muscle.sideDelts), _stab],
  ),
  'band_squat': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus)]),
  'v_squat_machine': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus), _sr(_ham)]),
  'reverse_hack_squat': _x(
    [_pr(_quad)],
    [_s(Muscle.gluteusMaximus), _sr(_ham)],
  ),
  'horizontal_leg_press': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus)]),
  'leg_press_feet_high': _x(
    [_pr(_quad, 'High foot placement')],
    [_s(Muscle.gluteusMaximus), _sr(_ham)],
  ),
  'leg_press_wide_stance': _x(
    [_pr(_quad, 'Wide foot placement')],
    [_s(Muscle.gluteusMaximus)],
  ),
  'sandbag_squat': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus), _stab]),
  'spanish_squat': _x([_pr(_quad, 'Constant tension, upright shins')]),
  'pistol_squat': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _stab],
  ),
  'shrimp_squat': _x(
    [_pr(_quad, 'Knee-dominant single leg')],
    [_s(Muscle.gluteusMaximus), _stab],
  ),
  'db_split_squat': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _stab],
  ),
  'barbell_split_squat': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _stab],
  ),
  'barbell_walking_lunge': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _stab],
  ),
  'barbell_step_up': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _stab],
  ),
  'smith_reverse_lunge': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham)],
  ),
  'step_up': _x([_pr(_quad), _p(Muscle.gluteusMaximus)], [_sr(_ham)]),
  'db_curtsy_lunge': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_s(Muscle.gluteusMedius), _sr(_ham), _stab],
  ),
  'kb_reverse_lunge': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _stab],
  ),
};
