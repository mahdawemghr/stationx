import '../models/models.dart';

/// A time span of one sleep stage, as read from the health store.
typedef StageSpan = ({DateTime from, DateTime to, SleepStage stage});

/// Pure helpers that turn raw health-store records into sleep and recovery values. Kept apart from
/// the plugin so they are unit-testable.
abstract final class HealthSummary {
  /// Total minutes covered by [intervals], merging overlaps (a phone and a watch can both record
  /// the same night).
  static int mergedMinutes(Iterable<({DateTime from, DateTime to})> intervals) {
    final list = intervals.where((i) => i.to.isAfter(i.from)).toList()
      ..sort((a, b) => a.from.compareTo(b.from));
    if (list.isEmpty) return 0;
    var total = Duration.zero;
    var curFrom = list.first.from;
    var curTo = list.first.to;
    for (final i in list.skip(1)) {
      if (i.from.isAfter(curTo)) {
        total += curTo.difference(curFrom);
        curFrom = i.from;
        curTo = i.to;
      } else if (i.to.isAfter(curTo)) {
        curTo = i.to;
      }
    }
    total += curTo.difference(curFrom);
    return total.inMinutes;
  }

  /// Window used to find "last night": 18:00 yesterday to 14:00 today.
  static ({DateTime from, DateTime to}) lastNightWindow(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return (
      from: today.subtract(const Duration(hours: 6)),
      to: today.add(const Duration(hours: 14)),
    );
  }

  /// The main night in [sessions] / [stages] (the longest session; short naps are ignored), or
  /// null when nothing was recorded. Stages are clipped to that session and overlapping
  /// recordings (phone + watch) are merged, so nothing is counted twice.
  static SleepNight? sleepNight({
    required Iterable<StageSpan> stages,
    required Iterable<({DateTime from, DateTime to})> sessions,
  }) {
    final merged = _mergeSpans(sessions);
    DateTime bed, wake;
    if (merged.isNotEmpty) {
      final main = merged.reduce(
        (a, b) => b.to.difference(b.from) > a.to.difference(a.from) ? b : a,
      );
      bed = main.from;
      wake = main.to;
    } else if (stages.isNotEmpty) {
      bed = stages.map((s) => s.from).reduce((a, b) => a.isBefore(b) ? a : b);
      wake = stages.map((s) => s.to).reduce((a, b) => a.isAfter(b) ? a : b);
    } else {
      return null;
    }
    final inBed = wake.difference(bed).inMinutes;
    if (inBed <= 0) return null;

    final byStage = <SleepStage, List<({DateTime from, DateTime to})>>{};
    for (final s in stages) {
      final from = s.from.isBefore(bed) ? bed : s.from;
      final to = s.to.isAfter(wake) ? wake : s.to;
      if (!to.isAfter(from)) continue;
      (byStage[s.stage] ??= []).add((from: from, to: to));
    }
    final minutes = <SleepStage, int>{
      for (final e in byStage.entries)
        if (mergedMinutes(e.value) > 0) e.key: mergedMinutes(e.value),
    };
    final asleepSpans = [
      for (final st in const [
        SleepStage.deep,
        SleepStage.light,
        SleepStage.rem,
        SleepStage.asleep,
      ])
        ...?byStage[st],
    ];
    final hasStages = asleepSpans.isNotEmpty;
    final asleep = hasStages
        ? mergedMinutes(asleepSpans)
        : (inBed - (minutes[SleepStage.awake] ?? 0)).clamp(0, inBed);
    if (asleep <= 0) return null;
    return SleepNight(
      bedtime: bed,
      wake: wake,
      stageMinutes: minutes,
      asleepMinutes: asleep.clamp(0, inBed),
      inBedMinutes: inBed,
    );
  }

  /// Total sleep per wake-up day, oldest first, at most [nights] days. Sessions that end on the
  /// same day add up.
  static List<NightSummary> nightHistory(
    Iterable<({DateTime from, DateTime to})> sessions, {
    int nights = 7,
  }) {
    final perDay = <DateTime, List<({DateTime from, DateTime to})>>{};
    for (final s in _mergeSpans(sessions)) {
      final day = DateTime(s.to.year, s.to.month, s.to.day);
      (perDay[day] ??= []).add(s);
    }
    final days = perDay.keys.toList()..sort();
    final last = days.length > nights
        ? days.sublist(days.length - nights)
        : days;
    return [
      for (final d in last)
        NightSummary(day: d, minutes: mergedMinutes(perDay[d]!)),
    ];
  }

  /// The longest sleep session ending on each day, newest first, at most [nights] days.
  static List<({DateTime day, DateTime from, DateTime to})> mainSessionPerDay(
    Iterable<({DateTime from, DateTime to})> sessions, {
    int nights = 7,
  }) {
    final best = <DateTime, ({DateTime from, DateTime to})>{};
    for (final s in _mergeSpans(sessions)) {
      final day = DateTime(s.to.year, s.to.month, s.to.day);
      final cur = best[day];
      if (cur == null ||
          s.to.difference(s.from) > cur.to.difference(cur.from)) {
        best[day] = s;
      }
    }
    final days = best.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final d in days.take(nights))
        (day: d, from: best[d]!.from, to: best[d]!.to),
    ];
  }

  /// Resting heart rate estimated from the samples recorded while asleep: the average of the
  /// lowest ~15% (at least 3), which is the quiet floor of the night. Null with fewer than 8
  /// plausible samples inside [from, to].
  static int? restingFromSleepHr(
    Iterable<({DateTime at, double bpm})> samples, {
    required DateTime from,
    required DateTime to,
  }) {
    final v = [
      for (final p in samples)
        if (!p.at.isBefore(from) &&
            p.at.isBefore(to) &&
            p.bpm > 30 &&
            p.bpm < 220)
          p.bpm,
    ]..sort();
    if (v.length < 8) return null;
    final take = (v.length * 0.15).ceil().clamp(3, v.length);
    final low = v.take(take);
    return (low.reduce((a, b) => a + b) / take).round();
  }

  static List<({DateTime from, DateTime to})> _mergeSpans(
    Iterable<({DateTime from, DateTime to})> spans,
  ) {
    final list = spans.where((i) => i.to.isAfter(i.from)).toList()
      ..sort((a, b) => a.from.compareTo(b.from));
    final out = <({DateTime from, DateTime to})>[];
    for (final s in list) {
      if (out.isNotEmpty && !s.from.isAfter(out.last.to)) {
        if (s.to.isAfter(out.last.to)) {
          out[out.length - 1] = (from: out.last.from, to: s.to);
        }
      } else {
        out.add(s);
      }
    }
    return out;
  }

  /// Latest and average resting heart rate from timestamped bpm values.
  static ({int? latest, int? average}) restingHr(
    Iterable<({DateTime at, double bpm})> points,
  ) {
    final valid = points.where((p) => p.bpm > 20 && p.bpm < 220).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    if (valid.isEmpty) return (latest: null, average: null);
    final avg = valid.fold(0.0, (a, p) => a + p.bpm) / valid.length;
    return (latest: valid.last.bpm.round(), average: avg.round());
  }
}
