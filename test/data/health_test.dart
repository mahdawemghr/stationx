import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/health/health_connect_repository.dart';
import 'package:stationx/data/health/health_consent_store.dart';
import 'package:stationx/data/health/health_gateway.dart';
import 'package:stationx/domain/domain.dart';

class FakeGateway extends HealthGateway {
  FakeGateway({this.ios = false});
  final bool ios;
  int permissionQueries = 0;

  @override
  HealthProvider get provider => ios ? HealthProvider.appleHealth : HealthProvider.healthConnect;
  @override
  bool get canQueryPermissions => !ios;

  GatewayAvailability avail = GatewayAvailability.available;
  bool granted = false;
  bool grantOnRequest = true;
  List<TimeSpan> asleep = [];
  List<TimeSpan> sessions = [];
  List<BpmPoint> hr = [];
  int reads = 0;
  bool revoked = false;
  bool throwOnRead = false;

  @override
  Future<GatewayAvailability> availability() async => avail;
  @override
  Future<bool> hasPermissions() async {
    permissionQueries++;
    return granted;
  }

  @override
  Future<bool> requestPermissions() async => granted = grantOnRequest;
  @override
  Future<List<TimeSpan>> sleepAsleep(DateTime from, DateTime to) async {
    reads++;
    if (throwOnRead) throw StateError('boom');
    return asleep;
  }

  @override
  Future<List<TimeSpan>> sleepSessions(DateTime from, DateTime to) async => sessions;
  @override
  Future<List<BpmPoint>> restingHeartRate(DateTime from, DateTime to) async => hr;
  @override
  Future<void> revoke() async {
    revoked = true;
    granted = false;
  }

  @override
  Future<void> installProvider() async {}
}

TimeSpan span(DateTime d, int h1, int m1, int h2, int m2) => (from: DateTime(d.year, d.month, d.day, h1, m1), to: DateTime(d.year, d.month, d.day, h2, m2));

void main() {
  final now = DateTime(2026, 10, 7, 9, 0);
  final yesterday = DateTime(2026, 10, 6);

  group('HealthSummary', () {
    test('merges overlapping intervals from several sources', () {
      final m = HealthSummary.mergedMinutes([
        (from: DateTime(2026, 10, 6, 23, 0), to: DateTime(2026, 10, 7, 3, 0)),
        (from: DateTime(2026, 10, 7, 2, 0), to: DateTime(2026, 10, 7, 6, 30)), // overlaps by 1h
        (from: DateTime(2026, 10, 7, 4, 0), to: DateTime(2026, 10, 7, 5, 0)), // fully inside
      ]);
      expect(m, 7 * 60 + 30);
    });
    test('ignores empty/inverted intervals; falls back to sessions', () {
      expect(HealthSummary.mergedMinutes([(from: now, to: now)]), 0);
      expect(HealthSummary.sleepMinutes(asleep: const [], sessions: [span(yesterday, 23, 0, 23, 0)]), isNull);
      expect(HealthSummary.sleepMinutes(asleep: const [], sessions: [(from: DateTime(2026, 10, 6, 23), to: DateTime(2026, 10, 7, 6))]), 420);
    });
    test('resting HR latest + average, outliers dropped', () {
      final r = HealthSummary.restingHr([
        (at: DateTime(2026, 10, 1), bpm: 58),
        (at: DateTime(2026, 10, 3), bpm: 56),
        (at: DateTime(2026, 10, 6), bpm: 54),
        (at: DateTime(2026, 10, 7), bpm: 0), // sensor glitch
      ]);
      expect(r.latest, 54);
      expect(r.average, 56);
      expect(HealthSummary.restingHr(const []), (latest: null, average: null));
    });
    test('last-night window', () {
      final w = HealthSummary.lastNightWindow(now);
      expect(w.from, DateTime(2026, 10, 6, 18));
      expect(w.to, DateTime(2026, 10, 7, 14));
    });
  });

  group('HealthConnectRepository', () {
    test('starts unsupported; platform without Health Connect stays unsupported and never connects', () async {
      final g = FakeGateway()..avail = GatewayAvailability.unsupported;
      final r = HealthConnectRepository(g, clock: () => now);
      expect(r.status, HealthStatus.unsupported);
      await r.init();
      expect(r.status, HealthStatus.unsupported);
      expect(await r.connect(), isFalse);
      expect(r.snapshot, isNull);
    });

    test('Health Connect app missing → notInstalled', () async {
      final r = HealthConnectRepository(FakeGateway()..avail = GatewayAvailability.notInstalled, clock: () => now);
      await r.init();
      expect(r.status, HealthStatus.notInstalled);
    });

    test('available but not granted → notConnected, no data read', () async {
      final g = FakeGateway();
      final r = HealthConnectRepository(g, clock: () => now);
      await r.init();
      expect(r.status, HealthStatus.notConnected);
      expect(g.reads, 0);
      await r.refresh(force: true); // no-op when not connected
      expect(g.reads, 0);
    });

    test('connect: user grants → connected and snapshot loaded', () async {
      final g = FakeGateway()
        ..asleep = [(from: DateTime(2026, 10, 6, 23, 15), to: DateTime(2026, 10, 7, 6, 55))]
        ..hr = [(at: DateTime(2026, 10, 5), bpm: 58), (at: DateTime(2026, 10, 6), bpm: 54)];
      final r = HealthConnectRepository(g, clock: () => now);
      await r.init();
      var notified = 0;
      r.addListener(() => notified++);
      expect(await r.connect(), isTrue);
      expect(r.status, HealthStatus.connected);
      expect(r.busy, isFalse);
      final s = r.snapshot!;
      expect(s.sleepMinutes, 460);
      expect(s.restingHr, 54);
      expect(s.restingHrAvg7d, 56);
      expect(s.restingHrDelta, -2);
      expect(s.hasData, isTrue);
      expect(notified, greaterThan(0));
    });

    test('connect: user denies → notConnected, nothing read', () async {
      final g = FakeGateway()..grantOnRequest = false;
      final r = HealthConnectRepository(g, clock: () => now);
      await r.init();
      expect(await r.connect(), isFalse);
      expect(r.status, HealthStatus.notConnected);
      expect(r.snapshot, isNull);
      expect(g.reads, 0);
    });

    test('already granted at startup loads data without prompting', () async {
      final g = FakeGateway()..granted = true;
      final r = HealthConnectRepository(g, clock: () => now);
      await r.init();
      expect(r.status, HealthStatus.connected);
      expect(g.reads, 1);
      expect(r.snapshot!.hasData, isFalse); // connected but nothing recorded
    });

    test('refresh is throttled unless forced; failures keep the previous snapshot', () async {
      var t = now;
      final g = FakeGateway()
        ..granted = true
        ..hr = [(at: now, bpm: 55)];
      final r = HealthConnectRepository(g, clock: () => t);
      await r.init();
      expect(g.reads, 1);
      await r.refresh();
      expect(g.reads, 1); // throttled
      t = now.add(const Duration(minutes: 6));
      g.throwOnRead = true;
      await r.refresh(); // throws inside → swallowed
      expect(r.snapshot!.restingHr, 55);
      expect(r.busy, isFalse);
      g.throwOnRead = false;
      await r.refresh(force: true);
      expect(g.reads, 3);
    });

    test('disconnect revokes and clears cached data', () async {
      final g = FakeGateway()
        ..granted = true
        ..hr = [(at: now, bpm: 55)];
      final r = HealthConnectRepository(g, clock: () => now);
      await r.init();
      await r.disconnect();
      expect(g.revoked, isTrue);
      expect(r.status, HealthStatus.notConnected);
      expect(r.snapshot, isNull);
    });
  });

  group('iOS (HealthKit cannot report read access)', () {
    test('never asks the OS for permission state; relies on remembered consent', () async {
      final g = FakeGateway(ios: true);
      final consent = MemoryHealthConsentStore();
      var r = HealthConnectRepository(g, consent: consent, clock: () => now);
      expect(r.provider, HealthProvider.appleHealth);
      await r.init();
      expect(r.status, HealthStatus.notConnected);
      expect(g.permissionQueries, 0);
      g.hr = [(at: now, bpm: 57)];
      expect(await r.connect(), isTrue);
      expect(consent.connected, isTrue);
      expect(r.snapshot!.restingHr, 57);
      // App restart: a new repository with the same consent store reconnects without prompting.
      r = HealthConnectRepository(g, consent: consent, clock: () => now);
      await r.init();
      expect(r.status, HealthStatus.connected);
      expect(r.snapshot!.restingHr, 57);
      expect(g.permissionQueries, 0);
    });

    test('connected but nothing readable (denied or no data) → empty snapshot, not an error', () async {
      final g = FakeGateway(ios: true);
      final r = HealthConnectRepository(g, consent: MemoryHealthConsentStore(true), clock: () => now);
      await r.init();
      expect(r.status, HealthStatus.connected);
      expect(r.snapshot!.hasData, isFalse);
    });

    test('disconnect forgets consent (iOS cannot revoke; user removes access in Settings)', () async {
      final g = FakeGateway(ios: true);
      final consent = MemoryHealthConsentStore(true);
      final r = HealthConnectRepository(g, consent: consent, clock: () => now);
      await r.init();
      await r.disconnect();
      expect(consent.connected, isFalse);
      expect(r.status, HealthStatus.notConnected);
      await r.init();
      expect(r.status, HealthStatus.notConnected);
    });

    test('Android keeps consent in sync with the real OS permission', () async {
      final g = FakeGateway()..granted = true;
      final consent = MemoryHealthConsentStore();
      final r = HealthConnectRepository(g, consent: consent, clock: () => now);
      await r.init();
      expect(consent.connected, isTrue);
      g.granted = false; // user revoked in system settings
      await r.init();
      expect(r.status, HealthStatus.notConnected);
      expect(consent.connected, isFalse);
    });
  });
}
