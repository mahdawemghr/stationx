import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Haptics used by the workout logger. Injectable so tests can verify calls.
abstract class DeviceFeedback {
  /// A set was marked done.
  void setDone();

  /// The rest countdown reached zero (double pulse).
  void restEnded();
}

class HapticDeviceFeedback implements DeviceFeedback {
  const HapticDeviceFeedback();

  @override
  void setDone() => _run(() => HapticFeedback.mediumImpact());

  @override
  void restEnded() {
    _run(() => HapticFeedback.heavyImpact());
    Future<void>.delayed(const Duration(milliseconds: 180), () => _run(() => HapticFeedback.heavyImpact()));
  }

  static void _run(Future<void> Function() f) {
    try {
      f().catchError((Object _) {});
    } catch (_) {}
  }
}

/// Keeps the screen awake while the logger is open. Wraps the plugin so tests do not need it.
abstract class KeepAwake {
  Future<void> enable();
  Future<void> disable();
}

class PluginKeepAwake implements KeepAwake {
  @override
  Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {} // unsupported platform / no plugin: best effort
  }

  @override
  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }
}

class NoopKeepAwake implements KeepAwake {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}
