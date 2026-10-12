import 'enums.dart';

class UserProfile {
  const UserProfile({
    this.name = 'Athlete',
    this.email = '',
    this.isGuest = true,
    this.weightKg = 74,
    this.heightCm = 175,
    this.age = 25,
    this.unit = WeightUnit.kg,
    this.themeMode = SxThemeMode.dark,
    this.defaultSets = 3,
    this.defaultRepMin = 8,
    this.defaultRepMax = 12,
    this.progressionEnabled = true,
    this.weeklySessionTarget = 4,
    this.cardioDistanceUnitKm = true,
    this.equipment,
    this.experienceLevel,
  });

  final String name;
  final String email;
  final bool isGuest;
  final double weightKg;
  final double heightCm;
  final int age;
  final WeightUnit unit;
  final SxThemeMode themeMode;
  final int defaultSets;
  final int defaultRepMin;
  final int defaultRepMax;
  final bool progressionEnabled;
  final int weeklySessionTarget;
  final bool cardioDistanceUnitKm;

  /// Equipment the user can train with; `null` = never chosen (nothing is filtered). Bodyweight is
  /// always available. Used only when a program is generated; saved programs are never changed by it.
  final Set<Equipment>? equipment;

  /// Experience level used ONLY when exercises are generated; null = never chosen (treated as
  /// intermediate, see [effectiveExperience]). Changing it never touches a saved program.
  final Difficulty? experienceLevel;

  Difficulty get effectiveExperience =>
      experienceLevel ?? Difficulty.intermediate;

  UserProfile copyWith({
    String? name,
    String? email,
    bool? isGuest,
    double? weightKg,
    double? heightCm,
    int? age,
    WeightUnit? unit,
    SxThemeMode? themeMode,
    int? defaultSets,
    int? defaultRepMin,
    int? defaultRepMax,
    bool? progressionEnabled,
    int? weeklySessionTarget,
    bool? cardioDistanceUnitKm,
    Set<Equipment>? equipment,
    bool clearEquipment = false,
    Difficulty? experienceLevel,
  }) => UserProfile(
    name: name ?? this.name,
    email: email ?? this.email,
    isGuest: isGuest ?? this.isGuest,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    age: age ?? this.age,
    unit: unit ?? this.unit,
    themeMode: themeMode ?? this.themeMode,
    defaultSets: defaultSets ?? this.defaultSets,
    defaultRepMin: defaultRepMin ?? this.defaultRepMin,
    defaultRepMax: defaultRepMax ?? this.defaultRepMax,
    progressionEnabled: progressionEnabled ?? this.progressionEnabled,
    weeklySessionTarget: weeklySessionTarget ?? this.weeklySessionTarget,
    cardioDistanceUnitKm: cardioDistanceUnitKm ?? this.cardioDistanceUnitKm,
    equipment: clearEquipment ? null : (equipment ?? this.equipment),
    experienceLevel: experienceLevel ?? this.experienceLevel,
  );
}
