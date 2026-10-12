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
