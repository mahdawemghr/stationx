import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/health/health_gateway.dart';
import 'package:stationx/data/health/health_sync_service.dart';
import 'package:stationx/data/health/health_sync_store.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/domain/domain.dart';

import 'health_sync_test.dart' show FakeHc;

class WatchHc extends FakeHc {
  List<BpmPoint> hr = [];
  int hrReads = 0;
  HealthHistoryAccess history = HealthHistoryAccess.needsGrant;
  int historyRequests = 0;
  int workoutReads = 0;
  final windows = <TimeSpan>[];
  List<StageSpan> stages = [];
  int sleepReads = 0;
  List<TimeSpan> sleepSess = [];
  List<BpmPoint> rhr = [];
  bool throwOnRead = false;

  @override
  Future<List<StageSpan>> sleepStages(DateTime a, DateTime b) async {
    sleepReads++;
    if (throwOnRead) throw StateError('read');
    return [
      for (final t in stages)
        if (t.to.isAfter(a) && t.from.isBefore(b)) t,
    ];
  }

  @override
  Future<List<TimeSpan>> sleepSessions(DateTime a, DateTime b) async => [
    for (final t in sleepSess)
      if (t.to.isAfter(a) && t.from.isBefore(b)) t,
  ];

  @override
  Future<List<BpmPoint>> restingHeartRate(DateTime a, DateTime b) async => [
    for (final p in rhr)
      if (!p.at.isBefore(a) && p.at.isBefore(b)) p,
  ];

  @override
  Future<List<BpmPoint>> heartRateSamples(DateTime a, DateTime b) async {
    hrReads++;
    return [
      for (final p in hr)
        if (!p.at.isBefore(a) && p.at.isBefore(b)) p,
    ];
  }

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

  group('heart-rate trend cost', () {
    List<BpmPoint> weekOfSamples() {
      final today = DateTime(now.year, now.month, now.day);
      return [
        for (var d = 0; d < 40; d++)
          (
            at: today.subtract(Duration(days: d)).add(const Duration(hours: 9)),
            bpm: 60.0 + d,
          ),
      ];
    }

    test('past days are read once; reopening only re-reads today', () async {
      await svc.enable(HealthFeature.enrichCardio);
      hc.hr = weekOfSamples();
      final first = await svc.heartRateTrend(7);
      expect(hc.hrReads, 7);
      hc.hrReads = 0;
      final again = await svc.heartRateTrend(7);
      expect(hc.hrReads, 1); // today only
      expect(
        [for (final d in again) d.average],
        [for (final d in first) d.average],
      );
    });

    test('a longer range reuses the days already read', () async {
      await svc.enable(HealthFeature.enrichCardio);
      hc.hr = weekOfSamples();
      await svc.heartRateTrend(7);
      hc.hrReads = 0;
      final t = await svc.heartRateTrend(30);
      expect(hc.hrReads, 30 - 6); // 6 cached past days; today is always re-read
      expect(t.length, 30);
      expect(t.last.average, 60); // today
    });

    test('the cache expires after half an hour', () async {
      await svc.enable(HealthFeature.enrichCardio);
      hc.hr = weekOfSamples();
      await svc.heartRateTrend(7);
      now = now.add(const Duration(minutes: 31));
      hc.hrReads = 0;
      await svc.heartRateTrend(7);
      expect(hc.hrReads, 7);
    });

    test('switching the heart-rate switch off clears it', () async {
      await svc.enable(HealthFeature.enrichCardio);
      hc.hr = weekOfSamples();
      await svc.heartRateTrend(7);
      await svc.disable(HealthFeature.enrichCardio);
      expect(
        (await svc.heartRateTrend(7)).every((d) => d.average == null),
        isTrue,
      );
      await svc.enable(HealthFeature.enrichCardio);
      hc.hrReads = 0;
      await svc.heartRateTrend(7);
      expect(hc.hrReads, 7);
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

    test(
      'heart rate switch off -> reported as off even when workouts exist',
      () async {
        await svc.enable(HealthFeature.importWorkouts);
        hc.external.add(
          wk('a', 'RUNNING', now.subtract(const Duration(days: 1))),
        );
        final d = await run();
        expect(d.step, WatchSetupStep.ok);
        expect(d.heartRate, WatchHeartRate.off);
      },
    );

    test('heart rate on but the watch wrote none -> noSamples', () async {
      await svc.enable(HealthFeature.importWorkouts);
      await svc.enable(HealthFeature.enrichCardio);
      hc.external.add(
        wk('a', 'RUNNING', now.subtract(const Duration(days: 1))),
      );
      final d = await run();
      expect(d.step, WatchSetupStep.ok);
      expect(d.heartRate, WatchHeartRate.noSamples);
    });

    test('heart rate on and samples exist -> found', () async {
      await svc.enable(HealthFeature.enrichCardio);
      hc.hr = [(at: now.subtract(const Duration(days: 1)), bpm: 80)];
      expect((await run()).heartRate, WatchHeartRate.found);
    });

    test(
      'heart rate only, no watch workouts -> says workouts are missing',
      () async {
        await svc.enable(HealthFeature.importWorkouts);
        await svc.enable(HealthFeature.enrichCardio);
        hc.hr = [(at: now.subtract(const Duration(days: 1)), bpm: 80)];
        // StationX's own saved workout is not watch data.
        hc.external.add(
          wk(
            'own',
            'RUNNING',
            now.subtract(const Duration(days: 1)),
            src: 'dev.mahdi_haji.stationx',
          ),
        );
        final d = await run();
        expect(d.step, WatchSetupStep.ok);
        expect(d.workoutsChecked, isTrue);
        expect(d.watchWorkouts, 0);
        expect(d.ownWorkouts, 1);
      },
    );

    test('watch workouts are counted separately from StationX ones', () async {
      await svc.enable(HealthFeature.importWorkouts);
      hc.external.add(
        wk('a', 'RUNNING', now.subtract(const Duration(days: 1))),
      );
      hc.external.add(
        wk('b', 'WALKING', now.subtract(const Duration(days: 2))),
      );
      final d = await run();
      expect(d.workoutsChecked, isTrue);
      expect(d.watchWorkouts, 2);
      expect(d.ownWorkouts, 0);
    });

    test('import switch off -> workouts not checked', () async {
      await svc.enable(HealthFeature.enrichCardio);
      hc.hr = [(at: now.subtract(const Duration(days: 1)), bpm: 80)];
      expect((await run()).workoutsChecked, isFalse);
    });
  });

  group('recovery report (sleep + resting heart rate)', () {
    // now = 2026-10-10 12:00; last night = 10-09 23:00 .. 10-10 07:00
    final bed = DateTime(2026, 10, 9, 23);
    final wake = DateTime(2026, 10, 10, 7);

    void night() {
      hc.sleepSess = [(from: bed, to: wake)];
      StageSpan st(SleepStage s, int start, int mins) => (
        from: bed.add(Duration(minutes: start)),
        to: bed.add(Duration(minutes: start + mins)),
        stage: s,
      );
      hc.stages = [
        st(SleepStage.light, 0, 200),
        st(SleepStage.deep, 200, 70),
        st(SleepStage.rem, 270, 105),
        st(SleepStage.light, 375, 85),
        st(SleepStage.awake, 460, 20),
      ];
    }

    // earlier nights: 23:00 -> 07:00 on 10-03 .. 10-09 wake days
    void priorNights({int mins = 480}) {
      hc.sleepSess = [
        for (var d = 3; d <= 9; d++)
          (
            from: DateTime(2026, 10, d, 7).subtract(Duration(minutes: mins)),
            to: DateTime(2026, 10, d, 7),
          ),
        ...hc.sleepSess,
      ];
    }

    test('switch off -> null and nothing is read', () async {
      night();
      expect(await svc.recoveryReport(), isNull);
      expect(hc.sleepReads, 0);
    });

    test('on: stages + session become a night with a verdict', () async {
      await svc.enable(HealthFeature.recovery);
      night();
      final r = (await svc.recoveryReport())!;
      expect(r.night!.deepMinutes, 70);
      expect(r.night!.asleepMinutes, 460);
      expect(r.night!.bedtime, bed);
      expect(r.verdict, RecoveryVerdict.ready);
      expect(r.quality, SleepQuality.great);
    });

    test('recorded resting heart rate: latest vs the earlier values', () async {
      await svc.enable(HealthFeature.recovery);
      night();
      hc.rhr = [
        (at: DateTime(2026, 10, 5, 7), bpm: 55),
        (at: DateTime(2026, 10, 6, 7), bpm: 54),
        (at: DateTime(2026, 10, 7, 7), bpm: 56),
        (at: DateTime(2026, 10, 8, 7), bpm: 55),
        (at: DateTime(2026, 10, 10, 6), bpm: 63),
      ];
      final r = (await svc.recoveryReport())!;
      expect(r.restingHr, 63);
      expect(r.restingBaseline, 55);
      expect(r.restingSource, RestingHrSource.recorded);
      expect(r.verdict, RecoveryVerdict.takeItEasy); // 8 above usual
    });

    test('no recorded value: estimated from heart rate during sleep', () async {
      await svc.enable(HealthFeature.recovery);
      await svc.enable(HealthFeature.enrichCardio);
      night();
      priorNights();
      // every night: 30 samples across the sleep, floor ~52 (last night 60)
      final samples = <BpmPoint>[];
      for (var d = 3; d <= 10; d++) {
        final start = DateTime(
          2026,
          10,
          d,
          7,
        ).subtract(const Duration(hours: 8));
        final floor = d == 10 ? 60.0 : 52.0;
        for (var i = 0; i < 30; i++) {
          samples.add((
            at: start.add(Duration(minutes: i * 15)),
            bpm: floor + (i % 10),
          ));
        }
      }
      hc.hr = samples;
      final r = (await svc.recoveryReport())!;
      expect(r.restingSource, RestingHrSource.estimated);
      expect(r.restingHr, closeTo(60, 1));
      expect(r.restingBaseline, closeTo(52, 1));
    });

    test('estimation needs the heart-rate switch', () async {
      await svc.enable(HealthFeature.recovery);
      night();
      hc.hr = [
        for (var i = 0; i < 30; i++)
          (at: bed.add(Duration(minutes: i * 15)), bpm: 55.0 + i % 5),
      ];
      expect((await svc.recoveryReport())!.restingHr, isNull);
    });

    test('history lists the last nights, oldest first', () async {
      await svc.enable(HealthFeature.recovery);
      night();
      priorNights(mins: 420);
      final r = (await svc.recoveryReport())!;
      expect(r.history.length, 7);
      expect(r.history.last.minutes, 480);
      expect(r.history.first.minutes, 420);
    });

    test(
      'enabled but the watch wrote nothing -> noData report, not null',
      () async {
        await svc.enable(HealthFeature.recovery);
        final r = (await svc.recoveryReport())!;
        expect(r.verdict, RecoveryVerdict.noData);
        expect(r.hasData, isFalse);
      },
    );

    test('permission revoked later -> null', () async {
      await svc.enable(HealthFeature.recovery);
      hc.granted.clear();
      expect(await svc.recoveryReport(), isNull);
    });

    test('a failing read never throws', () async {
      await svc.enable(HealthFeature.recovery);
      hc.throwOnRead = true;
      expect(await svc.recoveryReport(), isNull);
    });

    test('result is cached for a few minutes; force re-reads', () async {
      await svc.enable(HealthFeature.recovery);
      night();
      await svc.recoveryReport();
      final after1 = hc.sleepReads;
      await svc.recoveryReport();
      expect(hc.sleepReads, after1);
      now = now.add(const Duration(minutes: 6));
      await svc.recoveryReport();
      expect(hc.sleepReads, greaterThan(after1));
      final after3 = hc.sleepReads;
      await svc.recoveryReport(force: true);
      expect(hc.sleepReads, greaterThan(after3));
    });

    test(
      'a past day: that night with its own stages, not last night',
      () async {
        await svc.enable(HealthFeature.recovery);
        night(); // last night: wake 10-10 07:00
        // the night before: wake 10-08 07:00, 6h in bed, light only
        final b2 = DateTime(2026, 10, 7, 23);
        hc.sleepSess = [
          (from: b2, to: DateTime(2026, 10, 8, 5)),
          ...hc.sleepSess,
        ];
        hc.stages = [
          (from: b2, to: DateTime(2026, 10, 8, 5), stage: SleepStage.light),
          ...hc.stages,
        ];
        final r = (await svc.recoveryReport(day: DateTime(2026, 10, 8)))!;
        expect(r.night!.asleepMinutes, 360);
        expect(r.night!.deepMinutes, isNull);
        expect(r.night!.wake, DateTime(2026, 10, 8, 5));
        final today = (await svc.recoveryReport())!;
        expect(today.night!.deepMinutes, 70);
      },
    );

    test('a past day without sleep -> noData report', () async {
      await svc.enable(HealthFeature.recovery);
      night();
      final r = (await svc.recoveryReport(day: DateTime(2026, 10, 2)))!;
      expect(r.verdict, RecoveryVerdict.noData);
    });

    test(
      'sleepDays: minutes per wake day for the month, others left out',
      () async {
        await svc.enable(HealthFeature.recovery);
        hc.sleepSess = [
          (from: DateTime(2026, 9, 30, 23), to: DateTime(2026, 10, 1, 6, 30)),
          (from: DateTime(2026, 10, 4, 23), to: DateTime(2026, 10, 5, 7)),
          (from: DateTime(2026, 11, 2, 23), to: DateTime(2026, 11, 3, 7)),
        ];
        final m = await svc.sleepDays(DateTime(2026, 10));
        expect(m, {DateTime(2026, 10, 1): 450, DateTime(2026, 10, 5): 480});
      },
    );

    test('sleepDays is empty when off or not permitted', () async {
      hc.sleepSess = [
        (from: DateTime(2026, 10, 4, 23), to: DateTime(2026, 10, 5, 7)),
      ];
      expect(await svc.sleepDays(DateTime(2026, 10)), isEmpty);
      await svc.enable(HealthFeature.recovery);
      hc.granted.clear();
      expect(await svc.sleepDays(DateTime(2026, 10)), isEmpty);
    });

    test('turning the switch off clears what was cached', () async {
      await svc.enable(HealthFeature.recovery);
      night();
      expect(await svc.recoveryReport(), isNotNull);
      await svc.disable(HealthFeature.recovery);
      expect(await svc.recoveryReport(), isNull);
    });
  });
}
