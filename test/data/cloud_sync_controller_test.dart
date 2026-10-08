
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:isar_community/isar.dart';
import 'package:stationx/data/sync/cloud_auth.dart';
import 'package:stationx/data/sync/cloud_sync_controller.dart';
import 'package:stationx/data/sync/supabase_sync_gateway.dart';
import 'package:stationx/data/sync/sync_engine.dart';
import 'package:stationx/data/sync/sync_gateway.dart';
import 'package:stationx/data/sync/sync_rows.dart';
import 'package:stationx/data/sync/sync_tables.dart';
import 'package:stationx/domain/domain.dart';
import '../helpers/sync_fakes.dart';

CardioSession run(String id) => CardioSession(id: id, kind: CardioKind.cycling, workoutDate: DateTime.utc(2026, 9, 1, 7), durationSeconds: 1800);

void main() {
  late FakeServer server;
  late FakeCloudAuth auth;
  late Device device;
  late CloudSyncController ctl;
  var guestProfile = false;
  final extra = <Device>[];

  CloudSyncController build({Duration debounce = const Duration(milliseconds: 30), Duration throttle = const Duration(hours: 1), Duration retry = const Duration(milliseconds: 60)}) =>
      CloudSyncController(
        auth: auth,
        engine: device.engine,
        local: device.local,
        preferCloudProfile: () => guestProfile,
        debounce: debounce,
        resumeThrottle: throttle,
        retryAfter: retry,
      );

  setUpAll(() => Isar.initializeIsarCore(download: true));
  setUp(() async {
    server = FakeServer();
    auth = FakeCloudAuth();
    guestProfile = false;
    device = await Device.open(server, name: 'ctl');
    ctl = build();
    await ctl.init();
  });
  tearDown(() async {
    // Background syncs (sign-in, debounce, retry) must finish before the database closes.
    for (var i = 0; i < 40 && ctl.phase == CloudSyncPhase.syncing; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    ctl.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await device.close();
    for (final d in extra) {
      await d.close();
    }
    extra.clear();
  });

  Future<void> settle() async {
    for (var i = 0; i < 40; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      if (ctl.phase != CloudSyncPhase.syncing) return;
    }
  }

  test('unconfigured build: feature unavailable and inert', () async {
    final c = CloudSyncController.unavailable();
    expect(c.available, isFalse);
    expect(c.phase, CloudSyncPhase.unavailable);
    await c.init();
    final r = await c.syncNow();
    expect(r.error, isNotNull);
    c.onLocalChange();
    c.onResume();
    expect(c.phase, CloudSyncPhase.unavailable);
    c.dispose();
  });

  test('signed out by default; local data never touches the server', () async {
    await device.store.cardio.add(run('c1'));
    ctl.onLocalChange();
    ctl.onResume();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(ctl.phase, CloudSyncPhase.signedOut);
    expect(server.upsertCalls, 0);
    expect(server.pullCalls, 0);
  });

  test('wrong password: no sync, clear status', () async {
    auth.nextStatus = CloudAuthStatus.invalidCredentials;
    final r = await ctl.signIn('a@b.co', 'nope');
    expect(r.status, CloudAuthStatus.invalidCredentials);
    expect(ctl.phase, CloudSyncPhase.signedOut);
    expect(server.upsertCalls, 0);
  });

  test('sign in uploads local data, records last sync, pending drops to 0', () async {
    await device.store.cardio.add(run('c1'));
    await ctl.init();
    expect(ctl.pending, 1);
    final r = await ctl.signIn('a@b.co', 'secret123');
    expect(r.ok, isTrue);
    await settle();
    expect(ctl.phase, CloudSyncPhase.idle);
    expect(ctl.lastSyncAt, isNotNull);
    expect(ctl.pending, 0);
    expect(server.rows(SyncTable.cardioSessions).single['id'], 'c1');
    expect(ctl.user!.email, 'a@b.co');
  });

  test('local changes sync automatically after a debounce; bursts are coalesced; reload noise does not loop', () async {
    await ctl.signIn('a@b.co', 'x');
    await settle();
    final calls0 = server.upsertCalls;
    for (var i = 0; i < 4; i++) {
      await device.store.cardio.add(run('burst$i'));
      ctl.onLocalChange(); // each repo write notifies; the debounce coalesces them
    }
    expect(server.rows(SyncTable.cardioSessions).length, 0); // not instantly
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await settle();
    expect(server.rows(SyncTable.cardioSessions).length, 4);
    // Cardio table gets one batched upsert, not four.
    expect(server.upsertCalls - calls0, 1);
    // A reload-triggered change notification with nothing pending does not start another sync.
    final pulls = server.pullCalls;
    ctl.onLocalChange();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(server.pullCalls, pulls);
  });

  test('resume syncs, but is throttled', () async {
    ctl.dispose();
    ctl = build(throttle: const Duration(hours: 1));
    await ctl.init();
    await ctl.signIn('a@b.co', 'x');
    await settle();
    final pulls = server.pullCalls;
    ctl.onResume();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(server.pullCalls, pulls); // within the throttle window
    ctl.dispose();
    ctl = build(throttle: Duration.zero);
    await ctl.init();
    ctl.onResume();
    await settle();
    expect(server.pullCalls, greaterThan(pulls));
  });

  test('offline: shows a problem, keeps data pending, retries by itself and recovers', () async {
    await device.store.cardio.add(run('c1'));
    server.failNextUpsertAfter = 1;
    await ctl.signIn('a@b.co', 'x');
    await settle();
    expect(ctl.phase, CloudSyncPhase.error);
    expect(ctl.problem, CloudSyncProblem.offline);
    expect(ctl.pending, 1);
    expect(server.rows(SyncTable.cardioSessions), isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 250)); // retry timer fires
    await settle();
    expect(ctl.phase, CloudSyncPhase.idle);
    expect(ctl.problem, isNull);
    expect(server.rows(SyncTable.cardioSessions).length, 1);
    expect(ctl.pending, 0);
  });

  test('single flight: simultaneous requests do not upload twice', () async {
    await device.store.cardio.add(run('c1'));
    await ctl.signIn('a@b.co', 'x');
    await Future.wait([ctl.syncNow(), ctl.syncNow(), ctl.syncNow()]);
    await settle();
    expect(server.rows(SyncTable.cardioSessions).length, 1);
    expect(ctl.pending, 0);
  });

  test('sign out keeps local data and the account link; signing back in as the same user just continues', () async {
    await device.store.cardio.add(run('c1'));
    await ctl.signIn('a@b.co', 'x');
    await settle();
    await ctl.signOut();
    expect(ctl.phase, CloudSyncPhase.signedOut);
    expect(device.store.cardio.sessions.length, 1);
    await device.store.cardio.add(run('c2')); // offline edit while signed out
    final upsertsBefore = server.upsertCalls;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(server.upsertCalls, upsertsBefore); // nothing leaks while signed out
    await ctl.signIn('a@b.co', 'x');
    await settle();
    expect(ctl.needsAccountDecision, isFalse);
    expect(server.rows(SyncTable.cardioSessions).length, 2);
  });

  test('a different account on a device with data asks first, then merges', () async {
    await device.store.cardio.add(run('mine'));
    await ctl.signIn('a@b.co', 'x');
    await settle();
    await ctl.signOut();
    // Account 2 has its own cloud (separate fake server) with data.
    final server2 = FakeServer();
    final other = await Device.open(server2, userId: 'user-2', name: 'other');
    extra.add(other);
    await other.store.cardio.add(run('theirs'));
    await other.sync();
    ctl.dispose();
    device.useGateway(server2);
    ctl = build();
    await ctl.init();
    auth.nextUserId = 'user-2';
    await ctl.signIn('b@b.co', 'x');
    await settle();
    expect(ctl.needsAccountDecision, isTrue);
    expect(server2.rows(SyncTable.cardioSessions).map((r) => r['id']), ['theirs']);
    await ctl.resolveAccountDecision(AccountSwitch.merge);
    await settle();
    expect(ctl.needsAccountDecision, isFalse);
    expect(device.store.cardio.sessions.map((s) => s.id).toSet(), {'mine', 'theirs'});
    expect(server2.rows(SyncTable.cardioSessions).map((r) => r['id']).toSet(), {'mine', 'theirs'});
  });

  test('guest profile on a new device: the cloud profile wins', () async {
    await device.store.profile.update(const UserProfile(name: 'Guest Athlete', isGuest: true));
    server.seed(SyncTable.profiles, {'user_id': 'user-1', 'name': 'Sam', 'unit': 'lb', 'weight_kg': 82, 'created_at': '2026-02-01T00:00:00Z', 'updated_at': '2026-02-01T00:00:00Z', 'deleted_at': null});
    guestProfile = true;
    await ctl.signIn('a@b.co', 'x');
    await settle();
    expect(device.store.profile.profile.name, 'Sam');
    expect(device.store.profile.profile.isGuest, isFalse);
  });

  test('delete cloud account: signed out, link cleared, local data kept', () async {
    await device.store.cardio.add(run('c1'));
    await ctl.signIn('a@b.co', 'x');
    await settle();
    final r = await ctl.deleteCloudAccount();
    expect(r.ok, isTrue);
    expect(auth.deleteCalls, 1);
    expect(ctl.phase, CloudSyncPhase.signedOut);
    expect(device.store.cardio.sessions.length, 1);
    expect((await device.local.loadState()).userId, isNull);
  });

  test('failed account deletion changes nothing', () async {
    await ctl.signIn('a@b.co', 'x');
    await settle();
    auth.nextStatus = CloudAuthStatus.network;
    final r = await ctl.deleteCloudAccount();
    expect(r.ok, isFalse);
    expect(ctl.phase, isNot(CloudSyncPhase.signedOut));
    expect((await device.local.loadState()).userId, 'user-1');
  });

  test('forgetThisDevice signs out and unlinks (used when the user wipes the device)', () async {
    await ctl.signIn('a@b.co', 'x');
    await settle();
    await ctl.forgetThisDevice();
    expect(ctl.phase, CloudSyncPhase.signedOut);
    expect((await device.local.loadState()).userId, isNull);
    expect(ctl.lastSyncAt, isNull);
  });

  group('lost session', () {
    test('classification is typed: auth-lost vs offline vs server', () {
      expect(CloudSyncController.classify(const SyncAuthLostException('PGRST301')), CloudSyncProblem.signedOut);
      expect(CloudSyncController.classify(const SocketException('x')), CloudSyncProblem.offline);
      expect(CloudSyncController.classify(TimeoutException('x')), CloudSyncProblem.offline);
      // Text that merely MENTIONS 401 / jwt is a server problem, never a silent sign-out.
      expect(CloudSyncController.classify(StateError('row 401 failed jwt check')), CloudSyncProblem.server);
      expect(CloudSyncController.classify('boom'), CloudSyncProblem.server);
    });

    test('gateway maps PostgREST token errors (PGRST30x / 401) to auth-lost, not data errors', () {
      expect(SupabaseSyncGateway.isAuthFailure(const PostgrestException(message: 'JWT expired', code: 'PGRST301')), isTrue);
      expect(SupabaseSyncGateway.isAuthFailure(const PostgrestException(message: 'x', code: 'PGRST303')), isTrue);
      expect(SupabaseSyncGateway.isAuthFailure(const PostgrestException(message: 'x', code: '401')), isTrue);
      expect(SupabaseSyncGateway.isAuthFailure(const PostgrestException(message: 'check violation', code: '23514')), isFalse);
      expect(SupabaseSyncGateway.isAuthFailure(const PostgrestException(message: 'x')), isFalse);
    });

    test('auth lost: signs out locally, keeps data, stops the retry loop', () async {
      await device.store.cardio.add(run('c1'));
      final failing = _AuthLostGateway(server);
      device.useGateway(failing);
      ctl.dispose();
      ctl = build(retry: const Duration(milliseconds: 40));
      await ctl.init();
      await ctl.signIn('a@b.co', 'x');
      await settle();
      expect(failing.calls, 1);
      expect(ctl.problem, CloudSyncProblem.signedOut);
      expect(ctl.phase, CloudSyncPhase.signedOut);
      expect(auth.user, isNull, reason: 'the dead session was dropped locally');
      expect(device.store.cardio.sessions.length, 1, reason: 'local data stays');
      expect(ctl.pending, 1);
      // No retry timer: several retry periods later nothing else has been attempted.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(failing.calls, 1);
      expect(ctl.phase, CloudSyncPhase.signedOut);
    });
  });
}

/// Every call fails as if the access token had been revoked.
class _AuthLostGateway implements SyncGateway {
  _AuthLostGateway(this.inner);
  final SyncGateway inner;
  int calls = 0;
  @override
  Future<void> upsert(SyncTable table, List<Row> rows) async {
    calls++;
    throw const SyncAuthLostException('PGRST301');
  }

  @override
  Future<void> tombstone(SyncTable table, String id, DateTime at) async {
    calls++;
    throw const SyncAuthLostException('PGRST301');
  }

  @override
  Future<List<Row>> pull(SyncTable table, {String? sinceIso, int limit = 500}) async {
    calls++;
    throw const SyncAuthLostException('PGRST301');
  }
}
