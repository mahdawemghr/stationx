import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/history/calendar_page.dart';
import 'package:stationx/features/exercises/exercise_history_page.dart';
import 'package:stationx/features/history/edit_session_page.dart';
import 'package:stationx/features/workouts/workout_preview_page.dart';

import '../../helpers/pump.dart';

Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
  await t.pump(const Duration(milliseconds: 400));
}

const _push = SplitDayPlan(name: 'Push Day', muscles: [MuscleGroup.chest], exercises: [RoutineExercise(exerciseId: 'bench_press')]);
const _pull = SplitDayPlan(name: 'Pull Day', muscles: [MuscleGroup.back], exercises: [RoutineExercise(exerciseId: 'pullup')]);

Future<AppController> seeded() async {
  final app = AppController();
  await ScheduleBuilder.save([_push, _pull], workouts: app.workouts, sessions: app.sessions, catalog: app.exercises.all, stamp: 't');
  await app.sessions.add(WorkoutSession(
    id: 's1',
    workoutId: 'w_t_0',
    name: 'Push Day',
    workoutDate: DateTime.now().subtract(const Duration(days: 1)),
    exercises: const [ExerciseLog(exerciseId: 'bench_press', sets: [SetLog(weightKg: 60, reps: 8), SetLog(weightKg: 60, reps: 8)])],
  ));
  return app;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('workout page lists history; delete asks first and keeps the rotation', (t) async {
    final app = await seeded();
    final rotBefore = app.workouts.rotation.currentIndex;
    await pumpPage(t, const WorkoutPreviewPage(workoutId: 'w_t_0'), demo: false, controller: app, size: const Size(390, 1400));
    await settle(t);
    expect(find.byKey(const ValueKey('history_s1')), findsOneWidget);

    await t.tap(find.byTooltip(RegExp('^Delete .* session')));
    await settle(t);
    await t.tap(find.text('CANCEL'));
    await settle(t);
    expect(app.sessions.byId('s1'), isNotNull);

    await t.tap(find.byTooltip(RegExp('^Delete .* session')));
    await settle(t);
    await t.tap(find.text('DELETE WORKOUT'));
    await settle(t);
    expect(app.sessions.byId('s1'), isNull);
    expect(app.workouts.rotation.currentIndex, rotBefore);
    expect(find.text('No history yet'), findsOneWidget);
  });

  testWidgets('edit: add a set, remove a set, save keeps id and createdAt', (t) async {
    final app = await seeded();
    final created = app.sessions.byId('s1')!.meta.createdAt;
    await pumpPage(t, const EditSessionPage(sessionId: 's1'), demo: false, controller: app, size: const Size(390, 1400));
    await settle(t);
    await t.tap(find.text('ADD SET'));
    await settle(t);
    await t.tap(find.text('ADD SET'));
    await settle(t);
    await t.tap(find.byTooltip('Remove set 1'));
    await settle(t);
    await t.tap(find.text('SAVE CHANGES'));
    await settle(t);
    final s = app.sessions.byId('s1')!;
    expect(s.exercises.single.sets.length, 3);
    expect(s.meta.createdAt, created);
    expect(app.sessions.sessions.length, 1);
  });

  testWidgets('insert picker lists the schedule in rotation order', (t) async {
    final app = await seeded();
    await pumpPage(t, const CalendarPage(), demo: false, controller: app, size: const Size(390, 1600));
    await settle(t);
    final btn = find.text('INSERT WORKOUT').last;
    await t.ensureVisible(btn);
    await t.pump();
    await t.tap(btn);
    await settle(t);
    expect(find.text('INSERT WORKOUT'), findsWidgets);
    expect(find.textContaining('Which workout from your schedule'), findsOneWidget);
    final push = t.getTopLeft(find.text('Push Day').last).dy;
    final pull = t.getTopLeft(find.text('Pull Day').last).dy;
    expect(push < pull, isTrue);
    expect(find.textContaining('Day 1 ·'), findsOneWidget);
  });

  testWidgets('exercise history rows have edit and delete', (t) async {
    final app = await seeded();
    await pumpPage(t, const ExerciseHistoryPage(exerciseId: 'bench_press'), demo: false, controller: app, size: const Size(320, 1600), textScale: 1.3);
    await settle(t);
    final edit = find.text('EDIT');
    await t.scrollUntilVisible(edit, 200, scrollable: find.byType(Scrollable).first);
    expect(edit, findsOneWidget);
    expect(find.byTooltip(RegExp('^Delete .* workout')), findsOneWidget);
    await t.tap(edit);
    await settle(t);
    expect(find.byType(EditSessionPage), findsOneWidget);
  });
}
