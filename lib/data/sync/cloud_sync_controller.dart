import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'cloud_auth.dart';
import 'sync_engine.dart';
import 'sync_local_store.dart';

enum CloudSyncPhase {
  /// This build has no cloud configuration — the feature is hidden entirely.
  unavailable,
  signedOut,
  idle,
  syncing,
  error,
}

/// Why the last sync failed, in user-facing terms (never raw exception text).
enum CloudSyncProblem { offline, signedOut, server }

/// Coordinates optional cloud sync: auth state, when to sync (sign-in, local
/// changes with a debounce, app resume, manual, retry), and the status the UI shows.
/// Single-flight: at most one sync runs; a request during a run triggers one more pass.
/// The app is fully usable without any of this; sync never blocks the UI or throws.
class CloudSyncController extends ChangeNotifier {
  CloudSyncController({
    required this.auth,
    SyncEngine? engine,
    SyncLocalStore? local,
    this.preferCloudProfile,
    this.debounce = const Duration(seconds: 8),
    this.resumeThrottle = const Duration(minutes: 2),
    this.retryAfter = const Duration(minutes: 1),
    DateTime Function()? clock,
  })  : _engine = engine,
        _local = local,
        _clock = clock ?? DateTime.now {
    auth.addListener(_onAuthChanged);
  }

  /// No cloud configured: reports [CloudSyncPhase.unavailable] and does nothing.
  factory CloudSyncController.unavailable() => CloudSyncController(auth: NoCloudAuth());

  final CloudAuth auth;
  final SyncEngine? _engine;
  final SyncLocalStore? _local;

  /// True when the local profile is only a guest default, so the cloud profile should win.
  final bool Function()? preferCloudProfile;
  final Duration debounce;
  final Duration resumeThrottle;
  final Duration retryAfter;
  final DateTime Function() _clock;

  bool get available => auth.isConfigured && _engine != null && _local != null;
  CloudUser? get user => auth.user;

  CloudSyncPhase _phase = CloudSyncPhase.signedOut;
  CloudSyncProblem? _problem;
  DateTime? _lastSyncAt;
  int _pending = 0;
  bool _running = false;
  bool _again = false;
  bool _needsDecision = false;
  DateTime? _lastAttempt;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _disposed = false;

  CloudSyncPhase get phase {
    if (!available) return CloudSyncPhase.unavailable;
    if (user == null) return CloudSyncPhase.signedOut;
    return _phase;
  }

  CloudSyncProblem? get problem => _problem;
  DateTime? get lastSyncAt => _lastSyncAt;

  /// Local changes not yet uploaded.
  int get pending => _pending;

  /// A different account signed in on a device with data: the UI must ask the user.
  bool get needsAccountDecision => _needsDecision;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _onAuthChanged() {
    if (user == null) {
      _debounceTimer?.cancel();
      _retryTimer?.cancel();
      _phase = CloudSyncPhase.signedOut;
    }
    _notify();
  }

  /// Load persisted status; if already signed in, sync in the background.
  Future<void> init() async {
    if (!available) return;
    final state = await _local!.loadState();
    _lastSyncAt = state.lastSyncAt;
    _pending = await _local.pendingCount();
    _phase = CloudSyncPhase.idle;
    _notify();
    if (user != null) unawaited(syncNow());
  }

  // ───────────────────────── account actions ─────────────────────────

  Future<CloudAuthResult> signIn(String email, String password) async {
    final r = await auth.signIn(email, password);
    // Await the first sync so the caller can react (e.g. ask what to do with another account's data).
    if (r.ok) await syncNow();
    return r;
  }

  Future<CloudAuthResult> signUp(String email, String password, {String? name}) async {
    final r = await auth.signUp(email, password, name: name);
    if (r.ok) await syncNow();
    return r;
  }

  /// Sign out of the cloud. Local data stays on this device and the account link is
  /// remembered, so signing back in as the same user simply continues.
  Future<void> signOut() async {
    await auth.signOut();
    _needsDecision = false;
    _problem = null;
    _phase = CloudSyncPhase.signedOut;
    _notify();
  }

  /// Sign out AND forget the account link (used when the user wipes this device).
  Future<void> forgetThisDevice() async {
    await signOut();
    await _local?.saveState(const SyncState());
    _lastSyncAt = null;
    _pending = 0;
    _notify();
  }

  /// Permanently deletes the cloud account and its cloud data. Local data is kept.
  Future<CloudAuthResult> deleteCloudAccount() async {
    final r = await auth.deleteAccount();
    if (r.ok) {
      _needsDecision = false;
      _problem = null;
      _phase = CloudSyncPhase.signedOut;
      await _local?.saveState(const SyncState());
      _lastSyncAt = null;
      _notify();
    }
    return r;
  }

  // ───────────────────────── syncing ─────────────────────────

  /// Runs a sync now (or queues one if already running). Returns the last result.
  Future<SyncResult> syncNow({AccountSwitch decision = AccountSwitch.undecided}) async {
    final u = user;
    if (!available || u == null) return const SyncResult(error: 'not signed in');
    if (_running) {
      _again = true;
      return const SyncResult();
    }
    _running = true;
    _retryTimer?.cancel();
    _phase = CloudSyncPhase.syncing;
    _problem = null;
    _lastAttempt = _clock();
    _notify();
    late SyncResult result;
    try {
      do {
        _again = false;
        result = await _engine!.run(userId: u.id, decision: decision, preferCloudSingletons: preferCloudProfile?.call() ?? false);
        if (result.needsAccountDecision) break;
        if (!result.ok) break;
      } while (_again);
    } finally {
      _running = false;
    }
    _needsDecision = result.needsAccountDecision;
    if (result.ok) {
      _lastSyncAt = _clock();
      _problem = null;
      _phase = CloudSyncPhase.idle;
    } else if (result.needsAccountDecision) {
      _phase = CloudSyncPhase.idle;
    } else {
      _problem = _classify(result.error);
      _phase = CloudSyncPhase.error;
      _scheduleRetry();
    }
    _pending = await _local!.pendingCount();
    _notify();
    return result;
  }

  CloudSyncProblem _classify(Object? e) {
    if (e is SocketException || e is TimeoutException || e is HttpException) return CloudSyncProblem.offline;
    final text = '$e'.toLowerCase();
    if (text.contains('socket') || text.contains('failed host lookup') || text.contains('connection') || text.contains('network')) {
      return CloudSyncProblem.offline;
    }
    if (text.contains('jwt') || text.contains('401') || text.contains('not signed in') || text.contains('pgrst30')) {
      return CloudSyncProblem.signedOut;
    }
    return CloudSyncProblem.server;
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_disposed || user == null) return;
    _retryTimer = Timer(retryAfter, () {
      if (!_disposed && user != null) unawaited(syncNow());
    });
  }

  /// The user chose what to do after [needsAccountDecision].
  Future<SyncResult> resolveAccountDecision(AccountSwitch decision) => syncNow(decision: decision);

  // ───────────────────────── triggers ─────────────────────────

  /// Call when local data changed. Debounced; only pushes when something is pending.
  void onLocalChange() {
    if (!available || user == null || _running) return; // changes caused by a sync reload are ignored
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () async {
      if (_disposed || user == null) return;
      _pending = await _local!.pendingCount();
      _notify();
      if (_pending > 0) unawaited(syncNow());
    });
  }

  /// Call when the app returns to the foreground (throttled).
  void onResume() {
    if (!available || user == null || _running) return;
    final last = _lastAttempt;
    if (last != null && _clock().difference(last) < resumeThrottle) return;
    unawaited(syncNow());
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
