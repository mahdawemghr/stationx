import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/features/active_workout/active_workout_controller.dart';
import 'package:stationx/features/active_workout/active_workout_page.dart';
import 'package:stationx/features/today/today_page.dart';

import '../../helpers/pump.dart';

Future<AppController> withDraft() async {
  final app = AppController();
  await app.startDemo();
  final c = ActiveWorkoutController(
    workout: app.workouts.byId('w2')!,
    catalog: app.exercises.all,
    sessions: app.sessions,
    profile: app.profile.profile,
    draftStore: app.workoutDraft,
  );
  c.toggleSet(c.drafts[0], 0);
  c.toggleSet(c.drafts[0], 1);
  await c.flushDraft();
  c.dispose();
  return app;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('no draft: no Resume card', (t) async {
    await pumpPage(t, const TodayPage());
    expect(find.text('Resume workout'), findsNothing);
  });

  testWidgets('shows the workout name and sets done; Resume reopens the logger restored', (t) async {
    final app = await withDraft();
    await pumpPage(t, const TodayPage(), controller: app);
    expect(find.text('Resume workout'), findsOneWidget);
    final name = app.workouts.byId('w2')!.name;
    expect(find.textContaining('$name · 2 of 18 sets done'), findsOneWidget);
    await t.tap(find.text('RESUME'));
    await t.pumpAndSettle();
    expect(find.byType(ActiveWorkoutPage), findsOneWidget);
    expect(find.text('16 OF 18 SETS REMAINING'), findsOneWidget);
  });

  testWidgets('Discard asks first, then removes the card and the draft', (t) async {
    final app = await withDraft();
    await pumpPage(t, const TodayPage(), controller: app);
    await t.tap(find.text('DISCARD'));
    await t.pumpAndSettle();
    expect(find.text('DISCARD WORKOUT?'), findsOneWidget);
    await t.tap(find.text('KEEP IT'));
    await t.pumpAndSettle();
    expect(app.workoutDraft.current, isNotNull);
    await t.tap(find.text('DISCARD'));
    await t.pumpAndSettle();
    await t.tap(find.descendant(of: find.byType(Dialog), matching: find.text('DISCARD')));
    await t.pumpAndSettle();
    expect(app.workoutDraft.current, isNull);
    expect(find.text('Resume workout'), findsNothing);
  });

  testWidgets('a draft whose workout was deleted still resumes (from its snapshot)', (t) async {
    final app = await withDraft();
    await app.workouts.deleteWorkout('w2');
    await pumpPage(t, const TodayPage(), controller: app);
    expect(find.text('Resume workout'), findsOneWidget);
    await t.tap(find.text('RESUME'));
    await t.pumpAndSettle();
    expect(find.byType(ActiveWorkoutPage), findsOneWidget);
    expect(find.text('16 OF 18 SETS REMAINING'), findsOneWidget);
    expect(find.text('This workout no longer exists.'), findsNothing);
  });
}

