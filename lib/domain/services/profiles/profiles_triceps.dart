part of '../profile_dsl.dart';

// Muscle profiles: triceps. Add new entries at the END of the map (keys unique across ALL parts).
// Helpers (_p, _pr, _s, _sr, _x, _stab, region aliases) live in profile_dsl.dart.
final Map<String, ExerciseMuscleProfile> profilesTriceps = {
  'tricep_pushdown': _x([_pr(_tri)]),
  'rope_pushdown': _x([_pr(_tri)]),
  'skullcrusher': _x([_pr(_tri)]),
  'overhead_tri_ext': _x([_p(Muscle.tricepsLongHead, 'Long head stretched')]),
  'cable_oh_tri_ext': _x([_p(Muscle.tricepsLongHead, 'Long head stretched')]),
  'close_grip_bench': _x(
    [_pr(_tri)],
    [_s(Muscle.midChest), _s(Muscle.frontDelts)],
  ),
  'bench_dip': _x([_pr(_tri)], [_s(Muscle.frontDelts)]),
  'diamond_pushup': _x(
    [_pr(_tri)],
    [_s(Muscle.midChest), _s(Muscle.frontDelts)],
  ),
  'ez_overhead_extension': _x([
    _p(Muscle.tricepsLongHead, 'Long head stretched'),
  ]),
  'incline_skullcrusher': _x([
    _p(Muscle.tricepsLongHead, 'Long head stretched'),
  ]),
  'db_skullcrusher': _x([_pr(_tri)]),
  'tate_press': _x([_pr(_tri)]),
  'reverse_grip_pushdown': _x([_p(Muscle.tricepsMedialHead)]),
  'single_arm_pushdown': _x([_p(Muscle.tricepsLateralHead)]),
  'db_tricep_kickback': _x([_pr(_tri)]),
  'cable_tricep_kickback': _x([_p(Muscle.tricepsLateralHead)]),
  'machine_triceps_extension': _x([_pr(_tri)]),
  'jm_press': _x([_pr(_tri)], [_s(Muscle.midChest), _s(Muscle.frontDelts)]),
  'triceps_dip': _x(
    [_pr(_tri)],
    [_s(Muscle.lowerChest), _s(Muscle.frontDelts)],
  ),
  'seated_dip_machine': _x(
    [_pr(_tri)],
    [_s(Muscle.lowerChest), _s(Muscle.frontDelts)],
  ),
  'smith_close_grip_bench': _x(
    [_pr(_tri)],
    [_s(Muscle.midChest), _s(Muscle.frontDelts)],
  ),
  'single_arm_db_oh_extension': _x([
    _p(Muscle.tricepsLongHead, 'Long head stretched'),
  ]),
  'single_arm_cable_oh_extension': _x([
    _p(Muscle.tricepsLongHead, 'Long head stretched'),
  ]),
  'bodyweight_tri_extension': _x([_pr(_tri)]),
  'kb_oh_tri_ext': _x([_p(Muscle.tricepsLongHead, 'Long head stretched')]),
  'band_oh_tri_ext': _x([_p(Muscle.tricepsLongHead, 'Long head stretched')]),
  'band_pushdown': _x([_pr(_tri)]),
  'cross_body_cable_tri_ext': _x([_pr(_tri)]),
  'band_tri_kickback': _x([_pr(_tri)]),
  'close_grip_db_press': _x(
    [_pr(_tri)],
    [_s(Muscle.midChest), _s(Muscle.frontDelts)],
  ),
  'smith_jm_press': _x(
    [_pr(_tri)],
    [_s(Muscle.midChest), _s(Muscle.frontDelts)],
  ),
  'ring_dip': _x([_pr(_tri)], [_s(Muscle.lowerChest), _s(Muscle.frontDelts)]),
};
