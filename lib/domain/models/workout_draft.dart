// Snapshot of a workout that is in progress, persisted locally so an OS kill
// (or a crash) does not lose it. Local-only: never synced, never uploaded.
//
// Pure data + JSON; the logger controller converts to/from its live state.

class DraftSet {
  const DraftSet({
    required this.weightKg,
    required this.reps,
    required this.done,
  });
  final double weightKg;
  final int reps;
  final bool done;

  Map<String, Object?> toJson() => {'w': weightKg, 'r': reps, 'd': done};
  factory DraftSet.fromJson(Map<String, Object?> j) => DraftSet(
    weightKg: (j['w'] as num?)?.toDouble() ?? 0,
    reps: (j['r'] as num?)?.toInt() ?? 0,
    done: j['d'] as bool? ?? false,
  );
}

class DraftExercise {
  const DraftExercise({
    required this.exerciseId,
    required this.repMin,
    required this.repMax,
    required this.sets,
    this.expanded = false,
    this.suggestionUsed = false,
  });
  final String exerciseId;
  final int repMin;
  final int repMax;
  final List<DraftSet> sets;
  final bool expanded;
  final bool suggestionUsed;

  Map<String, Object?> toJson() => {
    'e': exerciseId,
    'min': repMin,
    'max': repMax,
    'x': expanded,
    'su': suggestionUsed,
    's': [for (final s in sets) s.toJson()],
  };
  factory DraftExercise.fromJson(Map<String, Object?> j) => DraftExercise(
    exerciseId: j['e'] as String,
    repMin: (j['min'] as num?)?.toInt() ?? 8,
    repMax: (j['max'] as num?)?.toInt() ?? 12,
    expanded: j['x'] as bool? ?? false,
    suggestionUsed: j['su'] as bool? ?? false,
    sets: [
      for (final s in (j['s'] as List? ?? const []))
        DraftSet.fromJson((s as Map).cast<String, Object?>()),
    ],
  );
}

class WorkoutDraft {
  const WorkoutDraft({
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.savedAt,
    required this.exercises,
    this.currentIndex = 0,
    this.notes = '',
    this.backdate,
  });

  final String workoutId;

  /// Kept so the draft stays understandable if the workout was later deleted.
  final String workoutName;
  final DateTime startedAt;
  final DateTime savedAt;
  final List<DraftExercise> exercises;
  final int currentIndex;
  final String notes;

  /// Set for a backdated entry (the rotation is not advanced on finish).
  final DateTime? backdate;

  int get totalSets => exercises.fold(0, (a, e) => a + e.sets.length);
  int get doneSets =>
      exercises.fold(0, (a, e) => a + e.sets.where((s) => s.done).length);

  Map<String, Object?> toJson() => {
    'v': 1,
    'wid': workoutId,
    'wn': workoutName,
    'st': startedAt.toIso8601String(),
    'sv': savedAt.toIso8601String(),
    'ci': currentIndex,
    'n': notes,
    if (backdate != null) 'bd': backdate!.toIso8601String(),
    'ex': [for (final e in exercises) e.toJson()],
  };

  factory WorkoutDraft.fromJson(Map<String, Object?> j) => WorkoutDraft(
    workoutId: j['wid'] as String,
    workoutName: j['wn'] as String? ?? 'Workout',
    startedAt: DateTime.parse(j['st'] as String),
    savedAt: DateTime.parse(j['sv'] as String),
    currentIndex: (j['ci'] as num?)?.toInt() ?? 0,
    notes: j['n'] as String? ?? '',
    backdate: j['bd'] == null ? null : DateTime.parse(j['bd'] as String),
    exercises: [
      for (final e in (j['ex'] as List? ?? const []))
        DraftExercise.fromJson((e as Map).cast<String, Object?>()),
    ],
  );
}
