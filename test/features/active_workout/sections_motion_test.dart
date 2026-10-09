import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/core/utils/formatters.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/active_workout/active_workout_controller.dart';
import 'package:stationx/features/active_workout/active_workout_page.dart';
import 'package:stationx/features/active_workout/widgets/exercise_block.dart';
import 'package:stationx/features/active_workout/workout_complete_page.dart';
import 'package:stationx/features/today/today_page.dart';

import '../../helpers/pump.dart';

ActiveWorkoutController ctlFor(AppController app, String id) => ActiveWorkoutController(
      workout: app.workouts.byId(id)!,
      catalog: app.exercises.all,
      sessions: app.sessions,
      profile: app.profile.profile,
    );

Future<AppController> pumpPushed(WidgetTester t, Widget page, {AppController? controller}) async {
  final app = await pumpPage(
    t,
    Builder(
      builder: (c) => Scaffold(
        body: Center(
          child: TextButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page)), child: const Text('launch')),
        ),
      ),
    ),
    controller: controller,
  );
  await t.tap(find.text('launch'));
  await t.pumpAndSettle();
  return app;
}

Future<void> tapDone(WidgetTester t, int n) async {
  await t.tap(find.bySemanticsLabel('Set $n done').first);
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(loadAppFonts);

  group('muscle sections', () {
    test('a new session runs in arranged order: one section per muscle, counts follow the sets', () async {
      final app = AppController();
      await app.startDemo();
      final saved = app.workouts.byId('w3')!; // saved order interleaves Legs / Shoulders
      final c = ctlFor(app, 'w3');
      // The OLD rule kept the saved order and showed Legs, Shoulders, Legs, Shoulders, Legs. The new rule
      // (plan 6.1: ONE section per muscle) arranges a NEW session, so display order == execution order.
      expect(c.sections.map((s) => s.label).toList(), ['Legs', 'Shoulders']);
      final arranged = WorkoutSections.arrange(saved.exercises, app.exercises.all);
      expect([for (final d in c.drafts) d.exercise.id], [for (final e in arranged) e.exerciseId]);
      expect([for (final s in c.sections) ...s.drafts], c.drafts);
      expect(c.sections[0].startIndex, 0);
      expect(c.sections[1].startIndex, c.sections[0].drafts.length);
      final s0 = c.sections.first;
      final first = c.drafts[0];
      expect((s0.exercisesDone, s0.setsDone, s0.setsTotal), (0, 0, s0.drafts.fold(0, (a, d) => a + d.sets.length)));
      for (var i = 0; i < first.sets.length; i++) {
        c.toggleSet(first, i);
      }
      expect((s0.exercisesDone, s0.setsDone), (1, first.sets.length));
      expect(c.sections[1].complete, isFalse);
      c.dispose();
    });

    test('a restored draft keeps its stored order (never reordered) and counts stay right', () async {
      final app = AppController();
      await app.startDemo();
      final w = app.workouts.byId('w3')!; // saved order is NOT arranged
      expect(WorkoutSections.isArranged(w.exercises, app.exercises.all), isFalse);
      final draft = WorkoutDraft(
        workoutId: w.id,
        workoutName: w.name,
        startedAt: DateTime.now(),
        savedAt: DateTime.now(),
        exercises: [
          for (var i = 0; i < w.exercises.length; i++)
            DraftExercise(
              exerciseId: w.exercises[i].exerciseId,
              repMin: w.exercises[i].repMin,
              repMax: w.exercises[i].repMax,
              sets: [for (var k = 0; k < w.exercises[i].sets; k++) DraftSet(weightKg: 50, reps: 5, done: i == 0 && k == 0)],
            ),
        ],
      );
      final c = ActiveWorkoutController(
        workout: w,
        catalog: app.exercises.all,
        sessions: app.sessions,
        profile: app.profile.profile,
        restoreFrom: draft,
      );
      expect([for (final d in c.drafts) d.exercise.id], [for (final e in w.exercises) e.exerciseId]);
      expect(c.sections.map((s) => s.label).toList(), ['Legs', 'Shoulders', 'Legs', 'Shoulders', 'Legs']);
      expect(c.sections.map((s) => s.startIndex).toList(), [0, 1, 2, 4, 5]);
      expect([for (final s in c.sections) ...s.drafts], c.drafts);
      expect(c.sections.first.setsDone, 1);
      expect(c.doneSets, 1);
      c.dispose();
    });

    test('swap keeps the exercise position', () async {
      final app = AppController();
      await app.startDemo();
      final c = ctlFor(app, 'w2');
      final before = [for (final d in c.drafts) d.exercise.id];
      final repl = app.exercises.all.firstWhere((e) => !before.contains(e.id) && e.primaryMuscle == c.drafts[1].exercise.primaryMuscle);
      c.replaceExercise(c.drafts[1], repl, app.sessions);
      expect(c.drafts[1].exercise.id, repl.id);
      expect(c.drafts.length, before.length);
      expect([for (final s in c.sections) ...s.drafts], c.drafts);
      c.dispose();
    });

    testWidgets('Legs + Shoulders shows exactly two section headers', (t) async {
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w3'), size: const Size(360, 3000));
      expect(find.byType(MuscleSectionHeader), findsNWidgets(2));
      expect(find.text('LEGS'), findsOneWidget);
      expect(find.text('SHOULDERS'), findsOneWidget);
    });

    testWidgets('single-muscle workout hides the section header', (t) async {
      final app = AppController();
      await app.startDemo();
      await app.workouts.saveWorkout(Workout(id: 'chest_only', name: 'Chest day', exercises: const [
        RoutineExercise(exerciseId: 'bench_press', sets: 3, repMin: 6, repMax: 8),
        RoutineExercise(exerciseId: 'incline_db_press', sets: 3, repMin: 8, repMax: 10),
      ]));
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'chest_only'), controller: app, size: const Size(360, 3000));
      expect(find.byType(MuscleSectionHeader), findsNothing);
      expect(find.text('CHEST'), findsNothing);
      // Two sub-areas (main + Upper chest) still get the compact sub-caption.
      expect(find.text('Upper chest'), findsOneWidget);
    });

    testWidgets('a forearm exercise creates a Forearms section and sub-captions appear in multi-muscle workouts', (t) async {
      final app = AppController();
      await app.startDemo();
      await app.workouts.saveWorkout(Workout(id: 'mix', name: 'Mix', exercises: const [
        RoutineExercise(exerciseId: 'wrist_curl', sets: 2, repMin: 10, repMax: 15),
        RoutineExercise(exerciseId: 'incline_db_press', sets: 3, repMin: 8, repMax: 10),
        RoutineExercise(exerciseId: 'bench_press', sets: 3, repMin: 6, repMax: 8),
      ]));
      final c = ctlFor(app, 'mix');
      expect(c.sections.map((s) => s.label).toList(), ['Forearms', 'Chest']);
      expect(c.sections[1].groups.map((g) => g.label).toList(), [null, 'Upper chest']);
      c.dispose();
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'mix'), controller: app, size: const Size(360, 3000));
      expect(find.text('FOREARMS'), findsOneWidget);
      expect(find.text('CHEST'), findsOneWidget);
      expect(find.text('Upper chest'), findsOneWidget);
    });

    testWidgets('headers render, are semantic headers and update per edit', (t) async {
      final h = t.ensureSemantics();
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2')); // Back 3, Triceps 2, Shoulders 1
      expect(find.byType(MuscleSectionHeader), findsWidgets);
      expect(find.text('BACK'), findsOneWidget);
      expect(find.textContaining('0/3 EX'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Back, 0/3 exercises')), findsOneWidget);
      expect(t.getSemantics(find.bySemanticsLabel(RegExp(r'^Back, 0/3'))).flagsCollection.isHeader, isTrue);
      await tapDone(t, 1);
      expect(find.textContaining('0/3 EX  •  1/'), findsOneWidget);
      h.dispose();
    });

    testWidgets('no overflow at 320x568 @2x with sections', (t) async {
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w3'), size: const Size(320, 568), textScale: 1.3);
      expect(t.takeException(), isNull);
    });
  });

  group('motion and performance', () {
    testWidgets('set-done animation never blocks the next tap', (t) async {
      final h = t.ensureSemantics();
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'));
      await t.tap(find.bySemanticsLabel('Set 1 done').first);
      await t.pump(const Duration(milliseconds: 16)); // mid-animation
      await t.tap(find.bySemanticsLabel('Set 2 done').first);
      await t.pump(const Duration(milliseconds: 16));
      expect(find.text('16 OF 18 SETS REMAINING'), findsOneWidget);
      h.dispose();
    });

    testWidgets('reduced motion: set done leaves no running animation', (t) async {
      final h = t.ensureSemantics();
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), screenReader: true);
      await t.tap(find.bySemanticsLabel('Set 1 done').first);
      await t.pump();
      await t.pump(const Duration(milliseconds: 20));
      // Nothing keeps ticking once the (ink / rest) effects end.
      await t.pump(const Duration(seconds: 1));
      expect(t.binding.transientCallbackCount, 0);
      expect(find.text('17 OF 18 SETS REMAINING'), findsOneWidget);
      h.dispose();
    });

    testWidgets('editing one set rebuilds only its own block', (t) async {
      final h = t.ensureSemantics();
      final builds = <int, int>{};
      ExerciseBlock.debugOnBuild = (i) => builds[i] = (builds[i] ?? 0) + 1;
      addTearDown(() => ExerciseBlock.debugOnBuild = null);
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'));
      expect(builds.keys, contains(0));
      expect(builds.length, greaterThan(1));
      final before = Map<int, int>.of(builds);
      await tapDone(t, 1); // first set of exercise 0 (does not complete it)
      await t.pump(const Duration(milliseconds: 300));
      expect(builds[0]! > before[0]!, isTrue);
      for (final i in before.keys.where((i) => i != 0)) {
        expect(builds[i], before[i], reason: 'block $i must not rebuild');
      }
      h.dispose();
    });
  });

  group('workout complete', () {
    testWidgets('count-up ends on the real numbers and fits 320x568', (t) async {
      final app = AppController();
      await app.startDemo();
      final s = app.sessions.sessions.firstWhere((s) => s.doneSets > 0);
      await pumpPage(t, WorkoutCompletePage(sessionId: s.id), controller: app, size: const Size(320, 568));
      await t.pump(const Duration(milliseconds: 100)); // mid count-up: not final yet
      await t.pumpAndSettle();
      final unit = app.profile.profile.unit;
      expect(find.text(Fmt.thousands(Fmt.toDisplayWeight(s.volume, unit))), findsWidgets);
      expect(find.text('${s.doneSets}'), findsWidgets);
      expect(t.takeException(), isNull);
    });

    testWidgets('reduced motion shows the final numbers immediately', (t) async {
      final app = AppController();
      await app.startDemo();
      final s = app.sessions.sessions.firstWhere((s) => s.doneSets > 0);
      await pumpPage(t, WorkoutCompletePage(sessionId: s.id), controller: app, screenReader: true);
      await t.pump();
      await t.pump(const Duration(milliseconds: 20));
      expect(find.text('${s.doneSets}'), findsWidgets);
    });
  });

  group('Today', () {
    testWidgets('entry stagger plays once: a rebuild starts no animation', (t) async {
      final app = AppController();
      await app.startDemo();
      await pumpPage(t, const TodayPage(), controller: app);
      await t.pumpAndSettle();
      app.profile.profile; // no-op read
      app.notifyListeners();
      await t.pump();
      expect(t.binding.transientCallbackCount, 0);
    });

    testWidgets('week stats count up to the real values and fit 320x568', (t) async {
      final app = AppController();
      await app.startDemo();
      await pumpPage(t, const TodayPage(), controller: app, size: const Size(320, 568));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('START WORKOUT'), findsOneWidget);
    });
  });

  group('maximum workout length', () {
    Future<AppController> pumpLogger(WidgetTester t, DateTime Function() clock, {String id = 'w2'}) async {
      final app = AppController();
      await app.startDemo();
      await pumpPushed(t, ActiveWorkoutPage(workoutId: id, clock: clock), controller: app);
      return app;
    }

    testWidgets('live expiry saves done sets once, advances once, shows the notice', (t) async {
      final h = t.ensureSemantics();
      var now = DateTime.now();
      final start = now;
      final app = await pumpLogger(t, () => now);
      final oldIds = {for (final s in app.sessions.sessions) s.id};
      final n = oldIds.length;
      final idx = app.workouts.rotation.currentIndex;
      await tapDone(t, 1);
      await t.pump(const Duration(seconds: 1));
      now = start.add(const Duration(minutes: 165));
      await t.pump(const Duration(seconds: 1));
      expect(find.textContaining('will end automatically in 15 min'), findsOneWidget);
      now = start.add(const Duration(hours: 3, seconds: 1));
      await t.pump(const Duration(seconds: 1));
      await t.pumpAndSettle();
      expect(find.byType(WorkoutCompletePage), findsOneWidget);
      expect(app.sessions.sessions.length, n + 1);
      expect(app.workouts.rotation.currentIndex, (idx + 1) % app.workouts.rotation.length);
      expect(app.sessions.sessions.firstWhere((s) => !oldIds.contains(s.id)).doneSets, 1);
      expect(find.textContaining('ended automatically after 3 hours'), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
      expect(app.sessions.sessions.length, n + 1); // no double save
      expect(app.workoutDraft.current, isNull);
      h.dispose();
    });

    testWidgets('nothing logged: nothing saved, logger closes with a message', (t) async {
      var now = DateTime.now();
      final start = now;
      final app = await pumpLogger(t, () => now);
      final n = app.sessions.sessions.length;
      now = start.add(const Duration(hours: 3));
      await t.pump(const Duration(seconds: 1));
      await t.pumpAndSettle();
      expect(find.byType(ActiveWorkoutPage), findsNothing);
      expect(app.sessions.sessions.length, n);
    });

    testWidgets('limit off: never ends', (t) async {
      var now = DateTime.now();
      final start = now;
      final app = AppController();
      await app.startDemo();
      await app.setMaxWorkoutMinutes(null);
      await pumpPushed(t, ActiveWorkoutPage(workoutId: 'w2', clock: () => now), controller: app);
      now = start.add(const Duration(hours: 9));
      await t.pump(const Duration(seconds: 2));
      expect(find.byType(ActiveWorkoutPage), findsOneWidget);
    });

    testWidgets('resume after kill: Today ends the expired draft, shows a dismissible notice, no double save', (t) async {
      final app = AppController();
      await app.startDemo();
      final c = ActiveWorkoutController(
        workout: app.workouts.byId('w2')!,
        catalog: app.exercises.all,
        sessions: app.sessions,
        profile: app.profile.profile,
        draftStore: app.workoutDraft,
        clock: () => DateTime.now().subtract(const Duration(hours: 4)),
      );
      c.toggleSet(c.drafts[0], 0);
      c.toggleSet(c.drafts[0], 1);
      await c.flushDraft();
      c.dispose();
      final n = app.sessions.sessions.length;
      await pumpPage(t, const TodayPage(), controller: app);
      await t.pumpAndSettle();
      expect(find.text('Resume workout'), findsNothing);
      expect(app.sessions.sessions.length, n + 1);
      expect(find.textContaining('ended automatically after 3 hours'), findsOneWidget);
      expect(find.textContaining('2 sets saved'), findsOneWidget);
      await app.autoEndExpiredWorkout();
      expect(app.sessions.sessions.length, n + 1);
      await t.tap(find.bySemanticsLabel('Dismiss'));
      await t.pumpAndSettle();
      expect(find.textContaining('ended automatically'), findsNothing);
      expect(app.pendingAutoEndNotice, isNull);
    });
  });
}
