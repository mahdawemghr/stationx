import '../models/models.dart';

/// Conservative double-progression engine. The UI only consumes
/// [ProgressionRecommendation]; all math lives here.
///
/// Principles: never be confident on thin history, never recommend a number for
/// bodyweight/timed work or a 0 load, never let one outlier set dictate the
/// weight, and never ask for more reps than last time + 1.
abstract final class ProgressionService {
  /// Need at least this many done sets in the last session...
  static const minDoneSets = 2;

  /// ...and this many sessions that logged the exercise.
  static const minSessions = 2;

  /// Older than this: don't extrapolate, just restart from the last weight.
  static const staleAfterDays = 21;

  static const _lbPerKg = 2.2046226218;

  /// Returns null when there is not enough trustworthy data (the UI then shows
  /// last performance only). [increment] is in DISPLAY units ([unit]), see [incrementFor].
  static ProgressionRecommendation? recommend({
    required List<SetLog> lastSets,
    required int repMin,
    required int repMax,
    required double increment,
    WeightUnit unit = WeightUnit.kg,
    int priorSessions = 2,
    DateTime? lastSessionDate,
    DateTime? now,
    Exercise? exercise,
  }) {
    if (exercise != null && !isLoadTracked(exercise)) return null;
    final done = lastSets
        .where((s) => s.done && s.reps > 0 && s.weightKg > 0)
        .toList();
    if (done.length < minDoneSets || priorSessions < minSessions) return null;

    final w = _workingWeight(done, repMin);
    final atW = done.where((s) => s.weightKg == w).toList();
    final best = atW.map((s) => s.reps).reduce((a, b) => a > b ? a : b);
    final u = unit == WeightUnit.kg ? 'kg' : 'lb';
    final wDisp = _fmt(_toDisplay(w, unit));

    final last = lastSessionDate;
    if (last != null &&
        (now ?? DateTime.now()).difference(last).inDays > staleAfterDays) {
      final weeks = ((now ?? DateTime.now()).difference(last).inDays / 7)
          .round();
      return ProgressionRecommendation(
        weightKg: w,
        repMin: repMin,
        repMax: repMax,
        reason: 'It has been about $weeks weeks. Start again from $wDisp $u.',
      );
    }

    final hitAll = atW.length >= 2 && atW.every((s) => s.reps >= repMax);
    if (hitAll) {
      final next = _round(_toDisplay(w, unit)) + increment;
      return ProgressionRecommendation(
        weightKg: _fromDisplay(next, unit),
        repMin: repMin,
        repMax: repMax,
        isIncrease: true,
        reason: 'You reached $repMax reps on every set at $wDisp $u.',
      );
    }
    return ProgressionRecommendation(
      weightKg: w,
      repMin: (best + 1).clamp(1, repMax),
      repMax: repMax,
      reason: 'Keep $wDisp $u and add a rep. Best last time was $best.',
    );
  }

  /// The weight that represents "what the lifter actually works with": the heaviest
  /// weight that has 2+ sets or reached [repMin] reps; otherwise the most common weight
  /// (ties: heavier). A lone heavy single never dictates.
  static double _workingWeight(List<SetLog> done, int repMin) {
    final byWeight = <double, List<SetLog>>{};
    for (final s in done) {
      byWeight.putIfAbsent(s.weightKg, () => []).add(s);
    }
    final weights = byWeight.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final w in weights) {
      final sets = byWeight[w]!;
      if (sets.length >= 2 || sets.any((s) => s.reps >= repMin)) return w;
    }
    weights.sort((a, b) {
      final c = byWeight[b]!.length.compareTo(byWeight[a]!.length);
      return c != 0 ? c : b.compareTo(a);
    });
    return weights.first;
  }

  /// False for bodyweight, isometric and timed work: a kg/lb number is meaningless there.
  static bool isLoadTracked(Exercise e) {
    if (e.equipment.isUnloaded) return false;
    return !_timed.hasMatch('${e.name} ${e.movementPattern}'.toLowerCase());
  }

  static final _timed = RegExp(
    r'plank|isometric|\bhold\b|wall sit|dead hang|l-sit|\bhang\b|carry',
  );
  static final _smallIsolation = RegExp(
    r'lateral raise|front raise|rear delt|reverse fly|reverse flye|\bfly\b|\bflye\b|curl|kickback|face pull|pushdown|triceps extension|wrist',
  );

  /// Smallest sensible jump in DISPLAY units. kg: 5 for barbell compounds, 2.5 for
  /// machines/cables/dumbbell compounds, 1 for small dumbbell isolation, 2.5 for other
  /// small isolation. lb: 5 for compounds, 2.5 for small isolation (never 5.5).
  static double incrementFor(Exercise e, [WeightUnit unit = WeightUnit.kg]) {
    final small = _smallIsolation.hasMatch(e.name.toLowerCase());
    if (unit == WeightUnit.lb) {
      return small ? 2.5 : 5;
    }
    if (small) return e.equipment == Equipment.dumbbell ? 1 : 2.5;
    if (e.equipment == Equipment.kettlebell) return 2; // KBs come in 2 kg steps
    return e.equipment == Equipment.barbell ? 5 : 2.5;
  }

  static double _toDisplay(double kg, WeightUnit u) =>
      u == WeightUnit.kg ? kg : kg * _lbPerKg;
  static double _fromDisplay(double v, WeightUnit u) =>
      u == WeightUnit.kg ? v : v / _lbPerKg;
  static double _round(double v) => (v * 2).round() / 2;

  static String _fmt(double v) {
    final r = _round(v);
    return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(1);
  }
}
