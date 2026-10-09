import '../models/models.dart';
import 'muscle_profiles.dart';
import 'split_catalog.dart';

/// A labelled (or unlabelled MAIN) run of exercises inside a [WorkoutSection].
class WorkoutSubSection {
  const WorkoutSubSection({
    required this.label,
    required this.isMain,
    required this.items,
  });

  /// Sub-header text ("Upper chest"); null for the main group (no sub-header: "just chest").
  final String? label;
  final bool isMain;
  final List<RoutineExercise> items;
}

/// One visual section of a workout: everything that trains one [SectionMuscle]. [startIndex] is the
/// position of its first exercise in the list the section was built from.
class WorkoutSection {
  const WorkoutSection({
    required this.muscle,
    required this.label,
    required this.groups,
    required this.startIndex,
  });
  final SectionMuscle muscle;
  final String label;
  final List<WorkoutSubSection> groups;
  final int startIndex;

  List<RoutineExercise> get items => [for (final g in groups) ...g.items];
  int get sets => items.fold(0, (a, e) => a + e.sets);

  @Deprecated('Use muscle')
  MuscleRegion get region => muscle.regions.first;
}

/// Header label shared by every screen (thin wrapper kept for compatibility).
String sectionLabel(MuscleRegion r) => SectionMuscle.of(r).label;

class _Info {
  _Info(this.index, this.muscle, this.rank, this.label, this.custom);
  final int index;
  final SectionMuscle? muscle; // null = unknown exercise id
  final int rank; // 0 = main group
  final String? label; // null = main
  final bool custom;
  bool get isMain => label == null;
}

/// Sections, their sub-area order and the main-vs-sub-area rules. PURE DART.
///
/// Rules: one section per [SectionMuscle]; inside it MAIN exercises (general/compound; no sub-header)
/// come first, then sub-areas in canonical order. Back: Lats + Upper back are main, then Traps, then Lower
/// back. Forearms: everything is main. Custom exercises are main (after built-in mains). A built-in whose
/// curated section belongs to another muscle than its profile says (e.g. Face Pull) is placed by its
/// primary leaf (Rear delts) in the muscle its profile says.
abstract final class WorkoutSections {
  /// Curated section ids that are the MAIN group of their muscle (no sub-header).
  static const Set<String> mainSectionIds = {
    'chest_mid',
    'chest_mid_cable',
    'back_lats',
    'back_lats_pulldown',
    'back_lats_pullover',
    'back_upper',
    'back_upper_cable',
    'back_upper_bodyweight',
    'shoulders_front',
    'shoulders_front_alt',
    'shoulders_front_raise',
    'biceps_mass',
    'biceps_mass_db',
    'biceps_forearms',
    'biceps_forearms_wrist',
    'biceps_forearms_reverse',
    'triceps_press',
    'legs_quads',
    'legs_quads_goblet',
    'legs_quads_press',
    'core_abs',
    'core_abs_legs',
  };

  /// True when [sectionId] (a curated `SplitCatalog` section id) has a position in the canonical order.
  static bool knowsSection(String sectionId) => _subs.containsKey(sectionId);

  // Sub-area order per curated section id: (muscle, rank, fallback label). Rank 0 = main. Sections split from
  // one sub-area (SplitCatalog families) share the sub-header label and take consecutive ranks, so they
  // merge into ONE sub-header in the canonical order; main sections have no header.
  static const Map<String, (SectionMuscle, int, String)> _subs = {
    'chest_mid': (SectionMuscle.chest, 0, 'Mid chest'),
    'chest_mid_cable': (SectionMuscle.chest, 0, 'Mid chest'),
    'chest_upper': (SectionMuscle.chest, 1, 'Upper chest'),
    'chest_lower': (SectionMuscle.chest, 2, 'Lower chest'),
    'chest_fly': (SectionMuscle.chest, 3, 'Flyes & isolation'),
    'back_lats': (SectionMuscle.back, 0, 'Lats'),
    'back_lats_pulldown': (SectionMuscle.back, 0, 'Lats'),
    'back_lats_pullover': (SectionMuscle.back, 0, 'Lats'),
    'back_upper': (SectionMuscle.back, 0, 'Upper back'),
    'back_upper_cable': (SectionMuscle.back, 0, 'Upper back'),
    'back_upper_bodyweight': (SectionMuscle.back, 0, 'Upper back'),
    'back_traps': (SectionMuscle.back, 1, 'Traps'),
    'back_lower': (SectionMuscle.back, 2, 'Lower back'),
    'shoulders_front': (SectionMuscle.shoulders, 0, 'Front & press'),
    'shoulders_front_alt': (SectionMuscle.shoulders, 0, 'Front & press'),
    'shoulders_front_raise': (SectionMuscle.shoulders, 0, 'Front & press'),
    'shoulders_side': (SectionMuscle.shoulders, 1, 'Side delts'),
    'shoulders_rear': (SectionMuscle.shoulders, 2, 'Rear delts'),
    'biceps_mass': (SectionMuscle.biceps, 0, 'Mass builders'),
    'biceps_mass_db': (SectionMuscle.biceps, 0, 'Mass builders'),
    'biceps_peak': (SectionMuscle.biceps, 1, 'Peak'),
    'biceps_brachialis': (SectionMuscle.biceps, 2, 'Brachialis'),
    'biceps_forearms': (SectionMuscle.forearms, 0, 'Forearms'),
    'biceps_forearms_wrist': (SectionMuscle.forearms, 0, 'Forearms'),
    'biceps_forearms_reverse': (SectionMuscle.forearms, 0, 'Forearms'),
    'triceps_press': (SectionMuscle.triceps, 0, 'Presses & dips'),
    'triceps_overhead': (SectionMuscle.triceps, 1, 'Overhead'),
    'triceps_pushdown': (SectionMuscle.triceps, 2, 'Pushdowns'),
    'legs_quads': (SectionMuscle.legs, 0, 'Quads'),
    'legs_quads_goblet': (SectionMuscle.legs, 0, 'Quads'),
    'legs_quads_press': (SectionMuscle.legs, 0, 'Quads'),
    'legs_lunges': (SectionMuscle.legs, 1, 'Lunges & single-leg'),
    'legs_lunges_step': (SectionMuscle.legs, 2, 'Lunges & single-leg'),
    'legs_lunges_sled': (SectionMuscle.legs, 3, 'Lunges & single-leg'),
    'legs_quad_iso': (SectionMuscle.legs, 4, 'Quad isolation'),
    'legs_hams': (SectionMuscle.legs, 5, 'Hamstrings'),
    'legs_hams_curl': (SectionMuscle.legs, 6, 'Hamstrings'),
    'legs_hams_bodyweight': (SectionMuscle.legs, 7, 'Hamstrings'),
    'legs_glutes': (SectionMuscle.legs, 8, 'Glutes'),
    'legs_glutes_hinge': (SectionMuscle.legs, 9, 'Glutes'),
    'legs_glutes_kick': (SectionMuscle.legs, 10, 'Glutes'),
    'legs_glutes_abduct': (SectionMuscle.legs, 11, 'Glutes'),
    'legs_glutes_adduct': (SectionMuscle.legs, 12, 'Glutes'),
    'legs_calves': (SectionMuscle.legs, 13, 'Calves'),
    'legs_calves_seated': (SectionMuscle.legs, 14, 'Calves'),
    'legs_calves_tibialis': (SectionMuscle.legs, 15, 'Calves'),
    'core_abs': (SectionMuscle.core, 0, 'Abs'),
    'core_abs_legs': (SectionMuscle.core, 0, 'Abs'),
    'core_stability': (SectionMuscle.core, 1, 'Stability & obliques'),
    'core_stability_rotation': (SectionMuscle.core, 2, 'Stability & obliques'),
    'core_stability_carry': (SectionMuscle.core, 3, 'Stability & obliques'),
  };

  // Fallback when the curated section disagrees with the profile muscle: place by the primary leaf.
  static const Map<Muscle, String> _leafSub = {
    Muscle.upperChest: 'chest_upper',
    Muscle.midChest: 'chest_mid',
    Muscle.lowerChest: 'chest_lower',
    Muscle.lats: 'back_lats',
    Muscle.upperBack: 'back_upper',
    Muscle.traps: 'back_traps',
    Muscle.lowerBack: 'back_lower',
    Muscle.frontDelts: 'shoulders_front',
    Muscle.sideDelts: 'shoulders_side',
    Muscle.rearDelts: 'shoulders_rear',
    Muscle.bicepsLongHead: 'biceps_mass',
    Muscle.bicepsShortHead: 'biceps_peak',
    Muscle.brachialis: 'biceps_brachialis',
    Muscle.tricepsLongHead: 'triceps_overhead',
    Muscle.tricepsLateralHead: 'triceps_pushdown',
    Muscle.tricepsMedialHead: 'triceps_pushdown',
    Muscle.rectusFemoris: 'legs_quads',
    Muscle.vastusLateralis: 'legs_quads',
    Muscle.vastusMedialis: 'legs_quads',
    Muscle.vastusIntermedius: 'legs_quads',
    Muscle.bicepsFemoris: 'legs_hams',
    Muscle.semitendinosus: 'legs_hams',
    Muscle.semimembranosus: 'legs_hams',
    Muscle.gluteusMaximus: 'legs_glutes',
    Muscle.gluteusMedius: 'legs_glutes',
    Muscle.gluteusMinimus: 'legs_glutes',
    Muscle.gastrocnemius: 'legs_calves',
    Muscle.soleus: 'legs_calves',
    Muscle.rectusAbdominis: 'core_abs',
    Muscle.obliques: 'core_stability',
    Muscle.transverseAbdominis: 'core_stability',
  };

  static List<_Info> _classify(
    List<RoutineExercise> list,
    List<Exercise> catalog,
  ) {
    final byId = {for (final e in catalog) e.id: e};
    final unknownRank = <String, int>{};
    final out = <_Info>[];
    for (var i = 0; i < list.length; i++) {
      final ex = byId[list[i].exerciseId];
      if (ex == null) {
        out.add(_Info(i, null, 0, null, false));
        continue;
      }
      final profile = MuscleProfiles.of(ex);
      final muscle = SectionMuscle.of(profile.primaryRegion);
      if (muscle == SectionMuscle.forearms || ex.isCustom) {
        out.add(_Info(i, muscle, 0, null, ex.isCustom));
        continue;
      }
      final sid = SplitCatalog.sectionIdOf(ex);
      var hit = _subs[sid];
      if (hit != null && hit.$1 != muscle) hit = null;
      if (hit == null) {
        final leaf = profile.lead.muscle;
        final lid = leaf == null ? null : _leafSub[leaf];
        final lhit = lid == null ? null : _subs[lid];
        if (lhit != null && lhit.$1 == muscle) hit = lhit;
      }
      if (hit != null) {
        out.add(_Info(i, muscle, hit.$2, hit.$2 == 0 ? null : hit.$3, false));
      } else if (_subs.containsKey(sid) || sid.startsWith('mine_')) {
        out.add(
          _Info(i, muscle, 0, null, false),
        ); // known id of another muscle, no leaf: main
      } else {
        // Unknown curated section id: a sub-area by its catalog label, after the known ones.
        final label = _labelOf(sid) ?? sid;
        final r = unknownRank.putIfAbsent(sid, () => 100 + unknownRank.length);
        out.add(_Info(i, muscle, r, label, false));
      }
    }
    return out;
  }

  static String? _labelOf(String sectionId) {
    for (final g in MuscleGroup.values) {
      for (final s in SplitCatalog.sectionsFor(g)) {
        if (s.id == sectionId) return s.label;
      }
    }
    return null;
  }

  /// Permutation of input indices in canonical order (unknown ids last, in input order).
  static List<_Info> _order(
    List<_Info> infos,
    List<SectionMuscle>? muscleOrder,
  ) {
    final order = <SectionMuscle>[...?muscleOrder];
    final seen = <SectionMuscle>{};
    order.removeWhere((m) => !seen.add(m));
    for (final i in infos) {
      if (i.muscle != null && seen.add(i.muscle!)) order.add(i.muscle!);
    }
    final out = <_Info>[];
    for (final m in order) {
      final mine = infos.where((i) => i.muscle == m).toList()
        ..sort((a, b) {
          final r = a.rank.compareTo(b.rank);
          if (r != 0) return r;
          final c = (a.custom ? 1 : 0).compareTo(b.custom ? 1 : 0);
          return c != 0 ? c : a.index.compareTo(b.index);
        });
      out.addAll(mine);
    }
    out.addAll(infos.where((i) => i.muscle == null));
    return out;
  }

  /// Canonical flat order: one block per [SectionMuscle] (ordered by [muscleOrder], then by first
  /// appearance), MAIN exercises first, then sub-areas. Stable, idempotent, never drops or duplicates;
  /// unknown ids go last.
  static List<RoutineExercise> arrange(
    List<RoutineExercise> exercises,
    List<Exercise> catalog, {
    List<SectionMuscle>? muscleOrder,
  }) {
    final infos = _classify(exercises, catalog);
    return [for (final i in _order(infos, muscleOrder)) exercises[i.index]];
  }

  /// True when [arrange] would not change the list.
  static bool isArranged(
    List<RoutineExercise> exercises,
    List<Exercise> catalog,
  ) {
    final infos = _classify(exercises, catalog);
    final o = _order(infos, null);
    for (var k = 0; k < o.length; k++) {
      if (o[k].index != k) return false;
    }
    return true;
  }

  /// Sections of the ARRANGED order: exactly one per [SectionMuscle]. For finished/saved workouts (the
  /// input is arranged first, so [WorkoutSection.startIndex] indexes the arranged list). Unknown ids are skipped.
  /// Use [groupContiguous] for drafts that must not be reordered.
  static List<WorkoutSection> group(
    List<RoutineExercise> exercises,
    List<Exercise> catalog,
  ) {
    final infos = _classify(exercises, catalog);
    return _build(_order(infos, null), exercises);
  }

  /// Old behaviour for IN-PROGRESS drafts: never reorders; a new section starts whenever the muscle
  /// changes (so one muscle can appear twice if its exercises are not contiguous). [WorkoutSection.startIndex]
  /// indexes the input. Unknown ids are skipped.
  static List<WorkoutSection> groupContiguous(
    List<RoutineExercise> exercises,
    List<Exercise> catalog,
  ) => _build(_classify(exercises, catalog), exercises, positional: false);

  static List<WorkoutSection> _build(
    List<_Info> ordered,
    List<RoutineExercise> src, {
    bool positional = true,
  }) {
    final out = <WorkoutSection>[];
    SectionMuscle? cur;
    var groups = <WorkoutSubSection>[];
    var items = <RoutineExercise>[];
    String? gLabel;
    var gStarted = false;
    var start = 0;
    void flushGroup() {
      if (items.isNotEmpty) {
        groups.add(
          WorkoutSubSection(
            label: gLabel,
            isMain: gLabel == null,
            items: items,
          ),
        );
      }
      items = [];
      gStarted = false;
    }

    void flushSection() {
      flushGroup();
      final m = cur;
      if (m != null && groups.isNotEmpty) {
        out.add(
          WorkoutSection(
            muscle: m,
            label: m.label,
            groups: groups,
            startIndex: start,
          ),
        );
      }
      groups = [];
    }

    for (var pos = 0; pos < ordered.length; pos++) {
      final i = ordered[pos];
      if (i.muscle == null) continue;
      final at = positional ? pos : i.index;
      if (cur != i.muscle) {
        flushSection();
        cur = i.muscle;
        start = at;
      }
      if (!gStarted || gLabel != i.label) {
        flushGroup();
        gLabel = i.label;
        gStarted = true;
      }
      items.add(src[i.index]);
    }
    if (cur != null) flushSection();
    return out;
  }

  /// Where to insert [newExercise] into [current] so it lands in its canonical place (end of its
  /// sub-area; a new muscle goes after the existing sections). [current] need not be arranged: it is
  /// never reordered, the index is just after the last existing exercise that canonically precedes it.
  static int insertionIndex(
    List<RoutineExercise> current,
    RoutineExercise newExercise,
    List<Exercise> catalog,
  ) {
    final all = [...current, newExercise];
    final order = _order(_classify(all, catalog), null);
    final n = current.length;
    if (all.isEmpty || _classify(all, catalog)[n].muscle == null) return n;
    var best = -1;
    for (final i in order) {
      if (i.index == n) break;
      if (i.index > best) best = i.index;
    }
    return best + 1;
  }

  /// Number of sections (= distinct muscles with known exercises) the arranged workout shows.
  static int sectionCount(
    List<RoutineExercise> exercises,
    List<Exercise> catalog,
  ) => group(exercises, catalog).length;

  /// Section headers show only when the workout has two or more sections (same rule on every screen).
  static bool showSectionHeaders(List<WorkoutSection> sections) =>
      sections.length >= 2;
}
