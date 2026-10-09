import '../split_section_def.dart';

// Curated sub-sections: chest (muscle: chest). Display order = list order (compounds first). Section keys are stable ids; do not
// rename them. Sections that share a `family` are one sub-area split to stay <= 13 exercises each.
const List<SectionDef> sectionsChest = [
  SectionDef(
    'upper',
    'Upper chest',
    'Incline pressing and flyes for the clavicular head.',
    [
      'incline_bench_press',
      'incline_db_press',
      'smith_incline_press',
      'incline_machine_press',
      'reverse_grip_bench_press',
      'decline_pushup',
      'incline_cable_fly',
      'incline_db_fly',
      'plate_loaded_incline_press',
      'incline_cable_press',
      'band_incline_press',
    ],
  ),
  SectionDef(
    'mid',
    'Mid chest · Presses',
    'Barbell, dumbbell, machine and plate-loaded presses for overall chest mass.',
    [
      'bench_press',
      'db_bench_press',
      'smith_bench_press',
      'machine_chest_press',
      'plate_loaded_chest_press',
      'db_floor_press',
      'barbell_floor_press',
      'kb_floor_press',
      'svend_press',
    ],
  ),
  SectionDef(
    'mid_cable',
    'Mid chest · Cable, push-ups & band',
    'Cable presses, push-up variations and band presses.',
    [
      'pushup',
      'cable_chest_press',
      'wide_pushup',
      'single_arm_cable_chest_press',
      'band_chest_press',
      'archer_pushup',
      'ring_pushup',
      'fingertip_pushup',
    ],
    family: 'mid',
  ),
  SectionDef(
    'lower',
    'Lower chest',
    'Decline and dip patterns for the lower fibres.',
    [
      'dips',
      'decline_bench_press',
      'decline_db_press',
      'assisted_dip',
      'incline_pushup',
      'high_cable_fly',
      'decline_machine_press',
      'smith_decline_press',
    ],
  ),
  SectionDef(
    'fly',
    'Flyes & isolation',
    'Stretch and squeeze the chest without the triceps.',
    [
      'cable_fly',
      'pec_deck',
      'db_fly',
      'single_arm_cable_fly',
      'seated_cable_fly',
      'band_chest_fly',
    ],
  ),
];
