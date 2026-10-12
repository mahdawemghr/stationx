import 'dart:async';

import '../../domain/domain.dart';
import '../memory/memory_repositories.dart';
import 'remote_exception.dart';
import 'remote_gateway.dart';
import 'row_mappers.dart';

/// Shared by every online repository of one [OnlineStore].
///
/// * **Write lane**: all writes run one after another, so two quick taps (or a workout finish racing a
///   rotation change) can never interleave their server calls or compute a plan from a stale cache.
/// * **Epoch**: bumped whenever the signed-in user changes or is cleared. A write or load that started
///   under an older epoch never touches the read model afterwards, so a late response from user A can
///   not appear in user B's session.
class OnlineContext {
  OnlineContext(this.remote, {this.onAuthLost});

  final RemoteGateway remote;

  /// Called (at most once per burst) when the server says the session is no longer valid.
  void Function()? onAuthLost;

  int _epoch = 0;
  int get epoch => _epoch;
  void invalidate() => _epoch++;
  bool isCurrent(int epoch) => epoch == _epoch;

  Future<void> _tail = Future<void>.value();

  /// Writes started so far / currently queued or running (used to avoid applying a stale snapshot).
  int writeCount = 0;
  int pendingWrites = 0;

  /// Runs [op] after every previously queued write finished (successfully or not).
  Future<T> write<T>(Future<T> Function() op) {
    final done = Completer<T>();
    final prev = _tail;
    writeCount++;
    pendingWrites++;
    _tail = done.future.then<void>((_) {}, onError: (_) {});
    prev.whenComplete(() async {
      try {
        done.complete(await op());
      } on RemoteException catch (e, st) {
        if (e.kind == RemoteFailure.authExpired) onAuthLost?.call();
        done.completeError(e, st);
      } catch (e, st) {
        done.completeError(RemoteException.from(e), st);
      } finally {
        pendingWrites--;
        writeCount++;
      }
    });
    return done.future;
  }
}

class OnlineExerciseRepository extends MemoryExerciseRepository {
  OnlineExerciseRepository(this._c) : super(const []);
  final OnlineContext _c;

  @override
  Future<void> addCustom(Exercise e) => _c.write(() async {
    final epoch = _c.epoch;
    await _c.remote.upsert(RemoteTable.exercises, [exerciseToRow(e)]);
    if (!_c.isCurrent(epoch)) return;
    if (byId(e.id) != null) {
      replaceCustom(e);
    } else {
      await super.addCustom(e);
    }
  });
}

class OnlineWorkoutRepository extends MemoryWorkoutRepository {
  OnlineWorkoutRepository(this._c)
    : super(const [], const Rotation(workoutIds: []));
  final OnlineContext _c;

  /// One atomic server call for [items] + [rot] (+ deleted ids). The read model changes only afterwards.
  Future<void> _commit(
    List<Workout> items,
    Rotation rot, {
    List<String> deleted = const [],
  }) async {
    final epoch = _c.epoch;
    await _c.remote.rpc('sx_save_workouts', {
      'p_workouts': [
        for (var i = 0; i < items.length; i++) workoutToRow(items[i], i),
      ],
      'p_delete_ids': deleted,
      'p_rotation': rotationToRow(rot),
    });
    if (_c.isCurrent(epoch)) reset(items, rot);
  }

  // The plan is computed when the write's turn comes (not when it is requested), so it always starts
  // from the read model that every earlier write left behind.
  @override
  Future<void> saveWorkout(Workout w) => _c.write(() async {
    final epoch = _c.epoch;
    final (items, rot) = planSave(w);
    await _c.remote.rpc('sx_save_workouts', {
      'p_workouts': [
        for (var i = 0; i < items.length; i++) workoutToRow(items[i], i),
      ],
      'p_delete_ids': const <String>[],
      'p_rotation': rotationToRow(rot),
    });
    if (_c.isCurrent(epoch)) reset(items, rot);
  });

  @override
  Future<void> deleteWorkout(String id) => _c.write(() async {
    final epoch = _c.epoch;
    final (items, rot) = planDelete(id);
    await _c.remote.rpc('sx_save_workouts', {
      'p_workouts': [
        for (var i = 0; i < items.length; i++) workoutToRow(items[i], i),
      ],
      'p_delete_ids': [id],
      'p_rotation': rotationToRow(rot),
    });
    if (_c.isCurrent(epoch)) reset(items, rot);
  });

  /// Replaces the whole routine list and rotation in ONE atomic call (schedule builder).
  Future<void> replaceAll(List<Workout> items, Rotation rot) =>
      _c.write(() async {
        final removed = [
          for (final w in workouts)
            if (!items.any((x) => x.id == w.id)) w.id,
        ];
        await _commit(items, rot, deleted: removed);
      });

  /// Read-model update for a change the server already confirmed (see `OnlineStore.finishWorkout`).
  void setRotationFromServer(Rotation r) => unawaited(super.setRotation(r));

  @override
  Future<void> saveSchedule(List<Workout> ws, Rotation rotation) =>
      _c.write(() async {
        final epoch = _c.epoch;
        final items = planSchedule(ws);
        await _commit(items, rotation);
        if (!_c.isCurrent(epoch)) return;
      });

  @override
  Future<void> setRotation(Rotation r) => _c.write(() async {
    final epoch = _c.epoch;
    await _c.remote.upsert(RemoteTable.rotations, [rotationToRow(r)]);
    if (_c.isCurrent(epoch)) await super.setRotation(r);
  });
}

class OnlineSessionRepository extends MemorySessionRepository {
  OnlineSessionRepository(this._c) : super(const []);
  final OnlineContext _c;

  /// Read-model updates for rows the server already confirmed. Idempotent on the id (a retry after a
  /// lost response never duplicates a session).
  void insertFromServer(WorkoutSession s) {
    if (byId(s.id) != null) {
      unawaited(super.update(s));
    } else {
      unawaited(super.add(s));
    }
  }

  void replaceFromServer(WorkoutSession s) => unawaited(super.update(s));

  @override
  Future<void> add(WorkoutSession s) => _c.write(() async {
    final epoch = _c.epoch;
    await _c.remote.upsert(RemoteTable.workoutSessions, [sessionToRow(s)]);
    if (_c.isCurrent(epoch)) insertFromServer(s);
  });

  @override
  Future<void> addAll(List<WorkoutSession> sessions) => _c.write(() async {
    final epoch = _c.epoch;
    await _c.remote.upsert(RemoteTable.workoutSessions, [
      for (final s in sessions) sessionToRow(s),
    ]);
    if (!_c.isCurrent(epoch)) return;
    final fresh = <WorkoutSession>[];
    for (final s in sessions) {
      if (byId(s.id) != null) {
        unawaited(super.update(s));
      } else {
        fresh.add(s);
      }
    }
    if (fresh.isNotEmpty) {
      unawaited(super.addAll(fresh)); // one notification for the whole import
    }
  });

  @override
  Future<void> update(WorkoutSession s) => _c.write(() async {
    if (byId(s.id) == null) return; // never resurrects a deleted session
    final epoch = _c.epoch;
    await _c.remote.upsert(RemoteTable.workoutSessions, [sessionToRow(s)]);
    if (_c.isCurrent(epoch)) await super.update(s);
  });

  @override
  Future<void> delete(String id) => _c.write(() async {
    final epoch = _c.epoch;
    await _c.remote.delete(RemoteTable.workoutSessions, id);
    if (_c.isCurrent(epoch)) await super.delete(id);
  });
}

class OnlineCardioRepository extends MemoryCardioRepository {
  OnlineCardioRepository(this._c) : super(const [], const []);
  final OnlineContext _c;

  @override
  Future<void> add(CardioSession s) => _c.write(() async {
    final epoch = _c.epoch;
    await _c.remote.upsert(RemoteTable.cardioSessions, [cardioToRow(s)]);
    if (!_c.isCurrent(epoch)) return;
    if (byId(s.id) != null) {
      await super.update(s);
    } else {
      await super.add(s);
    }
  });

  @override
  Future<void> update(CardioSession s) => _c.write(() async {
    if (byId(s.id) == null) return;
    final epoch = _c.epoch;
    await _c.remote.upsert(RemoteTable.cardioSessions, [cardioToRow(s)]);
    if (_c.isCurrent(epoch)) await super.update(s);
  });

  @override
  Future<void> delete(String id) => _c.write(() async {
    final epoch = _c.epoch;
    await _c.remote.delete(RemoteTable.cardioSessions, id);
    if (_c.isCurrent(epoch)) await super.delete(id);
  });

  @override
  Future<void> saveGoal(CardioGoal g) => _c.write(() async {
    final epoch = _c.epoch;
    await _c.remote.upsert(RemoteTable.cardioGoals, [goalToRow(g)]);
    if (_c.isCurrent(epoch)) await super.saveGoal(g);
  });

  /// Saves [goals] in one request (e.g. moving the "primary" flag between goals).
  Future<void> saveGoals(List<CardioGoal> goals) => _c.write(() async {
    final epoch = _c.epoch;
    await _c.remote.upsert(RemoteTable.cardioGoals, [
      for (final g in goals) goalToRow(g),
    ]);
    if (!_c.isCurrent(epoch)) return;
    for (final g in goals) {
      await super.saveGoal(g);
    }
  });

  @override
  Future<void> deleteGoal(String id) => _c.write(() async {
    final epoch = _c.epoch;
    await _c.remote.delete(RemoteTable.cardioGoals, id);
    if (_c.isCurrent(epoch)) await super.deleteGoal(id);
  });

  @override
  Future<void> addCustomActivity(CustomCardioActivity a) => _c.write(() async {
    final epoch = _c.epoch;
    await _c.remote.upsert(RemoteTable.customCardioActivities, [
      customActivityToRow(a),
    ]);
    if (!_c.isCurrent(epoch)) return;
    if (customActivities.any((x) => x.id == a.id)) {
      replaceCustomActivity(a);
    } else {
      await super.addCustomActivity(a);
    }
  });
}

class OnlineProfileRepository extends MemoryProfileRepository {
  OnlineProfileRepository(this._c);
  final OnlineContext _c;

  @override
  Future<void> update(UserProfile p) => _c.write(() async {
    final epoch = _c.epoch;
    await _c.remote.upsert(RemoteTable.profiles, [profileToRow(p)]);
    if (_c.isCurrent(epoch)) await super.update(p);
  });
}
