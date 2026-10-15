import 'dart:ui' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/health/health_gateway.dart';
import 'package:stationx/data/health/health_sync_service.dart';
import 'package:stationx/data/health/health_sync_store.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/health/recovery_card.dart';

import '../../data/health_sync_test.dart' show FakeHc;
import '../../helpers/pump.dart';

class _Gw extends FakeHc {
  List<StageSpan> stages = [];
  List<TimeSpan> sessions = [];
  @override
  Future<List<StageSpan>> sleepStages(DateTime a, DateTime b) async => [
    for (final t in stages)
      if (t.to.isAfter(a) && t.from.isBefore(b)) t,
  ];
  @override
  Future<List<TimeSpan>> sleepSessions(DateTime a, DateTime b) async => [
    for (final t in sessions)
      if (t.to.isAfter(a) && t.from.isBefore(b)) t,
  ];
}

Future<void> _settle(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 30)),
  );
  await t.pump(const Duration(milliseconds: 400));
}

/// Page transition + the staggered entrance of the details page.
Future<void> _openRoute(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 100));
  await t.pump(const Duration(seconds: 1));
}

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

  testWidgets('renders nothing while the switch is off', (t) async {
    await pumpPage(t, const RecoveryCard(), controller: app);
    await _settle(t);
    expect(find.text('RECOVERY'), findsNothing);
  });

  void goodNight() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bed = today.subtract(const Duration(hours: 1)); // 23:00 yesterday
    StageSpan st(SleepStage s, int start, int mins) => (
      from: bed.add(Duration(minutes: start)),
      to: bed.add(Duration(minutes: start + mins)),
      stage: s,
    );
    gw.sessions = [(from: bed, to: bed.add(const Duration(minutes: 500)))];
    gw.stages = [
      st(SleepStage.light, 0, 200),
      st(SleepStage.deep, 200, 70),
      st(SleepStage.rem, 270, 105),
      st(SleepStage.light, 375, 105),
      st(SleepStage.awake, 480, 20),
    ];
  }

  testWidgets('verdict card: ready, with the numbers behind it', (t) async {
    await svc.enable(HealthFeature.recovery);
    goodNight();
    await pumpPage(t, const RecoveryCard(), controller: app);
    await _settle(t);
    expect(find.text('RECOVERY'), findsOneWidget);
    expect(find.text("You're ready"), findsOneWidget);
    expect(find.textContaining('8h asleep'), findsOneWidget);
    expect(find.textContaining('Deep 1h 10m'), findsOneWidget);
  });

  testWidgets('tapping the card opens the details with stages and reasons', (
    t,
  ) async {
    await svc.enable(HealthFeature.recovery);
    goodNight();
    await pumpPage(t, const RecoveryCard(), controller: app);
    await _settle(t);
    await t.tap(find.text("You're ready"));
    await _openRoute(t);
    expect(find.text('SLEEP & RECOVERY'), findsOneWidget);
    expect(find.text('GREAT SLEEP'), findsOneWidget);
    expect(find.text('LAST NIGHT'), findsOneWidget);
    expect(find.text('Deep'), findsOneWidget);
    expect(find.text('REM'), findsOneWidget);
    expect(find.textContaining('Deep sleep 1h 10m'), findsOneWidget);
    expect(find.text('WHY'), findsOneWidget);
  });

  testWidgets('on but nothing recorded: says so, not tappable', (t) async {
    await svc.enable(HealthFeature.recovery);
    await pumpPage(t, const RecoveryCard(), controller: app);
    await _settle(t);
    expect(find.text('RECOVERY'), findsOneWidget);
    expect(find.text('No sleep recorded yet'), findsOneWidget);
  });

  testWidgets('details page does not overflow on a small phone', (t) async {
    await svc.enable(HealthFeature.recovery);
    goodNight();
    t.view.physicalSize = const Size(640, 1136);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await pumpPage(t, const RecoveryCard(), controller: app);
    await _settle(t);
    await t.tap(find.text("You're ready"));
    await _openRoute(t);
    expect(find.text('LAST NIGHT'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
