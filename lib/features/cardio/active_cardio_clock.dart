import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';

/// Wall-clock source. Tests replace it to advance time deterministically.
@visibleForTesting
DateTime Function() cardioNow = DateTime.now;

/// Accumulating stopwatch for a live cardio session. Counts only *active*
/// time; paused time is tracked separately. Uses the wall clock (not ticks) so
/// it stays correct when the UI timer is throttled in the background.
class CardioClock {
  CardioClock() : startedAt = cardioNow(), _runningSince = cardioNow();

  /// Rebuilds a clock from a persisted session; time keeps counting across the time the app was closed.
  CardioClock.restore(ActiveCardioDraft d)
    : startedAt = d.startedAt,
      _activeMs = d.activeMs,
      _pausedMs = d.pausedMs,
      _runningSince = d.runningSince,
      _pausedSince = d.pausedSince;

  final DateTime startedAt;
  int _activeMs = 0;
  int _pausedMs = 0;
  DateTime? _runningSince;
  DateTime? _pausedSince;

  bool get running => _runningSince != null;

  /// Persistable state of this clock (the page adds the rest of the session).
  ActiveCardioDraft snapshot({
    required CardioKind kind,
    int? targetMinutes,
    double? targetKm,
    String? customActivityId,
    double? km,
    double? speedKmh,
    double? inclinePct,
    int? resistance,
    String? saveId,
  }) => ActiveCardioDraft(
    kind: kind,
    startedAt: startedAt,
    activeMs: _activeMs,
    pausedMs: _pausedMs,
    runningSince: _runningSince,
    pausedSince: _pausedSince,
    targetMinutes: targetMinutes,
    targetKm: targetKm,
    customActivityId: customActivityId,
    km: km,
    speedKmh: speedKmh,
    inclinePct: inclinePct,
    resistance: resistance,
    saveId: saveId,
  );

  int get activeSeconds {
    final live = _runningSince == null
        ? 0
        : cardioNow().difference(_runningSince!).inMilliseconds;
    return (_activeMs + live) ~/ 1000;
  }

  /// Total seconds spent paused.
  int get pausedSeconds {
    final live = _pausedSince == null
        ? 0
        : cardioNow().difference(_pausedSince!).inMilliseconds;
    return (_pausedMs + live) ~/ 1000;
  }

  void pause() {
    if (_runningSince == null) return;
    final n = cardioNow();
    _activeMs += n.difference(_runningSince!).inMilliseconds;
    _runningSince = null;
    _pausedSince = n;
  }

  void resume() {
    if (_runningSince != null) return;
    final n = cardioNow();
    if (_pausedSince != null) {
      _pausedMs += n.difference(_pausedSince!).inMilliseconds;
    }
    _pausedSince = null;
    _runningSince = n;
  }
}
