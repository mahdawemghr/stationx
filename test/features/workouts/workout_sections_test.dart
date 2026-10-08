import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  setUpAll(loadAppFonts);

  group('muscle sections (Legs + Shoulders workout w3)', () {
    testWidgets('preview shows domain-derived section headers, order preserved', (t) async {
      final app = await open(t, () => const WorkoutPreviewPage(workoutId: 'w3'));
      final w = app.workouts.byId('w3')!;
      final sections = WorkoutSections.group(w.exercises, app.exercises.all);
      expect(sections.map((s) => s.label).toSet(), {'Legs', 'Shoulders'});
      for (final label in ['Legs', 'Shoulders']) {
        expect(find.text(label.toUpperCase()), findsNWidgets(sections.where((s) => s.label == label).length));
      }
      expect(find.bySemanticsLabel(RegExp(r'^Legs, \d+ exercises? · \d+ sets?')), findsWidgets);
      // Rows keep the workout order (top to bottom).
      final ys = [for (final re in w.exercises) t.getTopLeft(find.text(app.exercises.byId(re.exerciseId)!.name).first).dy];
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

    testWidgets('editor: headers shown, reorder regroups without changing the saved order logic', (t) async {
      final app = await open(t, () => const WorkoutEditorPage(workoutId: 'w3'));
      final before = app.workouts.byId('w3')!.exercises.map((e) => e.exerciseId).toList();
      expect(before.take(3), ['back_squat', 'overhead_press', 'leg_press']);
      expect(find.text('LEGS'), findsNWidgets(3));
      expect(find.text('SHOULDERS'), findsNWidgets(2));

      await t.ensureVisible(find.text('REORDER'));
      await t.tap(find.text('REORDER'));
      await settle(t);
      // Move overhead press (index 1) down twice: squat, press, rdl | OHP, lateral | calf.
      await t.tap(find.byTooltip('Move down').at(1));
      await settle(t);
      await t.tap(find.byTooltip('Move down').at(2));
      await settle(t);
      expect(find.text('LEGS'), findsNWidgets(2));
      expect(find.text('SHOULDERS'), findsNWidgets(1));

      await t.tap(find.text('SAVE WORKOUT STRUCTURE'));
      await settle(t);
      final after = app.workouts.byId('w3')!.exercises.map((e) => e.exerciseId).toList();
      expect(after, ['back_squat', 'leg_press', 'rdl', 'overhead_press', 'lateral_raise', 'calf_raise']);
    });

    testWidgets('hub routine card shows a one-line section summary', (t) async {
      await pumpPage(t, const WorkoutsHubPage(), size: const Size(390, 1800));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Legs · Shoulders'), findsOneWidget);
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
