import '../models/models.dart';

/// Turns one night of sleep, the resting heart rate and the last few nights into a plain verdict.
///
/// The rules are deliberately simple and explainable (no hidden model), based on how sleep and
/// recovery are usually judged: enough sleep (adults need about 7 to 9 hours), a healthy share of
/// deep and REM sleep, few awake minutes, and a resting heart rate that is not above your own
/// recent normal. Everything is compared with the user's own numbers; no population "score".
abstract final class ReadinessEngine {
  /// What a good night looks like.
  static const targetMinutes = 480;

  static const _wDuration = 55.0;
  static const _wDeep = 20.0;
  static const _wEfficiency = 15.0;
  static const _wRem = 10.0;

  /// Healthy shares of sleep time (adults): deep about 13 to 23 %, REM about 20 to 25 %.
  static const _deepShare = 0.13;
  static const _remShare = 0.18;

  static RecoveryReport evaluate({
    SleepNight? night,
    List<NightSummary> priorNights = const [],
    int? restingHr,
    int? restingBaseline,
    RestingHrSource? restingSource,
    List<NightSummary> history = const [],
  }) {
    if (night == null) {
      return RecoveryReport(
        verdict: RecoveryVerdict.noData,
        restingHr: restingHr,
        restingBaseline: restingBaseline,
        restingSource: restingSource,
        history: history,
      );
    }
    final a = night.asleepMinutes;
    final reasons = <RecoveryReason>[];

    // ── sleep points: only the parts the watch actually recorded count ──
    var earned = _wDuration * (a / targetMinutes).clamp(0.0, 1.0);
    var weights = _wDuration;
    final deep = night.deepMinutes;
    if (deep != null && a > 0) {
      earned += _wDeep * ((deep / a) / _deepShare).clamp(0.0, 1.0);
      weights += _wDeep;
    }
    final rem = night.remMinutes;
    if (rem != null && a > 0) {
      earned += _wRem * ((rem / a) / _remShare).clamp(0.0, 1.0);
      weights += _wRem;
    }
    final eff = night.efficiency;
    if (eff != null) {
      earned += _wEfficiency * ((eff - 0.75) / 0.15).clamp(0.0, 1.0);
      weights += _wEfficiency;
    }
    final sleepPoints = (100 * earned / weights).round();

    // ── reasons, in the order a person reads them ──
    reasons.add(_durationReason(a));
    if (deep != null && a > 0) reasons.add(_deepReason(deep, a));
    if (rem != null && a > 0) reasons.add(_remReason(rem, a));
    if (night.awakeMinutes >= 45) {
      reasons.add(
        RecoveryReason(
          'You were awake for ${_dur(night.awakeMinutes)} during the night, which breaks up recovery.',
          ReasonTone.bad,
        ),
      );
    }
    if (eff != null && eff < 0.85) {
      reasons.add(
        RecoveryReason(
          'You spent ${_dur(night.inBedMinutes)} in bed but slept ${_dur(a)} (${(eff * 100).round()}%).',
          ReasonTone.neutral,
        ),
      );
    }
    if (!night.hasStages) {
      reasons.add(
        const RecoveryReason(
          'Your watch did not record sleep stages, so this is based on sleep time only.',
          ReasonTone.neutral,
        ),
      );
    }

    // ── adjustments from resting heart rate and recent nights ──
    var adjust = 0;
    final delta = (restingHr != null && restingBaseline != null)
        ? restingHr - restingBaseline
        : null;
    if (delta != null) {
      if (delta >= 7) {
        adjust -= 30;
      } else if (delta >= 4) {
        adjust -= 18;
      } else if (delta >= 2) {
        adjust -= 6;
      }
      reasons.add(_restingReason(restingHr!, restingBaseline!, delta));
    }
    final recent = priorNights.take(6).toList();
    if (recent.length >= 3) {
      final avg = recent.fold<int>(0, (t, n) => t + n.minutes) ~/ recent.length;
      if (avg < 360) {
        adjust -= 12;
      } else if (avg < 390) {
        adjust -= 6;
      }
      if (avg < 390) {
        reasons.add(
          RecoveryReason(
            'Your last ${recent.length} nights averaged ${_dur(avg)}, so you may be carrying sleep debt.',
            ReasonTone.bad,
          ),
        );
      }
    }

    // ── a short night caps everything, however good the stages look ──
    var score = sleepPoints + adjust;
    if (a < 300) {
      score = score.clamp(0, 40);
    } else if (a < 360) {
      score = score.clamp(0, 65);
    } else if (a < 420) {
      score = score.clamp(0, 85);
    }
    score = score.clamp(0, 100);

    var quality = sleepPoints >= 85
        ? SleepQuality.great
        : sleepPoints >= 70
        ? SleepQuality.good
        : sleepPoints >= 50
        ? SleepQuality.fair
        : SleepQuality.poor;
    if (a < 300) {
      quality = SleepQuality.poor;
    } else if (a < 360 && quality.index < SleepQuality.fair.index) {
      quality = SleepQuality.fair;
    } else if (a < 420 && quality.index < SleepQuality.good.index) {
      quality = SleepQuality.good;
    }

    return RecoveryReport(
      verdict: score >= 75
          ? RecoveryVerdict.ready
          : score >= 55
          ? RecoveryVerdict.takeItEasy
          : RecoveryVerdict.needRest,
      night: night,
      quality: quality,
      score: score,
      reasons: reasons,
      restingHr: restingHr,
      restingBaseline: restingBaseline,
      restingSource: restingSource,
      history: history,
    );
  }

  static RecoveryReason _durationReason(int a) {
    if (a >= targetMinutes) {
      return RecoveryReason(
        'You slept ${_dur(a)}, on target for ${_dur(targetMinutes)}.',
        ReasonTone.good,
      );
    }
    if (a >= 420) {
      return RecoveryReason(
        'You slept ${_dur(a)}, a little under your ${_dur(targetMinutes)} target.',
        ReasonTone.neutral,
      );
    }
    if (a >= 360) {
      return RecoveryReason(
        'You slept ${_dur(a)}, ${_dur(targetMinutes - a)} short of your ${_dur(targetMinutes)} target.',
        ReasonTone.bad,
      );
    }
    return RecoveryReason(
      'You slept only ${_dur(a)}, well under the 7 to 9 hours adults need.',
      ReasonTone.bad,
    );
  }

  static RecoveryReason _deepReason(int deep, int a) {
    final share = deep / a;
    final pct = (share * 100).round();
    if (share >= _deepShare) {
      return RecoveryReason(
        'Deep sleep ${_dur(deep)} ($pct% of your sleep) is healthy. This is when your body repairs muscle.',
        ReasonTone.good,
      );
    }
    if (share >= 0.08) {
      return RecoveryReason(
        'Deep sleep was ${_dur(deep)} ($pct% of your sleep), a little low.',
        ReasonTone.neutral,
      );
    }
    return RecoveryReason(
      'Deep sleep was only ${_dur(deep)} ($pct% of your sleep), which is low for muscle repair.',
      ReasonTone.bad,
    );
  }

  static RecoveryReason _remReason(int rem, int a) {
    final share = rem / a;
    final pct = (share * 100).round();
    return share >= _remShare
        ? RecoveryReason(
            'REM sleep ${_dur(rem)} ($pct%) supports memory and mood.',
            ReasonTone.good,
          )
        : RecoveryReason(
            'REM sleep was ${_dur(rem)} ($pct%), on the low side.',
            ReasonTone.neutral,
          );
  }

  static RecoveryReason _restingReason(int hr, int base, int delta) {
    if (delta >= 4) {
      return RecoveryReason(
        'Resting heart rate $hr bpm is $delta above your usual $base, a sign your body is still recovering.',
        ReasonTone.bad,
      );
    }
    if (delta <= -2) {
      return RecoveryReason(
        'Resting heart rate $hr bpm is ${-delta} below your usual $base, a good sign of recovery.',
        ReasonTone.good,
      );
    }
    return RecoveryReason(
      'Resting heart rate $hr bpm is in line with your usual $base.',
      ReasonTone.good,
    );
  }

  /// "7h 10m", "7h", "50m".
  static String _dur(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
