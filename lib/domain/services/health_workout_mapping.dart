import '../models/models.dart';

/// Pure mapping between StationX sessions and health-store exercise sessions.
/// No fabricated numbers: distance / energy are copied only when the user logged them.
abstract final class WorkoutMapping {
  static const maxDuration = Duration(hours: 24);
  static const maxDistanceKm = 1000.0;
  static const maxCalories = 20000;

  /// StationX cardio kind to a platform-neutral activity. Unknown / custom kinds become a
  /// generic workout ([HealthActivity.other]) so new kinds never break writing.
  static HealthActivity activityForCardio(CardioKind kind) => switch (kind) {
    CardioKind.outdoorRun || CardioKind.trailRun => HealthActivity.running,
    CardioKind.outdoorWalk || CardioKind.nordicWalk => HealthActivity.walking,
    CardioKind.indoorWalk => HealthActivity.walkingTreadmill,
    CardioKind.treadmill => HealthActivity.runningTreadmill,
    CardioKind.cycling => HealthActivity.biking,
    CardioKind.stationaryBike ||
    CardioKind.recumbentBike ||
    CardioKind.indoorTrainer ||
    CardioKind.spinBike ||
    CardioKind.airBike => HealthActivity.bikingStationary,
    CardioKind.elliptical || CardioKind.arcTrainer => HealthActivity.elliptical,
    CardioKind.rowing || CardioKind.skiErg => HealthActivity.rowingMachine,
    CardioKind.stairClimber ||
    CardioKind.verticalClimber => HealthActivity.stairClimbingMachine,
    CardioKind.jumpRope => HealthActivity.jumpRope,
    CardioKind.hiking || CardioKind.rucking => HealthActivity.hiking,
    CardioKind.swimming => HealthActivity.swimming,
    CardioKind.openWaterSwim => HealthActivity.openWaterSwimming,
    CardioKind.outdoorRowing => HealthActivity.rowing,
    CardioKind.paddling => HealthActivity.paddling,
    CardioKind.crossCountrySki => HealthActivity.crossCountrySkiing,
    CardioKind.danceCardio => HealthActivity.dance,
    CardioKind.skating => HealthActivity.skating,
    CardioKind.climbing => HealthActivity.climbing,
    CardioKind.martialArts => HealthActivity.martialArts,
    CardioKind.handCycle => HealthActivity.handCycling,
    CardioKind.hiit => HealthActivity.hiit,
    CardioKind.boxing => HealthActivity.boxing,
    _ => HealthActivity.other,
  };

  /// Raw platform activity name (Health Connect / HealthKit via the plugin) to [HealthActivity].
  /// Unknown names are [HealthActivity.other].
  static HealthActivity activityFromName(String name) => switch (name
      .toUpperCase()) {
    'RUNNING' => HealthActivity.running,
    'RUNNING_TREADMILL' => HealthActivity.runningTreadmill,
    'WALKING' => HealthActivity.walking,
    'WALKING_TREADMILL' => HealthActivity.walkingTreadmill,
    'BIKING' => HealthActivity.biking,
    'BIKING_STATIONARY' => HealthActivity.bikingStationary,
    'HIKING' => HealthActivity.hiking,
    'ROWING' => HealthActivity.rowing,
    'ROWING_MACHINE' => HealthActivity.rowingMachine,
    'ELLIPTICAL' => HealthActivity.elliptical,
    'STAIR_CLIMBING' => HealthActivity.stairClimbing,
    'STAIR_CLIMBING_MACHINE' || 'STAIRS' => HealthActivity.stairClimbingMachine,
    'SWIMMING' || 'SWIMMING_POOL' => HealthActivity.swimming,
    'SWIMMING_OPEN_WATER' => HealthActivity.openWaterSwimming,
    'CROSS_COUNTRY_SKIING' => HealthActivity.crossCountrySkiing,
    'PADDLE_SPORTS' || 'PADDLING' || 'KAYAKING' => HealthActivity.paddling,
    'CARDIO_DANCE' || 'DANCING' || 'SOCIAL_DANCE' => HealthActivity.dance,
    'SKATING' || 'ICE_SKATING' || 'ROLLER_SKATING' => HealthActivity.skating,
    'CLIMBING' || 'ROCK_CLIMBING' => HealthActivity.climbing,
    'MARTIAL_ARTS' || 'KICKBOXING' => HealthActivity.martialArts,
    'JUMP_ROPE' => HealthActivity.jumpRope,
    'HIGH_INTENSITY_INTERVAL_TRAINING' => HealthActivity.hiit,
    'BOXING' => HealthActivity.boxing,
    'HAND_CYCLING' => HealthActivity.handCycling,
    'STRENGTH_TRAINING' ||
    'WEIGHTLIFTING' ||
    'TRADITIONAL_STRENGTH_TRAINING' ||
    'FUNCTIONAL_STRENGTH_TRAINING' => HealthActivity.strength,
    _ => HealthActivity.other,
  };

  /// The StationX cardio kind to import an external activity as, or null when not defensible
  /// (strength, generic "other", sports StationX has no cardio kind for).
  static CardioKind? cardioKindFor(HealthActivity a) => switch (a) {
    HealthActivity.running => CardioKind.outdoorRun,
    HealthActivity.runningTreadmill => CardioKind.treadmill,
    HealthActivity.walkingTreadmill => CardioKind.indoorWalk,
    HealthActivity.walking => CardioKind.outdoorWalk,
    HealthActivity.biking => CardioKind.cycling,
    HealthActivity.bikingStationary => CardioKind.stationaryBike,
    HealthActivity.hiking => CardioKind.hiking,
    HealthActivity.rowingMachine => CardioKind.rowing,
    HealthActivity.elliptical => CardioKind.elliptical,
    HealthActivity.stairClimbing ||
    HealthActivity.stairClimbingMachine => CardioKind.stairClimber,
    HealthActivity.swimming => CardioKind.swimming,
    HealthActivity.openWaterSwimming => CardioKind.openWaterSwim,
    HealthActivity.crossCountrySkiing => CardioKind.crossCountrySki,
    HealthActivity.paddling => CardioKind.paddling,
    HealthActivity.dance => CardioKind.danceCardio,
    HealthActivity.skating => CardioKind.skating,
    HealthActivity.climbing => CardioKind.climbing,
    HealthActivity.martialArts => CardioKind.martialArts,
    HealthActivity.jumpRope => CardioKind.jumpRope,
    HealthActivity.hiit => CardioKind.hiit,
    HealthActivity.boxing => CardioKind.boxing,
    HealthActivity.handCycling => CardioKind.handCycle,
    _ => null,
  };

  static String cardioKey(String id) => 'c:$id';
  static String strengthKey(String id) => 's:$id';

  /// Request for a cardio session, or null when it cannot be written honestly (no duration,
  /// future start, absurd length).
  static HealthWriteRequest? forCardio(CardioSession s, {DateTime? now}) {
    final seconds = s.durationSeconds;
    if (seconds <= 0 || seconds > maxDuration.inSeconds) return null;
    if (!_startOk(s.workoutDate, now)) return null;
    final km = s.distanceKm;
    final cal = s.calories;
    return HealthWriteRequest(
      key: cardioKey(s.id),
      activity: activityForCardio(s.kind),
      start: s.workoutDate,
      end: s.workoutDate.add(Duration(seconds: seconds)),
      title: s.kind == CardioKind.custom ? 'Cardio' : s.kind.label,
      distanceMeters:
          (km != null && km.isFinite && km > 0 && km <= maxDistanceKm)
          ? (km * 1000).round()
          : null,
      energyKcal: (cal != null && cal > 0 && cal <= maxCalories) ? cal : null,
      version: s.meta.updatedAt.millisecondsSinceEpoch,
    );
  }

  /// Request for a strength workout (the cardio finisher, if any, is NOT written separately:
  /// the session already spans it). Null without a recorded duration.
  static HealthWriteRequest? forStrength(WorkoutSession s, {DateTime? now}) {
    final seconds = s.durationSeconds;
    if (seconds <= 0 || seconds > maxDuration.inSeconds) return null;
    if (!_startOk(s.workoutDate, now)) return null;
    final name = s.name.trim();
    return HealthWriteRequest(
      key: strengthKey(s.id),
      activity: HealthActivity.strength,
      start: s.workoutDate,
      end: s.workoutDate.add(Duration(seconds: seconds)),
      title: name.isEmpty
          ? 'Strength training'
          : (name.length > 60 ? name.substring(0, 60) : name),
      version: s.meta.updatedAt.millisecondsSinceEpoch,
    );
  }

  static bool _startOk(DateTime start, DateTime? now) =>
      !start.isAfter((now ?? DateTime.now()).add(const Duration(minutes: 5)));
}
