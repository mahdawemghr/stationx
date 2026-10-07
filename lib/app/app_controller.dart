import 'package:flutter/foundation.dart';

import '../data/memory/memory_repositories.dart';
import '../data/seed/seed_data.dart';
import '../domain/domain.dart';

/// Root dependency container + session state. Screens read repositories through
/// [AppScope]; they never construct repositories themselves.
///
/// MOCK data layer: [MemoryStore] resets on restart. When an Isar store exists,
/// build it here and keep the same repository interfaces.
class AppController extends ChangeNotifier {
  AppController() : _store = MemoryStore(SeedData.fresh());

  MemoryStore _store;
  bool _signedIn = false;

  bool get signedIn => _signedIn;

  ExerciseRepository get exercises => _store.exercises;
  WorkoutRepository get workouts => _store.workouts;
  SessionRepository get sessions => _store.sessions;
  CardioRepository get cardio => _store.cardio;
  ProfileRepository get profile => _store.profile;

  WorkoutCompletion get completion => WorkoutCompletion(sessions, workouts);

  /// "Continue as Guest": demo data so every screen has content.
  void startDemo() {
    _store = MemoryStore(SeedData.demo(), profile: const UserProfile(name: 'Guest Athlete', isGuest: true));
    _signedIn = true;
    notifyListeners();
  }

  /// Local profile created from the Register screen: empty history.
  /// Password is never stored; there is no remote account.
  void startFresh({required String name, required String email}) {
    _store = MemoryStore(SeedData.fresh(), profile: UserProfile(name: name, email: email, isGuest: false));
    _signedIn = true;
    notifyListeners();
  }

  /// Local sign-in: no backend, so this opens an empty local profile for [email].
  void signInLocal({required String email}) {
    final name = email.contains('@') ? email.split('@').first : 'Athlete';
    _store = MemoryStore(SeedData.fresh(), profile: UserProfile(name: name, email: email, isGuest: false));
    _signedIn = true;
    notifyListeners();
  }

  /// "Delete All Local Data": wipes history, keeps nothing.
  void wipeAllData() {
    final p = _store.profile.profile;
    _store = MemoryStore(SeedData.fresh(), profile: p);
    notifyListeners();
  }

  void signOut() {
    _signedIn = false;
    _store = MemoryStore(SeedData.fresh());
    notifyListeners();
  }
}
