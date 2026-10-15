import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/health/health_gateway.dart';
import 'package:stationx/data/health/health_sync_service.dart';
import 'package:stationx/data/health/health_sync_store.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/health/heart_rate_widgets.dart';
import 'package:stationx/features/health/health_import_page.dart';
import 'package:stationx/features/health/watch_setup_page.dart';
import '../../data/health_sync_test.dart' show FakeHc;
import '../../helpers/pump.dart';

class _Gw extends FakeHc {
  List<BpmPoint> hr = [];
  @override
  Future<List<BpmPoint>> heartRateSamples(DateTime a, DateTime b) async => [
    for (final p in hr)
      if (!p.at.isBefore(a) && p.at.isBefore(b)) p,
  ];
}

Future<void> _settle(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 30)),
  );
  await t.pump(const Duration(milliseconds: 400));
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

  final start = DateTime.now().subtract(const Duration(hours: 2));

  group('HeartRateCard', () {
    testWidgets('renders nothing while the feature is off', (t) async {
      await pumpPage(
        t,
        HeartRateCard(sessionKey: 's:1', start: start, durationSeconds: 3600),
        controller: app,
      );
      await _settle(t);
      expect(find.text('HEART RATE'), findsNothing);
    });

    testWidgets('shows average and max from the watch', (t) async {
      await svc.enable(HealthFeature.enrichCardio);
      gw.hr = [
        for (var i = 0; i < 4; i++)
          (at: start.add(Duration(minutes: i * 10)), bpm: 100.0 + i * 20),
      ];
      await pumpPage(
        t,
        HeartRateCard(sessionKey: 's:1', start: start, durationSeconds: 3600),
        controller: app,
      );
      await _settle(t);
      expect(find.text('HEART RATE'), findsOneWidget);
      expect(find.text('130'), findsOneWidget); // avg
      expect(find.text('160'), findsOneWidget); // max
    });

    testWidgets(
      'no data yet: calm hint, then finds data after the watch syncs',
      (t) async {
        await svc.enable(HealthFeature.enrichCardio);
        await pumpPage(
          t,
          HeartRateCard(sessionKey: 's:2', start: start, durationSeconds: 3600),
          controller: app,
        );
        await _settle(t);
        expect(find.textContaining('No heart rate found'), findsOneWidget);
        gw.hr = [(at: start.add(const Duration(minutes: 5)), bpm: 111)];
        await t.tap(find.text('READ HEART RATE AGAIN'));
        await _settle(t);
        expect(find.text('111'), findsNWidgets(2));
      },
    );
  });

  group('LiveHeartRateChip', () {
    testWidgets('hidden with the feature off or without a fresh sample', (
      t,
    ) async {
      await pumpPage(t, const LiveHeartRateChip(), controller: app);
      await _settle(t);
      expect(find.text('bpm'), findsNothing);
      await svc.enable(HealthFeature.enrichCardio);
      await pumpPage(t, const LiveHeartRateChip(), controller: app);
      await _settle(t);
      expect(find.text('bpm'), findsNothing);
    });

    testWidgets('shows the newest sample', (t) async {
      await svc.enable(HealthFeature.enrichCardio);
      gw.hr = [
        (at: DateTime.now().subtract(const Duration(seconds: 10)), bpm: 147),
      ];
      await pumpPage(t, const LiveHeartRateChip(), controller: app);
      await _settle(t);
      expect(find.text('147'), findsOneWidget);
    });
  });

  group('WatchSetupPage', () {
    testWidgets('lists Galaxy Watch steps and reports the failing step', (
      t,
    ) async {
      await pumpPage(t, const WatchSetupPage(), controller: app);
      await _settle(t);
      expect(find.text('Galaxy Watch'), findsOneWidget);
      await t.ensureVisible(find.text('CHECK MY CONNECTION'));
      await t.tap(find.text('CHECK MY CONNECTION'));
      await _settle(t);
      expect(find.text('StationX is not allowed to read yet'), findsOneWidget);
    });

    testWidgets('reports success once data is found', (t) async {
      await svc.enable(HealthFeature.importWorkouts);
      gw.external.add(
        HealthWorkout(
          id: 'a',
          activityName: 'RUNNING',
          start: DateTime.now().subtract(const Duration(days: 1)),
          end: DateTime.now()
              .subtract(const Duration(days: 1))
              .add(const Duration(minutes: 30)),
          sourceName: 'com.sec.android.app.shealth',
        ),
      );
      await pumpPage(t, const WatchSetupPage(), controller: app);
      await _settle(t);
      await t.ensureVisible(find.text('CHECK MY CONNECTION'));
      await t.tap(find.text('CHECK MY CONNECTION'));
      await _settle(t);
      expect(find.text('Everything is connected'), findsOneWidget);
      expect(find.textContaining('Samsung Health'), findsWidgets);
    });
  });

  group('WatchSetupPage heart rate', () {
    testWidgets('workouts import but heart rate is off: says so, turns it on', (
      t,
    ) async {
      await svc.enable(HealthFeature.importWorkouts);
      final day = DateTime.now().subtract(const Duration(days: 1));
      gw.external.add(
        HealthWorkout(
          id: 'a',
          activityName: 'RUNNING',
          start: day,
          end: day.add(const Duration(minutes: 30)),
          sourceName: 'com.sec.android.app.shealth',
        ),
      );
      await pumpPage(t, const WatchSetupPage(), controller: app);
      await _settle(t);
      await t.ensureVisible(find.text('CHECK MY CONNECTION'));
      await t.tap(find.text('CHECK MY CONNECTION'));
      await _settle(t);
      expect(find.text('Heart rate is turned off'), findsOneWidget);
      await t.ensureVisible(find.text('TURN ON HEART RATE'));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('TURN ON HEART RATE'));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('CONTINUE')); // explanation dialog
      await _settle(t);
      expect(svc.isEnabled(HealthFeature.enrichCardio), isTrue);
      expect(find.text('Heart rate is turned off'), findsNothing);
    });
  });

  group('WatchSetupPage missing watch workouts', () {
    testWidgets(
      'only StationX workouts in the store: explains the real cause',
      (t) async {
        await svc.enable(HealthFeature.importWorkouts);
        await svc.enable(HealthFeature.enrichCardio);
        final day = DateTime.now().subtract(const Duration(days: 1));
        gw.hr = [(at: day, bpm: 90)];
        gw.external.add(
          HealthWorkout(
            id: 'own',
            activityName: 'RUNNING',
            start: day,
            end: day.add(const Duration(minutes: 30)),
            sourceName: 'dev.mahdi_haji.stationx',
          ),
        );
        await pumpPage(t, const WatchSetupPage(), controller: app);
        await _settle(t);
        await t.ensureVisible(find.text('CHECK MY CONNECTION'));
        await t.tap(find.text('CHECK MY CONNECTION'));
        await _settle(t);
        expect(find.text('No workouts from your watch yet'), findsOneWidget);
        expect(find.textContaining('saved by StationX itself'), findsOneWidget);
        expect(find.text('Heart rate is coming through'), findsOneWidget);
      },
    );
  });

  group('import page', () {
    testWidgets('offers 1 year / All and previews a watch strength session', (
      t,
    ) async {
      await svc.enable(HealthFeature.importWorkouts);
      final s = DateTime.now().subtract(const Duration(hours: 5));
      gw.external.add(
        HealthWorkout(
          id: 'st1',
          activityName: 'STRENGTH_TRAINING',
          start: s,
          end: s.add(const Duration(minutes: 50)),
          sourceName: 'com.sec.android.app.shealth',
        ),
      );
      await pumpPage(t, const HealthImportPage(), controller: app);
      await _settle(t);
      expect(find.text('1 YEAR'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('Strength training'), findsOneWidget);
      await t.tap(find.text('IMPORT 1 WORKOUT'));
      await _settle(t);
      expect(
        app.sessions.sessions
            .where((x) => x.name == 'Strength training')
            .length,
        1,
      );
    });
  });
}
