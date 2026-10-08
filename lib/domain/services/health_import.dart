import '../models/models.dart';
import '../repositories/repositories.dart';
import 'health_workout_mapping.dart';

/// What importing exercise sessions from the health store WOULD do (shown to the user first).
class HealthImportPlan {
  const HealthImportPlan({
    required this.sessions,
    required this.externalIds,
    required this.skippedOwn,
    required this.skippedAlreadyImported,
    required this.skippedUnsupported,
    required this.skippedInvalid,
    required this.sourceLabels,
  });

  /// Cardio sessions to add (oldest first).
  final List<CardioSession> sessions;

  /// External record id for each entry of [sessions] (same order).
  final List<String> externalIds;
  final int skippedOwn;
  final int skippedAlreadyImported;
  final int skippedUnsupported;
  final int skippedInvalid;

  /// Friendly origin names found among the sessions (e.g. `Samsung Health`).
  final Set<String> sourceLabels;

  bool get isEmpty => sessions.isEmpty;
}

abstract final class HealthImport {
  static const idPrefix = 'hc_';
  static const defaultDays = 30;
  static const maxDays = 90;
  static const maxSessions = 500;
  static const minDuration = Duration(minutes: 1);
  static const maxDuration = Duration(hours: 24);
  static const maxDistanceKm = 1000.0;
  static const maxCalories = 20000;
  static const maxSpeedKmh = 100.0;

  /// Android package names -> friendly names (anything else is shown as nothing, never raw).
  static const knownSources = {
    'com.sec.android.app.shealth': 'Samsung Health',
    'com.google.android.apps.fitness': 'Google Fit',
    'com.google.android.apps.healthdata': 'Health Connect',
    'com.fitbit.FitbitMobile': 'Fitbit',
    'com.garmin.android.apps.connectmobile': 'Garmin Connect',
    'com.strava': 'Strava',
    'com.polar.polarflow': 'Polar Flow',
    'com.huawei.health': 'Huawei Health',
  };

  static int clampDays(int? d) => (d ?? defaultDays).clamp(1, maxDays);

  /// Deterministic StationX session id for an external record id (FNV-1a, 64-bit hex).
  static String sessionIdFor(String externalId) {
    var h = 0xcbf29ce484222325;
    for (final c in externalId.codeUnits) {
      h = ((h ^ c) * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return '$idPrefix${h.toRadixString(16)}';
  }

  /// [ownSourceIds]: origins written by StationX itself. [ownRecordIds]: ids StationX wrote.
  /// [alreadyImported]: external ids imported before (even if the session was later deleted).
  static HealthImportPlan plan(
    Iterable<HealthWorkout> candidates, {
    required Set<String> ownSourceIds,
    Set<String> ownRecordIds = const {},
    Set<String> alreadyImported = const {},
    Set<String> existingSessionIds = const {},
    String sourceNote = 'Imported from Health Connect',
    DateTime? now,
    int? days,
  }) {
    final t = now ?? DateTime.now();
    final earliest = t.subtract(Duration(days: clampDays(days)));
    final latest = t.add(const Duration(minutes: 5));
    final out = <(HealthWorkout, CardioKind)>[];
    final seen = <String>{};
    var own = 0, dup = 0, unsupported = 0, invalid = 0;
    for (final w in candidates) {
      if (w.id.isEmpty || w.id.length > 200 || !seen.add(w.id)) {
        invalid++;
        continue;
      }
      if (ownSourceIds.contains(w.sourceName) || ownRecordIds.contains(w.id)) {
        own++;
        continue;
      }
      final sid = sessionIdFor(w.id);
      if (alreadyImported.contains(w.id) || existingSessionIds.contains(sid)) {
        dup++;
        continue;
      }
      final kind = WorkoutMapping.cardioKindFor(
        WorkoutMapping.activityFromName(w.activityName),
      );
      if (kind == null) {
        unsupported++;
        continue;
      }
      final d = w.end.difference(w.start);
      if (d < minDuration ||
          d > maxDuration ||
          w.start.isBefore(earliest) ||
          w.end.isAfter(latest)) {
        invalid++; // also drops not-yet-completed (end in the future) sessions
        continue;
      }
      out.add((w, kind));
    }
    out.sort((a, b) => a.$1.start.compareTo(b.$1.start));
    final picked = out.length > maxSessions ? out.sublist(out.length - maxSessions) : out;
    final labels = <String>{};
    final sessions = <CardioSession>[];
    for (final (w, kind) in picked) {
      final secs = w.end.difference(w.start).inSeconds;
      var km = (w.distanceMeters != null && w.distanceMeters!.isFinite && w.distanceMeters! > 0)
          ? w.distanceMeters! / 1000
          : null;
      if (km != null && (km > maxDistanceKm || km / (secs / 3600) > maxSpeedKmh)) km = null;
      final cal = (w.energyKcal != null && w.energyKcal!.isFinite && w.energyKcal! >= 1 && w.energyKcal! <= maxCalories)
          ? w.energyKcal!.round()
          : null;
      final label = knownSources[w.sourceName];
      if (label != null) labels.add(label);
      sessions.add(
        CardioSession(
          id: sessionIdFor(w.id),
          kind: kind,
          workoutDate: w.start,
          durationSeconds: secs,
          distanceKm: km,
          calories: cal,
          notes: label == null ? sourceNote : '$sourceNote ($label)',
          meta: SyncMeta(createdAt: t, updatedAt: t),
        ),
      );
    }
    return HealthImportPlan(
      sessions: sessions,
      externalIds: [
        for (final (w, _) in picked) w.id,
      ],
      skippedOwn: own,
      skippedAlreadyImported: dup,
      skippedUnsupported: unsupported,
      skippedInvalid: invalid,
      sourceLabels: labels,
    );
  }

  /// Adds the planned sessions to [cardio] (never touches strength history). Skips ids that
  /// appeared in the meantime, so applying twice adds nothing. Returns how many were added.
  static Future<int> apply(HealthImportPlan plan, CardioRepository cardio) async {
    var added = 0;
    for (final s in plan.sessions) {
      if (cardio.byId(s.id) != null) continue;
      await cardio.add(s);
      added++;
    }
    return added;
  }
}
