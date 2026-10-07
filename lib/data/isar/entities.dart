import 'package:isar_community/isar.dart';

import '../../domain/domain.dart';

part 'entities.g.dart';

// Isar storage entities. These mirror the domain models 1:1 (see mappers.dart)
// so the rest of the app never imports Isar. Keep every `meta` field
// (createdAt / updatedAt / syncStatus) — the future sync layer depends on them.
//
// Schema evolution: Isar 3 handles additive changes (new nullable/defaulted
// fields, new collections). Renaming or retyping a field needs a migration;
// bump AppMetaEntity.schemaVersion and handle it in IsarBootstrap.

@embedded
class MetaEmb {
  DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime updatedAt = DateTime.fromMillisecondsSinceEpoch(0);
  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;
}

@embedded
class StepEmb {
  String title = '';
  String text = '';
}

@embedded
class RoutineExerciseEmb {
  String exerciseId = '';
  int sets = 3;
  int repMin = 8;
  int repMax = 12;
}

@embedded
class CardioTargetEmb {
  @Enumerated(EnumType.name)
  CardioKind kind = CardioKind.outdoorRun;
  int? durationMinutes;
  double? distanceKm;
  double? speedKmh;
  double? inclinePct;
  int? resistance;
}

@embedded
class SetLogEmb {
  double weightKg = 0;
  int reps = 0;
  bool done = true;
  double? rpe;
}

@embedded
class ExerciseLogEmb {
  String exerciseId = '';
  List<SetLogEmb> sets = [];
}

@embedded
class CardioSessionEmb {
  String uid = '';
  @Enumerated(EnumType.name)
  CardioKind kind = CardioKind.outdoorRun;
  DateTime workoutDate = DateTime.fromMillisecondsSinceEpoch(0);
  int durationSeconds = 0;
  double? distanceKm;
  double? speedKmh;
  double? inclinePct;
  int? resistance;
  int? calories;
  int? avgHeartRate;
  double? rpe;
  String routeName = '';
  String notes = '';
  String? customActivityId;
  MetaEmb meta = MetaEmb();
}

@collection
class ExerciseEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String uid = '';
  String name = '';
  @Enumerated(EnumType.name)
  MuscleGroup primaryMuscle = MuscleGroup.chest;
  @Enumerated(EnumType.name)
  List<MuscleGroup> secondaryMuscles = [];
  @Enumerated(EnumType.name)
  Equipment equipment = Equipment.barbell;
  String movementPattern = '';
  List<StepEmb> instructions = [];
  bool isCustom = false;
  String? tempo;
  MetaEmb meta = MetaEmb();
}

@collection
class WorkoutEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String uid = '';

  /// Display order (index in the repository list).
  int position = 0;
  String name = '';
  String description = '';
  List<RoutineExerciseEmb> exercises = [];
  int restSeconds = 90;
  CardioTargetEmb? cardioFinisher;
  MetaEmb meta = MetaEmb();
}

/// Singleton (id = 1).
@collection
class RotationEntity {
  Id id = 1;
  List<String> workoutIds = [];
  int currentIndex = 0;
}

@collection
class SessionEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String uid = '';
  String workoutId = '';
  String name = '';

  /// When the user trained (backdatable). Never overwritten by "now".
  @Index()
  DateTime workoutDate = DateTime.fromMillisecondsSinceEpoch(0);
  List<ExerciseLogEmb> exercises = [];
  int durationSeconds = 0;
  CardioSessionEmb? cardio;
  String notes = '';

  /// meta.createdAt = when the record was entered.
  MetaEmb meta = MetaEmb();
}

@collection
class CardioSessionEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String uid = '';
  @Index()
  DateTime workoutDate = DateTime.fromMillisecondsSinceEpoch(0);
  CardioSessionEmb data = CardioSessionEmb();
}

@collection
class CardioGoalEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String uid = '';
  String title = '';
  @Enumerated(EnumType.name)
  GoalMetric metric = GoalMetric.durationMinutes;
  double target = 0;
  @Enumerated(EnumType.name)
  GoalPeriod period = GoalPeriod.week;
  bool isPrimary = false;
  MetaEmb meta = MetaEmb();
}

@collection
class CustomActivityEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String uid = '';
  String name = '';
  String category = 'Custom';
  String iconKey = 'fitness_center';
  @Enumerated(EnumType.name)
  List<CardioField> fields = [];
  int? roundSeconds;
  int? restSeconds;
  int? rounds;
  MetaEmb meta = MetaEmb();
}

/// Singleton (id = 1). Holds the single local profile + settings.
/// No password / credential is ever stored here.
@collection
class ProfileEntity {
  Id id = 1;
  String name = 'Athlete';
  String email = '';
  bool isGuest = true;
  double weightKg = 74;
  double heightCm = 175;
  int age = 25;
  @Enumerated(EnumType.name)
  WeightUnit unit = WeightUnit.kg;
  @Enumerated(EnumType.name)
  SxThemeMode themeMode = SxThemeMode.dark;
  int defaultSets = 3;
  int defaultRepMin = 8;
  int defaultRepMax = 12;
  int autoRestSeconds = 90;
  bool progressionEnabled = true;
  int weeklySessionTarget = 4;
  bool cardioDistanceUnitKm = true;
}

/// Singleton (id = 1): app-level flags that are not user data.
@collection
class AppMetaEntity {
  Id id = 1;
  bool signedIn = false;
  int schemaVersion = 1;

  /// User opted in to the platform health store (needed on iOS, where the OS
  /// cannot report read access). Additive field: existing databases default to false.
  bool healthConnected = false;
}
