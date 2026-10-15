/// Sleep stage as the health store reports it (Health Connect / HealthKit).
enum SleepStage {
  deep,
  light,
  rem,

  /// Generic "asleep" with no stage detail (older / simpler devices).
  asleep,
  awake,
}

/// One night of sleep, summarised from the health store. Values are what the watch recorded;
/// nothing is estimated except when [hasStages] is false (then asleep time is the session length).
class SleepNight {
  const SleepNight({
    required this.bedtime,
    required this.wake,
    required this.stageMinutes,
    required this.asleepMinutes,
    required this.inBedMinutes,
  });

  final DateTime bedtime;
  final DateTime wake;

  /// Minutes per recorded stage (stages the device did not write are absent).
  final Map<SleepStage, int> stageMinutes;

  /// Time actually asleep: deep + light + REM + generic asleep, or the whole session when the
  /// device wrote no stages.
  final int asleepMinutes;

  /// Time from bedtime to wake-up.
  final int inBedMinutes;

  /// True when the device recorded real sleep stages (deep / light / REM / asleep).
  bool get hasStages => stageMinutes.keys.any((s) => s != SleepStage.awake);

  int? get deepMinutes => stageMinutes[SleepStage.deep];
  int? get remMinutes => stageMinutes[SleepStage.rem];
  int? get lightMinutes => stageMinutes[SleepStage.light];
  int get awakeMinutes => stageMinutes[SleepStage.awake] ?? 0;

  /// Share of the time in bed that was spent asleep (0..1), null without stage data.
  double? get efficiency => (hasStages && inBedMinutes > 0)
      ? (asleepMinutes / inBedMinutes).clamp(0.0, 1.0)
      : null;
}

/// Total sleep for one night, for the 7-night history.
class NightSummary {
  const NightSummary({required this.day, required this.minutes});

  /// The day the night ended on (the morning you woke up).
  final DateTime day;
  final int minutes;
}

enum SleepQuality { great, good, fair, poor }

enum RecoveryVerdict { ready, takeItEasy, needRest, noData }

/// Where the resting heart rate came from.
enum RestingHrSource {
  /// A resting-heart-rate record the watch or app wrote.
  recorded,

  /// Estimated from heart-rate samples during sleep (when no resting value was recorded).
  estimated,
}

enum ReasonTone { good, neutral, bad }

/// One plain-language line explaining the verdict.
class RecoveryReason {
  const RecoveryReason(this.text, this.tone);
  final String text;
  final ReasonTone tone;
}

/// Everything the Today card and the details page show. Built from the user's own data only.
class RecoveryReport {
  const RecoveryReport({
    required this.verdict,
    this.night,
    this.quality,
    this.score = 0,
    this.reasons = const [],
    this.restingHr,
    this.restingBaseline,
    this.restingSource,
    this.history = const [],
  });

  final RecoveryVerdict verdict;
  final SleepNight? night;
  final SleepQuality? quality;

  /// 0..100, used only to pick the verdict; the UI does not show it.
  final int score;
  final List<RecoveryReason> reasons;
  final int? restingHr;

  /// Average resting heart rate over the previous nights, when enough were available.
  final int? restingBaseline;
  final RestingHrSource? restingSource;

  /// Total sleep for the last 7 nights, oldest first.
  final List<NightSummary> history;

  bool get hasData => night != null || restingHr != null;

  int? get restingHrDelta => (restingHr != null && restingBaseline != null)
      ? restingHr! - restingBaseline!
      : null;
}
