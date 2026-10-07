import '../models/models.dart';

class SwapCandidate {
  const SwapCandidate({required this.exercise, required this.matchPercent, required this.reason});
  final Exercise exercise;

  /// 0–100, computed from muscle / movement-pattern / equipment similarity.
  final int matchPercent;
  final String reason;
}

/// Ranks catalog alternatives for an exercise whose equipment is unavailable.
/// Score = 55 primary-muscle match + 25 same movement pattern + up to 15
/// secondary-muscle overlap + 5 same equipment family. Computed, never static.
abstract final class SmartSwapService {
  static List<SwapCandidate> alternatives({
    required Exercise current,
    required List<Exercise> catalog,
    Set<Equipment>? allowedEquipment,
    Set<String> excludeIds = const {},
  }) {
    final out = <SwapCandidate>[];
    for (final e in catalog) {
      if (e.id == current.id || excludeIds.contains(e.id)) continue;
      if (allowedEquipment != null && !allowedEquipment.contains(e.equipment)) continue;
      if (e.primaryMuscle != current.primaryMuscle) continue;
      var score = 55;
      final samePattern = e.movementPattern.isNotEmpty && e.movementPattern == current.movementPattern;
      if (samePattern) score += 25;
      final cs = current.secondaryMuscles.toSet();
      if (cs.isNotEmpty) {
        score += (15 * e.secondaryMuscles.toSet().intersection(cs).length / cs.length).round();
      } else {
        score += 8;
      }
      if (e.equipment == current.equipment) score += 5;
      out.add(SwapCandidate(
        exercise: e,
        matchPercent: score.clamp(0, 100),
        reason: samePattern
            ? '${e.movementPattern} • same plane as ${current.name}'
            : '${e.primaryMuscle.label} focus • different movement',
      ));
    }
    out.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return out;
  }
}
