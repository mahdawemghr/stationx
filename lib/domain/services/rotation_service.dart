import '../models/models.dart';

/// Sequential rotation rules. Pure functions, unit-tested.
abstract final class RotationService {
  /// Index after completing a workout: (i+1) mod n. No date input exists on
  /// purpose — skipping days never changes the rotation.
  static Rotation advance(Rotation r) {
    if (r.length == 0) return r;
    return r.copyWith(currentIndex: (r.currentIndex + 1) % r.length);
  }

  static Rotation pointAt(Rotation r, String workoutId) {
    final i = r.workoutIds.indexOf(workoutId);
    return i < 0 ? r : r.copyWith(currentIndex: i);
  }

  /// 1-based "Day N / M" label values.
  static (int day, int total) dayOf(Rotation r) => (r.length == 0 ? 0 : (r.currentIndex % r.length) + 1, r.length);
}
