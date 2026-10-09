import '../models/models.dart';
import 'exercise_recommender.dart';
import 'muscle_profiles.dart';
import 'split_models.dart';
import 'split_section_def.dart';
import 'split_sections/sections_all.dart';

RoutineExercise _r(String id, [int sets = 3, int min = 8, int max = 12]) =>
    RoutineExercise(exerciseId: id, sets: sets, repMin: min, repMax: max);

/// Presets, muscle sub-sections and exercise grouping for the schedule setup.
/// PURE DART: no UI, no storage. Sub-sections are a static map keyed by exercise id.
abstract final class SplitCatalog {
  // ── Sub-sections (single source of truth: section → exercise ids) ──
  static const Map<MuscleGroup, List<SectionDef>> _sections =
      splitSectionsByMuscle;

  /// Universally used lifts across all muscles, shown as "Common exercises" in the library.
  static const List<String> commonExerciseIds = [
    'bench_press',
    'incline_db_press',
    'db_bench_press',
    'pushup',
    'dips',
    'pullup',
    'lat_pulldown',
    'barbell_row',
    'seated_cable_row',
    'db_row',
    'deadlift',
    'overhead_press',
    'lateral_raise',
    'face_pull',
    'barbell_curl',
    'hammer_curl',
    'tricep_pushdown',
    'skullcrusher',
    'back_squat',
    'leg_press',
    'rdl',
    'walking_lunge',
    'leg_curl',
    'leg_extension',
    'hip_thrust',
    'calf_raise',
    'plank',
    'incline_bench_press',
    'front_squat',
    'ez_bar_curl',
    'seated_calf_raise',
    'hanging_leg_raise',
    'cable_crunch',
    // Added with the ~420 catalogue: universal staples only (every SectionMuscle incl. Forearms stays covered).
    'weighted_pullup',
    'goblet_squat',
    'bulgarian_split_squat',
    'kettlebell_swing',
    'farmers_carry',
    'db_wrist_curl',
  ];

  static final Set<String> _common = commonExerciseIds.toSet();

  static bool isCommon(String id) => _common.contains(id);

  static final Map<String, ({MuscleGroup muscle, int section, int order})>
  _byExercise = {
    for (final e in _sections.entries)
      for (var s = 0; s < e.value.length; s++)
        for (var i = 0; i < e.value[s].ids.length; i++)
          e.value[s].ids[i]: (muscle: e.key, section: s, order: i),
  };

  static const Map<MuscleGroup, List<RoutineExercise>> _suggested = {
    MuscleGroup.chest: [
      RoutineExercise(
        exerciseId: 'bench_press',
        sets: 4,
        repMin: 6,
        repMax: 10,
      ),
      RoutineExercise(
        exerciseId: 'incline_db_press',
        sets: 3,
        repMin: 8,
        repMax: 12,
      ),
      RoutineExercise(exerciseId: 'dips', sets: 3, repMin: 8, repMax: 12),
      RoutineExercise(exerciseId: 'cable_fly', sets: 3, repMin: 12, repMax: 15),
    ],
    MuscleGroup.back: [
      RoutineExercise(exerciseId: 'pullup', sets: 3, repMin: 6, repMax: 10),
      RoutineExercise(
        exerciseId: 'barbell_row',
        sets: 4,
        repMin: 6,
        repMax: 10,
      ),
      RoutineExercise(
        exerciseId: 'seated_cable_row',
        sets: 3,
        repMin: 8,
        repMax: 12,
      ),
      RoutineExercise(
        exerciseId: 'back_extension',
        sets: 3,
        repMin: 10,
        repMax: 15,
      ),
    ],
    MuscleGroup.shoulders: [
      RoutineExercise(
        exerciseId: 'overhead_press',
        sets: 4,
        repMin: 6,
        repMax: 10,
      ),
      RoutineExercise(
        exerciseId: 'lateral_raise',
        sets: 3,
        repMin: 12,
        repMax: 15,
      ),
      RoutineExercise(exerciseId: 'face_pull', sets: 3, repMin: 12, repMax: 15),
    ],
    MuscleGroup.biceps: [
      RoutineExercise(
        exerciseId: 'barbell_curl',
        sets: 3,
        repMin: 8,
        repMax: 12,
      ),
      RoutineExercise(
        exerciseId: 'incline_db_curl',
        sets: 3,
        repMin: 10,
        repMax: 12,
      ),
      RoutineExercise(
        exerciseId: 'hammer_curl',
        sets: 3,
        repMin: 10,
        repMax: 12,
      ),
    ],
    MuscleGroup.triceps: [
      RoutineExercise(
        exerciseId: 'close_grip_bench',
        sets: 3,
        repMin: 6,
        repMax: 10,
      ),
      RoutineExercise(
        exerciseId: 'overhead_tri_ext',
        sets: 3,
        repMin: 10,
        repMax: 12,
      ),
      RoutineExercise(
        exerciseId: 'tricep_pushdown',
        sets: 3,
        repMin: 10,
        repMax: 15,
      ),
    ],
    MuscleGroup.legs: [
      RoutineExercise(exerciseId: 'back_squat', sets: 4, repMin: 5, repMax: 8),
      RoutineExercise(exerciseId: 'rdl', sets: 3, repMin: 8, repMax: 10),
      RoutineExercise(exerciseId: 'leg_curl', sets: 3, repMin: 10, repMax: 15),
      RoutineExercise(
        exerciseId: 'calf_raise',
        sets: 4,
        repMin: 10,
        repMax: 15,
      ),
    ],
    MuscleGroup.core: [
      RoutineExercise(
        exerciseId: 'hanging_leg_raise',
        sets: 3,
        repMin: 8,
        repMax: 12,
      ),
      RoutineExercise(
        exerciseId: 'cable_crunch',
        sets: 3,
        repMin: 10,
        repMax: 15,
      ),
      RoutineExercise(exerciseId: 'plank', sets: 3, repMin: 30, repMax: 60),
    ],
  };

  static const Map<String, String> _reasons = {
    'bench_press':
        'The main flat press: heavy, simple and the best chest mass builder.',
    'incline_db_press': 'Targets the upper chest with a deep stretch.',
    'incline_bench_press': 'Heavy upper-chest pressing.',
    'dips': 'Loads the lower chest and triceps with bodyweight.',
    'cable_fly': 'Constant tension to finish the chest without the triceps.',
    'pullup': 'The best vertical pull for lat width.',
    'lat_pulldown': 'Pull-up pattern you can load and scale easily.',
    'barbell_row': 'Heavy row for back thickness.',
    'seated_cable_row': 'Smooth, controlled row for the mid back.',
    'back_extension': 'Strengthens the lower back and glutes with low fatigue.',
    'deadlift': 'Full posterior-chain strength; heavy, so use sparingly.',
    'overhead_press': 'The main shoulder press for the front delts.',
    'lateral_raise': 'Builds shoulder width, which presses barely touch.',
    'face_pull': 'Rear delts and upper back for healthy shoulders.',
    'barbell_curl': 'Heavy biceps builder; easy to progress.',
    'incline_db_curl': 'Stretched position works the long head.',
    'hammer_curl': 'Builds the brachialis for thicker-looking arms.',
    'close_grip_bench': 'Heavy compound lift for triceps strength.',
    'overhead_tri_ext':
        'Overhead position trains the long head, the biggest part of the triceps.',
    'tricep_pushdown': 'Easy-on-joints isolation to finish the triceps.',
    'back_squat': 'The king of leg exercises: quads, glutes and core.',
    'rdl': 'Hinge pattern that loads the hamstrings and glutes.',
    'leg_curl': 'Isolates the hamstrings, which squats barely reach.',
    'calf_raise': 'Direct work for the calves, which need high reps.',
    'hanging_leg_raise': 'Trains the lower abs and grip together.',
    'cable_crunch': 'Loadable crunch so you can progress your abs.',
    'plank': 'Builds trunk stability with no equipment.',
  };

  /// Built-in presets: Push/Pull/Legs, Upper/Lower, Full Body, Bro split (NOT Custom — Custom is "no preset").
  static final List<SplitPreset> presets = [
    SplitPreset(
      id: 'ppl',
      name: 'Push / Pull / Legs',
      blurb:
          'Pressing, pulling, then legs. Each muscle gets hit about twice a week if you run it twice.',
      suggestedDaysPerWeek: '3–6 days / week',
      days: [
        SplitDayPlan(
          name: 'Push',
          muscles: const [
            MuscleGroup.chest,
            MuscleGroup.shoulders,
            MuscleGroup.triceps,
          ],
          exercises: [
            _r('bench_press', 4, 6, 10),
            _r('overhead_press', 3, 6, 10),
            _r('incline_db_press', 3, 8, 12),
            _r('lateral_raise', 3, 12, 15),
            _r('tricep_pushdown', 3, 10, 15),
            _r('overhead_tri_ext', 3, 10, 12),
          ],
        ),
        SplitDayPlan(
          name: 'Pull',
          muscles: const [MuscleGroup.back, MuscleGroup.biceps],
          exercises: [
            _r('pullup', 3, 6, 10),
            _r('barbell_row', 4, 6, 10),
            _r('seated_cable_row', 3, 8, 12),
            _r('barbell_curl', 3, 8, 12),
            _r('hammer_curl', 3, 10, 12),
          ],
        ),
        SplitDayPlan(
          name: 'Legs',
          muscles: const [MuscleGroup.legs, MuscleGroup.core],
          exercises: [
            _r('back_squat', 4, 5, 8),
            _r('rdl', 3, 8, 10),
            _r('leg_press', 3, 10, 12),
            _r('leg_curl', 3, 10, 15),
            _r('calf_raise', 4, 10, 15),
            _r('hanging_leg_raise', 3, 8, 12),
          ],
        ),
      ],
    ),
    SplitPreset(
      id: 'upper_lower',
      name: 'Upper / Lower',
      blurb:
          'Two alternating days: upper body, then lower body. Simple and efficient.',
      suggestedDaysPerWeek: '2–4 days / week',
      days: [
        SplitDayPlan(
          name: 'Upper',
          muscles: const [
            MuscleGroup.chest,
            MuscleGroup.back,
            MuscleGroup.shoulders,
            MuscleGroup.biceps,
            MuscleGroup.triceps,
          ],
          exercises: [
            _r('bench_press', 4, 6, 10),
            _r('barbell_row', 4, 6, 10),
            _r('overhead_press', 3, 6, 10),
            _r('lat_pulldown', 3, 8, 12),
            _r('barbell_curl', 3, 8, 12),
            _r('tricep_pushdown', 3, 10, 15),
          ],
        ),
        SplitDayPlan(
          name: 'Lower',
          muscles: const [MuscleGroup.legs, MuscleGroup.core],
          exercises: [
            _r('back_squat', 4, 5, 8),
            _r('rdl', 3, 8, 10),
            _r('leg_press', 3, 10, 12),
            _r('leg_curl', 3, 10, 15),
            _r('calf_raise', 4, 10, 15),
            _r('plank', 3, 30, 60),
          ],
        ),
      ],
    ),
    SplitPreset(
      id: 'full_body',
      name: 'Full Body',
      blurb:
          'Every session trains the whole body, with the exercises varied between days.',
      suggestedDaysPerWeek: '3 days / week',
      days: [
        SplitDayPlan(
          name: 'Full Body A',
          muscles: const [
            MuscleGroup.chest,
            MuscleGroup.back,
            MuscleGroup.shoulders,
            MuscleGroup.legs,
            MuscleGroup.core,
          ],
          exercises: [
            _r('back_squat', 3, 5, 8),
            _r('bench_press', 3, 6, 10),
            _r('barbell_row', 3, 6, 10),
            _r('lateral_raise', 3, 12, 15),
            _r('plank', 3, 30, 60),
          ],
        ),
        SplitDayPlan(
          name: 'Full Body B',
          muscles: const [
            MuscleGroup.chest,
            MuscleGroup.back,
            MuscleGroup.shoulders,
            MuscleGroup.legs,
            MuscleGroup.core,
          ],
          exercises: [
            _r('rdl', 3, 6, 10),
            _r('overhead_press', 3, 6, 10),
            _r('lat_pulldown', 3, 8, 12),
            _r('incline_db_press', 3, 8, 12),
            _r('cable_crunch', 3, 10, 15),
          ],
        ),
        SplitDayPlan(
          name: 'Full Body C',
          muscles: const [
            MuscleGroup.chest,
            MuscleGroup.back,
            MuscleGroup.biceps,
            MuscleGroup.triceps,
            MuscleGroup.legs,
          ],
          exercises: [
            _r('leg_press', 3, 8, 12),
            _r('db_bench_press', 3, 8, 12),
            _r('seated_cable_row', 3, 8, 12),
            _r('db_curl', 2, 10, 12),
            _r('tricep_pushdown', 2, 10, 15),
            _r('calf_raise', 3, 10, 15),
          ],
        ),
      ],
    ),
    SplitPreset(
      id: 'bro_split',
      name: 'Bro split',
      blurb:
          'One muscle group a day: Chest, Back, Shoulders, Arms, Legs. High volume per muscle.',
      suggestedDaysPerWeek: '5 days / week',
      days: [
        SplitDayPlan(
          name: 'Chest',
          muscles: const [MuscleGroup.chest],
          exercises: [
            _r('bench_press', 4, 6, 10),
            _r('incline_db_press', 4, 8, 12),
            _r('dips', 3, 8, 12),
            _r('cable_fly', 3, 12, 15),
          ],
        ),
        SplitDayPlan(
          name: 'Back',
          muscles: const [MuscleGroup.back],
          exercises: [
            _r('pullup', 4, 6, 10),
            _r('barbell_row', 4, 6, 10),
            _r('seated_cable_row', 3, 8, 12),
            _r('straight_arm_pulldown', 3, 12, 15),
            _r('back_extension', 3, 10, 15),
          ],
        ),
        SplitDayPlan(
          name: 'Shoulders',
          muscles: const [MuscleGroup.shoulders],
          exercises: [
            _r('overhead_press', 4, 6, 10),
            _r('db_shoulder_press', 3, 8, 12),
            _r('lateral_raise', 4, 12, 15),
            _r('face_pull', 3, 12, 15),
          ],
        ),
        SplitDayPlan(
          name: 'Arms',
          muscles: const [MuscleGroup.biceps, MuscleGroup.triceps],
          exercises: [
            _r('barbell_curl', 3, 8, 12),
            _r('incline_db_curl', 3, 10, 12),
            _r('hammer_curl', 3, 10, 12),
            _r('close_grip_bench', 3, 6, 10),
            _r('overhead_tri_ext', 3, 10, 12),
            _r('tricep_pushdown', 3, 10, 15),
          ],
        ),
        SplitDayPlan(
          name: 'Legs',
          muscles: const [MuscleGroup.legs, MuscleGroup.core],
          exercises: [
            _r('back_squat', 4, 5, 8),
            _r('rdl', 3, 8, 10),
            _r('leg_press', 3, 10, 12),
            _r('leg_extension', 3, 12, 15),
            _r('leg_curl', 3, 10, 15),
            _r('calf_raise', 4, 10, 15),
          ],
        ),
      ],
    ),
  ];

  /// Sub-sections of [m] in display order (built-in only; the "Your exercises" section is added by [grouped]).
  static List<SplitSection> sectionsFor(MuscleGroup m) => [
    for (final s in _sections[m] ?? const <SectionDef>[])
      SplitSection(id: _id(m, s.key), label: s.label, muscle: m, hint: s.hint),
  ];

  static String _id(MuscleGroup m, String key) => '${m.name}_$key';

  /// Section id of an exercise: custom exercises belong to [mineSectionId]; built-ins to their mapped section
  /// (or the muscle's last built-in section when the id is not mapped).
  static String sectionIdOf(Exercise e) {
    if (e.isCustom) return mineSectionId(e.primaryMuscle);
    final secs = _sections[e.primaryMuscle];
    if (secs == null || secs.isEmpty) return mineSectionId(e.primaryMuscle);
    final hit = _byExercise[e.id];
    if (hit != null && hit.muscle == e.primaryMuscle) {
      return _id(e.primaryMuscle, secs[hit.section].key);
    }
    // Not curated: derive from the muscle profile, else the muscle's last built-in section.
    return derivedSectionIdOf(e) ?? _id(e.primaryMuscle, secs.last.key);
  }

  /// Exercises whose curated section deliberately differs from what the primary leaf alone gives (flyes are
  /// grouped as isolation work; rows with a lats lead sit with the rows via [sectionOverrideSwaps]; ab wheel is anti-extension
  /// "stability"). Exercises whose section cannot be derived at all (region-level profiles such as curls and
  /// pushdowns) are simply curated. The consistency test allows a derived mismatch only for these ids.
  static const Set<String> sectionOverrideIds = {
    'cable_fly',
    'pec_deck',
    'db_fly',
    'single_arm_cable_fly', // chest: "Flyes & isolation" (leaf is mid chest)
    'ab_wheel', // abs leaf, but an anti-extension stability drill
    'barbell_rollout', // same: anti-extension rollout
    'mountain_climber', // abs leaf, but a plank-based stability drill
  };

  /// Whole sections that are deliberately NOT derivable from the primary leaf (a per-section override table):
  /// every exercise curated in one of these is exempt from the derived == curated check. "Flyes & isolation" is
  /// a movement-type grouping whose members' leaves are chest leaves (mostly mid chest).
  static const Set<String> sectionOverrideSectionIds = {'chest_fly'};

  /// Per-region override table of allowed (derived family lead -> curated family lead) swaps: a row whose
  /// lead leaf is lats (Yates, underhand, one-arm and machine rows...) is curated with the rows
  /// ("back_upper"), not the pull-ups/pulldowns, because the movement pattern decides where it is looked up.
  static const Map<String, Set<String>> sectionOverrideSwaps = {
    'back_lats': {'back_upper'},
  };

  /// True when [e]'s curated section deliberately differs from its profile-derived one: its id is in
  /// [sectionOverrideIds], its curated section is in [sectionOverrideSectionIds], or the
  /// (derived, curated) family pair is in [sectionOverrideSwaps].
  static bool isSectionOverride(Exercise e) {
    if (sectionOverrideIds.contains(e.id)) return true;
    final curated = sectionIdOf(e);
    if (sectionOverrideSectionIds.contains(curated)) return true;
    final derived = derivedSectionIdOf(e);
    return derived != null &&
        (sectionOverrideSwaps[derived]?.contains(familyLeadOf(curated)) ??
            false);
  }

  /// Section id derived ONLY from the exercise's muscle profile (primary leaf, or the region when it maps
  /// to a single sub-area), or null when it cannot be derived defensibly. Used for exercises that are not
  /// curated in [_sections] and checked against the curated map by a consistency test.
  ///
  /// Derivation works at FAMILY level: a sub-area that was split into several sections (e.g. "Mid chest ·
  /// Presses" and "Mid chest · Cable, push-ups & band") is one family, and the result is the family's LEAD
  /// section id. A curated section agrees with the derivation when [familyLeadOf] its id equals the result;
  /// which member of the family an exercise sits in is curated only (see [SectionDef.family]).
  static String? derivedSectionIdOf(Exercise e) {
    final profile = MuscleProfiles.builtIn(e.id);
    if (profile == null) return null;
    final lead = profile.lead;
    final key = lead.muscle != null
        ? _leafSection[lead.muscle!]
        : _regionSection[lead.region];
    if (key == null) return null;
    final m = e.primaryMuscle;
    if (!(_sections[m] ?? const <SectionDef>[]).any((s) => s.key == key)) {
      return null;
    }
    return _id(m, key);
  }

  /// The lead section id of the family that section [sectionId] belongs to (itself when it is a lead, a
  /// custom "mine" section or unknown). Pair with [derivedSectionIdOf] to compare derived and curated sections.
  static String familyLeadOf(String sectionId) {
    for (final e in _sections.entries) {
      for (final s in e.value) {
        if (_id(e.key, s.key) == sectionId) return _id(e.key, s.familyKey);
      }
    }
    return sectionId;
  }

  /// Section ids of the family of [sectionId], lead first, in display order.
  static List<String> familyOf(String sectionId) {
    final lead = familyLeadOf(sectionId);
    final out = <String>[];
    for (final e in _sections.entries) {
      for (final s in e.value) {
        if (_id(e.key, s.familyKey) == lead) out.add(_id(e.key, s.key));
      }
    }
    return out;
  }

  /// Leaf muscle -> LEAD section key of the sub-area it belongs to (the family lead; see [SectionDef.family]).
  static const Map<Muscle, String> _leafSection = {
    Muscle.upperChest: 'upper',
    Muscle.midChest: 'mid',
    Muscle.lowerChest: 'lower',
    Muscle.lats: 'lats',
    Muscle.upperBack: 'upper',
    Muscle.traps: 'traps',
    Muscle.lowerBack: 'lower',
    Muscle.frontDelts: 'front',
    Muscle.sideDelts: 'side',
    Muscle.rearDelts: 'rear',
    Muscle.bicepsLongHead: 'mass',
    Muscle.bicepsShortHead: 'peak',
    Muscle.brachialis: 'brachialis',
    Muscle.brachioradialis: 'brachialis',
    Muscle.wristExtensors: 'forearms',
    Muscle.wristFlexors: 'forearms',
    Muscle.tricepsLongHead: 'overhead',
    Muscle.tricepsLateralHead: 'pushdown',
    Muscle.tricepsMedialHead: 'pushdown',
    Muscle.rectusFemoris: 'quads',
    Muscle.vastusLateralis: 'quads',
    Muscle.vastusMedialis: 'quads',
    Muscle.vastusIntermedius: 'quads',
    Muscle.bicepsFemoris: 'hams',
    Muscle.semitendinosus: 'hams',
    Muscle.semimembranosus: 'hams',
    Muscle.gluteusMaximus: 'glutes',
    Muscle.gluteusMedius: 'glutes',
    Muscle.gluteusMinimus: 'glutes',
    Muscle.gastrocnemius: 'calves',
    Muscle.soleus: 'calves',
    Muscle.rectusAbdominis: 'abs',
    Muscle.obliques: 'stability',
    Muscle.transverseAbdominis: 'stability',
  };

  static const Map<MuscleRegion, String> _regionSection = {
    // Quadriceps is deliberately absent: its exercises spread over 3 sections (quads / lunges / quad_iso), so a
    // region-level quad profile cannot be placed by derivation (curated only).
    MuscleRegion.hamstrings: 'hams',
    MuscleRegion.glutes: 'glutes',
    MuscleRegion.calves: 'calves',
    MuscleRegion.forearms: 'forearms',
  };

  static String mineSectionId(MuscleGroup m) => 'mine_${m.name}';

  /// [all] exercises whose primary muscle is [m], grouped by section in display order (empty sections omitted).
  /// Custom exercises go last in a "Your exercises" section.
  static List<({SplitSection section, List<Exercise> exercises})> grouped(
    MuscleGroup m,
    List<Exercise> all,
  ) {
    final mine = <Exercise>[];
    final bySection = <String, List<Exercise>>{};
    for (final e in all) {
      if (e.primaryMuscle != m) continue;
      if (e.isCustom) {
        mine.add(e);
      } else {
        bySection.putIfAbsent(sectionIdOf(e), () => []).add(e);
      }
    }
    int order(Exercise e) => _byExercise[e.id]?.order ?? 1 << 20;
    final out = <({SplitSection section, List<Exercise> exercises})>[];
    for (final s in sectionsFor(m)) {
      final list = bySection[s.id];
      if (list == null || list.isEmpty) continue;
      // Mapped order first; unmapped keep catalog order (index tiebreak, List.sort is not stable).
      final idx = {for (var i = 0; i < list.length; i++) list[i].id: i};
      list.sort((a, b) {
        final c = order(a).compareTo(order(b));
        return c != 0 ? c : idx[a.id]!.compareTo(idx[b.id]!);
      });
      out.add((section: s, exercises: list));
    }
    if (mine.isNotEmpty) {
      out.add((
        section: SplitSection(
          id: mineSectionId(m),
          label: 'Your exercises',
          muscle: m,
          hint: 'Exercises you created.',
        ),
        exercises: mine,
      ));
    }
    return out;
  }

  /// A short "why this one" line for a built-in exercise, or null. Curated lines win; other built-ins
  /// get a line derived from their muscle profile ("Trains lats; also biceps, upper back.").
  static String? reasonFor(String exerciseId) {
    final curated = _reasons[exerciseId];
    if (curated != null) return curated;
    final p = MuscleProfiles.builtIn(exerciseId);
    if (p == null) return null;
    String name(MuscleTarget t) =>
        (t.muscle?.label ?? t.region.label).toLowerCase();
    final prim = p.primary.map(name).toList();
    final sec = {
      for (final t in p.secondary)
        if (t.effectiveWeight >= 0.5) name(t),
    }.toList();
    return 'Trains ${prim.join(' and ')}${sec.isEmpty ? '' : '; also ${sec.join(', ')}'}.';
  }

  /// The recommended picks for [m] (a few exercises across its sections), as RoutineExercises, chosen by
  /// [ExerciseRecommender.forDay] for the muscle's regions so picks do not over-stack on one area. The
  /// hand-picked [_suggested] list only acts as a gentle preference. Only exercises present in [all]
  /// whose primary muscle is [m] are returned (2–4 when available).
  static List<RoutineExercise> suggest(MuscleGroup m, List<Exercise> all) {
    final pool = [
      for (final e in all)
        if (e.primaryMuscle == m) e,
    ];
    if (pool.isEmpty) return const [];
    final regions = [
      for (final r in MuscleRegion.values)
        if (r.legacy == m && r != MuscleRegion.forearms) r,
    ];
    final picks = ExerciseRecommender.forDay(
      regions: regions,
      catalog: pool,
      // 3 days/week => each muscle once per session: a full "menu" for the muscle.
      daysPerWeek: 3,
      maxExercises: 4,
      minExercises: 2,
      preferIds: [
        for (final r in _suggested[m] ?? const <RoutineExercise>[])
          r.exerciseId,
      ],
    );
    // The recommender returns compounds first in pick order; the user-facing list leads with the classic
    // lifts of [_suggested] (in their curated order), then the rest in recommender order.
    final classic = {
      for (var i = 0; i < (_suggested[m] ?? const []).length; i++)
        _suggested[m]![i].exerciseId: i,
    };
    final indexed = [for (var i = 0; i < picks.length; i++) (picks[i], i)];
    indexed.sort((a, b) {
      final ca = classic[a.$1.exerciseId] ?? 1 << 20;
      final cb = classic[b.$1.exerciseId] ?? 1 << 20;
      return ca != cb ? ca.compareTo(cb) : a.$2.compareTo(b.$2);
    });
    return [for (final p in indexed) p.$1];
  }
}
