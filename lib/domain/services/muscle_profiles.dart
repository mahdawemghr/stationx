import '../models/models.dart';

/// Muscle metadata lookup. Built-in exercises have a detailed hand-written profile (keyed by id);
/// everything else (custom exercises, unknown ids) gets a broad, region-level profile derived from the
/// stored [Exercise.primaryMuscle]/[Exercise.secondaryMuscles] — never invented precision.
/// PURE DART.
abstract final class MuscleProfiles {
  /// Detailed profile for a built-in exercise id, or null.
  static ExerciseMuscleProfile? builtIn(String exerciseId) =>
      _builtIn[exerciseId];

  static ExerciseMuscleProfile of(Exercise e) {
    final b = builtIn(e.id);
    if (b != null) return b;
    final t = MuscleTargetCodec.normalize(e.muscleTargets);
    return t != null ? ExerciseMuscleProfile(t) : derive(e);
  }

  /// Region-level fallback from the legacy broad fields.
  static ExerciseMuscleProfile derive(Exercise e) {
    MuscleRegion region(MuscleGroup g) => switch (g) {
      MuscleGroup.chest => MuscleRegion.chest,
      MuscleGroup.back => MuscleRegion.back,
      MuscleGroup.shoulders => MuscleRegion.shoulders,
      MuscleGroup.biceps => MuscleRegion.biceps,
      MuscleGroup.triceps => MuscleRegion.triceps,
      MuscleGroup.legs => MuscleRegion.quadriceps,
      MuscleGroup.core => MuscleRegion.core,
    };
    return ExerciseMuscleProfile([
      MuscleTarget.primary(region(e.primaryMuscle)),
      for (final s in e.secondaryMuscles) MuscleTarget.secondary(region(s)),
    ]);
  }
}

// ── Profile DSL ──────────────────────────────────────────────────────────────────────────────────────────
// Rules: the FIRST primary decides primaryRegion (must map to the seed's broad primaryMuscle); every legacy
// secondary broad group must appear among the secondary regions' broad groups (extras are allowed). A leaf is
// only used when defensible, otherwise the whole region (muscle == null).

const _bi = MuscleRegion.biceps, _tri = MuscleRegion.triceps;
const _quad = MuscleRegion.quadriceps, _ham = MuscleRegion.hamstrings;
const _core = MuscleRegion.core;
const _glu = MuscleRegion.glutes, _calf = MuscleRegion.calves;

/// Primary leaf target.
MuscleTarget _p(Muscle m, [String? emphasis]) =>
    MuscleTarget.primary(m.region, muscle: m, emphasis: emphasis);

/// Primary, whole region.
MuscleTarget _pr(MuscleRegion r, [String? emphasis]) =>
    MuscleTarget.primary(r, emphasis: emphasis);

/// Secondary leaf target.
MuscleTarget _s(Muscle m) => MuscleTarget.secondary(m.region, muscle: m);

/// Secondary, whole region.
MuscleTarget _sr(MuscleRegion r) => MuscleTarget.secondary(r);

/// Core working as a stabiliser (bracing / anti-rotation): counts less than a normal secondary.
const _stab = MuscleTarget.secondary(_core, weight: 0.25);

ExerciseMuscleProfile _x(
  List<MuscleTarget> primary, [
  List<MuscleTarget> secondary = const [],
]) => ExerciseMuscleProfile([...primary, ...secondary]);

final Map<String, ExerciseMuscleProfile> _builtIn = {
  // Chest
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
  // Back
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
  // Shoulders
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
  // Biceps / forearms
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
    [_p(Muscle.brachioradialis)],
    [_s(Muscle.brachialis), _s(Muscle.wristExtensors)],
  ),
  // Triceps
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
  // Legs
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
  'rdl': _x(
    [_pr(_ham, 'Stretch under load')],
    [_s(Muscle.gluteusMaximus), _s(Muscle.lowerBack)],
  ),
  'leg_curl': _x([_pr(_ham)]),
  'seated_leg_curl': _x([_pr(_ham)]),
  'hip_thrust': _x([_p(Muscle.gluteusMaximus)], [_sr(_ham), _stab]),
  'cable_kickback': _x([_p(Muscle.gluteusMaximus)]),
  'calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'single_leg_calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'seated_calf_raise': _x(
    [_p(Muscle.soleus, 'Knee bent shifts load to soleus')],
    [_s(Muscle.gastrocnemius)],
  ),
  // Core
  'plank': _x([_p(Muscle.transverseAbdominis), _p(Muscle.rectusAbdominis)]),
  'cable_crunch': _x([_p(Muscle.rectusAbdominis)]),
  'crunch': _x([_p(Muscle.rectusAbdominis)]),
  'hanging_leg_raise': _x([_p(Muscle.rectusAbdominis)], [_s(Muscle.obliques)]),
  'ab_wheel': _x(
    [_p(Muscle.rectusAbdominis)],
    [_s(Muscle.transverseAbdominis)],
  ),
  'side_plank': _x([_p(Muscle.obliques)], [_s(Muscle.transverseAbdominis)]),
  'russian_twist': _x([_p(Muscle.obliques)], [_s(Muscle.rectusAbdominis)]),
  // Expanded library
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
  'donkey_calf_raise': _x(
    [_p(Muscle.gastrocnemius, 'Stretch under load')],
    [_s(Muscle.soleus)],
  ),
  'leg_press_calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'smith_calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'db_calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'tibialis_raise': _x([_pr(_calf, 'Front of the shin')]),
  'decline_situp': _x([_p(Muscle.rectusAbdominis)]),
  'reverse_crunch': _x([_p(Muscle.rectusAbdominis)]),
  'hanging_knee_raise': _x([_p(Muscle.rectusAbdominis)], [_s(Muscle.obliques)]),
  'machine_crunch': _x([_p(Muscle.rectusAbdominis)]),
  'bicycle_crunch': _x([_p(Muscle.rectusAbdominis), _p(Muscle.obliques)]),
  'v_up': _x([_p(Muscle.rectusAbdominis)]),
  'toes_to_bar': _x(
    [_p(Muscle.rectusAbdominis)],
    [_s(Muscle.obliques), _s(Muscle.lats)],
  ),
  'lying_leg_raise': _x([_p(Muscle.rectusAbdominis)]),
  'dragon_flag': _x(
    [_p(Muscle.rectusAbdominis)],
    [_s(Muscle.transverseAbdominis)],
  ),
  'pallof_press': _x(
    [_p(Muscle.obliques, 'Anti-rotation')],
    [_s(Muscle.transverseAbdominis)],
  ),
  'cable_woodchop': _x([_p(Muscle.obliques)], [_s(Muscle.rectusAbdominis)]),
  'suitcase_carry': _x(
    [_p(Muscle.obliques, 'Anti-lateral flexion')],
    [_s(Muscle.transverseAbdominis), _s(Muscle.wristFlexors)],
  ),
  'dead_bug': _x([_p(Muscle.transverseAbdominis), _p(Muscle.rectusAbdominis)]),
  'bird_dog': _x(
    [_p(Muscle.transverseAbdominis)],
    [_s(Muscle.lowerBack), _s(Muscle.gluteusMaximus)],
  ),
  'hollow_hold': _x([
    _p(Muscle.transverseAbdominis),
    _p(Muscle.rectusAbdominis),
  ]),
  'stir_the_pot': _x(
    [_p(Muscle.transverseAbdominis), _p(Muscle.rectusAbdominis)],
    [_s(Muscle.obliques)],
  ),
  'side_bend': _x([_p(Muscle.obliques)]),
};
