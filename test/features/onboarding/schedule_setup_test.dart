import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/auth/register_page.dart';
import 'package:stationx/features/onboarding/schedule_setup_entry.dart';
import 'package:stationx/features/onboarding/schedule_setup_flow.dart';
import 'package:stationx/features/onboarding/setup_catalog.dart';
import 'package:stationx/features/onboarding/setup_week_step.dart';
import 'package:stationx/features/shell/main_shell.dart';
import '../../helpers/pump.dart';

SetupCatalog fixture() => SetupCatalog(
      presets: const [
        SplitPreset(
          id: 'fx',
          name: 'Fixture Split',
          blurb: 'Two test days.',
          suggestedDaysPerWeek: '2 days / week',
          days: [
            SplitDayPlan(
              name: 'Push',
              muscles: [MuscleGroup.chest],
              exercises: [RoutineExercise(exerciseId: 'bench_press', sets: 4, repMin: 6, repMax: 10)],
            ),
            SplitDayPlan(name: 'Pull', muscles: [MuscleGroup.back], exercises: [RoutineExercise(exerciseId: 'pullup')]),
          ],
        ),
      ],
      grouped: (m, all) {
        final list = all.where((e) => e.primaryMuscle == m).toList()..sort((a, b) => a.isCustom == b.isCustom ? a.name.compareTo(b.name) : (a.isCustom ? 1 : -1));
        if (list.isEmpty) return const [];
        final built = list.where((e) => !e.isCustom).toList();
        final mine = list.where((e) => e.isCustom).toList();
        return [
          if (built.isNotEmpty) (section: SplitSection(id: 'all_${m.name}', label: '${m.label} basics', muscle: m), exercises: built),
          if (mine.isNotEmpty) (section: SplitSection(id: 'mine_${m.name}', label: 'Your exercises', muscle: m), exercises: mine),
        ];
      },
      reasonFor: (id) => id == 'bench_press' ? 'Fixture reason for bench.' : null,
      suggest: (m, all) => m == MuscleGroup.chest ? const [RoutineExercise(exerciseId: 'bench_press')] : const [],
    );

Future<AppControllerLike> open(WidgetTester t, {bool afterSignup = true, Size size = const Size(390, 844), double scale = 1}) async {
  final app = await pumpPage(t, ScheduleSetupFlow(afterSignup: afterSignup, catalog: fixture()), demo: false, size: size, textScale: scale);
  return app;
}

typedef AppControllerLike = dynamic;

/// Case-insensitive text finder (buttons and the top bar upper-case their labels).
Finder tx(String s) => find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toLowerCase() == s.toLowerCase());

Future<void> tapText(WidgetTester t, String text, {bool last = false}) async {
  // The step bodies are lazy lists: scroll down until the label is built.
  for (var i = 0; i < 30 && tx(text).evaluate().isEmpty && find.byType(ListView).evaluate().isNotEmpty; i++) {
    await t.drag(find.byType(ListView).last, const Offset(0, -200));
    await t.pump();
  }
  final f = last ? tx(text).last : tx(text).first;
  await t.ensureVisible(f);
  // ensureVisible jumps the scroll offset but does not pump: lazy lists re-estimate their extent on the next frame.
  await t.pump();
  await t.tap(f);
  await t.pumpAndSettle();
}

/// Picks the fixture preset and takes the detailed per-day path.
Future<void> customizeFixture(WidgetTester t) async {
  await tapText(t, 'Fixture Split');
  await tapText(t, 'Customize exercises');
}

/// Last day -> days-per-week step -> Review.
Future<void> toReview(WidgetTester t) async {
  await tapText(t, 'Next: days per week');
  await tapText(t, 'Review');
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    // A tap that misses (e.g. button off-screen after scrolling) must fail, not just warn.
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('preset -> review -> save creates workouts and rotation', (t) async {
    final app = await open(t);
    expect(tx('Fixture Split'), findsOneWidget);
    await customizeFixture(t);
    expect(tx('Day 1 of 2'), findsOneWidget);
    expect(tx('Fixture reason for bench.'), findsOneWidget);
    // preset pick is pre-ticked with its sets
    expect(tx('4'), findsOneWidget);
    await tapText(t, 'Next: Pull');
    await toReview(t);
    expect(tx('Review'), findsWidgets);
    expect(tx('1. Push'), findsOneWidget);
    await tapText(t, 'Save schedule');
    expect(find.byType(MainShell), findsOneWidget);
    final rot = app.workouts.rotation;
    expect(rot.workoutIds.length, 2);
    final w = app.workouts.byId(rot.workoutIds.first)!;
    expect(w.name, 'Push');
    expect(w.exercises.single.sets, 4);
    expect(rot.currentIndex, 0);
  });

  testWidgets('custom flow: name days, pick muscles, add and remove days', (t) async {
    final app = await open(t);
    await tapText(t, 'Custom');
    expect(tx('Your days'), findsOneWidget);
    expect(tx('Choose at least one muscle for "Day 1".'), findsOneWidget);
    await t.enterText(find.byType(TextField).first, 'Chest day');
    await t.pump();
    await tapText(t, 'Chest');
    await tapText(t, 'Add day');
    expect(tx('DAY 2'), findsOneWidget);
    await t.tap(find.byTooltip('Remove day 2'));
    await t.pumpAndSettle();
    expect(tx('DAY 2'), findsNothing);
    await tapText(t, 'Continue');
    expect(tx('Day 1 of 1'), findsOneWidget);
    await toReview(t);
    await tapText(t, 'Save schedule');
    final ids = app.workouts.rotation.workoutIds;
    expect(ids.length, 1);
    expect(app.workouts.byId(ids.single)!.name, 'Chest day');
    expect(app.workouts.byId(ids.single)!.exercises.map((e) => e.exerciseId), ['bench_press']);
  });

  testWidgets('add exercise inside the flow ticks it immediately under Your exercises', (t) async {
    final app = await open(t);
    await customizeFixture(t);
    await tapText(t, 'Add chest exercise');
    await t.enterText(find.byType(TextField).last, 'Zebra Press');
    await t.pump();
    await tapText(t, 'Save exercise');
    expect(tx('Your exercises'), findsOneWidget);
    expect(tx('Zebra Press'), findsOneWidget);
    expect(app.exercises.all.any((e) => e.name == 'Zebra Press' && e.primaryMuscle == MuscleGroup.chest), isTrue);
    await tapText(t, 'Next: Pull');
    await toReview(t);
    expect(tx('Zebra Press'), findsOneWidget);
  });

  testWidgets('skip on the first step enters the app', (t) async {
    await open(t);
    await tapText(t, 'Skip');
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('skip midway asks before discarding', (t) async {
    await open(t);
    await customizeFixture(t);
    await tapText(t, 'Skip');
    expect(tx('Discard this schedule?'), findsOneWidget);
    await tapText(t, 'Keep editing');
    expect(tx('Day 1 of 2'), findsOneWidget);
    await tapText(t, 'Skip');
    await tapText(t, 'Discard');
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('validation: a day without exercises blocks saving', (t) async {
    final app = await open(t);
    final before = app.workouts.workouts.length;
    await customizeFixture(t);
    await tapText(t, 'Barbell Bench Press'); // untick the only pick
    expect(tx('Tick at least one exercise for this day.'), findsOneWidget);
    await tapText(t, 'Next: Pull');
    await toReview(t);
    expect(tx('"Push" has no exercises.'), findsOneWidget);
    final save = t.widget<SxButton>(find.byType(SxButton).last);
    expect(save.onPressed, isNull);
    expect(app.workouts.workouts.length, before);
  });

  testWidgets('register -> setup flow -> skip enters the app', (t) async {
    final app = await pumpPage(t, const RegisterPage(), demo: false);
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), 'Sam');
    await t.enterText(fields.at(1), 'sam@mail.com');
    await t.pump();
    final create = find.widgetWithIcon(SxButton, Icons.arrow_forward);
    await t.scrollUntilVisible(create, 200, scrollable: find.byType(Scrollable).first);
    await t.tap(create);
    await t.pumpAndSettle();
    expect(app.hasLocalAccount, isTrue);
    expect(find.byType(ScheduleSetupFlow), findsOneWidget);
    await tapText(t, 'Skip');
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('guest prompt on Today is dismissible', (t) async {
    ScheduleSetupPrompt.dismissed.value = false;
    final app = await pumpPage(t, const MainShell(), demo: false);
    await app.startGuest();
    await t.pumpAndSettle();
    expect(tx('Set up your schedule'), findsOneWidget);
    await t.tap(find.byTooltip('Dismiss'));
    await t.pumpAndSettle();
    expect(tx('Set up your schedule'), findsNothing);
    ScheduleSetupPrompt.dismissed.value = false;
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('no overflow at 320x568, text x$scale, every step', (t) async {
      await open(t, size: const Size(320, 568), scale: scale);
      expect(t.takeException(), isNull);
      await customizeFixture(t);
      expect(t.takeException(), isNull);
      await tapText(t, 'Next: Pull');
      await toReview(t);
      expect(t.takeException(), isNull);
    });

    testWidgets('no overflow in custom days at 320x568, text x$scale', (t) async {
      await open(t, size: const Size(320, 568), scale: scale);
      await tapText(t, 'Custom');
      await tapText(t, 'Add day');
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('real catalog: first preset is pre-ticked and saves', (t) async {
    final app = await pumpPage(t, const ScheduleSetupFlow(afterSignup: true), demo: false, size: const Size(390, 1200));
    final presets = SetupCatalog().presets;
    expect(presets, isNotEmpty);
    await tapText(t, presets.first.name);
    await tapText(t, 'Customize exercises');
    for (var i = 0; i < presets.first.days.length - 1; i++) {
      await t.tap(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toLowerCase().startsWith('next: ')));
      await t.pumpAndSettle();
    }
    await toReview(t);
    await tapText(t, 'Save schedule');
    expect(app.workouts.rotation.workoutIds.length, presets.first.days.length);
    for (final id in app.workouts.rotation.workoutIds) {
      expect(app.workouts.byId(id)!.exercises, isNotEmpty);
    }
  });

  testWidgets('pick step shows the five presets in the agreed order with Quick start', (t) async {
    final app = await pumpPage(t, const ScheduleSetupFlow(afterSignup: true), demo: false, size: const Size(390, 1600));
    expect(app, isNotNull);
    final names = ['Full Body', 'Upper / Lower', 'Push / Pull / Legs', 'Bro split', 'Custom'];
    double? last;
    for (final n in names) {
      final f = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toLowerCase() == n.toLowerCase());
      expect(f, findsWidgets, reason: n);
      final y = t.getTopLeft(f.first).dy;
      if (last != null) expect(y, greaterThan(last), reason: n);
      last = y;
    }
    await tapText(t, 'Full Body');
    expect(tx('Quick start'), findsOneWidget);
    expect(tx('Customize exercises'), findsOneWidget);
  });

  testWidgets('quick start: asks days per week, saves workouts and the weekly target', (t) async {
    final app = await open(t);
    await tapText(t, 'Fixture Split');
    await tapText(t, 'Quick start');
    expect(tx('How many days a week?'), findsOneWidget);
    expect(find.textContaining('continue with the next workout'), findsOneWidget);
    expect(tx('Day 1 of 2'), findsNothing); // per-muscle ticking skipped
    await tapText(t, '5');
    await tapText(t, 'Review');
    expect(tx('1. Push'), findsOneWidget);
    expect(find.textContaining('Goal: 5 days a week'), findsOneWidget);
    await tapText(t, 'Save schedule');
    expect(find.byType(MainShell), findsOneWidget);
    final ids = app.workouts.rotation.workoutIds;
    expect(ids.length, 2);
    expect(app.workouts.byId(ids.first)!.exercises.single.sets, 4);
    expect(app.profile.profile.weeklySessionTarget, 5);
  });

  testWidgets('quick start default days comes from the preset text', (t) async {
    final app = await open(t);
    await tapText(t, 'Fixture Split'); // "2 days / week"
    await tapText(t, 'Quick start');
    await tapText(t, 'Review');
    await tapText(t, 'Save schedule');
    expect(app.profile.profile.weeklySessionTarget, 2);
  });

  test('defaultDaysPerWeek parses text', () {
    expect(defaultDaysPerWeek('3–6 days / week', dayCount: 3), 5);
    expect(defaultDaysPerWeek('2–4 days / week', dayCount: 4), 3);
    expect(defaultDaysPerWeek('5 days / week', dayCount: 5), 5);
    expect(defaultDaysPerWeek('', dayCount: 1), 3);
    expect(defaultDaysPerWeek('', dayCount: 9), 4);
  });

  testWidgets('customize path also asks days per week before review', (t) async {
    final app = await open(t);
    await customizeFixture(t);
    await tapText(t, 'Next: Pull');
    await tapText(t, 'Next: days per week');
    expect(tx('How many days a week?'), findsOneWidget);
    await tapText(t, '3');
    await tapText(t, 'Review');
    await tapText(t, 'Save schedule');
    expect(app.profile.profile.weeklySessionTarget, 3);
    expect(app.workouts.rotation.workoutIds.length, 2);
  });

  testWidgets('quick start review can still edit a day', (t) async {
    await open(t);
    await tapText(t, 'Fixture Split');
    await tapText(t, 'Quick start');
    await tapText(t, 'Review');
    await t.tap(find.bySemanticsLabel('Edit day 2'));
    await t.pumpAndSettle();
    expect(tx('Day 2 of 2'), findsOneWidget);
  });

  testWidgets('custom has no Quick start but asks days per week', (t) async {
    final app = await open(t);
    await tapText(t, 'Custom');
    expect(tx('Quick start'), findsNothing);
    await tapText(t, 'Chest');
    await tapText(t, 'Continue');
    await tapText(t, 'Next: days per week');
    expect(tx('How many days a week?'), findsOneWidget);
    await tapText(t, '6');
    await tapText(t, 'Review');
    await tapText(t, 'Save schedule');
    expect(app.profile.profile.weeklySessionTarget, 6);
  });

  testWidgets('replace flow keeps old workouts (archived) and their history', (t) async {
    final app = await pumpPage(t, const ScheduleSetupFlow(afterSignup: true, catalog: null), demo: false);
    await ScheduleBuilder.save(
      const [SplitDayPlan(name: 'Old A', muscles: [MuscleGroup.chest], exercises: [RoutineExercise(exerciseId: 'bench_press')])],
      workouts: app.workouts,
      sessions: app.sessions,
      catalog: app.exercises.all,
      stamp: 'old',
    );
    await app.sessions.add(WorkoutSession(
      id: 's1',
      workoutId: 'w_old_0',
      name: 'Old A',
      workoutDate: DateTime.now(),
      exercises: const [ExerciseLog(exerciseId: 'bench_press', sets: [SetLog(weightKg: 60, reps: 8)])],
    ));
    final before = app.workouts.workouts.length;
    await tapText(t, 'Full Body');
    await tapText(t, 'Quick start');
    await tapText(t, 'Review');
    await tapText(t, 'Save schedule');
    expect(app.workouts.workouts.length, greaterThan(before));
    expect(app.workouts.byId('w_old_0'), isNotNull);
    expect(app.workouts.rotation.workoutIds.contains('w_old_0'), isFalse);
    expect(app.sessions.sessions.single.workoutId, 'w_old_0');
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('no overflow: pick actions, week step, quick review at 320x568, text x$scale', (t) async {
      await open(t, size: const Size(320, 568), scale: scale);
      await tapText(t, 'Fixture Split');
      expect(t.takeException(), isNull);
      await tapText(t, 'Quick start');
      expect(tx('How many days a week?'), findsOneWidget);
      expect(t.takeException(), isNull);
      await tapText(t, 'Review');
      expect(t.takeException(), isNull);
    });

    testWidgets('no overflow: real catalog day step with secondary tags at 320x568, text x$scale', (t) async {
      await pumpPage(t, const ScheduleSetupFlow(afterSignup: true), demo: false, size: const Size(320, 568), textScale: scale);
      await tapText(t, 'Push / Pull / Legs');
      await tapText(t, 'Customize exercises');
      expect(t.takeException(), isNull);
      expect(find.textContaining('Grouped by how people usually train it', skipOffstage: false), findsOneWidget);
    });
  }
}
