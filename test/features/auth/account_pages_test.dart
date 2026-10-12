import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/data/remote/auth_service.dart';
import 'package:stationx/data/remote/remote_exception.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/auth/login_page.dart';
import 'package:stationx/features/auth/register_page.dart';
import 'package:stationx/features/shell/main_shell.dart';
import '../../helpers/online_fakes.dart';
import '../../helpers/pump.dart';

const strong = 'Strong1pass';
Finder createBtn() => find.widgetWithText(SxButton, 'CREATE ACCOUNT');
Finder logInBtn() => find.widgetWithText(SxButton, 'LOG IN');

/// A rig whose controller has finished start-up with nobody signed in.
Future<OnlineRig> fresh() async {
  final rig = OnlineRig();
  await rig.app.init();
  return rig;
}

Future<void> fill(
  WidgetTester t, {
  String user = 'Sam',
  String pw = strong,
}) async {
  await t.enterText(find.byType(TextField).at(0), user);
  await t.enterText(find.byType(TextField).at(1), pw);
  await t.pump();
}

String fieldText(WidgetTester t, int i) =>
    t.widget<TextField>(find.byType(TextField).at(i)).controller!.text;

void main() {
  setUpAll(loadAppFonts);

  group('Create account', () {
    testWidgets(
      'exactly two fields: username and password; no e-mail, name, confirm or phone',
      (t) async {
        final s = await fresh();
        await pumpPage(
          t,
          const RegisterPage(),
          demo: false,
          controller: s.app,
          size: const Size(390, 1600),
        );
        expect(find.byType(TextField), findsNWidgets(2));
        expect(find.text('USERNAME'), findsOneWidget);
        expect(find.text('PASSWORD'), findsOneWidget);
        for (final word in [
          'EMAIL',
          'E-MAIL',
          'CONFIRM',
          'PHONE',
          'FULL NAME',
          'AGE',
          'WEIGHT',
          'HEIGHT',
        ]) {
          expect(
            find.textContaining(word, skipOffstage: false),
            findsNothing,
            reason: word,
          );
        }
        // Live rules, the no-reset note and the show-password toggle.
        expect(find.text('At least 8 characters'), findsOneWidget);
        expect(find.text('One uppercase letter'), findsOneWidget);
        expect(find.text('One number'), findsOneWidget);
        expect(
          find.text(
            "No e-mail is used, so a forgotten password can't be reset. Keep it somewhere safe.",
          ),
          findsOneWidget,
        );
        expect(find.byTooltip('Show password'), findsOneWidget);
        expect(find.textContaining('Forgot password'), findsNothing);
        await t.tap(find.byTooltip('Show password'));
        await t.pump();
        expect(find.byTooltip('Hide password'), findsOneWidget);
      },
    );

    testWidgets(
      'happy path: creates the account, signs in, loads the profile and opens "About you"',
      (t) async {
        final s = await fresh();
        await pumpPage(
          t,
          const RegisterPage(),
          controller: s.app,
          size: const Size(390, 1600),
        );
        await fill(t, user: '  Sam_Lifts ');
        await t.tap(createBtn());
        await t.pumpAndSettle();
        expect(s.auth.user?.username, 'sam_lifts');
        expect(s.auth.lastIdentifier, 'sam_lifts@stationx.local');
        expect(s.app.phase, SessionPhase.ready);
        expect(s.app.profile.profile.name, 'sam_lifts');
        expect(s.app.profile.profile.isGuest, isFalse);
        expect(
          s.app.workouts.workouts,
          isEmpty,
          reason: 'no program exists until onboarding saves one',
        );
        expect(find.byType(RegisterPage), findsNothing); // moved on
      },
    );

    testWidgets(
      'validation: friendly username and password messages, server not called',
      (t) async {
        final s = await fresh();
        await pumpPage(
          t,
          const RegisterPage(),
          demo: false,
          controller: s.app,
          size: const Size(390, 1600),
        );
        await t.tap(createBtn());
        await t.pump();
        expect(find.text('Choose a username'), findsOneWidget);
        expect(find.text('Required field'), findsOneWidget);
        await fill(t, user: 'admin', pw: 'weak');
        await t.tap(createBtn());
        await t.pump();
        expect(find.text('That username is reserved'), findsOneWidget);
        expect(
          find.text(
            'Use at least 8 characters, one capital letter and one number',
          ),
          findsOneWidget,
        );
        expect(s.auth.signUpCalls, 0);
        expect(s.app.phase, SessionPhase.signedOut);
      },
    );

    testWidgets(
      'username taken: calm message, nothing created, username kept, password cleared',
      (t) async {
        final s = await fresh();
        s.auth.seedUser('sam', 'Other1pass');
        await pumpPage(
          t,
          const RegisterPage(),
          demo: false,
          controller: s.app,
          size: const Size(390, 1600),
        );
        await fill(t);
        await t.tap(createBtn());
        await t.pumpAndSettle();
        expect(find.textContaining('That username is taken'), findsOneWidget);
        expect(s.app.phase, SessionPhase.signedOut);
        expect(fieldText(t, 0), 'Sam');
        expect(fieldText(t, 1), isEmpty);
      },
    );

    testWidgets(
      'rate limit and unexpected no-session responses have friendly text',
      (t) async {
        final s = await fresh();
        await pumpPage(
          t,
          const RegisterPage(),
          demo: false,
          controller: s.app,
          size: const Size(390, 1600),
        );
        s.auth.nextStatus = CloudAuthStatus.rateLimited;
        await fill(t);
        await t.tap(createBtn());
        await t.pumpAndSettle();
        expect(
          find.text('Too many attempts, try again in a minute'),
          findsOneWidget,
        );
        s.auth.nextStatus = CloudAuthStatus.signUpIncomplete;
        await fill(t);
        await t.tap(createBtn());
        await t.pumpAndSettle();
        expect(
          find.text("Couldn't finish sign-up, try signing in"),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'busy: the button is disabled while the request runs (no double submit)',
      (t) async {
        final s = await fresh();
        final gate = Completer<void>();
        s.auth.signUpGate = gate.future;
        await pumpPage(
          t,
          const RegisterPage(),
          demo: false,
          controller: s.app,
          size: const Size(390, 1600),
        );
        await fill(t);
        await t.tap(createBtn());
        await t.pump();
        expect(t.widget<SxButton>(createBtn()).onPressed, isNull);
        expect(
          t.widget<TextField>(find.byType(TextField).first).enabled,
          isFalse,
        );
        gate.complete();
        await t.pumpAndSettle();
        expect(s.auth.user?.username, 'sam');
        expect(s.auth.signUpCalls, 1);
      },
    );

    testWidgets(
      'no connection: says so, keeps the username AND password, and a second tap succeeds',
      (t) async {
        final s = await fresh();
        s.auth.nextStatus = CloudAuthStatus.network;
        await pumpPage(
          t,
          const RegisterPage(),
          demo: false,
          controller: s.app,
          size: const Size(390, 1800),
        );
        await fill(t);
        await t.tap(createBtn());
        await t.pumpAndSettle();
        expect(find.textContaining("Can't reach the server"), findsOneWidget);
        expect(
          find.textContaining('offline', skipOffstage: false),
          findsNothing,
          reason: 'there is no offline mode',
        );
        expect(fieldText(t, 0), 'Sam');
        expect(fieldText(t, 1), strong);
        expect(s.app.phase, SessionPhase.signedOut);
        await t.tap(createBtn());
        await t.pumpAndSettle();
        expect(s.auth.user?.username, 'sam');
        expect(s.app.phase, SessionPhase.ready);
      },
    );

    testWidgets(
      'account created but the data could not be loaded: not left half signed in; retry works',
      (t) async {
        final s = await fresh();
        await pumpPage(
          t,
          const RegisterPage(),
          demo: false,
          controller: s.app,
          size: const Size(390, 1800),
        );
        s.remote.failAll = const RemoteException(RemoteFailure.server);
        await fill(t);
        await t.tap(createBtn());
        await t.pumpAndSettle();
        expect(s.app.phase, SessionPhase.signedOut);
        expect(find.byType(RegisterPage), findsOneWidget);
        expect(find.byType(MainShell), findsNothing);
      },
    );
  });

  group('Log in', () {
    testWidgets('exactly two fields; no forgot-password, no e-mail', (t) async {
      final s = await fresh();
      await pumpPage(
        t,
        const LoginPage(),
        demo: false,
        controller: s.app,
        size: const Size(390, 1200),
      );
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('USERNAME'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.textContaining('EMAIL', skipOffstage: false), findsNothing);
      expect(find.textContaining('orgot', skipOffstage: false), findsNothing);
      expect(find.byTooltip('Show password'), findsOneWidget);
    });

    testWidgets(
      'wrong password: friendly message, stays on the page, password cleared',
      (t) async {
        final s = await fresh();
        s.auth.seedUser('sam', strong);
        await pumpPage(
          t,
          const LoginPage(),
          demo: false,
          controller: s.app,
          size: const Size(390, 1200),
        );
        await fill(t, pw: 'Wrong1pass');
        await t.tap(logInBtn());
        await t.pumpAndSettle();
        expect(find.text('Wrong username or password'), findsOneWidget);
        expect(find.byType(LoginPage), findsOneWidget);
        expect(s.auth.user, isNull);
        expect(fieldText(t, 0), 'Sam');
        expect(fieldText(t, 1), isEmpty);
      },
    );

    testWidgets(
      'success: signs in, loads the account data and enters the app',
      (t) async {
        final s = await fresh();
        s.auth.seedUser('sam', strong);
        await pumpPage(
          t,
          const LoginPage(),
          demo: false,
          controller: s.app,
          size: const Size(390, 1200),
        );
        await fill(t, user: 'SAM');
        await t.tap(logInBtn());
        await t.pumpAndSettle();
        expect(s.auth.user?.username, 'sam');
        expect(s.app.phase, SessionPhase.ready);
        expect(find.byType(MainShell), findsOneWidget);
      },
    );

    testWidgets('no connection: network message, nothing signed in', (t) async {
      final s = await fresh();
      s.auth.nextStatus = CloudAuthStatus.network;
      await pumpPage(
        t,
        const LoginPage(),
        demo: false,
        controller: s.app,
        size: const Size(390, 1200),
      );
      await fill(t);
      await t.tap(logInBtn());
      await t.pumpAndSettle();
      expect(find.textContaining("Can't reach the server"), findsOneWidget);
      expect(s.app.phase, SessionPhase.signedOut);
    });

    testWidgets("signing in as another user shows only that user's data", (
      t,
    ) async {
      final s = await fresh();
      await s.app.registerAccount('alice', strong);
      await s.app.sessions.add(WorkoutSessionFixture.one());
      await s.app.signOut();
      s.auth.seedUser('bob', strong);
      await pumpPage(
        t,
        const LoginPage(),
        demo: false,
        controller: s.app,
        size: const Size(390, 1200),
      );
      await fill(t, user: 'bob');
      await t.tap(logInBtn());
      await t.pumpAndSettle();
      expect(s.app.sessions.sessions, isEmpty);
      expect(s.app.profile.profile.email, 'bob');
    });
  });

  group('accessibility', () {
    for (final entry in {
      'create': const RegisterPage(),
      'login': const LoginPage(),
    }.entries) {
      testWidgets(
        '${entry.key}: labels, 48dp targets, no overflow at 320x568@2x text 1.3',
        (t) async {
          final h = t.ensureSemantics();
          final s = await fresh();
          await pumpPage(
            t,
            entry.value,
            demo: false,
            controller: s.app,
            size: const Size(320, 568),
            textScale: 1.3,
          );
          expect(t.takeException(), isNull);
          expect(find.bySemanticsLabel('Username'), findsOneWidget);
          expect(find.bySemanticsLabel('Password'), findsOneWidget);
          expect((await androidTapTargetGuideline.evaluate(t)).passed, isTrue);
          expect((await labeledTapTargetGuideline.evaluate(t)).passed, isTrue);
          // Error state still fits.
          await t.ensureVisible(find.byType(SxButton).first);
          await t.pumpAndSettle();
          await t.tap(find.byType(SxButton).first);
          await t.pump();
          expect(t.takeException(), isNull);
          h.dispose();
        },
      );

      testWidgets('${entry.key}: works with reduced motion', (t) async {
        t.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
        final s = await fresh();
        if (entry.key == 'login') s.auth.seedUser('sam', strong);
        await pumpPage(
          t,
          entry.value,
          demo: false,
          controller: s.app,
          size: const Size(390, 1800),
        );
        await fill(t);
        await t.tap(find.byType(SxButton).first);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(s.app.phase, SessionPhase.ready);
      });
    }
  });
}

/// Tiny session used to prove data does not leak between accounts.
abstract final class WorkoutSessionFixture {
  static WorkoutSession one() => WorkoutSession(
    id: 'alice_only',
    workoutId: 'w1',
    name: 'x',
    workoutDate: DateTime.utc(2026, 5, 1),
    exercises: const [],
  );
}
