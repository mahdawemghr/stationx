import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/health/health_gateway.dart';
import 'package:stationx/data/health/health_sync_service.dart';
import 'package:stationx/data/health/health_sync_store.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/history/calendar_page.dart';

import '../../data/health_sync_test.dart' show FakeHc;
import '../../helpers/pump.dart';

class _Gw extends FakeHc {
  List<TimeSpan> sessions = [];
  List<StageSpan> stages = [];
  @override
  Future<List<TimeSpan>> sleepSessions(DateTime a, DateTime b) async => [
    for (final t in sessions)
      if (t.to.isAfter(a) && t.from.isBefore(b)) t,
  ];
  @override
  Future<List<StageSpan>> sleepStages(DateTime a, DateTime b) async => [
    for (final t in stages)
      if (t.to.isAfter(a) && t.from.isBefore(b)) t,
  ];
}

Future<void> _settle(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 30)),
  );
  await t.pump(const Duration(milliseconds: 400));
}

Key _sleepKey(DateTime d) =>
    ValueKey('sleep-dot-${d.year}-${d.month}-${d.day}');
Key _dayKey(DateTime d) => ValueKey('cal-day-${d.year}-${d.month}-${d.day}');

void main() {
  setUpAll(loadAppFonts);
  late _Gw gw;
  late HealthSyncService svc;
  late AppController app;
  setUp(() {
    gw = _Gw();
    svc = HealthSyncService(gw, MemoryHealthSyncStore());
    app = AppController(healthSync: svc)..startDemo();
  });

  /// A night that ended at 07:00 on [wakeDay] (23:00 the evening before).
  void night(DateTime wakeDay, {int mins = 480}) {
    final wake = DateTime(wakeDay.year, wakeDay.month, wakeDay.day, 7);
    final bed = wake.subtract(Duration(minutes: mins));
    gw.sessions = [...gw.sessions, (from: bed, to: wake)];
    gw.stages = [
      ...gw.stages,
      (
        from: bed,
        to: bed.add(Duration(minutes: mins - 70)),
        stage: SleepStage.light,
      ),
      (
        from: wake.subtract(const Duration(minutes: 70)),
        to: wake,
        stage: SleepStage.deep,
      ),
    ];
  }

  testWidgets('feature off: no sleep markers and no sleep card', (t) async {
    night(DateTime.now());
    await pumpPage(t, const CalendarPage(), controller: app);
    await _settle(t);
    expect(find.byKey(_sleepKey(DateTime.now())), findsNothing);
    expect(find.text('SLEEP'), findsNothing);
  });

  testWidgets('a moon marks days with sleep and today shows its sleep card', (
    t,
  ) async {
    await svc.enable(HealthFeature.recovery);
    final today = DateTime.now();
    night(today);
    await pumpPage(t, const CalendarPage(), controller: app);
    await _settle(t);
    expect(find.byKey(_sleepKey(today)), findsOneWidget);
    expect(find.text('SLEEP'), findsOneWidget);
    expect(find.textContaining('asleep'), findsWidgets);
  });

  testWidgets(
    'a past day in another month: browse back, tap it, open details',
    (t) async {
      await svc.enable(HealthFeature.recovery);
      final now = DateTime.now();
      final lastOfPrev = DateTime(now.year, now.month, 0);
      night(lastOfPrev, mins: 450);
      await pumpPage(t, const CalendarPage(), controller: app);
      await _settle(t);
      await t.tap(find.byTooltip('Previous month'));
      await _settle(t);
      expect(find.byKey(_sleepKey(lastOfPrev)), findsOneWidget);
      await t.ensureVisible(find.byKey(_dayKey(lastOfPrev)));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.byKey(_dayKey(lastOfPrev)));
      await _settle(t);
      expect(find.text('SLEEP'), findsOneWidget);
      expect(find.textContaining('7h 30m asleep'), findsWidgets);
      await t.ensureVisible(find.text('SLEEP'));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('SLEEP'));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('LAST NIGHT'), findsOneWidget);
    },
  );

  testWidgets('days without sleep have no marker and no card', (t) async {
    await svc.enable(HealthFeature.recovery);
    final now = DateTime.now();
    night(DateTime(now.year, now.month, 0)); // only last month
    await pumpPage(t, const CalendarPage(), controller: app);
    await _settle(t);
    expect(find.byKey(_sleepKey(now)), findsNothing);
    expect(find.text('SLEEP'), findsNothing);
  });
}
