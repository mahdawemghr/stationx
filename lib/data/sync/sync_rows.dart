import '../../domain/domain.dart';

/// Domain ⇄ cloud row mapping. A "row" is the JSON map PostgREST sends/receives
/// (snake_case columns). `user_id` and `server_updated_at` are added/read by the
/// gateway and are never part of these maps.
///
/// All timestamps are exchanged in UTC ISO-8601. Enum-like values are the Dart
/// enum `name` (same strings as the local database), parsed defensively so a row
/// written by a newer app version never crashes an older one.
typedef Row = Map<String, dynamic>;

String _iso(DateTime d) => d.toUtc().toIso8601String();
DateTime _dt(Object? v, [DateTime? fallback]) =>
    v == null ? (fallback ?? DateTime.fromMillisecondsSinceEpoch(0)) : DateTime.parse(v as String);
double _d(Object? v, [double fallback = 0]) => v == null ? fallback : (v as num).toDouble();
double? _dn(Object? v) => v == null ? null : (v as num).toDouble();
int _i(Object? v, [int fallback = 0]) => v == null ? fallback : (v as num).round();
int? _in(Object? v) => v == null ? null : (v as num).round();
String _s(Object? v, [String fallback = '']) => v == null ? fallback : v as String;

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
      'created_at': _iso(m.createdAt),
      'updated_at': _iso(m.updatedAt),
      'deleted_at': null, // an edit always (re)activates the row
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
      'workout_id': s.workoutId,
      'name': s.name,
      'workout_date': _iso(s.workoutDate), // when the user trained — never `created_at`
      'duration_seconds': s.durationSeconds,
      'exercises': [
        for (final l in s.exercises)
          {
            'exerciseId': l.exerciseId,
            'sets': [
              for (final st in l.sets) {'weightKg': st.weightKg, 'reps': st.reps, 'done': st.done, 'rpe': st.rpe},
            ],
          },
      ],
      'cardio': s.cardio == null ? null : _cardioJson(s.cardio!),
      'notes': s.notes,
    };

WorkoutSession sessionFromRow(Row r) => WorkoutSession(
      id: _s(r['id']),
      workoutId: _s(r['workout_id']),
      name: _s(r['name']),
      workoutDate: _dt(r['workout_date']),
      durationSeconds: _i(r['duration_seconds']),
      exercises: [
        for (final l in (r['exercises'] as List? ?? const []))
          ExerciseLog(exerciseId: _s((l as Map)['exerciseId']), sets: [
            for (final st in (l['sets'] as List? ?? const []))
              SetLog(
                weightKg: _d((st as Map)['weightKg']),
                reps: _i(st['reps']),
                done: st['done'] as bool? ?? true,
                rpe: _dn(st['rpe']),
              ),
          ]),
      ],
      cardio: r['cardio'] == null ? null : _cardioFromJson((r['cardio'] as Map).cast<String, dynamic>()),
      notes: _s(r['notes']),
      meta: metaFromRow(r),
    );

// Cardio embedded inside a strength session (camelCase JSON, not a table row).
Map<String, dynamic> _cardioJson(CardioSession c) => {
      'id': c.id,
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
      'routeName': c.routeName,
      'notes': c.notes,
      'customActivityId': c.customActivityId,
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
      meta: SyncMeta(createdAt: _dt(j['createdAt']), updatedAt: _dt(j['updatedAt']), syncStatus: SyncStatus.synced),
    );

// ── cardio sessions ──
Row cardioToRow(CardioSession c) => {
      ..._common(c.meta, id: c.id),
      'kind': c.kind.name,
      'workout_date': _iso(c.workoutDate),
      'duration_seconds': c.durationSeconds,
      'distance_km': c.distanceKm,
      'speed_kmh': c.speedKmh,
      'incline_pct': c.inclinePct,
      'resistance': c.resistance,
      'calories': c.calories,
      'avg_heart_rate': c.avgHeartRate,
      'rpe': c.rpe,
      'route_name': c.routeName,
      'notes': c.notes,
      'custom_activity_id': c.customActivityId,
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
      'title': g.title,
      'metric': g.metric.name,
      'target': g.target,
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
      'name': a.name,
      'category': a.category,
      'icon_key': a.iconKey,
      'fields': [for (final f in a.fields) f.name],
      'round_seconds': a.roundSeconds,
      'rest_seconds': a.restSeconds,
      'rounds': a.rounds,
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
Row exerciseToRow(Exercise e) => {
      ..._common(e.meta, id: e.id),
      'name': e.name,
      'primary_muscle': e.primaryMuscle.name,
      'secondary_muscles': [for (final m in e.secondaryMuscles) m.name],
      'equipment': e.equipment.name,
      'movement_pattern': e.movementPattern,
      'instructions': [
        for (final s in e.instructions) {'title': s.title, 'text': s.text},
      ],
      'is_custom': e.isCustom,
      'tempo': e.tempo,
    };

Exercise exerciseFromRow(Row r) => Exercise(
      id: _s(r['id']),
      name: _s(r['name']),
      primaryMuscle: _enum(MuscleGroup.values, r['primary_muscle'], MuscleGroup.chest),
      secondaryMuscles: _enums(MuscleGroup.values, r['secondary_muscles']),
      equipment: _enum(Equipment.values, r['equipment'], Equipment.bodyweight),
      movementPattern: _s(r['movement_pattern']),
      instructions: [
        for (final s in (r['instructions'] as List? ?? const [])) ExerciseStep(_s((s as Map)['title']), _s(s['text'])),
      ],
      isCustom: r['is_custom'] as bool? ?? true,
      tempo: r['tempo'] as String?,
      meta: metaFromRow(r),
    );

// ── workouts ──
Row workoutToRow(Workout w, int position) => {
      ..._common(w.meta, id: w.id),
      'name': w.name,
      'description': w.description,
      'position': position,
      'exercises': [
        for (final e in w.exercises) {'exerciseId': e.exerciseId, 'sets': e.sets, 'repMin': e.repMin, 'repMax': e.repMax},
      ],
      'rest_seconds': w.restSeconds,
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
      restSeconds: _i(r['rest_seconds'], 90),
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
Row rotationToRow(Rotation r, {required DateTime createdAt, required DateTime updatedAt}) => {
      'workout_ids': r.workoutIds,
      'current_index': r.currentIndex,
      'created_at': _iso(createdAt),
      'updated_at': _iso(updatedAt),
      'deleted_at': null,
    };

Rotation rotationFromRow(Row r) => Rotation(
      workoutIds: [for (final w in (r['workout_ids'] as List? ?? const [])) w as String],
      currentIndex: _i(r['current_index']),
    );

// ── profile (singleton). Credentials never exist locally, so none are synced. ──
Row profileToRow(UserProfile p, {required DateTime updatedAt}) => {
      'name': p.name,
      if (p.email.isNotEmpty) 'email': p.email,
      'weight_kg': p.weightKg,
      'height_cm': p.heightCm,
      'age': p.age,
      'unit': p.unit.name,
      'theme_mode': p.themeMode.name,
      'default_sets': p.defaultSets,
      'default_rep_min': p.defaultRepMin,
      'default_rep_max': p.defaultRepMax,
      'auto_rest_seconds': p.autoRestSeconds,
      'progression_enabled': p.progressionEnabled,
      'weekly_session_target': p.weeklySessionTarget,
      'cardio_distance_unit_km': p.cardioDistanceUnitKm,
      'created_at': _iso(updatedAt),
      'updated_at': _iso(updatedAt),
      'deleted_at': null,
    };

/// Applies a cloud profile over [base] (keeps local-only fields). A profile that
/// exists in the cloud belongs to a real account, so `isGuest` becomes false.
UserProfile profileFromRow(Row r, UserProfile base) => base.copyWith(
      name: _s(r['name'], base.name),
      email: r['email'] == null ? base.email : r['email'] as String,
      isGuest: false,
      weightKg: _d(r['weight_kg'], base.weightKg),
      heightCm: _d(r['height_cm'], base.heightCm),
      age: _i(r['age'], base.age),
      unit: _enum(WeightUnit.values, r['unit'], base.unit),
      themeMode: _enum(SxThemeMode.values, r['theme_mode'], base.themeMode),
      defaultSets: _i(r['default_sets'], base.defaultSets),
      defaultRepMin: _i(r['default_rep_min'], base.defaultRepMin),
      defaultRepMax: _i(r['default_rep_max'], base.defaultRepMax),
      autoRestSeconds: _i(r['auto_rest_seconds'], base.autoRestSeconds),
      progressionEnabled: r['progression_enabled'] as bool? ?? base.progressionEnabled,
      weeklySessionTarget: _i(r['weekly_session_target'], base.weeklySessionTarget),
      cardioDistanceUnitKm: r['cardio_distance_unit_km'] as bool? ?? base.cardioDistanceUnitKm,
    );
