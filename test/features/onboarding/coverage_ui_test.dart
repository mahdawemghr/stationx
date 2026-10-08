import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/onboarding/setup_coverage.dart';
import 'package:stationx/features/onboarding/setup_review_step.dart';

import '../../helpers/pump.dart';

RoutineExercise re(String id, [int sets = 4]) => RoutineExercise(exerciseId: id, sets: sets, repMin: 6, repMax: 10);

void main() {
  setUpAll(loadAppFonts);

  final days = [
    SplitDayPlan(name: 'Push', muscles: const [MuscleGroup.chest], exercises: [re('bench_press'), re('bench_press', 4)]),
    SplitDayPlan(name: 'Pull', muscles: const [MuscleGroup.back], exercises: [re('lat_pulldown')]),
  ];

  Future<void> mount(WidgetTester t, {Size size = const Size(390, 844), double scale = 1}) async {
    final all = AppController().exercises.all;
    await pumpPage(
      t,
      Scaffold(body: SetupReviewStep(days: days, all: all, error: null, onEdit: (_) {}, perWeek: 4)),
      size: size,
      textScale: scale,
    );
  }

  testWidgets('review shows a collapsible coverage summary', (t) async {
    await mount(t);
    expect(find.text('Muscle coverage'), findsOneWidget);
    expect(find.text('Chest'), findsNothing); // collapsed: bars hidden
    await t.tap(find.text('Muscle coverage'));
    await t.pump();
    expect(find.text('Chest'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Chest coverage (high|moderate|low)')), findsOneWidget);
    // Regions with no work are hidden.
    expect(find.text('Calves'), findsNothing);
    expect(find.textContaining('Optional:'), findsWidgets);
    await t.tap(find.text('Muscle coverage'));
    await t.pump();
    expect(find.text('Chest'), findsNothing);
  });

  testWidgets('no overflow at 320x568 text x1.3, expanded', (t) async {
    await mount(t, size: const Size(320, 568), scale: 1.3);
    await t.tap(find.text('Muscle coverage'));
    await t.pump();
    expect(t.takeException(), isNull);
  });

  test('dayCoverageHint is calm and null when empty', () {
    final all = AppController().exercises.all;
    expect(dayCoverageHint(const SplitDayPlan(name: 'x', muscles: []), all), isNull);
    expect(dayCoverageHint(days.first, all), contains('Chest:'));
  });
}
