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
  HealthProvider get provider =>
      _ios ? HealthProvider.appleHealth : HealthProvider.healthConnect;

  @override
  bool get canQueryPermissions => !_ios;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<GatewayAvailability> availability() async {
    if (Platform.isIOS) {
      return GatewayAvailability.available; // HealthKit is built in on iPhone
    }
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
    if (_ios) {
      return false; // HealthKit never discloses READ status; see HealthConsentStore
    }
    try {
      await _ensureConfigured();
      return await _health.hasPermissions(_types, permissions: _access) ??
          false;
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

  Future<List<HealthDataPoint>> _read(
    HealthDataType t,
    DateTime from,
    DateTime to,
  ) async {
    try {
      await _ensureConfigured();
      return await _health.getHealthDataFromTypes(
        types: [t],
        startTime: from,
        endTime: to,
      );
    } catch (e) {
      debugPrint('HealthGateway read ${t.name} failed: ${e.runtimeType}');
      return const [];
    }
  }

  @override
  Future<List<TimeSpan>> sleepAsleep(DateTime from, DateTime to) async => [
    for (final p in await _read(HealthDataType.SLEEP_ASLEEP, from, to))
      (from: p.dateFrom, to: p.dateTo),
  ];

  @override
  Future<List<TimeSpan>> sleepSessions(DateTime from, DateTime to) async => [
    for (final p in await _read(
      _ios ? HealthDataType.SLEEP_IN_BED : HealthDataType.SLEEP_SESSION,
      from,
      to,
    ))
      (from: p.dateFrom, to: p.dateTo),
  ];

  @override
  Future<List<BpmPoint>> restingHeartRate(DateTime from, DateTime to) async {
    final out = <BpmPoint>[];
    for (final p in await _read(HealthDataType.RESTING_HEART_RATE, from, to)) {
      final v = p.value;
      if (v is NumericHealthValue) {
        out.add((at: p.dateTo, bpm: v.numericValue.toDouble()));
      }
    }
    return out;
  }

  // ───────────────────────── workouts: write / read ─────────────────────────

  static const _ownPackage = 'dev.mahdi_ramadhan.stationx';
  @override
  Set<String> get ownSourceIds => const {_ownPackage, 'StationX'};

  List<HealthDataType> _featureTypes(HealthFeature f) => switch (f) {
    HealthFeature.writeWorkouts => [
      HealthDataType.WORKOUT,
      if (!_ios) ...[
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.TOTAL_CALORIES_BURNED,
      ],
    ],
    HealthFeature.enrichCardio => [
      HealthDataType.HEART_RATE,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      if (!_ios) HealthDataType.TOTAL_CALORIES_BURNED,
    ],
    HealthFeature.importWorkouts => [
      HealthDataType.WORKOUT,
      // The plugin's Android workout reader also sums distance, energy and steps in the window.
      if (!_ios) ...[
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.STEPS,
      ],
    ],
  };

  HealthDataAccess _featureAccess(HealthFeature f) => f == HealthFeature.writeWorkouts
      ? HealthDataAccess.WRITE
      : HealthDataAccess.READ;

  @override
  Future<bool> hasFeaturePermissions(HealthFeature feature) async {
    if (_ios) return false;
    try {
      await _ensureConfigured();
      final t = _featureTypes(feature);
      return await _health.hasPermissions(
            t,
            permissions: List.filled(t.length, _featureAccess(feature)),
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestFeaturePermissions(HealthFeature feature) async {
    try {
      await _ensureConfigured();
      final t = _featureTypes(feature);
      return await _health.requestAuthorization(
        t,
        permissions: List.filled(t.length, _featureAccess(feature)),
      );
    } catch (_) {
      return false;
    }
  }

  // Health Connect's native layer has no BIKING_STATIONARY / JUMP_ROPE / HAND_CYCLING /
  // WALKING_TREADMILL (plugin 13.3.2), so those degrade to the closest supported type.
  HealthWorkoutActivityType _platformType(HealthActivity a) => switch (a) {
    HealthActivity.running => HealthWorkoutActivityType.RUNNING,
    HealthActivity.runningTreadmill => _ios ? HealthWorkoutActivityType.RUNNING : HealthWorkoutActivityType.RUNNING_TREADMILL,
    HealthActivity.walking || HealthActivity.walkingTreadmill => HealthWorkoutActivityType.WALKING,
    HealthActivity.biking || HealthActivity.bikingStationary => HealthWorkoutActivityType.BIKING,
    HealthActivity.hiking => HealthWorkoutActivityType.HIKING,
    HealthActivity.rowing => HealthWorkoutActivityType.ROWING,
    HealthActivity.rowingMachine => _ios ? HealthWorkoutActivityType.ROWING : HealthWorkoutActivityType.ROWING_MACHINE,
    HealthActivity.elliptical => HealthWorkoutActivityType.ELLIPTICAL,
    HealthActivity.stairClimbing => HealthWorkoutActivityType.STAIR_CLIMBING,
    HealthActivity.stairClimbingMachine => _ios ? HealthWorkoutActivityType.STAIR_CLIMBING : HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE,
    HealthActivity.swimming => _ios ? HealthWorkoutActivityType.SWIMMING : HealthWorkoutActivityType.SWIMMING_POOL,
    HealthActivity.jumpRope => _ios ? HealthWorkoutActivityType.JUMP_ROPE : HealthWorkoutActivityType.OTHER,
    HealthActivity.hiit => HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING,
    HealthActivity.boxing => HealthWorkoutActivityType.BOXING,
    HealthActivity.handCycling => _ios ? HealthWorkoutActivityType.HAND_CYCLING : HealthWorkoutActivityType.OTHER,
    HealthActivity.strength => _ios ? HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING : HealthWorkoutActivityType.STRENGTH_TRAINING,
    HealthActivity.other => HealthWorkoutActivityType.OTHER,
  };

  static String _distId(String key) => 'stationx.$key.dist';
  static String _kcalId(String key) => 'stationx.$key.kcal';

  @override
  Future<HealthWriteReceipt?> writeWorkout(HealthWriteRequest r) async {
    try {
      await _ensureConfigured();
      // Android: distance / energy are separate records with a client record id (so a re-save
      // upserts them). iOS: they are properties of the HKWorkout itself.
      final id = await _health.writeWorkoutDataUUID(
        activityType: _platformType(r.activity),
        start: r.start,
        end: r.end,
        title: r.title,
        totalDistance: _ios ? r.distanceMeters : null,
        totalEnergyBurned: _ios ? r.energyKcal : null,
        recordingMethod: RecordingMethod.manual,
      );
      if (id == null || id.isEmpty) return null;
      final extras = <String>[];
      if (!_ios) {
        try {
          if (r.distanceMeters != null) {
            final ok = await _health.writeHealthDataUUID(
              value: r.distanceMeters!.toDouble(),
              type: HealthDataType.DISTANCE_DELTA,
              startTime: r.start,
              endTime: r.end,
              clientRecordId: _distId(r.key),
              clientRecordVersion: r.version.toDouble(),
              recordingMethod: RecordingMethod.manual,
            );
            if (ok == null || ok.isEmpty) throw StateError('distance');
            extras.add(_distId(r.key));
          }
          if (r.energyKcal != null) {
            final ok = await _health.writeHealthDataUUID(
              value: r.energyKcal!.toDouble(),
              type: HealthDataType.TOTAL_CALORIES_BURNED,
              startTime: r.start,
              endTime: r.end,
              clientRecordId: _kcalId(r.key),
              clientRecordVersion: r.version.toDouble(),
              recordingMethod: RecordingMethod.manual,
            );
            if (ok == null || ok.isEmpty) throw StateError('energy');
            extras.add(_kcalId(r.key));
          }
        } catch (_) {
          // Never leave a session without its numbers: roll back, the caller retries.
          await deleteWorkout(HealthWriteReceipt(workoutId: id, extraClientIds: extras));
          return null;
        }
      }
      return HealthWriteReceipt(workoutId: id, extraClientIds: extras);
    } catch (e) {
      debugPrint('HealthGateway.writeWorkout failed: ${e.runtimeType}');
      return null;
    }
  }

  @override
  Future<bool> deleteWorkout(HealthWriteReceipt receipt) async {
    try {
      await _ensureConfigured();
      var ok = await _health.deleteByUUID(
        uuid: receipt.workoutId,
        type: HealthDataType.WORKOUT,
      );
      for (final cid in receipt.extraClientIds) {
        final type = cid.endsWith('.dist')
            ? HealthDataType.DISTANCE_DELTA
            : HealthDataType.TOTAL_CALORIES_BURNED;
        ok = await _health.deleteByClientRecordId(
              dataTypeKey: type,
              clientRecordId: cid,
            ) &&
            ok;
      }
      return ok;
    } catch (e) {
      debugPrint('HealthGateway.deleteWorkout failed: ${e.runtimeType}');
      return false;
    }
  }

  @override
  Future<List<HealthWorkout>> readWorkouts(DateTime from, DateTime to) async {
    final out = <HealthWorkout>[];
    for (final p in await _read(HealthDataType.WORKOUT, from, to)) {
      final v = p.value;
      final id = p.uuid;
      if (v is! WorkoutHealthValue || id.isEmpty) continue;
      double? meters;
      if (v.totalDistance != null) {
        meters = switch (v.totalDistanceUnit) {
          HealthDataUnit.MILE => v.totalDistance! * 1609.344,
          HealthDataUnit.FOOT => v.totalDistance! * 0.3048,
          HealthDataUnit.CENTIMETER => v.totalDistance! / 100,
          _ => v.totalDistance!.toDouble(),
        };
      }
      out.add(
        HealthWorkout(
          id: id,
          activityName: v.workoutActivityType.name,
          start: p.dateFrom,
          end: p.dateTo,
          sourceName: p.sourceName,
          distanceMeters: meters,
          energyKcal: v.totalEnergyBurned?.toDouble(),
        ),
      );
    }
    return out;
  }

  @override
  Future<HealthMetrics?> readMetrics(DateTime from, DateTime to) async {
    try {
      await _ensureConfigured();
      final points = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.HEART_RATE,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          if (!_ios) HealthDataType.TOTAL_CALORIES_BURNED,
        ],
        startTime: from,
        endTime: to,
      );
      final hr = <double>[];
      double active = 0, total = 0;
      var hasActive = false, hasTotal = false;
      for (final p in points) {
        if (ownSourceIds.contains(p.sourceName) || ownSourceIds.contains(p.sourceId)) continue;
        final v = p.value;
        if (v is! NumericHealthValue) continue;
        final n = v.numericValue.toDouble();
        switch (p.type) {
          case HealthDataType.HEART_RATE:
            hr.add(n);
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            active += n;
            hasActive = true;
          case HealthDataType.TOTAL_CALORIES_BURNED:
            total += n;
            hasTotal = true;
          default:
        }
      }
      return HealthMetrics(
        heartRates: hr,
        activeKcal: hasActive ? active : null,
        totalKcal: hasTotal ? total : null,
      );
    } catch (e) {
      debugPrint('HealthGateway.readMetrics failed: ${e.runtimeType}');
      return null;
    }
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
