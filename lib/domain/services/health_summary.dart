import '../models/models.dart';

/// Pure helpers that turn raw Health Connect records into [HealthSnapshot]
/// values. Kept separate from the plugin so they can be unit-tested.
abstract final class HealthSummary {
  /// Total minutes covered by [intervals], merging overlaps (several sources —
  /// phone + watch — can record the same night).
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

  /// Window used to find "last night": from 18:00 yesterday to 14:00 today.
  static ({DateTime from, DateTime to}) lastNightWindow(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return (
      from: today.subtract(const Duration(hours: 6)),
      to: today.add(const Duration(hours: 14)),
    );
  }

  /// Sleep minutes from stage data (preferred) or whole-session records.
  /// Returns null when neither contains anything.
  static int? sleepMinutes({
    required Iterable<({DateTime from, DateTime to})> asleep,
    required Iterable<({DateTime from, DateTime to})> sessions,
  }) {
    final a = mergedMinutes(asleep);
    if (a > 0) return a;
    final s = mergedMinutes(sessions);
    return s > 0 ? s : null;
  }

  /// Latest and 7-day-average resting heart rate from timestamped bpm values.
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
