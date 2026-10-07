import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../../domain/domain.dart';
import 'health_gateway.dart';

/// Health Connect (Android) and Apple Health / HealthKit (iOS) via the `health`
/// plugin. Read-only access to sleep and resting heart rate; all on-device.
///
/// NOT covered by automated tests (needs a real device). The iOS path has not
/// even been compiled on a Mac/Xcode yet. Keep this class thin — all logic
/// lives in HealthConnectRepository / HealthSummary.
class PluginHealthGateway implements HealthGateway {
  final Health _health = Health();
  bool _configured = false;

  // iOS has no "sleep session" type; "in bed" is its closest equivalent and is
  // only used as a fallback when no asleep stages exist.
  static final _ios = Platform.isIOS;
  static final _types = [
    HealthDataType.SLEEP_ASLEEP,
    if (_ios) HealthDataType.SLEEP_IN_BED else HealthDataType.SLEEP_SESSION,
    HealthDataType.RESTING_HEART_RATE,
  ];
  static final _access = List.filled(_types.length, HealthDataAccess.READ);

  @override
  HealthProvider get provider => _ios ? HealthProvider.appleHealth : HealthProvider.healthConnect;

  @override
  bool get canQueryPermissions => !_ios;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<GatewayAvailability> availability() async {
    if (Platform.isIOS) return GatewayAvailability.available; // HealthKit is built in on iPhone
    if (!Platform.isAndroid) return GatewayAvailability.unsupported;
    try {
      await _ensureConfigured();
      final s = await _health.getHealthConnectSdkStatus();
      return switch (s) {
        HealthConnectSdkStatus.sdkAvailable => GatewayAvailability.available,
        null => GatewayAvailability.unsupported,
        _ => GatewayAvailability.notInstalled,
      };
    } catch (e) {
      debugPrint('HealthGateway.availability failed: ${e.runtimeType}');
      return GatewayAvailability.unsupported;
    }
  }

  @override
  Future<bool> hasPermissions() async {
    if (_ios) return false; // HealthKit never discloses READ status; see HealthConsentStore
    try {
      await _ensureConfigured();
      return await _health.hasPermissions(_types, permissions: _access) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();
      return await _health.requestAuthorization(_types, permissions: _access);
    } catch (_) {
      return false;
    }
  }

  Future<List<HealthDataPoint>> _read(HealthDataType t, DateTime from, DateTime to) async {
    try {
      await _ensureConfigured();
      return await _health.getHealthDataFromTypes(types: [t], startTime: from, endTime: to);
    } catch (e) {
      debugPrint('HealthGateway read ${t.name} failed: ${e.runtimeType}');
      return const [];
    }
  }

  @override
  Future<List<TimeSpan>> sleepAsleep(DateTime from, DateTime to) async =>
      [for (final p in await _read(HealthDataType.SLEEP_ASLEEP, from, to)) (from: p.dateFrom, to: p.dateTo)];

  @override
  Future<List<TimeSpan>> sleepSessions(DateTime from, DateTime to) async =>
      [
        for (final p in await _read(_ios ? HealthDataType.SLEEP_IN_BED : HealthDataType.SLEEP_SESSION, from, to))
          (from: p.dateFrom, to: p.dateTo)
      ];

  @override
  Future<List<BpmPoint>> restingHeartRate(DateTime from, DateTime to) async {
    final out = <BpmPoint>[];
    for (final p in await _read(HealthDataType.RESTING_HEART_RATE, from, to)) {
      final v = p.value;
      if (v is NumericHealthValue) out.add((at: p.dateTo, bpm: v.numericValue.toDouble()));
    }
    return out;
  }

  @override
  Future<void> revoke() async {
    try {
      await _ensureConfigured();
      await _health.revokePermissions();
    } catch (_) {}
  }

  @override
  Future<void> installProvider() async {
    try {
      await _ensureConfigured();
      await _health.installHealthConnect();
    } catch (_) {}
  }
}
