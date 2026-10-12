// Snapshot of a live cardio session, persisted on the device so an OS kill (or the user closing the
// app) does not lose it. Device-local: never synced. Times are wall-clock timestamps, so a restored
// session keeps counting correctly across the time the app was closed.

import 'cardio.dart';

class ActiveCardioDraft {
  const ActiveCardioDraft({
    required this.kind,
    required this.startedAt,
    required this.activeMs,
    required this.pausedMs,
    this.runningSince,
    this.pausedSince,
    this.targetMinutes,
    this.targetKm,
    this.customActivityId,
    this.km,
    this.speedKmh,
    this.inclinePct,
    this.resistance,
    this.saveId,
  });

  final CardioKind kind;
  final DateTime startedAt;
  final int activeMs;
  final int pausedMs;

  /// Set while running; null while paused.
  final DateTime? runningSince;
  final DateTime? pausedSince;
  final int? targetMinutes;
  final double? targetKm;
  final String? customActivityId;
  final double? km;
  final double? speedKmh;
  final double? inclinePct;
  final int? resistance;

  /// Id reserved for the final save, so a retry after a lost response stays idempotent.
  final String? saveId;

  bool get paused => runningSince == null;

  int get activeSeconds {
    final live = runningSince == null
        ? 0
        : DateTime.now().difference(runningSince!).inMilliseconds;
    return (activeMs + live) ~/ 1000;
  }

  Map<String, Object?> toJson() => {
    'v': 1,
    'k': kind.name,
    'st': startedAt.toIso8601String(),
    'am': activeMs,
    'pm': pausedMs,
    if (runningSince != null) 'rs': runningSince!.toIso8601String(),
    if (pausedSince != null) 'ps': pausedSince!.toIso8601String(),
    if (targetMinutes != null) 'tm': targetMinutes,
    if (targetKm != null) 'tk': targetKm,
    if (customActivityId != null) 'ca': customActivityId,
    if (km != null) 'km': km,
    if (speedKmh != null) 'sp': speedKmh,
    if (inclinePct != null) 'in': inclinePct,
    if (resistance != null) 're': resistance,
    if (saveId != null) 'id': saveId,
  };

  factory ActiveCardioDraft.fromJson(Map<String, Object?> j) {
    DateTime? dt(String k) =>
        j[k] == null ? null : DateTime.parse(j[k] as String);
    return ActiveCardioDraft(
      kind: CardioKind.values.firstWhere(
        (e) => e.name == j['k'],
        orElse: () => CardioKind.custom,
      ),
      startedAt: DateTime.parse(j['st'] as String),
      activeMs: (j['am'] as num?)?.toInt() ?? 0,
      pausedMs: (j['pm'] as num?)?.toInt() ?? 0,
      runningSince: dt('rs'),
      pausedSince: dt('ps'),
      targetMinutes: (j['tm'] as num?)?.toInt(),
      targetKm: (j['tk'] as num?)?.toDouble(),
      customActivityId: j['ca'] as String?,
      km: (j['km'] as num?)?.toDouble(),
      speedKmh: (j['sp'] as num?)?.toDouble(),
      inclinePct: (j['in'] as num?)?.toDouble(),
      resistance: (j['re'] as num?)?.toInt(),
      saveId: j['id'] as String?,
    );
  }
}
