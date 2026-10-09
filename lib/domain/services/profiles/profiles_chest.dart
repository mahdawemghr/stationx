part of '../profile_dsl.dart';

// Muscle profiles: chest. Add new entries at the END of the map (keys unique across ALL parts).
// Helpers (_p, _pr, _s, _sr, _x, _stab, region aliases) live in profile_dsl.dart.
final Map<String, ExerciseMuscleProfile> profilesChest = {
  'bench_press': _x([_p(Muscle.midChest)], [_sr(_tri), _s(Muscle.frontDelts)]),
  'db_bench_press': _x(
    [_p(Muscle.midChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'machine_chest_press': _x(
    [_p(Muscle.midChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'pushup': _x([_p(Muscle.midChest)], [_sr(_tri), _s(Muscle.frontDelts)]),
  'incline_db_press': _x(
    [_p(Muscle.upperChest)],
    [_s(Muscle.frontDelts), _sr(_tri)],
  ),
  'incline_bench_press': _x(
    [_p(Muscle.upperChest)],
    [_s(Muscle.frontDelts), _sr(_tri)],
  ),
  'decline_bench_press': _x(
    [_p(Muscle.lowerChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'dips': _x([_p(Muscle.lowerChest)], [_sr(_tri), _s(Muscle.frontDelts)]),
  'cable_fly': _x([_p(Muscle.midChest)], [_s(Muscle.frontDelts)]),
  'pec_deck': _x([_p(Muscle.midChest)], [_s(Muscle.frontDelts)]),
  'db_fly': _x(
    [_p(Muscle.midChest, 'Stretch under load')],
    [_s(Muscle.frontDelts)],
  ),
  'incline_cable_fly': _x([_p(Muscle.upperChest)], [_s(Muscle.frontDelts)]),
  'high_cable_fly': _x([_p(Muscle.lowerChest)], [_s(Muscle.frontDelts)]),
  'incline_db_fly': _x(
    [_p(Muscle.upperChest, 'Stretch under load')],
    [_s(Muscle.frontDelts)],
  ),
  'smith_incline_press': _x(
    [_p(Muscle.upperChest)],
    [_s(Muscle.frontDelts), _sr(_tri)],
  ),
  'incline_machine_press': _x(
    [_p(Muscle.upperChest)],
    [_s(Muscle.frontDelts), _sr(_tri)],
  ),
  'reverse_grip_bench_press': _x(
    [_p(Muscle.upperChest)],
    [_s(Muscle.frontDelts), _sr(_tri)],
  ),
  'decline_pushup': _x(
    [_p(Muscle.upperChest)],
    [_s(Muscle.frontDelts), _sr(_tri)],
  ),
  'smith_bench_press': _x(
    [_p(Muscle.midChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'svend_press': _x(
    [_p(Muscle.midChest, 'Squeeze and hold')],
    [_s(Muscle.frontDelts)],
  ),
  'db_floor_press': _x(
    [_p(Muscle.midChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'cable_chest_press': _x(
    [_p(Muscle.midChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'wide_pushup': _x([_p(Muscle.midChest)], [_sr(_tri), _s(Muscle.frontDelts)]),
  'decline_db_press': _x(
    [_p(Muscle.lowerChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'incline_pushup': _x(
    [_p(Muscle.lowerChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'assisted_dip': _x(
    [_p(Muscle.lowerChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'single_arm_cable_fly': _x([_p(Muscle.midChest)], [_s(Muscle.frontDelts)]),
  'barbell_floor_press': _x(
    [_p(Muscle.midChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'plate_loaded_chest_press': _x(
    [_p(Muscle.midChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'plate_loaded_incline_press': _x(
    [_p(Muscle.upperChest)],
    [_s(Muscle.frontDelts), _sr(_tri)],
  ),
  'decline_machine_press': _x(
    [_p(Muscle.lowerChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'smith_decline_press': _x(
    [_p(Muscle.lowerChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'seated_cable_fly': _x([_p(Muscle.midChest)], [_s(Muscle.frontDelts)]),
  'single_arm_cable_chest_press': _x(
    [_p(Muscle.midChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'incline_cable_press': _x(
    [_p(Muscle.upperChest)],
    [_s(Muscle.frontDelts), _sr(_tri)],
  ),
  'band_chest_press': _x(
    [_p(Muscle.midChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'band_chest_fly': _x([_p(Muscle.midChest)], [_s(Muscle.frontDelts)]),
  'band_incline_press': _x(
    [_p(Muscle.upperChest)],
    [_s(Muscle.frontDelts), _sr(_tri)],
  ),
  'kb_floor_press': _x(
    [_p(Muscle.midChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'archer_pushup': _x(
    [_p(Muscle.midChest)],
    [_sr(_tri), _s(Muscle.frontDelts)],
  ),
  'ring_pushup': _x([_p(Muscle.midChest)], [_sr(_tri), _s(Muscle.frontDelts)]),
  'fingertip_pushup': _x(
    [_p(Muscle.midChest)],
    [_sr(_tri), _s(Muscle.frontDelts), _s(Muscle.wristFlexors)],
  ),
};
