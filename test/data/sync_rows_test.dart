import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/sync/sync_rows.dart';
import 'package:stationx/domain/domain.dart';

/// Rows travel as JSON (PostgREST): always round-trip through encode/decode.
Map<String, dynamic> wire(Map<String, dynamic> row) => jsonDecode(jsonEncode(row)) as Map<String, dynamic>;

void main() {
  final created = DateTime.utc(2026, 10, 7, 9, 0);
  final updated = DateTime.utc(2026, 10, 8, 12, 30, 15, 123, 456);
  final meta = SyncMeta(createdAt: created, updatedAt: updated);

  test('strength session round-trips; workout_date and created_at stay separate; nested cardio kept', () {
    final trained = DateTime.utc(2024, 3, 1, 18, 30);
    final s = WorkoutSession(
      id: 's1',
      workoutId: 'w2',
      name: 'Back + Triceps',
      workoutDate: trained,
      durationSeconds: 3300,
      notes: 'felt good',
      exercises: const [
        ExerciseLog(exerciseId: 'lat_pulldown', sets: [
          SetLog(weightKg: 50, reps: 8),
          SetLog(weightKg: 47.5, reps: 10, rpe: 8.5),
          SetLog(weightKg: 45, reps: 0, done: false),
        ]),
      ],
      cardio: CardioSession(
          id: 'c-in',
          kind: CardioKind.treadmill,
          workoutDate: trained,
          durationSeconds: 1200,
          distanceKm: 2.5,
          speedKmh: 7.5,
          inclinePct: 3,
          meta: meta),
      meta: meta,
    );
    final row = wire(sessionToRow(s));
    expect(row['workout_date'], '2024-03-01T18:30:00.000Z');
    expect(row['created_at'], '2026-10-07T09:00:00.000Z');
    expect(row['deleted_at'], isNull);
    final back = sessionFromRow(row);
    expect(back.workoutDate, trained);
    expect(back.meta.createdAt, created);
    expect(back.meta.updatedAt, updated);
    expect(back.meta.syncStatus, SyncStatus.synced); // came from the cloud ⇒ in sync
    expect(back.exercises.single.sets[1].rpe, 8.5);
    expect(back.exercises.single.sets[2].done, isFalse);
    expect(back.durationSeconds, 3300);
    expect(back.notes, 'felt good');
    expect(back.cardio!.kind, CardioKind.treadmill);
    expect(back.cardio!.inclinePct, 3);
    expect(back.volume, s.volume);
  });

  test('cardio session round-trips incl. optional fields', () {
    final c = CardioSession(
        id: 'c1',
        kind: CardioKind.stationaryBike,
        workoutDate: DateTime.utc(2026, 9, 10, 7, 15),
        durationSeconds: 1938,
        distanceKm: 5.2,
        resistance: 8,
        calories: 324,
        avgHeartRate: 144,
        rpe: 7.5,
        routeName: 'Loop',
        notes: 'n',
        customActivityId: 'a1',
        meta: meta);
    final b = cardioFromRow(wire(cardioToRow(c)));
    expect(b.kind, c.kind);
    expect(b.workoutDate, c.workoutDate);
    expect((b.distanceKm, b.resistance, b.calories, b.avgHeartRate, b.rpe), (5.2, 8, 324, 144, 7.5));
    expect((b.routeName, b.notes, b.customActivityId), ('Loop', 'n', 'a1'));
    expect(b.speedKmh, isNull);
    // Postgres returns numeric as number — ints must be accepted for doubles.
    final r = wire(cardioToRow(c))..['distance_km'] = 6;
    expect(cardioFromRow(r).distanceKm, 6.0);
  });

  test('goal, custom activity, custom exercise round-trip', () {
    final g = goalFromRow(wire(goalToRow(CardioGoal(id: 'g', title: 'Weekly', metric: GoalMetric.distanceKm, target: 25, period: GoalPeriod.month, isPrimary: true, meta: meta))));
    expect((g.title, g.metric, g.target, g.period, g.isPrimary), ('Weekly', GoalMetric.distanceKm, 25.0, GoalPeriod.month, true));
    final a = customActivityFromRow(wire(customActivityToRow(CustomCardioActivity(
        id: 'a', name: 'Boxing', fields: const [CardioField.duration, CardioField.heartRate], roundSeconds: 180, restSeconds: 60, rounds: 5, meta: meta))));
    expect((a.name, a.roundSeconds, a.restSeconds, a.rounds), ('Boxing', 180, 60, 5));
    expect(a.fields, [CardioField.duration, CardioField.heartRate]);
    final e = exerciseFromRow(wire(exerciseToRow(Exercise(
        id: 'x',
        name: 'My Press',
        primaryMuscle: MuscleGroup.shoulders,
        secondaryMuscles: const [MuscleGroup.triceps],
        equipment: Equipment.dumbbell,
        movementPattern: 'Vertical push',
        instructions: const [ExerciseStep('Setup', 'Stand tall')],
        isCustom: true,
        tempo: '3-0-1-0',
        meta: meta))));
    expect((e.name, e.primaryMuscle, e.equipment, e.tempo), ('My Press', MuscleGroup.shoulders, Equipment.dumbbell, '3-0-1-0'));
    expect(e.secondaryMuscles, [MuscleGroup.triceps]);
    expect(e.instructions.single.title, 'Setup');
  });

  test('workout round-trips with order and cardio finisher; rotation + profile singletons', () {
    final w = Workout(
      id: 'w1',
      name: 'Chest + Biceps',
      description: 'desc',
      restSeconds: 120,
      exercises: const [RoutineExercise(exerciseId: 'bench_press', sets: 4, repMin: 6, repMax: 10)],
      cardioFinisher: const CardioTarget(kind: CardioKind.treadmill, durationMinutes: 20, speedKmh: 7.5, inclinePct: 3),
      meta: meta,
    );
    final (b, pos) = workoutFromRow(wire(workoutToRow(w, 2)));
    expect(pos, 2);
    expect((b.name, b.restSeconds, b.exercises.single.sets, b.exercises.single.repMax), ('Chest + Biceps', 120, 4, 10));
    expect((b.cardioFinisher!.kind, b.cardioFinisher!.durationMinutes, b.cardioFinisher!.inclinePct), (CardioKind.treadmill, 20, 3.0));

    final rot = rotationFromRow(wire(rotationToRow(const Rotation(workoutIds: ['w1', 'w2', 'w3'], currentIndex: 2), createdAt: created, updatedAt: updated)));
    expect(rot.workoutIds, ['w1', 'w2', 'w3']);
    expect(rot.currentIndex, 2);

    const p = UserProfile(name: 'Sam', email: 'sam@x.io', isGuest: false, weightKg: 80, unit: WeightUnit.lb, themeMode: SxThemeMode.oled, autoRestSeconds: 120, weeklySessionTarget: 5, cardioDistanceUnitKm: false);
    final prow = wire(profileToRow(p, updatedAt: updated));
    expect(prow.containsKey('password'), isFalse);
    final pb = profileFromRow(prow, const UserProfile());
    expect((pb.name, pb.email, pb.isGuest, pb.weightKg, pb.unit, pb.themeMode, pb.autoRestSeconds, pb.weeklySessionTarget, pb.cardioDistanceUnitKm),
        ('Sam', 'sam@x.io', false, 80.0, WeightUnit.lb, SxThemeMode.oled, 120, 5, false));
  });

  test('unknown enum values from a newer app version never crash', () {
    final row = wire(cardioToRow(CardioSession(id: 'c', kind: CardioKind.rowing, workoutDate: created, durationSeconds: 60, meta: meta)))..['kind'] = 'swimmingFromTheFuture';
    expect(cardioFromRow(row).kind, CardioKind.custom);
    final g = wire(goalToRow(CardioGoal(id: 'g', title: 't', metric: GoalMetric.sessions, target: 1, meta: meta)))..['metric'] = 'vo2';
    expect(goalFromRow(g).metric, GoalMetric.durationMinutes);
  });

  test('profile from the cloud over a guest makes it a real account profile', () {
    final pb = profileFromRow({'name': 'Cloud Sam', 'unit': 'kg'}, const UserProfile(isGuest: true, name: 'Guest Athlete', weightKg: 99));
    expect((pb.isGuest, pb.name, pb.weightKg), (false, 'Cloud Sam', 99.0)); // missing columns keep local values
  });
}
