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

enum WeightUnit { kg, lb }

/// Interface theme (Profile › Interface Theme).
enum SxThemeMode { dark, oled, system }
