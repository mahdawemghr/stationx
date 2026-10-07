import '../../domain/domain.dart';

/// Time window selector shared by the strength and cardio progress views.
/// Windows filter on `workoutDate` (never `createdAt`).
enum ProgressPeriod {
  week('This week', 'THIS WEEK'),
  month('This month', 'MONTH'),
  threeMonths('3 months', '3 MONTHS'),
  year('Year', 'YEAR'),
  all('All time', 'ALL TIME');

  const ProgressPeriod(this.label, this.chipLabel);
  final String label;
  final String chipLabel;
}

/// Half-open window [from, to).
class PeriodWindow {
  const PeriodWindow(this.from, this.to);
  final DateTime from;
  final DateTime to;

  bool contains(DateTime d) => !d.isBefore(from) && d.isBefore(to);
  int get days => to.difference(from).inDays;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

PeriodWindow windowFor(ProgressPeriod p, DateTime now) {
  final today = _day(now);
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  switch (p) {
    case ProgressPeriod.week:
      final start = VolumeService.startOfWeek(now);
      return PeriodWindow(start, DateTime(start.year, start.month, start.day + 7));
    case ProgressPeriod.month:
      return PeriodWindow(DateTime(now.year, now.month), DateTime(now.year, now.month + 1));
    case ProgressPeriod.threeMonths:
      return PeriodWindow(DateTime(today.year, today.month, today.day - 89), tomorrow);
    case ProgressPeriod.year:
      return PeriodWindow(DateTime(today.year, today.month, today.day - 364), tomorrow);
    case ProgressPeriod.all:
      return PeriodWindow(DateTime(1970), tomorrow);
  }
}

/// The equally long window immediately before [w]; null for "all time".
PeriodWindow? previousWindow(ProgressPeriod p, PeriodWindow w) {
  if (p == ProgressPeriod.all) return null;
  if (p == ProgressPeriod.month) {
    return PeriodWindow(DateTime(w.from.year, w.from.month - 1), w.from);
  }
  return PeriodWindow(DateTime(w.from.year, w.from.month, w.from.day - w.days), w.from);
}

/// Like [previousWindow], but when the current window is still running (e.g.
/// mid-week) the previous window is cut to the same elapsed time, so deltas
/// compare like with like instead of "3 days vs a full week".
PeriodWindow? comparablePreviousWindow(ProgressPeriod p, PeriodWindow w, DateTime now) {
  final prev = previousWindow(p, w);
  if (prev == null || !now.isBefore(w.to)) return prev;
  final elapsed = _day(now).add(const Duration(days: 1)).difference(w.from);
  final end = prev.from.add(elapsed);
  return PeriodWindow(prev.from, end.isAfter(prev.to) ? prev.to : end);
}
