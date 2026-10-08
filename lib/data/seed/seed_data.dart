import '../../domain/domain.dart';
import 'seed_catalog.dart';

/// MOCK DATA. Everything here is generated relative to "now" so the demo
/// always looks current. None of it is persisted. A real Isar-backed store
/// must replace the in-memory repositories; see docs roadmap §0/§H.
/// Seed rows are "clean": never uploaded to the cloud, and (epoch `updatedAt`) always lose
/// to a real cloud copy, so a fresh install can never overwrite a user's edited routines.
SyncMeta _clean([DateTime? createdAt]) => SyncMeta(
  createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  syncStatus: SyncStatus.synced,
);

/// Demo sessions/cardio use this id prefix (`seed_s3`, `seed_c1`): the persistent "this is demo
/// data" marker. Real rows never start with it (they are uuid/timestamp based).
const kDemoIdPrefix = 'seed_';
bool isDemoId(String id) => id.startsWith(kDemoIdPrefix);

class SeedData {
  SeedData({
    required this.exercises,
    required this.workouts,
    required this.rotation,
    required this.sessions,
    required this.cardio,
    required this.goals,
  });

  final List<Exercise> exercises;
  final List<Workout> workouts;
  final Rotation rotation;
  final List<WorkoutSession> sessions;
  final List<CardioSession> cardio;
  final List<CardioGoal> goals;

  /// Ids of the goals [demo] adds (kept as-is: tests/screens reference them). They are not removed by
  /// "remove demo data" (goals hold no history) and do not count as user data.
  static const demoGoalIds = {'g_week', 'g_km', 'g_freq'};

  static List<Workout> defaultWorkouts() => [
    Workout(
      id: 'w1',
      meta: _clean(),
      name: 'Chest + Biceps',
      description: 'Upper hypertrophy split · Target RPE 8.0',
      exercises: const [
        RoutineExercise(
          exerciseId: 'bench_press',
          sets: 3,
          repMin: 6,
          repMax: 10,
        ),
        RoutineExercise(
          exerciseId: 'incline_db_press',
          sets: 3,
          repMin: 8,
          repMax: 12,
        ),
        RoutineExercise(
          exerciseId: 'cable_fly',
          sets: 3,
          repMin: 10,
          repMax: 15,
        ),
        RoutineExercise(
          exerciseId: 'barbell_curl',
          sets: 3,
          repMin: 8,
          repMax: 12,
        ),
        RoutineExercise(
          exerciseId: 'hammer_curl',
          sets: 3,
          repMin: 10,
          repMax: 12,
        ),
      ],
      cardioFinisher: const CardioTarget(
        kind: CardioKind.treadmill,
        durationMinutes: 20,
        speedKmh: 7.5,
        inclinePct: 3,
      ),
    ),
    Workout(
      id: 'w2',
      meta: _clean(),
      name: 'Back + Triceps',
      description: 'Upper hypertrophy split · Target RPE 8.0',
      exercises: const [
        RoutineExercise(
          exerciseId: 'lat_pulldown',
          sets: 3,
          repMin: 8,
          repMax: 12,
        ),
        RoutineExercise(
          exerciseId: 'seated_cable_row',
          sets: 3,
          repMin: 8,
          repMax: 12,
        ),
        RoutineExercise(
          exerciseId: 'one_arm_cable_row',
          sets: 3,
          repMin: 10,
          repMax: 12,
        ),
        RoutineExercise(
          exerciseId: 'tricep_pushdown',
          sets: 3,
          repMin: 10,
          repMax: 12,
        ),
        RoutineExercise(
          exerciseId: 'overhead_tri_ext',
          sets: 3,
          repMin: 10,
          repMax: 12,
        ),
        RoutineExercise(
          exerciseId: 'face_pull',
          sets: 3,
          repMin: 12,
          repMax: 15,
        ),
      ],
    ),
    Workout(
      id: 'w3',
      meta: _clean(),
      name: 'Legs + Shoulders',
      description: 'Squat & Overhead Press focus',
      exercises: const [
        RoutineExercise(
          exerciseId: 'back_squat',
          sets: 3,
          repMin: 5,
          repMax: 8,
        ),
        RoutineExercise(
          exerciseId: 'overhead_press',
          sets: 3,
          repMin: 6,
          repMax: 10,
        ),
        RoutineExercise(
          exerciseId: 'leg_press',
          sets: 3,
          repMin: 8,
          repMax: 12,
        ),
        RoutineExercise(exerciseId: 'rdl', sets: 3, repMin: 8, repMax: 10),
        RoutineExercise(
          exerciseId: 'lateral_raise',
          sets: 3,
          repMin: 12,
          repMax: 15,
        ),
        RoutineExercise(
          exerciseId: 'calf_raise',
          sets: 3,
          repMin: 12,
          repMax: 15,
        ),
      ],
    ),
  ];

  /// Empty account: catalog + default 3-day rotation, no history.
  factory SeedData.fresh() {
    final w = defaultWorkouts();
    return SeedData(
      exercises: seedExercises(),
      workouts: w,
      rotation: Rotation(workoutIds: [for (final x in w) x.id]),
      sessions: [],
      cardio: [],
      goals: [],
    );
  }

  /// Demo account with ~8 weeks of history. Rotation points at Day 2 because the
  /// newest generated session is Day 1.
  factory SeedData.demo([DateTime? now]) {
    now ??= DateTime.now();
    final base = SeedData.fresh();
    final w = base.workouts;
    final today = DateTime(now.year, now.month, now.day);
    const baseKg = <String, double>{
      'bench_press': 80,
      'incline_db_press': 30,
      'cable_fly': 15,
      'barbell_curl': 30,
      'hammer_curl': 14,
      'lat_pulldown': 45,
      'seated_cable_row': 55,
      'one_arm_cable_row': 22.5,
      'tricep_pushdown': 27.5,
      'overhead_tri_ext': 20,
      'face_pull': 17.5,
      'back_squat': 95,
      'overhead_press': 50,
      'leg_press': 150,
      'rdl': 80,
      'lateral_raise': 8,
      'calf_raise': 60,
    };
    double r(double v) => (v / 2.5).round() * 2.5;
    final sessions = <WorkoutSession>[];
    const count = 22;
    var daysBack = 1;
    for (var i = 0; i < count; i++) {
      final w0 = w[(3 - (i % 3)) % 3]; // i=0 → w1, i=1 → w3, i=2 → w2 ...
      final idx = i; // 0 = newest
      final date = today
          .subtract(Duration(days: daysBack))
          .add(const Duration(hours: 10, minutes: 45));
      final progress = (count - 1 - idx) / (count - 1); // 0 oldest → 1 newest
      final logs = <ExerciseLog>[];
      for (final re in w0.exercises) {
        final start = baseKg[re.exerciseId] ?? 20;
        final kg = r(start * (0.85 + 0.15 * progress));
        final reps = [re.repMax, re.repMax - 1, re.repMax - 2];
        logs.add(
          ExerciseLog(
            exerciseId: re.exerciseId,
            sets: [
              for (var s = 0; s < re.sets; s++)
                SetLog(
                  weightKg: s == 2 && idx % 2 == 0 ? r(kg + 2.5) : kg,
                  reps: (reps[s] - (idx % 3 == 0 ? 0 : 1)).clamp(
                    re.repMin,
                    re.repMax,
                  ),
                ),
            ],
          ),
        );
      }
      sessions.add(
        WorkoutSession(
          id: 'seed_s$i',
          workoutId: w0.id,
          name: w0.name,
          workoutDate: date,
          exercises: logs,
          durationSeconds: (50 + (i * 7) % 20) * 60,
          meta: _clean(date),
        ),
      );
      daysBack += (i % 4 == 3) ? 3 : 2;
    }
    final cardio = <CardioSession>[];
    final plan = [
      (CardioKind.outdoorRun, 1, 32 * 60 + 18, 5.2, 'Riverside Loop'),
      (CardioKind.cycling, 3, 45 * 60, 12.8, ''),
      (CardioKind.treadmill, 5, 25 * 60, 3.4, ''),
      (CardioKind.outdoorRun, 8, 30 * 60, 5.0, 'Riverside Loop'),
      (CardioKind.rowing, 10, 20 * 60, 4.8, ''),
      (CardioKind.outdoorRun, 14, 34 * 60, 5.2, 'Riverside Loop'),
      (CardioKind.treadmill, 17, 30 * 60, 4.0, ''),
      (CardioKind.outdoorRun, 22, 48 * 60, 8.0, 'Harbour Path'),
      (CardioKind.cycling, 28, 60 * 60, 17.5, ''),
      (CardioKind.outdoorRun, 33, 31 * 60, 5.0, 'Riverside Loop'),
    ];
    for (var i = 0; i < plan.length; i++) {
      final p = plan[i];
      final date = today
          .subtract(Duration(days: p.$2))
          .add(const Duration(hours: 7, minutes: 15));
      cardio.add(
        CardioSession(
          id: 'seed_c$i',
          kind: p.$1,
          workoutDate: date,
          durationSeconds: p.$3,
          distanceKm: p.$4,
          inclinePct: p.$1 == CardioKind.treadmill ? 3 : null,
          resistance: p.$1 == CardioKind.rowing ? 6 : null,
          routeName: p.$5,
          meta: _clean(date),
        ),
      );
    }
    return SeedData(
      exercises: base.exercises,
      workouts: w,
      rotation: const Rotation(workoutIds: ['w1', 'w2', 'w3'], currentIndex: 1),
      sessions: sessions,
      cardio: cardio,
      goals: [
        CardioGoal(
          id: 'g_week',
          title: 'Weekly Aerobic Duration',
          metric: GoalMetric.durationMinutes,
          target: 150,
          isPrimary: true,
          meta: _clean(),
        ),
        CardioGoal(
          id: 'g_km',
          title: 'Weekly Running Distance',
          metric: GoalMetric.distanceKm,
          target: 25,
          meta: _clean(),
        ),
        CardioGoal(
          id: 'g_freq',
          title: 'Cardio Frequency',
          metric: GoalMetric.sessions,
          target: 4,
          meta: _clean(),
        ),
      ],
    );
  }
}
