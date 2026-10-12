import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/auth/about_you_page.dart';
import 'package:stationx/features/auth/register_page.dart';
import 'package:stationx/features/onboarding/schedule_setup_entry.dart';
import 'package:stationx/features/onboarding/schedule_setup_flow.dart';
import 'package:stationx/features/onboarding/setup_catalog.dart';
import 'package:stationx/features/onboarding/setup_week_step.dart';
import 'package:stationx/features/shell/main_shell.dart';
import 'package:stationx/features/today/today_page.dart';
import 'package:stationx/features/workouts/workouts_hub_page.dart';
import '../../helpers/online_fakes.dart';
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
          exercises: [
            RoutineExercise(
              exerciseId: 'bench_press',
              sets: 4,
              repMin: 6,
              repMax: 10,
            ),
          ],
        ),
        SplitDayPlan(
          name: 'Pull',
          muscles: [MuscleGroup.back],
          exercises: [RoutineExercise(exerciseId: 'pullup')],
        ),
      ],
    ),
  ],
  grouped: (m, all) {
    final list = all.where((e) => e.primaryMuscle == m).toList()
      ..sort(
        (a, b) => a.isCustom == b.isCustom
            ? a.name.compareTo(b.name)
            : (a.isCustom ? 1 : -1),
      );
    if (list.isEmpty) return const [];
    final built = list.where((e) => !e.isCustom).toList();
    final mine = list.where((e) => e.isCustom).toList();
    return [
      if (built.isNotEmpty)
        (
          section: SplitSection(
            id: 'all_${m.name}',
            label: '${m.label} basics',
            muscle: m,
          ),
          exercises: built,
        ),
      if (mine.isNotEmpty)
        (
          section: SplitSection(
            id: 'mine_${m.name}',
            label: 'Your exercises',
            muscle: m,
          ),
          exercises: mine,
        ),
    ];
  },
  reasonFor: (id) => id == 'bench_press' ? 'Fixture reason for bench.' : null,
  suggest: (m, all) => m == MuscleGroup.chest
      ? const [RoutineExercise(exerciseId: 'bench_press')]
      : const [],
);

Future<AppControllerLike> open(
  WidgetTester t, {
  bool afterSignup = true,
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  final app = await pumpPage(
    t,
    ScheduleSetupFlow(afterSignup: afterSignup, catalog: fixture()),
    demo: false,
    size: size,
    textScale: scale,
  );
  return app;
}

typedef AppControllerLike = dynamic;

/// Case-insensitive text finder (buttons and the top bar upper-case their labels).
Finder tx(String s) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').toLowerCase() == s.toLowerCase(),
);

/// Moves the "training days" stepper to [n] with its Increase/Decrease buttons.
Future<void> setTraining(WidgetTester t, int n, {required int from}) async {
  final label = n > from ? 'Increase training days' : 'Decrease training days';
  for (var i = 0; i < (n - from).abs(); i++) {
    await t.tap(find.bySemanticsLabel(label));
    await t.pumpAndSettle();
  }
}

/// Scrolls the lazy step list down until [text] is built (the day step now starts with a search box).
Future<void> revealText(WidgetTester t, String text) async {
  for (
    var i = 0;
    i < 30 &&
        tx(text).evaluate().isEmpty &&
        find.byType(ListView).evaluate().isNotEmpty;
    i++
  ) {
    await t.drag(find.byType(ListView).last, const Offset(0, -200));
    await t.pump();
  }
}

Future<void> tapText(WidgetTester t, String text, {bool last = false}) async {
  // The step bodies are lazy lists: scroll down until the label is built.
  for (
    var i = 0;
    i < 30 &&
        tx(text).evaluate().isEmpty &&
        find.byType(ListView).evaluate().isNotEmpty;
    i++
  ) {
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
  await tapText(t, 'Continue');
  await tapText(t, 'Continue'); // experience
}

/// Last day -> days-per-week step -> Review.
Future<void> toReview(WidgetTester t) async {
  await tapText(t, 'Next: your week');
  await tapText(t, 'Review');
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    // A tap that misses (e.g. button off-screen after scrolling) must fail, not just warn.
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('preset -> review -> save creates workouts and rotation', (
    t,
  ) async {
    final app = await open(t);
    expect(tx('Fixture Split'), findsOneWidget);
    await customizeFixture(t);
    expect(tx('Day 1 of 2'), findsOneWidget);
    await revealText(t, 'Fixture reason for bench.');
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

  testWidgets('custom flow: name days, pick muscles, add and remove days', (
    t,
  ) async {
    final app = await open(t);
    await tapText(t, 'Custom');
    await tapText(t, 'Continue');
    await tapText(t, 'Continue'); // experience
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
    expect(app.workouts.byId(ids.single)!.exercises.map((e) => e.exerciseId), [
      'bench_press',
    ]);
  });

  testWidgets(
    'day step: pinned coverage bar, search, equipment and ticked-only filters',
    (t) async {
      final app = await open(t);
      await customizeFixture(t);
      // Pinned coverage bar for the day's muscle, already "covered" by the pre-ticked bench press.
      expect(find.byKey(const ValueKey('dayCoverageBar')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Chest coverage')), findsOneWidget);

      // Search narrows the list; nonsense shows the empty hint.
      final search = find.byType(TextField).first;
      await t.enterText(search, 'zzzzqqq');
      await t.pump();
      expect(
        tx('Nothing matches. Clear the search or filters.'),
        findsOneWidget,
      );
      await t.enterText(search, 'bench');
      await t.pump();
      expect(tx('Barbell Bench Press'), findsOneWidget);

      // A search also reaches other muscles; ticking one adds that muscle to the day.
      await t.enterText(search, 'lat pulldown');
      await t.pump();
      await revealText(t, 'More results');
      expect(tx('More results'), findsOneWidget);
      await tapText(t, 'Lat Pulldown');
      expect(find.bySemanticsLabel(RegExp(r'^Back coverage')), findsOneWidget);

      // Ticked-only hides everything not ticked (scroll back up: the search box lives in the lazy list).
      for (var i = 0; i < 40; i++) {
        await t.drag(find.byType(ListView).last, const Offset(0, 600));
        await t.pump();
      }
      await t.enterText(find.byType(TextField).first, '');
      await t.pump();
      await t.tap(find.text('Ticked only'));
      await t.pumpAndSettle();
      expect(tx('Barbell Bench Press'), findsOneWidget);
      expect(tx('Incline Barbell Bench Press'), findsNothing);
      expect(app, isNotNull);
    },
  );

  testWidgets(
    'add exercise inside the flow ticks it immediately under Your exercises',
    (t) async {
      final app = await open(t);
      await customizeFixture(t);
      await tapText(t, 'Add chest exercise');
      await t.enterText(find.byType(TextField).last, 'Zebra Press');
      await t.pump();
      await tapText(t, 'Save exercise');
      expect(tx('Your exercises'), findsOneWidget);
      expect(tx('Zebra Press'), findsOneWidget);
      expect(
        app.exercises.all.any(
          (e) =>
              e.name == 'Zebra Press' && e.primaryMuscle == MuscleGroup.chest,
        ),
        isTrue,
      );
      await tapText(t, 'Next: Pull');
      await toReview(t);
      expect(tx('Zebra Press'), findsOneWidget);
    },
  );

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
    final rig = OnlineRig();
    final app = await pumpPage(t, const RegisterPage(), controller: rig.app);
    await app.init();
    await t.enterText(find.byType(TextField).first, 'Sam');
    await t.enterText(find.byType(TextField).last, 'Passw0rdX');
    await t.pump();
    final create = find.widgetWithText(SxButton, 'CREATE ACCOUNT');
    await t.scrollUntilVisible(
      create,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(create);
    await t.pumpAndSettle();
    expect(app.phase, SessionPhase.ready);
    expect(app.profile.profile.email, 'sam');
    expect(
      find.byType(AboutYouPage),
      findsOneWidget,
    ); // the sign-up flow gained "About you"
    await tapText(t, 'Skip for now');
    expect(find.byType(ScheduleSetupFlow), findsOneWidget);
    await tapText(t, 'Skip');
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('schedule prompt on Today (new account) is dismissible', (
    t,
  ) async {
    ScheduleSetupPrompt.dismissed.value = false;
    await pumpPage(t, const MainShell(), demo: false);
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

    testWidgets('no overflow in custom days at 320x568, text x$scale', (
      t,
    ) async {
      await open(t, size: const Size(320, 568), scale: scale);
      await tapText(t, 'Custom');
      await tapText(t, 'Continue');
      await tapText(t, 'Continue'); // experience
      await tapText(t, 'Add day');
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('real catalog: first preset is pre-ticked and saves', (t) async {
    final app = await pumpPage(
      t,
      const ScheduleSetupFlow(afterSignup: true),
      demo: false,
      size: const Size(390, 1200),
    );
    final presets = SetupCatalog().presets;
    expect(presets, isNotEmpty);
    await tapText(t, presets.first.name);
    await tapText(t, 'Customize exercises');
    await tapText(t, 'Continue');
    await tapText(t, 'Continue'); // experience
    for (var i = 0; i < presets.first.days.length - 1; i++) {
      await t.tap(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').toLowerCase().startsWith('next: '),
        ),
      );
      await t.pumpAndSettle();
    }
    await toReview(t);
    await tapText(t, 'Save schedule');
    expect(app.workouts.rotation.workoutIds.length, presets.first.days.length);
    for (final id in app.workouts.rotation.workoutIds) {
      expect(app.workouts.byId(id)!.exercises, isNotEmpty);
    }
  });

  testWidgets(
    'equipment step: bodyweight only fits a real preset and the choice is saved to the profile',
    (t) async {
      final app = await pumpPage(
        t,
        const ScheduleSetupFlow(afterSignup: true),
        demo: false,
        size: const Size(390, 1200),
      );
      expect(app.profile.profile.equipment, isNull);
      await tapText(t, 'Push / Pull / Legs');
      await tapText(t, 'Quick start');
      expect(tx('Your equipment').evaluate(), isNotEmpty);
      await tapText(t, 'Bodyweight only');
      await tapText(t, 'Continue');
      await tapText(t, 'Continue'); // experience (default intermediate)
      await tapText(t, 'Review');
      expect(
        find.textContaining('no close match for your equipment'),
        findsOneWidget,
      );
      await tapText(t, 'Save schedule');
      expect(app.profile.profile.equipment, isEmpty);
      final byId = {for (final e in app.exercises.all) e.id: e};
      var total = 0;
      for (final id in app.workouts.rotation.workoutIds) {
        for (final r in app.workouts.byId(id)!.exercises) {
          total++;
          expect(
            byId[r.exerciseId]!.equipment,
            Equipment.bodyweight,
            reason: r.exerciseId,
          );
        }
      }
      expect(total, greaterThan(6));
    },
  );

  testWidgets('equipment step: full gym keeps the curated preset exactly', (
    t,
  ) async {
    final app = await pumpPage(
      t,
      const ScheduleSetupFlow(afterSignup: true),
      demo: false,
      size: const Size(390, 1200),
    );
    final preset = SetupCatalog().presets.firstWhere((p) => p.id == 'ppl');
    await tapText(t, 'Push / Pull / Legs');
    await tapText(t, 'Quick start');
    await tapText(t, 'Continue'); // default = every item ticked
    await tapText(t, 'Continue'); // experience (default intermediate)
    await tapText(t, 'Review');
    await tapText(t, 'Save schedule');
    final saved = [
      for (final id in app.workouts.rotation.workoutIds)
        ...app.workouts.byId(id)!.exercises.map((r) => r.exerciseId),
    ];
    final curated = [
      for (final d in preset.days) ...d.exercises.map((r) => r.exerciseId),
    ];
    expect(saved.toSet(), curated.toSet());
  });

  testWidgets(
    'equipment step: going back and forward keeps edits unless the equipment changed',
    (t) async {
      await pumpPage(
        t,
        const ScheduleSetupFlow(afterSignup: true),
        demo: false,
        size: const Size(390, 1200),
      );
      await tapText(t, 'Full Body');
      await tapText(t, 'Customize exercises');
      await tapText(t, 'Continue');
      await tapText(t, 'Continue'); // experience
      expect(tx('Day 1 of 3'), findsOneWidget);
      await t.tap(find.byTooltip('Back'));
      await t.pumpAndSettle();
      expect(tx('Your experience').evaluate(), isNotEmpty);
      await tapText(t, 'Continue');
      expect(tx('Day 1 of 3'), findsOneWidget);
    },
  );

  group('experience step', () {
    testWidgets(
      'a beginner with bodyweight only never gets an advanced exercise when something easier exists',
      (t) async {
        final app = await pumpPage(
          t,
          const ScheduleSetupFlow(afterSignup: true),
          demo: false,
          size: const Size(390, 1200),
        );
        expect(app.profile.profile.experienceLevel, isNull);
        await tapText(t, 'Push / Pull / Legs');
        await tapText(t, 'Quick start');
        await tapText(t, 'Bodyweight only');
        await tapText(t, 'Continue');
        expect(tx('Your experience').evaluate(), isNotEmpty);
        await tapText(t, 'Beginner');
        await tapText(t, 'Continue');
        await tapText(t, 'Review');
        await tapText(t, 'Save schedule');
        expect(app.profile.profile.experienceLevel, Difficulty.beginner);
        final byId = {for (final e in app.exercises.all) e.id: e};
        for (final id in app.workouts.rotation.workoutIds) {
          for (final r in app.workouts.byId(id)!.exercises) {
            final e = byId[r.exerciseId]!;
            expect(e.equipment, Equipment.bodyweight, reason: e.name);
            expect(e.difficulty, isNot(Difficulty.advanced), reason: e.name);
          }
        }
        expect(
          app.workouts.rotation.workoutIds.every(
            (id) => app.workouts.byId(id)!.exercises.isNotEmpty,
          ),
          isTrue,
        );
      },
    );

    testWidgets('skipping the whole setup stores no experience level', (
      t,
    ) async {
      final app = await pumpPage(
        t,
        const ScheduleSetupFlow(afterSignup: true),
        demo: false,
        size: const Size(390, 1200),
      );
      await tapText(t, 'Skip');
      expect(app.profile.profile.experienceLevel, isNull);
      expect(app.profile.profile.effectiveExperience, Difficulty.intermediate);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('no overflow: experience step at 320x568, text x$scale', (
        t,
      ) async {
        await pumpPage(
          t,
          const ScheduleSetupFlow(afterSignup: true),
          demo: false,
          size: const Size(320, 568),
          textScale: scale,
        );
        await tapText(t, 'Push / Pull / Legs');
        await tapText(t, 'Quick start');
        await tapText(t, 'Continue');
        expect(tx('Your experience').evaluate(), isNotEmpty);
        expect(t.takeException(), isNull);
        await tapText(t, 'Advanced');
        expect(t.takeException(), isNull);
      });
    }
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('no overflow: equipment step at 320x568, text x$scale', (
      t,
    ) async {
      await pumpPage(
        t,
        const ScheduleSetupFlow(afterSignup: true),
        demo: false,
        size: const Size(320, 568),
        textScale: scale,
      );
      await tapText(t, 'Push / Pull / Legs');
      await tapText(t, 'Quick start');
      expect(tx('Your equipment').evaluate(), isNotEmpty);
      expect(t.takeException(), isNull);
      await tapText(t, 'Bodyweight only');
      expect(t.takeException(), isNull);
    });
  }

  group('a new account that skipped setup', () {
    testWidgets('Today shows the setup prompt and no invented workout', (
      t,
    ) async {
      final rig = await OnlineRig.signedIn('sam_1', false);
      await pumpPage(t, const TodayPage(), controller: rig.app, demo: false);
      await t.pumpAndSettle();
      expect(find.text('Set up your schedule'), findsOneWidget);
      expect(rig.app.workouts.workouts, isEmpty);
      expect(t.takeException(), isNull);
    });

    testWidgets('Workouts shows an empty state without errors', (t) async {
      final rig = await OnlineRig.signedIn('sam_1', false);
      await pumpPage(
        t,
        const WorkoutsHubPage(),
        controller: rig.app,
        demo: false,
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(rig.app.workouts.workouts, isEmpty);
    });
  });

  group('explicit regeneration', () {
    Future<AppControllerLike> pumpEntry(WidgetTester t) async {
      final rig = await OnlineRig.signedIn(
        'sam_1',
        false,
      ); // a brand-new account: no program yet
      final app = rig.app;
      return pumpPage(
        t,
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => startScheduleSetup(context),
              child: const Text('Regenerate'),
            ),
          ),
        ),
        demo: false,
        controller: app,
      );
    }

    testWidgets(
      'with a saved program it asks first; Cancel leaves the program untouched',
      (t) async {
        final app = await pumpEntry(t);
        await ScheduleBuilder.save(
          const [
            SplitDayPlan(
              name: 'Keep me',
              muscles: [MuscleGroup.chest],
              exercises: [RoutineExercise(exerciseId: 'bench_press')],
            ),
          ],
          workouts: app.workouts,
          catalog: app.exercises.all,
          stamp: 'old',
        );
        final before = app.workouts.rotation.workoutIds.toList();
        await t.tap(find.text('Regenerate'));
        await t.pumpAndSettle();
        expect(tx('Replace your rotation?'), findsOneWidget);
        expect(find.byType(ScheduleSetupFlow), findsNothing);
        await t.tap(tx('Cancel'));
        await t.pumpAndSettle();
        expect(find.byType(ScheduleSetupFlow), findsNothing);
        expect(app.workouts.rotation.workoutIds, before);
        expect(app.workouts.byId(before.single)!.name, 'Keep me');
      },
    );

    testWidgets(
      'confirming opens the setup but still saves nothing until the user saves',
      (t) async {
        final app = await pumpEntry(t);
        await ScheduleBuilder.save(
          const [
            SplitDayPlan(
              name: 'Keep me',
              muscles: [MuscleGroup.chest],
              exercises: [RoutineExercise(exerciseId: 'bench_press')],
            ),
          ],
          workouts: app.workouts,
          catalog: app.exercises.all,
          stamp: 'old',
        );
        final before = app.workouts.rotation.workoutIds.toList();
        await t.tap(find.text('Regenerate'));
        await t.pumpAndSettle();
        await t.tap(tx('Continue'));
        await t.pumpAndSettle();
        expect(find.byType(ScheduleSetupFlow), findsOneWidget);
        expect(app.workouts.rotation.workoutIds, before);
      },
    );

    testWidgets(
      'a brand-new account has no program: no confirmation, straight to the setup',
      (t) async {
        final app = await pumpEntry(t);
        expect(app.workouts.workouts, isEmpty);
        await t.tap(find.text('Regenerate'));
        await t.pumpAndSettle();
        expect(tx('Replace your rotation?'), findsNothing);
        expect(find.byType(ScheduleSetupFlow), findsOneWidget);
      },
    );
  });

  testWidgets(
    'pick step shows the five presets in the agreed order with Quick start',
    (t) async {
      final app = await pumpPage(
        t,
        const ScheduleSetupFlow(afterSignup: true),
        demo: false,
        size: const Size(390, 1600),
      );
      expect(app, isNotNull);
      final names = [
        'Full Body',
        'Upper / Lower',
        'Push / Pull / Legs',
        'Bro split',
        'Custom',
      ];
      double? last;
      for (final n in names) {
        final f = find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').toLowerCase() == n.toLowerCase(),
        );
        expect(f, findsWidgets, reason: n);
        final y = t.getTopLeft(f.first).dy;
        if (last != null) expect(y, greaterThan(last), reason: n);
        last = y;
      }
      await tapText(t, 'Full Body');
      expect(tx('Quick start'), findsOneWidget);
      expect(tx('Customize exercises'), findsOneWidget);
    },
  );

  testWidgets(
    'quick start: asks days per week, saves workouts and the weekly target',
    (t) async {
      final app = await open(t);
      await tapText(t, 'Fixture Split');
      await tapText(t, 'Quick start');
      await tapText(t, 'Continue');
      await tapText(t, 'Continue'); // experience
      expect(tx('Training and rest days'), findsOneWidget);
      expect(
        find.textContaining('continue with the next workout'),
        findsOneWidget,
      );
      expect(tx('Day 1 of 2'), findsNothing); // per-muscle ticking skipped
      await setTraining(t, 5, from: 2);
      expect(find.text('Rest days'), findsOneWidget);
      await tapText(t, 'Review');
      expect(tx('1. Push'), findsOneWidget);
      expect(
        find.textContaining('Week: 5 training days · 2 rest days'),
        findsOneWidget,
      );
      await tapText(t, 'Save schedule');
      expect(find.byType(MainShell), findsOneWidget);
      final ids = app.workouts.rotation.workoutIds;
      expect(ids.length, 2);
      expect(app.workouts.byId(ids.first)!.exercises.single.sets, 4);
      expect(app.profile.profile.weeklySessionTarget, 5);
    },
  );

  testWidgets(
    'week step: training and rest days stay linked and are saved as the weekly target',
    (t) async {
      final app = await open(t);
      await tapText(t, 'Fixture Split'); // default 2 training days
      await tapText(t, 'Quick start');
      await tapText(t, 'Continue');
      await tapText(t, 'Continue'); // experience
      expect(find.text('Training days'), findsOneWidget);
      expect(find.text('Rest days'), findsOneWidget);
      // Starts at 2 training / 5 rest; each extra rest day removes one training day.
      await t.tap(find.bySemanticsLabel('Increase rest days'));
      await t.pumpAndSettle();
      await tapText(t, 'Review');
      expect(
        find.textContaining('Week: 1 training day · 6 rest days'),
        findsOneWidget,
      );
      await tapText(t, 'Save schedule');
      expect(app.profile.profile.weeklySessionTarget, 1);
    },
  );

  testWidgets('quick start default days comes from the preset text', (t) async {
    final app = await open(t);
    await tapText(t, 'Fixture Split'); // "2 days / week"
    await tapText(t, 'Quick start');
    await tapText(t, 'Continue');
    await tapText(t, 'Continue'); // experience
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

  testWidgets('customize path also asks days per week before review', (
    t,
  ) async {
    final app = await open(t);
    await customizeFixture(t);
    await tapText(t, 'Next: Pull');
    await tapText(t, 'Next: your week');
    expect(tx('Training and rest days'), findsOneWidget);
    await setTraining(t, 3, from: 2);
    await tapText(t, 'Review');
    await tapText(t, 'Save schedule');
    expect(app.profile.profile.weeklySessionTarget, 3);
    expect(app.workouts.rotation.workoutIds.length, 2);
  });

  testWidgets('quick start review can still edit a day', (t) async {
    await open(t);
    await tapText(t, 'Fixture Split');
    await tapText(t, 'Quick start');
    await tapText(t, 'Continue');
    await tapText(t, 'Continue'); // experience
    await tapText(t, 'Review');
    await t.tap(find.bySemanticsLabel('Edit day 2'));
    await t.pumpAndSettle();
    expect(tx('Day 2 of 2'), findsOneWidget);
  });

  testWidgets('custom has no Quick start but asks days per week', (t) async {
    final app = await open(t);
    await tapText(t, 'Custom');
    await tapText(t, 'Continue');
    await tapText(t, 'Continue'); // experience
    expect(tx('Quick start'), findsNothing);
    await tapText(t, 'Chest');
    await tapText(t, 'Continue');
    await tapText(t, 'Next: your week');
    expect(tx('Training and rest days'), findsOneWidget);
    await setTraining(t, 6, from: 3);
    await tapText(t, 'Review');
    await tapText(t, 'Save schedule');
    expect(app.profile.profile.weeklySessionTarget, 6);
  });

  testWidgets('replace flow keeps old workouts (archived) and their history', (
    t,
  ) async {
    final app = await pumpPage(
      t,
      const ScheduleSetupFlow(afterSignup: true, catalog: null),
      demo: false,
    );
    await ScheduleBuilder.save(
      const [
        SplitDayPlan(
          name: 'Old A',
          muscles: [MuscleGroup.chest],
          exercises: [RoutineExercise(exerciseId: 'bench_press')],
        ),
      ],
      workouts: app.workouts,
      sessions: app.sessions,
      catalog: app.exercises.all,
      stamp: 'old',
    );
    await app.sessions.add(
      WorkoutSession(
        id: 's1',
        workoutId: 'w_old_0',
        name: 'Old A',
        workoutDate: DateTime.now(),
        exercises: const [
          ExerciseLog(
            exerciseId: 'bench_press',
            sets: [SetLog(weightKg: 60, reps: 8)],
          ),
        ],
      ),
    );
    final before = app.workouts.workouts.length;
    await tapText(t, 'Full Body');
    await tapText(t, 'Quick start');
    await tapText(t, 'Continue');
    await tapText(t, 'Continue'); // experience
    await tapText(t, 'Review');
    await tapText(t, 'Save schedule');
    expect(app.workouts.workouts.length, greaterThan(before));
    expect(app.workouts.byId('w_old_0'), isNotNull);
    expect(app.workouts.rotation.workoutIds.contains('w_old_0'), isFalse);
    expect(app.sessions.sessions.single.workoutId, 'w_old_0');
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'no overflow: pick actions, week step, quick review at 320x568, text x$scale',
      (t) async {
        await open(t, size: const Size(320, 568), scale: scale);
        await tapText(t, 'Fixture Split');
        expect(t.takeException(), isNull);
        await tapText(t, 'Quick start');
        await tapText(t, 'Continue');
        await tapText(t, 'Continue'); // experience
        expect(tx('Training and rest days'), findsOneWidget);
        expect(t.takeException(), isNull);
        await tapText(t, 'Review');
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'no overflow: real catalog day step with secondary tags at 320x568, text x$scale',
      (t) async {
        await pumpPage(
          t,
          const ScheduleSetupFlow(afterSignup: true),
          demo: false,
          size: const Size(320, 568),
          textScale: scale,
        );
        await tapText(t, 'Push / Pull / Legs');
        await tapText(t, 'Customize exercises');
        await tapText(t, 'Continue');
        await tapText(t, 'Continue'); // experience
        expect(t.takeException(), isNull);
        expect(
          find.textContaining(
            'Main exercises first, then the separate parts of each muscle',
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      },
    );
  }
}
