import '../split_section_def.dart';

// Curated sub-sections: calves_adductors (muscle: legs). Display order = list order (compounds first). Section keys are stable ids; do not
// rename them. Sections that share a `family` are one sub-area split to stay <= 13 exercises each.
const List<SectionDef> sectionsCalvesAdductors = [
  SectionDef(
    'calves',
    'Calves · Standing',
    'Straight-knee raises for the gastrocnemius.',
    [
      'calf_raise',
      'standing_barbell_calf_raise',
      'smith_calf_raise',
      'cable_calf_raise',
      'donkey_calf_raise',
      'leg_press_calf_raise',
      'db_calf_raise',
      'single_leg_db_calf_raise',
      'stair_calf_raise',
      'band_calf_raise',
      'bodyweight_calf_raise',
      'single_leg_calf_raise',
    ],
  ),
  SectionDef(
    'calves_seated',
    'Calves · Seated & bent-knee',
    'Bent-knee raises that target the soleus.',
    [
      'seated_calf_raise',
      'seated_barbell_calf_raise',
      'seated_db_calf_raise',
      'bent_knee_calf_raise',
    ],
    family: 'calves',
  ),
  SectionDef(
    'calves_tibialis',
    'Calves · Tibialis (shins)',
    'Tibialis raises for the front of the lower leg.',
    ['tibialis_raise', 'band_tibialis_raise', 'weighted_tibialis_raise'],
    family: 'calves',
  ),
];
