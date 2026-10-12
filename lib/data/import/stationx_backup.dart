import 'dart:convert';

import '../../domain/domain.dart';
import '../remote/row_mappers.dart';
import 'gym_tracker_import.dart';

/// What restoring a backup WOULD add (computed without touching any data).
class StationXBackupPlan {
  const StationXBackupPlan({
    required this.exercises,
    required this.workouts,
    required this.sessions,
    required this.cardio,
    required this.goals,
    required this.activities,
    required this.rotation,
    required this.skippedExisting,
    required this.firstDate,
    required this.lastDate,
    required this.exportedAt,
  });

  final List<Exercise> exercises;
  final List<Workout> workouts;
  final List<WorkoutSession> sessions;
  final List<CardioSession> cardio;
  final List<CardioGoal> goals;
  final List<CustomCardioActivity> activities;

  /// The backup's routine order + pointer (used only when this account has no routines yet).
  final Rotation rotation;

  /// Records of the backup this account already has (same id) — never overwritten.
  final int skippedExisting;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? exportedAt;

  int get total =>
      exercises.length +
      workouts.length +
      sessions.length +
      cardio.length +
      goals.length +
      activities.length;
  bool get isEmpty => total == 0;
}

class StationXBackupResult {
  const StationXBackupResult({required this.added});
  final int added;
}

/// A complete, re-importable copy of the data of one account (`stationx_backup` v1): custom
/// exercises, routines + rotation, workout and cardio history, cardio goals and custom activities.
/// The profile/credentials are NOT part of it, so a backup can be restored into any other account.
///
/// Rules: existing data is never modified or deleted; a record with an id the account already has is
/// skipped (restoring twice, or into the same account, adds nothing). Records keep their original
/// dates. Rows are the same shape the server stores, so every field survives the round trip.
class StationXBackup {
  const StationXBackup._();

  static const format = 'stationx_backup';
  static const version = 1;
  static const fileName = 'stationx-backup';

  static String build({
    required List<Exercise> exercises,
    required List<Workout> workouts,
    required Rotation rotation,
    required List<WorkoutSession> sessions,
    required List<CardioSession> cardio,
    required List<CardioGoal> goals,
    required List<CustomCardioActivity> activities,
    DateTime? now,
  }) {
    final data = {
      'format': format,
      'version': version,
      'app': 'StationX',
      'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'exercises': [
        for (final e in exercises)
          if (e.isCustom) exerciseToRow(e),
      ],
      'workouts': [
        for (var i = 0; i < workouts.length; i++) workoutToRow(workouts[i], i),
      ],
      'rotation': rotationToRow(rotation),
      'workoutSessions': [for (final s in sessions) sessionToRow(s)],
      'cardioSessions': [for (final c in cardio) cardioToRow(c)],
      'cardioGoals': [for (final g in goals) goalToRow(g)],
      'customActivities': [for (final a in activities) customActivityToRow(a)],
    };
    return const JsonEncoder.withIndent(' ').convert(data);
  }

  /// True when [text] looks like a StationX backup (cheap check used to route an import).
  static bool looksLikeBackup(String text) {
    final head = text.length > 400 ? text.substring(0, 400) : text;
    return head.contains('"$format"');
  }

  static StationXBackupPlan plan(
    String jsonText, {
    required ExerciseRepository exercises,
    required WorkoutRepository workouts,
    required SessionRepository sessions,
    required CardioRepository cardio,
  }) {
    if (GymTrackerImport.exceedsLimit(jsonText)) {
      throw const ImportException(ImportProblem.tooLarge);
    }
    try {
      return _plan(
        jsonText,
        exercises: exercises,
        workouts: workouts,
        sessions: sessions,
        cardio: cardio,
      );
    } on ImportException {
      rethrow;
    } catch (_) {
      throw const ImportException(ImportProblem.wrongFormat);
    }
  }

  static List<Map<String, dynamic>> _rows(Object? v, int max) {
    if (v == null) return const [];
    if (v is! List) throw const ImportException(ImportProblem.wrongFormat);
    return [
      for (final r in v.take(max))
        if (r is Map) r.cast<String, dynamic>(),
    ];
  }

  static StationXBackupPlan _plan(
    String jsonText, {
    required ExerciseRepository exercises,
    required WorkoutRepository workouts,
    required SessionRepository sessions,
    required CardioRepository cardio,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      throw const ImportException(ImportProblem.notJson);
    }
    if (decoded is! Map || decoded['format'] != format) {
      throw const ImportException(ImportProblem.wrongFormat);
    }
    final v = decoded['version'];
    if (v is! int || v > version) {
      throw const ImportException(ImportProblem.unsupportedVersion);
    }

    var skipped = 0;
    bool known(bool exists) {
      if (exists) skipped++;
      return !exists;
    }

    final newExercises = <Exercise>[];
    for (final r in _rows(
      decoded['exercises'],
      GymTrackerImport.maxNewExercises,
    )) {
      final e = exerciseFromRow(r);
      if (e.id.isNotEmpty && known(exercises.byId(e.id) != null)) {
        newExercises.add(e);
      }
    }

    final newWorkouts = <Workout>[];
    final wRows = _rows(decoded['workouts'], 500)
      ..sort(
        (a, b) => ((a['position'] as num?) ?? 0).compareTo(
          (b['position'] as num?) ?? 0,
        ),
      );
    for (final r in wRows) {
      final w = workoutFromRow(r).$1;
      if (w.id.isNotEmpty && known(workouts.byId(w.id) != null)) {
        newWorkouts.add(w);
      }
    }

    final newSessions = <WorkoutSession>[];
    for (final r in _rows(
      decoded['workoutSessions'],
      GymTrackerImport.maxSessions,
    )) {
      final s = sessionFromRow(r);
      if (s.id.isNotEmpty && known(sessions.byId(s.id) != null)) {
        newSessions.add(s);
      }
    }

    final newCardio = <CardioSession>[];
    for (final r in _rows(
      decoded['cardioSessions'],
      GymTrackerImport.maxSessions,
    )) {
      final c = cardioFromRow(r);
      if (c.id.isNotEmpty && known(cardio.byId(c.id) != null)) {
        newCardio.add(c);
      }
    }

    final newGoals = <CardioGoal>[];
    for (final r in _rows(decoded['cardioGoals'], 200)) {
      final g = goalFromRow(r);
      if (g.id.isNotEmpty && known(cardio.goals.any((x) => x.id == g.id))) {
        newGoals.add(g);
      }
    }

    final newActivities = <CustomCardioActivity>[];
    for (final r in _rows(decoded['customActivities'], 200)) {
      final a = customActivityFromRow(r);
      if (a.id.isNotEmpty &&
          known(cardio.customActivities.any((x) => x.id == a.id))) {
        newActivities.add(a);
      }
    }

    final rot = decoded['rotation'];
    final rotation = rot is Map
        ? rotationFromRow(rot.cast<String, dynamic>())
        : const Rotation(workoutIds: []);

    final dates = [
      for (final s in newSessions) s.workoutDate,
      for (final c in newCardio) c.workoutDate,
    ]..sort();
    final at = decoded['exportedAt'];
    return StationXBackupPlan(
      exercises: newExercises,
      workouts: newWorkouts,
      sessions: newSessions,
      cardio: newCardio,
      goals: newGoals,
      activities: newActivities,
      rotation: rotation,
      skippedExisting: skipped,
      firstDate: dates.isEmpty ? null : dates.first,
      lastDate: dates.isEmpty ? null : dates.last,
      exportedAt: at is String ? DateTime.tryParse(at) : null,
    );
  }

  /// Applies a plan. Safe to repeat: records that exist by now are skipped.
  static Future<StationXBackupResult> apply(
    StationXBackupPlan plan, {
    required ExerciseRepository exercises,
    required WorkoutRepository workouts,
    required SessionRepository sessions,
    required CardioRepository cardio,
  }) async {
    var added = 0;
    for (final e in plan.exercises) {
      if (exercises.byId(e.id) == null) {
        await exercises.addCustom(e);
        added++;
      }
    }
    for (final a in plan.activities) {
      if (!cardio.customActivities.any((x) => x.id == a.id)) {
        await cardio.addCustomActivity(a);
        added++;
      }
    }
    for (final g in plan.goals) {
      if (!cardio.goals.any((x) => x.id == g.id)) {
        await cardio.saveGoal(g);
        added++;
      }
    }

    final freshWorkouts = [
      for (final w in plan.workouts)
        if (workouts.byId(w.id) == null) w,
    ];
    if (freshWorkouts.isNotEmpty) {
      final fresh = {for (final w in freshWorkouts) w.id};
      final current = workouts.rotation;
      final Rotation next;
      if (current.workoutIds.isEmpty && plan.rotation.workoutIds.isNotEmpty) {
        // Empty account: take over the backup's routine order and pointer.
        final ids = [
          for (final id in plan.rotation.workoutIds)
            if (fresh.contains(id)) id,
        ];
        next = Rotation(
          workoutIds: ids,
          currentIndex: ids.isEmpty
              ? 0
              : plan.rotation.currentIndex.clamp(0, ids.length - 1),
        );
      } else {
        // Existing routines keep their order and pointer; imported ones are appended.
        next = current.copyWith(
          workoutIds: [
            ...current.workoutIds,
            for (final id in plan.rotation.workoutIds)
              if (fresh.contains(id)) id,
          ],
        );
      }
      await workouts.saveSchedule(freshWorkouts, next);
      added += freshWorkouts.length;
    }

    final freshSessions = [
      for (final s in plan.sessions)
        if (sessions.byId(s.id) == null) s,
    ];
    if (freshSessions.isNotEmpty) {
      await sessions.addAll(freshSessions);
      added += freshSessions.length;
    }
    for (final c in plan.cardio) {
      if (cardio.byId(c.id) == null) {
        await cardio.add(c);
        added++;
      }
    }
    return StationXBackupResult(added: added);
  }
}
