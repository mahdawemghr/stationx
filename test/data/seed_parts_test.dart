import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_dsl.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/domain/services/profile_dsl.dart';
import 'package:stationx/domain/services/split_sections/sections_all.dart';

/// The original 212 ids in their historic order (recorded when the catalog was split into region parts).
const _snapshot = [
  'bench_press',
  'incline_db_press',
  'cable_fly',
  'pec_deck',
  'pushup',
  'dips',
  'lat_pulldown',
  'seated_cable_row',
  'one_arm_cable_row',
  'single_arm_pulldown',
  'straight_arm_pulldown',
  'assisted_pullup',
  'pullup',
  'db_row',
  'barbell_row',
  'deadlift',
  'face_pull',
  'overhead_press',
  'db_shoulder_press',
  'lateral_raise',
  'cable_lateral_raise',
  'barbell_curl',
  'hammer_curl',
  'cable_curl',
  'preacher_curl',
  'tricep_pushdown',
  'overhead_tri_ext',
  'cable_oh_tri_ext',
  'skullcrusher',
  'back_squat',
  'leg_press',
  'rdl',
  'leg_extension',
  'leg_curl',
  'calf_raise',
  'goblet_squat',
  'plank',
  'cable_crunch',
  'incline_bench_press',
  'incline_cable_fly',
  'db_bench_press',
  'machine_chest_press',
  'decline_bench_press',
  'high_cable_fly',
  'db_fly',
  'chinup',
  'close_grip_pulldown',
  'tbar_row',
  'chest_supported_row',
  'barbell_shrug',
  'db_shrug',
  'back_extension',
  'good_morning',
  'machine_shoulder_press',
  'arnold_press',
  'front_raise',
  'machine_lateral_raise',
  'rear_delt_fly',
  'reverse_pec_deck',
  'db_curl',
  'incline_db_curl',
  'concentration_curl',
  'spider_curl',
  'reverse_curl',
  'rope_hammer_curl',
  'rope_pushdown',
  'close_grip_bench',
  'bench_dip',
  'diamond_pushup',
  'hack_squat',
  'bulgarian_split_squat',
  'walking_lunge',
  'seated_leg_curl',
  'hip_thrust',
  'cable_kickback',
  'seated_calf_raise',
  'single_leg_calf_raise',
  'crunch',
  'hanging_leg_raise',
  'ab_wheel',
  'side_plank',
  'russian_twist',
  'incline_db_fly',
  'smith_incline_press',
  'incline_machine_press',
  'reverse_grip_bench_press',
  'decline_pushup',
  'smith_bench_press',
  'svend_press',
  'db_floor_press',
  'cable_chest_press',
  'wide_pushup',
  'decline_db_press',
  'incline_pushup',
  'assisted_dip',
  'single_arm_cable_fly',
  'neutral_grip_pullup',
  'reverse_grip_pulldown',
  'machine_pulldown',
  'db_pullover',
  'pendlay_row',
  'meadows_row',
  'seal_row',
  'inverted_row',
  'chest_supported_db_row',
  'wide_grip_cable_row',
  'cable_shrug',
  'rack_pull',
  'prone_y_raise',
  'reverse_hyperextension',
  'superman',
  'push_press',
  'landmine_press',
  'smith_shoulder_press',
  'plate_front_raise',
  'cable_front_raise',
  'pike_pushup',
  'handstand_pushup',
  'leaning_cable_lateral_raise',
  'seated_lateral_raise',
  'upright_row',
  'cable_rear_delt_fly',
  'chest_supported_rear_delt_raise',
  'rear_delt_row',
  'band_pull_apart',
  'ez_bar_curl',
  'bayesian_curl',
  'drag_curl',
  'machine_biceps_curl',
  'ez_preacher_curl',
  'db_preacher_curl',
  'wide_grip_barbell_curl',
  'cross_body_hammer_curl',
  'zottman_curl',
  'wrist_curl',
  'reverse_wrist_curl',
  'farmers_carry',
  'plate_pinch',
  'dead_hang',
  'wrist_roller',
  'ez_overhead_extension',
  'incline_skullcrusher',
  'db_skullcrusher',
  'tate_press',
  'reverse_grip_pushdown',
  'single_arm_pushdown',
  'db_tricep_kickback',
  'cable_tricep_kickback',
  'machine_triceps_extension',
  'jm_press',
  'triceps_dip',
  'seated_dip_machine',
  'smith_close_grip_bench',
  'front_squat',
  'smith_machine_squat',
  'pendulum_squat',
  'belt_squat',
  'single_leg_press',
  'leg_press_feet_low',
  'trap_bar_deadlift',
  'sumo_deadlift',
  'reverse_lunge',
  'forward_lunge',
  'db_step_up',
  'lateral_lunge',
  'cossack_squat',
  'smith_split_squat',
  'single_leg_extension',
  'sissy_squat',
  'reverse_nordic_curl',
  'wall_sit',
  'bodyweight_squat',
  'stiff_leg_deadlift',
  'db_rdl',
  'single_leg_rdl',
  'nordic_curl',
  'glute_ham_raise',
  'stability_ball_leg_curl',
  'standing_leg_curl',
  'machine_hip_thrust',
  'db_hip_thrust',
  'single_leg_hip_thrust',
  'glute_bridge',
  'frog_pump',
  'glute_kickback_machine',
  'cable_pull_through',
  'hip_abduction_machine',
  'cable_hip_abduction',
  'hip_adduction_machine',
  'kettlebell_swing',
  'donkey_calf_raise',
  'leg_press_calf_raise',
  'smith_calf_raise',
  'db_calf_raise',
  'tibialis_raise',
  'decline_situp',
  'reverse_crunch',
  'hanging_knee_raise',
  'machine_crunch',
  'bicycle_crunch',
  'v_up',
  'toes_to_bar',
  'lying_leg_raise',
  'dragon_flag',
  'pallof_press',
  'cable_woodchop',
  'suitcase_carry',
  'dead_bug',
  'bird_dog',
  'hollow_hold',
  'stir_the_pot',
  'side_bend',
];

void main() {
  test(
    'merged seed keeps the historic order of the original 212 rows (new rows follow)',
    () {
      final ids = [for (final e in seedExercises()) e.id];
      expect(ids.sublist(0, _snapshot.length), _snapshot);
      expect(ids.toSet().length, ids.length);
    },
  );

  test('seed region parts are disjoint and the merge equals their union', () {
    final seen = <String, String>{};
    var total = 0;
    seedRegionParts.forEach((region, build) {
      for (final e in build()) {
        expect(
          seen.containsKey(e.id),
          isFalse,
          reason: '${e.id} in $region and ${seen[e.id]}',
        );
        seen[e.id] = region;
        total++;
      }
    });
    expect(seedExercises().length, total);
    expect(total, greaterThanOrEqualTo(212));
  });

  test(
    'profile region parts are disjoint, cover every seed row, no strays',
    () {
      final seen = <String>{};
      var total = 0;
      profileRegionParts.forEach((region, map) {
        for (final id in map.keys) {
          expect(seen.add(id), isTrue, reason: '$id duplicated (see $region)');
          total++;
        }
      });
      expect(mergedBuiltInProfiles.length, total);
      final seedIds = {for (final e in seedExercises()) e.id};
      expect(seen, seedIds);
    },
  );

  test('section region parts are disjoint and every id is a seed row', () {
    final seedIds = {for (final e in seedExercises()) e.id};
    final seen = <String>{};
    final keys = <String>{};
    for (final entry in splitSectionRegionParts.entries) {
      for (final s in entry.value) {
        for (final id in s.ids) {
          expect(
            seen.add(id),
            isTrue,
            reason: '$id duplicated (see ${entry.key})',
          );
          expect(seedIds, contains(id));
        }
        expect(keys.add('${entry.key}/${s.key}'), isTrue);
      }
    }
    // every muscle still exposes its sections
    for (final m in MuscleGroup.values) {
      expect(SplitCatalog.sectionsFor(m), isNotEmpty, reason: m.name);
    }
    // Split sub-areas keep their original key as the family lead, so every pre-split section id still exists.
    final legIds = SplitCatalog.sectionsFor(
      MuscleGroup.legs,
    ).map((s) => s.id).toList();
    expect(legIds, [
      'legs_quads',
      'legs_quads_goblet',
      'legs_quads_press',
      'legs_lunges',
      'legs_lunges_step',
      'legs_lunges_sled',
      'legs_quad_iso',
      'legs_hams',
      'legs_hams_curl',
      'legs_hams_bodyweight',
      'legs_glutes',
      'legs_glutes_hinge',
      'legs_glutes_kick',
      'legs_glutes_abduct',
      'legs_glutes_adduct',
      'legs_calves',
      'legs_calves_seated',
      'legs_calves_tibialis',
    ]);
    for (final lead in [
      'legs_quads',
      'legs_lunges',
      'legs_quad_iso',
      'legs_hams',
      'legs_glutes',
      'legs_calves',
    ]) {
      expect(legIds, contains(lead));
    }
  });
}
