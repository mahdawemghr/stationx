// Test doubles for the online-first stack: an in-memory "Supabase" (FakeRemote) that behaves like the
// real one where it matters (per-user isolation like RLS, atomic RPCs, idempotent upserts, injected
// failures, held requests for race tests) and a fake Auth service. No network, no credentials.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stationx/data/data_store.dart';
import 'package:stationx/data/health/health_consent_store.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/remote/auth_service.dart';
import 'package:stationx/data/remote/online_store.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/data/remote/remote_exception.dart';
import 'package:stationx/data/remote/remote_gateway.dart';
import 'package:stationx/app/app_controller.dart';

class FakeAuth extends ChangeNotifier implements CloudAuth {
  final _passwords = <String, String>{}; // username -> password
  final _ids = <String, String>{};
  CloudUser? _user;
  CloudAuthStatus? failWith;
  int signOuts = 0;

  @override
  bool get isConfigured => true;
  @override
  CloudUser? get user => _user;

  void _become(String username) {
    _user = CloudUser(id: _ids[username]!, username: username);
    notifyListeners();
  }

  /// Pre-existing account (as if registered earlier / on another phone).
  String seedUser(String username, String password) {
    _passwords[username] = password;
    return _ids[username] ??= 'uid-$username';
  }

  /// Restores a saved session without a sign-in call (app start with a stored session).
  void restoreSession(String username) => _become(username);

  /// The server revokes the session (expired refresh token…).
  void expireSession() {
    _user = null;
    notifyListeners();
  }

  /// One-shot: the next sign-in / sign-up returns this status instead of working.
  CloudAuthStatus? nextStatus;
  int signUpCalls = 0;
  String? lastIdentifier;

  /// When set, sign-up waits for it (to observe the busy state).
  Future<void>? signUpGate;

  CloudAuthStatus? _takeFailure() {
    final s = failWith ?? nextStatus;
    nextStatus = null;
    return s;
  }

  @override
  Future<CloudAuthResult> signIn(String username, String password) async {
    lastIdentifier = Username.toIdentifier(username);
    final f = _takeFailure();
    if (f != null) return CloudAuthResult(f);
    if (_passwords[username] != password) {
      return const CloudAuthResult(CloudAuthStatus.invalidCredentials);
    }
    _become(username);
    return const CloudAuthResult(CloudAuthStatus.ok);
  }

  @override
  Future<CloudAuthResult> signUp(String username, String password) async {
    signUpCalls++;
    lastIdentifier = Username.toIdentifier(username);
    if (signUpGate != null) await signUpGate;
    final f = _takeFailure();
    if (f != null) return CloudAuthResult(f);
    if (_passwords.containsKey(username)) {
      return const CloudAuthResult(CloudAuthStatus.userExists);
    }
    seedUser(username, password);
    _become(username);
    return const CloudAuthResult(CloudAuthStatus.ok);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    if (_user != null) {
      _user = null;
      notifyListeners();
    }
  }

  /// Set by tests to make delete succeed/fail.
  bool deleteFails = false;
  @override
  Future<CloudAuthResult> deleteAccount() async {
    if (deleteFails) return const CloudAuthResult(CloudAuthStatus.network);
    final u = _user;
    if (u != null) {
      _passwords.remove(u.username);
      _user = null;
      notifyListeners();
    }
    return const CloudAuthResult(CloudAuthStatus.ok);
  }
}

class _Held {
  _Held(this.test, this.gate);
  final bool Function(String op) test;
  final Completer<void> gate;
}

/// In-memory Supabase. Data is stored per user id; every call acts on the CURRENT auth user only,
/// so cross-user access is impossible through this API (the SQL test in supabase/tests checks the real RLS).
class FakeRemote implements RemoteGateway {
  FakeRemote(this.auth) : _data = <String, Map<String, Map<String, Row>>>{};

  /// A second client (another phone) talking to the SAME server data as [other], signed in via [auth].
  FakeRemote.sharing(FakeRemote other, this.auth) : _data = other._data;
  final FakeAuth auth;

  // table name -> userId -> id -> row  (singletons use id '_')
  final Map<String, Map<String, Map<String, Row>>> _data;
  final calls = <String>[];
  final _failures = <RemoteException>[];
  RemoteException? failAll;
  final _held = <_Held>[];
  int latencyMicros = 0;

  /// Next [n] calls fail with [e] (nothing is stored).
  void failNext(RemoteException e, [int n = 1]) {
    for (var i = 0; i < n; i++) {
      _failures.add(e);
    }
  }

  /// Calls whose op name matches [test] wait until the returned function is called.
  VoidCallback hold(bool Function(String op) test) {
    final h = _Held(test, Completer<void>());
    _held.add(h);
    return () {
      _held.remove(h);
      h.gate.complete();
    };
  }

  @override
  String? get userId => auth.user?.id;

  String get _uid {
    final id = userId;
    if (id == null) {
      throw const RemoteException(RemoteFailure.authExpired, code: 'PGRST301');
    }
    return id;
  }

  Future<void> _enter(String op) async {
    calls.add(op);
    for (final h in [..._held]) {
      if (h.test(op)) await h.gate.future;
    }
    if (latencyMicros > 0) {
      await Future<void>.delayed(Duration(microseconds: latencyMicros));
    }
    if (failAll != null) throw failAll!;
    if (_failures.isNotEmpty) throw _failures.removeAt(0);
    _uid;
  }

  Map<String, Row> _t(String table, String uid) =>
      (_data[table] ??= {})[uid] ??= {};

  /// Rows of [table] owned by [uid] (test inspection; bypasses auth).
  List<Row> rowsOf(String table, String uid) => [
    for (final r in _t(table, uid).values) Map<String, dynamic>.from(r),
  ];

  Row? rowOf(String table, String uid, String id) => _t(table, uid)[id];

  /// Removes everything owned by [uid] (the server's ON DELETE CASCADE after the auth user is deleted).
  void dropUser(String uid) {
    for (final t in _data.values) {
      t.remove(uid);
    }
  }

  /// Writes a row directly (as if created from another device).
  void plant(String table, String uid, Row row) =>
      _t(table, uid)[(row['id'] as String?) ?? '_'] = {...row};

  @override
  Future<Row?> fetchProfile() async {
    await _enter('fetchProfile');
    final r = _t('profiles', _uid)['_'];
    return r == null ? null : {...r};
  }

  @override
  Future<Row?> fetchRotation() async {
    await _enter('fetchRotation');
    final r = _t('rotations', _uid)['_'];
    return r == null ? null : {...r};
  }

  @override
  Future<List<Row>> fetchAll(RemoteTable table) async {
    await _enter('fetchAll:${table.name}');
    final rows = [
      for (final r in _t(table.name, _uid).values) Map<String, dynamic>.from(r),
    ];
    return rows;
  }

  @override
  Future<void> upsert(RemoteTable table, List<Row> rows) async {
    await _enter('upsert:${table.name}');
    final uid = _uid;
    for (final r in rows) {
      _check(table, r);
      final id = table.singleton ? '_' : r['id'] as String;
      _t(table.name, uid)[id] = {
        ..._t(table.name, uid)[id] ?? {},
        ...r,
        'user_id': uid,
      };
    }
  }

  /// A few of the real CHECK constraints, so "server rejected" paths can be tested.
  void _check(RemoteTable t, Row r) {
    if (t == RemoteTable.workoutSessions &&
        (r['name'] as String? ?? '').isEmpty) {
      throw const RemoteException(RemoteFailure.rejected, code: '23514');
    }
    if (t == RemoteTable.cardioSessions &&
        (r['duration_seconds'] as int? ?? 0) < 0) {
      throw const RemoteException(RemoteFailure.rejected, code: '23514');
    }
  }

  @override
  Future<void> delete(RemoteTable table, String id) async {
    await _enter('delete:${table.name}');
    _t(table.name, _uid).remove(id);
  }

  @override
  Future<Object?> rpc(String function, Map<String, dynamic> params) async {
    await _enter('rpc:$function');
    final uid = _uid;
    switch (function) {
      case 'sx_save_workouts':
        _saveWorkouts(
          uid,
          params['p_workouts'] as List,
          (params['p_delete_ids'] as List?)?.cast<String>() ?? const [],
          params['p_rotation'] as Map?,
        );
        return null;
      case 'sx_finish_workout':
        final s = (params['p_session'] as Map).cast<String, dynamic>();
        _check(RemoteTable.workoutSessions, s);
        final rot =
            params['p_rotation']
                as Map?; // validated before any write: all or nothing
        _t('workout_sessions', uid)[s['id'] as String] = {...s, 'user_id': uid};
        if (rot != null) {
          _t('rotations', uid)['_'] = {
            ...rot.cast<String, dynamic>(),
            'user_id': uid,
          };
        }
        return null;
      case 'sx_init_account':
        final p = _t('profiles', uid);
        final prof = p['_'] ??= {'user_id': uid, 'initialized_at': null};
        if (prof['initialized_at'] != null) return false;
        if (_t('workouts', uid).isNotEmpty || _t('rotations', uid).isNotEmpty) {
          prof['initialized_at'] = DateTime.now().toIso8601String();
          return false;
        }
        _saveWorkouts(
          uid,
          params['p_workouts'] as List,
          const [],
          params['p_rotation'] as Map?,
        );
        prof['initialized_at'] = DateTime.now().toIso8601String();
        return true;
      case 'sx_reset_account_data':
        for (final t in [
          'workout_sessions',
          'cardio_sessions',
          'cardio_goals',
          'custom_cardio_activities',
          'exercises',
          'workouts',
          'rotations',
        ]) {
          _t(t, uid).clear();
        }
        _t('profiles', uid)['_']?['initialized_at'] = null;
        return null;
    }
    throw RemoteException(
      RemoteFailure.unknown,
      detail: 'unknown rpc $function',
    );
  }

  void _saveWorkouts(String uid, List ws, List<String> del, Map? rot) {
    for (final w in ws) {
      final m = (w as Map).cast<String, dynamic>();
      _t('workouts', uid)[m['id'] as String] = {...m, 'user_id': uid};
    }
    for (final id in del) {
      _t('workouts', uid).remove(id);
    }
    if (rot != null) {
      _t('rotations', uid)['_'] = {
        ...rot.cast<String, dynamic>(),
        'user_id': uid,
      };
    }
  }
}

/// Volatile [DeviceStore] (the real one is Isar).
class MemoryDeviceStore implements DeviceStore {
  @override
  final MemoryWorkoutDraftStore workoutDraft = MemoryWorkoutDraftStore();
  @override
  final MemoryCardioDraftStore cardioDraft = MemoryCardioDraftStore();
  @override
  final HealthConsentStore healthConsent = MemoryHealthConsentStore();
  String? _owner;
  @override
  String? get ownerUserId => _owner;
  @override
  Future<void> setOwnerUserId(String? id) async => _owner = id;
  @override
  Future<void> clearUserScopedState() async {
    await workoutDraft.clear();
    await cardioDraft.clear();
    _owner = null;
  }

  @override
  Future<void> close() async {}
}

/// Everything wired like production, but in memory.
class OnlineRig {
  OnlineRig() : this._();

  OnlineRig._({FakeAuth? auth, FakeRemote? shareWith}) {
    this.auth = auth ?? FakeAuth();
    remote = shareWith == null
        ? FakeRemote(this.auth)
        : FakeRemote.sharing(shareWith, this.auth);
    device = MemoryDeviceStore();
    store = OnlineStore(remote, device);
    app = AppController(store: store, auth: this.auth);
  }

  /// A rig with [user] registered and signed in. A new account starts with NO routines (the program is
  /// generated only in onboarding); [program] saves a 3-day program the way onboarding does.
  static Future<OnlineRig> signedIn([
    String user = 'sam_1',
    bool program = true,
  ]) async {
    final r = OnlineRig();
    await r.app.registerAccount(user, 'Passw0rdX');
    if (program) await r.saveThreeDayProgram();
    return r;
  }

  /// Saves the 3-day program `w1..w3` (Chest + Biceps, Back + Triceps, Legs + Shoulders) + rotation.
  Future<void> saveThreeDayProgram() async {
    final days = [
      for (final (i, name) in [
        'Chest + Biceps',
        'Back + Triceps',
        'Legs + Shoulders',
      ].indexed)
        Workout(
          id: 'w${i + 1}',
          name: name,
          exercises: const [RoutineExercise(exerciseId: 'bench_press')],
        ),
    ];
    await app.workouts.saveSchedule(
      days,
      const Rotation(workoutIds: ['w1', 'w2', 'w3']),
    );
  }

  /// A second device: its own controller + device storage over the same server data and accounts.
  factory OnlineRig.sharing(OnlineRig other) {
    final r = OnlineRig._(auth: FakeAuth(), shareWith: other.remote);
    for (final u in other.auth._passwords.entries) {
      r.auth.seedUser(u.key, u.value);
    }
    return r;
  }

  /// "App restart": a brand-new store + controller over the SAME server data and device storage.
  Future<AppController> restart() async {
    final fresh = OnlineStore(remote, device);
    final c = AppController(store: fresh, auth: auth);
    await c.init();
    return c;
  }

  late final FakeAuth auth;
  late final FakeRemote remote;
  late final MemoryDeviceStore device;
  late final OnlineStore store;
  late final AppController app;
}
