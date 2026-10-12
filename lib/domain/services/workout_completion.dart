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
  WorkoutCompletion(this.sessions, this.workouts, {this.finisher});
  final SessionRepository sessions;
  final WorkoutRepository workouts;

  /// When set, the session and the rotation move are saved as one atomic operation.
  final AtomicWorkoutFinisher? finisher;

  /// [advanceRotation] is false for backdated entries of past workouts.
  Future<void> complete(
    WorkoutSession session, {
    bool advanceRotation = true,
  }) async {
    final rot = workouts.rotation;
    final Rotation? next = !advanceRotation || rot.length == 0
        ? null
        : rot.currentWorkoutId == session.workoutId
        ? RotationService.advance(rot) // exactly today's behaviour
        : RotationService.afterCompleting(rot, session.workoutId);
    final move = next != null && next.currentIndex != rot.currentIndex
        ? next
        : null;
    final f = finisher;
    if (f != null) {
      await f.finishWorkout(session, move);
      return;
    }
    await sessions.add(session);
    if (move != null) await workouts.setRotation(move);
  }
}
