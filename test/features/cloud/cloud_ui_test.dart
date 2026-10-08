import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/data/sync/cloud_auth.dart';
import 'package:stationx/data/sync/cloud_sync_controller.dart';
import 'package:stationx/data/sync/sync_engine.dart';
import 'package:stationx/data/sync/sync_local_store.dart';
import 'package:stationx/features/cloud/cloud_auth_page.dart';
import 'package:stationx/features/landing/landing_page.dart';
import 'package:stationx/features/profile/profile_page.dart';
import '../../helpers/pump.dart';
import '../../helpers/sync_fakes.dart';

/// Controller wired to fakes: no Isar, no network.
({AppController app, FakeCloudAuth auth, NullLocalStore local, FakeServer server}) setup({bool configured = true, NullLocalStore? local}) {
  final auth = FakeCloudAuth(configured: configured);
  final store = local ?? NullLocalStore();
  final server = FakeServer();
  final ctl = CloudSyncController(
    auth: auth,
    engine: SyncEngine(store, server),
    local: store,
    debounce: const Duration(milliseconds: 10),
    retryAfter: const Duration(hours: 1),
  );
  final app = AppController(cloud: configured ? ctl : null);
  return (app: app, auth: auth, local: store, server: server);
}

Future<void> openProfileCard(WidgetTester t) async {
  await t.scrollUntilVisible(find.text('Cloud backup & sync'), 300, scrollable: find.byType(Scrollable).first);
  await t.drag(find.byType(Scrollable).first, const Offset(0, -150));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('availability', () {
    testWidgets('no cloud configured: nothing about cloud appears in Profile or on the welcome screen', (t) async {
      await pumpPage(t, const ProfilePage());
      await t.scrollUntilVisible(find.text('Privacy'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Cloud backup & sync', skipOffstage: false), findsNothing);
      await pumpPage(t, const LandingPage(), demo: false);
      expect(find.text('Restore from cloud backup', skipOffstage: false), findsNothing);
    });

    testWidgets('configured: signed-out card explains it is optional and offline until sign-in', (t) async {
      final s = setup();
      await s.app.startDemo();
      await pumpPage(t, const ProfilePage(), controller: s.app);
      await openProfileCard(t);
      expect(find.text('Off — your data stays on this device'), findsOneWidget);
      expect(find.textContaining('Nothing is uploaded until you sign in'), findsOneWidget);
      expect(find.text('SIGN IN OR CREATE ACCOUNT'), findsOneWidget);
    });
  });

  group('sign in / sign up', () {
    Future<(AppController, FakeCloudAuth)> openAuth(WidgetTester t, {bool restore = false, NullLocalStore? local}) async {
      final s = setup(local: local);
      await s.app.startDemo();
      await pumpPage(t, CloudAuthPage(restoreOnNewDevice: restore), controller: s.app);
      return (s.app, s.auth);
    }

    testWidgets('validates before calling the server', (t) async {
      final (_, auth) = await openAuth(t);
      await t.tap(find.text('SIGN IN').last);
      await t.pump();
      expect(find.text('INVALID EMAIL'), findsOneWidget);
      expect(find.text('REQUIRED'), findsOneWidget);
      expect(auth.signInCalls, 0);
    });

    testWidgets('wrong password shows a friendly message and stays on the page', (t) async {
      final (_, auth) = await openAuth(t);
      auth.nextStatus = CloudAuthStatus.invalidCredentials;
      await t.enterText(find.byType(TextField).at(0), 'sam@mail.com');
      await t.enterText(find.byType(TextField).at(1), 'wrong');
      await t.tap(find.text('SIGN IN').last);
      await t.pumpAndSettle();
      expect(find.text('Wrong email or password.'), findsOneWidget);
      expect(find.byType(CloudAuthPage), findsOneWidget);
      // The password field is cleared after every attempt.
      expect(t.widget<TextField>(find.byType(TextField).at(1)).controller!.text, isEmpty);
    });

    testWidgets('offline shows a network message', (t) async {
      final (_, auth) = await openAuth(t);
      auth.nextStatus = CloudAuthStatus.network;
      await t.enterText(find.byType(TextField).at(0), 'sam@mail.com');
      await t.enterText(find.byType(TextField).at(1), 'whatever1');
      await t.tap(find.text('SIGN IN').last);
      await t.pumpAndSettle();
      expect(find.textContaining("Can't reach the server"), findsOneWidget);
    });

    testWidgets('success signs in, syncs and closes the page', (t) async {
      final s = setup();
      await s.app.startDemo();
      await pumpPage(t, Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute<bool>(builder: (_) => const CloudAuthPage())), child: const Text('open')))), controller: s.app);
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).at(0), 'sam@mail.com');
      await t.enterText(find.byType(TextField).at(1), 'secret123');
      await t.tap(find.text('SIGN IN').last);
      await t.pumpAndSettle();
      expect(s.app.cloud.user!.email, 'sam@mail.com');
      expect(find.byType(CloudAuthPage), findsNothing);
      expect(find.text('Signed in as sam@mail.com'), findsOneWidget);
      await t.pump(const Duration(seconds: 3)); // let the snackbar finish
    });

    testWidgets('create account: weak password blocked; strong one shows e-mail confirmation step', (t) async {
      final (_, auth) = await openAuth(t);
      await t.tap(find.text('CREATE ACCOUNT').first);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).at(0), 'Sam');
      await t.enterText(find.byType(TextField).at(1), 'sam@mail.com');
      await t.enterText(find.byType(TextField).at(2), 'weak');
      await t.tap(find.widgetWithText(SxButton, 'CREATE ACCOUNT'));
      await t.pump();
      expect(find.text('TOO WEAK'), findsOneWidget);
      auth.nextStatus = CloudAuthStatus.needsEmailConfirmation;
      await t.enterText(find.byType(TextField).at(2), 'Strong123');
      await t.tap(find.widgetWithText(SxButton, 'CREATE ACCOUNT'));
      await t.pumpAndSettle();
      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.textContaining('sam@mail.com'), findsOneWidget);
      await t.tap(find.text('I CONFIRMED — SIGN IN'));
      await t.pumpAndSettle();
      expect(find.text('Cloud backup'.toUpperCase()), findsOneWidget);
      expect(find.widgetWithText(SxButton, 'SIGN IN'), findsOneWidget); // back on the sign-in tab
    });

    testWidgets('existing e-mail is reported without leaking anything else', (t) async {
      final (_, auth) = await openAuth(t);
      await t.tap(find.text('CREATE ACCOUNT').first);
      await t.pumpAndSettle();
      auth.nextStatus = CloudAuthStatus.userExists;
      await t.enterText(find.byType(TextField).at(1), 'sam@mail.com');
      await t.enterText(find.byType(TextField).at(2), 'Strong123');
      await t.tap(find.widgetWithText(SxButton, 'CREATE ACCOUNT'));
      await t.pumpAndSettle();
      expect(find.textContaining('already exists'), findsOneWidget);
    });

    testWidgets('different account on a device with data: asks, "cancel" signs out', (t) async {
      final local = NullLocalStore(state: const SyncState(userId: 'old-user'), userData: true);
      final s = setup(local: local);
      await s.app.startDemo();
      s.auth.nextUserId = 'new-user';
      await pumpPage(t, const CloudAuthPage(), controller: s.app);
      await t.enterText(find.byType(TextField).at(0), 'b@mail.com');
      await t.enterText(find.byType(TextField).at(1), 'secret123');
      await t.tap(find.text('SIGN IN').last);
      await t.pumpAndSettle();
      expect(find.text('This device has other data'), findsOneWidget);
      await t.tap(find.text('CANCEL AND SIGN OUT'));
      await t.pumpAndSettle();
      expect(s.app.cloud.user, isNull);
      expect(find.textContaining('Cancelled'), findsOneWidget);
    });

    testWidgets('different account: "replace" needs a second confirmation, then resets local data', (t) async {
      final local = NullLocalStore(state: const SyncState(userId: 'old-user'), userData: true);
      final s = setup(local: local);
      await s.app.startDemo();
      s.auth.nextUserId = 'new-user';
      await pumpPage(t, const CloudAuthPage(), controller: s.app);
      await t.enterText(find.byType(TextField).at(0), 'b@mail.com');
      await t.enterText(find.byType(TextField).at(1), 'secret123');
      await t.tap(find.text('SIGN IN').last);
      await t.pumpAndSettle();
      await t.tap(find.text("REPLACE WITH THIS ACCOUNT'S DATA"));
      await t.pumpAndSettle();
      expect(find.text('REPLACE LOCAL DATA?'), findsOneWidget);
      expect(local.resets, 0); // nothing destroyed before the second confirmation
      await t.tap(find.text('REPLACE'));
      await t.pumpAndSettle();
      expect(local.resets, 1);
    });

    testWidgets('restore on a new device enters the app without rewriting the profile', (t) async {
      final s = setup();
      await pumpPage(t, const LandingPage(), controller: s.app);
      expect(find.text('Restore from cloud backup', skipOffstage: false), findsOneWidget);
      await t.scrollUntilVisible(find.text('Restore from cloud backup'), 200, scrollable: find.byType(Scrollable).first);
      await t.drag(find.byType(Scrollable).first, const Offset(0, -120));
      await t.pumpAndSettle();
      await t.tap(find.text('Restore from cloud backup'));
      await t.pumpAndSettle();
      expect(find.text('RESTORE FROM CLOUD'), findsOneWidget);
      await t.enterText(find.byType(TextField).at(0), 'sam@mail.com');
      await t.enterText(find.byType(TextField).at(1), 'secret123');
      await t.tap(find.text('SIGN IN').last);
      await t.pumpAndSettle();
      expect(s.app.signedIn, isTrue);
      expect(s.app.profile.profile.name, isNot('Guest Athlete')); // untouched; the cloud supplies it
    });
  });

  group('signed-in card', () {
    Future<(AppController, FakeCloudAuth, NullLocalStore)> signedIn(WidgetTester t, {int pending = 0}) async {
      final local = NullLocalStore(pending: pending);
      final s = setup(local: local);
      await s.app.startDemo();
      await s.auth.signIn('sam@mail.com', 'x');
      await pumpPage(t, const ProfilePage(), controller: s.app);
      await s.app.cloud.syncNow();
      await t.pump();
      await openProfileCard(t);
      return (s.app, s.auth, local);
    }

    testWidgets('shows account, last sync and sync/sign-out/delete actions', (t) async {
      await signedIn(t);
      expect(find.text('sam@mail.com'), findsOneWidget);
      expect(find.text('Synced just now'), findsOneWidget);
      expect(find.text('SYNC NOW'), findsOneWidget);
      expect(find.text('SIGN OUT'), findsWidgets);
      expect(find.text('Delete cloud account & data'), findsOneWidget);
    });

    testWidgets('pending changes are shown', (t) async {
      await signedIn(t, pending: 3);
      expect(find.textContaining('3 changes waiting to upload'), findsOneWidget);
    });

    testWidgets('sign out keeps local data', (t) async {
      final (app, _, _) = await signedIn(t);
      final sessions = app.sessions.sessions.length;
      await t.tap(find.widgetWithText(SxButton, 'SIGN OUT').first);
      await t.pumpAndSettle();
      expect(app.cloud.user, isNull);
      expect(app.sessions.sessions.length, sessions);
      expect(find.text('Off — your data stays on this device'), findsOneWidget);
    });

    testWidgets('delete cloud account needs confirmation, keeps local data', (t) async {
      final (app, auth, _) = await signedIn(t);
      await t.tap(find.text('Delete cloud account & data'));
      await t.pumpAndSettle();
      expect(find.textContaining('Workouts and history on THIS device are kept'), findsOneWidget);
      await t.tap(find.text('CANCEL'));
      await t.pumpAndSettle();
      expect(auth.deleteCalls, 0);
      await t.tap(find.text('Delete cloud account & data'));
      await t.pumpAndSettle();
      await t.tap(find.text('DELETE ACCOUNT'));
      await t.pumpAndSettle();
      expect(auth.deleteCalls, 1);
      expect(app.cloud.user, isNull);
      expect(app.sessions.sessions, isNotEmpty);
    });

    testWidgets('sync problems are explained without technical text', (t) async {
      final (app, _, local) = await signedIn(t);
      // Simulate failure by making the store throw on the next run.
      local.state = const SyncState(userId: 'someone-else', cursors: {});
      local.userData = true;
      await app.cloud.syncNow();
      await t.pump();
      expect(app.cloud.needsAccountDecision, isTrue);
    });

    testWidgets('wiping the device while signed in also unlinks cloud sync and says so', (t) async {
      final (app, _, local) = await signedIn(t);
      await t.scrollUntilVisible(find.text('Delete all local data'), 300, scrollable: find.byType(Scrollable).first);
      await t.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete all local data'));
      await t.pumpAndSettle();
      expect(find.textContaining('turns cloud sync off here'), findsOneWidget);
      await t.tap(find.text('DELETE EVERYTHING'));
      await t.pumpAndSettle();
      expect(app.cloud.user, isNull);
      expect(local.state.userId, isNull);
      expect(app.sessions.sessions, isEmpty);
    });
  });

  testWidgets('cloud screens: 48dp targets and labels, no overflow at 2x text', (t) async {
    final h = t.ensureSemantics();
    final s = setup();
    await s.app.startDemo();
    await pumpPage(t, const CloudAuthPage(), controller: s.app, size: const Size(360, 640), textScale: 2.0);
    await t.tap(find.text('CREATE ACCOUNT').first);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect((await androidTapTargetGuideline.evaluate(t)).passed, isTrue);
    expect((await labeledTapTargetGuideline.evaluate(t)).passed, isTrue);
    h.dispose();
  });
}
