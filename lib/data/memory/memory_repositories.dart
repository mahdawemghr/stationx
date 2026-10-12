import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';
import '../data_store.dart';
import '../seed/seed_data.dart';

/// In-memory implementations of the repository contracts.
/// MOCK persistence: data resets on app restart. Swap for Isar-backed classes.

class MemoryExerciseRepository extends ChangeNotifier
    implements ExerciseRepository {
  MemoryExerciseRepository(List<Exercise> seed)
    : _items = [...seed],
      _index = {for (final e in seed) e.id: e};
  final List<Exercise> _items;
  final Map<String, Exercise> _index;

  /// Replace the whole catalogue (used by DataStore.replaceAll).
  void reset(List<Exercise> seed) {
    _items
      ..clear()
      ..addAll(seed);
    _index
      ..clear()
      ..addAll({for (final e in seed) e.id: e});
    notifyListeners();
  }

  @override
  List<Exercise> get all => List.unmodifiable(_items);
  @override
  Exercise? byId(String id) => _index[id];
  @override
  Future<void> addCustom(Exercise e) async {
    _items.add(e);
    _index[e.id] = e;
    notifyListeners();
  }

  /// Replaces the exercise with the same id in place (an idempotent retry of [addCustom]).
  @protected
  void replaceCustom(Exercise e) {
    final i = _items.indexWhere((x) => x.id == e.id);
    if (i < 0) return;
    _items[i] = e;
    _index[e.id] = e;
    notifyListeners();
  }
}

class MemoryWorkoutRepository extends ChangeNotifier
    implements WorkoutRepository {
  MemoryWorkoutRepository(List<Workout> workouts, this._rotation)
    : _items = [...workouts];
  final List<Workout> _items;
  Rotation _rotation;

  void reset(List<Workout> workouts, Rotation rotation) {
    _items
      ..clear()
      ..addAll(workouts);
    _rotation = rotation;
    notifyListeners();
  }

  @override
  List<Workout> get workouts => List.unmodifiable(_items);
  @override
  Workout? byId(String id) {
    for (final w in _items) {
      if (w.id == id) return w;
    }
    return null;
  }

  @override
  Rotation get rotation => _rotation;
  @override
  Workout? get currentWorkout => _rotation.currentWorkoutId == null
      ? null
      : byId(_rotation.currentWorkoutId!);
  @override
  Workout? get nextWorkout =>
      _rotation.nextWorkoutId == null ? null : byId(_rotation.nextWorkoutId!);

  /// Pure plan for saving [w]: the resulting workout list + rotation (a NEW workout is appended to
  /// the rotation). Persistence layers write the plan FIRST and call [reset] afterwards.
  @protected
  (List<Workout>, Rotation) planSave(Workout w) {
    final items = [..._items];
    final i = items.indexWhere((x) => x.id == w.id);
    if (i >= 0) {
      items[i] = w;
      return (items, _rotation);
    }
    items.add(w);
    return (
      items,
      _rotation.copyWith(workoutIds: [..._rotation.workoutIds, w.id]),
    );
  }

  /// Pure plan for deleting [id]. The CURRENT workout keeps its identity: removing an entry before
  /// it shifts the index down; removing the current one hands over to its successor (same index,
  /// wrapped); removing one after it, or one that is not in the rotation (archived), leaves the
  /// pointer on the same workout.
  @protected
  (List<Workout>, Rotation) planDelete(String id) {
    final items = _items.where((x) => x.id != id).toList();
    final old = _rotation.workoutIds;
    final r = old.indexOf(id);
    if (r < 0) return (items, _rotation);
    final ids = [...old]..removeAt(r);
    if (ids.isEmpty) return (items, const Rotation(workoutIds: []));
    final cur = _rotation.currentIndex % old.length;
    final idx = r < cur ? cur - 1 : (r == cur ? cur % ids.length : cur);
    return (items, Rotation(workoutIds: ids, currentIndex: idx));
  }

  @override
  Future<void> saveWorkout(Workout w) async {
    final (items, rot) = planSave(w);
    reset(items, rot);
  }

  @override
  Future<void> deleteWorkout(String id) async {
    final (items, rot) = planDelete(id);
    reset(items, rot);
  }

  @override
  Future<void> setRotation(Rotation r) async {
    _rotation = r;
    notifyListeners();
  }

  /// Pure plan for [saveSchedule]: the list with [ws] added/replaced.
  @protected
  List<Workout> planSchedule(List<Workout> ws) {
    final items = [..._items];
    for (final w in ws) {
      final i = items.indexWhere((x) => x.id == w.id);
      if (i >= 0) {
        items[i] = w;
      } else {
        items.add(w);
      }
    }
    return items;
  }

  @override
  Future<void> saveSchedule(List<Workout> ws, Rotation rotation) async {
    reset(planSchedule(ws), rotation);
  }

  @override
  Future<void> setCurrentWorkout(String workoutId) =>
      setRotation(RotationService.pointAt(_rotation, workoutId));

  @override
  Future<void> advanceRotation() =>
      setRotation(RotationService.advance(_rotation));
}

class MemorySessionRepository extends ChangeNotifier
    implements SessionRepository {
  MemorySessionRepository(List<WorkoutSession> seed) : _items = [...seed] {
    _sort();
  }
  final List<WorkoutSession> _items;
  void _sort() => _items.sort((a, b) => b.workoutDate.compareTo(a.workoutDate));

  void reset(List<WorkoutSession> seed) {
    _items
      ..clear()
      ..addAll(seed);
    _sort();
    notifyListeners();
  }

  @override
  List<WorkoutSession> get sessions => List.unmodifiable(_items);
  @override
  WorkoutSession? byId(String id) {
    for (final s in _items) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<void> add(WorkoutSession s) async {
    _items.add(s);
    _sort();
    notifyListeners();
  }

  @override
  Future<void> addAll(List<WorkoutSession> sessions) async {
    _items.addAll(sessions);
    _sort();
    notifyListeners();
  }

  @override
  Future<void> update(WorkoutSession s) async {
    final i = _items.indexWhere((x) => x.id == s.id);
    if (i < 0) {
      return; // never resurrects a deleted row (same as the Isar repositories)
    }
    _items[i] = s;
    _sort();
    notifyListeners();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  @override
  List<WorkoutSession> between(DateTime from, DateTime to) => _items
      .where((s) => !s.workoutDate.isBefore(from) && s.workoutDate.isBefore(to))
      .toList();

  @override
  WorkoutSession? lastWithExercise(String exerciseId, {String? excludeId}) {
    for (final s in _items) {
      if (s.id == excludeId) continue;
      if (s.exercises.any(
        (e) => e.exerciseId == exerciseId && e.doneSets.isNotEmpty,
      )) {
        return s;
      }
    }
    return null;
  }
}

class MemoryCardioRepository extends ChangeNotifier
    implements CardioRepository {
  MemoryCardioRepository(List<CardioSession> sessions, List<CardioGoal> goals)
    : _items = [...sessions],
      _goals = [...goals] {
    _sort();
  }
  final List<CardioSession> _items;
  final List<CardioGoal> _goals;
  final List<CustomCardioActivity> _custom = [];
  void _sort() => _items.sort((a, b) => b.workoutDate.compareTo(a.workoutDate));

  void reset(
    List<CardioSession> sessions,
    List<CardioGoal> goals,
    List<CustomCardioActivity> custom,
  ) {
    _items
      ..clear()
      ..addAll(sessions);
    _goals
      ..clear()
      ..addAll(goals);
    _custom
      ..clear()
      ..addAll(custom);
    _sort();
    notifyListeners();
  }

  @override
  List<CardioSession> get sessions => List.unmodifiable(_items);
  @override
  CardioSession? byId(String id) {
    for (final s in _items) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<void> add(CardioSession s) async {
    _items.add(s);
    _sort();
    notifyListeners();
  }

  @override
  Future<void> update(CardioSession s) async {
    final i = _items.indexWhere((x) => x.id == s.id);
    if (i < 0) {
      return; // never resurrects a deleted row (same as the Isar repositories)
    }
    _items[i] = s;
    _sort();
    notifyListeners();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  @override
  List<CardioSession> between(DateTime from, DateTime to) => _items
      .where((s) => !s.workoutDate.isBefore(from) && s.workoutDate.isBefore(to))
      .toList();

  @override
  List<CardioGoal> get goals => List.unmodifiable(_goals);
  @override
  Future<void> saveGoal(CardioGoal g) async {
    final i = _goals.indexWhere((x) => x.id == g.id);
    if (i >= 0) {
      _goals[i] = g;
    } else {
      _goals.add(g);
    }
    notifyListeners();
  }

  @override
  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  @override
  List<CustomCardioActivity> get customActivities => List.unmodifiable(_custom);
  @override
  Future<void> addCustomActivity(CustomCardioActivity a) async {
    _custom.add(a);
    notifyListeners();
  }

  /// Replaces the custom activity with the same id in place (an idempotent retry).
  @protected
  void replaceCustomActivity(CustomCardioActivity a) {
    final i = _custom.indexWhere((x) => x.id == a.id);
    if (i < 0) return;
    _custom[i] = a;
    notifyListeners();
  }
}

class MemoryProfileRepository extends ChangeNotifier
    implements ProfileRepository {
  MemoryProfileRepository([this._profile = const UserProfile()]);
  UserProfile _profile;
  void reset(UserProfile p) {
    _profile = p;
    notifyListeners();
  }

  @override
  UserProfile get profile => _profile;
  @override
  Future<void> update(UserProfile p) async {
    _profile = p;
    notifyListeners();
  }
}

/// Volatile draft store (tests / previews). Production uses IsarWorkoutDraftStore.
/// Holds the draft as a JSON string (like the persistent store) so tests exercise
/// the real serialisation. Unreadable data reads as "no draft".
class MemoryWorkoutDraftStore extends ChangeNotifier
    implements WorkoutDraftStore {
  MemoryWorkoutDraftStore([this._json]);
  String? _json;

  /// Raw stored value (persistence layers mirror this).
  String? get rawJson => _json;

  static WorkoutDraft? decode(String? json) {
    if (json == null) return null;
    try {
      return WorkoutDraft.fromJson(
        (jsonDecode(json) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  WorkoutDraft? get current => decode(_json);

  @override
  Future<void> save(WorkoutDraft draft) async {
    _json = jsonEncode(draft.toJson());
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    if (_json == null) return;
    _json = null;
    notifyListeners();
  }
}

class MemoryCardioDraftStore extends ChangeNotifier
    implements CardioDraftStore {
  MemoryCardioDraftStore([this._json]);
  String? _json;

  String? get rawJson => _json;

  static ActiveCardioDraft? decode(String? json) {
    if (json == null) return null;
    try {
      return ActiveCardioDraft.fromJson(
        (jsonDecode(json) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  ActiveCardioDraft? get current => decode(_json);

  @override
  Future<void> save(ActiveCardioDraft draft) async {
    _json = jsonEncode(draft.toJson());
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    if (_json == null) return;
    _json = null;
    notifyListeners();
  }
}

class MemoryStore implements DataStore {
  MemoryStore(SeedData seed, {UserProfile profile = const UserProfile()})
    : exercises = MemoryExerciseRepository(seed.exercises),
      workouts = MemoryWorkoutRepository(seed.workouts, seed.rotation),
      sessions = MemorySessionRepository(seed.sessions),
      cardio = MemoryCardioRepository(seed.cardio, seed.goals),
      profile = MemoryProfileRepository(profile),
      workoutDraft = MemoryWorkoutDraftStore(),
      cardioDraft = MemoryCardioDraftStore();

  @override
  final MemoryExerciseRepository exercises;
  @override
  final MemoryWorkoutRepository workouts;
  @override
  final MemorySessionRepository sessions;
  @override
  final MemoryCardioRepository cardio;
  @override
  final MemoryProfileRepository profile;
  @override
  final MemoryWorkoutDraftStore workoutDraft;
  @override
  final MemoryCardioDraftStore cardioDraft;

  /// Replaces all data (tests / previews).
  Future<void> replaceAll(SeedData seed, UserProfile profile) async {
    exercises.reset(seed.exercises);
    workouts.reset(seed.workouts, seed.rotation);
    sessions.reset(seed.sessions);
    cardio.reset(seed.cardio, seed.goals, const []);
    this.profile.reset(profile);
    await workoutDraft.clear();
    await cardioDraft.clear();
  }

  @override
  Future<void> load({required String userId, required String username}) async {}

  @override
  Future<void> clear() async {
    await replaceAll(SeedData.fresh(), const UserProfile());
  }

  @override
  Future<void> resetData() => replaceAll(SeedData.fresh(), profile.profile);

  @override
  Future<void> close() async {}
}
