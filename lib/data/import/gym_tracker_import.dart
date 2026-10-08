import 'dart:convert';
import 'dart:isolate';

import '../../domain/domain.dart';
import '../sync/text_limits.dart';
import 'exercise_aliases.dart';

/// Why a file could not be imported (maps to a friendly message in the UI).
enum ImportProblem {
  tooLarge,
  notJson,
  wrongFormat,
  unsupportedVersion,
  nothingToImport,
}

class ImportException implements Exception {
  const ImportException(this.problem, [this.detail]);
  final ImportProblem problem;
  final String? detail;
  @override
  String toString() =>
      'ImportException($problem${detail == null ? '' : ': $detail'})';
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
    this.needsReview = const [],
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

  /// Names of NEW custom exercises whose muscles could not be determined from the file's labels or the
  /// exercise name. They were still created (with a placeholder core target) so no set is lost, but the
  /// user should check their muscles. Empty when everything was understood.
  final List<String> needsReview;

  bool get isEmpty => sessions.isEmpty;
}

class ImportResult {
  const ImportResult({
    required this.sessionsAdded,
    required this.exercisesCreated,
    required this.rotationApplied,
  });
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

  /// Largest accepted file / pasted text, measured in UTF-8 BYTES.
  static const maxBytes = 10 * 1024 * 1024;

  // Clamps so imported data can never exceed the server CHECKs (supabase/migrations) or wedge sync.
  static const maxNameLength = 200;
  static const maxNotesLength = 5000;
  static const maxExerciseNoteLength = 500;
  static const maxExercisesPerSession = 100;
  static const maxSetsPerExercise = 50;
  static const maxSessions = 20000;
  static const maxNewExercises = 500;
  static const maxWeightKg = 2000.0;
  static const maxReps = 1000;

  /// Texts shorter than this are planned synchronously even by [planAsync] (an isolate costs more).
  static const isolateThresholdChars = 256 * 1024;

  /// True when [text] is larger than [maxBytes] once encoded as UTF-8. Cheap for small inputs.
  static bool exceedsLimit(String text) {
    if (text.length > maxBytes) return true; // a char is at least one byte
    if (text.length * 3 <= maxBytes) return false; // even 3 bytes/char fits
    return utf8.encode(text).length > maxBytes;
  }

  /// Same as [plan] but decodes and maps large inputs off the UI isolate.
  static Future<GymTrackerImportPlan> planAsync(
    String jsonText, {
    required Set<String> existingSessionIds,
    required List<Exercise> catalog,
    required List<Workout> workouts,
    DateTime? now,
  }) {
    if (exceedsLimit(jsonText)) {
      return Future.error(const ImportException(ImportProblem.tooLarge));
    }
    if (jsonText.length < isolateThresholdChars) {
      return Future(
        () => plan(
          jsonText,
          existingSessionIds: existingSessionIds,
          catalog: catalog,
          workouts: workouts,
          now: now,
        ),
      );
    }
    return Isolate.run(
      () => plan(
        jsonText,
        existingSessionIds: existingSessionIds,
        catalog: catalog,
        workouts: workouts,
        now: now,
      ),
    );
  }
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
    if (exceedsLimit(jsonText)) {
      throw const ImportException(ImportProblem.tooLarge);
    }
    try {
      return _plan(
        jsonText,
        existingSessionIds: existingSessionIds,
        catalog: catalog,
        workouts: workouts,
        now: now,
      );
    } on ImportException {
      rethrow;
    } catch (_) {
      // Hostile / malformed structure (wrong types, absurd nesting): never crash the caller.
      throw const ImportException(ImportProblem.wrongFormat);
    }
  }

  static GymTrackerImportPlan _plan(
    String jsonText, {
    required Set<String> existingSessionIds,
    required List<Exercise> catalog,
    required List<Workout> workouts,
    DateTime? now,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      throw const ImportException(ImportProblem.notJson);
    }
    if (decoded is! Map || decoded['format'] != 'gym_tracker_export') {
      throw const ImportException(ImportProblem.wrongFormat);
    }
    final version = decoded['version'];
    if (version is! int || version < 1 || version > supportedVersion) {
      throw ImportException(ImportProblem.unsupportedVersion, '$version');
    }
    final stamp = now ?? DateTime.now();

    // ── exercise resolution ──
    final byName = {
      for (final e in catalog) normalizeExerciseName(e.name): e.id,
    };
    final catalogIds = {for (final e in catalog) e.id};
    final gtExercises =
        <
          String,
          Map
        >{}; // normalised name → exported exercise record (muscles etc.)
    for (final e in (decoded['exercises'] is List ? decoded['exercises'] as List : const [])) {
      if (e is Map && e['name'] is String) {
        gtExercises[normalizeExerciseName(clipText(e['name'] as String, maxNameLength))] = e;
      }
    }
    final created = <String, Exercise>{};
    final needsReview = <String>[];
    final matchedIds = <String>{};
    String? resolve(String? untrimmedName) {
      if (untrimmedName == null) return null;
      final rawName = clipText(untrimmedName.trim(), maxNameLength).trim();
      if (rawName.isEmpty) return null;
      final key = normalizeExerciseName(rawName);
      if (key.isEmpty) return null;
      final exact = byName[key];
      if (exact != null) {
        matchedIds.add(exact);
        return exact;
      }
      final alias = gymTrackerAliases[key];
      if (alias != null && catalogIds.contains(alias)) {
        matchedIds.add(alias);
        return alias;
      }
      // Server ids are limited to 100 chars: long names get a stable hash suffix.
      final customId = key.length <= 80
          ? '$customExercisePrefix$key'
          : '$customExercisePrefix${key.substring(0, 60)}_${_hash(key)}';
      if (catalogIds.contains(customId)) {
        matchedIds.add(customId);
        return customId;
      }
      if (created[customId] == null && created.length >= maxNewExercises) {
        return null; // too many new exercises in one file: skip the rest
      }
      final existing = created[customId];
      if (existing != null) return existing.id;
      final built = _customExercise(customId, rawName, gtExercises[key], stamp);
      created[customId] = built.exercise;
      if (built.needsReview) needsReview.add(built.exercise.name);
      return built.exercise.id;
    }

    // ── workout mapping (by name, else by day position) ──
    final workoutByName = {
      for (final w in workouts) normalizeExerciseName(w.name): w.id,
    };
    String? workoutFor(int? day, String? templateName) {
      if (workouts.isEmpty) return null;
      final byTemplate = templateName == null
          ? null
          : workoutByName[normalizeExerciseName(templateName)];
      if (byTemplate != null) return byTemplate;
      if (day != null && day >= 1 && day <= workouts.length) {
        return workouts[day - 1].id;
      }
      return workouts.first.id;
    }

    // ── sessions ──
    final sessions = <WorkoutSession>[];
    var skippedExisting = 0,
        skippedNotCompleted = 0,
        skippedInvalid = 0,
        setCount = 0;
    final rawSessions = decoded['sessions'];
    final latest = stamp.add(const Duration(days: 366));
    for (final raw in (rawSessions is List ? rawSessions : const [])) {
      if (sessions.length >= maxSessions) {
        skippedInvalid++;
        continue;
      }
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
      if (id is! int ||
          id < 0 ||
          started == null ||
          started.year < 1970 ||
          started.isAfter(latest)) {
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
      final exs =
          [
            for (final e in (raw['exercises'] is List ? raw['exercises'] as List : const []))
              if (e is Map) e,
          ]..sort((a, b) => _order(a['orderIndex']).compareTo(_order(b['orderIndex'])));
      for (final e in exs) {
        if (logs.length >= maxExercisesPerSession) break;
        final sets = <SetLog>[];
        final rawSets =
            [
              for (final s in (e['sets'] is List ? e['sets'] as List : const []))
                if (s is Map) s,
            ]..sort((a, b) => _order(a['setNumber']).compareTo(_order(b['setNumber'])));
        for (final s in rawSets) {
          if (sets.length >= maxSetsPerExercise) break;
          final kg = s['weightKg'];
          final reps = s['reps'];
          if (kg is! num ||
              reps is! num ||
              !kg.isFinite ||
              !reps.isFinite ||
              kg < 0 ||
              kg > maxWeightKg ||
              reps <= 0 ||
              reps > maxReps) {
            continue;
          }
          sets.add(SetLog(weightKg: kg.toDouble(), reps: reps.round()));
        }
        if (sets.isEmpty) continue;
        final exName = e['exerciseName'];
        final exId = resolve(exName is String ? exName : null);
        if (exId == null) continue;
        logs.add(ExerciseLog(exerciseId: exId, sets: sets));
        setCount += sets.length;
        final note = e['note'];
        if (note is String && note.trim().isNotEmpty) {
          notes.add(
            '${clipText((exName as String).trim(), 100)}: '
            '${clipText(note.trim(), maxExerciseNoteLength)}',
          );
        }
      }
      if (logs.isEmpty) {
        skippedInvalid++;
        continue;
      }
      final completed = _date(raw['completedAt']);
      final secs = completed == null
          ? 0
          : completed.difference(started).inSeconds;
      final day = raw['templateDay'] is int ? raw['templateDay'] as int : null;
      final templateName = raw['templateName'] is String
          ? clipText((raw['templateName'] as String).trim(), maxNameLength).trim()
          : '';
      sessions.add(
        WorkoutSession(
          id: sessionId,
          workoutId: workoutFor(day, templateName.isEmpty ? null : templateName) ?? 'w1',
          name: templateName.isEmpty ? 'Workout' : templateName,
          workoutDate: started,
          durationSeconds: secs > 0 && secs <= 6 * 3600 ? secs : 0,
          exercises: logs,
          notes: clipText([importNote, ...notes].join('. '), maxNotesLength),
          meta: SyncMeta(
            createdAt: stamp,
            updatedAt: stamp,
          ), // entered now; pending → syncs if signed in
        ),
      );
    }
    sessions.sort((a, b) => a.workoutDate.compareTo(b.workoutDate));

    // ── rotation pointer ──
    final settings = decoded['settings'];
    final nextDay = settings is Map && settings['nextWorkoutDay'] is int
        ? settings['nextWorkoutDay'] as int
        : null;
    final rotationWorkout =
        nextDay != null && nextDay >= 1 && nextDay <= workouts.length
        ? workouts[nextDay - 1].id
        : null;

    final ach = decoded['achievements'];
    final unlocked = ach is List
        ? ach.where((a) => a is Map && a['unlockedAt'] != null).length
        : 0;

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
      needsReview: List.unmodifiable(needsReview),
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
    final fresh = [
      for (final s in plan.sessions)
        if (sessions.byId(s.id) == null) s,
    ];
    if (fresh.isNotEmpty) await sessions.addAll(fresh);
    var rotation = false;
    if (applyRotation && plan.rotationWorkoutId != null) {
      await workouts.setCurrentWorkout(plan.rotationWorkoutId!);
      rotation = true;
    }
    return ImportResult(
      sessionsAdded: fresh.length,
      exercisesCreated: createdCount,
      rotationApplied: rotation,
    );
  }

  static num _order(Object? v) => v is num && v.isFinite ? v : 0;

  /// Short stable FNV-1a hash (hex) used to keep long custom-exercise ids unique and <= 100 chars.
  static String _hash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  static ({Exercise exercise, bool needsReview}) _customExercise(
    String id,
    String name,
    Map? source,
    DateTime now,
  ) {
    List<String> labels(String field, int max) => [
      for (final part in clipText(source?[field]?.toString() ?? '', max).split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ].take(12).toList();

    final primaryLabels = [for (final l in labels('primaryMuscles', 200)) ?_target(l)];
    final secondaryLabels = [for (final l in labels('secondaryMuscles', 500)) ?_target(l)];

    var unknown = false;
    final _Pick first;
    final rest = <_Pick>[];
    if (primaryLabels.isNotEmpty) {
      first = primaryLabels.first;
      rest
        ..addAll(primaryLabels.skip(1))
        ..addAll(secondaryLabels);
    } else {
      final guess = _fromName(name);
      if (guess != null) {
        first = guess;
      } else {
        unknown = true;
        first = const _Pick(MuscleRegion.core, null); // placeholder, flagged for review
      }
      rest.addAll(secondaryLabels);
    }
    final targets = <MuscleTarget>[
      MuscleTarget.primary(first.region, muscle: first.muscle),
    ];
    for (final r in rest) {
      if (r.region == first.region && (r.muscle == null || r.muscle == first.muscle)) continue;
      targets.add(MuscleTarget.secondary(r.region, muscle: r.muscle));
    }
    final exercise = Exercise.custom(
      id: id,
      name: name,
      targets: targets,
      equipment: _equipment(name),
      meta: SyncMeta(createdAt: now, updatedAt: now),
    );
    return (exercise: exercise, needsReview: unknown);
  }

  /// A Gym Tracker muscle label → region (+ leaf only when the label itself names it). Null = not understood.
  static _Pick? _target(String label) {
    final s = label.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), ' ').trim();
    if (s.isEmpty) return null;
    bool has(String w) => s.contains(w);
    if (has('rear delt') || has('posterior delt')) return const _Pick(MuscleRegion.shoulders, Muscle.rearDelts);
    if (has('side delt') || has('lateral delt') || has('middle delt')) {
      return const _Pick(MuscleRegion.shoulders, Muscle.sideDelts);
    }
    if (has('front delt') || has('anterior delt')) return const _Pick(MuscleRegion.shoulders, Muscle.frontDelts);
    if (has('delt') || has('shoulder')) return const _Pick(MuscleRegion.shoulders, null);
    if (has('upper chest')) return const _Pick(MuscleRegion.chest, Muscle.upperChest);
    if (has('lower chest')) return const _Pick(MuscleRegion.chest, Muscle.lowerChest);
    if (has('chest') || has('pec')) return const _Pick(MuscleRegion.chest, null);
    if (has('tricep')) return const _Pick(MuscleRegion.triceps, null);
    if (has('bicep')) return const _Pick(MuscleRegion.biceps, null);
    if (has('brachialis')) return const _Pick(MuscleRegion.biceps, Muscle.brachialis);
    if (has('forearm') || has('grip')) return const _Pick(MuscleRegion.forearms, null);
    if (has('lower back')) return const _Pick(MuscleRegion.back, Muscle.lowerBack);
    if (has('upper back') || has('rhomboid')) return const _Pick(MuscleRegion.back, Muscle.upperBack);
    if (has('trap')) return const _Pick(MuscleRegion.back, Muscle.traps);
    if (RegExp(r'\blats?\b|latissimus').hasMatch(s)) return const _Pick(MuscleRegion.back, Muscle.lats);
    if (has('back')) return const _Pick(MuscleRegion.back, null);
    if (has('quad')) return const _Pick(MuscleRegion.quadriceps, null);
    if (has('hamstring')) return const _Pick(MuscleRegion.hamstrings, null);
    if (has('glute') || has('abductor') || has('hip')) return const _Pick(MuscleRegion.glutes, null);
    if (has('calf') || has('calves') || has('soleus') || has('gastroc')) {
      return const _Pick(MuscleRegion.calves, null);
    }
    if (has('oblique')) return const _Pick(MuscleRegion.core, Muscle.obliques);
    if (has('abs') || has('abdominal') || has('core')) return const _Pick(MuscleRegion.core, null);
    return null; // "Legs", "Full body", "Cardio", … are too vague to place
  }

  /// Conservative guess from the exercise NAME when the file gives no usable muscle label. Whole region only.
  static _Pick? _fromName(String name) {
    final s = ' ${name.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), ' ').trim()} ';
    bool has(String w) => s.contains(w);
    _Pick r(MuscleRegion x) => _Pick(x, null);
    if (has('leg curl') || has('hamstring') || has('romanian') || has(' rdl ') || has('good morning') || has('nordic')) {
      return r(MuscleRegion.hamstrings);
    }
    if (has('hip thrust') || has('glute') || has('bridge') || has('kickback') || has('abduction') || has('abductor')) {
      return r(MuscleRegion.glutes);
    }
    if (has('calf') || has('calves')) return r(MuscleRegion.calves);
    if (has('wrist curl') || has('forearm')) return r(MuscleRegion.forearms);
    if (has('tricep') || has('pushdown') || has('push down') || has('skull') || has('kickback')) {
      return r(MuscleRegion.triceps);
    }
    if (has('face pull') || has('rear delt') || has('reverse fly') || has('reverse pec') ||
        has('lateral raise') || has('front raise') || has('shoulder') || has('overhead press') ||
        has('military') || has('arnold') || has('upright row')) {
      return r(MuscleRegion.shoulders);
    }
    if (has('leg extension') || has('leg press') || has('squat') || has('lunge') || has('quad') || has('step up')) {
      return r(MuscleRegion.quadriceps);
    }
    if (has('curl')) return r(MuscleRegion.biceps);
    if (has('shrug')) return const _Pick(MuscleRegion.back, Muscle.traps);
    if (has('row') || has('pulldown') || has('pull down') || has('pull up') || has('pullup') ||
        has('chin up') || has('chinup') || has('deadlift') || has('back extension') || has('pullover')) {
      return r(MuscleRegion.back);
    }
    if (has('bench') || has('chest') || has('push up') || has('pushup') || has(' fly ') || has(' flye ') ||
        has('pec deck') || has('crossover')) {
      return r(MuscleRegion.chest);
    }
    if (has('crunch') || has('plank') || has('sit up') || has('situp') || has(' abs ') || has('leg raise') || has('woodchop')) {
      return r(MuscleRegion.core);
    }
    return null;
  }

  static Equipment _equipment(String name) {
    final s = name.toLowerCase();
    if (s.contains('machine') ||
        s.contains('leg press') ||
        s.contains('leg extension') ||
        s.contains('leg curl') ||
        s.contains('smith')) {
      return Equipment.machine;
    }
    if (s.contains('cable') ||
        s.contains('pulldown') ||
        s.contains('face pull')) {
      return Equipment.cable;
    }
    if (s.contains('dumbbell')) return Equipment.dumbbell;
    if (s.contains('barbell') ||
        s.contains('ez-bar') ||
        s.contains('ez bar') ||
        s.contains('bench press') ||
        s.contains('squat') ||
        s.contains('deadlift')) {
      return Equipment.barbell;
    }
    return Equipment.bodyweight;
  }
}

class _Pick {
  const _Pick(this.region, this.muscle);
  final MuscleRegion region;
  final Muscle? muscle;
}
