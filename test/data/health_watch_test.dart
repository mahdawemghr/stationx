import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/health/health_gateway.dart';
import 'package:stationx/data/health/health_sync_service.dart';
import 'package:stationx/data/health/health_sync_store.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/domain/domain.dart';

import 'health_sync_test.dart' show FakeHc;

class WatchHc extends FakeHc {
  List<BpmPoint> hr = [];
  HealthHistoryAccess history = HealthHistoryAccess.needsGrant;
  int historyRequests = 0;
  int workoutReads = 0;
  final windows = <TimeSpan>[];

  @override
  Future<List<BpmPoint>> heartRateSamples(DateTime a, DateTime b) async => [
    for (final p in hr)
      if (!p.at.isBefore(a) && p.at.isBefore(b)) p,
  ];

  @override
  Future<HealthHistoryAccess> historyAccess() async => history;

  @override
  Future<bool> requestHistoryAccess() async {
    historyRequests++;
    history = HealthHistoryAccess.granted;
    return true;
  }

  @override
  Future<List<HealthWorkout>> readWorkouts(DateTime a, DateTime b) async {
    workoutReads++;
    windows.add((from: a, to: b));
    return [
      for (final w in external)
        if (w.start.isBefore(b) && w.end.isAfter(a)) w,
    ];
  }
}

HealthWorkout wk(
  String id,
  String name,
  DateTime start, {
  int mins = 45,
  String src = 'com.sec.android.app.shealth',
  double? kcal,
}) => HealthWorkout(
  id: id,
  activityName: name,
  start: start,
  end: start.add(Duration(minutes: mins)),
  sourceName: src,
  energyKcal: kcal,
);

void main() {
  late WatchHc hc;
  late MemoryHealthSyncStore store;
  late HealthSyncService svc;
  late MemoryCardioRepository cardio;
  late MemorySessionRepository sessions;
  var now = DateTime(2026, 10, 10, 12);

  setUp(() {
    now = DateTime(2026, 10, 10, 12);
    hc = WatchHc();
    store = MemoryHealthSyncStore();
    svc = HealthSyncService(hc, store, clock: () => now);
    cardio = MemoryCardioRepository([], []);
    sessions = MemorySessionRepository([]);
    svc.attach(cardio: cardio, sessions: sessions);
  });

  group('import: strength + long history', () {
    test(
      'watch strength sessions become empty-set sessions; cardio still goes to cardio',
      () async {
        await svc.enable(HealthFeature.importWorkouts);
        final day = now.subtract(const Duration(days: 2));
        hc.external
          ..add(wk('r1', 'RUNNING', day))
          ..add(
            wk(
              's1',
              'STRENGTH_TRAINING',
              day.add(const Duration(hours: 5)),
              kcal: 210,
            ),
          )
          ..add(wk('y1', 'YOGA', day));
        final plan = (await svc.planImport(cardio))!;
        expect(plan.sessions.length, 1);
        expect(plan.strengthSessions.length, 1);
        expect(plan.skippedUnsupported, 1);
        expect(plan.count, 2);
        final s = plan.strengthSessions.single;
        expect(s.exercises, isEmpty);
        expect(s.durationSeconds, 45 * 60);
        expect(s.notes, contains('Samsung Health'));
        expect(s.notes, contains('210 kcal'));
        expect(sessions.sessions, isEmpty); // preview changes nothing

        expect(await svc.applyImport(plan, cardio), 2);
        expect(sessions.sessions.single.id, s.id);
        expect(cardio.sessions.length, 1);
      },
    );

    test(
      're-planning does not offer an imported strength session again',
      () async {
        await svc.enable(HealthFeature.importWorkouts);
        hc.external.add(
          wk('s1', 'WEIGHTLIFTING', now.subtract(const Duration(days: 1))),
        );
        final plan = (await svc.planImport(cardio))!;
        await svc.applyImport(plan, cardio);
        await sessions.delete(sessions.sessions.single.id);
        final again = (await svc.planImport(cardio))!;
        expect(again.strengthSessions, isEmpty);
        expect(again.skippedAlreadyImported, 1);
      },
    );

    test(
      'reads a year in chunks and de-duplicates records that overlap two chunks',
      () async {
        await svc.enable(HealthFeature.importWorkouts);
        hc.external
          ..add(wk('old', 'RUNNING', now.subtract(const Duration(days: 300))))
          ..add(wk('new', 'RUNNING', now.subtract(const Duration(days: 3))));
        final plan = (await svc.planImport(cardio, days: 365))!;
        expect(plan.sessions.length, 2);
        expect(hc.workoutReads, greaterThan(4));
        expect(hc.windows.first.from, now.subtract(const Duration(days: 365)));
        expect(hc.windows.last.to, now);
      },
    );

    test('window is capped at HealthImport.maxDays', () {
      expect(HealthImport.clampDays(100000), HealthImport.maxDays);
      expect(HealthImport.maxDays, greaterThanOrEqualTo(365));
    });

    test('enabling import asks for older-data access once', () async {
      await svc.enable(HealthFeature.importWorkouts);
      expect(hc.historyRequests, 1);
      await svc.enable(HealthFeature.enrichCardio);
      expect(hc.historyRequests, 1);
    });
  });

  group('auto import', () {
    HealthWorkout fresh(String id) =>
        wk(id, 'RUNNING', now.subtract(const Duration(hours: 3)));

    test('does nothing until the user turns it on', () async {
      await svc.enable(HealthFeature.importWorkouts);
      hc.external.add(fresh('a'));
      expect(await svc.autoImport(), 0);
      expect(cardio.sessions, isEmpty);
    });

    test(
      'imports silently, reports once, and is throttled to every 6 hours',
      () async {
        await svc.enable(HealthFeature.importWorkouts);
        await svc.setAutoImport(true);
        await Future<void>.delayed(
          const Duration(milliseconds: 20),
        ); // forced run from the switch
        expect(cardio.sessions.length, 0); // nothing yet in the fake
        hc.external.add(fresh('a'));
        now = now.add(const Duration(hours: 1));
        expect(await svc.autoImport(), 0); // throttled
        now = now.add(const Duration(hours: 6));
        expect(await svc.autoImport(), 1);
        expect(svc.takeAutoImportNotice(), 1);
        expect(svc.takeAutoImportNotice(), 0);
        now = now.add(const Duration(hours: 7));
        expect(await svc.autoImport(), 0); // already imported: no duplicates
        expect(cardio.sessions.length, 1);
      },
    );

    test(
      'permission loss is silent and retried next time (throttle not consumed)',
      () async {
        await svc.enable(HealthFeature.importWorkouts);
        await svc.setAutoImport(true);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        hc.granted.clear();
        hc.external.add(fresh('a'));
        now = now.add(const Duration(hours: 7));
        expect(await svc.autoImport(), 0);
        hc.granted.add(HealthFeature.importWorkouts);
        expect(await svc.autoImport(), 1);
      },
    );

    test('the switch survives a restart', () async {
      await svc.enable(HealthFeature.importWorkouts);
      await svc.setAutoImport(true);
      final again = HealthSyncService(
        hc,
        MemoryHealthSyncStore(
          HealthSyncState.parse(store.load().toJsonString()),
        ),
      );
      expect(again.autoImportEnabled, isTrue);
    });
  });

  group('heart rate on workouts', () {
    final start = DateTime(2026, 10, 10, 10);
    List<BpmPoint> samples(Iterable<double> v) => [
      for (final (i, b) in v.indexed)
        (at: start.add(Duration(minutes: i)), bpm: b),
    ];

    test('feature off: no read, no value', () async {
      hc.hr = samples([120, 130]);
      expect(
        await svc.heartRateFor(
          's:1',
          start,
          start.add(const Duration(hours: 1)),
        ),
        isNull,
      );
      expect(await svc.latestHeartRate(), isNull);
    });

    test(
      'average + max, ignoring implausible samples, cached for next time',
      () async {
        await svc.enable(HealthFeature.enrichCardio);
        hc.hr = samples([100, 140, 180, 0, 400]);
        final s = (await svc.heartRateFor(
          's:1',
          start,
          start.add(const Duration(hours: 1)),
        ))!;
        expect(s.avg, 140);
        expect(s.max, 180);
        expect(s.samples, 3);
        hc.hr = [];
        expect(svc.cachedHeartRate('s:1')!.avg, 140);
        expect(
          (await svc.heartRateFor(
            's:1',
            start,
            start.add(const Duration(hours: 1)),
          ))!.max,
          180,
        );
      },
    );

    test('no samples yet is not cached, so a later call can succeed', () async {
      await svc.enable(HealthFeature.enrichCardio);
      final end = start.add(const Duration(hours: 1));
      expect(await svc.heartRateFor('c:1', start, end), isNull);
      expect(svc.cachedHeartRate('c:1'), isNull);
      hc.hr = samples([110, 120]);
      expect((await svc.heartRateFor('c:1', start, end))!.avg, 115);
    });

    test('heart rate persists across restarts', () async {
      await svc.enable(HealthFeature.enrichCardio);
      hc.hr = samples([100, 120]);
      await svc.heartRateFor('s:9', start, start.add(const Duration(hours: 1)));
      final again = HealthSyncService(
        hc,
        MemoryHealthSyncStore(
          HealthSyncState.parse(store.load().toJsonString()),
        ),
      );
      expect(again.cachedHeartRate('s:9')!.avg, 110);
    });

    test(
      'latest heart rate = newest sample inside the last 2 minutes, else null',
      () async {
        await svc.enable(HealthFeature.enrichCardio);
        hc.hr = [
          (at: now.subtract(const Duration(seconds: 90)), bpm: 120),
          (at: now.subtract(const Duration(seconds: 20)), bpm: 133),
          (at: now.subtract(const Duration(minutes: 10)), bpm: 90),
        ];
        expect((await svc.latestHeartRate())!.bpm, 133);
        hc.hr = [(at: now.subtract(const Duration(minutes: 10)), bpm: 90)];
        expect(await svc.latestHeartRate(), isNull);
      },
    );

    test('imported workouts get their heart rate attached', () async {
      await svc.enable(HealthFeature.importWorkouts);
      await svc.enable(HealthFeature.enrichCardio);
      final day = now.subtract(const Duration(days: 1));
      hc.external.add(wk('s1', 'STRENGTH_TRAINING', day));
      hc.hr = [
        for (var i = 0; i < 10; i++)
          (at: day.add(Duration(minutes: i * 3)), bpm: 100.0 + i * 10),
      ];
      final plan = (await svc.planImport(cardio))!;
      await svc.applyImport(plan, cardio);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final id = sessions.sessions.single.id;
      expect(svc.cachedHeartRate(WorkoutMapping.strengthKey(id))!.max, 190);
    });

    test('daily trend: per-day average heart rate', () async {
      await svc.enable(HealthFeature.enrichCardio);
      final today = DateTime(now.year, now.month, now.day);
      hc.hr = [
        (
          at: today
              .subtract(const Duration(days: 1))
              .add(const Duration(hours: 9)),
          bpm: 100,
        ),
        (
          at: today
              .subtract(const Duration(days: 1))
              .add(const Duration(hours: 10)),
          bpm: 120,
        ),
        (at: today.add(const Duration(hours: 9)), bpm: 90),
      ];
      final t = await svc.heartRateTrend(3);
      expect(t.length, 3);
      expect(t[0].average, isNull);
      expect(t[1].average, 110);
      expect(t[2].average, 90);
    });
  });

  group('setup check', () {
    Future<WatchDiagnosis> run() => svc.diagnose();

    test('nothing turned on -> permissions step', () async {
      expect((await run()).step, WatchSetupStep.permissions);
    });

    test('turned on but the watch wrote nothing -> noRecentData', () async {
      await svc.enable(HealthFeature.importWorkouts);
      expect((await run()).step, WatchSetupStep.noRecentData);
    });

    test('permission revoked later -> permissions step', () async {
      await svc.enable(HealthFeature.importWorkouts);
      hc.granted.clear();
      expect((await run()).step, WatchSetupStep.permissions);
    });

    test('recent Samsung Health data -> ok with the source name', () async {
      await svc.enable(HealthFeature.importWorkouts);
      hc.external.add(
        wk('a', 'RUNNING', now.subtract(const Duration(days: 1))),
      );
      final d = await run();
      expect(d.step, WatchSetupStep.ok);
      expect(d.sources, {'Samsung Health'});
    });

    test("StationX's own records do not count as watch data", () async {
      await svc.enable(HealthFeature.importWorkouts);
      hc.external.add(
        wk(
          'a',
          'RUNNING',
          now.subtract(const Duration(days: 1)),
          src: 'dev.mahdi_haji.stationx',
        ),
      );
      expect((await run()).step, WatchSetupStep.noRecentData);
    });

    test('heart-rate samples alone are enough', () async {
      await svc.enable(HealthFeature.enrichCardio);
      hc.hr = [(at: now.subtract(const Duration(days: 1)), bpm: 80)];
      expect((await run()).step, WatchSetupStep.ok);
    });
  });
}
