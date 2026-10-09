import '../models/models.dart';
import 'muscle_profiles.dart';

enum CoverageLevel { none, low, moderate, high }

/// Weekly weighted-set thresholds for [CoverageLevel]. PRACTICAL GUIDELINES for a UI hint, not scientific
/// claims. A value `v` (weighted sets per week) is: none when `v <= 0`, low when `v < moderate`, moderate when
/// `v < high`, otherwise high. Leaves use lower numbers because a region's volume is split over its leaves.
abstract final class CoverageThresholds {
  static const double regionModerate = 4;
  static const double regionHigh = 10;
  static const double muscleModerate = 2;
  static const double muscleHigh = 5;

  static CoverageLevel level(
    double perWeek, {
    required double moderate,
    required double high,
  }) {
    if (perWeek <= 0) return CoverageLevel.none;
    if (perWeek < moderate) return CoverageLevel.low;
    if (perWeek < high) return CoverageLevel.moderate;
    return CoverageLevel.high;
  }
}

/// How much each muscle was trained. "direct" counts only PRIMARY targets (1 set = 1); "weighted" also adds
/// secondary contributions (× target weight). Region-level targets (no subdivision) count toward the region
/// only. Numbers are working sets over the measured period ([weeks]); levels are judged per week on WEIGHTED sets.
///
/// Per set and per region an exercise counts once: the MAX weight among its targets in that region (so an
/// exercise with two primary back leaves adds 1 to Back, not 2). Leaves are counted individually.
class CoverageReport {
  const CoverageReport({
    this.directByMuscle = const {},
    this.weightedByMuscle = const {},
    this.directByRegion = const {},
    this.weightedByRegion = const {},
    this.weeks = 1,
  });
  final Map<Muscle, double> directByMuscle;
  final Map<Muscle, double> weightedByMuscle;
  final Map<MuscleRegion, double> directByRegion;
  final Map<MuscleRegion, double> weightedByRegion;

  /// Length of the measured period in weeks (levels are judged per week).
  final double weeks;

  double get _w => weeks <= 0 ? 1 : weeks;

  CoverageLevel levelOfRegion(MuscleRegion r) => CoverageThresholds.level(
    (weightedByRegion[r] ?? 0) / _w,
    moderate: CoverageThresholds.regionModerate,
    high: CoverageThresholds.regionHigh,
  );

  CoverageLevel levelOfMuscle(Muscle m) => CoverageThresholds.level(
    (weightedByMuscle[m] ?? 0) / _w,
    moderate: CoverageThresholds.muscleModerate,
    high: CoverageThresholds.muscleHigh,
  );
}

abstract final class MuscleCoverage {
  /// Coverage of arbitrary (exercise, sets) slots. Totals are raw over the period; [weeks] only drives levels.
  static CoverageReport ofSlots(
    Iterable<(Exercise, int)> slots, {
    double weeks = 1,
  }) {
    final dm = <Muscle, double>{}, wm = <Muscle, double>{};
    final dr = <MuscleRegion, double>{}, wr = <MuscleRegion, double>{};
    for (final (ex, sets) in slots) {
      if (sets <= 0) continue;
      final targets = MuscleProfiles.of(ex).targets;
      final regionDirect = <MuscleRegion, double>{},
          regionWeighted = <MuscleRegion, double>{};
      for (final t in targets) {
        final w = t.effectiveWeight;
        final primary = t.role == TargetRole.primary;
        if (t.muscle != null) {
          wm[t.muscle!] = (wm[t.muscle!] ?? 0) + sets * w;
          if (primary) dm[t.muscle!] = (dm[t.muscle!] ?? 0) + sets * 1.0;
        }
        if ((regionWeighted[t.region] ?? 0) < w) regionWeighted[t.region] = w;
        if (primary) regionDirect[t.region] = 1.0;
      }
      regionWeighted.forEach((r, w) => wr[r] = (wr[r] ?? 0) + sets * w);
      regionDirect.forEach((r, w) => dr[r] = (dr[r] ?? 0) + sets * w);
    }
    return CoverageReport(
      directByMuscle: dm,
      weightedByMuscle: wm,
      directByRegion: dr,
      weightedByRegion: wr,
      weeks: weeks,
    );
  }

  static Iterable<(Exercise, int)> _workoutSlots(
    Workout w,
    Map<String, Exercise> byId,
  ) sync* {
    for (final re in w.exercises) {
      final ex = byId[re.exerciseId];
      if (ex != null) yield (ex, re.sets);
    }
  }

  /// One workout day.
  static CoverageReport ofWorkout(Workout w, List<Exercise> catalog) =>
      ofSlots(_workoutSlots(w, {for (final e in catalog) e.id: e}));

  /// A whole program (rotation), expressed per week for [daysPerWeek] sessions of the rotation in order
  /// (cycling when daysPerWeek > rotation length). weeks == 1.
  static CoverageReport ofProgram(
    List<Workout> rotation,
    List<Exercise> catalog, {
    int daysPerWeek = 4,
  }) {
    if (rotation.isEmpty || daysPerWeek <= 0) return const CoverageReport();
    final byId = {for (final e in catalog) e.id: e};
    return ofSlots([
      for (var i = 0; i < daysPerWeek; i++)
        ..._workoutSlots(rotation[i % rotation.length], byId),
    ]);
  }

  /// Logged history between [from] (inclusive) and [to] (exclusive); only done sets count.
  static CoverageReport ofHistory(
    Iterable<WorkoutSession> sessions,
    List<Exercise> catalog, {
    required DateTime from,
    required DateTime to,
  }) {
    final byId = {for (final e in catalog) e.id: e};
    final slots = <(Exercise, int)>[];
    for (final s in sessions) {
      if (s.workoutDate.isBefore(from) || !s.workoutDate.isBefore(to)) continue;
      for (final log in s.exercises) {
        final ex = byId[log.exerciseId];
        if (ex != null) slots.add((ex, log.doneSets.length));
      }
    }
    final weeks =
        to.difference(from).inMilliseconds / Duration.millisecondsPerDay / 7;
    return ofSlots(slots, weeks: weeks < 1e-6 ? 1e-6 : weeks);
  }
}
