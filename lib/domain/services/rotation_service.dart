import '../models/models.dart';

/// Sequential rotation rules. Pure functions, unit-tested.
abstract final class RotationService {
  /// Index after completing a workout: (i+1) mod n. No date input exists on
  /// purpose — skipping days never changes the rotation.
  static Rotation advance(Rotation r) {
    if (r.length == 0) return r;
    return r.copyWith(currentIndex: (r.currentIndex + 1) % r.length);
  }

  /// Rotation after a workout was COMPLETED (product decision, X.4):
  ///  * the completed workout is the current one -> index+1 (wraps), same as [advance];
  ///  * it is elsewhere in the rotation (user did a different day) -> the pointer moves to the position
  ///    AFTER the performed workout, so the sequence continues from what was actually done
  ///    (if it appears more than once, the first occurrence at/after the pointer is used);
  ///  * it is NOT in the rotation (archived / ad-hoc) -> unchanged, never advanced.
  /// Pure; backdated sessions must not call this (see WorkoutCompletion).
  static Rotation afterCompleting(Rotation r, String workoutId) {
    final n = r.length;
    if (n == 0) return r;
    final cur = r.currentIndex % n;
    for (var k = 0; k < n; k++) {
      final i = (cur + k) % n;
      if (r.workoutIds[i] == workoutId) {
        return r.copyWith(currentIndex: (i + 1) % n);
      }
    }
    return r;
  }

  static Rotation pointAt(Rotation r, String workoutId) {
    final i = r.workoutIds.indexOf(workoutId);
    return i < 0 ? r : r.copyWith(currentIndex: i);
  }

  /// 1-based "Day N / M" label values.
  static (int day, int total) dayOf(Rotation r) =>
      (r.length == 0 ? 0 : (r.currentIndex % r.length) + 1, r.length);
}
