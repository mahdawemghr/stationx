import 'sync_meta.dart';

/// Which input fields a cardio activity exposes. Drives the adaptive forms.
enum CardioField {
  duration,
  distance,
  pace,
  speed,
  incline,
  resistance,
  calories,
  heartRate,
  rpe,
}

enum CardioKind {
  outdoorRun('Outdoor Run', [
    CardioField.duration,
    CardioField.distance,
    CardioField.pace,
  ]),
  outdoorWalk('Outdoor Walk', [
    CardioField.duration,
    CardioField.distance,
    CardioField.pace,
  ]),
  treadmill('Treadmill Run', [
    CardioField.duration,
    CardioField.distance,
    CardioField.speed,
    CardioField.incline,
  ]),
  cycling('Cycling', [
    CardioField.duration,
    CardioField.distance,
    CardioField.speed,
  ]),
  stationaryBike('Upright Bike', [
    CardioField.duration,
    CardioField.distance,
    CardioField.resistance,
  ]),
  elliptical('Elliptical', [
    CardioField.duration,
    CardioField.distance,
    CardioField.resistance,
  ]),
  rowing('Rowing Machine', [
    CardioField.duration,
    CardioField.distance,
    CardioField.resistance,
  ]),
  stairClimber('Stair Climber / Stepper', [
    CardioField.duration,
    CardioField.resistance,
  ]),
  jumpRope('Jump Rope', [CardioField.duration]),
  // Added 2026-10 (append-only: stored by `name`, never by index). Watts and
  // cadence/SPM/stroke rate are NOT stored fields; floors/laps map onto distance.
  trailRun('Trail Run', [
    CardioField.duration,
    CardioField.distance,
    CardioField.pace,
  ]),
  hiking('Hiking', [
    CardioField.duration,
    CardioField.distance,
    CardioField.pace,
  ]),
  spinBike('Spin / Indoor Cycle', [
    CardioField.duration,
    CardioField.distance,
    CardioField.resistance,
  ]),
  airBike('Air Bike', [
    CardioField.duration,
    CardioField.distance,
    CardioField.calories,
  ]),
  skiErg('Ski Erg', [
    CardioField.duration,
    CardioField.distance,
    CardioField.resistance,
    CardioField.calories,
  ]),
  arcTrainer('Arc Trainer', [
    CardioField.duration,
    CardioField.distance,
    CardioField.resistance,
  ]),
  verticalClimber('Vertical Climber', [
    CardioField.duration,
    CardioField.distance,
    CardioField.calories,
  ]),
  swimming('Pool Swim', [CardioField.duration, CardioField.distance]),
  handCycle('Arm Ergometer', [
    CardioField.duration,
    CardioField.distance,
    CardioField.resistance,
  ]),
  hiit('HIIT / Circuit / Conditioning', [
    CardioField.duration,
    CardioField.calories,
  ]),
  boxing('Boxing / Heavy Bag', [CardioField.duration, CardioField.calories]),
  // Added 2026-10 (second batch; append-only, before `custom`). No new stored fields.
  indoorWalk('Indoor Walk / Walking Pad', [
    CardioField.duration,
    CardioField.distance,
    CardioField.speed,
    CardioField.incline,
  ]),
  nordicWalk('Nordic Walking', [
    CardioField.duration,
    CardioField.distance,
    CardioField.pace,
  ]),
  rucking('Rucking', [
    CardioField.duration,
    CardioField.distance,
    CardioField.pace,
  ]),
  recumbentBike('Recumbent Bike', [
    CardioField.duration,
    CardioField.distance,
    CardioField.resistance,
  ]),
  indoorTrainer('Bike Trainer / Zwift', [
    CardioField.duration,
    CardioField.distance,
    CardioField.resistance,
  ]),
  crossCountrySki('Cross-Country Skiing', [
    CardioField.duration,
    CardioField.distance,
    CardioField.pace,
  ]),
  openWaterSwim('Open Water Swim', [
    CardioField.duration,
    CardioField.distance,
  ]),
  outdoorRowing('Rowing (On Water)', [
    CardioField.duration,
    CardioField.distance,
  ]),
  paddling('Kayak / Canoe / SUP', [CardioField.duration, CardioField.distance]),
  danceCardio('Dance / Zumba / Aerobics', [
    CardioField.duration,
    CardioField.calories,
  ]),
  skating('Skating / Rollerblading', [
    CardioField.duration,
    CardioField.distance,
    CardioField.speed,
  ]),
  climbing('Climbing / Bouldering', [
    CardioField.duration,
    CardioField.calories,
  ]),
  martialArts('Kickboxing / Martial Arts', [
    CardioField.duration,
    CardioField.calories,
  ]),
  custom('Custom', [CardioField.duration]);

  const CardioKind(this.label, this.fields);
  final String label;

  /// Primary (spec-required) fields for this kind.
  final List<CardioField> fields;

  bool get hasDistance => fields.contains(CardioField.distance);

  /// Whether a "fastest pace" personal record is meaningful. Kinds without a pace convention
  /// (bikes, skating, walking pad...) never get a run-style pace PR. A treadmill session is a
  /// run, so it keeps one even though it logs speed rather than pace.
  bool get hasPacePr =>
      paceBasis != CardioPaceBasis.none || this == CardioKind.treadmill;

  /// How pace is conventionally quoted for this activity (derived, never stored).
  CardioPaceBasis get paceBasis => switch (this) {
    CardioKind.rowing ||
    CardioKind.skiErg ||
    CardioKind.outdoorRowing ||
    CardioKind.paddling => CardioPaceBasis.per500m,
    CardioKind.swimming || CardioKind.openWaterSwim => CardioPaceBasis.per100m,
    _ =>
      fields.contains(CardioField.pace)
          ? CardioPaceBasis.perKm
          : CardioPaceBasis.none,
  };
}

/// Pace convention: running/walking per km (or mi), rowing & ski erg per 500 m,
/// swimming per 100 m.
enum CardioPaceBasis {
  none(0),
  perKm(1000),
  per500m(500),
  per100m(100);

  const CardioPaceBasis(this.meters);
  final double meters;

  String get unitLabel => switch (this) {
    none => '',
    perKm => '/km',
    per500m => '/500m',
    per100m => '/100m',
  };
}

/// Resolves which input fields a session of [kind] exposes. A `CardioKind.custom`
/// session follows its [CustomCardioActivity.fields] (when known) and otherwise keeps
/// distance/speed whenever the session already has them, so editing never hides (and then
/// erases) a stored distance.
abstract final class CardioFieldResolver {
  static List<CardioField> fieldsFor(
    CardioKind kind, {
    CustomCardioActivity? custom,
    double? existingDistanceKm,
  }) {
    final base = (kind == CardioKind.custom && custom != null)
        ? custom.fields
        : kind.fields;
    if (kind == CardioKind.custom &&
        (existingDistanceKm ?? 0) > 0 &&
        !base.contains(CardioField.distance)) {
      return [...base, CardioField.distance];
    }
    return base;
  }
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
  double? get paceSecPerKm => (distanceKm != null && distanceKm! > 0)
      ? durationSeconds / distanceKm!
      : null;

  /// Seconds per 500 m (rowing / ski erg convention), derived. Null without distance.
  double? get paceSecPer500m => _paceSecPer(500);

  /// Seconds per 100 m (swimming convention), derived. Null without distance.
  double? get paceSecPer100m => _paceSecPer(100);

  /// Pace in the convention of [kind] (see [CardioKind.paceBasis]); null for `none`.
  double? get conventionalPaceSec {
    final b = kind.paceBasis;
    return b == CardioPaceBasis.none ? null : _paceSecPer(b.meters);
  }

  double? _paceSecPer(double meters) =>
      (distanceKm != null && distanceKm! > 0 && durationSeconds > 0)
      ? durationSeconds / (distanceKm! * 1000 / meters)
      : null;

  double? get avgSpeedKmh =>
      speedKmh ??
      ((distanceKm != null && durationSeconds > 0)
          ? distanceKm! / (durationSeconds / 3600)
          : null);

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
  }) => CardioSession(
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

  CardioGoal copyWith({
    String? title,
    GoalMetric? metric,
    double? target,
    GoalPeriod? period,
    bool? isPrimary,
  }) => CardioGoal(
    id: id,
    title: title ?? this.title,
    metric: metric ?? this.metric,
    target: target ?? this.target,
    period: period ?? this.period,
    isPrimary: isPrimary ?? this.isPrimary,
    meta: meta.touched(),
  );
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
