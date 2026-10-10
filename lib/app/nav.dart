import 'package:flutter/material.dart';

import '../domain/domain.dart';
import '../features/active_workout/active_workout_page.dart';
import '../features/active_workout/workout_complete_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/cardio/active_cardio_page.dart';
import '../features/cardio/backdate_cardio_page.dart';
import '../features/cardio/cardio_complete_page.dart';
import '../features/cardio/cardio_goal_details_page.dart';
import '../features/cardio/cardio_goals_page.dart';
import '../features/cardio/cardio_history_page.dart';
import '../features/cardio/cardio_prepare_page.dart';
import '../features/cardio/cardio_session_details_page.dart';
import '../features/cardio/cardio_settings_page.dart';
import '../features/cardio/create_custom_activity_page.dart';
import '../features/cardio/edit_cardio_session_page.dart';
import '../features/cardio/select_activity_page.dart';
import '../features/exercises/exercise_details_page.dart';
import '../features/exercises/exercise_history_page.dart';
import '../features/exercises/exercise_library_page.dart';
import '../features/health/health_import_page.dart';
import '../features/health/health_sync_settings_page.dart';
import '../features/history/calendar_page.dart';
import '../features/history/edit_session_page.dart';
import '../features/onboarding/schedule_setup_flow.dart';
import '../features/progress/personal_records_page.dart';
import '../features/shell/main_shell.dart';
import '../features/workouts/workout_editor_page.dart';
import '../features/workouts/workout_preview_page.dart';

/// Central navigation API. Features call these helpers instead of building
/// routes ad hoc, so every screen's constructor contract lives in one place.
/// All routes push on the root navigator (bottom nav hidden on pushed screens).
abstract final class AppNav {
  static Future<T?> _push<T>(BuildContext c, Widget page) =>
      Navigator.of(c).push<T>(MaterialPageRoute<T>(builder: (_) => page));

  static Future<T?> _replace<T>(BuildContext c, Widget page) =>
      Navigator.of(c).pushReplacement<T, Object?>(MaterialPageRoute<T>(builder: (_) => page));

  // ── entry ──
  static void login(BuildContext c) => _push(c, const LoginPage());
  static void register(BuildContext c) => _push(c, const RegisterPage());

  /// Replace everything with the 4-tab shell (after sign-in / guest).
  static void enterApp(BuildContext c) => Navigator.of(c).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainShell()), (_) => false);

  /// Schedule setup. [afterSignup] replaces the whole stack (skip/finish then enters the app).
  static Future<void> scheduleSetup(BuildContext c, {bool afterSignup = false}) {
    if (!afterSignup) return _push(c, const ScheduleSetupFlow());
    return Navigator.of(c).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const ScheduleSetupFlow(afterSignup: true)), (_) => false);
  }

  // ── tabs ──
  static void switchTab(BuildContext c, int index) => MainShell.switchTab(c, index);

  // ── workouts ──
  static Future<void> healthSyncSettings(BuildContext c) => _push(c, const HealthSyncSettingsPage());
  static Future<void> healthImport(BuildContext c) => _push(c, const HealthImportPage());
  static Future<void> workoutPreview(BuildContext c, String workoutId) => _push(c, WorkoutPreviewPage(workoutId: workoutId));
  static Future<void> workoutEditor(BuildContext c, String workoutId) => _push(c, WorkoutEditorPage(workoutId: workoutId));

  /// Start (or backdate, when [backdate] is set) a workout.
  static Future<void> activeWorkout(BuildContext c, String workoutId, {DateTime? backdate}) =>
      _push(c, ActiveWorkoutPage(workoutId: workoutId, backdate: backdate));

  /// Replaces the active workout screen with the completion screen.
  static Future<void> workoutComplete(BuildContext c, String sessionId) => _replace(c, WorkoutCompletePage(sessionId: sessionId));
  static Future<void> viewWorkoutSession(BuildContext c, String sessionId) => _push(c, WorkoutCompletePage(sessionId: sessionId));
  static Future<void> editWorkoutSession(BuildContext c, String sessionId) => _push(c, EditSessionPage(sessionId: sessionId));

  // ── exercises ──
  static Future<Exercise?> exercisePicker(BuildContext c) => _push<Exercise>(c, const ExerciseLibraryPage(pickMode: true));
  static Future<void> exerciseLibrary(BuildContext c) => _push(c, const ExerciseLibraryPage());
  static Future<void> exerciseDetails(BuildContext c, String exerciseId) => _push(c, ExerciseDetailsPage(exerciseId: exerciseId));
  static Future<void> exerciseHistory(BuildContext c, String exerciseId) => _push(c, ExerciseHistoryPage(exerciseId: exerciseId));
  static Future<void> personalRecords(BuildContext c) => _push(c, const PersonalRecordsPage());

  // ── history ──
  static Future<void> calendar(BuildContext c) => _push(c, const CalendarPage());

  // ── cardio ──
  static Future<void> selectCardioActivity(BuildContext c) => _push(c, const SelectCardioActivityPage());
  static Future<void> cardioPrepare(BuildContext c, CardioKind kind, {String? customActivityId}) =>
      _push(c, CardioPreparePage(kind: kind, customActivityId: customActivityId));
  static Future<void> activeCardio(BuildContext c, CardioKind kind, {int? targetMinutes, double? targetKm, String? customActivityId, bool replace = false}) {
    final p = ActiveCardioPage(kind: kind, targetMinutes: targetMinutes, targetKm: targetKm, customActivityId: customActivityId);
    return replace ? _replace(c, p) : _push(c, p);
  }
  static Future<void> cardioComplete(BuildContext c, String sessionId) => _replace(c, CardioCompletePage(sessionId: sessionId));
  static Future<void> cardioDetails(BuildContext c, String sessionId) => _push(c, CardioSessionDetailsPage(sessionId: sessionId));
  static Future<void> editCardio(BuildContext c, String sessionId) => _push(c, EditCardioSessionPage(sessionId: sessionId));
  static Future<void> backdateCardio(BuildContext c, {CardioKind? kind, DateTime? date}) => _push(c, BackdateCardioPage(kind: kind, date: date));
  static Future<void> cardioHistory(BuildContext c) => _push(c, const CardioHistoryPage());
  static Future<void> cardioGoals(BuildContext c) => _push(c, const CardioGoalsPage());
  static Future<void> cardioGoalDetails(BuildContext c, String goalId) => _push(c, CardioGoalDetailsPage(goalId: goalId));
  static Future<void> createCustomCardio(BuildContext c, {String? initialName}) =>
      _push(c, CreateCustomCardioActivityPage(initialName: initialName));
  static Future<void> cardioSettings(BuildContext c) => _push(c, const CardioSettingsPage());
}
