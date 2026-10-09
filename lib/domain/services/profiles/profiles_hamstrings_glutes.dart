part of '../profile_dsl.dart';

// Muscle profiles: hamstrings_glutes. Add new entries at the END of the map (keys unique across ALL parts).
// Helpers (_p, _pr, _s, _sr, _x, _stab, region aliases) live in profile_dsl.dart.
final Map<String, ExerciseMuscleProfile> profilesHamstringsGlutes = {
  'rdl': _x(
    [_pr(_ham, 'Stretch under load')],
    [_s(Muscle.gluteusMaximus), _s(Muscle.lowerBack)],
  ),
  'leg_curl': _x([_pr(_ham)]),
  'seated_leg_curl': _x([_pr(_ham)]),
  'hip_thrust': _x([_p(Muscle.gluteusMaximus)], [_sr(_ham), _stab]),
  'cable_kickback': _x([_p(Muscle.gluteusMaximus)]),
  'stiff_leg_deadlift': _x(
    [_pr(_ham, 'Stretch under load')],
    [_s(Muscle.gluteusMaximus), _s(Muscle.lowerBack)],
  ),
  'db_rdl': _x(
    [_pr(_ham, 'Stretch under load')],
    [_s(Muscle.gluteusMaximus), _s(Muscle.lowerBack)],
  ),
  'single_leg_rdl': _x(
    [_pr(_ham)],
    [
      _s(Muscle.gluteusMaximus),
      _s(Muscle.gluteusMedius),
      _s(Muscle.lowerBack),
      _stab,
    ],
  ),
  'nordic_curl': _x([_pr(_ham, 'Eccentric overload')]),
  'glute_ham_raise': _x([_pr(_ham), _p(Muscle.gluteusMaximus)]),
  'stability_ball_leg_curl': _x([_pr(_ham)], [_s(Muscle.gluteusMaximus)]),
  'standing_leg_curl': _x([_pr(_ham)]),
  'machine_hip_thrust': _x([_p(Muscle.gluteusMaximus)], [_sr(_ham)]),
  'db_hip_thrust': _x([_p(Muscle.gluteusMaximus)], [_sr(_ham)]),
  'single_leg_hip_thrust': _x([_p(Muscle.gluteusMaximus)], [_sr(_ham)]),
  'glute_bridge': _x([_p(Muscle.gluteusMaximus)], [_sr(_ham)]),
  'frog_pump': _x([_p(Muscle.gluteusMaximus)]),
  'glute_kickback_machine': _x([_p(Muscle.gluteusMaximus)]),
  'cable_pull_through': _x(
    [_p(Muscle.gluteusMaximus)],
    [_sr(_ham), _s(Muscle.lowerBack)],
  ),
  'hip_abduction_machine': _x(
    [_p(Muscle.gluteusMedius)],
    [_s(Muscle.gluteusMinimus)],
  ),
  'cable_hip_abduction': _x(
    [_p(Muscle.gluteusMedius)],
    [_s(Muscle.gluteusMinimus)],
  ),
  'hip_adduction_machine': _x([_pr(_glu, 'Inner thigh (adductors)')]),
  'kettlebell_swing': _x(
    [_p(Muscle.gluteusMaximus)],
    [_sr(_ham), _s(Muscle.lowerBack), _stab],
  ),
  'kb_rdl': _x(
    [_pr(_ham, 'Stretch under load')],
    [_s(Muscle.gluteusMaximus), _s(Muscle.lowerBack)],
  ),
  'cable_rdl': _x(
    [_pr(_ham, 'Stretch under load')],
    [_s(Muscle.gluteusMaximus), _s(Muscle.lowerBack)],
  ),
  'smith_rdl': _x(
    [_pr(_ham, 'Stretch under load')],
    [_s(Muscle.gluteusMaximus), _s(Muscle.lowerBack)],
  ),
  'db_stiff_leg_deadlift': _x(
    [_pr(_ham, 'Stretch under load')],
    [_s(Muscle.gluteusMaximus), _s(Muscle.lowerBack)],
  ),
  'kb_single_leg_rdl': _x(
    [_pr(_ham)],
    [
      _s(Muscle.gluteusMaximus),
      _s(Muscle.gluteusMedius),
      _s(Muscle.lowerBack),
      _stab,
    ],
  ),
  'standing_cable_leg_curl': _x([_pr(_ham)]),
  'db_leg_curl': _x([_pr(_ham)]),
  'band_leg_curl': _x([_pr(_ham)]),
  'slider_leg_curl': _x([_pr(_ham)], [_s(Muscle.gluteusMaximus)]),
  'single_leg_slider_curl': _x([_pr(_ham)], [_s(Muscle.gluteusMaximus)]),
  'nordic_curl_machine': _x([_pr(_ham, 'Eccentric overload')]),
  'barbell_glute_bridge': _x([_p(Muscle.gluteusMaximus)], [_sr(_ham), _stab]),
  'db_glute_bridge': _x([_p(Muscle.gluteusMaximus)], [_sr(_ham)]),
  'single_leg_glute_bridge': _x([_p(Muscle.gluteusMaximus)], [_sr(_ham)]),
  'smith_hip_thrust': _x([_p(Muscle.gluteusMaximus)], [_sr(_ham)]),
  'band_hip_thrust': _x(
    [_p(Muscle.gluteusMaximus)],
    [_sr(_ham), _s(Muscle.gluteusMedius)],
  ),
  'band_glute_bridge': _x(
    [_p(Muscle.gluteusMaximus)],
    [_sr(_ham), _s(Muscle.gluteusMedius)],
  ),
  'band_pull_through': _x(
    [_p(Muscle.gluteusMaximus)],
    [_sr(_ham), _s(Muscle.lowerBack)],
  ),
  'kb_sumo_deadlift': _x(
    [_p(Muscle.gluteusMaximus, 'Wide stance, inner thigh'), _pr(_quad)],
    [_sr(_ham), _s(Muscle.lowerBack)],
  ),
  'kb_single_arm_swing': _x(
    [_p(Muscle.gluteusMaximus)],
    [_sr(_ham), _s(Muscle.lowerBack), _stab],
  ),
  'kb_clean': _x(
    [_p(Muscle.gluteusMaximus)],
    [_sr(_ham), _s(Muscle.lowerBack), _s(Muscle.traps), _stab],
  ),
  'kb_snatch': _x(
    [_p(Muscle.gluteusMaximus)],
    [
      _sr(_ham),
      _s(Muscle.lowerBack),
      _s(Muscle.traps),
      _s(Muscle.frontDelts),
      _stab,
    ],
  ),
  'donkey_kick': _x([_p(Muscle.gluteusMaximus)], [_sr(_ham)]),
  'band_donkey_kick': _x([_p(Muscle.gluteusMaximus)], [_sr(_ham)]),
  'fire_hydrant': _x([_p(Muscle.gluteusMedius)], [_s(Muscle.gluteusMinimus)]),
  'side_lying_hip_abduction': _x(
    [_p(Muscle.gluteusMedius)],
    [_s(Muscle.gluteusMinimus)],
  ),
  'clamshell': _x([_p(Muscle.gluteusMedius)], [_s(Muscle.gluteusMinimus)]),
  'band_clamshell': _x([_p(Muscle.gluteusMedius)], [_s(Muscle.gluteusMinimus)]),
  'band_standing_hip_abduction': _x(
    [_p(Muscle.gluteusMedius)],
    [_s(Muscle.gluteusMinimus)],
  ),
  'monster_walk': _x(
    [_p(Muscle.gluteusMedius)],
    [_s(Muscle.gluteusMaximus), _s(Muscle.gluteusMinimus)],
  ),
  'band_lateral_walk': _x(
    [_p(Muscle.gluteusMedius)],
    [_s(Muscle.gluteusMinimus)],
  ),
  'side_plank_hip_abduction': _x(
    [_p(Muscle.gluteusMedius)],
    [_s(Muscle.gluteusMinimus), _s(Muscle.obliques)],
  ),
};
