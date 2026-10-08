import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/data_store.dart';
import '../data/device/device_services.dart';
import '../data/health/health_connect_repository.dart';
import '../data/health/health_gateway.dart';
import '../data/health/health_sync_service.dart';
import '../data/health/health_sync_store.dart';
import '../data/import/import_file_source.dart';
import '../data/sync/cloud_sync_controller.dart';
import '../data/memory/memory_repositories.dart';
import '../data/seed/seed_data.dart';
import '../domain/domain.dart';

/// Root dependency container + session state. Screens read repositories through
/// [AppScope]; they never construct repositories themselves.
///
/// Production uses `IsarStore` (persistent); tests default to a volatile
/// [MemoryStore]. There is no remote account: "sign in" only restores the single
/// local profile on this device, and no password is ever stored.
class AppController extends ChangeNotifier {
  AppController({DataStore? store, HealthRepository? health, HealthSyncService? healthSync, CloudSyncController? cloud, ImportFileSource? importSource, DeviceFeedback? feedback, KeepAwake? keepAwake})
      : _store = store ?? MemoryStore(SeedData.fresh()),
        health = health ?? NoopHealthRepository(),
        healthSync = healthSync ?? HealthSyncService(HealthGateway.inert, MemoryHealthSyncStore()),
        cloud = cloud ?? CloudSyncController.unavailable(),
        importSource = importSource ?? const FilePickerImportSource(),
        feedback = feedback ?? const HapticDeviceFeedback(),
        keepAwake = keepAwake ?? PluginKeepAwake() {
    // Any local data change may need uploading (debounced inside the controller; a no-op
    // when cloud sync is unavailable or the user is signed out).
    _localChanges = Listenable.merge([_store.exercises, _store.workouts, _store.sessions, _store.cardio, _store.profile])
      ..addListener(this.cloud.onLocalChange);
    // Mirror finished / edited / deleted sessions to the health store (only when the user opted in).
    this.healthSync.attach(cardio: _store.cardio, sessions: _store.sessions);
    unawaited(this.healthSync.retryPending());
  }

  late final Listenable _localChanges;

  /// Opt-in workout write / enrich / import for Health Connect and Apple Health. All features
  /// default OFF; inert in tests and on platforms without a health store.
  final HealthSyncService healthSync;

  final DataStore _store;

  /// Optional wearable data (Health Connect). Read-only, opt-in, on-device.
  final HealthRepository health;

  /// Optional cloud backup/sync. Inert unless the build is configured and the user signs in.
  final CloudSyncController cloud;

  /// Where "Import from Gym Tracker" gets its file (system picker; fakeable in tests).
  final ImportFileSource importSource;

  /// Haptics for the workout logger (fakeable in tests).
  final DeviceFeedback feedback;

  /// Keeps the screen on while the logger is open (fakeable in tests).
  final KeepAwake keepAwake;

  /// Persisted flag: the user is past the landing screen.
  bool get signedIn => _store.signedIn;

  ExerciseRepository get exercises => _store.exercises;
  WorkoutRepository get workouts => _store.workouts;
  SessionRepository get sessions => _store.sessions;
  CardioRepository get cardio => _store.cardio;
  ProfileRepository get profile => _store.profile;

  /// Local-only in-progress workout draft (never synced).
  WorkoutDraftStore get workoutDraft => _store.workoutDraft;

  // ── maximum workout length (device-local preference, never synced) ──
  int? _fallbackRaw;
  String? _fallbackNotice;
  AutoEndResult? _notice;
  bool _noticeLoaded = false;
  Future<AutoEndResult?>? _autoEnding;

  /// Maximum workout length in minutes; null = off. Default 180 when never chosen.
  /// Allowed values: [WorkoutLimit.options]. Kept across "Delete all local data".
  int? get maxWorkoutMinutes {
    final raw = _store is LocalSettingsStore ? (_store as LocalSettingsStore).maxWorkoutMinutesRaw : _fallbackRaw;
    if (raw == null) return WorkoutLimit.defaultMinutes;
    return raw <= 0 ? null : raw;
  }

  Duration? get maxWorkoutDuration {
    final m = maxWorkoutMinutes;
    return m == null ? null : Duration(minutes: m);
  }

  /// [minutes] null = off.
  Future<void> setMaxWorkoutMinutes(int? minutes) async {
    final raw = (minutes == null || minutes <= 0) ? 0 : minutes;
    if (_store is LocalSettingsStore) {
      await (_store as LocalSettingsStore).setMaxWorkoutMinutesRaw(raw);
    } else {
      _fallbackRaw = raw;
    }
    notifyListeners();
  }

  /// The "workout ended automatically" notice waiting to be shown (survives a restart).
  AutoEndResult? get pendingAutoEndNotice {
    if (!_noticeLoaded) {
      _noticeLoaded = true;
      final json = _store is LocalSettingsStore ? (_store as LocalSettingsStore).autoEndNoticeJson : _fallbackNotice;
      if (json != null) {
        try {
          _notice = AutoEndResult.tryParse((jsonDecode(json) as Map).cast<String, Object?>());
        } catch (_) {}
      }
    }
    return _notice;
  }

  Future<void> _setNotice(AutoEndResult? r) async {
    _noticeLoaded = true;
    _notice = r;
    final json = r == null ? null : jsonEncode(r.toJson());
    if (_store is LocalSettingsStore) {
      await (_store as LocalSettingsStore).setAutoEndNoticeJson(json);
    } else {
      _fallbackNotice = json;
    }
  }

  Future<void> clearAutoEndNotice() async {
    if (pendingAutoEndNotice == null) return;
    await _setNotice(null);
    notifyListeners();
  }

  /// Ends the persisted in-progress workout if it exceeded the maximum length: saves the done
  /// sets as one session (duration capped at the limit), advances the rotation like a normal
  /// finish, clears the draft and records [pendingAutoEndNotice]. Returns null when nothing
  /// expired. Single-flight and idempotent: safe to call repeatedly / concurrently.
  Future<AutoEndResult?> autoEndExpiredWorkout({DateTime? now}) {
    return _autoEnding ??= _autoEnd(now ?? DateTime.now()).whenComplete(() => _autoEnding = null);
  }

  Future<AutoEndResult?> _autoEnd(DateTime now) async {
    final d = workoutDraft.current;
    final max = maxWorkoutMinutes;
    if (d == null || !WorkoutLimit.isExpired(d.startedAt, now, max)) return null;
    final result = await DraftCompletion.complete(d, now: now, maxMinutes: max, sessions: sessions, workouts: workouts);
    await workoutDraft.clear();
    await _setNotice(result);
    notifyListeners();
    return result;
  }

  /// Call when the app returns to the foreground (and at start-up, after the store loaded).
  Future<void> onAppResumed() async {
    try {
      await autoEndExpiredWorkout();
    } catch (_) {
      // Never crash the lifecycle; the draft stays and the next call retries.
    }
  }

  WorkoutCompletion get completion => WorkoutCompletion(sessions, workouts);

  /// A real (non-guest) local account exists on this device.
  bool get hasLocalAccount => !profile.profile.isGuest && profile.profile.email.isNotEmpty;

  /// Logged sessions/cardio that are NOT demo rows (`seed_*`).
  bool get hasRealTrainingData => sessions.sessions.any((s) => !isDemoId(s.id)) || cardio.sessions.any((c) => !isDemoId(c.id));

  /// Demo sessions/cardio are on this device (persistent marker: their `seed_` ids).
  bool get hasDemoData => sessions.sessions.any((s) => isDemoId(s.id)) || cardio.sessions.any((c) => isDemoId(c.id));

  /// A real account or real logged training data exists — never overwrite silently.
  /// Demo rows do not count, so real workouts logged on top of demo are distinguishable.
  bool get hasUserData => hasLocalAccount || hasRealTrainingData;

  /// Deletes ONLY the demo sessions/cardio (`seed_*`); real rows, routines, rotation, profile and
  /// the cloud account are untouched.
  Future<void> removeDemoData() async {
    for (final s in sessions.sessions.where((s) => isDemoId(s.id)).toList()) {
      await sessions.delete(s.id);
    }
    for (final c in cardio.sessions.where((c) => isDemoId(c.id)).toList()) {
      await cardio.delete(c.id);
    }
    notifyListeners();
  }

  /// "Continue as Guest (Offline Mode)": an empty local profile. Existing local
  /// data is kept, never replaced.
  Future<void> startGuest() async {
    if (!hasUserData) {
      await profile.update(const UserProfile(name: 'Guest Athlete', isGuest: true));
    }
    await _store.setSignedIn(true);
    notifyListeners();
  }

  /// Demo data replaces everything on the device, so it is refused while signed in to cloud
  /// sync (the next sync would push the demo data over the backup).
  bool get canLoadDemo => cloud.user == null;

  /// Replaces all data with ~8 weeks of sample history (explicit user action in Profile).
  /// Destructive — callers confirm. Returns false (and changes nothing) when signed in to
  /// cloud, or when logged sessions already exist and [replaceExisting] is not set.
  Future<bool> loadDemoData({bool replaceExisting = false}) async {
    if (!canLoadDemo) return false;
    if (!replaceExisting && hasRealTrainingData) return false;
    final p = profile.profile;
    await _store.replaceAll(SeedData.demo(), p); // also clears any in-progress draft
    notifyListeners();
    return true;
  }

  /// Test/preview shortcut: signed-in guest with demo history.
  @visibleForTesting
  Future<void> startDemo() async {
    await _store.replaceAll(SeedData.demo(), const UserProfile(name: 'Guest Athlete', isGuest: true));
    await _store.setSignedIn(true);
    notifyListeners();
  }

  /// Creates the local account. A guest's existing data is kept and attached to
  /// the account. Returns an error message, or null on success.
  /// The password is validated by the form only — never stored or logged.
  Future<String?> register({required String name, required String email}) async {
    if (hasLocalAccount && profile.profile.email.toLowerCase() != email.toLowerCase()) {
      return 'This device already has a local account (${profile.profile.email}). '
          'Sign in with it, or delete local data in Profile first.';
    }
    await profile.update(profile.profile.copyWith(name: name, email: email, isGuest: false));
    await _store.setSignedIn(true);
    notifyListeners();
    return null;
  }

  /// Restores the local account on this device. There is no server, so this
  /// cannot verify a password; it only matches the local profile's email.
  /// Returns an error message, or null on success.
  Future<String?> signInLocal({required String email}) async {
    if (!hasLocalAccount) {
      return 'No local account on this device yet. Create an account or continue as guest.';
    }
    if (profile.profile.email.toLowerCase() != email.toLowerCase()) {
      return 'No local account for this email on this device.';
    }
    await _store.setSignedIn(true);
    notifyListeners();
    return null;
  }

  /// "Delete All Local Data": removes all history and custom content; keeps the
  /// profile (name/email/settings). Restores the default catalogue + rotation.
  /// The cloud backup/account is never touched; the local sync link (account id + cursors) is always
  /// reset by the store's `replaceAll`, signed in or not, so a later sync starts from scratch.
  Future<void> wipeAllData() async {
    // Otherwise the next sync would pull everything back (or push the wipe's defaults).
    // The cloud backup itself is kept; delete it explicitly from Cloud sync settings.
    if (cloud.user != null) await cloud.forgetThisDevice();
    await _store.replaceAll(SeedData.fresh(), profile.profile);
    notifyListeners();
  }

  /// Enter the app after a cloud sign-in on a new device (profile comes from the cloud,
  /// so nothing is rewritten here).
  Future<void> resumeSession() async {
    await _store.setSignedIn(true);
    notifyListeners();
  }

  /// Back to the landing screen. Local data is kept.
  Future<void> signOut() async {
    await _store.setSignedIn(false);
    notifyListeners();
  }

  @override
  void dispose() {
    _localChanges.removeListener(cloud.onLocalChange);
    cloud.dispose();
    healthSync.dispose();
    super.dispose();
  }

  Future<void> close() => _store.close();
}
