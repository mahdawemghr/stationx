import 'package:flutter/material.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/active_workout/active_workout_page.dart';
import 'package:stationx/features/active_workout/workout_complete_page.dart';
import 'package:stationx/features/auth/login_page.dart';
import 'package:stationx/features/auth/register_page.dart';
import 'package:stationx/features/cardio/active_cardio_page.dart';
import 'package:stationx/features/cardio/backdate_cardio_page.dart';
import 'package:stationx/features/cardio/cardio_complete_page.dart';
import 'package:stationx/features/cardio/cardio_goal_details_page.dart';
import 'package:stationx/features/cardio/cardio_goals_page.dart';
import 'package:stationx/features/cardio/cardio_history_page.dart';
import 'package:stationx/features/cardio/cardio_prepare_page.dart';
import 'package:stationx/features/cardio/cardio_session_details_page.dart';
import 'package:stationx/features/cardio/cardio_settings_page.dart';
import 'package:stationx/features/cardio/create_custom_activity_page.dart';
import 'package:stationx/features/cardio/edit_cardio_session_page.dart';
import 'package:stationx/features/cardio/select_activity_page.dart';
import 'package:stationx/features/exercises/exercise_details_page.dart';
import 'package:stationx/features/exercises/exercise_history_page.dart';
import 'package:stationx/features/exercises/exercise_library_page.dart';
import 'package:stationx/features/history/calendar_page.dart';
import 'package:stationx/features/landing/landing_page.dart';
import 'package:stationx/features/profile/privacy_page.dart';
import 'package:stationx/features/progress/personal_records_page.dart';
import 'package:stationx/features/shell/main_shell.dart';
import 'package:stationx/features/workouts/workout_editor_page.dart';
import 'package:stationx/features/workouts/workout_preview_page.dart';

/// Every screen, built with demo data.
final screens = <String, Widget Function()>{
  'landing': () => const LandingPage(),
  'login': () => const LoginPage(),
  'register': () => const RegisterPage(),
  'today': () => const MainShell(),
  'workouts': () => const MainShell(initialIndex: 1),
  'progress': () => const MainShell(initialIndex: 2),
  'profile': () => const MainShell(initialIndex: 3),
  'workout_preview': () => const WorkoutPreviewPage(workoutId: 'w2'),
  'workout_editor': () => const WorkoutEditorPage(workoutId: 'w2'),
  'active_workout': () => const ActiveWorkoutPage(workoutId: 'w2'),
  'active_mixed': () => const ActiveWorkoutPage(workoutId: 'w1'),
  'workout_complete': () => const WorkoutCompletePage(sessionId: 'seed_s0'),
  'exercise_library': () => const ExerciseLibraryPage(),
  'exercise_details': () => const ExerciseDetailsPage(exerciseId: 'lat_pulldown'),
  'exercise_history': () => const ExerciseHistoryPage(exerciseId: 'lat_pulldown'),
  'personal_records': () => const PersonalRecordsPage(),
  'calendar': () => const CalendarPage(),
  'cardio_select': () => const SelectCardioActivityPage(),
  'cardio_prepare': () => const CardioPreparePage(kind: CardioKind.outdoorRun),
  'cardio_active': () => const ActiveCardioPage(kind: CardioKind.treadmill),
  'cardio_complete': () => const CardioCompletePage(sessionId: 'seed_c0'),
  'cardio_details': () => const CardioSessionDetailsPage(sessionId: 'seed_c0'),
  'cardio_edit': () => const EditCardioSessionPage(sessionId: 'seed_c0'),
  'cardio_backdate': () => const BackdateCardioPage(),
  'cardio_history': () => const CardioHistoryPage(),
  'cardio_goals': () => const CardioGoalsPage(),
  'cardio_goal_details': () => const CardioGoalDetailsPage(goalId: 'g_week'),
  'cardio_custom': () => const CreateCustomCardioActivityPage(),
  'cardio_settings': () => const CardioSettingsPage(),
  'privacy': () => const PrivacyPage(),
};

