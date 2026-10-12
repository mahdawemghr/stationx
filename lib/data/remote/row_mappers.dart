import '../../domain/domain.dart';
import 'remote_gateway.dart' show Row;
import 'text_limits.dart';

/// Domain ⇄ server row mapping. A "row" is the JSON map PostgREST sends/receives
/// (snake_case columns). `user_id` is added by the gateway and never part of these maps;
/// `updated_at` is owned by the server (trigger) and is never sent.
///
/// All timestamps are exchanged in UTC ISO-8601. Enum-like values are the Dart
/// enum `name` (same strings as the local database), parsed defensively so a row
/// written by a newer app version never crashes an older one.

double? _cn(double? v, double lo, double hi) =>
    v == null ? null : clampNum(v, lo, hi);
int? _ci(int? v, int lo, int hi) => v == null ? null : clampInt(v, lo, hi);

/// Rounds to the number of decimals the server column stores (numeric(p,s)), so the value we send is
/// exactly the value that comes back (otherwise a restored phone would hold a re-rounded number).
double _r(double v, int places) {
  var f = 1.0;
  for (var i = 0; i < places; i++) {
    f *= 10;
  }
  return (v * f).round() / f;
}

double? _rn(double? v, int places) => v == null ? null : _r(v, places);

String _iso(DateTime d) => d.toUtc().toIso8601String();
DateTime _dt(Object? v, [DateTime? fallback]) => v == null
    ? (fallback ?? DateTime.fromMillisecondsSinceEpoch(0))
    : DateTime.parse(v as String);
double _d(Object? v, [double fallback = 0]) =>
    v == null ? fallback : (v as num).toDouble();
double? _dn(Object? v) => v == null ? null : (v as num).toDouble();
int _i(Object? v, [int fallback = 0]) =>
    v == null ? fallback : (v as num).round();
int? _in(Object? v) => v == null ? null : (v as num).round();
String _s(Object? v, [String fallback = '']) =>
    v == null ? fallback : v as String;

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

List<T> _enums<T extends Enum>(List<T> values, Object? names) {
  if (names is! List) return <T>[];
  return [
    for (final n in names)
      for (final v in values)
        if (v.name == n) v,
  ];
}

Row _common(SyncMeta m, {String? id}) => {
  'id': ?id,
  'created_at': _iso(
    m.createdAt,
  ), // when entered; kept by the server on later edits
};

/// Meta for a row that came FROM the cloud: it is, by definition, in sync.
SyncMeta metaFromRow(Row r) => SyncMeta(
  createdAt: _dt(r['created_at']),
  updatedAt: _dt(r['updated_at']),
  syncStatus: SyncStatus.synced,
);

// ── strength sessions ──
Row sessionToRow(WorkoutSession s) => {
  ..._common(s.meta, id: s.id),
  'workout_id': clipText(s.workoutId, 100),
  'name': clipNonEmpty(s.name, 200, 'Workout'),
  'workout_date': _iso(
    s.workoutDate,
  ), // when the user trained — never `created_at`
  'duration_seconds': clampInt(s.durationSeconds, 0, 172800),
  // Server CHECK: <= 100 exercises. Sets per exercise are capped too so the jsonb stays small.
  'exercises': [
    for (final l in s.exercises.take(100))
      {
        'exerciseId': clipText(l.exerciseId, 100),
        'sets': [
          for (final st in l.sets.take(100))
            {
              'weightKg': clampNum(st.weightKg, 0, 100000),
              'reps': clampInt(st.reps, 0, 100000),
              'done': st.done,
              'rpe': st.rpe == null ? null : clampNum(st.rpe!, 0, 10),
            },
        ],
      },
  ],
  'cardio': s.cardio == null ? null : _cardioJson(s.cardio!),
  'notes': clipText(s.notes, 5000),
};

WorkoutSession sessionFromRow(Row r) => WorkoutSession(
  id: _s(r['id']),
  workoutId: _s(r['workout_id']),
  name: _s(r['name']),
  workoutDate: _dt(r['workout_date']),
  durationSeconds: _i(r['duration_seconds']),
  exercises: [
    for (final l in (r['exercises'] as List? ?? const []))
      ExerciseLog(
        exerciseId: _s((l as Map)['exerciseId']),
        sets: [
          for (final st in (l['sets'] as List? ?? const []))
            SetLog(
              weightKg: _d((st as Map)['weightKg']),
              reps: _i(st['reps']),
              done: st['done'] as bool? ?? true,
              rpe: _dn(st['rpe']),
            ),
        ],
      ),
  ],
  cardio: r['cardio'] == null
      ? null
      : _cardioFromJson((r['cardio'] as Map).cast<String, dynamic>()),
  notes: _s(r['notes']),
  meta: metaFromRow(r),
);

// Cardio embedded inside a strength session (camelCase JSON, not a table row).
Map<String, dynamic> _cardioJson(CardioSession c) => {
  'id': clipText(c.id, 100),
  'kind': c.kind.name,
  'workoutDate': _iso(c.workoutDate),
  'durationSeconds': c.durationSeconds,
  'distanceKm': c.distanceKm,
  'speedKmh': c.speedKmh,
  'inclinePct': c.inclinePct,
  'resistance': c.resistance,
  'calories': c.calories,
  'avgHeartRate': c.avgHeartRate,
  'rpe': c.rpe,
  'routeName': clipText(c.routeName, 200),
  'notes': clipText(c.notes, 5000),
  'customActivityId': c.customActivityId == null
      ? null
      : clipText(c.customActivityId!, 100),
  'createdAt': _iso(c.meta.createdAt),
  'updatedAt': _iso(c.meta.updatedAt),
};

CardioSession _cardioFromJson(Map<String, dynamic> j) => CardioSession(
  id: _s(j['id']),
  kind: _enum(CardioKind.values, j['kind'], CardioKind.custom),
  workoutDate: _dt(j['workoutDate']),
  durationSeconds: _i(j['durationSeconds']),
  distanceKm: _dn(j['distanceKm']),
  speedKmh: _dn(j['speedKmh']),
  inclinePct: _dn(j['inclinePct']),
  resistance: _in(j['resistance']),
  calories: _in(j['calories']),
  avgHeartRate: _in(j['avgHeartRate']),
  rpe: _dn(j['rpe']),
  routeName: _s(j['routeName']),
  notes: _s(j['notes']),
  customActivityId: j['customActivityId'] as String?,
  meta: SyncMeta(
    createdAt: _dt(j['createdAt']),
    updatedAt: _dt(j['updatedAt']),
    syncStatus: SyncStatus.synced,
  ),
);

// ── cardio sessions ──
Row cardioToRow(CardioSession c) => {
  ..._common(c.meta, id: c.id),
  'kind': c.kind.name,
  'workout_date': _iso(c.workoutDate),
  'duration_seconds': clampInt(c.durationSeconds, 0, 172800),
  // numeric(8,3) / (6,2) / (5,2) / (3,1): rounded here to the stored precision.
  'distance_km': _rn(_cn(c.distanceKm, 0, 99999), 3),
  'speed_kmh': _rn(_cn(c.speedKmh, 0, 499), 2),
  'incline_pct': _rn(_cn(c.inclinePct, -50, 100), 2),
  'resistance': _ci(c.resistance, 0, 1000),
  'calories': _ci(c.calories, 0, 100000),
  'avg_heart_rate': _ci(c.avgHeartRate, 20, 260),
  'rpe': _rn(_cn(c.rpe, 0, 10), 1),
  'route_name': clipText(c.routeName, 200),
  'notes': clipText(c.notes, 5000),
  'custom_activity_id': c.customActivityId == null
      ? null
      : clipText(c.customActivityId!, 100),
};

CardioSession cardioFromRow(Row r) => CardioSession(
  id: _s(r['id']),
  kind: _enum(CardioKind.values, r['kind'], CardioKind.custom),
  workoutDate: _dt(r['workout_date']),
  durationSeconds: _i(r['duration_seconds']),
  distanceKm: _dn(r['distance_km']),
  speedKmh: _dn(r['speed_kmh']),
  inclinePct: _dn(r['incline_pct']),
  resistance: _in(r['resistance']),
  calories: _in(r['calories']),
  avgHeartRate: _in(r['avg_heart_rate']),
  rpe: _dn(r['rpe']),
  routeName: _s(r['route_name']),
  notes: _s(r['notes']),
  customActivityId: r['custom_activity_id'] as String?,
  meta: metaFromRow(r),
);

// ── goals ──
Row goalToRow(CardioGoal g) => {
  ..._common(g.meta, id: g.id),
  'title': clipNonEmpty(g.title, 200, 'Goal'),
  'metric': g.metric.name,
  'target': _r(clampNum(g.target, 0.01, 99999999), 2), // numeric(10,2)
  'period': g.period.name,
  'is_primary': g.isPrimary,
};

CardioGoal goalFromRow(Row r) => CardioGoal(
  id: _s(r['id']),
  title: _s(r['title']),
  metric: _enum(GoalMetric.values, r['metric'], GoalMetric.durationMinutes),
  target: _d(r['target'], 1),
  period: _enum(GoalPeriod.values, r['period'], GoalPeriod.week),
  isPrimary: r['is_primary'] as bool? ?? false,
  meta: metaFromRow(r),
);

// ── custom cardio activities ──
Row customActivityToRow(CustomCardioActivity a) => {
  ..._common(a.meta, id: a.id),
  'name': clipNonEmpty(a.name, 200, 'Activity'),
  'category': clipText(a.category, 100),
  'icon_key': clipText(a.iconKey, 60),
  'fields': [for (final f in a.fields) f.name],
  'round_seconds': a.roundSeconds == null
      ? null
      : clampInt(a.roundSeconds!, 1, 1000000),
  'rest_seconds': a.restSeconds == null
      ? null
      : clampInt(a.restSeconds!, 0, 1000000),
  'rounds': a.rounds == null ? null : clampInt(a.rounds!, 1, 1000000),
};

CustomCardioActivity customActivityFromRow(Row r) => CustomCardioActivity(
  id: _s(r['id']),
  name: _s(r['name']),
  category: _s(r['category'], 'Custom'),
  iconKey: _s(r['icon_key'], 'fitness_center'),
  fields: _enums(CardioField.values, r['fields']),
  roundSeconds: _in(r['round_seconds']),
  restSeconds: _in(r['rest_seconds']),
  rounds: _in(r['rounds']),
  meta: metaFromRow(r),
);

// ── custom exercises (the built-in catalogue is not synced) ──
// Server CHECK: muscle_targets is null or an array of <= 12 entries.
Object? _targets(Exercise e) {
  final j = MuscleTargetCodec.toJson(e.muscleTargets);
  return j != null && j.length > 12 ? j.take(12).toList() : j;
}

Row exerciseToRow(Exercise e) => {
  ..._common(e.meta, id: e.id),
  'name': clipNonEmpty(e.name, 200, 'Exercise'),
  'primary_muscle': e.primaryMuscle.name,
  'secondary_muscles': [for (final m in e.secondaryMuscles) m.name],
  'equipment': e.equipment.name,
  'movement_pattern': clipText(e.movementPattern, 100),
  'instructions': [
    for (final s in e.instructions.take(30))
      {'title': clipText(s.title, 200), 'text': clipText(s.text, 2000)},
  ],
  'is_custom': e.isCustom,
  'tempo': e.tempo == null ? null : clipText(e.tempo!, 20),
  'muscle_targets': _targets(e),
};

Exercise exerciseFromRow(Row r) => Exercise(
  id: _s(r['id']),
  name: _s(r['name']),
  primaryMuscle: _enum(
    MuscleGroup.values,
    r['primary_muscle'],
    MuscleGroup.chest,
  ),
  secondaryMuscles: _enums(MuscleGroup.values, r['secondary_muscles']),
  // Unknown (newer) equipment from another client falls back to bodyweight; new values need migration 20261012010000.
  equipment: _enum(Equipment.values, r['equipment'], Equipment.bodyweight),
  movementPattern: _s(r['movement_pattern']),
  instructions: [
    for (final s in (r['instructions'] as List? ?? const []))
      ExerciseStep(_s((s as Map)['title']), _s(s['text'])),
  ],
  isCustom: r['is_custom'] as bool? ?? true,
  tempo: r['tempo'] as String?,
  muscleTargets: MuscleTargetCodec.fromJson(r['muscle_targets']),
  meta: metaFromRow(r),
);

// ── workouts ──
Row workoutToRow(Workout w, int position) => {
  ..._common(w.meta, id: w.id),
  'name': clipNonEmpty(w.name, 200, 'Workout'),
  'description': clipText(w.description, 1000),
  'position': position,
  'exercises': [
    for (final e in w.exercises.take(100))
      {
        'exerciseId': clipText(e.exerciseId, 100),
        'sets': clampInt(e.sets, 0, 1000),
        'repMin': clampInt(e.repMin, 0, 10000),
        'repMax': clampInt(e.repMax, 0, 10000),
      },
  ],
  'cardio_finisher': w.cardioFinisher == null
      ? null
      : {
          'kind': w.cardioFinisher!.kind.name,
          'durationMinutes': w.cardioFinisher!.durationMinutes,
          'distanceKm': w.cardioFinisher!.distanceKm,
          'speedKmh': w.cardioFinisher!.speedKmh,
          'inclinePct': w.cardioFinisher!.inclinePct,
          'resistance': w.cardioFinisher!.resistance,
        },
};

/// Returns the workout and its list position.
(Workout, int) workoutFromRow(Row r) {
  final cf = r['cardio_finisher'] as Map?;
  return (
    Workout(
      id: _s(r['id']),
      name: _s(r['name']),
      description: _s(r['description']),
      exercises: [
        for (final e in (r['exercises'] as List? ?? const []))
          RoutineExercise(
            exerciseId: _s((e as Map)['exerciseId']),
            sets: _i(e['sets'], 3),
            repMin: _i(e['repMin'], 8),
            repMax: _i(e['repMax'], 12),
          ),
      ],
      cardioFinisher: cf == null
          ? null
          : CardioTarget(
              kind: _enum(CardioKind.values, cf['kind'], CardioKind.treadmill),
              durationMinutes: _in(cf['durationMinutes']),
              distanceKm: _dn(cf['distanceKm']),
              speedKmh: _dn(cf['speedKmh']),
              inclinePct: _dn(cf['inclinePct']),
              resistance: _in(cf['resistance']),
            ),
      meta: metaFromRow(r),
    ),
    _i(r['position']),
  );
}

// ── rotation (singleton) ──
Row rotationToRow(Rotation r) => {
  // Server CHECKs: <= 500 ids (<= 64 KB), current_index >= 0.
  'workout_ids': [for (final id in r.workoutIds.take(500)) clipText(id, 100)],
  'current_index': clampInt(r.currentIndex, 0, 1000000),
};

Rotation rotationFromRow(Row r) => Rotation(
  workoutIds: [
    for (final w in (r['workout_ids'] as List? ?? const [])) w as String,
  ],
  currentIndex: _i(r['current_index']),
);

// ── profile (singleton). Credentials never exist locally, so none are synced. ──
Row profileToRow(UserProfile p) => {
  // The username is owned by the auth account (profiles.email is set by the signup trigger): not sent.
  'name': clipText(p.name, 100),
  'weight_kg': _r(clampNum(p.weightKg, 0.1, 699), 2), // numeric(6,2)
  'height_cm': _r(clampNum(p.heightCm, 0.1, 299), 1), // numeric(5,1)
  'age': clampInt(p.age, 1, 130),
  'unit': p.unit.name,
  'theme_mode': p.themeMode.name,
  'default_sets': clampInt(p.defaultSets, 1, 20),
  'default_rep_min': clampInt(p.defaultRepMin, 1, 100),
  'default_rep_max': clampInt(
    p.defaultRepMax,
    clampInt(p.defaultRepMin, 1, 100),
    100,
  ),
  'progression_enabled': p.progressionEnabled,
  'weekly_session_target': clampInt(p.weeklySessionTarget, 0, 21),
  'cardio_distance_unit_km': p.cardioDistanceUnitKm,
  // null = never chosen; [] = bodyweight only.
  'equipment': p.equipment == null
      ? null
      : ([for (final e in p.equipment!) e.name]..sort()),
  // Only sent once chosen: the column comes from migration 20261016 and a server without it would
  // reject the unknown key. Never chosen (null) is simply absent and read back as null.
  if (p.experienceLevel != null) 'experience_level': p.experienceLevel!.name,
};

/// The app keeps the (normalised) username in `UserProfile.email`. A profile row that was only ever
/// created by the signup trigger carries the private auth identifier `<username>@stationx.local`
/// instead; map that back so a restored phone never shows the backend identifier.
String _usernameFromEmailColumn(String v) {
  const suffix = '@stationx.local';
  return v.endsWith(suffix) ? v.substring(0, v.length - suffix.length) : v;
}

/// Applies a cloud profile over [base] (keeps local-only fields). A profile that
/// exists in the cloud belongs to a real account, so `isGuest` becomes false.
UserProfile profileFromRow(Row r, UserProfile base) => base.copyWith(
  name: _s(r['name'], base.name),
  email: r['email'] == null
      ? base.email
      : _usernameFromEmailColumn(r['email'] as String),
  isGuest: false,
  weightKg: _d(r['weight_kg'], base.weightKg),
  heightCm: _d(r['height_cm'], base.heightCm),
  age: _i(r['age'], base.age),
  unit: _enum(WeightUnit.values, r['unit'], base.unit),
  themeMode: _enum(SxThemeMode.values, r['theme_mode'], base.themeMode),
  defaultSets: _i(r['default_sets'], base.defaultSets),
  defaultRepMin: _i(r['default_rep_min'], base.defaultRepMin),
  defaultRepMax: _i(r['default_rep_max'], base.defaultRepMax),
  progressionEnabled:
      r['progression_enabled'] as bool? ?? base.progressionEnabled,
  weeklySessionTarget: _i(r['weekly_session_target'], base.weeklySessionTarget),
  cardioDistanceUnitKm:
      r['cardio_distance_unit_km'] as bool? ?? base.cardioDistanceUnitKm,
  equipment: _equipmentFromColumn(r['equipment']),
  clearEquipment: r['equipment'] == null,
  experienceLevel: Difficulty.tryParse(r['experience_level']),
);

/// Unknown names (written by a newer app) are ignored rather than failing the whole profile.
Set<Equipment>? _equipmentFromColumn(Object? v) {
  if (v is! List) return null;
  final names = {for (final e in Equipment.values) e.name: e};
  return {
    for (final x in v)
      if (names[x] != null) names[x]!,
  };
}
