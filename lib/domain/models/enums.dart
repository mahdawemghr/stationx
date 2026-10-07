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
  bodyweight('Bodyweight');

  const Equipment(this.label);
  final String label;
}

enum WeightUnit { kg, lb }

/// Interface theme (Profile › Interface Theme).
enum SxThemeMode { dark, oled, system }
