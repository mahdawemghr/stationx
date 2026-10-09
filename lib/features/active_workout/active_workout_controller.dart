import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/formatters.dart';
import '../../data/device/device_services.dart';
import '../../domain/domain.dart';

/// One working set while the workout is in progress.
class SetDraft {
  SetDraft({required this.weightKg, required this.reps, this.done = false});
  double weightKg;
  int reps;
  bool done;
}

/// One exercise slot of the running workout.
class ExerciseDraft extends ChangeNotifier {
  ExerciseDraft({
    required this.exercise,
    required this.sets,
    required this.repMin,
    required this.repMax,
    this.prevSets = const [],
    this.recommendation,
    this.expanded = false,
    this.suggestionUsed = false,
  });

  Exercise exercise;
  final List<SetDraft> sets;
  final int repMin;
  final int repMax;

  /// Done sets of the most recent earlier session (PREV column).
  List<SetLog> prevSets;

  /// From ProgressionService — null (thin/stale/untracked history) shows last performance only.
  ProgressionRecommendation? recommendation;
  bool expanded;

  /// The user already tapped "Use ..." (hides the suggestion chip).
  bool suggestionUsed;

  int get doneCount => sets.where((s) => s.done).length;
  bool get complete => sets.isNotEmpty && doneCount == sets.length;
  int get remaining => sets.length - doneCount;
  double get volume => sets.where((s) => s.done).fold(0.0, (a, s) => a + s.weightKg * s.reps);

  /// Index of the first set not yet done (the "active" row), or -1.
  int get activeSetIndex => sets.indexWhere((s) => !s.done);

  /// Tells this exercise's own widgets that something inside it changed, so only
  /// that block rebuilds (the controller notifies the page-level summaries).
  void touch() => notifyListeners();
}

/// A run of consecutive drafts of one sub-area inside a [DraftSection]. [label] is null for the MAIN group.
class DraftGroup {
  const DraftGroup({required this.label, required this.drafts, required this.startIndex});
  final String? label;
  final List<ExerciseDraft> drafts;
  final int startIndex;
}

/// A run of consecutive exercises that train the same muscle (see WorkoutSections.groupContiguous).
/// [label] is empty for the flat fallback (no header).
class DraftSection {
  const DraftSection({required this.label, required this.drafts, required this.startIndex, this.groups = const []});
  final String label;
  final List<ExerciseDraft> drafts;
  final int startIndex;

  /// Sub-area runs (main group has a null label). Empty for the flat fallback.
  final List<DraftGroup> groups;

  int get exercisesDone => drafts.where((d) => d.complete).length;
  int get setsDone => drafts.fold(0, (a, d) => a + d.doneCount);
  int get setsTotal => drafts.fold(0, (a, d) => a + d.sets.length);
  bool get complete => drafts.isNotEmpty && exercisesDone == drafts.length;
}

class RestState {
  const RestState({required this.endsAt, required this.totalSeconds});
  final DateTime endsAt;
  final int totalSeconds;
}

/// Live cardio finisher / extra cardio block of a session.
/// Distance is manual; for treadmills with a speed set it falls back to
/// speed × time (flagged as an estimate in the UI). No sensors are involved.
class CardioDraft extends ChangeNotifier {
  CardioDraft({
    required this.kind,
    this.targetMinutes,
    this.speedKmh,
    this.inclinePct,
    this.resistance,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  CardioKind kind;
  int? targetMinutes;
  double? speedKmh;
  double? inclinePct;
  int? resistance;
  double? manualDistanceKm;

  int _accumulated = 0;
  DateTime? _since;

  bool get running => _since != null;
  bool get started => _accumulated > 0 || _since != null;

  int get seconds => _accumulated + (_since == null ? 0 : _clock().difference(_since!).inSeconds);

  bool get distanceIsEstimate => manualDistanceKm == null && speedKmh != null && kind.hasDistance;

  double? get distanceKm {
    if (manualDistanceKm != null) return manualDistanceKm;
    if (distanceIsEstimate && seconds > 0) {
      return double.parse((speedKmh! * seconds / 3600).toStringAsFixed(2));
    }
    return null;
  }

  bool get complete => targetMinutes != null ? seconds >= targetMinutes! * 60 : (started && !running);

  void start() {
    if (running) return;
    _since = _clock();
    notifyListeners();
  }

  void pause() {
    if (!running) return;
    _accumulated = seconds;
    _since = null;
    notifyListeners();
  }

  void toggle() => running ? pause() : start();

  void update({
    double? speedKmh,
    double? inclinePct,
    int? resistance,
    double? distanceKm,
    int? targetMinutes,
  }) {
    if (speedKmh != null) this.speedKmh = speedKmh;
    if (inclinePct != null) this.inclinePct = inclinePct;
    if (resistance != null) this.resistance = resistance;
    if (distanceKm != null) manualDistanceKm = distanceKm;
    if (targetMinutes != null) this.targetMinutes = targetMinutes;
    notifyListeners();
  }

  CardioSession? toSession({required String id, required DateTime workoutDate}) {
    pause();
    if (seconds <= 0) return null;
    return CardioSession(
      id: id,
      kind: kind,
      workoutDate: workoutDate,
      durationSeconds: seconds,
      distanceKm: distanceKm,
      speedKmh: speedKmh,
      inclinePct: inclinePct,
      resistance: resistance,
    );
  }
}

/// A workout that is not in the catalogue any more (deleted/archived) is rebuilt from its draft.
Workout workoutFromDraft(WorkoutDraft d) => Workout(
      id: d.workoutId,
      name: d.workoutName,
      exercises: [
        for (final e in d.exercises)
          RoutineExercise(exerciseId: e.exerciseId, sets: e.sets.length, repMin: e.repMin, repMax: e.repMax),
      ],
    );

/// State of a running workout. Pure logic, no widgets. Per-second clocks live
/// in their own widgets (see widgets/timers.dart) so this only notifies on real
/// changes (set logged, exercise swapped, ...). Every change is also persisted
/// (debounced) to [draftStore] so the workout survives the app being killed.
class ActiveWorkoutController extends ChangeNotifier {
  ActiveWorkoutController({
    required this.workout,
    required List<Exercise> catalog,
    required SessionRepository sessions,
    required this.profile,
    DateTime Function()? clock,
    DeviceFeedback? feedback,
    this.draftStore,
    WorkoutDraft? restoreFrom,
    this.backdate,
    this.draftDebounce = const Duration(milliseconds: 500),
  })  : _catalog = catalog,
        _clock = clock ?? DateTime.now,
        feedback = feedback ?? const HapticDeviceFeedback(),
        startedAt = restoreFrom?.startedAt ?? (clock ?? DateTime.now)() {
    final byId = {for (final e in catalog) e.id: e};
    final routine = restoreFrom == null
        // New session: display order == execution order (main exercises first, one block per muscle).
        ? WorkoutSections.arrange(workout.exercises, catalog)
        : [
            for (final e in restoreFrom.exercises)
              RoutineExercise(exerciseId: e.exerciseId, sets: e.sets.length, repMin: e.repMin, repMax: e.repMax),
          ];
    for (var i = 0; i < routine.length; i++) {
      final ex = byId[routine[i].exerciseId];
      if (ex == null) continue;
      final d = _build(routine[i], ex, sessions);
      if (restoreFrom != null) {
        final snap = restoreFrom.exercises[i];
        for (var k = 0; k < snap.sets.length && k < d.sets.length; k++) {
          d.sets[k]
            ..weightKg = snap.sets[k].weightKg
            ..reps = snap.sets[k].reps
            ..done = snap.sets[k].done;
        }
        d.expanded = snap.expanded;
        d.suggestionUsed = snap.suggestionUsed;
      }
      drafts.add(d);
    }
    final t = workout.cardioFinisher;
    if (t != null) {
      cardio = CardioDraft(
        kind: t.kind,
        targetMinutes: t.durationMinutes,
        speedKmh: t.speedKmh,
        inclinePct: t.inclinePct,
        resistance: t.resistance,
        clock: _clock,
      )..addListener(notifyListeners);
    }
    if (restoreFrom == null || !drafts.any((d) => d.expanded)) _expandFirstIncomplete();
    notes = restoreFrom?.notes ?? '';
    persistEnabled = true;
  }

  final Workout workout;
  final UserProfile profile;
  final List<Exercise> _catalog;
  final DateTime Function() _clock;
  final DateTime startedAt;
  final DeviceFeedback feedback;
  final WorkoutDraftStore? draftStore;
  final DateTime? backdate;
  final Duration draftDebounce;
  final List<ExerciseDraft> drafts = [];
  final ValueNotifier<RestState?> rest = ValueNotifier(null);

  /// Fires only when the page structure changes (cardio block added / removed),
  /// not on every edit, so the page shell does not rebuild per set.
  final ValueNotifier<int> layout = ValueNotifier(0);
  CardioDraft? cardio;
  String notes = '';

  Timer? _draftTimer;
  Timer? _restTimer;
  /// Lets the page hold persistence back while a conflicting older draft is being resolved.
  bool persistEnabled = false;
  bool _closed = false;

  static ExerciseDraft _buildStatic(RoutineExercise re, Exercise ex, SessionRepository sessions, UserProfile profile,
      {DateTime? now}) {
    final last = sessions.lastWithExercise(ex.id);
    final prev = last == null
        ? <SetLog>[]
        : last.exercises.firstWhere((l) => l.exerciseId == ex.id).doneSets.toList();
    final priorSessions = sessions.sessions
        .where((s) => s.exercises.any((l) => l.exerciseId == ex.id && l.doneSets.isNotEmpty))
        .length;
    final rec = profile.progressionEnabled && last != null
        ? ProgressionService.recommend(
            lastSets: prev,
            repMin: re.repMin,
            repMax: re.repMax,
            increment: ProgressionService.incrementFor(ex, profile.unit),
            unit: profile.unit,
            priorSessions: priorSessions,
            lastSessionDate: last.workoutDate,
            now: now,
            exercise: ex,
          )
        : null;
    // Always prefill LAST time's numbers; an increase is only ever a tappable suggestion.
    final sets = <SetDraft>[];
    for (var i = 0; i < re.sets; i++) {
      if (prev.isNotEmpty) {
        final p = prev[i < prev.length ? i : prev.length - 1];
        sets.add(SetDraft(weightKg: p.weightKg, reps: p.reps));
      } else {
        sets.add(SetDraft(weightKg: 0, reps: re.repMin));
      }
    }
    return ExerciseDraft(
        exercise: ex, sets: sets, repMin: re.repMin, repMax: re.repMax, prevSets: prev, recommendation: rec);
  }

  ExerciseDraft _build(RoutineExercise re, Exercise ex, SessionRepository sessions) =>
      _buildStatic(re, ex, sessions, profile, now: _clock());

  bool get isMixed => cardio != null;

  List<DraftSection>? _sections;

  /// Muscle sections of the running workout (order preserved, grouping rule lives in
  /// [WorkoutSections]). Memoized; recomputed only when an exercise is swapped.
  List<DraftSection> get sections => _sections ??= _computeSections();

  List<DraftSection> _computeSections() {
    final routine = [
      for (final d in drafts) RoutineExercise(exerciseId: d.exercise.id, sets: d.sets.length, repMin: d.repMin, repMax: d.repMax),
    ];
    // Drafts are never reordered: contiguous runs only.
    final groups = WorkoutSections.groupContiguous(routine, _catalog);
    final covered = groups.fold<int>(0, (a, g) => a + g.items.length);
    if (covered != drafts.length) {
      // Some exercise is missing from the catalog: never drop it, show one flat section.
      return [DraftSection(label: '', drafts: List.unmodifiable(drafts), startIndex: 0)];
    }
    return [
      for (final g in groups)
        DraftSection(
          label: g.label,
          drafts: List.unmodifiable(drafts.sublist(g.startIndex, g.startIndex + g.items.length)),
          startIndex: g.startIndex,
          groups: () {
            var at = g.startIndex;
            return [
              for (final sub in g.groups)
                DraftGroup(
                  label: sub.label,
                  drafts: List.unmodifiable(drafts.sublist(at, at += sub.items.length)),
                  startIndex: at - sub.items.length,
                ),
            ];
          }(),
        ),
    ];
  }

  int get elapsedSeconds => _clock().difference(startedAt).inSeconds;

  // ── derived ──
  int get totalSets => drafts.fold(0, (a, d) => a + d.sets.length);
  int get doneSets => drafts.fold(0, (a, d) => a + d.doneCount);
  int get remainingSets => totalSets - doneSets;
  double get volumeKg => drafts.fold(0.0, (a, d) => a + d.volume);
  int get completedExercises => drafts.where((d) => d.complete).length;
  bool get hasLoggedAnything => doneSets > 0 || (cardio?.started ?? false);

  /// 0-based index of the first incomplete exercise (or the last one).
  int get currentIndex {
    final i = drafts.indexWhere((d) => !d.complete);
    return i < 0 ? (drafts.isEmpty ? 0 : drafts.length - 1) : i;
  }

  int get itemsTotal => drafts.length + (cardio == null ? 0 : 1);
  int get itemsDone => completedExercises + ((cardio?.complete ?? false) ? 1 : 0);

  // ── draft persistence ──
  WorkoutDraft toDraft() => WorkoutDraft(
        workoutId: workout.id,
        workoutName: workout.name,
        startedAt: startedAt,
        savedAt: _clock(),
        currentIndex: currentIndex,
        notes: notes,
        backdate: backdate,
        exercises: [
          for (final d in drafts)
            DraftExercise(
              exerciseId: d.exercise.id,
              repMin: d.repMin,
              repMax: d.repMax,
              expanded: d.expanded,
              suggestionUsed: d.suggestionUsed,
              sets: [for (final s in d.sets) DraftSet(weightKg: s.weightKg, reps: s.reps, done: s.done)],
            ),
        ],
      );

  /// Lets the page hold persistence back while a conflicting older draft is being resolved.

  /// The controller's clock (injectable in tests).
  DateTime now() => _clock();

  @override
  void notifyListeners() {
    super.notifyListeners();
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    if (draftStore == null || !persistEnabled || _closed) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(draftDebounce, () {
      _draftTimer = null;
      _writeDraft();
    });
  }

  Future<void> _writeDraft() async {
    final store = draftStore;
    if (store == null || _closed || !persistEnabled) return;
    try {
      // A workout with nothing logged is not worth resuming.
      if (hasLoggedAnything) {
        await store.save(toDraft());
      } else if (store.current != null) {
        await store.clear();
      }
    } catch (_) {
      // Best effort: a failed draft write must never break logging.
    }
  }

  /// Writes any pending change now (app going to background, page closing).
  Future<void> flushDraft() async {
    if (_draftTimer == null) return;
    _draftTimer!.cancel();
    _draftTimer = null;
    await _writeDraft();
  }

  /// Finished or discarded: drop the draft and stop persisting.
  Future<void> discardDraft() async {
    _closed = true;
    _draftTimer?.cancel();
    _draftTimer = null;
    try {
      await draftStore?.clear();
    } catch (_) {}
  }

  // ── mutations ──
  /// Opens the first unfinished exercise and collapses the rest; returns the drafts that changed.
  List<ExerciseDraft> _expandFirstIncomplete() {
    final i = drafts.indexWhere((d) => !d.complete);
    final changed = <ExerciseDraft>[];
    for (var k = 0; k < drafts.length; k++) {
      final want = k == i;
      if (drafts[k].expanded != want) {
        drafts[k].expanded = want;
        changed.add(drafts[k]);
      }
    }
    return changed;
  }

  void toggleExpanded(ExerciseDraft d) {
    d.expanded = !d.expanded;
    d.touch();
    notifyListeners();
  }

  /// Weighted work must not be logged at 0 kg: the caller opens the weight keypad instead.
  bool needsWeight(ExerciseDraft d, int i) =>
      !d.sets[i].done && d.sets[i].weightKg <= 0 && !d.exercise.equipment.isUnloaded;

  /// Toggles a set. Returns false (nothing changed) when [needsWeight].
  bool toggleSet(ExerciseDraft d, int i) {
    if (needsWeight(d, i)) return false;
    final s = d.sets[i];
    s.done = !s.done;
    if (s.done) {
      feedback.setDone();
      final secs = profile.autoRestSeconds;
      // Rest also runs between exercises; only the very last set of the workout skips it.
      if (remainingSets > 0 && secs > 0) {
        _startRest(secs);
      } else {
        _stopRest();
      }
      if (d.complete) {
        // Collapse the finished exercise and open the next unfinished one.
        d.expanded = false;
        for (final o in _expandFirstIncomplete()) {
          if (!identical(o, d)) o.touch();
        }
      }
    }
    d.touch();
    notifyListeners();
    return true;
  }

  void setWeight(ExerciseDraft d, int i, double kg) {
    final old = d.sets[i].weightKg;
    final v = kg < 0 ? 0.0 : kg;
    d.sets[i].weightKg = v;
    if (!d.sets[i].done) {
      for (var j = i + 1; j < d.sets.length; j++) {
        if (!d.sets[j].done && d.sets[j].weightKg == old) d.sets[j].weightKg = v;
      }
    }
    d.touch();
    notifyListeners();
  }

  void setReps(ExerciseDraft d, int i, int reps) {
    final old = d.sets[i].reps;
    final v = reps < 0 ? 0 : reps;
    d.sets[i].reps = v;
    if (!d.sets[i].done) {
      for (var j = i + 1; j < d.sets.length; j++) {
        if (!d.sets[j].done && d.sets[j].reps == old) d.sets[j].reps = v;
      }
    }
    d.touch();
    notifyListeners();
  }

  /// ± stepper: moves the weight by one unit-appropriate step (2.5 kg / 5 lb).
  void stepWeight(ExerciseDraft d, int i, int direction, WeightUnit unit) {
    final step = unit == WeightUnit.kg ? 2.5 : 5.0;
    final shown = Fmt.toDisplayWeight(d.sets[i].weightKg, unit) + direction * step;
    final rounded = (shown * 2).round() / 2;
    setWeight(d, i, Fmt.fromDisplayWeight(rounded < 0 ? 0 : rounded, unit));
  }

  void stepReps(ExerciseDraft d, int i, int direction) => setReps(d, i, d.sets[i].reps + direction);

  /// "Same as last set": copies weight and reps of the previous set.
  void sameAsLast(ExerciseDraft d, int i) {
    if (i <= 0) return;
    d.sets[i]
      ..weightKg = d.sets[i - 1].weightKg
      ..reps = d.sets[i - 1].reps;
    d.touch();
    notifyListeners();
  }

  /// Applies the progression suggestion to every set not yet done.
  void useSuggestion(ExerciseDraft d) {
    final r = d.recommendation;
    if (r == null) return;
    for (final s in d.sets) {
      if (s.done) continue;
      s.weightKg = r.weightKg;
      s.reps = r.repMin;
    }
    d.suggestionUsed = true;
    d.touch();
    notifyListeners();
  }

  void addSet(ExerciseDraft d) {
    final last = d.sets.isEmpty ? null : d.sets.last;
    d.sets.add(SetDraft(weightKg: last?.weightKg ?? 0, reps: last?.reps ?? d.repMin));
    d.expanded = true;
    d.touch();
    notifyListeners();
  }

  /// Removes set [i] and returns it (for undo), or null when it is the last remaining set.
  SetDraft? removeSet(ExerciseDraft d, int i) {
    if (d.sets.length <= 1) return null;
    final s = d.sets.removeAt(i);
    d.touch();
    notifyListeners();
    return s;
  }

  void insertSet(ExerciseDraft d, int i, SetDraft s) {
    d.sets.insert(i.clamp(0, d.sets.length), s);
    d.touch();
    notifyListeners();
  }

  /// Swap [d]'s exercise for [replacement] inside this session only.
  void replaceExercise(ExerciseDraft d, Exercise replacement, SessionRepository sessions) {
    final before = [for (final x in sections) '${x.label}:${x.drafts.length}:${x.groups.length}'].join('|');
    final fresh = _buildStatic(
        RoutineExercise(exerciseId: replacement.id, sets: d.sets.length, repMin: d.repMin, repMax: d.repMax),
        replacement,
        sessions,
        profile,
        now: _clock());
    d.exercise = replacement;
    d.prevSets = fresh.prevSets;
    d.recommendation = fresh.recommendation;
    d.suggestionUsed = false;
    for (var i = 0; i < d.sets.length; i++) {
      d.sets[i]
        ..done = false
        ..weightKg = fresh.sets[i].weightKg
        ..reps = fresh.sets[i].reps;
    }
    d.expanded = true;
    d.touch();
    _sections = null;
    if ([for (final x in sections) '${x.label}:${x.drafts.length}:${x.groups.length}'].join('|') != before) layout.value++;
    notifyListeners();
  }

  // ── rest ──
  void _startRest(int secs) {
    rest.value = RestState(endsAt: _clock().add(Duration(seconds: secs)), totalSeconds: secs);
    _scheduleRestEnd();
  }

  void _stopRest() {
    _restTimer?.cancel();
    _restTimer = null;
    rest.value = null;
  }

  void _scheduleRestEnd() {
    _restTimer?.cancel();
    final r = rest.value;
    if (r == null) return;
    var wait = r.endsAt.difference(_clock());
    if (wait.isNegative) wait = Duration.zero;
    _restTimer = Timer(wait, () {
      _restTimer = null;
      if (rest.value != null) feedback.restEnded();
    });
  }

  void skipRest() => _stopRest();

  void addRest(int seconds) {
    final r = rest.value;
    if (r == null) return;
    rest.value = RestState(endsAt: r.endsAt.add(Duration(seconds: seconds)), totalSeconds: r.totalSeconds + seconds);
    _scheduleRestEnd();
  }

  void addCardio(CardioKind kind) {
    cardio?.removeListener(notifyListeners);
    cardio = CardioDraft(kind: kind, clock: _clock)..addListener(notifyListeners);
    layout.value++;
    notifyListeners();
  }

  void removeCardio() {
    cardio?.removeListener(notifyListeners);
    cardio?.dispose();
    cardio = null;
    layout.value++;
    notifyListeners();
  }

  /// Builds the history entry. Only logged (done) sets are kept; exercises with
  /// none are dropped. [workoutDate] is the user's date (backdatable) and is
  /// independent of `meta.createdAt`, which is stamped now.
  WorkoutSession buildSession({required String id, required DateTime workoutDate}) {
    final logs = <ExerciseLog>[];
    for (final d in drafts) {
      final sets = [
        for (final s in d.sets)
          if (s.done) SetLog(weightKg: s.weightKg, reps: s.reps),
      ];
      if (sets.isNotEmpty) logs.add(ExerciseLog(exerciseId: d.exercise.id, sets: sets));
    }
    return WorkoutSession(
      id: id,
      workoutId: workout.id,
      name: workout.name,
      workoutDate: workoutDate,
      exercises: logs,
      durationSeconds: elapsedSeconds,
      cardio: cardio?.toSession(id: '${id}_c', workoutDate: workoutDate),
      meta: SyncMeta(createdAt: _clock()),
    );
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    // Persist a pending change that the debounce has not written yet.
    if (_draftTimer != null && !_closed) {
      _draftTimer!.cancel();
      _draftTimer = null;
      _writeDraft();
    }
    _closed = true;
    cardio?.removeListener(notifyListeners);
    cardio?.dispose();
    rest.dispose();
    layout.dispose();
    for (final d in drafts) {
      d.dispose();
    }
    super.dispose();
  }
}
