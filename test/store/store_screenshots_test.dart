import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/features/active_workout/active_workout_page.dart';
import 'package:stationx/features/exercises/exercise_details_page.dart';
import 'package:stationx/features/history/calendar_page.dart';
import 'package:stationx/features/shell/main_shell.dart';
import '../helpers/pump.dart';

/// Regenerates the Play Store phone screenshots (1080×2400, 9:20 — same ratio as the portfolio screenshots) into
/// docs/store/screenshots from the seeded demo data. Opt-in so normal test
/// runs don't touch the repo:
///   STORE_SHOTS=1 flutter test test/store
void main() {
  final enabled = Platform.environment['STORE_SHOTS'] == '1';
  const out = 'docs/store/screenshots';
  const size = Size(360, 800);

  setUpAll(loadAppFonts);

  Future<void> capture(WidgetTester t, Widget page, String name) async {
    await pumpPage(t, page, size: size);
    await t.pump(const Duration(milliseconds: 600));
    await shot(t, name, pixelRatio: 3, dir: out);
  }

  testWidgets('01 today', (t) => capture(t, const MainShell(), '01_today'), skip: !enabled);
  testWidgets('02 workouts', (t) => capture(t, const MainShell(initialIndex: 1), '02_workouts'), skip: !enabled);
  testWidgets('03 active workout', (t) => capture(t, const ActiveWorkoutPage(workoutId: 'w2'), '03_active_workout'), skip: !enabled);
  testWidgets('04 exercise', (t) => capture(t, const ExerciseDetailsPage(exerciseId: 'lat_pulldown'), '04_exercise_details'), skip: !enabled);
  testWidgets('05 progress', (t) => capture(t, const MainShell(initialIndex: 2), '05_progress'), skip: !enabled);
  testWidgets('06 calendar', (t) => capture(t, const CalendarPage(), '06_calendar'), skip: !enabled);
}
