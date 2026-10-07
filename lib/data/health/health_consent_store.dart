/// Remembers that the user opted in. Needed on iOS, where HealthKit never says
/// whether READ access was granted (so the OS cannot be asked). On Android the
/// system permission is authoritative and this flag is only informational.
abstract class HealthConsentStore {
  bool get connected;
  Future<void> setConnected(bool value);
}

class MemoryHealthConsentStore implements HealthConsentStore {
  MemoryHealthConsentStore([this._connected = false]);
  bool _connected;
  @override
  bool get connected => _connected;
  @override
  Future<void> setConnected(bool value) async => _connected = value;
}
