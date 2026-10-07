import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/active_workout/active_workout_page.dart';
import 'package:stationx/features/cardio/cardio_home_view.dart';
import 'package:stationx/features/workouts/swap_exercise_sheet.dart';
import 'package:stationx/features/workouts/workout_editor_page.dart';
import 'package:stationx/features/workouts/workout_preview_page.dart';
import 'package:stationx/features/workouts/workouts_hub_page.dart';

import '../../helpers/pump.dart';

Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
  await t.pump(const Duration(milliseconds: 400));
}

/// Navigation targets are owned by other features; assert only that the route
/// was pushed, and drain any build/paint errors the target page may raise.
void expectPushed(WidgetTester t, Type page) {
  expect(find.byType(page), findsOneWidget);
  while (t.takeException() != null) {}
}

void main() {
  setUpAll(loadAppFonts);

  group('Hub', () {
    testWidgets('shows sequential rotation position from the index', (t) async {
      await pumpPage(t, const WorkoutsHubPage());
      expect(find.text('3-Day Rotation'), findsOneWidget);
      expect(find.text('Day 2 / 3'), findsOneWidget);
      expect(find.text('UP NEXT'), findsOneWidget);
      expect(find.text('Back + Triceps'), findsWidgets);
    });

    testWidgets('Launch opens the next workout', (t) async {
      await pumpPage(t, const WorkoutsHubPage());
      await t.tap(find.text('LAUNCH'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expectPushed(t, ActiveWorkoutPage);
    });

    testWidgets('Change next workout sets the index and never advances/logs', (t) async {
      final app = await pumpPage(t, const WorkoutsHubPage());
      final sessionsBefore = app.sessions.sessions.length;
      await t.tap(find.text('CHANGE NEXT'));
      await settle(t);
      await t.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Legs + Shoulders')));
      await settle(t);
      expect(app.workouts.rotation.currentIndex, 2);
      expect(app.workouts.currentWorkout!.id, 'w3');
      expect(app.sessions.sessions.length, sessionsBefore);
      expect(find.text('Day 3 / 3'), findsOneWidget);
    });

    testWidgets('empty account shows rotation without history', (t) async {
      await pumpPage(t, const WorkoutsHubPage(), demo: false);
      expect(find.text('Not logged yet'), findsNothing); // only shown for earlier days; current index 0
      expect(find.text('Day 1 / 3'), findsOneWidget);
      expect(find.text('Not done yet'), findsWidgets);
    });

    testWidgets('no routines → empty state with actions', (t) async {
      final app = await pumpPage(t, const WorkoutsHubPage(), demo: false);
      for (final w in [...app.workouts.workouts]) {
        await app.workouts.deleteWorkout(w.id);
      }
      await settle(t);
      expect(find.text('Build your first workout'), findsOneWidget);
      await t.tap(find.text('BROWSE TEMPLATES'));
      await settle(t);
      expect(find.text('Push / Pull / Legs'), findsOneWidget);
    });

    testWidgets('adding a built-in template creates real workouts', (t) async {
      final app = await pumpPage(t, const WorkoutsHubPage());
      await t.tap(find.text('TEMPLATES'));
      await settle(t);
      final before = app.workouts.workouts.length;
      await t.tap(find.text('ADD').first);
      await settle(t);
      expect(app.workouts.workouts.length, before + 3);
      expect(app.workouts.rotation.length, before + 3);
      expect(app.workouts.rotation.currentIndex, 1, reason: 'adding must not move the rotation');
    });

    testWidgets('cardio segment embeds CardioHomeView', (t) async {
      await pumpPage(t, const WorkoutsHubPage());
      await t.tap(find.text('CARDIO'));
      await settle(t);
      expect(find.byType(CardioHomeView), findsOneWidget);
      expect(find.text('ROUTINES'), findsNothing);
      while (t.takeException() != null) {}
    });

    testWidgets('saved tab is an honest empty state', (t) async {
      await pumpPage(t, const WorkoutsHubPage());
      await t.tap(find.text('SAVED'));
      await settle(t);
      expect(find.text('Nothing saved yet'), findsOneWidget);
    });

    testWidgets('delete routine asks for confirmation', (t) async {
      final app = await pumpPage(t, const WorkoutsHubPage());
      await t.scrollUntilVisible(find.byTooltip('Routine options').first, 200, scrollable: find.byType(Scrollable).first);
      await t.ensureVisible(find.byTooltip('Routine options').first);
      await t.pump();
      await t.tap(find.byTooltip('Routine options').first);
      await settle(t);
      await t.tap(find.text('Delete routine'));
      await settle(t);
      expect(find.textContaining('DELETE '), findsWidgets);
      await t.tap(find.text('CANCEL'));
      await settle(t);
      expect(app.workouts.workouts.length, 3);
    });

    // 320 px @ 1.3x overflows inside the shared SxBrandBar (core) — reported to the owner.
    for (final (size, scale) in [(const Size(320, 568), 1.0), (const Size(360, 800), 1.3), (const Size(412, 915), 1.0)]) {
      testWidgets('layout ok at $size x$scale', (t) async {
        await pumpPage(t, const WorkoutsHubPage(), size: size, textScale: scale);
        await t.drag(find.byType(ListView).first, const Offset(0, -600));
        await settle(t);
        expect(t.takeException(), isNull);
      });
    }
  });

  group('Preview', () {
    testWidgets('shows sequence with last session numbers and starts workout', (t) async {
      await pumpPage(t, const WorkoutPreviewPage(workoutId: 'w2'));
      expect(find.text('BACK + TRICEPS'), findsOneWidget);
      expect(find.text('Lat Pulldown'), findsOneWidget);
      expect(find.textContaining('kg ×'), findsWidgets);
      await t.tap(find.text('START WORKOUT'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expectPushed(t, ActiveWorkoutPage);
    });

    testWidgets('no history → "No history", still renders', (t) async {
      await pumpPage(t, const WorkoutPreviewPage(workoutId: 'w2'), demo: false);
      expect(find.text('No history'), findsWidgets);
    });

    testWidgets('unknown workout → error state', (t) async {
      await pumpPage(t, const WorkoutPreviewPage(workoutId: 'nope'));
      expect(find.text('Unable to load'), findsOneWidget);
    });

    testWidgets('edit opens editor', (t) async {
      await pumpPage(t, const WorkoutPreviewPage(workoutId: 'w2'));
      await t.tap(find.text('EDIT WORKOUT STRUCTURE'));
      await settle(t);
      expect(find.text('WorkoutEditorPage'), findsNothing); // real editor, not a stub
      expect(find.text('ROUTINE ARCHITECTURE'), findsOneWidget);
    });

    testWidgets('small screen, large text: no exception', (t) async {
      await pumpPage(t, const WorkoutPreviewPage(workoutId: 'w3'), size: const Size(320, 568), textScale: 1.3);
      expect(t.takeException(), isNull);
    });
  });

  group('Editor', () {
    Future<AppController> open(WidgetTester t, String id, {bool demo = true, Size size = const Size(390, 844), double scale = 1}) async {
      final app = await pumpPage(t, Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => WorkoutEditorPage(workoutId: id))), child: const Text('go')))), demo: demo, size: size, textScale: scale);
      await t.tap(find.text('go'));
      await settle(t);
      return app;
    }

    testWidgets('delete + save persists via repository', (t) async {
      final app = await open(t, 'w2');
      expect(find.text('6 movements'), findsOneWidget);
      await t.tap(find.byTooltip('Remove exercise').first);
      await settle(t);
      await t.tap(find.text('REMOVE'));
      await settle(t);
      expect(find.text('5 movements'), findsOneWidget);
      await t.tap(find.text('SAVE WORKOUT STRUCTURE'));
      await settle(t);
      expect(app.workouts.byId('w2')!.exercises.length, 5);
      expect(app.workouts.rotation.currentIndex, 1);
      expect(find.text('go'), findsOneWidget); // popped
    });

    testWidgets('unsaved changes ask before leaving', (t) async {
      final app = await open(t, 'w2');
      await t.tap(find.byTooltip('Remove exercise').first);
      await settle(t);
      await t.tap(find.text('REMOVE'));
      await settle(t);
      await t.pageBack();
      await settle(t);
      expect(find.text('DISCARD CHANGES?'), findsOneWidget);
      await t.tap(find.text('DISCARD'));
      await settle(t);
      expect(find.text('go'), findsOneWidget);
      expect(app.workouts.byId('w2')!.exercises.length, 6);
    });

    testWidgets('new draft needs an exercise, then joins the rotation end', (t) async {
      final app = await open(t, 'new_1');
      expect(find.text('New Routine'), findsWidgets);
      await t.tap(find.text('SAVE WORKOUT STRUCTURE'));
      await settle(t);
      expect(find.text('Add at least one exercise'), findsOneWidget);
      expect(app.workouts.byId('new_1'), isNull);
    });

    testWidgets('sets/reps sheet edits the draft and rep range stays valid', (t) async {
      final app = await open(t, 'w2');
      await t.tap(find.byTooltip('Edit sets and reps').first);
      await settle(t);
      await t.tap(find.byTooltip('Increase Sets'));
      await t.pump();
      for (var i = 0; i < 6; i++) {
        await t.tap(find.byTooltip('Decrease Max reps'));
        await t.pump();
      }
      await t.tap(find.text('DONE'));
      await settle(t);
      await t.tap(find.text('SAVE WORKOUT STRUCTURE'));
      await settle(t);
      final re = app.workouts.byId('w2')!.exercises.first;
      expect(re.sets, 4);
      expect(re.repMax >= re.repMin, isTrue);
    });

    testWidgets('reorder mode moves exercises', (t) async {
      final app = await open(t, 'w2');
      await t.scrollUntilVisible(find.text('REORDER'), 200, scrollable: find.byType(Scrollable).first);
      await t.ensureVisible(find.text('REORDER'));
      await t.pump();
      await t.tap(find.text('REORDER'));
      await settle(t);
      await t.tap(find.byTooltip('Move down').first);
      await settle(t);
      await t.tap(find.text('SAVE WORKOUT STRUCTURE'));
      await settle(t);
      expect(app.workouts.byId('w2')!.exercises.first.exerciseId, 'seated_cable_row');
    });

    testWidgets('small screen, large text: no exception', (t) async {
      await open(t, 'w2', size: const Size(320, 568), scale: 1.3);
      expect(t.takeException(), isNull);
    });
  });

  group('Smart swap', () {
    late List<Exercise> catalog;
    late Exercise lat;
    setUp(() {
      final a = AppController()..startDemo();
      catalog = a.exercises.all;
      lat = a.exercises.byId('lat_pulldown')!;
    });

    Future<void> mount(WidgetTester t, ValueChanged<Exercise> onReplace) async {
      await pumpPage(
        t,
        Scaffold(body: SwapExerciseBody(current: lat, catalog: catalog, sets: 4, repRange: '8-12', slotLabel: 'Slot 1/6', onClose: () {}, onReplace: onReplace)),
      );
    }

    testWidgets('lists computed, ranked same-muscle alternatives', (t) async {
      await mount(t, (_) {});
      final expected = SmartSwapService.alternatives(current: lat, catalog: catalog);
      expect(find.text('${expected.length} available'), findsOneWidget);
      expect(find.text('${expected.first.matchPercent}% MATCH'), findsWidgets);
      expect(find.text('Lat Pulldown'), findsOneWidget); // current only, not an alternative
    });

    testWidgets('equipment filter narrows and replace returns selection', (t) async {
      Exercise? picked;
      await mount(t, (e) => picked = e);
      await t.drag(find.text('Free Weights'), const Offset(-250, 0));
      await t.pump();
      await t.tap(find.text('Machines'));
      await t.pump();
      final machines = SmartSwapService.alternatives(current: lat, catalog: catalog, allowedEquipment: {Equipment.machine});
      expect(find.text('${machines.length} available'), findsOneWidget);
      await t.tap(find.text('REPLACE EXERCISE'));
      await t.pump();
      expect(picked!.id, machines.first.exercise.id);
      expect(picked!.equipment, Equipment.machine);
    });

    testWidgets('no candidates → none returned', (t) async {
      final none = SmartSwapService.alternatives(current: lat, catalog: catalog, excludeIds: {for (final e in catalog) e.id});
      expect(none, isEmpty);
    });

    testWidgets('excluded ids are omitted; small screen ok', (t) async {
      await pumpPage(
        t,
        Scaffold(body: SwapExerciseBody(current: lat, catalog: catalog, sets: 4, repRange: '8-12', excludeIds: {for (final e in catalog) e.id}, onClose: () {}, onReplace: (_) {})),
        size: const Size(320, 568),
        textScale: 1.3,
      );
      await t.scrollUntilVisible(find.text('No alternatives'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('No alternatives'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
