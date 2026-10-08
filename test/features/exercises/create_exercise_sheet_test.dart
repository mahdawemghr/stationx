import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/exercises/create_exercise_sheet.dart';

import '../../helpers/pump.dart';

Finder chip(String label) => find.widgetWithText(SxChip, label);

void main() {
  setUpAll(loadAppFonts);

  Future<(dynamic, List<Exercise?>)> open(WidgetTester t, {MuscleGroup initial = MuscleGroup.chest, Size size = const Size(390, 844)}) async {
    final out = <Exercise?>[];
    final app = await pumpPage(
      t,
      Builder(
        builder: (c) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async => out.add(await showCreateExerciseSheet(c, initialMuscle: initial)),
              child: const Text('go'),
            ),
          ),
        ),
      ),
      size: size,
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    return (app, out);
  }

  Future<void> save(WidgetTester t) async {
    await t.ensureVisible(find.text('SAVE EXERCISE'));
    await t.tap(find.text('SAVE EXERCISE'));
    await t.pumpAndSettle();
  }

  testWidgets('quick path: name + save yields one primary target from initialMuscle', (t) async {
    final (app, out) = await open(t, initial: MuscleGroup.legs);
    await t.enterText(find.byType(TextField).last, 'Zercher Squat');
    await save(t);
    final ex = out.single!;
    expect(ex.isCustom, isTrue);
    expect(ex.primaryMuscle, MuscleGroup.legs);
    expect(ex.secondaryMuscles, isEmpty);
    expect(ex.muscleTargets!.single.role, TargetRole.primary);
    expect(ex.muscleTargets!.single.region, MuscleRegion.quadriceps);
    expect(app.exercises.byId(ex.id)!.muscleTargets, isNotNull);
  });

  testWidgets('multi-target: subgroup, assisting row and note are saved and legacy fields derived', (t) async {
    final (_, out) = await open(t);
    await t.enterText(find.byType(TextField).last, 'Lat Pulldown Variation');
    await t.tap(chip('Back').first);
    await settle(t);
    await t.ensureVisible(chip('Lats').first);
    await t.tap(chip('Lats').first);
    await settle(t);
    await t.ensureVisible(find.text('Add note').first);
    await t.tap(find.text('Add note').first);
    await settle(t);
    await t.enterText(find.widgetWithText(TextField, 'e.g. stretch under load'), 'Wide grip');
    await t.ensureVisible(chip('Add muscle'));
    await t.tap(chip('Add muscle'));
    await settle(t);
    // second row defaults to Assisting; pick Biceps (first region not yet used is Chest -> change it)
    expect(find.text('MUSCLE 2'), findsOneWidget);
    await t.ensureVisible(chip('Biceps').last);
    await t.tap(chip('Biceps').last);
    await settle(t);
    await save(t);
    final ex = out.single!;
    expect(ex.primaryMuscle, MuscleGroup.back);
    expect(ex.secondaryMuscles, [MuscleGroup.biceps]);
    final tg = ex.muscleTargets!;
    expect((tg[0].region, tg[0].muscle, tg[0].role, tg[0].emphasis), (MuscleRegion.back, Muscle.lats, TargetRole.primary, 'Wide grip'));
    expect((tg[1].region, tg[1].muscle, tg[1].role), (MuscleRegion.biceps, null, TargetRole.secondary));
  });

  testWidgets('validation: duplicate target, no primary, empty name; remove row', (t) async {
    final (_, out) = await open(t);
    await save(t);
    expect(find.text('Required'), findsOneWidget);
    await t.enterText(find.byType(TextField).last, 'Dup Test');
    // add a second row and make it the same region (Chest) as row 1
    await t.ensureVisible(chip('Add muscle'));
    await t.tap(chip('Add muscle'));
    await settle(t);
    await t.ensureVisible(chip('Chest').last);
    await t.tap(chip('Chest').last);
    await settle(t);
    await save(t);
    expect(find.text('The same muscle is listed twice'), findsOneWidget);
    expect(out, isEmpty);
    // different subgroup is NOT a duplicate; but make row 1 assisting too -> no primary
    await t.ensureVisible(chip('Upper chest').last);
    await t.tap(chip('Upper chest').last);
    await settle(t);
    await t.ensureVisible(chip('Assisting').first);
    await t.tap(chip('Assisting').first);
    await settle(t);
    await t.ensureVisible(chip('Assisting').last);
    await t.tap(chip('Assisting').last);
    await settle(t);
    await save(t);
    expect(find.text('Choose at least one primary muscle'), findsOneWidget);
    // remove row 2, make row 1 primary again -> saves
    await t.tap(find.byTooltip('Remove muscle 2'));
    await settle(t);
    expect(find.text('MUSCLE 2'), findsNothing);
    await t.ensureVisible(chip('Primary').first);
    await t.tap(chip('Primary').first);
    await settle(t);
    await save(t);
    expect(out.single!.muscleTargets!.single.region, MuscleRegion.chest);
  });

  testWidgets('no overflow at 320x568 with several rows and 1.3 text scale; 48dp targets', (t) async {
    final out = <Exercise?>[];
    await pumpPage(
      t,
      Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () async => out.add(await showCreateExerciseSheet(c)), child: const Text('go')))),
      size: const Size(320, 568),
      textScale: 1.3,
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await t.ensureVisible(chip('Add muscle'));
      await t.tap(chip('Add muscle'));
      await settle(t);
    }
    expect(t.takeException(), isNull);
    for (final f in [chip('Add muscle'), chip('Primary').first, chip('Assisting').last]) {
      await t.ensureVisible(f);
      expect(t.getSize(f).height, greaterThanOrEqualTo(48));
    }
    expect(find.byTooltip('Remove muscle 3'), findsOneWidget);
  });
}

/// Two pumps: the first builds, the second runs the (short) size/fade animations to the end.
Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 350));
}
