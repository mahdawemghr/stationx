import '../models/models.dart';
import '../repositories/repositories.dart';

/// Saves a finished session and advances the rotation exactly once.
/// `workoutDate` is taken from the session as supplied (backdatable);
/// `createdAt` is stamped at construction time of the session meta.
class WorkoutCompletion {
  WorkoutCompletion(this.sessions, this.workouts);
  final SessionRepository sessions;
  final WorkoutRepository workouts;

  /// [advanceRotation] is false for backdated entries of past workouts.
  Future<void> complete(WorkoutSession session, {bool advanceRotation = true}) async {
    await sessions.add(session);
    if (advanceRotation) await workouts.advanceRotation();
  }
}
