import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../domain/domain.dart';

/// Shared helpers for the cardio management screens (details, edit, backdate,
/// history, goals, goal details, custom activity, settings).

IconData cardioKindIcon(CardioKind k) => switch (k) {
      CardioKind.outdoorRun => Icons.directions_run,
      CardioKind.outdoorWalk => Icons.directions_walk,
      CardioKind.treadmill => Icons.speed,
      CardioKind.cycling => Icons.directions_bike,
      CardioKind.stationaryBike => Icons.pedal_bike,
      CardioKind.elliptical => Icons.accessibility_new,
      CardioKind.rowing => Icons.kayaking,
      CardioKind.stairClimber => Icons.stairs,
      CardioKind.jumpRope => Icons.bolt,
      CardioKind.custom => Icons.fitness_center,
    };

/// Glyphs offered by "Create Custom Cardio Activity"; key = persisted `iconKey`.
const Map<String, IconData> cardioCustomIcons = {
  'sports_mma': Icons.sports_mma,
  'fitness_center': Icons.fitness_center,
  'downhill_skiing': Icons.downhill_skiing,
  'landscape': Icons.landscape,
  'pool': Icons.pool,
  'sports_soccer': Icons.sports_soccer,
  'directions_run': Icons.directions_run,
  'timer': Icons.timer,
};

IconData customActivityIcon(String key) => cardioCustomIcons[key] ?? Icons.fitness_center;

/// Distance/pace display in the user's cardio unit (storage stays km, sec/km).
class CardioUnits {
  const CardioUnits(this.km);
  final bool km;
  static const _kmPerMi = 1.609344;

  String get distanceUnit => km ? 'km' : 'mi';
  String get speedUnit => km ? 'km/h' : 'mph';
  String get paceUnit => km ? '/km' : '/mi';

  double distance(double distanceKm) => km ? distanceKm : distanceKm / _kmPerMi;
  double toKm(double shown) => km ? shown : shown * _kmPerMi;
  String distanceText(double? distanceKm) => distanceKm == null ? '—' : Fmt.number(distance(distanceKm), decimals: 2);
  String paceText(double? secPerKm) => secPerKm == null ? '—' : Fmt.pace(km ? secPerKm : secPerKm * _kmPerMi);
  String speedText(double? kmh) => kmh == null ? '—' : Fmt.number(km ? kmh : kmh / _kmPerMi, decimals: 1);
}

/// Sequence number ("Session #12") = chronological position of the session.
int cardioSessionNumber(List<CardioSession> all, CardioSession s) {
  final asc = [...all]..sort((a, b) => a.workoutDate.compareTo(b.workoutDate));
  final i = asc.indexWhere((x) => x.id == s.id);
  return i < 0 ? asc.length + 1 : i + 1;
}

/// PR (if any) that [session] currently holds, with a short label.
String? cardioPrLabel(CardioSession session, List<CardioSession> all) {
  for (final pr in PrService.cardio(all)) {
    if (pr.sessionId != session.id) continue;
    return switch (pr.type) {
      CardioPrType.longestDuration => 'Longest session',
      CardioPrType.longestDistance => 'Longest distance',
      CardioPrType.fastestPace => 'Fastest pace',
    };
  }
  return null;
}

// ── goals ──

String goalMetricLabel(GoalMetric m) => switch (m) {
      GoalMetric.durationMinutes => 'Duration',
      GoalMetric.distanceKm => 'Distance',
      GoalMetric.sessions => 'Sessions',
      GoalMetric.calories => 'Calories',
    };

String goalMetricUnit(GoalMetric m) => switch (m) {
      GoalMetric.durationMinutes => 'MIN',
      GoalMetric.distanceKm => 'KM',
      GoalMetric.sessions => 'SESSIONS',
      GoalMetric.calories => 'KCAL',
    };

IconData goalMetricIcon(GoalMetric m) => switch (m) {
      GoalMetric.durationMinutes => Icons.timer_outlined,
      GoalMetric.distanceKm => Icons.straighten,
      GoalMetric.sessions => Icons.event_repeat,
      GoalMetric.calories => Icons.local_fire_department_outlined,
    };

String goalPeriodLabel(GoalPeriod p) => p == GoalPeriod.week ? 'Weekly' : 'Monthly';

/// [from, to) of the goal period containing [now], shifted back by [offset] periods.
(DateTime, DateTime) goalPeriodRange(GoalPeriod p, DateTime now, {int offset = 0}) {
  if (p == GoalPeriod.week) {
    final day = DateTime(now.year, now.month, now.day);
    final start = day.subtract(Duration(days: day.weekday - 1 + 7 * offset));
    return (start, start.add(const Duration(days: 7)));
  }
  final start = DateTime(now.year, now.month - offset);
  return (start, DateTime(start.year, start.month + 1));
}

List<CardioSession> sessionsInRange(List<CardioSession> all, (DateTime, DateTime) r) =>
    all.where((s) => !s.workoutDate.isBefore(r.$1) && s.workoutDate.isBefore(r.$2)).toList();

double goalValueForPeriod(CardioGoal g, List<CardioSession> all, DateTime now, {int offset = 0}) =>
    CardioMetrics.goalValue(g, sessionsInRange(all, goalPeriodRange(g.period, now, offset: offset)));

/// "92" / "18.4" — goal numbers without trailing zeros.
String goalNumber(GoalMetric m, double v) =>
    m == GoalMetric.distanceKm ? Fmt.number(v, decimals: 1) : Fmt.thousands(v);

int daysLeftInPeriod(GoalPeriod p, DateTime now) {
  final r = goalPeriodRange(p, now);
  final today = DateTime(now.year, now.month, now.day);
  return r.$2.difference(today).inDays;
}

/// Honest pace status computed from progress vs elapsed time in the period.
({String text, bool good}) goalPaceStatus(CardioGoal g, double value, DateTime now) {
  if (value >= g.target) return (text: 'Goal reached for this ${g.period == GoalPeriod.week ? 'week' : 'month'}', good: true);
  final r = goalPeriodRange(g.period, now);
  final total = r.$2.difference(r.$1).inDays;
  final today = DateTime(now.year, now.month, now.day);
  final elapsed = (today.difference(r.$1).inDays + 1).clamp(1, total);
  final expected = g.target * elapsed / total;
  final left = daysLeftInPeriod(g.period, now);
  if (value >= expected) return (text: 'On track — $left day${left == 1 ? '' : 's'} left in the period', good: true);
  final gap = expected - value;
  return (text: 'Behind pace by ${goalNumber(g.metric, gap)} ${goalMetricUnit(g.metric).toLowerCase()}', good: false);
}

/// "+32 min" / "+5.2 km" contribution of one session to a goal.
String goalContribution(CardioGoal g, CardioSession s) => switch (g.metric) {
      GoalMetric.durationMinutes => '+${(s.durationSeconds / 60).round()}',
      GoalMetric.distanceKm => '+${Fmt.number(s.distanceKm ?? 0, decimals: 1)}',
      GoalMetric.sessions => '+1',
      GoalMetric.calories => '+${s.calories ?? 0}',
    };
