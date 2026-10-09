import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/onboarding/schedule_setup_flow.dart';
import 'package:stationx/features/onboarding/setup_catalog.dart';
import '../../helpers/pump.dart';
import 'schedule_setup_test.dart' as sb show tapText;

Finder tx(String s) => find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toLowerCase() == s.toLowerCase());

/// Scrolls (top first, then down) until [text] is built.
Future<void> reveal(WidgetTester t, String text) async {
  if (tx(text).evaluate().isNotEmpty) return;
  for (var i = 0; i < 40 && find.byType(ListView).evaluate().isNotEmpty; i++) {
    await t.drag(find.byType(ListView).last, const Offset(0, 600));
    await t.pump();
  }
  for (var i = 0; i < 200 && tx(text).evaluate().isEmpty; i++) {
    await t.drag(find.byType(ListView).last, const Offset(0, -200));
    await t.pump();
  }
}

Future<void> tapText(WidgetTester t, String text) async {
  await reveal(t, text);
  await sb.tapText(t, text);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);

  Future<List<Exercise>> catalog(WidgetTester t) async => (await pumpPage(t, const SizedBox(), demo: false)).exercises.all;

  testWidgets('picker groups: chest main first, then upper, lower, flyes', (t) async {
    final all = await catalog(t);
    final g = SetupCatalog().groupedSection(SectionMuscle.chest, all);
    expect(g.first.label, isNull);
    final labels = [for (final x in g) x.label];
    expect(labels.whereType<String>().toList(), ['Upper chest', 'Lower chest', 'Flyes & isolation']);
    expect(g.first.exercises, isNotEmpty);
  });

  testWidgets('picker groups: back is ONE section, lats + upper back main, then traps, lower back', (t) async {
    final all = await catalog(t);
    final c = SetupCatalog();
    final g = c.groupedSection(SectionMuscle.back, all);
    expect(g.where((x) => x.label == null).length, 1);
    expect(g.first.label, isNull);
    expect(g.map((x) => x.label).whereType<String>().toList(), ['Traps', 'Lower back']);
    final mainIds = g.first.exercises.map((e) => e.id).toSet();
    expect(mainIds.contains('pullup'), isTrue);
  });

  testWidgets('forearms: a picker section, may be sparse, never crashes', (t) async {
    final all = await catalog(t);
    final c = SetupCatalog();
    expect(() => c.suggestSection(SectionMuscle.forearms, all), returnsNormally);
    for (final x in c.groupedSection(SectionMuscle.forearms, all)) {
      expect(x.label, isNull, reason: 'forearm exercises are all main');
    }
    expect(SplitDayPlan(name: 'x', sectionMuscles: const [SectionMuscle.forearms, SectionMuscle.biceps]).muscles, [MuscleGroup.biceps]);
    expect(const SplitDayPlan(name: 'x', muscles: [MuscleGroup.legs]).sectionMuscles, [SectionMuscle.legs]);
  });

  testWidgets('presets map to section muscles', (t) async {
    for (final p in SplitCatalog.presets) {
      for (final d in p.days) {
        expect(d.sectionMuscles, isNotEmpty, reason: '${p.name} ${d.name}');
        expect(d.sectionMuscles.length, d.muscles.length);
      }
    }
  });

  testWidgets('custom day: Forearms chip is selectable and its section is listed', (t) async {
    await pumpPage(t, const ScheduleSetupFlow(afterSignup: true), demo: false);
    await tapText(t, 'Custom');
    expect(tx('Forearms'), findsOneWidget);
    await tapText(t, 'Forearms');
    await tapText(t, 'Chest');
    await tapText(t, 'Continue');
    expect(tx('Forearms'), findsWidgets); // section header (2 muscles)
    await reveal(t, 'Add forearms exercise');
    expect(tx('Add forearms exercise'), findsOneWidget);
    await reveal(t, 'Add chest exercise');
    expect(tx('Add chest exercise'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('day step: chest rows read main -> upper -> lower -> flyes, then save is canonical in any tap order', (t) async {
    final app = await pumpPage(t, const ScheduleSetupFlow(afterSignup: true), demo: false);
    final all = app.exercises.all;
    await tapText(t, 'Custom');
    await tapText(t, 'Chest');
    await tapText(t, 'Back');
    await tapText(t, 'Continue');
    // Section headers (>= 2 muscles) and sub-headers in canonical order.
    for (final h in ['Chest', 'Upper chest', 'Lower chest', 'Flyes & isolation', 'Back', 'Traps', 'Lower back']) {
      await reveal(t, h);
      expect(tx(h), findsWidgets, reason: h);
    }
    // Tick in reverse canonical order: a flye, a lower-chest move, a traps move.
    final groups = SetupCatalog().groupedSection(SectionMuscle.chest, all);
    final fly = groups.last.exercises.first;
    final lower = groups.firstWhere((g) => g.label == 'Lower chest').exercises.first;
    final back = SetupCatalog().groupedSection(SectionMuscle.back, all);
    final traps = back.firstWhere((g) => g.label == 'Traps').exercises.first;
    await tapText(t, fly.name);
    await tapText(t, traps.name);
    await tapText(t, lower.name);
    await tapText(t, 'Next: days per week');
    await tapText(t, 'Review');
    expect(find.textContaining('CHEST', skipOffstage: false), findsWidgets);
    await tapText(t, 'Save schedule');
    final w = app.workouts.byId(app.workouts.rotation.workoutIds.first)!;
    expect(WorkoutSections.isArranged(w.exercises, all), isTrue);
    final ids = w.exercises.map((e) => e.exerciseId).toList();
    expect(ids.indexOf(lower.id), lessThan(ids.indexOf(fly.id)));
    expect(ids.indexOf(fly.id), lessThan(ids.indexOf(traps.id)));
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('no overflow: custom, day (2 muscles), review at 320x568, text x$scale', (t) async {
      await pumpPage(t, const ScheduleSetupFlow(afterSignup: true), demo: false, size: const Size(320, 568), textScale: scale);
      for (var i = 0; i < 6; i++) {
        await t.drag(find.byType(ListView).last, const Offset(0, -150));
        await t.pump();
      }
      await tapText(t, 'Custom');
      expect(t.takeException(), isNull);
      await tapText(t, 'Forearms');
      await tapText(t, 'Legs');
      await tapText(t, 'Continue');
      expect(t.takeException(), isNull);
      await tapText(t, 'Next: days per week');
      await tapText(t, 'Review');
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('reduced motion: flow still works', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpPage(t, const ScheduleSetupFlow(afterSignup: true), demo: false);
    await tapText(t, 'Custom');
    await tapText(t, 'Chest');
    await tapText(t, 'Continue');
    await reveal(t, 'Add chest exercise');
    expect(tx('Add chest exercise'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
