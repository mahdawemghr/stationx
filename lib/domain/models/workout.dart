import 'cardio.dart';
import 'sync_meta.dart';

/// One exercise slot inside a routine day.
class RoutineExercise {
  const RoutineExercise({
    required this.exerciseId,
    this.sets = 3,
    this.repMin = 8,
    this.repMax = 12,
  });

  final String exerciseId;
  final int sets;
  final int repMin;
  final int repMax;

  RoutineExercise copyWith({
    String? exerciseId,
    int? sets,
    int? repMin,
    int? repMax,
  }) => RoutineExercise(
    exerciseId: exerciseId ?? this.exerciseId,
    sets: sets ?? this.sets,
    repMin: repMin ?? this.repMin,
    repMax: repMax ?? this.repMax,
  );
}

/// A workout "day" in the rotation (e.g. "Back + Triceps").
class Workout {
  Workout({
    required this.id,
    required this.name,
    this.description = '',
    this.exercises = const [],
    this.restSeconds = 90,
    this.cardioFinisher,
    SyncMeta? meta,
  }) : meta = meta ?? SyncMeta();

  final String id;
  final String name;
  final String description;
  final List<RoutineExercise> exercises;
  final int restSeconds;

  /// Optional cardio block that follows the strength work (mixed workout).
  final CardioTarget? cardioFinisher;
  final SyncMeta meta;

  int get totalSets => exercises.fold(0, (a, e) => a + e.sets);

  /// ~3 min per working set incl. rest — UI estimate only.
  int get estimatedMinutes => (totalSets * 3).clamp(0, 600);

  Workout copyWith({
    String? name,
    String? description,
    List<RoutineExercise>? exercises,
    int? restSeconds,
    CardioTarget? cardioFinisher,
    bool clearCardio = false,
  }) => Workout(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    exercises: exercises ?? this.exercises,
    restSeconds: restSeconds ?? this.restSeconds,
    cardioFinisher: clearCardio
        ? null
        : (cardioFinisher ?? this.cardioFinisher),
    meta: meta.touched(),
  );
}

/// Sequential rotation. The *index* — not the calendar — decides the next
/// workout. Never auto-advanced by dates.
class Rotation {
  const Rotation({required this.workoutIds, this.currentIndex = 0});
  final List<String> workoutIds;
  final int currentIndex;

  String? get currentWorkoutId =>
      workoutIds.isEmpty ? null : workoutIds[currentIndex % workoutIds.length];
  String? get nextWorkoutId => workoutIds.isEmpty
      ? null
      : workoutIds[(currentIndex + 1) % workoutIds.length];
  int get length => workoutIds.length;

  Rotation copyWith({List<String>? workoutIds, int? currentIndex}) => Rotation(
    workoutIds: workoutIds ?? this.workoutIds,
    currentIndex: currentIndex ?? this.currentIndex,
  );
}

class SetLog {
  const SetLog({
    required this.weightKg,
    required this.reps,
    this.done = true,
    this.rpe,
  });
  final double weightKg;
  final int reps;
  final bool done;
  final double? rpe;

  double get volume => weightKg * reps;

  SetLog copyWith({double? weightKg, int? reps, bool? done, double? rpe}) =>
      SetLog(
        weightKg: weightKg ?? this.weightKg,
        reps: reps ?? this.reps,
        done: done ?? this.done,
        rpe: rpe ?? this.rpe,
      );
}

class ExerciseLog {
  const ExerciseLog({required this.exerciseId, required this.sets});
  final String exerciseId;
  final List<SetLog> sets;

  Iterable<SetLog> get doneSets => sets.where((s) => s.done && s.reps > 0);
  double get volume => doneSets.fold(0.0, (a, s) => a + s.volume);
}

/// A completed strength session (history entry).
///
/// [workoutDate] is *when the user trained* (editable / backdatable);
/// `meta.createdAt` is *when the record was entered*. Never conflate them.
class WorkoutSession {
  WorkoutSession({
    required this.id,
    required this.workoutId,
    required this.name,
    required this.workoutDate,
    required this.exercises,
    this.durationSeconds = 0,
    this.cardio,
    this.notes = '',
    SyncMeta? meta,
  }) : meta = meta ?? SyncMeta();

  final String id;
  final String workoutId;
  final String name;
  final DateTime workoutDate;
  final List<ExerciseLog> exercises;
  final int durationSeconds;

  /// Cardio finisher performed in the same session (mixed workout).
  final CardioSession? cardio;
  final String notes;
  final SyncMeta meta;

  double get volume => exercises.fold(0.0, (a, e) => a + e.volume);
  int get doneSets => exercises.fold(0, (a, e) => a + e.doneSets.length);
}
