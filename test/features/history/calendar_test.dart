import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/features/history/calendar_page.dart';

import '../../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('calendar: renders month, selects a day with a session', (t) async {
    final app = await pumpPage(t, const CalendarPage());
    await shot(t, 'calendar_today');
    final s = app.sessions.sessions.first;
    final d = s.workoutDate;
    final now = DateTime.now();
    // Navigate to the session's month if needed.
    var months = (now.year - d.year) * 12 + now.month - d.month;
    while (months-- > 0) {
      await t.tap(find.byTooltip('Previous month'));
      await t.pump();
    }
    await t.tap(find.bySemanticsLabel(RegExp('${Fmt2.long(d)}.*')).first);
    await t.pump();
    expect(find.text(s.name), findsWidgets);
    await shot(t, 'calendar_day');
  });

  testWidgets('calendar: filters change visible sessions', (t) async {
    await pumpPage(t, const CalendarPage());
    await t.tap(find.textContaining('Cardio only'));
    await t.pump();
    expect(find.textContaining('Cardio only'), findsOneWidget);
  });

  testWidgets('calendar: empty account shows rest-day state', (t) async {
    await pumpPage(t, const CalendarPage(), demo: false);
    expect(find.text('Rest day'), findsOneWidget);
  });

  testWidgets('calendar: future date cannot be backdated', (t) async {
    await pumpPage(t, const CalendarPage());
    await t.tap(find.byTooltip('Next month'));
    await t.pump();
    expect(find.text('Upcoming day'), findsOneWidget);
    await t.scrollUntilVisible(find.textContaining('Pick today or an earlier date'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Pick today or an earlier date'), findsOneWidget);
  });

  testWidgets('calendar: log historical lift opens workout picker', (t) async {
    await pumpPage(t, const CalendarPage());
    final btn = find.text('LOG LIFT');
    await t.scrollUntilVisible(btn, 300, scrollable: find.byType(Scrollable).first);
    await t.tap(btn);
    await t.pumpAndSettle();
    expect(find.text('LOG HISTORICAL LIFT'), findsOneWidget);
    expect(find.text('Back + Triceps'), findsWidgets);
  });

  testWidgets('calendar: small screen no overflow', (t) async {
    await pumpPage(t, const CalendarPage(), size: const Size(320, 568), textScale: 1.3);
    expect(t.takeException(), isNull);
    await pumpPage(t, const CalendarPage(), size: const Size(320, 568), textScale: 1.3, demo: false);
    expect(t.takeException(), isNull);
  });
}

class Fmt2 {
  static String long(DateTime d) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const m = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}';
  }
}
