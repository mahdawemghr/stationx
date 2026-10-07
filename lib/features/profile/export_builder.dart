import 'dart:convert';

import '../../domain/domain.dart';

/// Builds plain-text exports of local data. Pure formatting (no calculations).
abstract final class ExportBuilder {
  static String json({
    required UserProfile profile,
    required List<WorkoutSession> sessions,
    required List<CardioSession> cardio,
  }) {
    final data = {
      'app': 'StationX',
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': {'name': profile.name, 'unit': profile.unit.name},
      'workoutSessions': [
        for (final s in sessions)
          {
            'id': s.id,
            'workout': s.name,
            'workoutDate': s.workoutDate.toIso8601String(),
            'createdAt': s.meta.createdAt.toIso8601String(),
            'durationSeconds': s.durationSeconds,
            'exercises': [
              for (final e in s.exercises)
                {
                  'exerciseId': e.exerciseId,
                  'sets': [
                    for (final x in e.sets) {'weightKg': x.weightKg, 'reps': x.reps, 'done': x.done, if (x.rpe != null) 'rpe': x.rpe}
                  ],
                }
            ],
          }
      ],
      'cardioSessions': [
        for (final c in cardio)
          {
            'id': c.id,
            'kind': c.kind.name,
            'workoutDate': c.workoutDate.toIso8601String(),
            'createdAt': c.meta.createdAt.toIso8601String(),
            'durationSeconds': c.durationSeconds,
            if (c.distanceKm != null) 'distanceKm': c.distanceKm,
            if (c.speedKmh != null) 'speedKmh': c.speedKmh,
            if (c.inclinePct != null) 'inclinePct': c.inclinePct,
            if (c.resistance != null) 'resistance': c.resistance,
            if (c.calories != null) 'calories': c.calories,
            if (c.avgHeartRate != null) 'avgHeartRate': c.avgHeartRate,
          }
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// One row per logged set + one row per cardio session.
  static String csv({required List<WorkoutSession> sessions, required List<CardioSession> cardio}) {
    final b = StringBuffer('type,workout_date,created_at,name,exercise_id,set,weight_kg,reps,duration_s,distance_km\n');
    String q(String v) => '"${v.replaceAll('"', '""')}"';
    for (final s in sessions) {
      for (final e in s.exercises) {
        for (var i = 0; i < e.sets.length; i++) {
          final x = e.sets[i];
          if (!x.done) continue;
          b.writeln('strength,${s.workoutDate.toIso8601String()},${s.meta.createdAt.toIso8601String()},${q(s.name)},${e.exerciseId},${i + 1},${x.weightKg},${x.reps},,');
        }
      }
    }
    for (final c in cardio) {
      b.writeln('cardio,${c.workoutDate.toIso8601String()},${c.meta.createdAt.toIso8601String()},${q(c.kind.label)},,,,,${c.durationSeconds},${c.distanceKm ?? ''}');
    }
    return b.toString();
  }
}
