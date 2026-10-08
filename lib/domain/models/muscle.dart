import 'dart:convert';

import 'enums.dart';

/// Detailed training regions. [legacy] is the broad 7-way [MuscleGroup] that storage, sync and the
/// simplified UI already use (it never changes), so the detailed layer needs no schema change.
enum MuscleRegion {
  chest('Chest', MuscleGroup.chest),
  back('Back', MuscleGroup.back),
  shoulders('Shoulders', MuscleGroup.shoulders),
  biceps('Biceps', MuscleGroup.biceps),
  triceps('Triceps', MuscleGroup.triceps),
  forearms('Forearms', MuscleGroup.biceps),
  quadriceps('Quadriceps', MuscleGroup.legs),
  hamstrings('Hamstrings', MuscleGroup.legs),
  glutes('Glutes', MuscleGroup.legs),
  calves('Calves', MuscleGroup.legs),
  core('Core', MuscleGroup.core);

  const MuscleRegion(this.label, this.legacy);
  final String label;
  final MuscleGroup legacy;

  List<Muscle> get muscles => [for (final m in Muscle.values) if (m.region == this) m];
}

/// Practical gym subdivisions (not an anatomy standard). Each belongs to one [MuscleRegion].
enum Muscle {
  upperChest('Upper chest', MuscleRegion.chest),
  midChest('Mid chest', MuscleRegion.chest),
  lowerChest('Lower chest', MuscleRegion.chest),

  lats('Lats', MuscleRegion.back),
  upperBack('Upper back', MuscleRegion.back),
  traps('Traps', MuscleRegion.back),
  lowerBack('Lower back', MuscleRegion.back),

  frontDelts('Front delts', MuscleRegion.shoulders),
  sideDelts('Side delts', MuscleRegion.shoulders),
  rearDelts('Rear delts', MuscleRegion.shoulders),

  bicepsLongHead('Biceps long head', MuscleRegion.biceps),
  bicepsShortHead('Biceps short head', MuscleRegion.biceps),
  brachialis('Brachialis', MuscleRegion.biceps),

  tricepsLongHead('Triceps long head', MuscleRegion.triceps),
  tricepsLateralHead('Triceps lateral head', MuscleRegion.triceps),
  tricepsMedialHead('Triceps medial head', MuscleRegion.triceps),

  wristFlexors('Wrist flexors', MuscleRegion.forearms),
  wristExtensors('Wrist extensors', MuscleRegion.forearms),
  brachioradialis('Brachioradialis / grip', MuscleRegion.forearms),

  rectusFemoris('Rectus femoris', MuscleRegion.quadriceps),
  vastusLateralis('Vastus lateralis', MuscleRegion.quadriceps),
  vastusMedialis('Vastus medialis', MuscleRegion.quadriceps),
  vastusIntermedius('Vastus intermedius', MuscleRegion.quadriceps),

  bicepsFemoris('Biceps femoris', MuscleRegion.hamstrings),
  semitendinosus('Semitendinosus', MuscleRegion.hamstrings),
  semimembranosus('Semimembranosus', MuscleRegion.hamstrings),

  gluteusMaximus('Gluteus maximus', MuscleRegion.glutes),
  gluteusMedius('Gluteus medius', MuscleRegion.glutes),
  gluteusMinimus('Gluteus minimus', MuscleRegion.glutes),

  gastrocnemius('Gastrocnemius', MuscleRegion.calves),
  soleus('Soleus', MuscleRegion.calves),

  rectusAbdominis('Abs', MuscleRegion.core),
  obliques('Obliques', MuscleRegion.core),
  transverseAbdominis('Deep core', MuscleRegion.core);

  const Muscle(this.label, this.region);
  final String label;
  final MuscleRegion region;
}

enum TargetRole { primary, secondary }

/// One thing an exercise trains. [muscle] == null means "the region as a whole" — used when a subdivision
/// can't be assigned reliably (no fake precision). [weight] overrides the default role weight when set.
class MuscleTarget {
  const MuscleTarget(this.region, {this.muscle, this.role = TargetRole.secondary, this.weight, this.emphasis});
  const MuscleTarget.primary(MuscleRegion region, {Muscle? muscle, String? emphasis})
      : this(region, muscle: muscle, role: TargetRole.primary, emphasis: emphasis);
  const MuscleTarget.secondary(MuscleRegion region, {Muscle? muscle, double? weight})
      : this(region, muscle: muscle, role: TargetRole.secondary, weight: weight);

  final MuscleRegion region;
  final Muscle? muscle;
  final TargetRole role;
  final double? weight;

  /// Optional human note, e.g. "stretch under load" — descriptive only, never used in maths.
  final String? emphasis;

  /// Contribution of ONE set to this target (primary counts fully, secondary less).
  double get effectiveWeight => weight ?? (role == TargetRole.primary ? MuscleWeights.primary : MuscleWeights.secondary);
}

/// The single place the contribution model lives.
abstract final class MuscleWeights {
  static const double primary = 1.0;
  static const double secondary = 0.5;
}

/// Structured muscle metadata of one exercise: any number of targets, ≥1 primary.
class ExerciseMuscleProfile {
  const ExerciseMuscleProfile(this.targets);
  final List<MuscleTarget> targets;

  Iterable<MuscleTarget> get primary => targets.where((t) => t.role == TargetRole.primary);
  Iterable<MuscleTarget> get secondary => targets.where((t) => t.role == TargetRole.secondary);
  MuscleTarget get lead => primary.isNotEmpty ? primary.first : targets.first;
  MuscleRegion get primaryRegion => lead.region;
}

/// JSON codec for persisting [MuscleTarget] lists (Isar string field, Supabase jsonb column). Pure Dart.
/// Tolerant: unknown/invalid entries are dropped; a list without any primary target is treated as absent (null).
abstract final class MuscleTargetCodec {
  static const int maxTargets = 12;
  static const int maxEmphasisLength = 60;

  /// Plain JSON-able list (for jsonb). Empty list -> null.
  static List<Map<String, Object?>>? toJson(List<MuscleTarget>? targets) {
    final clean = normalize(targets);
    if (clean == null) return null;
    return [
      for (final t in clean)
        {
          'region': t.region.name,
          if (t.muscle != null) 'muscle': t.muscle!.name,
          'role': t.role.name,
          if (t.emphasis != null) 'emphasis': t.emphasis,
          if (_validWeight(t.weight) != null) 'weight': _validWeight(t.weight),
        },
    ];
  }

  /// Tolerant decode of a decoded-JSON list (or anything). Null when absent/invalid/no primary.
  static List<MuscleTarget>? fromJson(Object? raw) {
    if (raw is! List) return null;
    final out = <MuscleTarget>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final region = _byName(MuscleRegion.values, e['region']);
      if (region == null) continue;
      Muscle? muscle;
      if (e['muscle'] != null) {
        muscle = _byName(Muscle.values, e['muscle']);
        if (muscle == null || muscle.region != region) continue; // invalid leaf: drop the entry
      }
      final role = _byName(TargetRole.values, e['role']);
      if (role == null) continue;
      final w = e['weight'];
      final weight = _validWeight(w);
      final em = e['emphasis'];
      final emphasis = em is String && em.trim().isNotEmpty ? _clip(em.trim()) : null;
      out.add(MuscleTarget(region, muscle: muscle, role: role, weight: weight, emphasis: emphasis));
    }
    return normalize(out);
  }

  /// String form for storage; null when [targets] is null/invalid.
  static String? encode(List<MuscleTarget>? targets) {
    final j = toJson(targets);
    return j == null ? null : jsonEncode(j);
  }

  static List<MuscleTarget>? decode(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return fromJson(jsonDecode(s));
    } catch (_) {
      return null;
    }
  }

  /// Dedupes (same region+leaf; first wins), caps, requires >=1 primary and primaries first is NOT
  /// enforced (order is preserved). Returns null when empty or without a primary.
  static List<MuscleTarget>? normalize(List<MuscleTarget>? targets) {
    if (targets == null || targets.isEmpty) return null;
    final seen = <String>{};
    final out = <MuscleTarget>[];
    for (final t in targets) {
      if (t.muscle != null && t.muscle!.region != t.region) continue;
      if (!seen.add('${t.region.name}/${t.muscle?.name ?? ''}')) continue;
      out.add(t);
      if (out.length >= maxTargets) break;
    }
    if (!out.any((t) => t.role == TargetRole.primary)) return null;
    return out;
  }

  /// A custom weight must be in (0, 1.0] for both roles (1.0 = a full set; nothing counts more than one
  /// set). Anything else (0, negative, NaN, > 1) is dropped so the role default applies.
  static double? _validWeight(Object? w) =>
      (w is num && w.isFinite && w > 0 && w <= MuscleWeights.primary) ? w.toDouble() : null;

  static String _clip(String s) => s.length <= maxEmphasisLength ? s : s.substring(0, maxEmphasisLength);

  static T? _byName<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
