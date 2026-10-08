import '../../domain/domain.dart';

/// Thin boundary around the platform plugin so the repository logic is
/// testable without a device. Implementations must never throw for "no data";
/// they return empty lists / false.
enum GatewayAvailability { unsupported, notInstalled, available }

typedef TimeSpan = ({DateTime from, DateTime to});
typedef BpmPoint = ({DateTime at, double bpm});

abstract class HealthGateway {
  /// A gateway that does nothing (tests, unsupported platforms).
  static final HealthGateway inert = _InertGateway();

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

  // ── Optional capabilities (write workouts / enrich / import). Defaults are inert so that
  // read-only gateways and old fakes keep working. ──

  /// Origins (Android package / iOS source names) that identify records written by StationX.
  Set<String> get ownSourceIds => const {};

  /// True when the OS currently grants everything [feature] needs. Only meaningful when
  /// [canQueryPermissions]; on iOS the app relies on the remembered opt-in.
  Future<bool> hasFeaturePermissions(HealthFeature feature) async => false;

  /// Shows the system permission sheet for exactly the types [feature] needs.
  Future<bool> requestFeaturePermissions(HealthFeature feature) async => false;

  /// Writes ONE exercise session. Returns null on failure (nothing is left half-written).
  Future<HealthWriteReceipt?> writeWorkout(HealthWriteRequest request) async => null;

  /// Deletes exactly what [receipt] describes (StationX's own records). True on success.
  Future<bool> deleteWorkout(HealthWriteReceipt receipt) async => false;

  /// Exercise sessions overlapping [from, to), from any app. Empty on failure.
  Future<List<HealthWorkout>> readWorkouts(DateTime from, DateTime to) async =>
      const [];

  /// Heart-rate samples and energy within [from, to), StationX's own records excluded.
  /// Null on failure.
  Future<HealthMetrics?> readMetrics(DateTime from, DateTime to) async => null;
}

class _InertGateway extends HealthGateway {
  @override
  HealthProvider get provider => HealthProvider.none;
  @override
  bool get canQueryPermissions => false;
  @override
  Future<GatewayAvailability> availability() async => GatewayAvailability.unsupported;
  @override
  Future<bool> hasPermissions() async => false;
  @override
  Future<bool> requestPermissions() async => false;
  @override
  Future<List<TimeSpan>> sleepAsleep(DateTime from, DateTime to) async => const [];
  @override
  Future<List<TimeSpan>> sleepSessions(DateTime from, DateTime to) async => const [];
  @override
  Future<List<BpmPoint>> restingHeartRate(DateTime from, DateTime to) async => const [];
  @override
  Future<void> revoke() async {}
  @override
  Future<void> installProvider() async {}
}
