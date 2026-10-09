import '../split_section_def.dart';

// Curated sub-sections: triceps (muscle: triceps). Add ids to the matching section's list (display order = list order,
// compounds first). Section keys/labels are stable ids; do not rename them.
const List<SectionDef> sectionsTriceps = [
  SectionDef(
    'overhead',
    'Overhead (long head)',
    'Arms overhead to stretch the largest head.',
    [
      'overhead_tri_ext',
      'cable_oh_tri_ext',
      'ez_overhead_extension',
      'skullcrusher',
      'incline_skullcrusher',
      'db_skullcrusher',
      'tate_press',
      'single_arm_db_oh_extension',
      'single_arm_cable_oh_extension',
      'bodyweight_tri_extension',
      'kb_oh_tri_ext',
      'band_oh_tri_ext',
    ],
  ),
  SectionDef(
    'pushdown',
    'Pushdowns',
    'Cable and machine extensions for the lateral and medial heads.',
    [
      'tricep_pushdown',
      'rope_pushdown',
      'single_arm_pushdown',
      'reverse_grip_pushdown',
      'machine_triceps_extension',
      'cable_tricep_kickback',
      'db_tricep_kickback',
      'band_pushdown',
      'cross_body_cable_tri_ext',
      'band_tri_kickback',
    ],
  ),
  SectionDef(
    'press',
    'Presses & dips',
    'Heavy compound lifts for triceps strength.',
    [
      'close_grip_bench',
      'smith_close_grip_bench',
      'jm_press',
      'triceps_dip',
      'seated_dip_machine',
      'bench_dip',
      'diamond_pushup',
      'close_grip_db_press',
      'smith_jm_press',
      'ring_dip',
    ],
  ),
];
