import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/workouts/workout_editor_page.dart';
import 'package:stationx/features/workouts/workout_preview_page.dart';
import 'package:stationx/features/workouts/workouts_hub_page.dart';

import '../../helpers/pump.dart';

Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
  await t.pump(const Duration(milliseconds: 400));
}

Future<AppController> open(WidgetTester t, Widget Function() page, {Size size = const Size(390, 1800)}) async {
  final app = await pumpPage(
    t,
    Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page())), child: const Text('go')))),
    size: size,
  );
  await t.tap(find.text('go'));
  await settle(t);
  return app;
}

RoutineExercise _re(String id) => RoutineExercise(exerciseId: id, sets: 3, repMin: 8, repMax: 12);

Future<void> _save(AppController app, String id, List<String> ex) =>
    app.workouts.saveWorkout(Workout(id: id, name: 'T $id', exercises: [for (final e in ex) _re(e)], restSeconds: 90));

Future<AppController> _openWith(WidgetTester t, String id, List<String> ex, Widget Function() page,
    {Size size = const Size(390, 2400)}) async {
  final app = await pumpPage(
    t,
    Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page())), child: const Text('go')))),
    size: size,
  );
  await _save(app, id, ex);
  await t.tap(find.text('go'));
  await settle(t);
  return app;
}

void main() {
  setUpAll(loadAppFonts);

  group('muscle sections (Legs + Shoulders workout w3)', () {
    testWidgets('preview shows domain-derived section headers, order preserved', (t) async {
      final app = await open(t, () => const WorkoutPreviewPage(workoutId: 'w3'));
      final w = app.workouts.byId('w3')!;
      final sections = WorkoutSections.group(w.exercises, app.exercises.all);
      // NEW BEHAVIOUR: exactly one header per muscle (the seeded order interleaves Legs/Shoulders/Legs,
      // which used to render 3 sections). Displayed order is the ARRANGED order, not the stored one.
      expect(sections.map((s) => s.label), ['Legs', 'Shoulders']);
      expect(find.text('LEGS'), findsOneWidget);
      expect(find.text('SHOULDERS'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Legs, \d+ exercises? · \d+ sets?')), findsWidgets);
      final arranged = WorkoutSections.arrange(w.exercises, app.exercises.all);
      final ys = [for (final re in arranged) t.getTopLeft(find.text(app.exercises.byId(re.exerciseId)!.name).first).dy];
      expect([...ys]..sort(), ys);
    });

    testWidgets('preview section can be collapsed and expanded', (t) async {
      await open(t, () => const WorkoutPreviewPage(workoutId: 'w3'));
      expect(find.textContaining('Squat'), findsOneWidget);
      await t.tap(find.text('LEGS').first);
      await settle(t);
      expect(find.textContaining('Squat'), findsNothing);
      await t.tap(find.text('LEGS').first);
      await settle(t);
      expect(find.textContaining('Squat'), findsOneWidget);
    });

    testWidgets('editor: one header per muscle, arranged on open, move clamped to the section', (t) async {
      final app = await open(t, () => const WorkoutEditorPage(workoutId: 'w3'));
      // Old behaviour showed LEGS x3 / SHOULDERS x2 (stored order interleaved). Now arranged on open.
      expect(find.text('LEGS'), findsOneWidget);
      expect(find.text('SHOULDERS'), findsOneWidget);

      await t.ensureVisible(find.text('REORDER'));
      await t.tap(find.text('REORDER'));
      await settle(t);
      // First row of a section cannot move up (it would cross into the previous section).
      final ups = t.widgetList<SxIconButton>(find.byType(SxIconButton)).where((b) => b.tooltip == 'Move up').toList();
      expect(ups.first.onPressed, isNull);
      await t.tap(find.byTooltip('Move down').first);
      await settle(t);

      await t.tap(find.text('SAVE WORKOUT STRUCTURE'));
      await settle(t);
      final after = app.workouts.byId('w3')!.exercises.map((e) => e.exerciseId).toList();
      expect(WorkoutSections.isArranged(app.workouts.byId('w3')!.exercises, app.exercises.all), isTrue);
      expect(after.toSet(), {'back_squat', 'overhead_press', 'leg_press', 'rdl', 'lateral_raise', 'calf_raise'});
    });

    testWidgets('hub routine card shows a one-line section summary', (t) async {
      await pumpPage(t, const WorkoutsHubPage(), size: const Size(390, 1800));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Legs · Shoulders'), findsOneWidget);
    });

    testWidgets('Legs + Shoulders -> exactly 2 section headers', (t) async {
      await _openWith(t, 'x1', ['back_squat', 'overhead_press', 'rdl', 'lateral_raise'], () => const WorkoutPreviewPage(workoutId: 'x1'));
      expect(find.text('LEGS'), findsOneWidget);
      expect(find.text('SHOULDERS'), findsOneWidget);
    });

    testWidgets('push day (chest, shoulders, triceps) -> 3 section headers', (t) async {
      await _openWith(t, 'x2', ['bench_press', 'overhead_press', 'tricep_pushdown', 'lateral_raise'], () => const WorkoutPreviewPage(workoutId: 'x2'));
      expect(find.text('CHEST'), findsOneWidget);
      expect(find.text('SHOULDERS'), findsOneWidget);
      expect(find.text('TRICEPS'), findsOneWidget);
    });

    testWidgets('single-muscle workout: no section header, sub-headers kept; main before sub-areas', (t) async {
      // Stored in a scrambled order on purpose.
      final app = await _openWith(t, 'x3', ['cable_fly', 'decline_bench_press', 'incline_bench_press', 'bench_press'], () => const WorkoutPreviewPage(workoutId: 'x3'));
      expect(find.text('CHEST'), findsNothing);
      expect(find.text('Upper chest'), findsOneWidget);
      expect(find.text('Lower chest'), findsOneWidget);
      expect(find.text('Flyes & isolation'), findsOneWidget);
      final names = [for (final id in ['bench_press', 'incline_bench_press', 'decline_bench_press', 'cable_fly']) app.exercises.byId(id)!.name];
      final ys = [for (final n in names) t.getTopLeft(find.text(n).first).dy];
      expect([...ys]..sort(), ys, reason: 'bench, incline, decline, fly');
    });

    testWidgets('forearms get their own section when a wrist curl is present', (t) async {
      await _openWith(t, 'x4', ['barbell_curl', 'wrist_curl'], () => const WorkoutPreviewPage(workoutId: 'x4'));
      expect(find.text('BICEPS'), findsOneWidget);
      expect(find.text('FOREARMS'), findsOneWidget);
    });

    testWidgets('editor: added chest exercise lands in the Chest section (no second header)', (t) async {
      final app = await _openWith(t, 'x5', ['bench_press', 'cable_fly', 'back_squat'], () => const WorkoutEditorPage(workoutId: 'x5'));
      expect(find.text('CHEST'), findsOneWidget);
      await t.ensureVisible(find.text('ADD EXERCISE'));
      await t.tap(find.text('ADD EXERCISE'));
      await settle(t);
      await t.enterText(find.byType(TextField).first, 'Incline Barbell');
      await settle(t);
      await t.tap(find.text('Incline Barbell Press').first);
      await settle(t);
      expect(find.text('CHEST'), findsOneWidget);
      await t.ensureVisible(find.text('SAVE WORKOUT STRUCTURE'));
      await t.tap(find.text('SAVE WORKOUT STRUCTURE'));
      await settle(t);
      final ids = app.workouts.byId('x5')!.exercises.map((e) => e.exerciseId).toList();
      expect(ids, ['bench_press', 'incline_bench_press', 'cable_fly', 'back_squat']);
    });

    testWidgets('editor: dragging outside the section snaps back with a snack', (t) async {
      final app = await _openWith(t, 'x6', ['bench_press', 'cable_fly', 'back_squat', 'leg_press'], () => const WorkoutEditorPage(workoutId: 'x6'));
      final handles = find.byIcon(Icons.drag_handle);
      expect(handles, findsNWidgets(4));
      // Drag the first chest row far down, past the Legs rows.
      final g = await t.startGesture(t.getCenter(handles.first));
      await t.pump(const Duration(milliseconds: 600));
      await g.moveBy(const Offset(0, 80));
      await t.pump(const Duration(milliseconds: 100));
      await g.moveBy(const Offset(0, 400));
      await t.pump(const Duration(milliseconds: 100));
      await g.up();
      await settle(t);
      expect(find.text('Exercises stay inside their muscle section'), findsOneWidget);
      await t.ensureVisible(find.text('SAVE WORKOUT STRUCTURE'));
      await t.tap(find.text('SAVE WORKOUT STRUCTURE'));
      await settle(t);
      final ids = app.workouts.byId('x6')!.exercises.map((e) => e.exerciseId).toList();
      // Still chest first (snapped to the end of the Chest section at most), legs after.
      expect(ids.take(2).toSet(), {'bench_press', 'cable_fly'});
      expect(ids.skip(2).toSet(), {'back_squat', 'leg_press'});
    });

    testWidgets('reduced motion: preview collapse is instant', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await open(t, () => const WorkoutPreviewPage(workoutId: 'w3'));
      await t.tap(find.text('LEGS').first);
      await t.pump();
      await t.pump(const Duration(milliseconds: 20));
      expect(find.textContaining('Squat'), findsNothing);
    });

    for (final entry in <String, Widget Function()>{
      'preview': () => const WorkoutPreviewPage(workoutId: 'w3'),
      'editor': () => const WorkoutEditorPage(workoutId: 'w3'),
    }.entries) {
      testWidgets('${entry.key}: no overflow at 320x568, 2x text', (t) async {
        final app = await pumpPage(
          t,
          Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => entry.value())), child: const Text('go')))),
          size: const Size(320, 568),
          textScale: 2.0,
        );
        expect(app, isNotNull);
        await t.tap(find.text('go'));
        await settle(t);
        final e = t.takeException();
        expect(e, isNull, reason: e is FlutterError ? e.toStringDeep() : '$e');
      });
    }
  });
}
