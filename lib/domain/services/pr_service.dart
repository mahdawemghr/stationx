import '../models/models.dart';
import 'formulas.dart';

/// Strength + cardio personal records computed from history.
abstract final class PrService {
  /// Best value per [PrType] for [exerciseId], with the previous best.
  static Map<PrType, StrengthPr> forExercise(
    String exerciseId,
    List<WorkoutSession> sessions,
  ) {
    // Only sessions that logged this exercise matter; filtering first keeps the sort cheap
    // (the library screen calls this once per exercise over the whole history).
    final asc =
        sessions
            .where((s) => s.exercises.any((e) => e.exerciseId == exerciseId))
            .toList()
          ..sort((a, b) => a.workoutDate.compareTo(b.workoutDate));
    final best = <PrType, StrengthPr>{};
    for (final s in asc) {
      for (final log in s.exercises.where((e) => e.exerciseId == exerciseId)) {
        double sessionVolume = 0;
        SetLog? heaviest;
        for (final set in log.doneSets) {
          // Most reps counts for every set (bodyweight included); everything
          // that needs a load is skipped for zero-weight sets.
          _consider(
            best,
            PrType.mostReps,
            set.reps.toDouble(),
            exerciseId,
            set,
            s.workoutDate,
          );
          if (set.weightKg <= 0) continue;
          sessionVolume += set.volume;
          if (heaviest == null || set.weightKg > heaviest.weightKg) {
            heaviest = set;
          }
          _consider(
            best,
            PrType.heaviestWeight,
            set.weightKg,
            exerciseId,
            set,
            s.workoutDate,
          );
          // 0 (no reliable estimate, e.g. > 12 reps) is dropped by _consider.
          _consider(
            best,
            PrType.estimated1Rm,
            estimateOneRepMax(set.weightKg, set.reps),
            exerciseId,
            set,
            s.workoutDate,
          );
        }
        if (sessionVolume > 0 && heaviest != null) {
          _consider(
            best,
            PrType.highestVolume,
            sessionVolume,
            exerciseId,
            heaviest,
            s.workoutDate,
          );
        }
      }
    }
    return best;
  }

  static void _consider(
    Map<PrType, StrengthPr> best,
    PrType t,
    double v,
    String id,
    SetLog set,
    DateTime d,
  ) {
    if (!(v > 0)) return; // never produce a 0-valued (or NaN) record
    final cur = best[t];
    // Strictly greater: on a tie the earliest (sessions are walked oldest first) keeps the record.
    if (cur == null || v > cur.value) {
      best[t] = StrengthPr(
        exerciseId: id,
        type: t,
        weightKg: set.weightKg,
        reps: set.reps,
        value: v,
        date: d,
        previousValue: cur?.value,
      );
    }
  }

  /// All PRs of [type] across every logged exercise, newest first.
  static List<StrengthPr> all(PrType type, List<WorkoutSession> sessions) {
    final ids = {
      for (final s in sessions)
        for (final e in s.exercises) e.exerciseId,
    };
    final out = <StrengthPr>[];
    for (final id in ids) {
      final pr = forExercise(id, sessions)[type];
      if (pr != null) out.add(pr);
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  /// PRs that were *set* inside [from, to) (i.e. new records in that window).
  static List<StrengthPr> setBetween(
    List<WorkoutSession> sessions,
    DateTime from,
    DateTime to, {
    PrType type = PrType.estimated1Rm,
  }) {
    return all(
      type,
      sessions,
    ).where((p) => !p.date.isBefore(from) && p.date.isBefore(to)).toList();
  }

  /// Exercise ids that hit a new e1RM PR *in this session* (strictly better than
  /// everything logged before it).
  static Set<String> newPrExerciseIds(
    WorkoutSession session,
    List<WorkoutSession> history,
  ) {
    final prior = history
        .where(
          (h) =>
              h.id != session.id && !h.workoutDate.isAfter(session.workoutDate),
        )
        .toList();
    final out = <String>{};
    for (final log in session.exercises) {
      final before = forExercise(
        log.exerciseId,
        prior,
      )[PrType.estimated1Rm]?.value;
      final now = log.doneSets
          .map((s) => estimateOneRepMax(s.weightKg, s.reps))
          .fold(0.0, (a, b) => a > b ? a : b);
      if (before != null && now > before) out.add(log.exerciseId);
    }
    return out;
  }

  /// Cardio records. Duration is global; distance and pace are computed PER
  /// [CardioKind] (a bike ride must never beat a run). Output order: the
  /// duration record, then for each kind (enum order) its distance and pace.
  /// Ties keep the earliest session. Pace needs at least 1 km.
  static List<CardioPr> cardio(List<CardioSession> sessions) {
    if (sessions.isEmpty) return const [];
    final asc = [...sessions]
      ..sort((a, b) => a.workoutDate.compareTo(b.workoutDate));
    CardioSession? longestD;
    for (final s in asc) {
      if (s.durationSeconds > 0 &&
          (longestD == null || s.durationSeconds > longestD.durationSeconds)) {
        longestD = s;
      }
    }
    final out = <CardioPr>[
      if (longestD != null)
        CardioPr(
          type: CardioPrType.longestDuration,
          sessionId: longestD.id,
          value: longestD.durationSeconds.toDouble(),
          date: longestD.workoutDate,
          kindLabel: longestD.kind.label,
        ),
    ];
    for (final kind in CardioKind.values) {
      // A pace PR needs a meaningful distance in the kind's own convention
      // (1 km run, 500 m row, 100 m swim) — PRs stay per kind, value in sec/km.
      final minPaceKm = switch (kind.paceBasis) {
        CardioPaceBasis.per100m => 0.1,
        CardioPaceBasis.per500m => 0.5,
        _ => 1.0,
      };
      CardioSession? longestK, fastest;
      for (final s in asc.where((s) => s.kind == kind)) {
        final km = s.distanceKm ?? 0;
        if (km > 0 && (longestK == null || km > longestK.distanceKm!)) {
          longestK = s;
        }
        if (kind.hasPacePr &&
            km >= minPaceKm &&
            s.durationSeconds > 0 &&
            (fastest == null || s.paceSecPerKm! < fastest.paceSecPerKm!)) {
          fastest = s;
        }
      }
      if (longestK != null) {
        out.add(
          CardioPr(
            type: CardioPrType.longestDistance,
            sessionId: longestK.id,
            value: longestK.distanceKm!,
            date: longestK.workoutDate,
            kindLabel: kind.label,
          ),
        );
      }
      if (fastest != null) {
        out.add(
          CardioPr(
            type: CardioPrType.fastestPace,
            sessionId: fastest.id,
            value: fastest.paceSecPerKm!,
            date: fastest.workoutDate,
            kindLabel: kind.label,
          ),
        );
      }
    }
    return out;
  }
}
