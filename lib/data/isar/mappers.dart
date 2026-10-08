import '../../domain/domain.dart';
import 'entities.dart';

/// Domain ⇄ Isar entity mapping. All persistence-shape knowledge lives here.

MetaEmb metaToEmb(SyncMeta m) => MetaEmb()
  ..createdAt = m.createdAt
  ..updatedAt = m.updatedAt
  ..syncStatus = m.syncStatus;

SyncMeta metaFromEmb(MetaEmb m) => SyncMeta(
  createdAt: m.createdAt,
  updatedAt: m.updatedAt,
  syncStatus: m.syncStatus,
);

// ── Exercise ──
ExerciseEntity exerciseToEntity(Exercise e) => ExerciseEntity()
  ..uid = e.id
  ..name = e.name
  ..primaryMuscle = e.primaryMuscle
  ..secondaryMuscles = [...e.secondaryMuscles]
  ..equipment = e.equipment
  ..movementPattern = e.movementPattern
  ..instructions = [
    for (final s in e.instructions)
      StepEmb()
        ..title = s.title
        ..text = s.text,
  ]
  ..isCustom = e.isCustom
  ..tempo = e.tempo
  ..muscleTargetsJson = MuscleTargetCodec.encode(e.muscleTargets)
  ..meta = metaToEmb(e.meta);

Exercise exerciseFromEntity(ExerciseEntity e) => Exercise(
  id: e.uid,
  name: e.name,
  primaryMuscle: e.primaryMuscle,
  secondaryMuscles: [...e.secondaryMuscles],
  equipment: e.equipment,
  movementPattern: e.movementPattern,
  instructions: [for (final s in e.instructions) ExerciseStep(s.title, s.text)],
  isCustom: e.isCustom,
  tempo: e.tempo,
  muscleTargets: MuscleTargetCodec.decode(e.muscleTargetsJson),
  meta: metaFromEmb(e.meta),
);

// ── Workout / rotation ──
CardioTargetEmb targetToEmb(CardioTarget t) => CardioTargetEmb()
  ..kind = t.kind
  ..durationMinutes = t.durationMinutes
  ..distanceKm = t.distanceKm
  ..speedKmh = t.speedKmh
  ..inclinePct = t.inclinePct
  ..resistance = t.resistance;

CardioTarget targetFromEmb(CardioTargetEmb t) => CardioTarget(
  kind: t.kind,
  durationMinutes: t.durationMinutes,
  distanceKm: t.distanceKm,
  speedKmh: t.speedKmh,
  inclinePct: t.inclinePct,
  resistance: t.resistance,
);

WorkoutEntity workoutToEntity(Workout w, int position) => WorkoutEntity()
  ..uid = w.id
  ..position = position
  ..name = w.name
  ..description = w.description
  ..exercises = [
    for (final e in w.exercises)
      RoutineExerciseEmb()
        ..exerciseId = e.exerciseId
        ..sets = e.sets
        ..repMin = e.repMin
        ..repMax = e.repMax,
  ]
  ..restSeconds = w.restSeconds
  ..cardioFinisher = w.cardioFinisher == null
      ? null
      : targetToEmb(w.cardioFinisher!)
  ..meta = metaToEmb(w.meta);

Workout workoutFromEntity(WorkoutEntity w) => Workout(
  id: w.uid,
  name: w.name,
  description: w.description,
  exercises: [
    for (final e in w.exercises)
      RoutineExercise(
        exerciseId: e.exerciseId,
        sets: e.sets,
        repMin: e.repMin,
        repMax: e.repMax,
      ),
  ],
  restSeconds: w.restSeconds,
  cardioFinisher: w.cardioFinisher == null
      ? null
      : targetFromEmb(w.cardioFinisher!),
  meta: metaFromEmb(w.meta),
);

RotationEntity rotationToEntity(Rotation r) => RotationEntity()
  ..workoutIds = [...r.workoutIds]
  ..currentIndex = r.currentIndex;

Rotation rotationFromEntity(RotationEntity r) =>
    Rotation(workoutIds: [...r.workoutIds], currentIndex: r.currentIndex);

// ── Cardio ──
CardioSessionEmb cardioToEmb(CardioSession s) => CardioSessionEmb()
  ..uid = s.id
  ..kind = s.kind
  ..workoutDate = s.workoutDate
  ..durationSeconds = s.durationSeconds
  ..distanceKm = s.distanceKm
  ..speedKmh = s.speedKmh
  ..inclinePct = s.inclinePct
  ..resistance = s.resistance
  ..calories = s.calories
  ..avgHeartRate = s.avgHeartRate
  ..rpe = s.rpe
  ..routeName = s.routeName
  ..notes = s.notes
  ..customActivityId = s.customActivityId
  ..meta = metaToEmb(s.meta);

CardioSession cardioFromEmb(CardioSessionEmb s) => CardioSession(
  id: s.uid,
  kind: s.kind,
  workoutDate: s.workoutDate,
  durationSeconds: s.durationSeconds,
  distanceKm: s.distanceKm,
  speedKmh: s.speedKmh,
  inclinePct: s.inclinePct,
  resistance: s.resistance,
  calories: s.calories,
  avgHeartRate: s.avgHeartRate,
  rpe: s.rpe,
  routeName: s.routeName,
  notes: s.notes,
  customActivityId: s.customActivityId,
  meta: metaFromEmb(s.meta),
);

CardioSessionEntity cardioToEntity(CardioSession s) => CardioSessionEntity()
  ..uid = s.id
  ..workoutDate = s.workoutDate
  ..data = cardioToEmb(s);

CardioSession cardioFromEntity(CardioSessionEntity e) => cardioFromEmb(e.data);

CardioGoalEntity goalToEntity(CardioGoal g) => CardioGoalEntity()
  ..uid = g.id
  ..title = g.title
  ..metric = g.metric
  ..target = g.target
  ..period = g.period
  ..isPrimary = g.isPrimary
  ..meta = metaToEmb(g.meta);

CardioGoal goalFromEntity(CardioGoalEntity g) => CardioGoal(
  id: g.uid,
  title: g.title,
  metric: g.metric,
  target: g.target,
  period: g.period,
  isPrimary: g.isPrimary,
  meta: metaFromEmb(g.meta),
);

CustomActivityEntity customActivityToEntity(CustomCardioActivity a) =>
    CustomActivityEntity()
      ..uid = a.id
      ..name = a.name
      ..category = a.category
      ..iconKey = a.iconKey
      ..fields = [...a.fields]
      ..roundSeconds = a.roundSeconds
      ..restSeconds = a.restSeconds
      ..rounds = a.rounds
      ..meta = metaToEmb(a.meta);

CustomCardioActivity customActivityFromEntity(CustomActivityEntity a) =>
    CustomCardioActivity(
      id: a.uid,
      name: a.name,
      category: a.category,
      iconKey: a.iconKey,
      fields: [...a.fields],
      roundSeconds: a.roundSeconds,
      restSeconds: a.restSeconds,
      rounds: a.rounds,
      meta: metaFromEmb(a.meta),
    );

// ── Strength sessions ──
SessionEntity sessionToEntity(WorkoutSession s) => SessionEntity()
  ..uid = s.id
  ..workoutId = s.workoutId
  ..name = s.name
  ..workoutDate = s.workoutDate
  ..exercises = [
    for (final l in s.exercises)
      ExerciseLogEmb()
        ..exerciseId = l.exerciseId
        ..sets = [
          for (final st in l.sets)
            SetLogEmb()
              ..weightKg = st.weightKg
              ..reps = st.reps
              ..done = st.done
              ..rpe = st.rpe,
        ],
  ]
  ..durationSeconds = s.durationSeconds
  ..cardio = s.cardio == null ? null : cardioToEmb(s.cardio!)
  ..notes = s.notes
  ..meta = metaToEmb(s.meta);

WorkoutSession sessionFromEntity(SessionEntity s) => WorkoutSession(
  id: s.uid,
  workoutId: s.workoutId,
  name: s.name,
  workoutDate: s.workoutDate,
  exercises: [
    for (final l in s.exercises)
      ExerciseLog(
        exerciseId: l.exerciseId,
        sets: [
          for (final st in l.sets)
            SetLog(
              weightKg: st.weightKg,
              reps: st.reps,
              done: st.done,
              rpe: st.rpe,
            ),
        ],
      ),
  ],
  durationSeconds: s.durationSeconds,
  cardio: s.cardio == null ? null : cardioFromEmb(s.cardio!),
  notes: s.notes,
  meta: metaFromEmb(s.meta),
);

// ── Profile ──
ProfileEntity profileToEntity(UserProfile p) => ProfileEntity()
  ..name = p.name
  ..email = p.email
  ..isGuest = p.isGuest
  ..weightKg = p.weightKg
  ..heightCm = p.heightCm
  ..age = p.age
  ..unit = p.unit
  ..themeMode = p.themeMode
  ..defaultSets = p.defaultSets
  ..defaultRepMin = p.defaultRepMin
  ..defaultRepMax = p.defaultRepMax
  ..autoRestSeconds = p.autoRestSeconds
  ..progressionEnabled = p.progressionEnabled
  ..weeklySessionTarget = p.weeklySessionTarget
  ..cardioDistanceUnitKm = p.cardioDistanceUnitKm;

UserProfile profileFromEntity(ProfileEntity p) => UserProfile(
  name: p.name,
  email: p.email,
  isGuest: p.isGuest,
  weightKg: p.weightKg,
  heightCm: p.heightCm,
  age: p.age,
  unit: p.unit,
  themeMode: p.themeMode,
  defaultSets: p.defaultSets,
  defaultRepMin: p.defaultRepMin,
  defaultRepMax: p.defaultRepMax,
  autoRestSeconds: p.autoRestSeconds,
  progressionEnabled: p.progressionEnabled,
  weeklySessionTarget: p.weeklySessionTarget,
  cardioDistanceUnitKm: p.cardioDistanceUnitKm,
);
