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
      if (await _gateway.availability() != GatewayAvailability.available) return false;
      final ok = await _gateway.requestFeaturePermissions(f);
      if (!ok) return false;
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
    _queueFor(WorkoutMapping.cardioKey(s.id), WorkoutMapping.forCardio(s, now: _clock()));
  }

  void onStrengthSaved(WorkoutSession s) {
    if (!isEnabled(HealthFeature.writeWorkouts)) return;
    _queueFor(WorkoutMapping.strengthKey(s.id), WorkoutMapping.forStrength(s, now: _clock()));
  }

  void onCardioDeleted(String id) => _queueDelete(WorkoutMapping.cardioKey(id));
  void onStrengthDeleted(String id) => _queueDelete(WorkoutMapping.strengthKey(id));

  void _queueFor(String key, HealthWriteRequest? req) {
    if (req == null) {
      _queueDelete(key); // no longer writable (e.g. duration removed): remove what we wrote
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
      _rerun = true; // something was queued meanwhile: run once more after this pass
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
  Future<HealthImportPlan?> planImport(CardioRepository cardio, {int? days}) async {
    if (!isEnabled(HealthFeature.importWorkouts)) return null;
    try {
      if (_gateway.canQueryPermissions &&
          !await _gateway.hasFeaturePermissions(HealthFeature.importWorkouts)) {
        return null;
      }
      final now = _clock();
      final d = HealthImport.clampDays(days);
      final found = await _gateway.readWorkouts(now.subtract(Duration(days: d)), now);
      return HealthImport.plan(
        found,
        ownSourceIds: _gateway.ownSourceIds,
        ownRecordIds: {for (final r in _state.receipts.values) r.workoutId},
        alreadyImported: _state.importedIds,
        existingSessionIds: {for (final s in cardio.sessions) s.id},
        sourceNote: 'Imported from ${provider.label}',
        now: now,
        days: d,
      );
    } catch (_) {
      return null;
    }
  }

  /// Adds the previewed sessions (after the user confirmed). Idempotent. Returns how many were added.
  Future<int> applyImport(HealthImportPlan plan, CardioRepository cardio) async {
    final added = await HealthImport.apply(plan, cardio);
    _state.importedIds.addAll(plan.externalIds);
    await _persist();
    notifyListeners();
    return added;
  }

  // ───────────────────────── automatic hooks ─────────────────────────

  CardioRepository? _cardio;
  SessionRepository? _sessions;
  Map<String, DateTime> _cardioSeen = {};
  Map<String, DateTime> _sessionSeen = {};

  /// Observes the repositories so every save / edit / delete anywhere in the app is mirrored,
  /// without feature code calling the service. Sessions that already exist are NOT written (only
  /// new or edited ones); sessions arriving from cloud sync or imports are ignored.
  void attach({required CardioRepository cardio, required SessionRepository sessions}) {
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

  static bool _foreignId(String id) => id.startsWith(HealthImport.idPrefix) || id.startsWith('gt_');

  bool _fresh(DateTime createdAt) => _clock().difference(createdAt).inHours < 24;

  void _onCardio() {
    final repo = _cardio;
    if (repo == null) return;
    final now = {for (final s in repo.sessions) s.id: s};
    for (final s in now.values) {
      final before = _cardioSeen[s.id];
      if (before != null && before == s.meta.updatedAt) continue;
      if (_foreignId(s.id)) continue;
      final known = _state.receipts.containsKey(WorkoutMapping.cardioKey(s.id));
      if (before == null ? _fresh(s.meta.createdAt) : (known || _fresh(s.meta.createdAt))) {
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
      final known = _state.receipts.containsKey(WorkoutMapping.strengthKey(s.id));
      if (before == null ? _fresh(s.meta.createdAt) : (known || _fresh(s.meta.createdAt))) {
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
