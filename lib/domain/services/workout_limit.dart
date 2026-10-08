/// Maximum workout length policy. Pure functions.
///
/// "Elapsed" uses the SAME definition as the logger (`ActiveWorkoutController.elapsedSeconds`):
/// wall-clock time since the workout started (paused/rest time is NOT excluded).
/// Robust to clock changes: elapsed is never negative; if the device clock went backwards
/// (now < startedAt) the workout is simply not expired.
abstract final class WorkoutLimit {
  /// Default when the user never chose: 3 hours.
  static const int defaultMinutes = 180;

  /// Selectable limits in minutes; `null` = off (no limit).
  static const List<int?> options = [120, 180, 240, null];

  static String label(int? minutes) {
    if (minutes == null) return 'Off';
    final h = minutes ~/ 60, m = minutes % 60;
    if (m == 0) return '$h hour${h == 1 ? '' : 's'}';
    return h == 0 ? '$m min' : '${h}h ${m}min';
  }

  /// Elapsed seconds since [startedAt], clamped at 0.
  static int elapsedSeconds(DateTime startedAt, DateTime now) {
    final s = now.difference(startedAt).inSeconds;
    return s < 0 ? 0 : s;
  }

  /// True when the limit is on and elapsed >= the limit (exactly at the limit = expired).
  static bool isExpired(DateTime startedAt, DateTime now, int? maxMinutes) {
    if (maxMinutes == null || maxMinutes <= 0) return false;
    return elapsedSeconds(startedAt, now) >= maxMinutes * 60;
  }

  /// min(elapsed, limit) in seconds; just elapsed when the limit is off.
  static int cappedDuration(DateTime startedAt, DateTime now, int? maxMinutes) {
    final e = elapsedSeconds(startedAt, now);
    if (maxMinutes == null || maxMinutes <= 0) return e;
    final cap = maxMinutes * 60;
    return e < cap ? e : cap;
  }
}
