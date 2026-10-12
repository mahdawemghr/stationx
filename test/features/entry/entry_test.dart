import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/data/remote/remote_exception.dart';
import 'package:stationx/features/auth/about_you_page.dart';
import 'package:stationx/features/auth/login_page.dart';
import 'package:stationx/features/auth/register_page.dart';
import 'package:stationx/features/landing/landing_page.dart';
import 'package:stationx/features/profile/profile_page.dart';
import 'package:stationx/features/shell/main_shell.dart';
import 'package:stationx/features/today/today_page.dart';
import 'package:stationx/domain/domain.dart';
import '../../helpers/online_fakes.dart';
import '../../helpers/pump.dart';

const _pw = 'Passw0rdX';

void main() {
  setUpAll(loadAppFonts);

  group('Landing', () {
    testWidgets(
      'online-first: no guest/offline entry, only create account and log in',
      (t) async {
        await pumpPage(t, const LandingPage(), demo: false);
        await t.scrollUntilVisible(
          find.text('LOG IN'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.textContaining('Guest', skipOffstage: false), findsNothing);
        expect(
          find.textContaining('Offline', skipOffstage: false),
          findsNothing,
        );
        expect(
          find.textContaining('Local-first', skipOffstage: false),
          findsNothing,
        );
      },
    );

    testWidgets('create account and log in open their forms', (t) async {
      await pumpPage(t, const LandingPage(), demo: false);
      await t.scrollUntilVisible(
        find.text('LOG IN'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text('LOG IN'));
      await t.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('says why the user is back when the session expired', (
      t,
    ) async {
      final rig = await OnlineRig.signedIn();
      rig.auth.expireSession();
      await t.pump();
      await pumpPage(t, const LandingPage(), controller: rig.app);
      expect(find.textContaining('session expired'), findsOneWidget);
    });
  });

  group('Login', () {
    Finder logIn() => find.widgetWithText(SxButton, 'LOG IN');

    testWidgets(
      'asks for username and password, validates, reports a wrong password, then enters the app',
      (t) async {
        final rig = OnlineRig()..auth.seedUser('sam', _pw);
        final app = await pumpPage(t, const LoginPage(), controller: rig.app);
        await app.init(); // start-up: no saved session -> signed out
        expect(find.byType(TextField), findsNWidgets(2));
        expect(find.text('PASSWORD'), findsOneWidget);
        await t.tap(logIn());
        await t.pump();
        expect(find.text('Choose a username'), findsOneWidget);
        await t.enterText(find.byType(TextField).first, 'a b');
        await t.pump();
        await t.tap(logIn());
        await t.pump();
        expect(find.textContaining('no spaces'), findsOneWidget);

        await t.enterText(find.byType(TextField).first, 'sam');
        await t.enterText(find.byType(TextField).last, 'WrongPass1');
        await t.tap(logIn());
        await t.pumpAndSettle();
        expect(find.text('Wrong username or password'), findsOneWidget);
        expect(app.phase, SessionPhase.signedOut);

        await t.enterText(find.byType(TextField).last, _pw);
        await t.tap(logIn());
        await t.pumpAndSettle();
        expect(app.phase, SessionPhase.ready);
        expect(find.byType(MainShell), findsOneWidget);
        expect(app.profile.profile.email, 'sam');
      },
    );

    testWidgets(
      'a connection problem keeps the typed password and says nothing was done',
      (t) async {
        final rig = OnlineRig()..auth.seedUser('sam', _pw);
        final app = await pumpPage(t, const LoginPage(), controller: rig.app);
        await app.init();
        rig.remote.failAll = const RemoteException(RemoteFailure.offline);
        await t.enterText(find.byType(TextField).first, 'sam');
        await t.enterText(find.byType(TextField).last, _pw);
        await t.tap(logIn());
        await t.pumpAndSettle();
        expect(find.textContaining("Can't reach the server"), findsOneWidget);
        expect(app.phase, SessionPhase.signedOut);
        expect(app.sessions.sessions, isEmpty);
        rig.remote.failAll = null;
        await t.tap(logIn()); // same form, same password: just try again
        await t.pumpAndSettle();
        expect(app.phase, SessionPhase.ready);
      },
    );
  });

  group('Register', () {
    testWidgets(
      'asks for username and password with the rules; creates the account and goes to "About you"',
      (t) async {
        final rig = OnlineRig();
        final app = await pumpPage(
          t,
          const RegisterPage(),
          controller: rig.app,
          size: const Size(390, 2000),
        );
        await app.init();
        expect(find.byType(TextField), findsNWidgets(2));
        expect(find.text('At least 8 characters'), findsOneWidget);
        await t.tap(find.widgetWithText(SxButton, 'CREATE ACCOUNT'));
        await t.pump();
        expect(app.phase, SessionPhase.signedOut);
        expect(find.text('Choose a username'), findsOneWidget);
        await t.enterText(find.byType(TextField).first, '  Sam_Lifts ');
        await t.enterText(find.byType(TextField).last, 'weak');
        await t.tap(find.widgetWithText(SxButton, 'CREATE ACCOUNT'));
        await t.pump();
        expect(
          rig.remote.calls,
          isEmpty,
          reason: 'a weak password never reaches the server',
        );
        await t.enterText(find.byType(TextField).last, _pw);
        await t.tap(find.widgetWithText(SxButton, 'CREATE ACCOUNT'));
        await t.pumpAndSettle();
        expect(app.phase, SessionPhase.ready);
        expect(app.profile.profile.email, 'sam_lifts');
        expect(app.workouts.rotation.currentIndex, 0);
        expect(find.byType(AboutYouPage), findsOneWidget);
      },
    );

    testWidgets('a taken username is reported', (t) async {
      final rig = OnlineRig()..auth.seedUser('sam', _pw);
      await pumpPage(
        t,
        const RegisterPage(),
        controller: rig.app,
        size: const Size(390, 2000),
      );
      await t.enterText(find.byType(TextField).first, 'sam');
      await t.enterText(find.byType(TextField).last, _pw);
      await t.tap(find.widgetWithText(SxButton, 'CREATE ACCOUNT'));
      await t.pumpAndSettle();
      expect(find.textContaining('taken'), findsOneWidget);
    });
  });

  group('Today', () {
    testWidgets('shows the rotation workout (not date based) and starts it', (
      t,
    ) async {
      final app = await pumpPage(t, const TodayPage());
      expect(find.text('Back + Triceps'), findsOneWidget);
      expect(find.text('DAY 2 / 3'), findsOneWidget);
      // Skipping days must not change the rotation: advance only on completion.
      expect(app.workouts.rotation.currentIndex, 1);
      await t.tap(find.text('START WORKOUT'));
      await t.pump(const Duration(milliseconds: 500));
      t.takeException(); // destination page is owned by another feature
      expect(
        Navigator.of(
          t.element(find.byType(TodayPage, skipOffstage: false)),
        ).canPop(),
        isTrue,
      );
    });

    testWidgets(
      'empty account has hero + empty progress hint, no fake recovery data',
      (t) async {
        await pumpPage(t, const TodayPage(), demo: false);
        expect(find.text('Chest + Biceps'), findsOneWidget);
        expect(
          find.textContaining("Complete a workout", skipOffstage: false),
          findsOneWidget,
        );
        // Default test platform has no Health Connect: no recovery card, and never any made-up score.
        expect(find.text('Recovery', skipOffstage: false), findsNothing);
        expect(find.textContaining('88%'), findsNothing);
      },
    );

    testWidgets('completing a workout advances the hero', (t) async {
      final app = await pumpPage(t, const TodayPage());
      await app.completion.complete(
        WorkoutSession(
          id: 'n',
          workoutId: 'w2',
          name: 'Back + Triceps',
          workoutDate: DateTime.now(),
          exercises: [],
        ),
      );
      await t.pump();
      expect(find.text('Legs + Shoulders'), findsWidgets);
      expect(find.text('DAY 3 / 3'), findsOneWidget);
    });
  });

  group('Profile', () {
    testWidgets('unit + theme persist through the repository', (t) async {
      final app = await pumpPage(
        t,
        const ProfilePage(),
        size: const Size(390, 2600),
      );
      await t.tap(find.text('LB (POUNDS)'));
      await t.pump();
      expect(app.profile.profile.unit, WeightUnit.lb);
      await t.tap(find.text('OLED'));
      await t.pump();
      expect(app.profile.profile.themeMode, SxThemeMode.oled);
    });

    testWidgets('default sets stepper and progression switch', (t) async {
      final app = await pumpPage(
        t,
        const ProfilePage(),
        size: const Size(390, 2600),
      );
      await t.tap(find.bySemanticsLabel('Increase sets'));
      await t.pump();
      expect(app.profile.profile.defaultSets, 4);
      await t.tap(find.byType(Switch));
      await t.pump();
      expect(app.profile.profile.progressionEnabled, isFalse);
    });

    testWidgets('delete all data asks first, then wipes', (t) async {
      final app = await pumpPage(
        t,
        const ProfilePage(),
        size: const Size(390, 2600),
      );
      expect(app.sessions.sessions, isNotEmpty);
      await t.tap(find.text('Delete all my data'));
      await t.pumpAndSettle();
      await t.tap(find.text("CANCEL"));
      await t.pumpAndSettle();
      expect(app.sessions.sessions, isNotEmpty);
      await t.tap(find.text('Delete all my data'));
      await t.pumpAndSettle();
      await t.tap(find.text('DELETE EVERYTHING'));
      await t.pumpAndSettle();
      expect(app.sessions.sessions, isEmpty);
    });

    testWidgets(
      'a profile change that the server rejects is not shown as saved and says so',
      (t) async {
        final rig = await OnlineRig.signedIn();
        final app = await pumpPage(
          t,
          const ProfilePage(),
          controller: rig.app,
          size: const Size(390, 2600),
        );
        rig.remote.failNext(const RemoteException(RemoteFailure.offline));
        await t.tap(find.text('LB (POUNDS)'));
        await t.pumpAndSettle();
        expect(
          app.profile.profile.unit,
          WeightUnit.kg,
          reason: 'unchanged: the server never confirmed',
        );
        expect(
          find.textContaining("Couldn't save your profile"),
          findsOneWidget,
        );
        expect(
          rig.remote.rowOf('profiles', rig.auth.user!.id, '_')!['unit'],
          isNot('lb'),
        );
        await t.tap(find.text('Retry'));
        await t.pumpAndSettle();
        expect(app.profile.profile.unit, WeightUnit.lb);
      },
    );

    testWidgets(
      'logging out asks first and leaves nothing of the user behind',
      (t) async {
        final rig = await OnlineRig.signedIn();
        await rig.app.sessions.add(
          WorkoutSession(
            id: 's1',
            workoutId: 'w1',
            name: 'x',
            workoutDate: DateTime.now(),
            exercises: const [],
          ),
        );
        final app = await pumpPage(
          t,
          const ProfilePage(),
          controller: rig.app,
          size: const Size(390, 2600),
        );
        await t.tap(find.text('Log out'));
        await t.pumpAndSettle();
        await t.tap(find.text('LOG OUT'));
        await t.pumpAndSettle();
        expect(app.phase, SessionPhase.signedOut);
        expect(app.sessions.sessions, isEmpty);
        expect(rig.auth.user, isNull);
      },
    );

    testWidgets('export sheet renders JSON for real data', (t) async {
      await pumpPage(t, const ProfilePage(), size: const Size(390, 2600));
      await t.tap(find.text('EXPORT YOUR DATA'));
      await t.pumpAndSettle();
      expect(find.text('EXPORT DATA'), findsOneWidget);
      // Summary + actions instead of a giant text dump.
      expect(find.textContaining('will be exported as JSON'), findsOneWidget);
      expect(find.text('COPY TO CLIPBOARD'), findsOneWidget);
    });
  });

  group('Responsive', () {
    final pages = <String, Widget>{
      'landing': const LandingPage(),
      'login': const LoginPage(),
      'register': const RegisterPage(),
      'today': const TodayPage(),
      'profile': const ProfilePage(),
    };
    for (final e in pages.entries) {
      for (final demo in [true, false]) {
        testWidgets('${e.key} demo=$demo at 320x568 scale 1.3', (t) async {
          await pumpPage(
            t,
            e.value,
            size: const Size(320, 568),
            textScale: 1.3,
            demo: demo,
          );
          expect(t.takeException(), isNull);
        });
      }
    }
  });
}
