/// Sync state for future cloud sync. Local-only today (always [pending]).
enum SyncStatus { pending, synced, failed }

enum MuscleGroup {
  chest('Chest'),
  back('Back'),
  shoulders('Shoulders'),
  biceps('Biceps'),
  triceps('Triceps'),
  legs('Legs'),
  core('Core');

  const MuscleGroup(this.label);
  final String label;
}

enum Equipment {
  cable('Cable'),
  dumbbell('Dumbbell'),
  barbell('Barbell'),
  machine('Machine'),
  bodyweight('Bodyweight'),
  // Appended (stored by name; server CHECK widened by migration 20261012010000_equipment_values.sql).
  kettlebell('Kettlebell'),
  band('Band'),
  smithMachine('Smith machine'),
  other('Other');

  const Equipment(this.label);
  final String label;

  /// No external load to log (bodyweight, resistance bands): no kg prompt, no load progression.
  bool get isUnloaded => this == bodyweight || this == band;
}

/// How demanding an exercise is, and also the user's experience level (same three steps):
/// beginner, intermediate, advanced. An exercise without a level (custom) has `null`.
enum Difficulty {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  const Difficulty(this.label);
  final String label;

  /// Parses a stored name; unknown or missing -> null.
  static Difficulty? tryParse(Object? v) {
    for (final d in values) {
      if (d.name == v) return d;
    }
    return null;
  }
}

enum WeightUnit { kg, lb }

/// Interface theme (Profile › Interface Theme).
enum SxThemeMode { dark, oled, system }
