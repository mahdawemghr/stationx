import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/domain/domain.dart';

typedef _Span = ({DateTime from, DateTime to});
typedef BpmPointT = ({DateTime at, double bpm});

_Span _s(DateTime a, int mins) => (from: a, to: a.add(Duration(minutes: mins)));

void main() {
  final night = DateTime(2026, 10, 14, 23);

  group('mergedMinutes', () {
    test('overlapping sources (phone + watch) are not double counted', () {
      expect(
        HealthSummary.mergedMinutes([
          _s(night, 360),
          _s(night.add(const Duration(minutes: 60)), 360),
        ]),
        420,
      );
    });
    test('gaps stay gaps; empty and reversed spans are 0', () {
      expect(
        HealthSummary.mergedMinutes([
          _s(night, 60),
          _s(night.add(const Duration(hours: 3)), 60),
        ]),
        120,
      );
      expect(HealthSummary.mergedMinutes(const []), 0);
      expect(HealthSummary.mergedMinutes([(from: night, to: night)]), 0);
    });
  });

  group('lastNightWindow', () {
    test('18:00 yesterday to 14:00 today', () {
      final w = HealthSummary.lastNightWindow(DateTime(2026, 10, 15, 8, 30));
      expect(w.from, DateTime(2026, 10, 14, 18));
      expect(w.to, DateTime(2026, 10, 15, 14));
    });
  });

  group('restingHr', () {
    test('latest and 7-day average; implausible values dropped', () {
      final r = HealthSummary.restingHr([
        (at: DateTime(2026, 10, 10), bpm: 60.0),
        (at: DateTime(2026, 10, 12), bpm: 64.0),
        (at: DateTime(2026, 10, 14), bpm: 62.0),
        (at: DateTime(2026, 10, 13), bpm: 0.0),
        (at: DateTime(2026, 10, 13, 12), bpm: 400.0),
      ]);
      expect(r.latest, 62);
      expect(r.average, 62);
    });
    test('nothing valid -> nulls', () {
      final r = HealthSummary.restingHr(const []);
      expect(r.latest, isNull);
      expect(r.average, isNull);
    });
  });

  group('sleepNight (stages)', () {
    // bed 23:00 -> wake 07:00 = 480 min in bed
    final bed = DateTime(2026, 10, 14, 23);
    final wake = DateTime(2026, 10, 15, 7);
    _Span session = (from: bed, to: wake);
    StageSpan st(SleepStage s, int startMin, int mins) => (
      from: bed.add(Duration(minutes: startMin)),
      to: bed.add(Duration(minutes: startMin + mins)),
      stage: s,
    );

    test(
      'Samsung-style stages: asleep = deep + light + REM, awake kept apart',
      () {
        final n = HealthSummary.sleepNight(
          stages: [
            st(SleepStage.light, 0, 200),
            st(SleepStage.deep, 200, 70),
            st(SleepStage.rem, 270, 100),
            st(SleepStage.light, 370, 90),
            st(SleepStage.awake, 460, 20),
          ],
          sessions: [session],
        )!;
        expect(n.bedtime, bed);
        expect(n.wake, wake);
        expect(n.inBedMinutes, 480);
        expect(n.deepMinutes, 70);
        expect(n.remMinutes, 100);
        expect(n.lightMinutes, 290);
        expect(n.awakeMinutes, 20);
        expect(n.asleepMinutes, 460);
        expect(n.hasStages, isTrue);
      },
    );

    test('phone + watch recording the same stages are not double counted', () {
      final n = HealthSummary.sleepNight(
        stages: [
          st(SleepStage.deep, 100, 60),
          st(SleepStage.deep, 100, 60),
          st(SleepStage.light, 0, 100),
        ],
        sessions: [session],
      )!;
      expect(n.deepMinutes, 60);
      expect(n.asleepMinutes, 160);
    });

    test('no stages: the whole session counts and hasStages is false', () {
      final n = HealthSummary.sleepNight(
        stages: const [],
        sessions: [session],
      )!;
      expect(n.asleepMinutes, 480);
      expect(n.hasStages, isFalse);
    });

    test('only an awake stage is not stage data', () {
      final n = HealthSummary.sleepNight(
        stages: [st(SleepStage.awake, 10, 30)],
        sessions: [session],
      )!;
      expect(n.hasStages, isFalse);
      expect(n.asleepMinutes, 450);
    });

    test('stages without a session still make a night', () {
      final n = HealthSummary.sleepNight(
        stages: [st(SleepStage.light, 0, 120), st(SleepStage.deep, 120, 60)],
        sessions: const [],
      )!;
      expect(n.bedtime, bed);
      expect(n.inBedMinutes, 180);
      expect(n.asleepMinutes, 180);
    });

    test(
      'the longest session wins over a short nap and stages outside it are clipped',
      () {
        final nap = (
          from: DateTime(2026, 10, 15, 13),
          to: DateTime(2026, 10, 15, 13, 30),
        );
        final n = HealthSummary.sleepNight(
          stages: [
            st(SleepStage.light, -60, 120), // starts an hour before bed
          ],
          sessions: [session, nap],
        )!;
        expect(n.bedtime, bed);
        expect(n.lightMinutes, 60); // clipped to the session
      },
    );

    test('nothing recorded -> null', () {
      expect(
        HealthSummary.sleepNight(stages: const [], sessions: const []),
        isNull,
      );
    });
  });

  group('nightHistory', () {
    test('one entry per wake day, oldest first, last 7 only', () {
      final spans = <_Span>[
        for (var d = 1; d <= 9; d++)
          (
            from: DateTime(2026, 10, d, 23).subtract(const Duration(days: 1)),
            to: DateTime(2026, 10, d, 6, 30),
          ),
      ];
      final h = HealthSummary.nightHistory(spans, nights: 7);
      expect(h.length, 7);
      expect(h.first.day, DateTime(2026, 10, 3));
      expect(h.last.day, DateTime(2026, 10, 9));
      expect(h.first.minutes, 450);
    });

    test('two sessions ending the same day add up', () {
      final h = HealthSummary.nightHistory([
        (from: DateTime(2026, 10, 9, 0), to: DateTime(2026, 10, 9, 5)),
        (from: DateTime(2026, 10, 9, 13), to: DateTime(2026, 10, 9, 14)),
      ]);
      expect(h.single.minutes, 360);
    });
  });

  group('restingFromSleepHr', () {
    final from = DateTime(2026, 10, 14, 23);
    final to = DateTime(2026, 10, 15, 7);
    List<BpmPointT> samples(List<double> bpm) => [
      for (final (i, b) in bpm.indexed)
        (at: from.add(Duration(minutes: i * 20)), bpm: b),
    ];

    test('averages the lowest ~15% of sleeping samples', () {
      // 20 samples: lowest 3 are 50, 51, 52 -> 51
      final bpm = [
        50, 51, 52, 58, 60, 61, 62, 63, 64, 65, //
        66, 67, 68, 70, 72, 74, 75, 76, 78, 80,
      ].map((e) => e.toDouble()).toList();
      expect(
        HealthSummary.restingFromSleepHr(samples(bpm), from: from, to: to),
        51,
      );
    });

    test(
      'too few samples -> null; outside the window and junk are ignored',
      () {
        expect(
          HealthSummary.restingFromSleepHr(
            samples([50, 51, 52]),
            from: from,
            to: to,
          ),
          isNull,
        );
        final mixed = [
          ...samples([for (var i = 0; i < 10; i++) 60.0 + i]),
          (
            at: to.add(const Duration(hours: 2)),
            bpm: 40.0,
          ), // awake, after the night
          (at: from.add(const Duration(minutes: 5)), bpm: 5.0), // junk
        ];
        expect(
          HealthSummary.restingFromSleepHr(mixed, from: from, to: to),
          isNotNull,
        );
        expect(
          HealthSummary.restingFromSleepHr(mixed, from: from, to: to)! >= 60,
          isTrue,
        );
      },
    );
  });

  test('recovery is a separate opt-in feature', () {
    expect(HealthFeature.values, contains(HealthFeature.recovery));
  });
}
