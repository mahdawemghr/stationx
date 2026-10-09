part of '../profile_dsl.dart';

// Muscle profiles: shoulders. Add new entries at the END of the map (keys unique across ALL parts).
// Helpers (_p, _pr, _s, _sr, _x, _stab, region aliases) live in profile_dsl.dart.
final Map<String, ExerciseMuscleProfile> profilesShoulders = {
  'overhead_press': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.sideDelts), _sr(_tri)],
  ),
  'db_shoulder_press': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.sideDelts), _sr(_tri)],
  ),
  'machine_shoulder_press': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.sideDelts), _sr(_tri)],
  ),
  'arnold_press': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.sideDelts), _sr(_tri)],
  ),
  'front_raise': _x([_p(Muscle.frontDelts)]),
  'lateral_raise': _x([_p(Muscle.sideDelts)]),
  'cable_lateral_raise': _x([_p(Muscle.sideDelts)]),
  'machine_lateral_raise': _x([_p(Muscle.sideDelts)]),
  'face_pull': _x(
    [_p(Muscle.rearDelts)],
    [_s(Muscle.upperBack), _s(Muscle.traps)],
  ),
  'rear_delt_fly': _x([_p(Muscle.rearDelts)], [_s(Muscle.upperBack)]),
  'reverse_pec_deck': _x([_p(Muscle.rearDelts)], [_s(Muscle.upperBack)]),
  'push_press': _x([_p(Muscle.frontDelts)], [_s(Muscle.sideDelts), _sr(_tri)]),
  'landmine_press': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.upperChest), _sr(_tri)],
  ),
  'smith_shoulder_press': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.sideDelts), _sr(_tri)],
  ),
  'plate_front_raise': _x([_p(Muscle.frontDelts)]),
  'cable_front_raise': _x([_p(Muscle.frontDelts)]),
  'pike_pushup': _x([_p(Muscle.frontDelts)], [_s(Muscle.sideDelts), _sr(_tri)]),
  'handstand_pushup': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.sideDelts), _sr(_tri)],
  ),
  'leaning_cable_lateral_raise': _x([_p(Muscle.sideDelts)]),
  'seated_lateral_raise': _x([_p(Muscle.sideDelts)]),
  'upright_row': _x(
    [_p(Muscle.sideDelts)],
    [_s(Muscle.traps), _s(Muscle.frontDelts)],
  ),
  'cable_rear_delt_fly': _x([_p(Muscle.rearDelts)], [_s(Muscle.upperBack)]),
  'chest_supported_rear_delt_raise': _x(
    [_p(Muscle.rearDelts)],
    [_s(Muscle.upperBack)],
  ),
  'rear_delt_row': _x([_p(Muscle.rearDelts)], [_s(Muscle.upperBack), _sr(_bi)]),
  'band_pull_apart': _x(
    [_p(Muscle.rearDelts)],
    [_s(Muscle.upperBack), _s(Muscle.traps)],
  ),
  'seated_barbell_press': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.sideDelts), _sr(_tri)],
  ),
  'neutral_grip_db_press': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.sideDelts), _sr(_tri)],
  ),
  'z_press': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.sideDelts), _sr(_tri), _stab],
  ),
  'cable_shoulder_press': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.sideDelts), _sr(_tri)],
  ),
  'plate_loaded_shoulder_press': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.sideDelts), _sr(_tri)],
  ),
  'kb_press': _x([_p(Muscle.frontDelts)], [_s(Muscle.sideDelts), _sr(_tri)]),
  'band_shoulder_press': _x(
    [_p(Muscle.frontDelts)],
    [_s(Muscle.sideDelts), _sr(_tri)],
  ),
  'barbell_front_raise': _x([_p(Muscle.frontDelts)]),
  'leaning_db_lateral_raise': _x([_p(Muscle.sideDelts)]),
  'behind_back_cable_lateral_raise': _x([_p(Muscle.sideDelts)]),
  'band_lateral_raise': _x([_p(Muscle.sideDelts)]),
  'side_lying_lateral_raise': _x([_p(Muscle.sideDelts)]),
  'smith_upright_row': _x(
    [_p(Muscle.sideDelts)],
    [_s(Muscle.traps), _s(Muscle.frontDelts)],
  ),
  'cable_y_raise': _x(
    [_p(Muscle.rearDelts)],
    [_s(Muscle.traps), _s(Muscle.upperBack)],
  ),
  'cable_rear_delt_row': _x(
    [_p(Muscle.rearDelts)],
    [_s(Muscle.upperBack), _sr(_bi)],
  ),
  'prone_t_raise': _x(
    [_p(Muscle.rearDelts)],
    [_s(Muscle.upperBack), _s(Muscle.traps)],
  ),
  'band_reverse_fly': _x([_p(Muscle.rearDelts)], [_s(Muscle.upperBack)]),
  'band_face_pull': _x(
    [_p(Muscle.rearDelts)],
    [_s(Muscle.upperBack), _s(Muscle.traps)],
  ),
};
