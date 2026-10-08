import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/health/health_gateway.dart';
import 'package:stationx/data/health/health_sync_service.dart';
import 'package:stationx/data/health/health_sync_store.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/cardio/cardio_complete_page.dart';
import 'package:stationx/features/health/health_import_page.dart';
import 'package:stationx/features/health/health_sync_settings_page.dart';
import '../../data/health_sync_test.dart' show FakeHc;
import '../../helpers/pump.dart';

class _Gw extends FakeHc {
  GatewayAvailability avail = GatewayAvailability.available;
  @override
  Future<GatewayAvailability> availability() async => avail;
}

CardioSession _run(String id, {int? hr, int? cal}) => CardioSession(
      id: id,
      kind: CardioKind.outdoorRun,
      workoutDate: DateTime.now().subtract(const Duration(hours: 1)),
      durationSeconds: 1800,
      avgHeartRate: hr,
      calories: cal,
    );

HealthWorkout _ext(String id, {String act = 'RUNNING', int hoursAgo = 5}) => HealthWorkout(
      id: id,
      activityName: act,
      start: DateTime.now().subtract(Duration(hours: hoursAgo)),
      end: DateTime.now().subtract(Duration(hours: hoursAgo - 1)),
      sourceName: 'com.sec.android.app.shealth',
      distanceMeters: 5000,
    );

Future<void> _settle(WidgetTester t) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
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

  Switch sw(WidgetTester t, HealthFeature f) =>
      t.widget<Switch>(find.descendant(of: find.byKey(ValueKey('health-switch-${f.name}')), matching: find.byType(Switch)));

  group('settings page', () {
    testWidgets('switches default off; mentions Samsung Health', (t) async {
      await pumpPage(t, const HealthSyncSettingsPage(), controller: app);
      await _settle(t);
      for (final f in HealthFeature.values) {
        expect(sw(t, f).value, isFalse);
      }
      expect(find.textContaining('Samsung Health shares data through Health Connect'), findsOneWidget);
      expect(gw.calls, 0);
    });

    testWidgets('enable shows explanation first, calls enable only after accept', (t) async {
      await pumpPage(t, const HealthSyncSettingsPage(), controller: app);
      await _settle(t);
      await t.tap(find.text('Save my workouts to Health Connect'));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('NOT sent'), findsOneWidget);
      expect(svc.isEnabled(HealthFeature.writeWorkouts), isFalse);
      await t.tap(find.text('CONTINUE'));
      await _settle(t);
      expect(svc.isEnabled(HealthFeature.writeWorkouts), isTrue);
      expect(sw(t, HealthFeature.writeWorkouts).value, isTrue);
    });

    testWidgets('cancel keeps it off and asks nothing from the system', (t) async {
      await pumpPage(t, const HealthSyncSettingsPage(), controller: app);
      await _settle(t);
      await t.tap(find.text('Import workouts from other apps').first);
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('CANCEL'));
      await _settle(t);
      expect(svc.isEnabled(HealthFeature.importWorkouts), isFalse);
      expect(gw.granted, isEmpty);
    });

    testWidgets('denied permission: calm next step, switch stays off', (t) async {
      gw.grant = false;
      await pumpPage(t, const HealthSyncSettingsPage(), controller: app);
      await _settle(t);
      await t.tap(find.text('Fill heart rate & calories from my watch'));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('CONTINUE'));
      await _settle(t);
      expect(find.textContaining('Health Connect › App permissions'), findsOneWidget);
      expect(sw(t, HealthFeature.enrichCardio).value, isFalse);
    });

    testWidgets('status shows waiting count and retry', (t) async {
      await svc.enable(HealthFeature.writeWorkouts);
      gw.failWrites = true;
      await app.cardio.add(_run('r1'));
      await _settle(t);
      expect(svc.pendingCount, 1);
      await pumpPage(t, const HealthSyncSettingsPage(), controller: app);
      await _settle(t);
      expect(find.textContaining('1 workout is waiting to sync'), findsOneWidget);
      expect(find.text('Could not sync yet. StationX will try again.'), findsOneWidget);
      gw.failWrites = false;
      await t.tap(find.text('RETRY NOW'));
      await _settle(t);
      expect(svc.pendingCount, 0);
      expect(find.text('RETRY NOW'), findsNothing);
      expect(find.textContaining('Removing a workout in StationX'), findsOneWidget);
    });

    testWidgets('unsupported device hides switches', (t) async {
      gw.avail = GatewayAvailability.unsupported;
      await pumpPage(t, const HealthSyncSettingsPage(), controller: app);
      await _settle(t);
      expect(find.text('Not available on this device'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('not installed offers install', (t) async {
      gw.avail = GatewayAvailability.notInstalled;
      await pumpPage(t, const HealthSyncSettingsPage(), controller: app);
      await _settle(t);
      expect(find.text('INSTALL HEALTH CONNECT'), findsOneWidget);
      expect(sw(t, HealthFeature.writeWorkouts).onChanged, isNull);
    });

    testWidgets('no overflow at 320x568 with large text', (t) async {
      await svc.enable(HealthFeature.writeWorkouts);
      await pumpPage(t, const HealthSyncSettingsPage(), controller: app, size: const Size(320, 568), textScale: 1.5);
      await _settle(t);
      expect(t.takeException(), isNull);
    });
  });

  group('enrichment card', () {
    Future<void> pumpComplete(WidgetTester t, String id) async {
      await pumpPage(t, CardioCompletePage(sessionId: id), controller: app);
      await _settle(t);
    }

    testWidgets('hidden when the feature is off', (t) async {
      await app.cardio.add(_run('e0'));
      await pumpComplete(t, 'e0');
      expect(find.byKey(const Key('health-enrichment-card')), findsNothing);
    });

    testWidgets('apply fills only empty fields', (t) async {
      await svc.enable(HealthFeature.enrichCardio);
      gw.metrics = const HealthMetrics(heartRates: [140, 150], activeKcal: 300);
      await app.cardio.add(_run('e1', cal: 250));
      await pumpComplete(t, 'e1');
      expect(find.text('Add heart rate & calories from your watch?'), findsOneWidget);
      expect(find.text('145 bpm'), findsOneWidget);
      expect(find.text('300 kcal'), findsNothing); // typed calories never suggested
      await t.tap(find.text('APPLY'));
      await _settle(t);
      final s = app.cardio.byId('e1')!;
      expect(s.avgHeartRate, 145);
      expect(s.calories, 250);
      expect(find.byKey(const Key('health-enrichment-card')), findsNothing);
    });

    testWidgets('dismiss changes nothing', (t) async {
      await svc.enable(HealthFeature.enrichCardio);
      gw.metrics = const HealthMetrics(heartRates: [140], activeKcal: 300);
      await app.cardio.add(_run('e2'));
      await pumpComplete(t, 'e2');
      await t.tap(find.text('DISMISS'));
      await _settle(t);
      expect(app.cardio.byId('e2')!.avgHeartRate, isNull);
      expect(find.byKey(const Key('health-enrichment-card')), findsNothing);
    });

    testWidgets('nothing available: calm hint, check again finds data', (t) async {
      await svc.enable(HealthFeature.enrichCardio);
      await app.cardio.add(_run('e3'));
      await pumpComplete(t, 'e3');
      expect(find.text('Nothing from your watch yet'), findsOneWidget);
      gw.metrics = const HealthMetrics(heartRates: [120]);
      await t.tap(find.text('CHECK AGAIN'));
      await _settle(t);
      expect(find.text('120 bpm'), findsOneWidget);
    });
  });

  group('import page', () {
    Future<void> pumpImport(WidgetTester t, {Size size = const Size(390, 844)}) async {
      await pumpPage(t, const HealthImportPage(), controller: app, size: size);
      await _settle(t);
    }

    testWidgets('preview, then import adds sessions once', (t) async {
      await svc.enable(HealthFeature.importWorkouts);
      gw.external
        ..add(_ext('a'))
        ..add(_ext('b', act: 'BIKING', hoursAgo: 30))
        ..add(_ext('c', act: 'DANCING'));
      final before = app.cardio.sessions.length;
      await pumpImport(t);
      expect(find.text('IMPORT 2 WORKOUTS'), findsOneWidget);
      await t.tap(find.text('IMPORT 2 WORKOUTS'));
      await _settle(t);
      expect(app.cardio.sessions.length, before + 2);
      final plan = await svc.planImport(app.cardio);
      expect(plan!.sessions, isEmpty);
    });

    testWidgets('nothing new shows calm empty state', (t) async {
      await svc.enable(HealthFeature.importWorkouts);
      await pumpImport(t);
      expect(find.text('Nothing new to import'), findsOneWidget);
      expect(find.textContaining('IMPORT 0'), findsNothing);
    });

    testWidgets('import off points to the switch', (t) async {
      await pumpImport(t);
      expect(find.text('Import is off'), findsOneWidget);
    });

    testWidgets('unsupported device', (t) async {
      gw.avail = GatewayAvailability.unsupported;
      await pumpImport(t);
      expect(find.text('Not available'), findsOneWidget);
    });

    testWidgets('permission revoked shows error with retry', (t) async {
      await svc.enable(HealthFeature.importWorkouts);
      gw.granted.clear();
      await pumpImport(t);
      expect(find.text('Could not read workouts'), findsOneWidget);
      expect(find.text('TRY AGAIN'), findsOneWidget);
    });

    testWidgets('no overflow at 320x568', (t) async {
      await svc.enable(HealthFeature.importWorkouts);
      for (var i = 0; i < 6; i++) {
        gw.external.add(_ext('x$i', hoursAgo: 3 + i * 25));
      }
      await pumpImport(t, size: const Size(320, 568));
      expect(t.takeException(), isNull);
    });
  });
}
