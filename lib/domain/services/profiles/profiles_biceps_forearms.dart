part of '../profile_dsl.dart';

// Muscle profiles: biceps_forearms. Add new entries at the END of the map (keys unique across ALL parts).
// Helpers (_p, _pr, _s, _sr, _x, _stab, region aliases) live in profile_dsl.dart.
final Map<String, ExerciseMuscleProfile> profilesBicepsForearms = {
  'barbell_curl': _x([_pr(_bi)]),
  'cable_curl': _x([_pr(_bi)]),
  'db_curl': _x([_pr(_bi)]),
  'concentration_curl': _x([_pr(_bi)]),
  'preacher_curl': _x([_p(Muscle.bicepsShortHead, 'Short head emphasis')]),
  'spider_curl': _x([_p(Muscle.bicepsShortHead, 'Short head emphasis')]),
  'incline_db_curl': _x([_p(Muscle.bicepsLongHead, 'Long head stretched')]),
  'hammer_curl': _x(
    [_p(Muscle.brachialis), _p(Muscle.brachioradialis)],
    [_sr(_bi)],
  ),
  'rope_hammer_curl': _x(
    [_p(Muscle.brachialis), _p(Muscle.brachioradialis)],
    [_sr(_bi)],
  ),
  'reverse_curl': _x(
    [_pr(MuscleRegion.forearms, 'Brachioradialis emphasis')],
    [_s(Muscle.brachialis), _s(Muscle.wristExtensors)],
  ),
  'ez_bar_curl': _x([_pr(_bi)]),
  'bayesian_curl': _x([
    _p(Muscle.bicepsLongHead, 'Long head stretched behind the body'),
  ]),
  'drag_curl': _x([_pr(_bi)]),
  'machine_biceps_curl': _x([_pr(_bi)]),
  'ez_preacher_curl': _x([_p(Muscle.bicepsShortHead, 'Short head emphasis')]),
  'db_preacher_curl': _x([_p(Muscle.bicepsShortHead, 'Short head emphasis')]),
  'wide_grip_barbell_curl': _x([_pr(_bi)]),
  'cross_body_hammer_curl': _x(
    [_p(Muscle.brachialis)],
    [_sr(_bi), _s(Muscle.brachioradialis)],
  ),
  'zottman_curl': _x(
    [_pr(_bi)],
    [_s(Muscle.brachioradialis), _s(Muscle.wristExtensors)],
  ),
  'wrist_curl': _x([_p(Muscle.wristFlexors)]),
  'reverse_wrist_curl': _x([_p(Muscle.wristExtensors)]),
  'farmers_carry': _x(
    [_p(Muscle.wristFlexors, 'Grip endurance')],
    [_s(Muscle.traps), _stab],
  ),
  'plate_pinch': _x([_p(Muscle.wristFlexors, 'Pinch grip')]),
  'dead_hang': _x(
    [_p(Muscle.wristFlexors, 'Grip endurance')],
    [_s(Muscle.lats)],
  ),
  'wrist_roller': _x([_p(Muscle.wristFlexors), _p(Muscle.wristExtensors)]),
  'incline_hammer_curl': _x(
    [_p(Muscle.brachialis), _p(Muscle.brachioradialis)],
    [_sr(_bi)],
  ),
  'kb_hammer_curl': _x(
    [_p(Muscle.brachialis), _p(Muscle.brachioradialis)],
    [_sr(_bi)],
  ),
  'cable_preacher_curl': _x([
    _p(Muscle.bicepsShortHead, 'Short head emphasis'),
  ]),
  'lying_cable_curl': _x([_pr(_bi)]),
  'high_cable_curl': _x([_pr(_bi)]),
  'close_grip_ez_curl': _x([_pr(_bi)]),
  'kb_curl': _x([_pr(_bi)]),
  'band_curl': _x([_pr(_bi)]),
  'inverted_biceps_curl': _x(
    [_pr(_bi)],
    [_s(Muscle.upperBack), _s(Muscle.lats)],
  ),
  'db_wrist_curl': _x([_p(Muscle.wristFlexors)]),
  'db_reverse_wrist_curl': _x([_p(Muscle.wristExtensors)]),
  'behind_back_wrist_curl': _x([_p(Muscle.wristFlexors)]),
  'cable_wrist_curl': _x([_p(Muscle.wristFlexors)]),
  'cable_reverse_wrist_curl': _x([_p(Muscle.wristExtensors)]),
  'wrist_curl_machine': _x([_p(Muscle.wristFlexors)]),
  'band_wrist_curl': _x([_p(Muscle.wristFlexors)]),
  'band_reverse_wrist_curl': _x([_p(Muscle.wristExtensors)]),
  'db_reverse_curl': _x(
    [_pr(MuscleRegion.forearms, 'Brachioradialis emphasis')],
    [_s(Muscle.brachialis), _s(Muscle.wristExtensors)],
  ),
  'cable_reverse_curl': _x(
    [_pr(MuscleRegion.forearms, 'Brachioradialis emphasis')],
    [_s(Muscle.brachialis), _s(Muscle.wristExtensors)],
  ),
  'kb_farmers_carry': _x(
    [_p(Muscle.wristFlexors, 'Grip endurance')],
    [_s(Muscle.traps), _stab],
  ),
  'trap_bar_carry': _x(
    [_p(Muscle.wristFlexors, 'Grip endurance')],
    [_s(Muscle.traps), _stab],
  ),
  'kb_bottoms_up_carry': _x(
    [_p(Muscle.wristFlexors, 'Grip and wrist stability')],
    [_sr(MuscleRegion.shoulders), _stab],
  ),
  'towel_dead_hang': _x(
    [_p(Muscle.wristFlexors, 'Thick towel grip')],
    [_s(Muscle.lats)],
  ),
  'hand_gripper': _x([_p(Muscle.wristFlexors, 'Crush grip')]),
  'db_pronation_supination': _x([
    _pr(MuscleRegion.forearms, 'Forearm rotation'),
  ]),
};
