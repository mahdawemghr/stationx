import 'sync_meta.dart';

/// Which input fields a cardio activity exposes. Drives the adaptive forms.
enum CardioField { duration, distance, pace, speed, incline, resistance, calories, heartRate, rpe }

enum CardioKind {
  outdoorRun('Outdoor Run', [CardioField.duration, CardioField.distance, CardioField.pace]),
  outdoorWalk('Outdoor Walk', [CardioField.duration, CardioField.distance, CardioField.pace]),
  treadmill('Treadmill',
      [CardioField.duration, CardioField.distance, CardioField.speed, CardioField.incline]),
  cycling('Cycling', [CardioField.duration, CardioField.distance, CardioField.speed]),
  stationaryBike('Stationary Bike',
      [CardioField.duration, CardioField.distance, CardioField.resistance]),
  elliptical('Elliptical', [CardioField.duration, CardioField.distance, CardioField.resistance]),
  rowing('Rowing Machine', [CardioField.duration, CardioField.distance, CardioField.resistance]),
  stairClimber('Stair Climber', [CardioField.duration, CardioField.resistance]),
  jumpRope('Jump Rope', [CardioField.duration]),
  custom('Custom', [CardioField.duration]);

  const CardioKind(this.label, this.fields);
  final String label;

  /// Primary (spec-required) fields for this kind.
  final List<CardioField> fields;

  bool get hasDistance => fields.contains(CardioField.distance);
}

/// Target for a planned cardio block (e.g. 20 min treadmill finisher).
class CardioTarget {
  const CardioTarget({
    required this.kind,
    this.durationMinutes,
    this.distanceKm,
    this.speedKmh,
    this.inclinePct,
    this.resistance,
  });
  final CardioKind kind;
  final int? durationMinutes;
  final double? distanceKm;
  final double? speedKmh;
  final double? inclinePct;
  final int? resistance;
}

/// A logged cardio session — standalone, or attached to a [WorkoutSession].
/// Sensor-derived fields (heart rate, cadence, calories) are optional and
/// only present when the user typed them / a sensor supplied them.
class CardioSession {
  CardioSession({
    required this.id,
    required this.kind,
    required this.workoutDate,
    required this.durationSeconds,
    this.distanceKm,
    this.speedKmh,
    this.inclinePct,
    this.resistance,
    this.calories,
    this.avgHeartRate,
    this.rpe,
    this.routeName = '',
    this.notes = '',
    this.customActivityId,
    SyncMeta? meta,
  }) : meta = meta ?? SyncMeta();

  final String id;
  final CardioKind kind;

  /// When the user did it (backdatable). `meta.createdAt` = when entered.
  final DateTime workoutDate;
  final int durationSeconds;
  final double? distanceKm;
  final double? speedKmh;
  final double? inclinePct;
  final int? resistance;
  final int? calories;
  final int? avgHeartRate;
  final double? rpe;
  final String routeName;
  final String notes;
  final String? customActivityId;
  final SyncMeta meta;

  /// Seconds per km, derived from duration & distance.
  double? get paceSecPerKm =>
      (distanceKm != null && distanceKm! > 0) ? durationSeconds / distanceKm! : null;

  double? get avgSpeedKmh =>
      speedKmh ?? ((distanceKm != null && durationSeconds > 0) ? distanceKm! / (durationSeconds / 3600) : null);

  CardioSession copyWith({
    CardioKind? kind,
    DateTime? workoutDate,
    int? durationSeconds,
    double? distanceKm,
    double? speedKmh,
    double? inclinePct,
    int? resistance,
    int? calories,
    int? avgHeartRate,
    double? rpe,
    String? routeName,
    String? notes,
  }) =>
      CardioSession(
        id: id,
        kind: kind ?? this.kind,
        workoutDate: workoutDate ?? this.workoutDate,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        distanceKm: distanceKm ?? this.distanceKm,
        speedKmh: speedKmh ?? this.speedKmh,
        inclinePct: inclinePct ?? this.inclinePct,
        resistance: resistance ?? this.resistance,
        calories: calories ?? this.calories,
        avgHeartRate: avgHeartRate ?? this.avgHeartRate,
        rpe: rpe ?? this.rpe,
        routeName: routeName ?? this.routeName,
        notes: notes ?? this.notes,
        customActivityId: customActivityId,
        meta: meta.touched(),
      );
}

enum GoalMetric { durationMinutes, distanceKm, sessions, calories }

enum GoalPeriod { week, month }

class CardioGoal {
  CardioGoal({
    required this.id,
    required this.title,
    required this.metric,
    required this.target,
    this.period = GoalPeriod.week,
    this.isPrimary = false,
    SyncMeta? meta,
  }) : meta = meta ?? SyncMeta();

  final String id;
  final String title;
  final GoalMetric metric;
  final double target;
  final GoalPeriod period;
  final bool isPrimary;
  final SyncMeta meta;

  CardioGoal copyWith({String? title, GoalMetric? metric, double? target, GoalPeriod? period, bool? isPrimary}) =>
      CardioGoal(
          id: id,
          title: title ?? this.title,
          metric: metric ?? this.metric,
          target: target ?? this.target,
          period: period ?? this.period,
          isPrimary: isPrimary ?? this.isPrimary,
          meta: meta.touched());
}

/// User-defined cardio activity (Create Custom Cardio Activity).
class CustomCardioActivity {
  CustomCardioActivity({
    required this.id,
    required this.name,
    this.category = 'Custom',
    this.iconKey = 'fitness_center',
    this.fields = const [CardioField.duration],
    this.roundSeconds,
    this.restSeconds,
    this.rounds,
    SyncMeta? meta,
  }) : meta = meta ?? SyncMeta();

  final String id;
  final String name;
  final String category;
  final String iconKey;
  final List<CardioField> fields;

  /// Optional interval template (not part of the persisted session model yet).
  final int? roundSeconds;
  final int? restSeconds;
  final int? rounds;
  final SyncMeta meta;
}
