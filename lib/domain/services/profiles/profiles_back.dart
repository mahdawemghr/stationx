part of '../profile_dsl.dart';

// Muscle profiles: back. Add new entries at the END of the map (keys unique across ALL parts).
// Helpers (_p, _pr, _s, _sr, _x, _stab, region aliases) live in profile_dsl.dart.
final Map<String, ExerciseMuscleProfile> profilesBack = {
  'lat_pulldown': _x([_p(Muscle.lats)], [_sr(_bi), _s(Muscle.upperBack)]),
  'single_arm_pulldown': _x(
    [_p(Muscle.lats)],
    [_sr(_bi), _s(Muscle.upperBack)],
  ),
  'close_grip_pulldown': _x(
    [_p(Muscle.lats)],
    [_sr(_bi), _s(Muscle.upperBack)],
  ),
  'assisted_pullup': _x([_p(Muscle.lats)], [_sr(_bi), _s(Muscle.upperBack)]),
  'pullup': _x([_p(Muscle.lats)], [_sr(_bi), _s(Muscle.upperBack)]),
  'chinup': _x([_p(Muscle.lats)], [_sr(_bi), _s(Muscle.upperBack)]),
  'straight_arm_pulldown': _x([
    _p(Muscle.lats, 'Lat isolation, arms stay straight'),
  ]),
  'seated_cable_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.rearDelts), _sr(_bi)],
  ),
  'one_arm_cable_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.rearDelts), _sr(_bi)],
  ),
  'chest_supported_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.rearDelts), _sr(_bi)],
  ),
  'db_row': _x(
    [_p(Muscle.lats), _p(Muscle.upperBack)],
    [_s(Muscle.rearDelts), _sr(_bi)],
  ),
  'barbell_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.traps), _s(Muscle.lowerBack), _sr(_bi)],
  ),
  'tbar_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.traps), _s(Muscle.lowerBack), _sr(_bi)],
  ),
  'barbell_shrug': _x([_p(Muscle.traps)]),
  'db_shrug': _x([_p(Muscle.traps)]),
  'back_extension': _x(
    [_p(Muscle.lowerBack)],
    [_s(Muscle.gluteusMaximus), _sr(_ham)],
  ),
  'good_morning': _x(
    [_p(Muscle.lowerBack)],
    [_sr(_ham), _s(Muscle.gluteusMaximus)],
  ),
  'deadlift': _x(
    [_p(Muscle.lowerBack), _pr(_ham), _p(Muscle.gluteusMaximus)],
    [
      _s(Muscle.traps),
      _s(Muscle.upperBack),
      _sr(_quad),
      _stab,
      _s(Muscle.brachioradialis),
    ],
  ),
  'neutral_grip_pullup': _x(
    [_p(Muscle.lats)],
    [_sr(_bi), _s(Muscle.upperBack)],
  ),
  'reverse_grip_pulldown': _x(
    [_p(Muscle.lats)],
    [_sr(_bi), _s(Muscle.upperBack)],
  ),
  'machine_pulldown': _x([_p(Muscle.lats)], [_sr(_bi), _s(Muscle.upperBack)]),
  'db_pullover': _x(
    [_p(Muscle.lats, 'Stretch under load')],
    [_s(Muscle.midChest), _sr(_tri)],
  ),
  'pendlay_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.traps), _s(Muscle.lowerBack), _sr(_bi)],
  ),
  'meadows_row': _x(
    [_p(Muscle.upperBack), _p(Muscle.lats)],
    [_s(Muscle.rearDelts), _sr(_bi)],
  ),
  'seal_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.rearDelts), _sr(_bi)],
  ),
  'inverted_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.rearDelts), _sr(_bi)],
  ),
  'chest_supported_db_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.rearDelts), _sr(_bi)],
  ),
  'wide_grip_cable_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.rearDelts), _s(Muscle.lats), _sr(_bi)],
  ),
  'cable_shrug': _x([_p(Muscle.traps)]),
  'rack_pull': _x(
    [_p(Muscle.traps)],
    [
      _s(Muscle.upperBack),
      _s(Muscle.lowerBack),
      _s(Muscle.gluteusMaximus),
      _sr(_ham),
      _s(Muscle.brachioradialis),
    ],
  ),
  'prone_y_raise': _x(
    [_p(Muscle.traps, 'Lower traps')],
    [_s(Muscle.rearDelts), _s(Muscle.upperBack)],
  ),
  'reverse_hyperextension': _x(
    [_p(Muscle.lowerBack)],
    [_s(Muscle.gluteusMaximus), _sr(_ham)],
  ),
  'superman': _x([_p(Muscle.lowerBack)], [_s(Muscle.gluteusMaximus)]),
  'plate_loaded_pulldown': _x(
    [_p(Muscle.lats)],
    [_sr(_bi), _s(Muscle.upperBack)],
  ),
  'iso_lateral_pulldown': _x(
    [_p(Muscle.lats)],
    [_sr(_bi), _s(Muscle.upperBack)],
  ),
  'pullover_machine': _x([_p(Muscle.lats, 'Stretch under load')], [_sr(_tri)]),
  'wide_grip_pullup': _x([_p(Muscle.lats)], [_sr(_bi), _s(Muscle.upperBack)]),
  'weighted_pullup': _x([_p(Muscle.lats)], [_sr(_bi), _s(Muscle.upperBack)]),
  'commando_pullup': _x([_p(Muscle.lats)], [_sr(_bi), _s(Muscle.upperBack)]),
  'archer_pullup': _x([_p(Muscle.lats)], [_sr(_bi), _s(Muscle.upperBack)]),
  'towel_pullup': _x(
    [_p(Muscle.lats)],
    [_sr(_bi), _s(Muscle.upperBack), _s(Muscle.wristFlexors)],
  ),
  'band_lat_pulldown': _x([_p(Muscle.lats)], [_sr(_bi), _s(Muscle.upperBack)]),
  'high_row_machine': _x(
    [_p(Muscle.lats), _p(Muscle.upperBack)],
    [_s(Muscle.rearDelts), _sr(_bi)],
  ),
  'iso_lateral_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.rearDelts), _sr(_bi)],
  ),
  'seated_row_machine': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.rearDelts), _sr(_bi)],
  ),
  'yates_row': _x(
    [_p(Muscle.lats), _p(Muscle.upperBack)],
    [_s(Muscle.rearDelts), _s(Muscle.traps), _sr(_bi)],
  ),
  'underhand_barbell_row': _x(
    [_p(Muscle.lats)],
    [_s(Muscle.upperBack), _s(Muscle.lowerBack), _sr(_bi)],
  ),
  'db_bent_over_row': _x(
    [_p(Muscle.lats), _p(Muscle.upperBack)],
    [_s(Muscle.rearDelts), _sr(_bi)],
  ),
  'kroc_row': _x(
    [_p(Muscle.lats), _p(Muscle.upperBack)],
    [_s(Muscle.rearDelts), _sr(_bi)],
  ),
  'landmine_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.traps), _s(Muscle.lowerBack), _sr(_bi)],
  ),
  'smith_bent_over_row': _x(
    [_p(Muscle.lats), _p(Muscle.upperBack)],
    [_s(Muscle.rearDelts), _sr(_bi)],
  ),
  'high_cable_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.rearDelts), _s(Muscle.lats), _sr(_bi)],
  ),
  'underhand_cable_row': _x(
    [_p(Muscle.lats), _p(Muscle.upperBack)],
    [_s(Muscle.rearDelts), _sr(_bi)],
  ),
  'kb_row': _x(
    [_p(Muscle.lats), _p(Muscle.upperBack)],
    [_s(Muscle.rearDelts), _sr(_bi)],
  ),
  'kb_gorilla_row': _x(
    [_p(Muscle.lats), _p(Muscle.upperBack)],
    [_s(Muscle.rearDelts), _sr(_bi)],
  ),
  'renegade_row': _x(
    [_p(Muscle.lats)],
    [_s(Muscle.upperBack), _s(Muscle.rearDelts), _sr(_bi), _stab],
  ),
  'band_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.rearDelts), _sr(_bi)],
  ),
  'feet_elevated_inverted_row': _x(
    [_p(Muscle.upperBack)],
    [_s(Muscle.lats), _s(Muscle.rearDelts), _sr(_bi)],
  ),
  'trap_bar_shrug': _x([_p(Muscle.traps)]),
  'smith_shrug': _x([_p(Muscle.traps)]),
  'machine_shrug': _x([_p(Muscle.traps)]),
  'behind_back_shrug': _x([_p(Muscle.traps)]),
  'incline_db_shrug': _x([_p(Muscle.traps)]),
  'kb_shrug': _x([_p(Muscle.traps)]),
  'barbell_high_pull': _x(
    [_p(Muscle.traps)],
    [_s(Muscle.sideDelts), _s(Muscle.gluteusMaximus), _sr(_ham)],
  ),
  'scapular_pullup': _x(
    [_p(Muscle.traps, 'Lower traps')],
    [_s(Muscle.upperBack), _s(Muscle.lats)],
  ),
  'deficit_deadlift': _x(
    [_p(Muscle.lowerBack), _pr(_ham), _p(Muscle.gluteusMaximus)],
    [
      _s(Muscle.traps),
      _s(Muscle.upperBack),
      _sr(_quad),
      _stab,
      _s(Muscle.brachioradialis),
    ],
  ),
  'snatch_grip_deadlift': _x(
    [_p(Muscle.lowerBack), _pr(_ham), _p(Muscle.gluteusMaximus)],
    [
      _s(Muscle.traps),
      _s(Muscle.upperBack),
      _sr(_quad),
      _stab,
      _s(Muscle.brachioradialis),
    ],
  ),
  'db_deadlift': _x(
    [_p(Muscle.lowerBack), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _sr(_quad), _s(Muscle.traps), _s(Muscle.brachioradialis)],
  ),
  'kb_deadlift': _x(
    [_p(Muscle.lowerBack), _p(Muscle.gluteusMaximus)],
    [_sr(_ham), _sr(_quad), _s(Muscle.brachioradialis)],
  ),
  'db_good_morning': _x(
    [_p(Muscle.lowerBack)],
    [_sr(_ham), _s(Muscle.gluteusMaximus)],
  ),
  'band_good_morning': _x(
    [_p(Muscle.lowerBack)],
    [_sr(_ham), _s(Muscle.gluteusMaximus)],
  ),
  'back_extension_machine': _x(
    [_p(Muscle.lowerBack)],
    [_s(Muscle.gluteusMaximus), _sr(_ham)],
  ),
  'weighted_back_extension': _x(
    [_p(Muscle.lowerBack)],
    [_s(Muscle.gluteusMaximus), _sr(_ham)],
  ),
};
