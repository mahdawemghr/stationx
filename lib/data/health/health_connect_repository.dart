import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';
import 'health_consent_store.dart';
import 'health_gateway.dart';

/// [HealthRepository] over a [HealthGateway]. Read-only, opt-in: it only tracks whether the user
/// connected the platform health store. The individual features (import, heart rate, write-back) are
/// handled by `HealthSyncService`.
class HealthConnectRepository extends ChangeNotifier
    implements HealthRepository {
  HealthConnectRepository(this._gateway, {HealthConsentStore? consent})
    : _consent = consent ?? MemoryHealthConsentStore();

  final HealthGateway _gateway;
  final HealthConsentStore _consent;

  HealthStatus _status = HealthStatus.unsupported;
  bool _busy = false;

  @override
  HealthProvider get provider => _gateway.provider;
  @override
  HealthStatus get status => _status;
  @override
  bool get busy => _busy;

  void _set({HealthStatus? status, bool? busy}) {
    if (status != null) _status = status;
    if (busy != null) _busy = busy;
    notifyListeners();
  }

  @override
  Future<void> init() async {
    final a = await _gateway.availability();
    switch (a) {
      case GatewayAvailability.unsupported:
        _set(status: HealthStatus.unsupported);
      case GatewayAvailability.notInstalled:
        _set(status: HealthStatus.notInstalled);
      case GatewayAvailability.available:
        // Android: ask the OS. iOS: the OS can't say, so trust the user's remembered opt-in.
        final granted = _gateway.canQueryPermissions
            ? await _gateway.hasPermissions()
            : _consent.connected;
        if (_gateway.canQueryPermissions) await _consent.setConnected(granted);
        _set(
          status: granted ? HealthStatus.connected : HealthStatus.notConnected,
        );
    }
  }

  @override
  Future<bool> connect() async {
    if (_busy) return false;
    _set(busy: true);
    var granted = false;
    try {
      final a = await _gateway.availability();
      if (a != GatewayAvailability.available) {
        _set(
          status: a == GatewayAvailability.notInstalled
              ? HealthStatus.notInstalled
              : HealthStatus.unsupported,
        );
        return false;
      }
      granted = await _gateway.requestPermissions();
      await _consent.setConnected(granted);
      _set(
        status: granted ? HealthStatus.connected : HealthStatus.notConnected,
      );
    } finally {
      _set(busy: false);
    }
    return granted;
  }

  @override
  Future<void> disconnect() async {
    await _gateway
        .revoke(); // no-op on iOS (user removes access in Settings › Health)
    await _consent.setConnected(false);
    _set(status: HealthStatus.notConnected);
  }

  @override
  Future<void> installProvider() => _gateway.installProvider();
}

/// Used where Health Connect cannot exist (iOS, desktop, tests).
class NoopHealthRepository extends ChangeNotifier implements HealthRepository {
  @override
  HealthProvider get provider => HealthProvider.none;
  @override
  HealthStatus get status => HealthStatus.unsupported;
  @override
  bool get busy => false;
  @override
  Future<void> init() async {}
  @override
  Future<bool> connect() async => false;
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> installProvider() async {}
}
