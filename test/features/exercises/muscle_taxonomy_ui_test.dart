import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/exercises/exercise_details_page.dart';
import 'package:stationx/features/exercises/exercise_library_page.dart';

import '../../helpers/pump.dart';

Finder chip(String label) => find.widgetWithText(SxChip, label);

void main() {
  setUpAll(loadAppFonts);

  group('library sub-muscle chips', () {
    testWidgets('appear only after choosing a muscle and filter by detailed muscle', (t) async {
      await pumpPage(t, const ExerciseLibraryPage());
      expect(find.byKey(const ValueKey('subMuscleChips')), findsNothing);
      await t.tap(chip('Back'));
      await settle(t);
      expect(find.byKey(const ValueKey('subMuscleChips')), findsOneWidget);
      expect(chip('Lats'), findsOneWidget);

      await t.tap(chip('Lats'));
      await settle(t);
      await t.enterText(find.byType(TextField), 'pulldown');
      await settle(t);
      expect(find.text('Lat Pulldown'), findsOneWidget);

      // A back exercise with no Lats target is filtered out.
      final all = AppController().exercises.all;
      final nonLat = all.firstWhere((e) =>
          e.primaryMuscle == MuscleGroup.back && !MuscleProfiles.of(e).targets.any((x) => x.muscle == Muscle.lats));
      await t.enterText(find.byType(TextField), nonLat.name);
      await settle(t);
      expect(find.text('No exercises found'), findsOneWidget);

      // Back to the broad filter: the exercise is visible again.
      await t.tap(find.textContaining(RegExp('clear filters', caseSensitive: false)));
      await settle(t);
      expect(find.byKey(const ValueKey('subMuscleChips')), findsNothing);
    });

    testWidgets('only leaves that have exercises are offered; changing muscle resets', (t) async {
      final app = await pumpPage(t, const ExerciseLibraryPage());
      final chestLeaves = <Muscle>{
        for (final e in app.exercises.all)
          for (final x in MuscleProfiles.of(e).targets)
            if (x.muscle != null && x.region.legacy == MuscleGroup.chest) x.muscle!,
      };
      await t.tap(chip('Chest'));
      await settle(t);
      for (final m in Muscle.values.where((m) => m.region.legacy != MuscleGroup.chest)) {
        expect(chip(m.label), findsNothing, reason: m.label);
      }
      expect(chestLeaves, isNotEmpty);
      await t.tap(chip(chestLeaves.first.label));
      await settle(t);
      await t.tap(chip('Back'));
      await settle(t);
      expect(chip('Lats'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('combines with search/equipment/Common; no overflow at 320x568', (t) async {
      await pumpPage(t, const ExerciseLibraryPage(), size: const Size(320, 568), textScale: 1.3);
      await t.tap(chip('Back'));
      await settle(t);
      await t.tap(chip('Lats'));
      await settle(t);
      await t.tap(find.text('Common'));
      await settle(t);
      expect(t.takeException(), isNull);
    });
  });

  group('details muscle labels', () {
    testWidgets('lat_pulldown shows Lats primary and secondary muscles from profile', (t) async {
      await pumpPage(t, const ExerciseDetailsPage(exerciseId: 'lat_pulldown'));
      await t.scrollUntilVisible(find.text('SECONDARY'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Lats'), findsWidgets);
      expect(find.text('PRIMARY'), findsWidgets);
      final prof = MuscleProfiles.of(AppController().exercises.byId('lat_pulldown')!);
      final sec = prof.secondary.map((x) => x.muscle?.label ?? x.region.label).first;
      expect(find.text(sec), findsWidgets);
      expect(
        find.bySemanticsLabel(RegExp('^Primary muscles: .*Lats')),
        findsOneWidget,
      );
    });

    testWidgets('custom exercise shows broad primary/secondary without crashing', (t) async {
      final app = AppController()..startDemo();
      await app.exercises.addCustom(Exercise(
        id: 'custom_x',
        name: 'My Odd Row',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscles: const [MuscleGroup.biceps],
        equipment: Equipment.cable,
        isCustom: true,
      ));
      await pumpPage(t, const ExerciseDetailsPage(exerciseId: 'custom_x'), controller: app, size: const Size(320, 568), textScale: 1.3);
      await t.scrollUntilVisible(find.text('SECONDARY'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Back'), findsWidgets);
      expect(find.text('Biceps'), findsWidgets);
      expect(t.takeException(), isNull);

      // Library: custom exercise is under the broad Back filter, but under no detailed one.
      await pumpPage(t, const ExerciseLibraryPage(), controller: app);
      await t.tap(chip('Back'));
      await settle(t);
      await t.enterText(find.byType(TextField), 'My Odd Row');
      await settle(t);
      expect(find.descendant(of: find.byType(SxCard), matching: find.text('My Odd Row')), findsOneWidget);
      await t.tap(chip('Lats'));
      await settle(t);
      expect(find.descendant(of: find.byType(SxCard), matching: find.text('My Odd Row')), findsNothing);
    });
  });
}

/// Two pumps: the first builds, the second runs the (short) size/fade animations to the end.
Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 350));
}
