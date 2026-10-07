import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';

/// One working set while the workout is in progress.
class SetDraft {
  SetDraft({required this.weightKg, required this.reps, this.done = false});
  double weightKg;
  int reps;
  bool done;
}

/// One exercise slot of the running workout.
class ExerciseDraft {
  ExerciseDraft({
    required this.exercise,
    required this.sets,
    required this.repMin,
    required this.repMax,
    this.prevSets = const [],
    this.recommendation,
    this.expanded = false,
  });

  Exercise exercise;
  final List<SetDraft> sets;
  final int repMin;
  final int repMax;

  /// Done sets of the most recent earlier session (PREV column).
  List<SetLog> prevSets;

  /// From ProgressionService — null hides the Smart Overload card.
  ProgressionRecommendation? recommendation;
  bool expanded;

  int get doneCount => sets.where((s) => s.done).length;
  bool get complete => sets.isNotEmpty && doneCount == sets.length;
  int get remaining => sets.length - doneCount;
  double get volume => sets.where((s) => s.done).fold(0.0, (a, s) => a + s.weightKg * s.reps);

  /// Index of the first set not yet done (the "active" row), or -1.
  int get activeSetIndex => sets.indexWhere((s) => !s.done);
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

/// State of a running workout. Pure logic, no widgets. Per-second clocks live
/// in their own widgets (see widgets/timers.dart) so this only notifies on real
/// changes (set logged, exercise swapped, ...).
class ActiveWorkoutController extends ChangeNotifier {
  ActiveWorkoutController({
    required this.workout,
    required List<Exercise> catalog,
    required SessionRepository sessions,
    required this.profile,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        startedAt = (clock ?? DateTime.now)() {
    final byId = {for (final e in catalog) e.id: e};
    for (final re in workout.exercises) {
      final ex = byId[re.exerciseId];
      if (ex == null) continue;
      drafts.add(_build(re, ex, sessions));
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
    _expandFirstIncomplete();
  }

  final Workout workout;
  final UserProfile profile;
  final DateTime Function() _clock;
  final DateTime startedAt;
  final List<ExerciseDraft> drafts = [];
  final ValueNotifier<RestState?> rest = ValueNotifier(null);
  CardioDraft? cardio;

  static ExerciseDraft _buildStatic(RoutineExercise re, Exercise ex, SessionRepository sessions, UserProfile profile) {
    final last = sessions.lastWithExercise(ex.id);
    final prev = last == null
        ? <SetLog>[]
        : last.exercises.firstWhere((l) => l.exerciseId == ex.id).doneSets.toList();
    final rec = profile.progressionEnabled
        ? ProgressionService.recommend(
            lastSets: prev,
            repMin: re.repMin,
            repMax: re.repMax,
            incrementKg: ProgressionService.incrementFor(ex),
          )
        : null;
    final sets = <SetDraft>[];
    for (var i = 0; i < re.sets; i++) {
      if (rec != null) {
        sets.add(SetDraft(weightKg: rec.weightKg, reps: rec.repMin));
      } else if (prev.isNotEmpty) {
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
      _buildStatic(re, ex, sessions, profile);

  bool get isMixed => cardio != null;

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

  // ── mutations ──
  void _expandFirstIncomplete() {
    final i = drafts.indexWhere((d) => !d.complete);
    for (var k = 0; k < drafts.length; k++) {
      drafts[k].expanded = k == i;
    }
  }

  void toggleExpanded(ExerciseDraft d) {
    d.expanded = !d.expanded;
    notifyListeners();
  }

  void toggleSet(ExerciseDraft d, int i) {
    final s = d.sets[i];
    s.done = !s.done;
    if (s.done) {
      final secs = profile.autoRestSeconds;
      if (!d.complete && secs > 0) {
        rest.value = RestState(endsAt: _clock().add(Duration(seconds: secs)), totalSeconds: secs);
      } else {
        rest.value = null;
      }
      if (d.complete) {
        // Collapse the finished exercise and open the next unfinished one.
        d.expanded = false;
        _expandFirstIncomplete();
      }
    }
    notifyListeners();
  }

  void setWeight(ExerciseDraft d, int i, double kg) {
    d.sets[i].weightKg = kg < 0 ? 0 : kg;
    notifyListeners();
  }

  void setReps(ExerciseDraft d, int i, int reps) {
    d.sets[i].reps = reps < 0 ? 0 : reps;
    notifyListeners();
  }

  void addSet(ExerciseDraft d) {
    final last = d.sets.isEmpty ? null : d.sets.last;
    d.sets.add(SetDraft(weightKg: last?.weightKg ?? 0, reps: last?.reps ?? d.repMin));
    d.expanded = true;
    notifyListeners();
  }

  void removeSet(ExerciseDraft d, int i) {
    if (d.sets.length <= 1) return;
    d.sets.removeAt(i);
    notifyListeners();
  }

  /// Swap [d]'s exercise for [replacement] inside this session only.
  void replaceExercise(ExerciseDraft d, Exercise replacement, SessionRepository sessions) {
    final fresh = _buildStatic(
        RoutineExercise(exerciseId: replacement.id, sets: d.sets.length, repMin: d.repMin, repMax: d.repMax),
        replacement,
        sessions,
        profile);
    d.exercise = replacement;
    d.prevSets = fresh.prevSets;
    d.recommendation = fresh.recommendation;
    for (var i = 0; i < d.sets.length; i++) {
      d.sets[i]
        ..done = false
        ..weightKg = fresh.sets[i].weightKg
        ..reps = fresh.sets[i].reps;
    }
    d.expanded = true;
    notifyListeners();
  }

  void skipRest() {
    rest.value = null;
  }

  void addRest(int seconds) {
    final r = rest.value;
    if (r == null) return;
    rest.value = RestState(endsAt: r.endsAt.add(Duration(seconds: seconds)), totalSeconds: r.totalSeconds + seconds);
  }

  void addCardio(CardioKind kind) {
    cardio?.removeListener(notifyListeners);
    cardio = CardioDraft(kind: kind, clock: _clock)..addListener(notifyListeners);
    notifyListeners();
  }

  void removeCardio() {
    cardio?.removeListener(notifyListeners);
    cardio?.dispose();
    cardio = null;
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
    cardio?.removeListener(notifyListeners);
    cardio?.dispose();
    rest.dispose();
    super.dispose();
  }
}
