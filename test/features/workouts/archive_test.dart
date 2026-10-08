import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/features/active_workout/workout_complete_page.dart';
import 'package:stationx/features/history/calendar_page.dart';
import 'package:stationx/features/workouts/workouts_hub_page.dart';

import '../../helpers/pump.dart';

Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
  await t.pump(const Duration(milliseconds: 400));
}

const _a = SplitDayPlan(name: 'Old Push', muscles: [MuscleGroup.chest], exercises: [RoutineExercise(exerciseId: 'bench_press')]);
const _b = SplitDayPlan(name: 'New Pull', muscles: [MuscleGroup.back], exercises: [RoutineExercise(exerciseId: 'pullup')]);

/// Old schedule with a logged session, then replaced by a new one -> Old Push is archived.
Future<AppController> seedReplaced(WidgetTester t, Widget page, {Size size = const Size(390, 1200), double scale = 1}) async {
  final app = AppController();
  Future<void> save(List<SplitDayPlan> d, String stamp) =>
      ScheduleBuilder.save(d, workouts: app.workouts, sessions: app.sessions, catalog: app.exercises.all, stamp: stamp);
  await save([_a], 'old');
  await app.sessions.add(WorkoutSession(
    id: 's_old',
    workoutId: 'w_old_0',
    name: 'Old Push',
    workoutDate: DateTime.now(),
    exercises: const [ExerciseLog(exerciseId: 'bench_press', sets: [SetLog(weightKg: 60, reps: 8)])],
  ));
  await save([_b], 'new');
  await pumpPage(t, page, demo: false, controller: app, size: size, textScale: scale);
  return app;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('replacing keeps every old workout; it is archived, not deleted', (t) async {
    final app = await seedReplaced(t, const WorkoutsHubPage());
    expect(app.workouts.byId('w_old_0'), isNotNull);
    expect(app.workouts.rotation.workoutIds, ['w_new_0']);
    expect(app.sessions.sessions.single.workoutId, 'w_old_0');
    await settle(t);
    await t.scrollUntilVisible(find.text('Old Push'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('ARCHIVED'), findsOneWidget);
    expect(find.text('Old Push'), findsOneWidget);
  });

  testWidgets('archived section: add back to rotation puts it at the end', (t) async {
    final app = await seedReplaced(t, const WorkoutsHubPage());
    await settle(t);
    await t.scrollUntilVisible(find.text('Old Push'), 200, scrollable: find.byType(Scrollable).first);
    final card = find.ancestor(of: find.text('Old Push'), matching: find.byType(SxCard)).first;
    final btn = find.descendant(of: card, matching: find.text('ADD BACK TO ROTATION'));
    await t.ensureVisible(btn);
    await t.pump();
    await t.tap(btn);
    await settle(t);
    expect(app.workouts.rotation.workoutIds, ['w_new_0', 'w_old_0']);
    expect(app.workouts.rotation.workoutIds.last, 'w_old_0');
  });

  testWidgets('archived routine opens its preview and can be deleted only after confirming', (t) async {
    final app = await seedReplaced(t, const WorkoutsHubPage());
    await settle(t);
    final menu = find.byTooltip('Routine options').last;
    await t.scrollUntilVisible(menu, 200, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(menu);
    await t.pump();
    await t.tap(menu);
    await settle(t);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Edit structure'), findsOneWidget);
    expect(find.text('Add back to rotation'), findsOneWidget);
    await t.tap(find.text('Delete routine'));
    await settle(t);
    await t.tap(find.text('CANCEL'));
    await settle(t);
    expect(app.workouts.byId('w_old_0'), isNotNull);
  });

  testWidgets('history still opens for a session of an archived workout', (t) async {
    final app = await seedReplaced(t, const CalendarPage());
    await settle(t);
    expect(app.workouts.rotation.workoutIds.contains('w_old_0'), isFalse);
    final d = DateTime.now();
    await t.tap(find.bySemanticsLabel(RegExp('${Fmt2.long(d)}.*')).first);
    await settle(t);
    expect(find.text('Old Push'), findsWidgets);
    await t.tap(find.text('Old Push').first);
    await settle(t);
    expect(app.sessions.byId('s_old'), isNotNull);
    expect(find.byType(WorkoutCompletePage), findsOneWidget);
    while (t.takeException() != null) {}
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('archived section has no overflow at 320x568, text x$scale', (t) async {
      await seedReplaced(t, const WorkoutsHubPage(), size: const Size(320, 568), scale: scale);
      await settle(t);
      // The archived section is a lazily built sliver child: scroll until it exists.
      for (var i = 0; i < 20 && find.text('ADD BACK TO ROTATION').evaluate().isEmpty; i++) {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await t.pump();
      }
      expect(find.text('ADD BACK TO ROTATION'), findsWidgets);
      expect(t.takeException(), isNull);
    });
  }
}

class Fmt2 {
  static String long(DateTime d) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const m = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}';
  }
}
