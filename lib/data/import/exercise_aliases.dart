/// Gym Tracker exercise name → StationX catalogue id, for exercises that are
/// the same movement under a different name. Anything not listed here (and not
/// an exact name match) is imported as a custom exercise so no logged set is lost.
///
/// An exact catalogue name always wins over an alias (see the matching order
/// in gym_tracker_import.dart), so never alias a name the catalogue already has.
///
/// Keys are normalised with [normalizeExerciseName].
const gymTrackerAliases = <String, String>{
  'benchpress': 'bench_press',
  'inclinedumbbellpress': 'incline_db_press',
  'straightarmcablepulldown': 'straight_arm_pulldown',
  'cabletriceppushdown': 'tricep_pushdown',
  'overheadcabletricepextension': 'cable_oh_tri_ext',
  'lyinglegcurl': 'leg_curl',
  'dumbbelllateralraise': 'lateral_raise',
  // Added with the 212-exercise catalogue: common alternate names.
  'reversehyper': 'reverse_hyperextension',
  'woodchopper': 'cable_woodchop',
  'bayesiancurl': 'bayesian_curl',
  'standingcalfraisesmith': 'smith_calf_raise',
  'gluteham': 'glute_ham_raise',
  'lyinglegraises': 'lying_leg_raise',
  'barbellupright': 'upright_row',
  'uprightrowbarbell': 'upright_row',
};

/// "EZ-Bar Preacher Curl" → "ezbarpreachercurl": case, spaces and punctuation ignored.
String normalizeExerciseName(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
