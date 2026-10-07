import 'package:flutter/foundation.dart';

import '../data/data_store.dart';
import '../data/health/health_connect_repository.dart';
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
  AppController({DataStore? store, HealthRepository? health})
      : _store = store ?? MemoryStore(SeedData.fresh()),
        health = health ?? NoopHealthRepository();

  final DataStore _store;

  /// Optional wearable data (Health Connect). Read-only, opt-in, on-device.
  final HealthRepository health;

  /// Persisted flag: the user is past the landing screen.
  bool get signedIn => _store.signedIn;

  ExerciseRepository get exercises => _store.exercises;
  WorkoutRepository get workouts => _store.workouts;
  SessionRepository get sessions => _store.sessions;
  CardioRepository get cardio => _store.cardio;
  ProfileRepository get profile => _store.profile;

  WorkoutCompletion get completion => WorkoutCompletion(sessions, workouts);

  /// A real (non-guest) local account exists on this device.
  bool get hasLocalAccount => !profile.profile.isGuest && profile.profile.email.isNotEmpty;

  /// Any logged training data or an account exists — never overwrite silently.
  bool get hasUserData => hasLocalAccount || sessions.sessions.isNotEmpty || cardio.sessions.isNotEmpty;

  /// "Continue as Guest (Offline Mode)": an empty local profile. Existing local
  /// data is kept, never replaced.
  Future<void> startGuest() async {
    if (!hasUserData) {
      await profile.update(const UserProfile(name: 'Guest Athlete', isGuest: true));
    }
    await _store.setSignedIn(true);
    notifyListeners();
  }

  /// Replaces all data with ~8 weeks of mock history (explicit user action in
  /// Profile; also used by tests and previews). Destructive — callers confirm.
  Future<void> loadDemoData() async {
    final p = profile.profile;
    await _store.replaceAll(SeedData.demo(), p);
    notifyListeners();
  }

  /// Test/preview shortcut: signed-in guest with demo history.
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
  Future<void> wipeAllData() async {
    await _store.replaceAll(SeedData.fresh(), profile.profile);
    notifyListeners();
  }

  /// Back to the landing screen. Local data is kept.
  Future<void> signOut() async {
    await _store.setSignedIn(false);
    notifyListeners();
  }

  Future<void> close() => _store.close();
}
