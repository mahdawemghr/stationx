import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:stationx/data/sync/cloud_auth.dart';
import 'package:stationx/data/isar/isar_store.dart';
import 'package:stationx/data/isar/isar_sync_store.dart';
import 'package:stationx/data/sync/sync_engine.dart';
import 'package:stationx/data/sync/sync_local_store.dart';
import 'package:stationx/data/sync/sync_gateway.dart';
import 'package:stationx/data/sync/sync_rows.dart';
import 'package:stationx/data/sync/sync_tables.dart';

/// In-memory stand-in for the Supabase backend. Implements the same server rules
/// as the real schema: last-write-wins on `updated_at` (stale writes ignored),
/// server-assigned monotonic `server_updated_at`, tombstones, pull cursor (inclusive).
class FakeServer implements SyncGateway {
  final Map<String, Map<String, Row>> tables = {for (final t in SyncTable.values) t.name: {}};
  int _tick = 0;
  int upsertCalls = 0;
  int pullCalls = 0;

  /// Test hooks.
  Object? failNextUpsertAfter; // throw on the Nth upsert call (1-based) once
  void Function(SyncTable table, List<Row> rows)? onUpsert;

  String _ts() => DateTime.utc(2026, 1, 1).add(Duration(milliseconds: ++_tick)).toIso8601String();
  String _key(SyncTable t, Row r) => t.singleton ? 'self' : r['id'] as String;

  List<Row> rows(SyncTable t, {bool includeDeleted = false}) =>
      [for (final r in tables[t.name]!.values) if (includeDeleted || r['deleted_at'] == null) r];

  /// Simulates a row written by something else (e.g. the signup trigger).
  void seed(SyncTable t, Row r) => tables[t.name]![_key(t, r)] = {...r, 'server_updated_at': _ts()};

  @override
  Future<void> upsert(SyncTable table, List<Row> rs) async {
    upsertCalls++;
    final fail = failNextUpsertAfter;
    if (fail is int && upsertCalls == fail) {
      failNextUpsertAfter = null;
      throw const SocketException('simulated network failure');
    }
    onUpsert?.call(table, rs);
    for (final r in rs) {
      final k = _key(table, r);
      final old = tables[table.name]![k];
      if (old != null && DateTime.parse(r['updated_at'] as String).isBefore(DateTime.parse(old['updated_at'] as String))) {
        continue; // stale write ignored (the server trigger does the same)
      }
      tables[table.name]![k] = {...?old, ...r, 'server_updated_at': _ts()};
    }
  }

  @override
  Future<void> tombstone(SyncTable table, String id, DateTime at) async {
    final old = tables[table.name]![id];
    if (old == null) return;
    if (at.isBefore(DateTime.parse(old['updated_at'] as String))) return;
    tables[table.name]![id] = {...old, 'deleted_at': at.toUtc().toIso8601String(), 'updated_at': at.toUtc().toIso8601String(), 'server_updated_at': _ts()};
  }

  @override
  Future<List<Row>> pull(SyncTable table, {String? sinceIso, int limit = 500}) async {
    pullCalls++;
    final since = sinceIso == null ? null : DateTime.parse(sinceIso);
    final out = [
      for (final r in tables[table.name]!.values)
        if (since == null || !DateTime.parse(r['server_updated_at'] as String).isBefore(since)) {...r},
    ]..sort((a, b) => (a['server_updated_at'] as String).compareTo(b['server_updated_at'] as String));
    return out.take(limit).toList();
  }
}

/// One simulated phone: its own Isar database + sync engine.
class Device {
  Device._(this.dir, this.store, this.local, this.engine, this.userId);
  final Directory dir;
  final IsarStore store;
  final IsarSyncLocalStore local;
  SyncEngine engine;
  String userId;

  static Future<Device> open(SyncGateway gateway, {String userId = 'user-1', int pushBatch = 100, int pullPage = 500, String name = 'dev'}) async {
    final dir = Directory.systemTemp.createTempSync('stationx_sync_$name');
    final store = await IsarStore.open(directory: dir.path, name: name);
    final local = IsarSyncLocalStore(store);
    return Device._(dir, store, local, SyncEngine(local, gateway, pushBatch: pushBatch, pullPage: pullPage), userId);
  }

  Future<SyncResult> sync({AccountSwitch decision = AccountSwitch.undecided, bool preferCloudSingletons = false}) =>
      engine.run(userId: userId, decision: decision, preferCloudSingletons: preferCloudSingletons);

  void useGateway(SyncGateway g, {int pushBatch = 100, int pullPage = 500}) => engine = SyncEngine(local, g, pushBatch: pushBatch, pullPage: pullPage);

  Future<void> close() async {
    await store.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}

/// Controllable stand-in for the cloud account API.
class FakeCloudAuth extends ChangeNotifier implements CloudAuth {
  FakeCloudAuth({this.configured = true});
  final bool configured;
  CloudUser? _user;
  CloudAuthStatus nextStatus = CloudAuthStatus.ok;
  String nextUserId = 'user-1';
  int signInCalls = 0;
  int deleteCalls = 0;

  @override
  bool get isConfigured => configured;
  @override
  CloudUser? get user => _user;

  @override
  Future<CloudAuthResult> signIn(String email, String password) async {
    signInCalls++;
    if (nextStatus == CloudAuthStatus.ok) {
      _user = CloudUser(id: nextUserId, email: email);
      notifyListeners();
    }
    return CloudAuthResult(nextStatus);
  }

  @override
  Future<CloudAuthResult> signUp(String email, String password, {String? name}) async {
    if (nextStatus == CloudAuthStatus.ok) {
      _user = CloudUser(id: nextUserId, email: email);
      notifyListeners();
    }
    return CloudAuthResult(nextStatus);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  @override
  Future<CloudAuthResult> deleteAccount() async {
    deleteCalls++;
    if (nextStatus == CloudAuthStatus.ok) {
      _user = null;
      notifyListeners();
    }
    return CloudAuthResult(nextStatus);
  }
}

/// Local store that holds nothing — enough to drive CloudSyncController from widget tests
/// (no Isar, no async I/O).
class NullLocalStore implements SyncLocalStore {
  NullLocalStore({this.state = const SyncState(), this.userData = false, this.pending = 0});
  SyncState state;
  bool userData;
  int pending;
  int resets = 0;

  @override
  Future<List<DirtyRow>> dirtyRows(SyncTable table) async => [];
  @override
  Future<List<SyncDeletion>> pendingDeletions() async => [];
  @override
  Future<void> markPushed(SyncTable table, List<DirtyRow> pushed) async {}
  @override
  Future<void> clearDeletions(List<SyncDeletion> done) async {}
  @override
  Future<int> pendingCount() async => pending;
  @override
  Future<int> applyRemote(SyncTable table, List<Row> rows) async => 0;
  @override
  Future<SyncState> loadState() async => state;
  @override
  Future<void> saveState(SyncState s) async => state = s;
  @override
  Future<void> reloadCaches() async {}
  @override
  Future<void> bumpDirtySingletons() async {}
  @override
  Future<void> markSingletonsClean() async {}
  @override
  Future<void> markAllUserDataDirty() async {}
  @override
  Future<bool> hasUserData() async => userData;
  @override
  Future<void> resetForAccountSwitch() async => resets++;
}
