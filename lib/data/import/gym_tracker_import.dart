import 'dart:convert';

import '../../domain/domain.dart';
import 'exercise_aliases.dart';

/// Why a file could not be imported (maps to a friendly message in the UI).
enum ImportProblem { tooLarge, notJson, wrongFormat, unsupportedVersion, nothingToImport }

class ImportException implements Exception {
  const ImportException(this.problem, [this.detail]);
  final ImportProblem problem;
  final String? detail;
  @override
  String toString() => 'ImportException($problem${detail == null ? '' : ': $detail'})';
}

/// What an import WOULD do, computed without touching any data (shown to the user first).
class GymTrackerImportPlan {
  const GymTrackerImportPlan({
    required this.sessions,
    required this.newExercises,
    required this.skippedAlreadyImported,
    required this.skippedNotCompleted,
    required this.skippedInvalid,
    required this.sets,
    required this.matchedExercises,
    required this.firstDate,
    required this.lastDate,
    required this.rotationDay,
    required this.rotationWorkoutId,
    required this.achievementsInFile,
  });

  /// Completed workouts to add (oldest first).
  final List<WorkoutSession> sessions;

  /// Custom exercises that must be created for names StationX does not have.
  final List<Exercise> newExercises;
  final int skippedAlreadyImported;
  final int skippedNotCompleted;
  final int skippedInvalid;
  final int sets;

  /// Distinct exercises used by the imported workouts that matched a StationX exercise.
  final int matchedExercises;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Gym Tracker's "next workout day" (1-based) and the StationX workout it points to.
  final int? rotationDay;
  final String? rotationWorkoutId;
  final int achievementsInFile;

  bool get isEmpty => sessions.isEmpty;
}

class ImportResult {
  const ImportResult({required this.sessionsAdded, required this.exercisesCreated, required this.rotationApplied});
  final int sessionsAdded;
  final int exercisesCreated;
  final bool rotationApplied;
}

/// Imports a `gym_tracker_export` v1 file (see gym_tracker/docs/EXPORT_FORMAT.md) into StationX.
///
/// Rules
///  * Only `completed` workouts are imported (in-progress / abandoned ones are skipped).
///  * `workoutDate` = when the workout was STARTED (when the user trained); `meta.createdAt` = now
///    (when it was entered). They are never conflated.
///  * Ids are `gt_s<id>`: importing the same file twice adds nothing the second time.
///  * Existing data is never modified or deleted; the rotation only changes if the caller asks.
///  * Weights are kilograms in the file and in StationX — no unit conversion happens.
///  * Exercises: exact name match → curated alias → previously imported custom exercise → new custom exercise.
///  * Personal records are recomputed from history (not copied); achievements are not imported.
class GymTrackerImport {
  const GymTrackerImport._();

  static const maxBytes = 50 * 1024 * 1024;
  static const supportedVersion = 1;
  static const idPrefix = 'gt_s';
  static const customExercisePrefix = 'gt_x_';
  static const importNote = 'Imported from Gym Tracker';

  static GymTrackerImportPlan plan(
    String jsonText, {
    required Set<String> existingSessionIds,
    required List<Exercise> catalog,
    required List<Workout> workouts,
    DateTime? now,
  }) {
    if (jsonText.length > maxBytes) throw const ImportException(ImportProblem.tooLarge);
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      throw const ImportException(ImportProblem.notJson);
    }
    if (decoded is! Map || decoded['format'] != 'gym_tracker_export') throw const ImportException(ImportProblem.wrongFormat);
    final version = decoded['version'];
    if (version is! int || version < 1 || version > supportedVersion) {
      throw ImportException(ImportProblem.unsupportedVersion, '$version');
    }
    final stamp = now ?? DateTime.now();

    // ── exercise resolution ──
    final byName = {for (final e in catalog) normalizeExerciseName(e.name): e.id};
    final catalogIds = {for (final e in catalog) e.id};
    final gtExercises = <String, Map>{}; // normalised name → exported exercise record (muscles etc.)
    for (final e in (decoded['exercises'] as List? ?? const [])) {
      if (e is Map && e['name'] is String) gtExercises[normalizeExerciseName(e['name'] as String)] = e;
    }
    final created = <String, Exercise>{};
    final matchedIds = <String>{};
    String? resolve(String? rawName) {
      if (rawName == null || rawName.trim().isEmpty) return null;
      final key = normalizeExerciseName(rawName);
      if (key.isEmpty) return null;
      final exact = byName[key];
      if (exact != null) return matchedIds.add(exact) ? exact : exact;
      final alias = gymTrackerAliases[key];
      if (alias != null && catalogIds.contains(alias)) {
        matchedIds.add(alias);
        return alias;
      }
      final customId = '$customExercisePrefix$key';
      if (catalogIds.contains(customId)) {
        matchedIds.add(customId);
        return customId;
      }
      return (created[customId] ??= _customExercise(customId, rawName.trim(), gtExercises[key], stamp)).id;
    }

    // ── workout mapping (by name, else by day position) ──
    final workoutByName = {for (final w in workouts) normalizeExerciseName(w.name): w.id};
    String? workoutFor(int? day, String? templateName) {
      if (workouts.isEmpty) return null;
      final byTemplate = templateName == null ? null : workoutByName[normalizeExerciseName(templateName)];
      if (byTemplate != null) return byTemplate;
      if (day != null && day >= 1 && day <= workouts.length) return workouts[day - 1].id;
      return workouts.first.id;
    }

    // ── sessions ──
    final sessions = <WorkoutSession>[];
    var skippedExisting = 0, skippedNotCompleted = 0, skippedInvalid = 0, setCount = 0;
    for (final raw in (decoded['sessions'] as List? ?? const [])) {
      if (raw is! Map) {
        skippedInvalid++;
        continue;
      }
      if (raw['status'] != 'completed') {
        skippedNotCompleted++;
        continue;
      }
      final id = raw['id'];
      final started = _date(raw['startedAt']);
      if (id is! int || started == null) {
        skippedInvalid++;
        continue;
      }
      final sessionId = '$idPrefix$id';
      if (existingSessionIds.contains(sessionId)) {
        skippedExisting++;
        continue;
      }
      final logs = <ExerciseLog>[];
      final notes = <String>[];
      final exs = [for (final e in (raw['exercises'] as List? ?? const [])) if (e is Map) e]
        ..sort((a, b) => ((a['orderIndex'] as num?) ?? 0).compareTo((b['orderIndex'] as num?) ?? 0));
      for (final e in exs) {
        final sets = <SetLog>[];
        final rawSets = [for (final s in (e['sets'] as List? ?? const [])) if (s is Map) s]
          ..sort((a, b) => ((a['setNumber'] as num?) ?? 0).compareTo((b['setNumber'] as num?) ?? 0));
        for (final s in rawSets) {
          final kg = s['weightKg'];
          final reps = s['reps'];
          if (kg is! num || reps is! num || !kg.isFinite || kg < 0 || reps <= 0) continue;
          sets.add(SetLog(weightKg: kg.toDouble(), reps: reps.round()));
        }
        if (sets.isEmpty) continue;
        final exId = resolve(e['exerciseName'] as String?);
        if (exId == null) continue;
        logs.add(ExerciseLog(exerciseId: exId, sets: sets));
        setCount += sets.length;
        final note = e['note'];
        if (note is String && note.trim().isNotEmpty) notes.add('${e['exerciseName']}: ${note.trim()}');
      }
      if (logs.isEmpty) {
        skippedInvalid++;
        continue;
      }
      final completed = _date(raw['completedAt']);
      final secs = completed == null ? 0 : completed.difference(started).inSeconds;
      final day = raw['templateDay'] is int ? raw['templateDay'] as int : null;
      sessions.add(WorkoutSession(
        id: sessionId,
        workoutId: workoutFor(day, raw['templateName'] as String?) ?? 'w1',
        name: (raw['templateName'] as String?)?.trim().isNotEmpty == true ? (raw['templateName'] as String).trim() : 'Workout',
        workoutDate: started,
        durationSeconds: secs > 0 && secs <= 6 * 3600 ? secs : 0,
        exercises: logs,
        notes: [importNote, ...notes].join('. '),
        meta: SyncMeta(createdAt: stamp, updatedAt: stamp), // entered now; pending → syncs if signed in
      ));
    }
    sessions.sort((a, b) => a.workoutDate.compareTo(b.workoutDate));

    // ── rotation pointer ──
    final settings = decoded['settings'];
    final nextDay = settings is Map && settings['nextWorkoutDay'] is int ? settings['nextWorkoutDay'] as int : null;
    final rotationWorkout = nextDay != null && nextDay >= 1 && nextDay <= workouts.length ? workouts[nextDay - 1].id : null;

    final ach = decoded['achievements'];
    final unlocked = ach is List ? ach.where((a) => a is Map && a['unlockedAt'] != null).length : 0;

    return GymTrackerImportPlan(
      sessions: sessions,
      newExercises: created.values.toList(),
      skippedAlreadyImported: skippedExisting,
      skippedNotCompleted: skippedNotCompleted,
      skippedInvalid: skippedInvalid,
      sets: setCount,
      matchedExercises: matchedIds.length,
      firstDate: sessions.isEmpty ? null : sessions.first.workoutDate,
      lastDate: sessions.isEmpty ? null : sessions.last.workoutDate,
      rotationDay: nextDay,
      rotationWorkoutId: rotationWorkout,
      achievementsInFile: unlocked,
    );
  }

  /// Applies a plan. Safe to repeat: sessions already present are skipped.
  static Future<ImportResult> apply(
    GymTrackerImportPlan plan, {
    required ExerciseRepository exercises,
    required SessionRepository sessions,
    required WorkoutRepository workouts,
    bool applyRotation = false,
  }) async {
    var createdCount = 0;
    for (final e in plan.newExercises) {
      if (exercises.byId(e.id) == null) {
        await exercises.addCustom(e);
        createdCount++;
      }
    }
    final fresh = [for (final s in plan.sessions) if (sessions.byId(s.id) == null) s];
    if (fresh.isNotEmpty) await sessions.addAll(fresh);
    var rotation = false;
    if (applyRotation && plan.rotationWorkoutId != null) {
      await workouts.setCurrentWorkout(plan.rotationWorkoutId!);
      rotation = true;
    }
    return ImportResult(sessionsAdded: fresh.length, exercisesCreated: createdCount, rotationApplied: rotation);
  }

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

  static Exercise _customExercise(String id, String name, Map? source, DateTime now) {
    final primary = _muscle(source?['primaryMuscles']?.toString().split(',').first) ?? _muscle(name) ?? MuscleGroup.core;
    final secondary = <MuscleGroup>{
      for (final part in (source?['secondaryMuscles']?.toString().split(',') ?? const <String>[])) ?_muscle(part),
    }..remove(primary);
    return Exercise(
      id: id,
      name: name,
      primaryMuscle: primary,
      secondaryMuscles: secondary.toList(),
      equipment: _equipment(name),
      isCustom: true,
      meta: SyncMeta(createdAt: now, updatedAt: now),
    );
  }

  /// Gym Tracker muscle labels (Chest, Rear Delts, Quads, …) → StationX's 7 groups.
  static MuscleGroup? _muscle(String? label) {
    final s = (label ?? '').toLowerCase().trim();
    if (s.isEmpty) return null;
    if (s.contains('chest') || s.contains('pec')) return MuscleGroup.chest;
    if (s.contains('tricep')) return MuscleGroup.triceps;
    if (s.contains('bicep') || s.contains('forearm') || s.contains('curl')) return MuscleGroup.biceps;
    if (s.contains('delt') || s.contains('shoulder') || s.contains('lateral raise')) return MuscleGroup.shoulders;
    if (s.contains('back') || s.contains('lat') || s.contains('trap') || s.contains('row')) return MuscleGroup.back;
    if (s.contains('quad') || s.contains('hamstring') || s.contains('glute') || s.contains('calf') || s.contains('calves') || s.contains('leg') || s.contains('squat')) {
      return MuscleGroup.legs;
    }
    if (s.contains('abs') || s.contains('core') || s.contains('oblique')) return MuscleGroup.core;
    return null;
  }

  static Equipment _equipment(String name) {
    final s = name.toLowerCase();
    if (s.contains('machine') || s.contains('leg press') || s.contains('leg extension') || s.contains('leg curl') || s.contains('smith')) return Equipment.machine;
    if (s.contains('cable') || s.contains('pulldown') || s.contains('face pull')) return Equipment.cable;
    if (s.contains('dumbbell')) return Equipment.dumbbell;
    if (s.contains('barbell') || s.contains('ez-bar') || s.contains('ez bar') || s.contains('bench press') || s.contains('squat') || s.contains('deadlift')) return Equipment.barbell;
    return Equipment.bodyweight;
  }
}
