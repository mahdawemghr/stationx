import 'package:flutter/material.dart';

import 'cardio_kind_presentation.dart';
import 'cardio_manage_helpers.dart' show cardioCustomIcons;
import 'cardio_pace.dart';
import '../../core/utils/formatters.dart';
import '../../domain/domain.dart';

/// Presentation helpers for [CardioKind] shared by the live-flow screens
/// (home, select, prepare, active, complete). Pure + stateless.

IconData cardioKindIcon(CardioKind k) => cardioKindGlyph(k);

/// Maps a custom activity's `iconKey` to an icon (unknown → generic).
IconData cardioIconForKey(String key) => cardioCustomIcons[key] ?? Icons.fitness_center;

String cardioKindBlurb(CardioKind k) => cardioBlurb(k);

String cardioBlurb(CardioKind k) => switch (k) {
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
      CardioKind.indoorWalk => 'Walking pad or treadmill walk • speed & incline',
      CardioKind.nordicWalk => 'Pole walking • distance, time & pace',
      CardioKind.rucking => 'Weighted-pack walks • distance, time & pace',
      CardioKind.recumbentBike => 'Seated bike • resistance & distance',
      CardioKind.indoorTrainer => 'Smart trainer or Zwift • time, distance & resistance',
      CardioKind.crossCountrySki => 'Nordic skiing • distance, time & pace',
      CardioKind.openWaterSwim => 'Lake or sea swims • distance & pace per 100 m',
      CardioKind.outdoorRowing => 'On the water • distance & pace per 500 m',
      CardioKind.paddling => 'Kayak, canoe or SUP • distance & pace per 500 m',
      CardioKind.danceCardio => 'Dance cardio & classes • time & calories',
      CardioKind.skating => 'Inline, roller or ice • distance & speed',
      CardioKind.climbing => 'Wall or boulder sessions • time & calories',
      CardioKind.martialArts => 'Kickboxing, sparring & drills • time & calories',
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
enum CardioGroup { outdoor, gym, highIntensity, lowImpact, classes }

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
      CardioKind.indoorWalk => {CardioGroup.gym, CardioGroup.lowImpact},
      CardioKind.nordicWalk => {CardioGroup.outdoor, CardioGroup.lowImpact},
      CardioKind.rucking => {CardioGroup.outdoor},
      CardioKind.recumbentBike => {CardioGroup.gym, CardioGroup.lowImpact},
      CardioKind.indoorTrainer => {CardioGroup.gym},
      CardioKind.crossCountrySki => {CardioGroup.outdoor, CardioGroup.highIntensity},
      CardioKind.openWaterSwim => {CardioGroup.outdoor, CardioGroup.lowImpact},
      CardioKind.outdoorRowing => {CardioGroup.outdoor},
      CardioKind.paddling => {CardioGroup.outdoor, CardioGroup.lowImpact},
      CardioKind.danceCardio => {CardioGroup.classes},
      CardioKind.skating => {CardioGroup.outdoor},
      CardioKind.climbing => {CardioGroup.classes, CardioGroup.highIntensity},
      CardioKind.martialArts => {CardioGroup.classes, CardioGroup.highIntensity},
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
