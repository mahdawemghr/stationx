import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/isar/isar_store.dart';
import 'package:stationx/domain/domain.dart';

/// Account/session rules of AppController running on the persistent store.
void main() {
  late Directory dir;
  setUpAll(() => Isar.initializeIsarCore(download: true));
  setUp(() => dir = Directory.systemTemp.createTempSync('stationx_ctl_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<AppController> boot() async => AppController(store: await IsarStore.open(directory: dir.path, name: 'ctl'));

  test('fresh install is signed out; guest start persists across restart with empty data', () async {
    var app = await boot();
    expect(app.signedIn, isFalse);
    await app.startGuest();
    expect(app.profile.profile.isGuest, isTrue);
    expect(app.sessions.sessions, isEmpty);
    await app.close();
    app = await boot();
    expect(app.signedIn, isTrue); // returning user skips the landing screen
    await app.close();
  });

  test('guest data is kept when registering and when starting guest again', () async {
    var app = await boot();
    await app.startGuest();
    await app.sessions.add(WorkoutSession(id: 's', workoutId: 'w1', name: 'A', workoutDate: DateTime(2026, 1, 2), exercises: const []));
    expect(await app.register(name: 'Sam', email: 'sam@mail.com'), isNull);
    expect(app.sessions.sessions.length, 1); // guest data attached to the account
    await app.signOut();
    await app.close();
    app = await boot();
    expect(app.signedIn, isFalse); // signed out persists
    expect(app.hasLocalAccount, isTrue);
    await app.startGuest(); // must not wipe the account or its data
    expect(app.profile.profile.email, 'sam@mail.com');
    expect(app.sessions.sessions.length, 1);
    await app.close();
  });

  test('sign-in only restores the matching local account; second account is refused', () async {
    final app = await boot();
    expect(await app.signInLocal(email: 'a@b.co'), contains('No local account'));
    await app.register(name: 'Sam', email: 'sam@mail.com');
    await app.signOut();
    expect(await app.signInLocal(email: 'other@mail.com'), contains('No local account for this email'));
    expect(app.signedIn, isFalse);
    expect(await app.register(name: 'Eve', email: 'eve@mail.com'), contains('already has a local account'));
    expect(await app.signInLocal(email: 'SAM@mail.com'), isNull); // case-insensitive
    expect(app.signedIn, isTrue);
    await app.close();
  });

  test('demo data and wipe: wipe keeps profile, restores catalogue + rotation, persists', () async {
    var app = await boot();
    await app.register(name: 'Sam', email: 'sam@mail.com');
    await app.loadDemoData();
    expect(app.sessions.sessions, isNotEmpty);
    expect(app.profile.profile.name, 'Sam'); // demo replaces data, not the profile
    await app.wipeAllData();
    await app.close();
    app = await boot();
    expect(app.sessions.sessions, isEmpty);
    expect(app.cardio.sessions, isEmpty);
    expect(app.exercises.all, isNotEmpty);
    expect(app.workouts.rotation.currentIndex, 0);
    expect(app.profile.profile.email, 'sam@mail.com');
    await app.close();
  });
}
