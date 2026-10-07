import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../domain/domain.dart';

/// Presentation helpers for [CardioKind] shared by the live-flow screens
/// (home, select, prepare, active, complete). Pure + stateless.

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

/// Maps a custom activity's `iconKey` to an icon (unknown → generic).
IconData cardioIconForKey(String key) => switch (key) {
      'sports_mma' => Icons.sports_mma,
      'sports_soccer' => Icons.sports_soccer,
      'downhill_skiing' => Icons.downhill_skiing,
      'landscape' => Icons.landscape,
      'surfing' => Icons.surfing,
      'rowing' => Icons.rowing,
      'kayaking' => Icons.kayaking,
      'local_fire_department' => Icons.local_fire_department,
      _ => Icons.fitness_center,
    };

String cardioKindBlurb(CardioKind k) => switch (k) {
      CardioKind.outdoorRun => 'Distance, duration & pace',
      CardioKind.outdoorWalk => 'Low-impact endurance & active recovery',
      CardioKind.treadmill => 'Speed & incline • indoor sessions',
      CardioKind.cycling => 'Distance, duration & average speed',
      CardioKind.stationaryBike => 'Duration, distance & resistance level',
      CardioKind.elliptical => 'Low impact, joint-friendly endurance',
      CardioKind.rowing => 'Duration, distance & resistance',
      CardioKind.stairClimber => 'Duration & intensity level',
      CardioKind.jumpRope => 'High-intensity, duration based',
      CardioKind.custom => 'Your own activity',
    };

String cardioFieldLabel(CardioField f) => switch (f) {
      CardioField.duration => 'DURATION',
      CardioField.distance => 'DISTANCE',
      CardioField.pace => 'PACE',
      CardioField.speed => 'SPEED',
      CardioField.incline => 'INCLINE',
      CardioField.resistance => 'RESISTANCE',
      CardioField.calories => 'KCAL',
      CardioField.heartRate => 'HR',
      CardioField.rpe => 'RPE',
    };

String cardioMetricsLine(CardioKind k) => 'METRICS: ${k.fields.map(cardioFieldLabel).join(' • ')}';

/// Coarse grouping used by the activity filter chips.
enum CardioGroup { outdoor, gym, highIntensity, lowImpact }

Set<CardioGroup> cardioGroups(CardioKind k) => switch (k) {
      CardioKind.outdoorRun => {CardioGroup.outdoor},
      CardioKind.outdoorWalk => {CardioGroup.outdoor, CardioGroup.lowImpact},
      CardioKind.treadmill => {CardioGroup.gym},
      CardioKind.cycling => {CardioGroup.outdoor},
      CardioKind.stationaryBike => {CardioGroup.gym, CardioGroup.lowImpact},
      CardioKind.elliptical => {CardioGroup.gym, CardioGroup.lowImpact},
      CardioKind.rowing => {CardioGroup.gym},
      CardioKind.stairClimber => {CardioGroup.gym, CardioGroup.highIntensity},
      CardioKind.jumpRope => {CardioGroup.highIntensity},
      CardioKind.custom => {},
    };

/// A (label, value) display metric.
class CardioMetric {
  const CardioMetric(this.label, this.value, [this.unit]);
  final String label;
  final String value;
  final String? unit;
}

/// Up to three summary metrics for a logged session, adapted to its kind.
/// Only values that exist are returned — never placeholders.
List<CardioMetric> cardioSummaryMetrics(CardioSession s, {bool miles = false}) {
  final out = <CardioMetric>[
    CardioMetric('Time', '${(s.durationSeconds / 60).round()}', 'min'),
  ];
  if (s.distanceKm != null) out.add(CardioMetric('Distance', Fmt.km(s.distanceKm, miles: miles), miles ? 'mi' : 'km'));
  final f = s.kind.fields;
  if (f.contains(CardioField.pace) && s.paceSecPerKm != null) {
    out.add(CardioMetric('Pace', Fmt.pace(s.paceSecPerKm), '/km'));
  } else if (f.contains(CardioField.speed) && s.avgSpeedKmh != null) {
    out.add(CardioMetric('Speed', Fmt.number(s.avgSpeedKmh!), 'km/h'));
  } else if (f.contains(CardioField.resistance) && s.resistance != null) {
    out.add(CardioMetric('Resist.', '${s.resistance}', 'lvl'));
  } else if (s.calories != null) {
    out.add(CardioMetric('Burn', Fmt.thousands(s.calories!), 'kcal'));
  }
  return out.take(3).toList();
}

/// Session at the start of "this week" (Mon) → +7 days.
({DateTime from, DateTime to}) cardioWeek(DateTime now, {int offsetWeeks = 0}) {
  final start = VolumeService.startOfWeek(now).add(Duration(days: 7 * offsetWeeks));
  final from = DateTime(start.year, start.month, start.day);
  return (from: from, to: DateTime(from.year, from.month, from.day + 7));
}

/// Primary weekly duration goal, if any (falls back to any duration goal).
CardioGoal? weeklyDurationGoal(Iterable<CardioGoal> goals) {
  CardioGoal? any;
  for (final g in goals) {
    if (g.metric != GoalMetric.durationMinutes || g.period != GoalPeriod.week) continue;
    if (g.isPrimary) return g;
    any ??= g;
  }
  return any;
}

/// Most recent session of [kind] (repository lists newest first).
CardioSession? lastOfKind(Iterable<CardioSession> sessions, CardioKind kind, {String? exceptId, String? customId}) {
  for (final s in sessions) {
    if (s.id == exceptId) continue;
    if (s.kind == kind && s.customActivityId == customId) return s;
  }
  return null;
}
