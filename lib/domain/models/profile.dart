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
    this.autoRestSeconds = 90,
    this.progressionEnabled = true,
    this.weeklySessionTarget = 4,
    this.cardioDistanceUnitKm = true,
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
  final int autoRestSeconds;
  final bool progressionEnabled;
  final int weeklySessionTarget;
  final bool cardioDistanceUnitKm;

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
    int? autoRestSeconds,
    bool? progressionEnabled,
    int? weeklySessionTarget,
    bool? cardioDistanceUnitKm,
  }) =>
      UserProfile(
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
        autoRestSeconds: autoRestSeconds ?? this.autoRestSeconds,
        progressionEnabled: progressionEnabled ?? this.progressionEnabled,
        weeklySessionTarget: weeklySessionTarget ?? this.weeklySessionTarget,
        cardioDistanceUnitKm: cardioDistanceUnitKm ?? this.cardioDistanceUnitKm,
      );
}
