/// Which platform health store is behind the integration.
enum HealthProvider {
  none('Health'),
  healthConnect('Health Connect'),
  appleHealth('Apple Health');

  const HealthProvider(this.label);
  final String label;
}

/// Availability / consent state of the optional Health Connect integration.
enum HealthStatus {
  /// Platform without Health Connect (iOS, desktop, tests).
  unsupported,

  /// Android, but the Health Connect app is missing or needs an update.
  notInstalled,

  /// Available, but the user has not granted read access (or revoked it).
  notConnected,

  /// Read access granted.
  connected,
}

/// What the app reads from Health Connect. Read-only: sleep and resting heart
/// rate. Nothing is written back and nothing leaves the device.
class HealthSnapshot {
  const HealthSnapshot({required this.fetchedAt, this.sleepMinutes, this.restingHr, this.restingHrAvg7d});

  final DateTime fetchedAt;

  /// Time asleep in the most recent night (minutes), if any sleep was recorded.
  final int? sleepMinutes;

  /// Latest resting heart rate (bpm) in the last 7 days.
  final int? restingHr;

  /// Average resting heart rate (bpm) over the last 7 days.
  final int? restingHrAvg7d;

  bool get hasData => sleepMinutes != null || restingHr != null;

  /// Today's resting HR minus the 7-day average (negative = lower/better).
  int? get restingHrDelta => (restingHr != null && restingHrAvg7d != null) ? restingHr! - restingHrAvg7d! : null;
}
