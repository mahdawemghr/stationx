import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/features/workouts/workouts_hub_page.dart';
import 'package:stationx/features/today/today_page.dart';
import 'package:stationx/features/profile/profile_page.dart';
import 'package:stationx/features/progress/progress_page.dart';
import 'package:stationx/features/history/calendar_page.dart';
import '../helpers/pump.dart';

/// The main tabs must lay out without overflow on narrow screens with large text (a 280dp cover
/// display is the narrowest realistic width; 2.0x is the largest Android font scale).
void main() {
  setUpAll(loadAppFonts);
  final pages = <String, Widget>{
    'hub': const WorkoutsHubPage(),
    'today': const TodayPage(),
    'profile': const ProfilePage(),
    'progress': const ProgressPage(),
    'calendar': const CalendarPage(),
  };
  for (final e in pages.entries) {
    for (final (size, scale) in [
      (const Size(320, 568), 1.0),
      (const Size(320, 568), 1.3),
      (const Size(320, 568), 2.0),
      (const Size(360, 640), 2.0),
      (const Size(280, 600), 1.0),
      (const Size(280, 600), 2.0),
      (const Size(360, 800), 1.3),
    ]) {
      for (final demo in [true, false]) {
        testWidgets(
          '${e.key} ${size.width.toInt()}x${size.height.toInt()} text x$scale demo=$demo',
          (t) async {
            await pumpPage(
              t,
              e.value,
              size: size,
              textScale: scale,
              demo: demo,
            );
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  }
}
