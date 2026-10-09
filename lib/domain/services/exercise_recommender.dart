import '../models/models.dart';
import 'muscle_coverage.dart';
import 'muscle_profiles.dart';
import 'smart_swap_service.dart';

/// A muscle area that looks under-trained. INFORMATIONAL only — never an instruction to add volume.
class CoverageGap {
  const CoverageGap({
    required this.region,
    this.muscle,
    required this.level,
    required this.note,
  });
  final MuscleRegion region;
  final Muscle? muscle;
  final CoverageLevel level;
  final String note;
}

/// One reusable recommendation engine (workout generation, schedule generation, replacement, gap hints).
/// Screens never rank or score exercises themselves. PURE DART, deterministic (ties → catalog order).
///
/// Contribution maths reuses [MuscleWeights] / [MuscleTarget.effectiveWeight] (primary 1.0, secondary 0.5).
/// The engine keeps its own tiny running tally while building a day (cheaper and independent of
/// [MuscleCoverage]'s reporting API); the numbers are the same working-set maths.
abstract final class ExerciseRecommender {
  // ── Tunables (documented; one place) ──────────────────────────────────────────────────────────────────

  /// Reasonable weekly weighted working sets per region (direct + 0.5×secondary). A day's target is this
  /// divided by how often the region is trained per week ([frequencyPerWeek]).
  static const Map<MuscleRegion, int> weeklyTargetSets = {
    MuscleRegion.chest: 12,
    MuscleRegion.back: 14,
    MuscleRegion.shoulders: 10,
    MuscleRegion.biceps: 8,
    MuscleRegion.triceps: 8,
    MuscleRegion.forearms: 3,
    MuscleRegion.quadriceps: 12,
    MuscleRegion.hamstrings: 8,
    MuscleRegion.glutes: 8,
    MuscleRegion.calves: 8,
    MuscleRegion.core: 6,
  };

  /// How many times per week a region of a day covering [regionCount] regions is trained, estimated from
  /// [daysPerWeek]. Full-body-ish days (≥4 regions) repeat about every other day; focused days about every
  /// third day. Clamped to 1..3. More days per week ⇒ higher frequency ⇒ fewer sets per muscle per day.
  static int frequencyPerWeek(int daysPerWeek, int regionCount) {
    final d = daysPerWeek < 1 ? 1 : daysPerWeek;
    final f = regionCount >= 4 ? (d / 2).ceil() : (d / 3).ceil();
    return f.clamp(1, 3);
  }

  /// Weighted working sets that make [region] "adequate" within one day.
  static int dayTargetSets(
    MuscleRegion region, {
    int daysPerWeek = 4,
    int regionCount = 1,
  }) {
    final weekly = weeklyTargetSets[region] ?? 8;
    final t = (weekly / frequencyPerWeek(daysPerWeek, regionCount)).round();
    return t < 3 ? 3 : t;
  }

  static const _isolationPatterns = {
    'curl',
    'extension',
    'fly',
    'raise',
    'rear delt',
    'shrug',
    'crunch',
    'rotation',
    'isometric',
    'overhead extension',
    'flexion',
    'kickback',
  };

  /// Compound = not an isolation movement pattern AND meaningfully trains ≥2 regions (targets with weight
  /// ≥ 0.5, so stabiliser-only core work does not count). Everything else is isolation. Used for the
  /// "similar training purpose" tier, compound-before-isolation ordering and rep ranges.
  static bool isCompound(Exercise e, [ExerciseMuscleProfile? profile]) {
    if (_isolationPatterns.contains(e.movementPattern.toLowerCase())) {
      return false;
    }
    final p = profile ?? MuscleProfiles.of(e);
    final regions = {
      for (final t in p.targets)
        if (t.effectiveWeight >= 0.5) t.region,
    };
    return regions.length >= 2;
  }

  /// Per-region contribution of ONE set: the highest target weight in that region (an exercise with two
  /// primary leaves in one region still trains the region once per set).
  static Map<MuscleRegion, double> _regionWeights(ExerciseMuscleProfile p) {
    final out = <MuscleRegion, double>{};
    for (final t in p.targets) {
      final w = t.effectiveWeight;
      if (w > (out[t.region] ?? 0)) out[t.region] = w;
    }
    return out;
  }

  // ── Replacements ──────────────────────────────────────────────────────────────────────────────────────

  /// Ranked replacements for [current]. Score (max 100):
  ///  * 50 muscle match — same leaf 1.0, same region (one side region-level) 0.8, different leaf in the same
  ///    region 0.55, other region of the same broad group 0.15 (kept only so the legacy broad-muscle
  ///    behaviour of SmartSwap still lists them, at the bottom); other broad groups are excluded.
  ///  * 18 same movement pattern + 12 secondary-muscle overlap weighted by [MuscleTarget.effectiveWeight]
  ///  * 10 same training purpose (compound/isolation; 3 when different)
  ///  * 5 same equipment · 5 the user has logged this exercise before ("history", minor)
  /// [allowedEquipment] null = all. [excludeIds] (e.g. exercises already in the workout) are skipped.
  static List<SwapCandidate> replacements({
    required Exercise current,
    required List<Exercise> catalog,
    Iterable<WorkoutSession> history = const [],
    Set<Equipment>? allowedEquipment,
    Set<String> excludeIds = const {},
  }) {
    final cur = MuscleProfiles.of(current);
    final curCompound = isCompound(current, cur);
    final done = _doneIds(history);
    final scored = <(SwapCandidate, int, bool)>[];
    for (var i = 0; i < catalog.length; i++) {
      final e = catalog[i];
      if (e.id == current.id || excludeIds.contains(e.id)) continue;
      if (allowedEquipment != null && !allowedEquipment.contains(e.equipment)) {
        continue;
      }
      final p = MuscleProfiles.of(e);
      final m = _primaryMatch(cur, p);
      if (m.score <= 0) continue;
      var score = 50 * m.score;
      final samePattern =
          e.movementPattern.isNotEmpty &&
          e.movementPattern == current.movementPattern;
      if (samePattern) score += 18;
      final overlap = _secondaryOverlap(cur, p);
      score += 12 * overlap;
      score += isCompound(e, p) == curCompound ? 10 : 3;
      if (e.equipment == current.equipment) score += 5;
      final familiar = done.contains(e.id);
      if (familiar) score += 5;
      final parts = <String>[
        m.label ?? p.lead.muscle?.label ?? p.primaryRegion.label,
        samePattern ? e.movementPattern.toLowerCase() : 'different movement',
        if (overlap >= 0.6) 'similar assisting muscles',
        if (familiar) "you've done this before",
      ];
      scored.add((
        SwapCandidate(
          exercise: e,
          matchPercent: score.round().clamp(0, 100),
          reason: parts.join(' • '),
        ),
        i,
        familiar,
      ));
    }
    // Deterministic: higher match first; on equal match the exercise the user has done before wins, then
    // catalogue order (so adding new equal-profile exercises never reshuffles familiar ones).
    scored.sort((a, b) {
      final c = b.$1.matchPercent.compareTo(a.$1.matchPercent);
      if (c != 0) return c;
      if (a.$3 != b.$3) return a.$3 ? -1 : 1;
      return a.$2.compareTo(b.$2);
    });
    return [for (final s in scored) s.$1];
  }

  static Set<String> _doneIds(Iterable<WorkoutSession> history) => {
    for (final s in history)
      for (final l in s.exercises)
        if (l.doneSets.isNotEmpty) l.exerciseId,
  };

  /// Best-aligned primary targets of [a] against [b]: average over a's primaries of the best pair score.
  static ({double score, String? label}) _primaryMatch(
    ExerciseMuscleProfile a,
    ExerciseMuscleProfile b,
  ) {
    final ap = a.primary.toList(), bp = b.primary.toList();
    if (ap.isEmpty || bp.isEmpty) return (score: 0, label: null);
    var sum = 0.0;
    String? label;
    var bestSeen = -1.0;
    for (final x in ap) {
      var best = 0.0;
      MuscleTarget? bestT;
      for (final y in bp) {
        final s = _pair(x, y);
        if (s > best) {
          best = s;
          bestT = y;
        }
      }
      sum += best;
      if (best > bestSeen && bestT != null) {
        bestSeen = best;
        label = bestT.muscle?.label ?? bestT.region.label;
      }
    }
    return (score: sum / ap.length, label: label);
  }

  static double _pair(MuscleTarget x, MuscleTarget y) {
    if (x.region == y.region) {
      if (x.muscle == null && y.muscle == null) return 1.0;
      if (x.muscle == null || y.muscle == null) return 0.8;
      return x.muscle == y.muscle ? 1.0 : 0.55;
    }
    return x.region.legacy == y.region.legacy ? 0.15 : 0.0;
  }

  /// 0..1: how much of a's secondary work (weighted) b also provides. No secondaries on a: b without any
  /// also scores 1, otherwise 0.5.
  static double _secondaryOverlap(
    ExerciseMuscleProfile a,
    ExerciseMuscleProfile b,
  ) {
    final sec = a.secondary.toList();
    if (sec.isEmpty) return b.secondary.isEmpty ? 1.0 : 0.5;
    var total = 0.0, got = 0.0;
    for (final s in sec) {
      total += s.effectiveWeight;
      var best = 0.0;
      for (final t in b.targets) {
        final v = t.region != s.region
            ? 0.0
            : (s.muscle == null || t.muscle == null)
            ? 0.7
            : (s.muscle == t.muscle ? 1.0 : 0.4);
        if (v > best) best = v;
      }
      got += s.effectiveWeight * best;
    }
    return total == 0 ? 0 : got / total;
  }

  // ── Subgroup coverage ─────────────────────────────────────────────────────────────────────────────────

  /// Leaves a region should get DIRECT (primary) work from before [forDay] considers it covered, even
  /// when its weighted set count is already adequate. Each inner set is one requirement satisfied by ANY
  /// of its members (back: lats, upper back, and traps OR lower back). Regions not listed (and leaves no
  /// catalog exercise trains as a primary) impose no requirement. Small, extensible data table.
  static const Map<MuscleRegion, List<Set<Muscle>>> requiredLeaves = {
    MuscleRegion.chest: [
      {Muscle.upperChest},
      {Muscle.midChest},
      {Muscle.lowerChest},
    ],
    MuscleRegion.back: [
      {Muscle.lats},
      {Muscle.upperBack},
      {Muscle.traps, Muscle.lowerBack},
    ],
    MuscleRegion.shoulders: [
      {Muscle.sideDelts},
      {Muscle.rearDelts},
    ],
  };

  /// Heavy multi-region hinges (deadlift-type): primary work in 2+ regions with a hinge pattern. They are
  /// not used as a leaf filler (e.g. for lower back) while a simpler exercise can fill that leaf.
  static bool _isHeavyHinge(Exercise e, ExerciseMuscleProfile p) =>
      e.movementPattern.toLowerCase() == 'hinge' &&
      {for (final t in p.primary) t.region}.length >= 2;

  // ── Day building ──────────────────────────────────────────────────────────────────────────────────────

  /// Picks up to [maxExercises] NEW exercises (not in [existing]) for a day that trains [regions], without
  /// blindly stacking exercises on muscles that the running selection (incl. [existing]) already covers:
  ///  * a region is "adequate" once its weighted sets reach [dayTargetSets] (secondary work from other
  ///    picks counts, so a pressing day needs fewer extra triceps sets) → no more exercises for it;
  ///  * candidates score on not-yet-covered leaves/regions, deficit size, compound-before-isolation, history
  ///    familiarity, equipment variety and the optional [preferIds] order (a gentle tie-break for curated
  ///    starting points);
  ///  * [minExercises] forces at least that many picks (when candidates exist) even if adequate.
  /// Compounds come first in the result; sets/reps: compound 3–4 × 6–10, isolation 3 × 10–15, time-based
  /// holds 3 × 30–60 s. Fewer [daysPerWeek] ⇒ higher per-day targets (see [frequencyPerWeek]).
  static List<RoutineExercise> forDay({
    required List<MuscleRegion> regions,
    required List<Exercise> catalog,
    List<RoutineExercise> existing = const [],
    Iterable<WorkoutSession> history = const [],
    Set<Equipment>? allowedEquipment,
    int daysPerWeek = 4,
    int maxExercises = 6,
    int minExercises = 0,
    List<String> preferIds = const [],
  }) {
    if (regions.isEmpty || maxExercises <= 0) return const [];
    final byId = {for (final e in catalog) e.id: e};
    final target = {
      for (final r in regions)
        r: dayTargetSets(
          r,
          daysPerWeek: daysPerWeek,
          regionCount: regions.length,
        ),
    };
    final acc = _Tally();
    final usedIds = <String>{};
    final usedEquipment = <Equipment>{};
    for (final r in existing) {
      usedIds.add(r.exerciseId);
      final e = byId[r.exerciseId];
      if (e == null) continue;
      acc.add(MuscleProfiles.of(e), r.sets);
      usedEquipment.add(e.equipment);
    }
    final done = _doneIds(history);
    final prefer = {for (var i = 0; i < preferIds.length; i++) preferIds[i]: i};

    final pool = <_Cand>[];
    for (var i = 0; i < catalog.length; i++) {
      final e = catalog[i];
      if (usedIds.contains(e.id)) continue;
      if (allowedEquipment != null && !allowedEquipment.contains(e.equipment)) {
        continue;
      }
      final p = MuscleProfiles.of(e);
      if (!p.primary.any((t) => regions.contains(t.region))) continue;
      pool.add(_Cand(e, p, i, isCompound(e, p), _isHeavyHinge(e, p)));
    }

    final picked = <(RoutineExercise, bool)>[];
    while (picked.length < maxExercises && pool.isNotEmpty) {
      double deficit(MuscleRegion r) => (target[r] ?? 0) - acc.region(r);
      final deficitOpen = {
        for (final r in regions)
          if (deficit(r) >= 1.0) r,
      };
      // Unmet leaf requirements that at least one remaining candidate can fill (no fake precision: a
      // leaf nothing in the catalog trains directly is simply skipped).
      final unmet = <(MuscleRegion, Set<Muscle>)>[];
      for (final r in regions) {
        for (final group in requiredLeaves[r] ?? const <Set<Muscle>>[]) {
          if (group.any((m) => acc.leafDirect(m) > 0)) continue;
          if (pool.any((c) => _fills(c, group))) unmet.add((r, group));
        }
      }
      // A heavy hinge only fills a group when no other candidate can.
      bool fillsAllowed(_Cand c, Set<Muscle> g) =>
          _fills(c, g) &&
          (!c.heavyHinge || !pool.any((o) => !o.heavyHinge && _fills(o, g)));
      final open = {...deficitOpen, for (final u in unmet) u.$1};
      final forced = picked.length < minExercises;
      if (open.isEmpty && !forced) break;
      _Cand? best;
      var bestScore = 0.0;
      for (final c in pool) {
        final fillsUnmet = unmet.any((u) => fillsAllowed(c, u.$2));
        if (!forced &&
            !fillsUnmet &&
            !c.profile.primary.any((t) => deficitOpen.contains(t.region))) {
          continue;
        }
        var s = 0.0;
        if (fillsUnmet) s += 3.0; // above any repeat of an already-covered leaf
        var novel = 0.0;
        for (final e in _regionWeights(c.profile).entries) {
          if (!regions.contains(e.key)) continue;
          final frac =
              ((target[e.key] ?? 0) - acc.region(e.key)).clamp(0, 99) /
              (target[e.key] ?? 1);
          s += e.value * frac * 2;
        }
        for (final t in c.profile.primary) {
          if (t.muscle == null || !regions.contains(t.region)) continue;
          // Uncovered leaf is worth more, repeats less. Novelty is capped so exercises that merely list
          // many leaves do not beat a clearly useful one.
          if (acc.leafDirect(t.muscle!) == 0) {
            novel += 1.5;
          } else {
            s -= 1.0;
          }
        }
        s += novel > 2.0 ? 2.0 : novel;
        if (c.compound) s += 1.0;
        if (done.contains(c.exercise.id)) s += 0.4;
        if (!usedEquipment.contains(c.exercise.equipment)) s += 0.2;
        final pi = prefer[c.exercise.id];
        if (pi != null) s += 0.8 - 0.05 * pi.clamp(0, 10);
        if (best == null || s > bestScore + 1e-9) {
          best = c;
          bestScore = s;
        }
      }
      if (best == null || (bestScore <= 0 && !forced)) break;
      pool.remove(best);
      final e = best.exercise;
      final timed = e.movementPattern.toLowerCase() == 'isometric';
      final leadOpen = best.profile.primary
          .map((t) => deficit(t.region))
          .fold(0.0, (a, b) => a > b ? a : b);
      final base = best.compound ? (picked.any((p) => p.$2) ? 3 : 4) : 3;
      final sets = leadOpen <= 0 ? 3 : leadOpen.ceil().clamp(2, base);
      acc.add(best.profile, sets);
      usedEquipment.add(e.equipment);
      picked.add((
        RoutineExercise(
          exerciseId: e.id,
          sets: sets,
          repMin: timed ? 30 : (best.compound ? 6 : 10),
          repMax: timed ? 60 : (best.compound ? 10 : 15),
        ),
        best.compound,
      ));
    }
    // Compounds first, otherwise in pick order (stable).
    return [
      for (final p in picked)
        if (p.$2) p.$1,
      for (final p in picked)
        if (!p.$2) p.$1,
    ];
  }

  // ── Gaps ──────────────────────────────────────────────────────────────────────────────────────────────

  /// Leaves worth a gentle mention when their region IS trained but they get almost nothing.
  static const _notableLeaves = [
    Muscle.upperChest,
    Muscle.lats,
    Muscle.upperBack,
    Muscle.sideDelts,
    Muscle.rearDelts,
    Muscle.bicepsLongHead,
    Muscle.tricepsLongHead,
    Muscle.gluteusMaximus,
  ];

  /// Under-trained areas of [report] given the program context. INFORMATIONAL: it never says a muscle
  /// "needs" volume and never adds anything by itself. Rules (per week = report value / report.weeks):
  ///  * a region is a gap when direct < 40 % and weighted < 50 % of its [weeklyTargetSets];
  ///  * thresholds shrink ×0.75 for programs of ≤3 days/week (less frequency, naturally less volume);
  ///  * a notable leaf (e.g. rear delts) is mentioned only when its region is fine, the region has leaf
  ///    detail, and the leaf's weighted sets < 2/week;
  ///  * forearms are never flagged (trained indirectly); an empty report yields no gaps.
  static List<CoverageGap> gaps(CoverageReport report, {int daysPerWeek = 4}) {
    final w = report.weeks <= 0 ? 1.0 : report.weeks;
    if (!report.weightedByRegion.values.any((v) => v > 0)) return const [];
    final scale = daysPerWeek <= 3 ? 0.75 : 1.0;
    final out = <CoverageGap>[];
    final flagged = <MuscleRegion>{};
    for (final r in MuscleRegion.values) {
      if (r == MuscleRegion.forearms) continue;
      final weekly = (weeklyTargetSets[r] ?? 8) * scale;
      final direct = (report.directByRegion[r] ?? 0) / w;
      final weighted = (report.weightedByRegion[r] ?? 0) / w;
      if (direct >= 0.4 * weekly || weighted >= 0.5 * weekly) continue;
      flagged.add(r);
      final lower = r.label.toLowerCase();
      out.add(
        CoverageGap(
          region: r,
          level: weighted <= 0 ? CoverageLevel.none : CoverageLevel.low,
          note: weighted <= 0
              ? 'No $lower work in this program — optional to add.'
              : direct <= 0
              ? '${r.label} only get indirect work in this program — optional to add direct sets.'
              : '${r.label} ${_verb(r.label)} little direct work in this program — optional to add.',
        ),
      );
    }
    for (final m in _notableLeaves) {
      final r = m.region;
      if (flagged.contains(r)) continue;
      final hasLeafDetail = report.directByMuscle.entries.any(
        (e) => e.key.region == r && e.value > 0,
      );
      if (!hasLeafDetail) continue;
      final weighted = (report.weightedByMuscle[m] ?? 0) / w;
      if (weighted >= 2 * scale) continue;
      out.add(
        CoverageGap(
          region: r,
          muscle: m,
          level: weighted <= 0 ? CoverageLevel.none : CoverageLevel.low,
          note:
              '${m.label} ${_verb(m.label)} little direct work in this program — optional to add.',
        ),
      );
    }
    return out;
  }

  static String _verb(String label) =>
      label.toLowerCase().endsWith('s') ? 'get' : 'gets';
}

class _Cand {
  _Cand(
    this.exercise,
    this.profile,
    this.index,
    this.compound,
    this.heavyHinge,
  );
  final Exercise exercise;
  final ExerciseMuscleProfile profile;
  final int index;
  final bool compound;
  final bool heavyHinge;
}

/// True when [c] has direct (primary) work on any leaf of [group].
bool _fills(_Cand c, Set<Muscle> group) =>
    c.profile.primary.any((t) => t.muscle != null && group.contains(t.muscle));

/// Running working-set tally for the day being built (same weights as [MuscleCoverage]).
class _Tally {
  final Map<MuscleRegion, double> _region = {};
  final Map<Muscle, double> _leafDirect = {};

  double region(MuscleRegion r) => _region[r] ?? 0;
  double leafDirect(Muscle m) => _leafDirect[m] ?? 0;

  void add(ExerciseMuscleProfile p, int sets) {
    for (final e in ExerciseRecommender._regionWeights(p).entries) {
      _region[e.key] = region(e.key) + e.value * sets;
    }
    for (final t in p.targets) {
      if (t.role == TargetRole.primary && t.muscle != null) {
        _leafDirect[t.muscle!] = leafDirect(t.muscle!) + sets;
      }
    }
  }
}
