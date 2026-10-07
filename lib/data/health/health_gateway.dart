import '../../domain/domain.dart';

/// Thin boundary around the platform plugin so the repository logic is
/// testable without a device. Implementations must never throw for "no data";
/// they return empty lists / false.
enum GatewayAvailability { unsupported, notInstalled, available }

typedef TimeSpan = ({DateTime from, DateTime to});
typedef BpmPoint = ({DateTime at, double bpm});

abstract class HealthGateway {
  HealthProvider get provider;

  /// Android can report whether READ access is granted. iOS cannot (privacy by
  /// design) — there the repository relies on remembered consent + data presence.
  bool get canQueryPermissions;

  Future<GatewayAvailability> availability();
  Future<bool> hasPermissions();
  Future<bool> requestPermissions();

  /// Sleep stage intervals classified as asleep.
  Future<List<TimeSpan>> sleepAsleep(DateTime from, DateTime to);

  /// Whole sleep sessions (fallback when no stage data exists).
  Future<List<TimeSpan>> sleepSessions(DateTime from, DateTime to);

  Future<List<BpmPoint>> restingHeartRate(DateTime from, DateTime to);
  Future<void> revoke();
  Future<void> installProvider();
}
