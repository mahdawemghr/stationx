import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/features/active_workout/active_workout_page.dart';
import 'package:stationx/features/active_workout/widgets/set_row.dart';

import '../../helpers/pump.dart';

/// Gym ergonomics: the first set rows must be on screen the moment the logger opens.
void main() {
  setUpAll(loadAppFonts);

  Future<List<Rect>> rowRects(WidgetTester t, Size size, double scale) async {
    await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), size: size, textScale: scale);
    await t.pump(const Duration(milliseconds: 400));
    return [for (final e in find.byType(SetRowView).evaluate().take(2)) t.getRect(find.byWidget(e.widget))];
  }

  double footerTop(WidgetTester t, Size size) => t.getRect(find.text('FINISH WORKOUT')).top;

  // Footer top = the Finish label minus the footer's 12dp padding (the row must end above it).
  testWidgets('first two set rows are fully visible above the footer at 360x720', (t) async {
    const size = Size(360, 720);
    final rects = await rowRects(t, size, 1.0);
    expect(rects.length, 2);
    for (final r in rects) {
      expect(r.bottom, lessThanOrEqualTo(footerTop(t, size) - 12), reason: 'row $r must end above the footer');
      expect(r.top, greaterThan(60));
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('320x568: the active first set row is fully visible and the second row starts on screen', (t) async {
    const size = Size(320, 568);
    final rects = await rowRects(t, size, 1.0);
    final limit = footerTop(t, size) - 12;
    expect(rects[0].bottom, lessThanOrEqualTo(limit), reason: 'first row ${rects[0]} vs footer $limit');
    expect(rects[1].top, lessThan(limit), reason: 'second row starts above the footer');
    expect(t.takeException(), isNull);
  });

  testWidgets('no overflow at 2x text on 320x568', (t) async {
    await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), size: const Size(320, 568), textScale: 2.0);
    await t.pump(const Duration(milliseconds: 400));
    expect(t.takeException(), isNull);
  });
}
