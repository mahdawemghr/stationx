import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';
import 'health_consent_store.dart';
import 'health_gateway.dart';

/// [HealthRepository] over a [HealthGateway]. Read-only, opt-in. A failed read
/// never throws to the UI: the previous snapshot is kept.
class HealthConnectRepository extends ChangeNotifier
    implements HealthRepository {
  HealthConnectRepository(
    this._gateway, {
    HealthConsentStore? consent,
    DateTime Function()? clock,
    this.minRefresh = const Duration(minutes: 5),
  }) : _consent = consent ?? MemoryHealthConsentStore(),
       _clock = clock ?? DateTime.now;

  final HealthGateway _gateway;
  final HealthConsentStore _consent;
  final DateTime Function() _clock;
  final Duration minRefresh;

  HealthStatus _status = HealthStatus.unsupported;
  HealthSnapshot? _snapshot;
  bool _busy = false;

  @override
  HealthProvider get provider => _gateway.provider;
  @override
  HealthStatus get status => _status;
  @override
  HealthSnapshot? get snapshot => _snapshot;
  @override
  bool get busy => _busy;

  void _set({
    HealthStatus? status,
    HealthSnapshot? snapshot,
    bool clearSnapshot = false,
    bool? busy,
  }) {
    if (status != null) _status = status;
    if (clearSnapshot) {
      _snapshot = null;
    } else if (snapshot != null) {
      _snapshot = snapshot;
    }
    if (busy != null) _busy = busy;
    notifyListeners();
  }

  @override
  Future<void> init() async {
    final a = await _gateway.availability();
    switch (a) {
      case GatewayAvailability.unsupported:
        _set(status: HealthStatus.unsupported, clearSnapshot: true);
      case GatewayAvailability.notInstalled:
        _set(status: HealthStatus.notInstalled, clearSnapshot: true);
      case GatewayAvailability.available:
        // Android: ask the OS. iOS: the OS can't say, so trust the user's remembered opt-in.
        final granted = _gateway.canQueryPermissions
            ? await _gateway.hasPermissions()
            : _consent.connected;
        if (_gateway.canQueryPermissions) await _consent.setConnected(granted);
        _set(
          status: granted ? HealthStatus.connected : HealthStatus.notConnected,
          clearSnapshot: !granted,
        );
        if (granted) await refresh(force: true);
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
    if (granted) await refresh(force: true);
    return granted;
  }

  @override
  Future<void> refresh({bool force = false}) async {
    if (_status != HealthStatus.connected || _busy) return;
    final last = _snapshot?.fetchedAt;
    final now = _clock();
    if (!force && last != null && now.difference(last) < minRefresh) return;
    _set(busy: true);
    try {
      final night = HealthSummary.lastNightWindow(now);
      final asleep = await _gateway.sleepAsleep(night.from, night.to);
      final sessions = asleep.isEmpty
          ? await _gateway.sleepSessions(night.from, night.to)
          : const <TimeSpan>[];
      final hr = await _gateway.restingHeartRate(
        now.subtract(const Duration(days: 7)),
        now,
      );
      final rhr = HealthSummary.restingHr(hr);
      _set(
        snapshot: HealthSnapshot(
          fetchedAt: now,
          sleepMinutes: HealthSummary.sleepMinutes(
            asleep: asleep,
            sessions: sessions,
          ),
          restingHr: rhr.latest,
          restingHrAvg7d: rhr.average,
        ),
      );
    } catch (e) {
      debugPrint(
        'Health refresh failed: ${e.runtimeType}',
      ); // keep previous snapshot
    } finally {
      _set(busy: false);
    }
  }

  @override
  Future<void> disconnect() async {
    await _gateway
        .revoke(); // no-op on iOS (user removes access in Settings › Health)
    await _consent.setConnected(false);
    _set(status: HealthStatus.notConnected, clearSnapshot: true);
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
  HealthSnapshot? get snapshot => null;
  @override
  bool get busy => false;
  @override
  Future<void> init() async {}
  @override
  Future<bool> connect() async => false;
  @override
  Future<void> refresh({bool force = false}) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> installProvider() async {}
}
