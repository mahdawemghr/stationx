import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/features/exercises/exercise_details_page.dart';
import 'package:stationx/features/exercises/exercise_history_page.dart';
import 'package:stationx/features/exercises/exercise_library_page.dart';
import 'package:stationx/domain/domain.dart';

import '../../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('library: renders, shot, filters by search + muscle', (t) async {
    await pumpPage(t, const ExerciseLibraryPage());
    await shot(t, 'ex_library');
    // The seed library is large and lazily built: search to bring a known exercise into view.
    await t.enterText(find.byType(TextField), 'barbell bench');
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'squat');
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('Barbell Bench Press'), findsNothing);
    expect(find.text('Barbell Back Squat'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'zzzz');
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('No exercises found'), findsOneWidget);
    await t.enterText(find.byType(TextField), '');
    await t.pump(const Duration(milliseconds: 200));
    await t.tap(find.text('Chest'));
    await t.pump();
    await t.enterText(find.byType(TextField), 'barbell bench');
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('Barbell Back Squat'), findsNothing);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
  });

  testWidgets(
    'library: Common chip limits to common lifts, no overflow at 320x568',
    (t) async {
      t.view.physicalSize = const Size(640, 1136);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await pumpPage(t, const ExerciseLibraryPage());
      await t.tap(find.text('Common'));
      await t.pump();
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'cable fly');
      await t.pump(const Duration(milliseconds: 200));
      expect(find.text('No exercises found'), findsOneWidget);
      await t.tap(
        find.textContaining(RegExp('clear filters', caseSensitive: false)),
      );
      await t.pump();
      await t.tap(find.text('All exercises'));
      await t.pump();
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('library: pick mode pops the exercise', (t) async {
    Exercise? picked;
    await pumpPage(
      t,
      Builder(
        builder: (c) => Scaffold(
          body: TextButton(
            onPressed: () async =>
                picked = await Navigator.of(c).push<Exercise>(
                  MaterialPageRoute(
                    builder: (_) => const ExerciseLibraryPage(pickMode: true),
                  ),
                ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'lat pull');
    await t.pump(const Duration(milliseconds: 200));
    await t.tap(find.text('Lat Pulldown'));
    await t.pumpAndSettle();
    expect(picked?.id, 'lat_pulldown');
  });

  testWidgets('library: custom exercise is added', (t) async {
    final app = await pumpPage(t, const ExerciseLibraryPage());
    final before = app.exercises.all.length;
    await t.tap(find.text('CUSTOM'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, 'Zercher Squat');
    await t.ensureVisible(find.text('SAVE EXERCISE')); // 9 equipment chips make the sheet scroll
    await t.pumpAndSettle();
    await t.tap(find.text('SAVE EXERCISE'));
    await t.pumpAndSettle();
    expect(app.exercises.all.length, before + 1);
  });

  testWidgets('details + history render with data', (t) async {
    await pumpPage(t, const ExerciseDetailsPage(exerciseId: 'lat_pulldown'));
    await shot(t, 'ex_details');
    expect(find.text('Lat Pulldown'), findsWidgets);
    await pumpPage(t, const ExerciseHistoryPage(exerciseId: 'lat_pulldown'));
    await shot(t, 'ex_history');
    expect(find.text('KEY MILESTONES'), findsOneWidget);
    await t.tap(find.text('Reps'));
    await t.pump();
  });

  testWidgets('history empty state for never-logged exercise', (t) async {
    await pumpPage(t, const ExerciseHistoryPage(exerciseId: 'plank'));
    expect(find.text('No history yet'), findsOneWidget);
    await pumpPage(
      t,
      const ExerciseDetailsPage(exerciseId: 'plank'),
      demo: false,
    );
    expect(find.textContaining('No sets logged'), findsOneWidget);
  });

  testWidgets('small screen + text scale 1.3: no overflow', (t) async {
    for (final page in const [
      ExerciseLibraryPage(),
      ExerciseDetailsPage(exerciseId: 'lat_pulldown'),
      ExerciseHistoryPage(exerciseId: 'lat_pulldown'),
    ]) {
      await pumpPage(t, page, size: const Size(320, 568), textScale: 1.3);
      expect(t.takeException(), isNull);
    }
    await shot(t, 'ex_history_small');
  });
}
