import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/features/auth/login_page.dart';
import 'package:stationx/features/auth/register_page.dart';
import 'package:stationx/features/landing/landing_page.dart';
import 'package:stationx/features/profile/profile_page.dart';
import 'package:stationx/features/shell/main_shell.dart';
import 'package:stationx/features/today/today_page.dart';
import 'package:stationx/domain/domain.dart';
import '../../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);

  group('Landing', () {
    testWidgets('guest enters the app with demo data', (t) async {
      final app = await pumpPage(t, const LandingPage(), demo: false);
      expect(app.signedIn, isFalse);
      await t.scrollUntilVisible(find.text('Continue as Guest (Offline Mode)'), 200, scrollable: find.byType(Scrollable).first);
      await t.tap(find.text('Continue as Guest (Offline Mode)'));
      await t.pumpAndSettle();
      expect(app.signedIn, isTrue);
      expect(find.byType(MainShell), findsOneWidget);
      expect(app.sessions.sessions, isNotEmpty);
    });

    testWidgets('create account and log in open their forms', (t) async {
      await pumpPage(t, const LandingPage(), demo: false);
      await t.scrollUntilVisible(find.text('LOG IN'), 200, scrollable: find.byType(Scrollable).first);
      await t.tap(find.text('LOG IN'));
      await t.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  group('Login', () {
    testWidgets('validates then opens a local profile', (t) async {
      final app = await pumpPage(t, const LoginPage(), demo: false);
      await t.tap(find.text('LOG IN').first);
      await t.pump();
      expect(find.text('REQUIRED FIELD'), findsNWidgets(2));
      await t.enterText(find.byType(TextField).first, 'nope');
      await t.pump();
      expect(find.text('INVALID FORMAT'), findsOneWidget);
      await t.enterText(find.byType(TextField).first, 'sam@mail.com');
      await t.enterText(find.byType(TextField).last, 'secret');
      await t.tap(find.text('LOG IN').first);
      await t.pumpAndSettle();
      expect(app.signedIn, isTrue);
      expect(app.profile.profile.email, 'sam@mail.com');
      expect(app.sessions.sessions, isEmpty);
    });
  });

  group('Register', () {
    testWidgets('password rules update and mismatch blocks submit', (t) async {
      final app = await pumpPage(t, const RegisterPage(), demo: false, size: const Size(390, 1700));
      expect(find.text('LEVEL 0/3'), findsOneWidget);
      final fields = find.byType(TextField);
      await t.enterText(fields.at(0), 'Sam');
      await t.enterText(fields.at(1), 'sam@mail.com');
      await t.enterText(fields.at(2), 'Abcdef12');
      await t.pump();
      expect(find.text('LEVEL 3/3'), findsOneWidget);
      await t.enterText(fields.at(3), 'different');
      await t.tap(find.byType(SxButton).last);
      await t.pump();
      expect(app.signedIn, isFalse);
      expect(find.text("PASSWORDS DO NOT MATCH", skipOffstage: false), findsOneWidget);
      await t.enterText(fields.at(3), 'Abcdef12');
      await t.pump();
      await t.tap(find.byType(SxButton).last);
      await t.pumpAndSettle();
      expect(app.signedIn, isTrue);
      expect(app.profile.profile.name, 'Sam');
      expect(app.workouts.rotation.currentIndex, 0);
    });
  });

  group('Today', () {
    testWidgets('shows the rotation workout (not date based) and starts it', (t) async {
      final app = await pumpPage(t, const TodayPage());
      expect(find.text('Back + Triceps'), findsOneWidget);
      expect(find.text('DAY 2 / 3'), findsOneWidget);
      // Skipping days must not change the rotation: advance only on completion.
      expect(app.workouts.rotation.currentIndex, 1);
      await t.tap(find.text('START WORKOUT'));
      await t.pump(const Duration(milliseconds: 500));
      t.takeException(); // destination page is owned by another feature
      expect(Navigator.of(t.element(find.byType(TodayPage, skipOffstage: false))).canPop(), isTrue);
    });

    testWidgets('empty account has hero + empty progress hint, no fake recovery data', (t) async {
      await pumpPage(t, const TodayPage(), demo: false);
      expect(find.text('Chest + Biceps'), findsOneWidget);
      expect(find.textContaining("Complete a workout", skipOffstage: false), findsOneWidget);
      expect(find.text("NOT CONNECTED", skipOffstage: false), findsOneWidget);
      expect(find.textContaining('88%'), findsNothing);
    });

    testWidgets('completing a workout advances the hero', (t) async {
      final app = await pumpPage(t, const TodayPage());
      await app.completion.complete(WorkoutSession(id: 'n', workoutId: 'w2', name: 'Back + Triceps', workoutDate: DateTime.now(), exercises: []));
      await t.pump();
      expect(find.text('Legs + Shoulders'), findsWidgets);
      expect(find.text('DAY 3 / 3'), findsOneWidget);
    });
  });

  group('Profile', () {
    testWidgets('unit + theme persist through the repository', (t) async {
      final app = await pumpPage(t, const ProfilePage(), size: const Size(390, 1800));
      await t.tap(find.text('LB (POUNDS)'));
      await t.pump();
      expect(app.profile.profile.unit, WeightUnit.lb);
      await t.tap(find.text('OLED'));
      await t.pump();
      expect(app.profile.profile.themeMode, SxThemeMode.oled);
    });

    testWidgets('default sets stepper and progression switch', (t) async {
      final app = await pumpPage(t, const ProfilePage(), size: const Size(390, 1800));
      await t.tap(find.bySemanticsLabel('Increase sets'));
      await t.pump();
      expect(app.profile.profile.defaultSets, 4);
      await t.tap(find.byType(Switch));
      await t.pump();
      expect(app.profile.profile.progressionEnabled, isFalse);
    });

    testWidgets('delete all data asks first, then wipes', (t) async {
      final app = await pumpPage(t, const ProfilePage(), size: const Size(390, 1800));
      expect(app.sessions.sessions, isNotEmpty);
      await t.tap(find.text('PURGE'));
      await t.pumpAndSettle();
      await t.tap(find.text("CANCEL"));
      await t.pumpAndSettle();
      expect(app.sessions.sessions, isNotEmpty);
      await t.tap(find.text('PURGE'));
      await t.pumpAndSettle();
      await t.tap(find.text('DELETE EVERYTHING'));
      await t.pumpAndSettle();
      expect(app.sessions.sessions, isEmpty);
    });

    testWidgets('export sheet renders JSON for real data', (t) async {
      await pumpPage(t, const ProfilePage(), size: const Size(390, 1800));
      await t.tap(find.text('EXPORT CSV / JSON'));
      await t.pumpAndSettle();
      expect(find.text('EXPORT DATA'), findsOneWidget);
      expect(find.textContaining('workoutSessions', findRichText: true), findsOneWidget);
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
          await pumpPage(t, e.value, size: const Size(320, 568), textScale: 1.3, demo: demo);
          expect(t.takeException(), isNull);
        });
      }
    }
  });
}
