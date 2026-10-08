import '../models/models.dart';
import '../repositories/repositories.dart';
import 'rotation_service.dart';

/// Saves a finished session and moves the rotation (see
/// [RotationService.afterCompleting] for the product decision):
///  * completing the CURRENT workout advances the pointer by one (wraps);
///  * completing another workout that is in the rotation points to the position after it;
///  * completing a workout that is not in the rotation (archived / ad-hoc) never changes it;
///  * backdated sessions ([advanceRotation] false) never touch the rotation.
/// `workoutDate` is taken from the session as supplied (backdatable);
/// `createdAt` is stamped at construction time of the session meta.
class WorkoutCompletion {
  WorkoutCompletion(this.sessions, this.workouts);
  final SessionRepository sessions;
  final WorkoutRepository workouts;

  /// [advanceRotation] is false for backdated entries of past workouts.
  Future<void> complete(
    WorkoutSession session, {
    bool advanceRotation = true,
  }) async {
    await sessions.add(session);
    if (!advanceRotation) return;
    final rot = workouts.rotation;
    if (rot.length == 0) return;
    if (rot.currentWorkoutId == session.workoutId) {
      await workouts.advanceRotation(); // exactly today's behaviour
      return;
    }
    final next = RotationService.afterCompleting(rot, session.workoutId);
    if (next.currentIndex != rot.currentIndex) await workouts.setRotation(next);
  }
}
