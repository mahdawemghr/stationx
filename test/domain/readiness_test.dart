import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/domain/domain.dart';

SleepNight night({
  required int asleep,
  int? deep,
  int? rem,
  int? light,
  int awake = 0,
  int? inBed,
}) {
  final stages = <SleepStage, int>{
    SleepStage.deep: ?deep,
    SleepStage.rem: ?rem,
    SleepStage.light: ?light,
    if (awake > 0) SleepStage.awake: awake,
  };
  final bed = inBed ?? asleep + awake;
  final b = DateTime(2026, 10, 14, 23);
  return SleepNight(
    bedtime: b,
    wake: b.add(Duration(minutes: bed)),
    stageMinutes: stages,
    asleepMinutes: asleep,
    inBedMinutes: bed,
  );
}

List<NightSummary> prior(List<int> minutes) => [
  for (final (i, m) in minutes.indexed)
    NightSummary(day: DateTime(2026, 10, 13 - i), minutes: m),
];

void main() {
  group('no data', () {
    test('no night -> noData, nothing invented', () {
      final r = ReadinessEngine.evaluate();
      expect(r.verdict, RecoveryVerdict.noData);
      expect(r.quality, isNull);
      expect(r.reasons, isEmpty);
    });
  });

  group('sleep quality + verdict (no heart rate)', () {
    test('8h, healthy deep + REM, little awake -> great and ready', () {
      final r = ReadinessEngine.evaluate(
        night: night(asleep: 480, deep: 70, rem: 105, light: 305, awake: 20),
      );
      expect(r.quality, SleepQuality.great);
      expect(r.verdict, RecoveryVerdict.ready);
      expect(
        r.reasons.any((x) => x.text.contains('Deep sleep 1h 10m')),
        isTrue,
      );
    });

    test('5h30 can never be "ready" even if stages look fine', () {
      final r = ReadinessEngine.evaluate(
        night: night(asleep: 330, deep: 45, rem: 65, light: 220),
      );
      expect(r.verdict, RecoveryVerdict.takeItEasy);
      expect(r.quality, isNot(SleepQuality.great));
    });

    test('under 5h -> needRest and poor', () {
      final r = ReadinessEngine.evaluate(
        night: night(asleep: 270, deep: 40, rem: 50, light: 180),
      );
      expect(r.verdict, RecoveryVerdict.needRest);
      expect(r.quality, SleepQuality.poor);
      expect(r.reasons.first.tone, ReasonTone.bad);
    });

    test('long but fragmented night: awake time is called out', () {
      final r = ReadinessEngine.evaluate(
        night: night(asleep: 420, deep: 50, rem: 80, light: 290, awake: 70),
      );
      expect(r.reasons.any((x) => x.text.contains('awake for 1h 10m')), isTrue);
    });

    test(
      'no stage data: still gives a verdict and says what it is based on',
      () {
        final r = ReadinessEngine.evaluate(night: night(asleep: 465));
        expect(r.verdict, RecoveryVerdict.ready);
        expect(r.night!.hasStages, isFalse);
        expect(
          r.reasons.any((x) => x.text.contains('did not record sleep stages')),
          isTrue,
        );
      },
    );
  });

  group('resting heart rate vs your baseline', () {
    final good = night(asleep: 480, deep: 70, rem: 105, light: 305, awake: 20);

    test('well above baseline downgrades an otherwise great night', () {
      final r = ReadinessEngine.evaluate(
        night: good,
        restingHr: 62,
        restingBaseline: 54,
        restingSource: RestingHrSource.estimated,
      );
      expect(r.verdict, RecoveryVerdict.takeItEasy);
      expect(
        r.reasons.any(
          (x) => x.text.contains('62 bpm') && x.tone == ReasonTone.bad,
        ),
        isTrue,
      );
    });

    test('a little above baseline keeps you ready', () {
      final r = ReadinessEngine.evaluate(
        night: good,
        restingHr: 55,
        restingBaseline: 54,
      );
      expect(r.verdict, RecoveryVerdict.ready);
    });

    test('below baseline is a good sign', () {
      final r = ReadinessEngine.evaluate(
        night: good,
        restingHr: 51,
        restingBaseline: 55,
      );
      expect(r.verdict, RecoveryVerdict.ready);
      expect(
        r.reasons.any(
          (x) => x.text.contains('51 bpm') && x.tone == ReasonTone.good,
        ),
        isTrue,
      );
    });

    test('without a baseline nothing is compared', () {
      final r = ReadinessEngine.evaluate(night: good, restingHr: 70);
      expect(r.verdict, RecoveryVerdict.ready);
      expect(r.reasons.any((x) => x.text.contains('bpm')), isFalse);
    });
  });

  group('sleep debt', () {
    test('several short nights pull a good night down a notch', () {
      final good = night(
        asleep: 480,
        deep: 70,
        rem: 105,
        light: 305,
        awake: 20,
      );
      final fresh = ReadinessEngine.evaluate(
        night: good,
        priorNights: prior([480, 470, 490, 480]),
      );
      final debt = ReadinessEngine.evaluate(
        night: good,
        priorNights: prior([330, 340, 320, 350, 335]),
      );
      expect(fresh.verdict, RecoveryVerdict.ready);
      expect(debt.score, lessThan(fresh.score));
      expect(debt.reasons.any((x) => x.text.contains('sleep debt')), isTrue);
    });

    test('fewer than 3 prior nights is not enough to judge', () {
      final good = night(
        asleep: 480,
        deep: 70,
        rem: 105,
        light: 305,
        awake: 20,
      );
      final r = ReadinessEngine.evaluate(
        night: good,
        priorNights: prior([300, 300]),
      );
      expect(r.reasons.any((x) => x.text.contains('sleep debt')), isFalse);
    });
  });

  test('score is always within 0..100', () {
    for (final a in [0, 60, 300, 480, 900]) {
      final r = ReadinessEngine.evaluate(
        night: night(asleep: a, deep: 500, rem: 500, light: 10),
        restingHr: 90,
        restingBaseline: 50,
      );
      expect(r.score, inInclusiveRange(0, 100));
    }
  });
}
