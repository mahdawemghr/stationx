
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/active_workout/active_workout_controller.dart';
import 'package:stationx/features/active_workout/active_workout_page.dart';
import 'package:stationx/features/active_workout/workout_complete_page.dart';

import '../../helpers/pump.dart';

/// Pumps a launcher screen with a button that pushes [page], so back-navigation
/// (and PopScope) behave as in the app.
Future<AppController> pumpPushed(WidgetTester t, Widget page,
    {Size size = const Size(390, 844), double textScale = 1, AppController? controller}) async {
  final app = await pumpPage(
    t,
    Builder(
      builder: (c) => Scaffold(
        body: Center(
          child: TextButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page)), child: const Text('launch')),
        ),
      ),
    ),
    size: size,
    textScale: textScale,
    controller: controller,
  );
  await t.tap(find.text('launch'));
  await t.pumpAndSettle();
  return app;
}

/// Like [pumpPushed] but lets the test seed data before the page is pushed.
Future<AppController> pumpLaunched(
  WidgetTester t,
  Widget Function() page, {
  required Future<void> Function(AppController app) prep,
  Size size = const Size(390, 844),
}) async {
  final app = await pumpPage(
    t,
    Builder(
      builder: (c) => Scaffold(
        body: Center(
          child: TextButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page())), child: const Text('launch')),
        ),
      ),
    ),
    size: size,
  );
  await prep(app);
  await t.tap(find.text('launch'));
  await t.pumpAndSettle();
  return app;
}

Future<void> tapDone(WidgetTester t, int setNumber) async {
  await t.tap(find.bySemanticsLabel('Set $setNumber done').first);
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('logging a set updates progress, volume and starts the rest timer', (t) async {
    final h = t.ensureSemantics();
    await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'));
    expect(find.text('18 OF 18 SETS REMAINING'), findsOneWidget);
    expect(find.text('--:--'), findsOneWidget);
    await tapDone(t, 1);
    expect(find.text('17 OF 18 SETS REMAINING'), findsOneWidget);
    expect(find.text('SKIP'), findsOneWidget);
    expect(find.text('+30S'), findsNothing); // label is "+30s"
    expect(find.text('+30s'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 300)); // rest tile grows to show its 48dp actions
    await t.tap(find.text('SKIP'));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('SKIP'), findsNothing);
    h.dispose();
  });

  testWidgets('editing weight via the keypad', (t) async {
    await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'));
    await t.ensureVisible(find.text('47.5').first);
    await t.pump();
    await t.tap(find.text('47.5').first);
    await t.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    await t.tap(find.descendant(of: sheet, matching: find.text('6')));
    await t.tap(find.descendant(of: sheet, matching: find.text('0')));
    await t.pump();
    await t.tap(find.text('CONFIRM'));
    await t.pumpAndSettle();
    expect(find.text('60'), findsWidgets);
  });

  testWidgets('add set and swipe-remove a set', (t) async {
    await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'));
    await t.ensureVisible(find.text('Add Set'));
    await t.pump();
    await t.tap(find.text('Add Set'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('04'));
    await t.pump();
    expect(find.text('04'), findsOneWidget);
    expect(find.text('19 OF 19 SETS REMAINING'), findsOneWidget);
    await t.drag(find.text('04'), const Offset(-400, 0));
    await t.pumpAndSettle();
    expect(find.text('04'), findsNothing);
    expect(find.text('18 OF 18 SETS REMAINING'), findsOneWidget);
  });

  testWidgets('finish saves with workoutDate=now, separate createdAt, advances rotation once', (t) async {
    final h = t.ensureSemantics();
    final app = await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'));
    final idxBefore = app.workouts.rotation.currentIndex;
    final countBefore = app.sessions.sessions.length;
    final before = DateTime.now();
    await tapDone(t, 1);
    await t.tap(find.text('FINISH WORKOUT'));
    await t.pumpAndSettle();
    expect(find.text('FINISH WORKOUT?'), findsOneWidget); // unfinished sets
    await t.tap(find.text('FINISH'));
    await t.pumpAndSettle();
    expect(app.sessions.sessions.length, countBefore + 1);
    final s = app.sessions.sessions.firstWhere((x) => x.id.startsWith('ws_'));
    expect(s.workoutId, 'w2');
    expect(s.doneSets, 1);
    expect(s.workoutDate.isBefore(before), isFalse);
    expect(s.meta.createdAt.isBefore(before), isFalse);
    expect(app.workouts.rotation.currentIndex, (idxBefore + 1) % 3);
    // The completion page replaced the logger.
    expect(find.byType(WorkoutCompletePage), findsOneWidget);
    expect(find.byType(ActiveWorkoutPage), findsNothing);
    h.dispose();
  });

  testWidgets('backdated finish keeps the chosen workoutDate and does not advance the rotation', (t) async {
    final h = t.ensureSemantics();
    final past = DateTime(2024, 3, 1);
    final app = await pumpPage(t, ActiveWorkoutPage(workoutId: 'w2', backdate: past));
    expect(find.textContaining('Backdated entry'), findsOneWidget);
    final idxBefore = app.workouts.rotation.currentIndex;
    await tapDone(t, 1);
    await t.tap(find.text('FINISH WORKOUT'));
    await t.pumpAndSettle();
    await t.tap(find.text('FINISH'));
    await t.pumpAndSettle();
    final s = app.sessions.sessions.firstWhere((x) => x.id.startsWith('ws_'));
    expect(s.workoutDate, past);
    expect(s.meta.createdAt.isAfter(past), isTrue);
    expect(app.workouts.rotation.currentIndex, idxBefore);
    h.dispose();
  });

  testWidgets('finish with nothing logged does not save', (t) async {
    final app = await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'));
    final n = app.sessions.sessions.length;
    await t.tap(find.text('FINISH WORKOUT'));
    await t.pumpAndSettle();
    expect(find.textContaining('Log at least one set'), findsOneWidget);
    expect(app.sessions.sessions.length, n);
  });

  testWidgets('back asks to discard; keep stays, discard leaves without saving', (t) async {
    final app = await pumpPushed(t, const ActiveWorkoutPage(workoutId: 'w2'));
    final n = app.sessions.sessions.length;
    final idx = app.workouts.rotation.currentIndex;
    await tapDone(t, 1); // something logged: back must ask
    await t.tap(find.byIcon(Icons.arrow_back));
    await t.pumpAndSettle();
    expect(find.text('DISCARD WORKOUT?'), findsOneWidget);
    await t.tap(find.text('KEEP TRAINING'));
    await t.pumpAndSettle();
    expect(find.byType(ActiveWorkoutPage), findsOneWidget);

    await t.tap(find.byIcon(Icons.arrow_back));
    await t.pumpAndSettle();
    await t.tap(find.text('DISCARD'));
    await t.pumpAndSettle();
    await t.pumpAndSettle();
    expect(find.byType(ActiveWorkoutPage), findsNothing);
    expect(app.sessions.sessions.length, n);
    expect(app.workouts.rotation.currentIndex, idx);
  });

  testWidgets('mixed workout: cardio block fields adapt to treadmill', (t) async {
    await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w1'), size: const Size(390, 3200));
    expect(find.text('CARDIO FINISHER'), findsOneWidget);
    expect(find.text('TREADMILL RUN'), findsOneWidget);
    expect(find.text('Target: 20 min • 7.5 km/h • 3% Incline'), findsOneWidget);
    expect(find.text('SPEED / INCLINE'), findsOneWidget);
    expect(find.text('DISTANCE'), findsOneWidget);
    expect(find.text('RESISTANCE'), findsNothing);
    expect(find.text('+ Add 5 min'), findsOneWidget);
    await t.tap(find.text('+ Add 5 min'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Target: 25 min • 7.5 km/h • 3% Incline'), findsOneWidget);
  });

  testWidgets('unknown workout and empty workout show real states', (t) async {
    await pumpPage(t, const ActiveWorkoutPage(workoutId: 'nope'));
    expect(find.text('This workout no longer exists.'), findsOneWidget);

    await pumpLaunched(
      t,
      () => const ActiveWorkoutPage(workoutId: 'empty'),
      prep: (app) => app.workouts.saveWorkout(Workout(id: 'empty', name: 'Empty day')),
    );
    expect(find.text('No exercises'), findsOneWidget);
    expect(find.text('EDIT WORKOUT'), findsOneWidget);
  });

  testWidgets('small screen / large text: no overflow in logger, mixed and summary', (t) async {
    for (final id in ['w2', 'w1']) {
      await pumpPage(t, ActiveWorkoutPage(workoutId: id), size: const Size(320, 568), textScale: 1.3);
      expect(t.takeException(), isNull, reason: 'logger $id');
    }
    await pumpPage(t, const WorkoutCompletePage(sessionId: 'seed_s2'), size: const Size(320, 568), textScale: 1.3);
    expect(t.takeException(), isNull, reason: 'summary');
  });

  testWidgets('summary: not found and details toggle', (t) async {
    await pumpPage(t, const WorkoutCompletePage(sessionId: 'missing'));
    expect(find.textContaining('could not be found'), findsOneWidget);

    await pumpPage(t, const WorkoutCompletePage(sessionId: 'seed_s2'), size: const Size(390, 1200));
    expect(find.text('WORKOUT DETAILS'), findsNothing);
    await t.tap(find.text('VIEW WORKOUT DETAILS'));
    await t.pumpAndSettle();
    expect(find.text('WORKOUT DETAILS'), findsOneWidget);
    expect(find.text('HIDE WORKOUT DETAILS'), findsOneWidget);
  });

  testWidgets('summary: mixed session shows strength + cardio sections from real data', (t) async {
    final mixed = WorkoutSession(
      id: 'mixed1',
      workoutId: 'w1',
      name: 'Chest + Biceps',
      workoutDate: DateTime.now(),
      durationSeconds: 4704,
      exercises: const [
        ExerciseLog(exerciseId: 'bench_press', sets: [SetLog(weightKg: 80, reps: 8), SetLog(weightKg: 80, reps: 8)]),
        ExerciseLog(exerciseId: 'barbell_curl', sets: [SetLog(weightKg: 30, reps: 10)]),
      ],
      cardio: CardioSession(
          id: 'mixed1_c', kind: CardioKind.treadmill, workoutDate: DateTime.now(), durationSeconds: 1200, distanceKm: 2.5, speedKmh: 7.5, inclinePct: 3),
    );
    await pumpLaunched(t, () => const WorkoutCompletePage(sessionId: 'mixed1'),
        prep: (app) => app.sessions.add(mixed), size: const Size(390, 2000));
    expect(find.text('WORKOUT COMPLETE'), findsOneWidget);
    expect(find.text('STRENGTH'), findsOneWidget);
    expect(find.text('CARDIO'), findsOneWidget);
    expect(find.text('Treadmill Run'), findsOneWidget);
    expect(find.text('Incline'.toUpperCase()), findsOneWidget);
    expect(find.text('RESISTANCE'), findsNothing);
    expect(find.text('Muscle volume'), findsOneWidget);
    await shot(t, 'aw_complete_mixed');
  });

  group('ActiveWorkoutController', () {
    test('keeps only done sets and drops empty exercises; cardio is optional', () {
      final app = AppController()..startDemo();
      final w = app.workouts.byId('w1')!;
      final c = ActiveWorkoutController(workout: w, catalog: app.exercises.all, sessions: app.sessions, profile: app.profile.profile);
      expect(c.isMixed, isTrue);
      c.toggleSet(c.drafts[0], 0);
      final s = c.buildSession(id: 'a', workoutDate: DateTime(2020, 1, 2));
      expect(s.exercises.length, 1);
      expect(s.exercises.first.sets.length, 1);
      expect(s.workoutDate, DateTime(2020, 1, 2));
      expect(s.meta.createdAt.year, DateTime.now().year);
      expect(s.cardio, isNull); // timer never started
      c.dispose();
    });

    test('finishing an exercise collapses it and expands the next', () {
      final app = AppController()..startDemo();
      final w = app.workouts.byId('w2')!;
      final c = ActiveWorkoutController(workout: w, catalog: app.exercises.all, sessions: app.sessions, profile: app.profile.profile);
      expect(c.drafts[0].expanded, isTrue);
      for (var i = 0; i < c.drafts[0].sets.length; i++) {
        c.toggleSet(c.drafts[0], i);
      }
      expect(c.drafts[0].expanded, isFalse);
      expect(c.drafts[1].expanded, isTrue);
      expect(c.rest.value, isNotNull); // rest continues between exercises
      c.dispose();
    });

    test('no rest after the very last set of the workout', () {
      final app = AppController()..startDemo();
      final w = app.workouts.byId('w2')!;
      final c = ActiveWorkoutController(workout: w, catalog: app.exercises.all, sessions: app.sessions, profile: app.profile.profile);
      for (final d in c.drafts) {
        for (var i = 0; i < d.sets.length; i++) {
          c.toggleSet(d, i);
        }
      }
      expect(c.remainingSets, 0);
      expect(c.rest.value, isNull);
      c.dispose();
    });
  });
}
