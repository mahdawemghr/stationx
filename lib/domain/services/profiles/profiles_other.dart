part of '../profile_dsl.dart';

// Muscle profiles: other. Add new entries at the END of the map (keys unique across ALL parts).
// Helpers (_p, _pr, _s, _sr, _x, _stab, region aliases) live in profile_dsl.dart.
final Map<String, ExerciseMuscleProfile> profilesOther = {
  'sled_push': _x([_pr(_quad)], [_s(Muscle.gluteusMaximus), _stab]),
  'backward_sled_drag': _x(
    [_pr(_quad, 'Knee-dominant, low impact')],
    [_s(Muscle.gluteusMaximus)],
  ),
  'yoke_walk': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_s(Muscle.traps), _s(Muscle.lowerBack), _stab],
  ),
  'sandbag_carry': _x(
    [_pr(_quad), _p(Muscle.gluteusMaximus)],
    [_s(Muscle.upperBack), _stab],
  ),
};
