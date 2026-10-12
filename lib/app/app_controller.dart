import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/data_store.dart';
import '../data/device/device_services.dart';
import '../data/health/health_connect_repository.dart';
import '../data/health/health_gateway.dart';
import '../data/health/health_sync_service.dart';
import '../data/health/health_sync_store.dart';
import '../data/import/import_file_source.dart';
import '../data/remote/auth_service.dart';
import '../data/remote/remote_exception.dart';
import '../data/memory/memory_repositories.dart';
import '../data/remote/online_store.dart';
import '../data/seed/seed_data.dart';
import '../domain/domain.dart';

/// Where the app is in the account lifecycle. The root widget switches on this.
enum SessionPhase {
  /// Looking for a saved session at start-up.
  restoring,

  /// Nobody is signed in (or the session ended): the landing / login screens.
  signedOut,

  /// Signed in, loading the user's data from the server.
  loading,

  /// Data loaded: the app is usable.
  ready,

  /// Signed in but the data could not be loaded (offline / server): retry or log out.
  loadFailed,
}

enum AccountOutcome {
  /// Signed in and the user's data is loaded.
  signedIn,

  /// Rejected: [AccountResult.message] (already friendly) or [AccountResult.status] says why.
  failed,
}

class AccountResult {
  const AccountResult(this.outcome, {this.message, this.status});
  final AccountOutcome outcome;

  /// Ready-to-show text (validation). Null when [status] explains it.
  final String? message;
  final CloudAuthStatus? status;
  bool get entered => outcome == AccountOutcome.signedIn;
}

/// Root dependency container + account lifecycle. Screens read repositories through [AppScope];
/// they never construct repositories themselves.
///
/// Online-first: Supabase is the only source of truth for user data. Production wires `OnlineStore`
/// (read model of the signed-in user, writes confirmed by the server first); tests default to a
/// volatile [MemoryStore] and an always-signed-in session.
///
/// Lifecycle: [init] restores the saved Supabase session -> [SessionPhase.loading] -> the store loads
/// the user's data -> [SessionPhase.ready]. Logout, an expired session or switching accounts clear all
/// user data first. Every boot carries a generation number so a slow response for an earlier user can
/// never land in a later user's session.
class AppController extends ChangeNotifier {
  AppController({
    DataStore? store,
    HealthRepository? health,
    HealthSyncService? healthSync,
    CloudAuth? auth,
    ImportFileSource? importSource,
    DeviceFeedback? feedback,
    KeepAwake? keepAwake,
  }) : _store = store ?? MemoryStore(SeedData.fresh()),
       health = health ?? NoopHealthRepository(),
       healthSync =
           healthSync ??
           HealthSyncService(HealthGateway.inert, MemoryHealthSyncStore()),
       auth = auth ?? NoCloudAuth(),
       _offlineSession = auth == null,
       importSource = importSource ?? const FilePickerImportSource(),
       feedback = feedback ?? const HapticDeviceFeedback(),
       keepAwake = keepAwake ?? PluginKeepAwake() {
    _phase = _offlineSession ? SessionPhase.ready : SessionPhase.restoring;
    this.healthSync.attach(cardio: _store.cardio, sessions: _store.sessions);
    unawaited(this.healthSync.retryPending());
    if (!_offlineSession) this.auth.addListener(_onAuthChanged);
    final s = _store;
    if (s is OnlineStore) {
      s.onAuthLost = () => unawaited(_endSession(expired: true));
    }
  }

  /// Tests / previews without an auth service: no sign-in, always "ready".
  final bool _offlineSession;

  /// Opt-in workout write / enrich / import for Health Connect and Apple Health. All features
  /// default OFF; inert in tests and on platforms without a health store.
  final HealthSyncService healthSync;

  final DataStore _store;

  /// Optional wearable data (Health Connect). Read-only, opt-in, on-device.
  final HealthRepository health;

  /// Supabase Auth (username + password).
  final CloudAuth auth;

  /// Where "Import from Gym Tracker" gets its file (system picker; fakeable in tests).
  final ImportFileSource importSource;

  /// Haptics for the workout logger (fakeable in tests).
  final DeviceFeedback feedback;

  /// Keeps the screen on while the logger is open (fakeable in tests).
  final KeepAwake keepAwake;

  ExerciseRepository get exercises => _store.exercises;
  WorkoutRepository get workouts => _store.workouts;
  SessionRepository get sessions => _store.sessions;
  CardioRepository get cardio => _store.cardio;
  ProfileRepository get profile => _store.profile;

  /// Device-local in-progress workout draft (temporary UI state, never uploaded).
  WorkoutDraftStore get workoutDraft => _store.workoutDraft;

  // ───────────────────────── session lifecycle ─────────────────────────
  late SessionPhase _phase;
  SessionPhase get phase => _phase;

  /// Why the data could not be loaded (while [phase] is [SessionPhase.loadFailed]).
  RemoteException? loadError;

  /// One-shot message for the login screen ("Your session expired…").
  String? sessionNotice;

  /// The last background refresh failed (data on screen may be out of date).
  bool refreshFailed = false;

  int _generation = 0;
  Future<bool>? _booting;
  String? _activeUserId;
  DateTime? _lastRefresh;
  Future<void>? _refreshing;

  /// True once the user is signed in and their data is loaded.
  bool get isReady => _phase == SessionPhase.ready;

  /// The signed-in username (empty when signed out).
  String get username => auth.user?.username ?? profile.profile.email;

  void _set(SessionPhase p) {
    _phase = p;
    notifyListeners();
  }

  /// Start-up: restore the saved session, if any. Safe to call once after construction.
  Future<void> init() async {
    if (_offlineSession) return;
    final u = auth.user;
    if (u == null) {
      _set(SessionPhase.signedOut);
      return;
    }
    await _boot(u);
  }

  void _onAuthChanged() {
    if (_offlineSession) return;
    final u = auth.user;
    if (u == null) {
      if (_phase != SessionPhase.signedOut &&
          _phase != SessionPhase.restoring) {
        unawaited(_endSession(expired: true));
      }
    } else if (u.id != _activeUserId) {
      unawaited(_boot(u));
    }
  }

  /// Loads [user]'s data. Single-flight per user; returns true when the app is ready.
  Future<bool> _boot(CloudUser user) {
    if (_booting != null && _activeUserId == user.id) return _booting!;
    return _booting = _doBoot(user).whenComplete(() => _booting = null);
  }

  Future<bool> _doBoot(CloudUser user) async {
    final gen = ++_generation;
    if (_activeUserId != null && _activeUserId != user.id) {
      await _clearUserData();
    }
    _activeUserId = user.id;
    loadError = null;
    sessionNotice = null;
    _set(SessionPhase.loading);
    healthSync.detach();
    try {
      await _store.load(userId: user.id, username: user.username);
      if (gen != _generation) return false; // a newer boot / sign-out took over
      _lastRefresh = DateTime.now();
      _set(SessionPhase.ready);
      return true;
    } on RemoteException catch (e) {
      if (gen != _generation) return false;
      if (e.kind == RemoteFailure.authExpired) {
        await _endSession(expired: true);
      } else {
        loadError = e;
        _set(SessionPhase.loadFailed);
      }
      return false;
    } catch (e) {
      if (gen != _generation) return false;
      loadError = RemoteException.from(e);
      _set(SessionPhase.loadFailed);
      return false;
    } finally {
      if (gen == _generation) {
        healthSync.attach(cardio: _store.cardio, sessions: _store.sessions);
      }
    }
  }

  /// "Try again" on the load-failed screen.
  Future<void> retryLoad() async {
    final u = auth.user;
    if (u == null) {
      await _endSession(expired: true);
      return;
    }
    await _boot(u);
  }

  /// Re-reads the user's data (app resumed / pull to refresh). Never replaces the screen: a failure
  /// only sets [refreshFailed]. Throttled unless [force]. Skipped while a save is in flight.
  Future<void> refresh({bool force = false}) {
    if (_offlineSession || _phase != SessionPhase.ready) return Future.value();
    final last = _lastRefresh;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 30)) {
      return Future.value();
    }
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<void> _doRefresh() async {
    final u = auth.user;
    if (u == null) return;
    final gen = _generation;
    healthSync.detach();
    try {
      await _store.load(userId: u.id, username: u.username);
      if (gen != _generation) return;
      _lastRefresh = DateTime.now();
      if (refreshFailed) {
        refreshFailed = false;
        notifyListeners();
      }
    } on RemoteException catch (e) {
      if (gen != _generation) return;
      if (e.kind == RemoteFailure.authExpired) {
        await _endSession(expired: true);
      } else if (!refreshFailed) {
        refreshFailed = true;
        notifyListeners();
      }
    } catch (_) {
      if (gen == _generation && !refreshFailed) {
        refreshFailed = true;
        notifyListeners();
      }
    } finally {
      if (gen == _generation) {
        healthSync.attach(cardio: _store.cardio, sessions: _store.sessions);
      }
    }
  }

  Future<void> _clearUserData() async {
    healthSync.detach();
    await _store.clear();
    healthSync.attach(cardio: _store.cardio, sessions: _store.sessions);
  }

  /// Ends the session: invalidates in-flight work, wipes every piece of the user's data from memory
  /// and the device-local draft, drops the Supabase session and shows the signed-out screen.
  Future<void> _endSession({required bool expired}) async {
    _generation++;
    _activeUserId = null;
    _booting = null;
    loadError = null;
    refreshFailed = false;
    sessionNotice = expired
        ? 'Your session expired. Please log in again.'
        : null;
    _set(SessionPhase.signedOut);
    await _clearUserData();
    try {
      await auth.signOut();
    } catch (_) {}
  }

  /// A saved workout draft exists on this device (logging out discards it).
  bool get hasUnfinishedWorkout => workoutDraft.current != null;

  /// Logs out: nothing of this user stays in memory or on the device afterwards.
  Future<void> signOut() => _endSession(expired: false);

  /// Deletes the account and ALL its data on the server, then ends the session. Throws
  /// [RemoteException]-free: returns the auth result so the UI can show why it failed.
  Future<CloudAuthResult> deleteAccount() async {
    final r = await auth.deleteAccount();
    if (r.ok) await _endSession(expired: false);
    return r;
  }

  /// "Delete all my data": removes every workout, session, cardio entry and goal of the account on
  /// the server (the account and profile stay) and
  Future<void> deleteAllData() async {
    await _store.resetData();
    notifyListeners();
  }

  // ───────────────────────── accounts (username + password) ─────────────────────────
  // The username is the app-level identity; Supabase Auth gets a private identifier derived from it.

  /// Creates an account, signs in and loads (initialising, on the server, the default routines and
  /// the profile) before returning. Nothing is entered unless the server confirmed everything.
  /// The password is passed straight to the server and never stored or logged.
  Future<AccountResult> registerAccount(
    String rawUsername,
    String password,
  ) async {
    final username = Username.normalize(rawUsername);
    final bad = Username.validate(username);
    if (bad != null) return AccountResult(AccountOutcome.failed, message: bad);
    if (!PasswordPolicy.isStrong(password)) {
      return const AccountResult(
        AccountOutcome.failed,
        status: CloudAuthStatus.weakPassword,
      );
    }
    final r = await auth.signUp(username, password);
    if (!r.ok) return AccountResult(AccountOutcome.failed, status: r.status);
    return _afterAuth();
  }

  /// Logs in and loads the user's data.
  Future<AccountResult> signInAccount(
    String rawUsername,
    String password,
  ) async {
    final username = Username.normalize(rawUsername);
    final bad = Username.validate(username);
    if (bad != null) return AccountResult(AccountOutcome.failed, message: bad);
    final r = await auth.signIn(username, password);
    if (!r.ok) return AccountResult(AccountOutcome.failed, status: r.status);
    return _afterAuth();
  }

  Future<AccountResult> _afterAuth() async {
    final u = auth.user;
    if (u == null) {
      return const AccountResult(
        AccountOutcome.failed,
        status: CloudAuthStatus.unknown,
      );
    }
    final ok = await _boot(u);
    if (ok) return const AccountResult(AccountOutcome.signedIn);
    final status = loadError?.kind == RemoteFailure.offline
        ? CloudAuthStatus.network
        : CloudAuthStatus.unknown;
    // Signed in but unusable: end the session so the form can simply be submitted again.
    if (_phase != SessionPhase.signedOut) await _endSession(expired: false);
    return AccountResult(AccountOutcome.failed, status: status);
  }

  WorkoutCompletion get completion =>
      WorkoutCompletion(sessions, workouts, finisher: _finisher);

  AtomicWorkoutFinisher? get _finisher =>
      _store is AtomicWorkoutFinisher ? _store as AtomicWorkoutFinisher : null;

  /// Test/preview shortcut: signed-in athlete with demo history (memory store only).
  @visibleForTesting
  Future<void> startDemo() async {
    final s = _store;
    if (s is MemoryStore) {
      await s.replaceAll(
        SeedData.demo(),
        const UserProfile(name: 'Guest Athlete'),
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    auth.removeListener(_onAuthChanged);
    final a = auth;
    if (a is ChangeNotifier) (a as ChangeNotifier).dispose();
    healthSync.dispose();
    super.dispose();
  }

  Future<void> close() => _store.close();
}
