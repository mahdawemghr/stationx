import '../models/models.dart';
import '../repositories/repositories.dart';
import 'workout_completion.dart';
import 'workout_limit.dart';

/// Outcome of auto-ending a workout. Persisted (local-only) until the user has seen it.
class AutoEndResult {
  const AutoEndResult({
    required this.workoutName,
    required this.setsLogged,
    required this.savedSession,
    required this.endedAfter,
    this.sessionId,
  });
  final String workoutName;
  final int setsLogged;

  /// False when no set was done: nothing was saved and the draft was just discarded.
  final bool savedSession;
  final Duration endedAfter;
  final String? sessionId;

  Map<String, Object?> toJson() => {
        'wn': workoutName,
        'sl': setsLogged,
        'ss': savedSession,
        'ea': endedAfter.inSeconds,
        if (sessionId != null) 'id': sessionId,
      };
  static AutoEndResult? tryParse(Map<String, Object?> j) {
    try {
      return AutoEndResult(
        workoutName: j['wn'] as String? ?? 'Workout',
        setsLogged: (j['sl'] as num?)?.toInt() ?? 0,
        savedSession: j['ss'] as bool? ?? false,
        endedAfter: Duration(seconds: (j['ea'] as num?)?.toInt() ?? 0),
        sessionId: j['id'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Turns a persisted [WorkoutDraft] into a saved session. Mirrors the live logger finish
/// (`ActiveWorkoutController.buildSession` + `WorkoutCompletion.complete`) so an expired draft
/// completes exactly like a normal finish: only DONE sets are kept, `workoutDate` is the user's
/// date (backdate ?? start) while `createdAt` is [now], the rotation advances through
/// [WorkoutCompletion] (backdated drafts never advance it).
abstract final class DraftCompletion {
  /// Stable id derived from the draft, so retries / double calls never duplicate the session.
  static String sessionId(WorkoutDraft d) => 'ws_auto_${d.startedAt.microsecondsSinceEpoch}';

  /// Null when no set is done (nothing to save). [durationSeconds] defaults to the elapsed time
  /// from start to [now].
  static WorkoutSession? toSession(WorkoutDraft d, {required DateTime now, int? durationSeconds}) {
    final logs = <ExerciseLog>[];
    for (final e in d.exercises) {
      final sets = [
        for (final s in e.sets)
          if (s.done) SetLog(weightKg: s.weightKg, reps: s.reps),
      ];
      if (sets.isNotEmpty) logs.add(ExerciseLog(exerciseId: e.exerciseId, sets: sets));
    }
    if (logs.isEmpty) return null;
    return WorkoutSession(
      id: sessionId(d),
      workoutId: d.workoutId,
      name: d.workoutName,
      workoutDate: d.backdate ?? d.startedAt,
      exercises: logs,
      durationSeconds: durationSeconds ?? WorkoutLimit.elapsedSeconds(d.startedAt, now),
      meta: SyncMeta(createdAt: now),
    );
  }

  /// Saves the session (if any done set) and moves the rotation. Idempotent: an existing
  /// session with the derived id is not added again (and the rotation is not advanced twice).
  /// Does NOT clear the draft (the caller does, after this returns).
  static Future<AutoEndResult> complete(
    WorkoutDraft d, {
    required DateTime now,
    required int? maxMinutes,
    required SessionRepository sessions,
    required WorkoutRepository workouts,
  }) async {
    final capped = WorkoutLimit.cappedDuration(d.startedAt, now, maxMinutes);
    final session = toSession(d, now: now, durationSeconds: capped);
    final endedAfter = Duration(seconds: capped);
    if (session == null) {
      return AutoEndResult(workoutName: d.workoutName, setsLogged: 0, savedSession: false, endedAfter: endedAfter);
    }
    if (sessions.byId(session.id) == null) {
      await WorkoutCompletion(sessions, workouts).complete(session, advanceRotation: d.backdate == null);
    }
    return AutoEndResult(
      workoutName: d.workoutName,
      setsLogged: d.doneSets,
      savedSession: true,
      endedAfter: endedAfter,
      sessionId: session.id,
    );
  }
}

