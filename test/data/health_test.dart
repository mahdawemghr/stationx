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
  HealthProvider get provider =>
      ios ? HealthProvider.appleHealth : HealthProvider.healthConnect;
  @override
  bool get canQueryPermissions => !ios;

  GatewayAvailability avail = GatewayAvailability.available;
  bool granted = false;
  bool grantOnRequest = true;
  bool revoked = false;

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
  Future<void> revoke() async {
    revoked = true;
    granted = false;
  }

  @override
  Future<void> installProvider() async {}
}

void main() {
  test(
    'the base connection never reads sleep or resting heart rate (only the recovery switch does)',
    () {
      // Compile-time guarantee: FakeGateway implements the whole abstract gateway without them.
      expect(FakeGateway().canQueryPermissions, isTrue);
    },
  );

  group('HealthConnectRepository (connection state only)', () {
    test(
      'starts unsupported; platform without Health Connect stays unsupported and never connects',
      () async {
        final g = FakeGateway()..avail = GatewayAvailability.unsupported;
        final r = HealthConnectRepository(g);
        expect(r.status, HealthStatus.unsupported);
        await r.init();
        expect(r.status, HealthStatus.unsupported);
        expect(await r.connect(), isFalse);
      },
    );

    test('Health Connect app missing → notInstalled', () async {
      final r = HealthConnectRepository(
        FakeGateway()..avail = GatewayAvailability.notInstalled,
      );
      await r.init();
      expect(r.status, HealthStatus.notInstalled);
    });

    test('available but not granted → notConnected', () async {
      final r = HealthConnectRepository(FakeGateway());
      await r.init();
      expect(r.status, HealthStatus.notConnected);
    });

    test('connect: user grants → connected; busy is released', () async {
      final r = HealthConnectRepository(FakeGateway());
      await r.init();
      var notified = 0;
      r.addListener(() => notified++);
      expect(await r.connect(), isTrue);
      expect(r.status, HealthStatus.connected);
      expect(r.busy, isFalse);
      expect(notified, greaterThan(0));
    });

    test('connect: user denies → notConnected', () async {
      final r = HealthConnectRepository(FakeGateway()..grantOnRequest = false);
      await r.init();
      expect(await r.connect(), isFalse);
      expect(r.status, HealthStatus.notConnected);
    });

    test('already granted at startup connects without prompting', () async {
      final g = FakeGateway()..granted = true;
      final r = HealthConnectRepository(g);
      await r.init();
      expect(r.status, HealthStatus.connected);
    });

    test('disconnect revokes and forgets consent', () async {
      final g = FakeGateway()..granted = true;
      final r = HealthConnectRepository(g);
      await r.init();
      await r.disconnect();
      expect(g.revoked, isTrue);
      expect(r.status, HealthStatus.notConnected);
    });
  });

  group('iOS (HealthKit cannot report read access)', () {
    test(
      'never asks the OS for permission state; relies on remembered consent',
      () async {
        final g = FakeGateway(ios: true);
        final consent = MemoryHealthConsentStore();
        var r = HealthConnectRepository(g, consent: consent);
        expect(r.provider, HealthProvider.appleHealth);
        await r.init();
        expect(r.status, HealthStatus.notConnected);
        expect(g.permissionQueries, 0);
        expect(await r.connect(), isTrue);
        expect(consent.connected, isTrue);
        // App restart: a new repository with the same consent store reconnects without prompting.
        r = HealthConnectRepository(g, consent: consent);
        await r.init();
        expect(r.status, HealthStatus.connected);
        expect(g.permissionQueries, 0);
      },
    );

    test(
      'disconnect forgets consent (iOS cannot revoke; user removes access in Settings)',
      () async {
        final g = FakeGateway(ios: true);
        final consent = MemoryHealthConsentStore(true);
        final r = HealthConnectRepository(g, consent: consent);
        await r.init();
        await r.disconnect();
        expect(consent.connected, isFalse);
        expect(r.status, HealthStatus.notConnected);
        await r.init();
        expect(r.status, HealthStatus.notConnected);
      },
    );

    test('Android keeps consent in sync with the real OS permission', () async {
      final g = FakeGateway()..granted = true;
      final consent = MemoryHealthConsentStore();
      final r = HealthConnectRepository(g, consent: consent);
      await r.init();
      expect(consent.connected, isTrue);
      g.granted = false; // user revoked in system settings
      await r.init();
      expect(r.status, HealthStatus.notConnected);
      expect(consent.connected, isFalse);
    });
  });
}
