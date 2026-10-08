/// The three independent, opt-in Health Connect / Apple Health capabilities. All default OFF.
enum HealthFeature {
  /// Save finished workouts to Health Connect / Apple Health (write exercise sessions).
  writeWorkouts,

  /// Suggest average heart rate / calories for a cardio session from the health store (read).
  enrichCardio,

  /// Import exercise sessions recorded by other apps (Samsung Health, a watch, ...) (read).
  importWorkouts,
}

/// Platform-neutral activity type. The gateway turns it into the platform enum; the mapping from
/// StationX kinds lives in `WorkoutMapping`.
enum HealthActivity {
  running,
  runningTreadmill,
  walking,
  walkingTreadmill,
  biking,
  bikingStationary,
  hiking,
  rowing,
  rowingMachine,
  elliptical,
  stairClimbing,
  stairClimbingMachine,
  swimming,
  jumpRope,
  hiit,
  boxing,
  handCycling,
  strength,

  /// Any activity StationX cannot name (written as a generic workout; never imported).
  other,
}

/// One exercise session to save. Built by `WorkoutMapping`; contains ONLY what the user logged.
class HealthWriteRequest {
  const HealthWriteRequest({
    required this.key,
    required this.activity,
    required this.start,
    required this.end,
    required this.title,
    this.distanceMeters,
    this.energyKcal,
    this.version = 0,
  });

  /// Stable StationX key: `c:<cardioSessionId>` or `s:<strengthSessionId>`.
  final String key;
  final HealthActivity activity;
  final DateTime start;
  final DateTime end;
  final String title;

  /// Whole metres, only when the user logged a distance.
  final int? distanceMeters;

  /// Whole kcal, only when the user logged calories.
  final int? energyKcal;

  /// Monotonic per edit (milliseconds since epoch of the edit); used as the record version.
  final int version;

  HealthWriteRequest withVersion(int v) => HealthWriteRequest(
    key: key,
    activity: activity,
    start: start,
    end: end,
    title: title,
    distanceMeters: distanceMeters,
    energyKcal: energyKcal,
    version: v,
  );

  Map<String, Object?> toJson() => {
    'key': key,
    'activity': activity.name,
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'title': title,
    'distanceMeters': distanceMeters,
    'energyKcal': energyKcal,
    'version': version,
  };

  static HealthWriteRequest? tryParse(Object? raw) {
    try {
      final m = (raw as Map).cast<String, Object?>();
      final a = HealthActivity.values.where((e) => e.name == m['activity']);
      return HealthWriteRequest(
        key: m['key']! as String,
        activity: a.isEmpty ? HealthActivity.other : a.first,
        start: DateTime.fromMillisecondsSinceEpoch(m['start']! as int),
        end: DateTime.fromMillisecondsSinceEpoch(m['end']! as int),
        title: (m['title'] as String?) ?? '',
        distanceMeters: m['distanceMeters'] as int?,
        energyKcal: m['energyKcal'] as int?,
        version: (m['version'] as int?) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

/// What StationX wrote for one key, so it can later be replaced/deleted (and only those records).
class HealthWriteReceipt {
  const HealthWriteReceipt({
    required this.workoutId,
    this.extraClientIds = const [],
  });

  /// Platform id (Health Connect record uuid / HealthKit workout uuid) of the session.
  final String workoutId;

  /// Health Connect only: client record ids of the separate distance / calories records.
  final List<String> extraClientIds;

  Map<String, Object?> toJson() => {
    'workoutId': workoutId,
    'extra': extraClientIds,
  };

  static HealthWriteReceipt? tryParse(Object? raw) {
    try {
      final m = (raw as Map).cast<String, Object?>();
      final id = m['workoutId'];
      if (id is! String || id.isEmpty) return null;
      return HealthWriteReceipt(
        workoutId: id,
        extraClientIds: [
          for (final e in (m['extra'] as List? ?? const []))
            if (e is String) e,
        ],
      );
    } catch (_) {
      return null;
    }
  }
}

/// An exercise session read from the health store (recorded by some app).
class HealthWorkout {
  const HealthWorkout({
    required this.id,
    required this.activityName,
    required this.start,
    required this.end,
    this.sourceName = '',
    this.distanceMeters,
    this.energyKcal,
  });

  /// Platform record id (stable across reads).
  final String id;

  /// Raw platform activity name (e.g. `RUNNING`); mapped by `WorkoutMapping.activityFromName`.
  final String activityName;
  final DateTime start;
  final DateTime end;

  /// Origin: Android package name / iOS source name.
  final String sourceName;
  final double? distanceMeters;
  final double? energyKcal;
}

/// Raw metrics read for a time window (own StationX records already excluded by the gateway).
class HealthMetrics {
  const HealthMetrics({
    this.heartRates = const [],
    this.activeKcal,
    this.totalKcal,
  });
  final List<double> heartRates;
  final double? activeKcal;
  final double? totalKcal;
}

/// Values the health store could fill into a cardio session. Only fields that are empty in the
/// session are ever present; the UI must show them and apply only after the user confirms.
class HealthEnrichment {
  const HealthEnrichment({this.avgHeartRate, this.calories});
  final int? avgHeartRate;
  final int? calories;
  bool get isEmpty => avgHeartRate == null && calories == null;
}
