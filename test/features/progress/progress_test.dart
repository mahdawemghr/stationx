import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/features/progress/personal_records_page.dart';
import 'package:stationx/features/progress/progress_page.dart';

import '../../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('progress strength: tiles + sections from real data', (t) async {
    await pumpPage(t, const ProgressPage());
    await shot(t, 'progress_strength');
    expect(find.text('WORKOUTS'), findsOneWidget);
    expect(find.text('NEW PRS'), findsOneWidget);
    await t.drag(find.byType(ListView).first, const Offset(0, -1200));
    await t.pump();
    await shot(t, 'progress_strength_2');
  });

  testWidgets('progress: period menu + cardio switch', (t) async {
    await pumpPage(t, const ProgressPage());
    await t.tap(find.text('THIS WEEK'));
    await t.pumpAndSettle();
    await t.tap(find.text('All time'));
    await t.pumpAndSettle();
    expect(find.text('ALL TIME'), findsOneWidget);
    await t.tap(find.text('CARDIO'));
    await t.pumpAndSettle();
    await shot(t, 'progress_cardio');
    expect(find.textContaining('AEROBIC DURATION'), findsOneWidget);
  });

  testWidgets('progress empty states (no data)', (t) async {
    await pumpPage(t, const ProgressPage(), demo: false);
    expect(find.text('No training data yet'), findsOneWidget);
    await t.tap(find.text('CARDIO'));
    await t.pumpAndSettle();
    expect(find.text('No cardio recorded yet'), findsOneWidget);
  });

  testWidgets('personal records: renders, filters', (t) async {
    await pumpPage(t, const PersonalRecordsPage());
    await shot(t, 'pr_board');
    expect(find.text('CALCULATION MATRIX'), findsOneWidget);
    expect(find.textContaining('not a tested 1RM'), findsOneWidget);
    await t.tap(find.text('Most Reps'));
    await t.pump();
    await t.tap(find.text('Chest'));
    await t.pump();
    expect(find.text('Lat Pulldown'), findsNothing);
  });

  testWidgets('personal records empty', (t) async {
    await pumpPage(t, const PersonalRecordsPage(), demo: false);
    expect(find.text('No records yet'), findsOneWidget);
  });

  testWidgets('small screen / text scale: no overflow', (t) async {
    for (final demo in [true, false]) {
      await pumpPage(t, const ProgressPage(), size: const Size(320, 568), textScale: 1.3, demo: demo);
      expect(t.takeException(), isNull);
      await t.tap(find.text('CARDIO'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await pumpPage(t, const PersonalRecordsPage(), size: const Size(320, 568), textScale: 1.3, demo: demo);
      expect(t.takeException(), isNull);
    }
  });
}
