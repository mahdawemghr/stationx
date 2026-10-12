import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';
import 'health_gateway.dart';
import 'health_sync_store.dart';

/// What the health settings area should show when something is wrong.
enum HealthSyncIssue { none, needsPermission, retrying }

/// Opt-in two-way workout integration with Health Connect / Apple Health.
///
///  * WRITE ([HealthFeature.writeWorkouts]): finished cardio / strength sessions are saved as one
///    exercise session each; edits replace, deletes remove only what StationX wrote.
///  * ENRICH ([HealthFeature.enrichCardio]): suggests heart rate / calories for a cardio session.
///  * IMPORT ([HealthFeature.importWorkouts]): previews sessions recorded by other apps.
///
/// Local-first: nothing here ever blocks or fails a local save. Failed writes are queued
/// (persisted) and retried by [retryPending]. With a feature OFF no health-store call is made.
class HealthSyncService extends ChangeNotifier {
  HealthSyncService(this._gateway, this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      _state = _store.load();

  final HealthGateway _gateway;
  final HealthSyncStore _store;
  final DateTime Function() _clock;
  final HealthSyncState _state;

  HealthProvider get provider => _gateway.provider;
  Future<GatewayAvailability> availability() => _gateway.availability();

  bool isEnabled(HealthFeature f) => _state.enabled.contains(f);

  /// Operations waiting to be sent (failed or enabled-while-offline).
  int get pendingCount => _state.pending.length;
  DateTime? lastSuccessAt;
  HealthSyncIssue _issue = HealthSyncIssue.none;
  HealthSyncIssue get issue => _issue;

  /// Sessions currently saved in the health store by StationX (for display).
  int get savedCount => _state.receipts.length;

  // ───────────────────────── opt-in ─────────────────────────

  /// Asks the system for exactly the permissions [f] needs and turns it on only when granted.
  /// Call ONLY after the explanation screen was accepted.
  Future<bool> enable(HealthFeature f) async {
    try {
      if (await _gateway.availability() != GatewayAvailability.available) {
        return false;
      }
      final ok = await _gateway.requestFeaturePermissions(f);
      if (!ok) return false;
      // Import also asks to read older data (otherwise Android only returns ~30 days). Optional:
      // a "no" here never blocks the feature.
      if (f == HealthFeature.importWorkouts &&
          await _gateway.historyAccess() == HealthHistoryAccess.needsGrant) {
        await _gateway.requestHistoryAccess();
      }
    } catch (_) {
      return false;
    }
    _state.enabled.add(f);
    await _persist();
    _issue = HealthSyncIssue.none;
    notifyListeners();
    unawaited(retryPending());
    return true;
  }

  /// Turns [f] off. Queued writes are dropped (queued deletes stay and run if it is re-enabled).
  /// Already-saved health records are left alone; the user can delete them in the health app.
  Future<void> disable(HealthFeature f) async {
    _state.enabled.remove(f);
    if (f == HealthFeature.writeWorkouts) {
      _state.pending.removeWhere((_, o) => !o.isDelete);
    }
    await _persist();
    notifyListeners();
  }

  /// Re-checks the OS permissions of every enabled feature (Android only).
  Future<void> refreshPermissions() async {
    if (!_gateway.canQueryPermissions) return;
    var missing = false;
    for (final f in _state.enabled) {
      if (!await _gateway.hasFeaturePermissions(f)) missing = true;
    }
    _issue = missing
        ? HealthSyncIssue.needsPermission
        : (_state.pending.isEmpty ? HealthSyncIssue.none : _issue);
    notifyListeners();
  }

  // ───────────────────────── write ─────────────────────────

  void onCardioSaved(CardioSession s) {
    if (!isEnabled(HealthFeature.writeWorkouts)) return;
    _queueFor(
      WorkoutMapping.cardioKey(s.id),
      WorkoutMapping.forCardio(s, now: _clock()),
    );
  }

  void onStrengthSaved(WorkoutSession s) {
    if (!isEnabled(HealthFeature.writeWorkouts)) return;
    _queueFor(
      WorkoutMapping.strengthKey(s.id),
      WorkoutMapping.forStrength(s, now: _clock()),
    );
  }

  void onCardioDeleted(String id) => _queueDelete(WorkoutMapping.cardioKey(id));
  void onStrengthDeleted(String id) =>
      _queueDelete(WorkoutMapping.strengthKey(id));

  void _queueFor(String key, HealthWriteRequest? req) {
    if (req == null) {
      _queueDelete(
        key,
      ); // no longer writable (e.g. duration removed): remove what we wrote
      return;
    }
    _state.pending[key] = PendingHealthOp.upsert(req);
    _afterQueue();
  }

  void _queueDelete(String key) {
    if (_state.receipts.containsKey(key)) {
      _state.pending[key] = PendingHealthOp.delete();
    } else {
      _state.pending.remove(key);
    }
    _afterQueue();
  }

  void _afterQueue() {
    unawaited(_persist());
    notifyListeners();
    unawaited(retryPending());
  }

  Future<void>? _flushing;

  /// Sends queued operations. Single-flight; never throws.
  Future<void> retryPending() {
    final running = _flushing;
    if (running != null) {
      _rerun =
          true; // something was queued meanwhile: run once more after this pass
      return running;
    }
    return _flushing = _loop();
  }

  bool _rerun = false;

  Future<void> _loop() async {
    try {
      do {
        _rerun = false;
        await _flush();
      } while (_rerun);
    } finally {
      _flushing = null;
    }
  }

  Future<void> _flush() async {
    try {
      if (!isEnabled(HealthFeature.writeWorkouts) || _state.pending.isEmpty) {
        return;
      }
      if (_gateway.canQueryPermissions &&
          !await _gateway.hasFeaturePermissions(HealthFeature.writeWorkouts)) {
        _issue = HealthSyncIssue.needsPermission;
        notifyListeners();
        return;
      }
      var failed = false;
      for (final key in _state.pending.keys.toList()) {
        final op = _state.pending[key];
        if (op == null) continue;
        final ok = await _run(key, op);
        if (ok) {
          if (identical(_state.pending[key], op)) _state.pending.remove(key);
          lastSuccessAt = _clock();
        } else {
          op.attempts++;
          failed = true;
        }
      }
      _issue = failed ? HealthSyncIssue.retrying : HealthSyncIssue.none;
      await _persist();
      notifyListeners();
    } catch (e) {
      debugPrint('Health sync flush failed: ${e.runtimeType}');
      _issue = HealthSyncIssue.retrying;
    }
  }

  Future<bool> _run(String key, PendingHealthOp op) async {
    try {
      final prev = _state.receipts[key];
      if (op.isDelete) {
        if (prev == null) return true;
        if (!await _gateway.deleteWorkout(prev)) return false;
        _state.receipts.remove(key);
        return true;
      }
      // Replace: remove what StationX wrote before, then write the current version.
      if (prev != null) {
        if (!await _gateway.deleteWorkout(prev)) return false;
        _state.receipts.remove(key);
        await _persist(); // crash-safe: the old record is gone, so don't try to delete it again
      }
      final receipt = await _gateway.writeWorkout(op.request!);
      if (receipt == null) return false;
      _state.receipts[key] = receipt;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ───────────────────────── enrich ─────────────────────────

  /// Suggested heart rate / calories for [s] from the health store, or null. Never changes
  /// anything: the UI shows the values and calls [HealthEnrichmentService.apply] after confirmation.
  Future<HealthEnrichment?> suggestEnrichment(CardioSession s) async {
    if (!isEnabled(HealthFeature.enrichCardio)) return null;
    if (s.avgHeartRate != null && s.calories != null) return null;
    if (s.durationSeconds <= 0) return null;
    try {
      if (_gateway.canQueryPermissions &&
          !await _gateway.hasFeaturePermissions(HealthFeature.enrichCardio)) {
        return null;
      }
      final m = await _gateway.readMetrics(
        s.workoutDate,
        s.workoutDate.add(Duration(seconds: s.durationSeconds)),
      );
      if (m == null) return null;
      final e = HealthEnrichmentService.suggest(s, m);
      return e.isEmpty ? null : e;
    } catch (_) {
      return null;
    }
  }

  // ───────────────────────── import ─────────────────────────

  /// Preview of sessions other apps recorded in the last [days] (default 30, max 90). Null when
  /// import is off or not permitted. Changes nothing.
  Future<HealthImportPlan?> planImport(
    CardioRepository cardio, {
    int? days,
    SessionRepository? sessions,
  }) async {
    if (!isEnabled(HealthFeature.importWorkouts)) return null;
    try {
      if (_gateway.canQueryPermissions &&
          !await _gateway.hasFeaturePermissions(HealthFeature.importWorkouts)) {
        return null;
      }
      final now = _clock();
      final d = HealthImport.clampDays(days);
      final found = await _readWorkoutsChunked(
        now.subtract(Duration(days: d)),
        now,
      );
      final sessionRepo = sessions ?? _sessions;
      return HealthImport.plan(
        found,
        ownSourceIds: _gateway.ownSourceIds,
        ownRecordIds: {for (final r in _state.receipts.values) r.workoutId},
        alreadyImported: _state.importedIds,
        existingSessionIds: {for (final s in cardio.sessions) s.id},
        existingStrengthIds: {
          if (sessionRepo != null)
            for (final s in sessionRepo.sessions) s.id,
        },
        sourceNote: 'Imported from ${provider.label}',
        now: now,
        days: d,
      );
    } catch (_) {
      return null;
    }
  }

  /// Adds the previewed sessions (after the user confirmed). Idempotent. Returns how many were added.
  Future<int> applyImport(
    HealthImportPlan plan,
    CardioRepository cardio, {
    SessionRepository? sessions,
  }) async {
    final repo = sessions ?? _sessions;
    final added = await HealthImport.apply(plan, cardio, repo);
    _state.importedIds.addAll(
      repo == null ? plan.externalIds : plan.allExternalIds,
    );
    await _persist();
    notifyListeners();
    // Watch heart rate for what was just imported (best effort, only if that feature is on).
    unawaited(_attachHeartRates(plan));
    return added;
  }

  Future<void> _attachHeartRates(HealthImportPlan plan) async {
    for (final s in plan.sessions) {
      await heartRateFor(
        WorkoutMapping.cardioKey(s.id),
        s.workoutDate,
        s.workoutDate.add(Duration(seconds: s.durationSeconds)),
      );
    }
    for (final s in plan.strengthSessions) {
      await heartRateFor(
        WorkoutMapping.strengthKey(s.id),
        s.workoutDate,
        s.workoutDate.add(Duration(seconds: s.durationSeconds)),
      );
    }
  }

  /// Reads long ranges in 60-day windows (the platform call is slow and can time out on a big
  /// span) and drops records that overlap two windows.
  Future<List<HealthWorkout>> _readWorkoutsChunked(
    DateTime from,
    DateTime to,
  ) async {
    const step = Duration(days: 60);
    final seen = <String>{};
    final out = <HealthWorkout>[];
    var start = from;
    while (start.isBefore(to)) {
      var end = start.add(step);
      if (end.isAfter(to)) end = to;
      for (final w in await _gateway.readWorkouts(start, end)) {
        if (seen.add(w.id)) out.add(w);
      }
      start = end;
    }
    return out;
  }

  // ───────────────────────── older data ─────────────────────────

  Future<HealthHistoryAccess> historyAccess() async {
    try {
      return await _gateway.historyAccess();
    } catch (_) {
      return HealthHistoryAccess.notSupported;
    }
  }

  Future<bool> requestHistoryAccess() async {
    try {
      return await _gateway.requestHistoryAccess();
    } catch (_) {
      return false;
    }
  }

  // ───────────────────────── automatic import ─────────────────────────

  static const autoImportEvery = Duration(hours: 6);
  bool get autoImportEnabled =>
      _state.autoImport && isEnabled(HealthFeature.importWorkouts);

  /// Set by [autoImport] when new workouts arrived; the shell shows it once via [takeAutoImportNotice].
  int _autoNotice = 0;
  int takeAutoImportNotice() {
    final n = _autoNotice;
    _autoNotice = 0;
    return n;
  }

  Future<void> setAutoImport(bool on) async {
    _state.autoImport = on;
    await _persist();
    notifyListeners();
    if (on) unawaited(autoImport(force: true));
  }

  bool _autoRunning = false;

  /// Imports new workouts without a preview. Silent on any failure. At most every
  /// [autoImportEvery] unless [force]. Returns how many were added.
  Future<int> autoImport({bool force = false}) async {
    if (!autoImportEnabled || _autoRunning) return 0;
    final cardio = _cardio;
    if (cardio == null) return 0;
    final now = _clock();
    final last = _state.lastAutoImportMs;
    if (!force && last != null) {
      final since = now.difference(DateTime.fromMillisecondsSinceEpoch(last));
      if (!since.isNegative && since < autoImportEvery) return 0;
    }
    _autoRunning = true;
    try {
      // First run reaches back 90 days; later runs only the gap (at least a week of overlap).
      final days = last == null
          ? 90
          : (now.difference(DateTime.fromMillisecondsSinceEpoch(last)).inDays +
                7);
      final plan = await planImport(cardio, days: days);
      if (plan == null) return 0; // not permitted / failed: try again next time
      _state.lastAutoImportMs = now.millisecondsSinceEpoch;
      if (plan.isEmpty) {
        await _persist();
        return 0;
      }
      final added = await applyImport(plan, cardio);
      _autoNotice += added;
      notifyListeners();
      return added;
    } catch (_) {
      return 0;
    } finally {
      _autoRunning = false;
    }
  }

  // ───────────────────────── heart rate on workouts ─────────────────────────

  /// Heart rate remembered for a session, or null.
  HrStats? cachedHeartRate(String key) => _state.heartRates[key];

  /// Average / max heart rate between [start] and [end] from the health store (cached once found).
  /// Null when the feature is off, not permitted, or the watch recorded nothing (yet): not cached
  /// then, so a later call can succeed after the watch syncs.
  Future<HrStats?> heartRateFor(
    String key,
    DateTime start,
    DateTime end,
  ) async {
    final cached = _state.heartRates[key];
    if (cached != null) return cached;
    if (!isEnabled(HealthFeature.enrichCardio) || !end.isAfter(start)) {
      return null;
    }
    try {
      if (_gateway.canQueryPermissions &&
          !await _gateway.hasFeaturePermissions(HealthFeature.enrichCardio)) {
        return null;
      }
      final samples = await _gateway.heartRateSamples(start, end);
      final stats = HealthEnrichmentService.statsFor([
        for (final p in samples) p.bpm,
      ]);
      if (stats == null) return null;
      _state.heartRates[key] = stats;
      await _persist();
      notifyListeners();
      return stats;
    } catch (_) {
      return null;
    }
  }

  /// Drops a remembered value so the next [heartRateFor] re-reads (after the user edits times).
  Future<void> forgetHeartRate(String key) async {
    if (_state.heartRates.remove(key) != null) await _persist();
  }

  /// Most recent heart-rate sample from the last [within], or null. For the live chip.
  Future<BpmPoint?> latestHeartRate({
    Duration within = const Duration(minutes: 2),
  }) async {
    if (!isEnabled(HealthFeature.enrichCardio)) return null;
    try {
      final now = _clock();
      if (_gateway.canQueryPermissions &&
          !await _gateway.hasFeaturePermissions(HealthFeature.enrichCardio)) {
        return null;
      }
      final samples = await _gateway.heartRateSamples(
        now.subtract(within),
        now.add(const Duration(minutes: 1)),
      );
      BpmPoint? best;
      for (final p in samples) {
        if (p.bpm < HealthEnrichmentService.minBpm ||
            p.bpm > HealthEnrichmentService.maxBpm) {
          continue;
        }
        if (best == null || p.at.isAfter(best.at)) best = p;
      }
      return best;
    } catch (_) {
      return null;
    }
  }

  /// Average heart rate per day for the last [days] days (oldest first). Needs the heart-rate
  /// permission ([HealthFeature.enrichCardio]).
  Future<List<HeartRateDay>> heartRateTrend(int days) async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final first = today.subtract(Duration(days: days - 1));
    try {
      final sums = <DateTime, (double, int)>{};
      if (isEnabled(HealthFeature.enrichCardio) &&
          (!_gateway.canQueryPermissions ||
              await _gateway.hasFeaturePermissions(
                HealthFeature.enrichCardio,
              ))) {
        // One day at a time keeps each platform call small (a watch writes a sample per minute).
        for (var i = 0; i < days; i++) {
          final d0 = first.add(Duration(days: i));
          final d1 = i == days - 1 ? now : first.add(Duration(days: i + 1));
          final pts = await _gateway.heartRateSamples(d0, d1);
          final ok = [
            for (final p in pts)
              if (p.bpm >= HealthEnrichmentService.minBpm &&
                  p.bpm <= HealthEnrichmentService.maxBpm)
                p.bpm,
          ];
          if (ok.isNotEmpty) sums[d0] = (ok.reduce((a, b) => a + b), ok.length);
        }
      }
      return [
        for (var i = 0; i < days; i++)
          () {
            final d = first.add(Duration(days: i));
            final sm = sums[d];
            return HeartRateDay(
              day: d,
              average: sm == null ? null : sm.$1 / sm.$2,
            );
          }(),
      ];
    } catch (_) {
      return const [];
    }
  }

  // ───────────────────────── setup check ─────────────────────────

  /// Finds the first reason watch data does not reach StationX. Reads only the last 7 days and
  /// changes nothing.
  Future<WatchDiagnosis> diagnose() async {
    try {
      final a = await _gateway.availability();
      if (a != GatewayAvailability.available) {
        return const WatchDiagnosis(step: WatchSetupStep.storeMissing);
      }
      var granted =
          isEnabled(HealthFeature.importWorkouts) ||
          isEnabled(HealthFeature.enrichCardio);
      if (granted && _gateway.canQueryPermissions) {
        granted =
            (!isEnabled(HealthFeature.importWorkouts) ||
                await _gateway.hasFeaturePermissions(
                  HealthFeature.importWorkouts,
                )) &&
            (!isEnabled(HealthFeature.enrichCardio) ||
                await _gateway.hasFeaturePermissions(
                  HealthFeature.enrichCardio,
                ));
      }
      if (!granted) {
        return const WatchDiagnosis(step: WatchSetupStep.permissions);
      }
      final now = _clock();
      final from = now.subtract(const Duration(days: 7));
      final workouts = isEnabled(HealthFeature.importWorkouts)
          ? await _gateway.readWorkouts(from, now)
          : const <HealthWorkout>[];
      final hr = isEnabled(HealthFeature.enrichCardio)
          ? (await _gateway.heartRateSamples(from, now)).length
          : 0;
      return HealthEnrichmentService.diagnose(
        storeAvailable: true,
        permissionsGranted: true,
        recentWorkouts: workouts,
        recentHeartRateSamples: hr,
        ownSourceIds: _gateway.ownSourceIds,
        knownSources: HealthImport.knownSources,
      );
    } catch (_) {
      return const WatchDiagnosis(step: WatchSetupStep.noRecentData);
    }
  }

  // ───────────────────────── automatic hooks ─────────────────────────

  CardioRepository? _cardio;
  SessionRepository? _sessions;
  Map<String, DateTime> _cardioSeen = {};
  Map<String, DateTime> _sessionSeen = {};

  /// Observes the repositories so every save / edit / delete anywhere in the app is mirrored,
  /// without feature code calling the service. Sessions that already exist are NOT written (only
  /// new or edited ones); sessions arriving from cloud sync or imports are ignored.
  void attach({
    required CardioRepository cardio,
    required SessionRepository sessions,
  }) {
    detach();
    _cardio = cardio;
    _sessions = sessions;
    _cardioSeen = {for (final s in cardio.sessions) s.id: s.meta.updatedAt};
    _sessionSeen = {for (final s in sessions.sessions) s.id: s.meta.updatedAt};
    cardio.addListener(_onCardio);
    sessions.addListener(_onSessions);
  }

  void detach() {
    _cardio?.removeListener(_onCardio);
    _sessions?.removeListener(_onSessions);
    _cardio = null;
    _sessions = null;
  }

  @override
  void dispose() {
    detach();
    super.dispose();
  }

  static bool _foreignId(String id) =>
      id.startsWith(HealthImport.idPrefix) || id.startsWith('gt_');

  bool _fresh(DateTime createdAt) =>
      _clock().difference(createdAt).inHours < 24;

  void _onCardio() {
    final repo = _cardio;
    if (repo == null) return;
    final now = {for (final s in repo.sessions) s.id: s};
    for (final s in now.values) {
      final before = _cardioSeen[s.id];
      if (before != null && before == s.meta.updatedAt) continue;
      if (_foreignId(s.id)) continue;
      final known = _state.receipts.containsKey(WorkoutMapping.cardioKey(s.id));
      if (before == null
          ? _fresh(s.meta.createdAt)
          : (known || _fresh(s.meta.createdAt))) {
        onCardioSaved(s);
      }
    }
    for (final id in _cardioSeen.keys) {
      if (!now.containsKey(id)) onCardioDeleted(id);
    }
    _cardioSeen = {for (final e in now.entries) e.key: e.value.meta.updatedAt};
  }

  void _onSessions() {
    final repo = _sessions;
    if (repo == null) return;
    final now = {for (final s in repo.sessions) s.id: s};
    for (final s in now.values) {
      final before = _sessionSeen[s.id];
      if (before != null && before == s.meta.updatedAt) continue;
      if (_foreignId(s.id)) continue;
      final known = _state.receipts.containsKey(
        WorkoutMapping.strengthKey(s.id),
      );
      if (before == null
          ? _fresh(s.meta.createdAt)
          : (known || _fresh(s.meta.createdAt))) {
        onStrengthSaved(s);
      }
    }
    for (final id in _sessionSeen.keys) {
      if (!now.containsKey(id)) onStrengthDeleted(id);
    }
    _sessionSeen = {for (final e in now.entries) e.key: e.value.meta.updatedAt};
  }

  Future<void> _persist() => _store.save(_state);
}
