import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';
import '../data_store.dart';
import '../health/health_consent_store.dart';
import '../seed/seed_catalog.dart';
import 'online_repositories.dart';
import 'remote_exception.dart';
import 'remote_gateway.dart';
import 'row_mappers.dart';

/// Production [DataStore]: Supabase is the only source of truth for user data.
///
/// The repositories are an in-memory **read model of the signed-in user's rows**, hydrated by [load]
/// and emptied by [clear]. It is never persisted. Every write goes to the server first and the read
/// model changes only after the server confirmed it (see [OnlineContext]).
class OnlineStore implements DataStore, AtomicWorkoutFinisher {
  OnlineStore(RemoteGateway remote, this.device, {void Function()? onAuthLost})
    : _c = OnlineContext(remote, onAuthLost: onAuthLost) {
    exercises = OnlineExerciseRepository(_c);
    workouts = OnlineWorkoutRepository(_c);
    sessions = OnlineSessionRepository(_c);
    cardio = OnlineCardioRepository(_c);
    profile = OnlineProfileRepository(_c);
  }

  final OnlineContext _c;
  final DeviceStore device;

  @override
  late final OnlineExerciseRepository exercises;
  @override
  late final OnlineWorkoutRepository workouts;
  @override
  late final OnlineSessionRepository sessions;
  @override
  late final OnlineCardioRepository cardio;
  @override
  late final OnlineProfileRepository profile;

  /// Set by the app controller; invoked when the server reports the session is no longer valid.
  set onAuthLost(void Function()? f) => _c.onAuthLost = f;

  /// Rows the server returned that this client could not parse (diagnostics only; they are skipped).
  int skippedRows = 0;

  @override
  WorkoutDraftStore get workoutDraft => device.workoutDraft;

  HealthConsentStore get healthConsent => device.healthConsent;

  RemoteGateway get remote => _c.remote;

  @override
  Future<void> load({required String userId, required String username}) async {
    final epoch = _c.epoch;
    // A different account than the one this device last held: its draft/notice must not carry over.
    if (device.ownerUserId != null && device.ownerUserId != userId) {
      await device.clearUserScopedState();
    }
    await device.setOwnerUserId(userId);

    final writes = _c.writeCount;
    final data = await _fetch(userId);
    if (!_c.isCurrent(epoch)) {
      return; // user changed / signed out while loading: discard silently
    }
    // A save started or finished while this snapshot was in flight: the snapshot may predate it, so
    // applying it could undo a confirmed change. Keep the read model; the next refresh catches up.
    if (_c.writeCount != writes || _c.pendingWrites > 0) return;
    _apply(data, username);
  }

  Future<_Data> _fetch(String userId) async {
    final r = _c.remote;
    Future<T> auth<T>(Future<T> f) async {
      final v = await f;
      if (r.userId != userId) {
        throw const RemoteException(
          RemoteFailure.authExpired,
          detail: 'account changed',
        );
      }
      return v;
    }

    var d = await auth(_fetchAll());
    if (d.profile == null || d.profile!['initialized_at'] == null) {
      // First sign-in of this account: mark it initialised on the server, exactly once. No routines are
      // created here: the user's program is generated only in onboarding (or when they ask for it).
      await r.rpc('sx_init_account', const {
        'p_workouts': <Object?>[],
        'p_rotation': null,
      });
      d = await auth(_fetchAll());
    }
    return d;
  }

  Future<_Data> _fetchAll() async {
    final r = _c.remote;
    final res = await Future.wait<Object?>([
      r.fetchProfile(),
      r.fetchRotation(),
      r.fetchAll(RemoteTable.exercises),
      r.fetchAll(RemoteTable.workouts),
      r.fetchAll(RemoteTable.workoutSessions),
      r.fetchAll(RemoteTable.cardioSessions),
      r.fetchAll(RemoteTable.cardioGoals),
      r.fetchAll(RemoteTable.customCardioActivities),
    ]);
    return _Data(
      profile: res[0] as Row?,
      rotation: res[1] as Row?,
      exercises: res[2]! as List<Row>,
      workouts: res[3]! as List<Row>,
      sessions: res[4]! as List<Row>,
      cardio: res[5]! as List<Row>,
      goals: res[6]! as List<Row>,
      custom: res[7]! as List<Row>,
    );
  }

  List<T> _parse<T>(List<Row> rows, T Function(Row) f) {
    final out = <T>[];
    for (final row in rows) {
      try {
        out.add(f(row));
      } catch (_) {
        skippedRows++; // a malformed row must not make the whole account unloadable
      }
    }
    return out;
  }

  void _apply(_Data d, String username) {
    skippedRows = 0;
    final custom = _parse(d.exercises, exerciseFromRow);
    final customIds = {for (final e in custom) e.id};
    exercises.reset([
      for (final e in seedExercises())
        if (!customIds.contains(e.id)) e,
      ...custom,
    ]);

    final parsed = _parse(d.workouts, workoutFromRow)
      ..sort((a, b) => a.$2.compareTo(b.$2));
    final list = [for (final p in parsed) p.$1];
    workouts.reset(
      list,
      d.rotation == null
          ? Rotation(workoutIds: [for (final w in list) w.id])
          : rotationFromRow(d.rotation!),
    );

    sessions.reset(_parse(d.sessions, sessionFromRow));
    cardio.reset(
      _parse(d.cardio, cardioFromRow),
      _parse(d.goals, goalFromRow),
      _parse(d.custom, customActivityFromRow),
    );

    final base = UserProfile(name: username, email: username, isGuest: false);
    profile.reset(
      d.profile == null
          ? base
          : profileFromRow(d.profile!, base).copyWith(email: username),
    );
    if (skippedRows > 0) {
      debugPrint('OnlineStore: skipped $skippedRows unreadable row(s)');
    }
  }

  @override
  Future<void> clear() {
    _c.invalidate();
    exercises.reset(const []);
    workouts.reset(const [], const Rotation(workoutIds: []));
    sessions.reset(const []);
    cardio.reset(const [], const [], const []);
    profile.reset(const UserProfile());
    return device.clearUserScopedState();
  }

  @override
  Future<void> resetData() async {
    final id = _c.remote.userId;
    if (id == null) {
      throw const RemoteException(
        RemoteFailure.authExpired,
        detail: 'no session',
      );
    }
    await _c.write(() => _c.remote.rpc('sx_reset_account_data', const {}));
    await workoutDraft.clear();
    final username = profile.profile.email;
    final epoch = _c.epoch;
    final data = await _fetch(id);
    if (_c.isCurrent(epoch)) _apply(data, username);
  }

  @override
  Future<void> finishWorkout(WorkoutSession session, Rotation? rotation) =>
      _c.write(() async {
        final epoch = _c.epoch;
        await _c.remote.rpc('sx_finish_workout', {
          'p_session': sessionToRow(session),
          'p_rotation': rotation == null ? null : rotationToRow(rotation),
        });
        if (!_c.isCurrent(epoch)) return;
        // Server confirmed both: now (and only now) the read model follows.
        if (sessions.byId(session.id) != null) {
          sessions.replaceFromServer(session);
        } else {
          sessions.insertFromServer(session);
        }
        if (rotation != null) workouts.setRotationFromServer(rotation);
      });

  @override
  Future<void> close() => device.close();
}

class _Data {
  _Data({
    required this.profile,
    required this.rotation,
    required this.exercises,
    required this.workouts,
    required this.sessions,
    required this.cardio,
    required this.goals,
    required this.custom,
  });
  final Row? profile;
  final Row? rotation;
  final List<Row> exercises;
  final List<Row> workouts;
  final List<Row> sessions;
  final List<Row> cardio;
  final List<Row> goals;
  final List<Row> custom;
}
