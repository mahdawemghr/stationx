import '../../models/models.dart';
import '../split_section_def.dart';
import 'sections_back.dart';
import 'sections_biceps_forearms.dart';
import 'sections_calves_adductors.dart';
import 'sections_chest.dart';
import 'sections_core.dart';
import 'sections_hamstrings_glutes.dart';
import 'sections_quads.dart';
import 'sections_shoulders.dart';
import 'sections_triceps.dart';

/// Region data files, in merge order (legs = quads, then hamstrings/glutes, then calves). Region agents edit
/// ONLY their own sections_REGION.dart; this merge file never needs to change for new exercises.
const Map<String, List<SectionDef>> splitSectionRegionParts = {
  'chest': sectionsChest,
  'back': sectionsBack,
  'shoulders': sectionsShoulders,
  'biceps_forearms': sectionsBicepsForearms,
  'triceps': sectionsTriceps,
  'quads': sectionsQuads,
  'hamstrings_glutes': sectionsHamstringsGlutes,
  'calves_adductors': sectionsCalvesAdductors,
  'core': sectionsCore,
};

/// Section -> ordered exercise ids per muscle (single source of truth for SplitCatalog).
const Map<MuscleGroup, List<SectionDef>> splitSectionsByMuscle = {
  MuscleGroup.chest: sectionsChest,
  MuscleGroup.back: sectionsBack,
  MuscleGroup.shoulders: sectionsShoulders,
  MuscleGroup.biceps: sectionsBicepsForearms,
  MuscleGroup.triceps: sectionsTriceps,
  MuscleGroup.legs: [
    ...sectionsQuads,
    ...sectionsHamstringsGlutes,
    ...sectionsCalvesAdductors,
  ],
  MuscleGroup.core: sectionsCore,
};
