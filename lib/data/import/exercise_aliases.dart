/// Gym Tracker exercise name → StationX catalogue id, for exercises that are
/// the same movement under a different name. Anything not listed here (and not
/// an exact name match) is imported as a custom exercise so no logged set is lost.
///
/// Keys are normalised with [normalizeExerciseName].
const gymTrackerAliases = <String, String>{
  'benchpress': 'bench_press',
  'inclinedumbbellpress': 'incline_db_press',
  'ezbarpreachercurl': 'preacher_curl',
  'hammercurl': 'hammer_curl',
  'latpulldown': 'lat_pulldown',
  'seatedcablerow': 'seated_cable_row',
  'straightarmcablepulldown': 'straight_arm_pulldown',
  'facepull': 'face_pull',
  'cabletriceppushdown': 'tricep_pushdown',
  'overheadcabletricepextension': 'cable_oh_tri_ext',
  'legpress': 'leg_press',
  'legextension': 'leg_extension',
  'lyinglegcurl': 'leg_curl',
  'dumbbelllateralraise': 'lateral_raise',
};

/// "EZ-Bar Preacher Curl" → "ezbarpreachercurl": case, spaces and punctuation ignored.
String normalizeExerciseName(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
