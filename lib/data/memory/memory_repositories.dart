import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';
import '../seed/seed_data.dart';

/// In-memory implementations of the repository contracts.
/// MOCK persistence: data resets on app restart. Swap for Isar-backed classes.

class MemoryExerciseRepository extends ChangeNotifier implements ExerciseRepository {
  MemoryExerciseRepository(List<Exercise> seed)
      : _items = [...seed],
        _index = {for (final e in seed) e.id: e};
  final List<Exercise> _items;
  final Map<String, Exercise> _index;

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
}

class MemoryWorkoutRepository extends ChangeNotifier implements WorkoutRepository {
  MemoryWorkoutRepository(List<Workout> workouts, this._rotation) : _items = [...workouts];
  final List<Workout> _items;
  Rotation _rotation;

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
  Workout? get currentWorkout => _rotation.currentWorkoutId == null ? null : byId(_rotation.currentWorkoutId!);
  @override
  Workout? get nextWorkout => _rotation.nextWorkoutId == null ? null : byId(_rotation.nextWorkoutId!);

  @override
  Future<void> saveWorkout(Workout w) async {
    final i = _items.indexWhere((x) => x.id == w.id);
    if (i >= 0) {
      _items[i] = w;
    } else {
      _items.add(w);
      _rotation = _rotation.copyWith(workoutIds: [..._rotation.workoutIds, w.id]);
    }
    notifyListeners();
  }

  @override
  Future<void> deleteWorkout(String id) async {
    _items.removeWhere((x) => x.id == id);
    final ids = _rotation.workoutIds.where((x) => x != id).toList();
    _rotation = Rotation(workoutIds: ids, currentIndex: ids.isEmpty ? 0 : _rotation.currentIndex % ids.length);
    notifyListeners();
  }

  @override
  Future<void> setRotation(Rotation r) async {
    _rotation = r;
    notifyListeners();
  }

  @override
  Future<void> setCurrentWorkout(String workoutId) => setRotation(RotationService.pointAt(_rotation, workoutId));

  @override
  Future<void> advanceRotation() => setRotation(RotationService.advance(_rotation));
}

class MemorySessionRepository extends ChangeNotifier implements SessionRepository {
  MemorySessionRepository(List<WorkoutSession> seed) : _items = [...seed] {
    _sort();
  }
  final List<WorkoutSession> _items;
  void _sort() => _items.sort((a, b) => b.workoutDate.compareTo(a.workoutDate));

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
  Future<void> update(WorkoutSession s) async {
    final i = _items.indexWhere((x) => x.id == s.id);
    if (i >= 0) _items[i] = s;
    _sort();
    notifyListeners();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  @override
  List<WorkoutSession> between(DateTime from, DateTime to) =>
      _items.where((s) => !s.workoutDate.isBefore(from) && s.workoutDate.isBefore(to)).toList();

  @override
  WorkoutSession? lastWithExercise(String exerciseId, {String? excludeId}) {
    for (final s in _items) {
      if (s.id == excludeId) continue;
      if (s.exercises.any((e) => e.exerciseId == exerciseId && e.doneSets.isNotEmpty)) return s;
    }
    return null;
  }
}

class MemoryCardioRepository extends ChangeNotifier implements CardioRepository {
  MemoryCardioRepository(List<CardioSession> sessions, List<CardioGoal> goals)
      : _items = [...sessions],
        _goals = [...goals] {
    _sort();
  }
  final List<CardioSession> _items;
  final List<CardioGoal> _goals;
  final List<CustomCardioActivity> _custom = [];
  void _sort() => _items.sort((a, b) => b.workoutDate.compareTo(a.workoutDate));

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
    if (i >= 0) _items[i] = s;
    _sort();
    notifyListeners();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  @override
  List<CardioSession> between(DateTime from, DateTime to) =>
      _items.where((s) => !s.workoutDate.isBefore(from) && s.workoutDate.isBefore(to)).toList();

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
}

class MemoryProfileRepository extends ChangeNotifier implements ProfileRepository {
  MemoryProfileRepository([this._profile = const UserProfile()]);
  UserProfile _profile;
  @override
  UserProfile get profile => _profile;
  @override
  Future<void> update(UserProfile p) async {
    _profile = p;
    notifyListeners();
  }
}

/// Builds a full set of repositories from a seed.
class MemoryStore {
  MemoryStore(SeedData seed, {UserProfile profile = const UserProfile()})
      : exercises = MemoryExerciseRepository(seed.exercises),
        workouts = MemoryWorkoutRepository(seed.workouts, seed.rotation),
        sessions = MemorySessionRepository(seed.sessions),
        cardio = MemoryCardioRepository(seed.cardio, seed.goals),
        profile = MemoryProfileRepository(profile);

  final MemoryExerciseRepository exercises;
  final MemoryWorkoutRepository workouts;
  final MemorySessionRepository sessions;
  final MemoryCardioRepository cardio;
  final MemoryProfileRepository profile;
}
