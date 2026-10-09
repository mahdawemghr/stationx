import '../models/models.dart';

part 'profiles/profiles_chest.dart';
part 'profiles/profiles_back.dart';
part 'profiles/profiles_shoulders.dart';
part 'profiles/profiles_biceps_forearms.dart';
part 'profiles/profiles_triceps.dart';
part 'profiles/profiles_quads.dart';
part 'profiles/profiles_hamstrings_glutes.dart';
part 'profiles/profiles_calves_adductors.dart';
part 'profiles/profiles_core.dart';
part 'profiles/profiles_other.dart';

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

/// Region part maps, in merge order. A region agent edits ONLY its own profiles/profiles_REGION.dart.
final Map<String, Map<String, ExerciseMuscleProfile>> profileRegionParts = {
  'chest': profilesChest,
  'back': profilesBack,
  'shoulders': profilesShoulders,
  'biceps_forearms': profilesBicepsForearms,
  'triceps': profilesTriceps,
  'quads': profilesQuads,
  'hamstrings_glutes': profilesHamstringsGlutes,
  'calves_adductors': profilesCalvesAdductors,
  'core': profilesCore,
  'other': profilesOther,
};

/// All parts merged (ids are unique across parts; a test enforces it).
final Map<String, ExerciseMuscleProfile> mergedBuiltInProfiles = {
  for (final p in profileRegionParts.values) ...p,
};
