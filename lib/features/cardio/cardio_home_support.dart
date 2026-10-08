import 'package:flutter/material.dart';

import 'cardio_pace.dart';
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
      CardioKind.trailRun => Icons.terrain,
      CardioKind.hiking => Icons.hiking,
      CardioKind.spinBike => Icons.directions_bike_outlined,
      CardioKind.airBike => Icons.air,
      CardioKind.skiErg => Icons.downhill_skiing,
      CardioKind.arcTrainer => Icons.sports_gymnastics,
      CardioKind.verticalClimber => Icons.north,
      CardioKind.swimming => Icons.pool,
      CardioKind.handCycle => Icons.back_hand_outlined,
      CardioKind.hiit => Icons.local_fire_department,
      CardioKind.boxing => Icons.sports_mma,
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
      CardioKind.trailRun => 'Off-road running • distance, time & pace',
      CardioKind.hiking => 'Long walks on trails • distance & time',
      CardioKind.spinBike => 'Indoor cycling • resistance & distance',
      CardioKind.airBike => 'Fan bike • time, distance & calories',
      CardioKind.skiErg => 'Pull-style erg • distance, damper & calories',
      CardioKind.arcTrainer => 'Low-impact trainer • resistance & distance',
      CardioKind.verticalClimber => 'Full-body climber • time, climb & calories',
      CardioKind.swimming => 'Pool laps • distance & pace per 100 m',
      CardioKind.handCycle => 'Upper-body cycle • resistance & distance',
      CardioKind.hiit => 'Intervals & circuits • time & calories',
      CardioKind.boxing => 'Heavy bag & pads • time & calories',
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
      CardioKind.trailRun => {CardioGroup.outdoor},
      CardioKind.hiking => {CardioGroup.outdoor, CardioGroup.lowImpact},
      CardioKind.spinBike => {CardioGroup.gym, CardioGroup.lowImpact},
      CardioKind.airBike => {CardioGroup.gym, CardioGroup.highIntensity},
      CardioKind.skiErg => {CardioGroup.gym, CardioGroup.highIntensity},
      CardioKind.arcTrainer => {CardioGroup.gym, CardioGroup.lowImpact},
      CardioKind.verticalClimber => {CardioGroup.gym, CardioGroup.highIntensity},
      CardioKind.swimming => {CardioGroup.lowImpact},
      CardioKind.handCycle => {CardioGroup.gym, CardioGroup.lowImpact},
      CardioKind.hiit => {CardioGroup.highIntensity},
      CardioKind.boxing => {CardioGroup.highIntensity},
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
  if (CardioPace.has(s.kind) && s.paceSecPerKm != null) {
    out.add(CardioMetric('Pace', CardioPace.text(s.kind, s.paceSecPerKm, miles: miles), CardioPace.unit(s.kind, miles: miles)));
  } else if (f.contains(CardioField.speed) && s.avgSpeedKmh != null) {
    out.add(CardioMetric('Speed', Fmt.number(miles ? s.avgSpeedKmh! * 0.621371 : s.avgSpeedKmh!), miles ? 'mph' : 'km/h'));
  } else if (f.contains(CardioField.resistance) && s.resistance != null) {
    out.add(CardioMetric('Resist.', '${s.resistance}', 'lvl'));
  } else if (s.calories != null) {
    out.add(CardioMetric('Burn', Fmt.thousands(s.calories!), 'kcal'));
  }
  return out.take(3).toList();
}

/// Session at the start of "this week" (Mon) → +7 days.
({DateTime from, DateTime to}) cardioWeek(DateTime now, {int offsetWeeks = 0}) {
  // Calendar arithmetic (not Duration) so a DST change never shifts the week boundary.
  final s0 = VolumeService.startOfWeek(now);
  final from = DateTime(s0.year, s0.month, s0.day + 7 * offsetWeeks);
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
