import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/data/remote/remote_exception.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/auth/about_you_page.dart';
import 'package:stationx/features/auth/login_page.dart';
import 'package:stationx/features/auth/register_page.dart';
import 'package:stationx/features/onboarding/schedule_setup_flow.dart';
import 'package:stationx/features/shell/main_shell.dart';
import '../../helpers/online_fakes.dart';
import '../../helpers/pump.dart';

const _pw = 'Strong1pass';

Finder field(String label) => find.bySemanticsLabel(label);
Finder tf(int i) => find.byType(TextField).at(i);
Finder continueBtn() => find.widgetWithText(SxButton, 'CONTINUE');
bool continueEnabled(WidgetTester t) =>
    t.widget<SxButton>(continueBtn()).onPressed != null;

Future<void> typeAll(
  WidgetTester t, {
  String age = '30',
  String h = '180',
  String w = '80',
}) async {
  await t.enterText(tf(0), age);
  await t.enterText(tf(1), h);
  await t.enterText(tf(2), w);
  await t.pump();
}

void main() {
  setUpAll(loadAppFonts);

  Future<({OnlineRig rig, AppController app})> openPage(
    WidgetTester t, {
    Size size = const Size(390, 900),
    double scale = 1.0,
  }) async {
    final rig = OnlineRig();
    await rig.app.registerAccount('sam', _pw);
    final app = await pumpPage(
      t,
      const AboutYouPage(),
      controller: rig.app,
      demo: false,
      size: size,
      textScale: scale,
    );
    return (rig: rig, app: app);
  }

  testWidgets('shows the reason and three labelled number inputs', (t) async {
    final h = t.ensureSemantics();
    await openPage(t);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(field('Age'), findsOneWidget);
    expect(field('Height'), findsOneWidget);
    expect(field('Weight'), findsOneWidget);
    expect(
      find.textContaining('Used for body-weight stats and calorie estimates'),
      findsOneWidget,
    );
    expect(find.text('Skip for now'), findsOneWidget);
    expect(find.text('You can add this later in Profile.'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      final k = t.widget<TextField>(tf(i)).keyboardType;
      expect(k == TextInputType.number || k.decimal == true, isTrue);
    }
    h.dispose();
  });

  testWidgets(
    'Continue is disabled until all three are valid; friendly messages',
    (t) async {
      await openPage(t);
      expect(continueEnabled(t), isFalse);
      await t.enterText(tf(0), '30');
      await t.pump();
      expect(continueEnabled(t), isFalse);
      await t.enterText(tf(1), '99');
      await t.enterText(tf(2), '20');
      await t.pump();
      expect(
        find.text('Height must be between 100 and 250 cm'),
        findsOneWidget,
      );
      expect(find.text('Weight must be between 30 and 300 kg'), findsOneWidget);
      expect(continueEnabled(t), isFalse);
      await t.enterText(tf(0), '12');
      await t.pump();
      expect(find.text('Age must be between 13 and 100'), findsOneWidget);
      await typeAll(t);
      expect(continueEnabled(t), isTrue);
      expect(find.textContaining('must be between'), findsNothing);
      await t.enterText(tf(2), '12.5.3');
      await t.pump();
      expect(continueEnabled(t), isFalse);
    },
  );

  testWidgets(
    'metric Continue saves age/cm/kg to the server once and goes to schedule setup',
    (t) async {
      final o = await openPage(t);
      final app = o.app;
      var notified = 0;
      app.profile.addListener(() => notified++);
      final before = app.profile.profile;
      await typeAll(t, age: '31', h: '181.5', w: '82.4');
      await t.tap(continueBtn());
      await t.pumpAndSettle();
      final p = app.profile.profile;
      expect(
        (p.age, p.heightCm, p.weightKg, p.unit),
        (31, 181.5, 82.4, WeightUnit.kg),
      );
      expect(p.name, before.name);
      expect(p.themeMode, before.themeMode);
      expect(p.cardioDistanceUnitKm, before.cardioDistanceUnitKm);
      expect(notified, 1);
      final row = o.rig.remote.rowOf('profiles', o.rig.auth.user!.id, '_')!;
      expect(
        (row['age'], row['height_cm'], row['weight_kg']),
        (31, 181.5, 82.4),
      );
      expect(find.byType(ScheduleSetupFlow), findsOneWidget);
      expect(find.byType(AboutYouPage), findsNothing);
    },
  );

  testWidgets(
    'a failed save keeps the user here with the numbers intact, and Continue works on retry',
    (t) async {
      final o = await openPage(t);
      await typeAll(t, age: '31', h: '181', w: '82');
      o.rig.remote.failNext(const RemoteException(RemoteFailure.offline));
      await t.tap(continueBtn());
      await t.pumpAndSettle();
      expect(find.byType(AboutYouPage), findsOneWidget);
      expect(find.byType(ScheduleSetupFlow), findsNothing);
      expect(find.textContaining("Couldn't save your details"), findsOneWidget);
      expect(
        o.app.profile.profile.age,
        const UserProfile().age,
        reason: 'nothing was confirmed',
      );
      expect(t.widget<TextField>(tf(0)).controller!.text, '31');
      expect(continueEnabled(t), isTrue);
      await t.tap(continueBtn());
      await t.pumpAndSettle();
      expect(o.app.profile.profile.age, 31);
      expect(find.byType(ScheduleSetupFlow), findsOneWidget);
    },
  );

  testWidgets('imperial inputs convert, save as cm/kg and set unit lb', (
    t,
  ) async {
    final app = (await openPage(t)).app;
    await t.tap(find.text('IMPERIAL (FT, IN, LB)'));
    await t.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(4)); // age, ft, in, weight
    expect(field('Height (ft)'), findsOneWidget);
    expect(field('Height (in)'), findsOneWidget);
    await t.enterText(tf(0), '28');
    await t.enterText(tf(1), '5');
    await t.enterText(tf(2), '9');
    await t.enterText(tf(3), '165');
    await t.pump();
    expect(continueEnabled(t), isTrue);
    await t.tap(continueBtn());
    await t.pumpAndSettle();
    final p = app.profile.profile;
    expect(p.age, 28);
    expect(p.heightCm, BodyMetrics.cmFromFeetInches(5, 9));
    expect(p.weightKg, BodyMetrics.kgFromLb(165));
    expect(p.unit, WeightUnit.lb);
  });

  testWidgets(
    'imperial: inches over 11 explained; switching units carries valid values',
    (t) async {
      await openPage(t);
      await typeAll(t, age: '30', h: '180', w: '80');
      await t.tap(find.text('IMPERIAL (FT, IN, LB)'));
      await t.pumpAndSettle();
      expect(t.widget<TextField>(tf(1)).controller!.text, '5');
      expect(t.widget<TextField>(tf(2)).controller!.text, '11');
      expect(t.widget<TextField>(tf(3)).controller!.text, '176.4');
      await t.enterText(tf(2), '12');
      await t.pump();
      expect(find.text('Inches go from 0 to 11'), findsOneWidget);
      expect(continueEnabled(t), isFalse);
    },
  );

  testWidgets('Skip leaves the profile untouched and continues', (t) async {
    final app = (await openPage(t)).app;
    final before = app.profile.profile;
    await t.tap(find.text('Skip for now'));
    await t.pumpAndSettle();
    final p = app.profile.profile;
    expect(
      (p.age, p.heightCm, p.weightKg, p.unit),
      (before.age, before.heightCm, before.weightKg, before.unit),
    );
    expect(find.byType(ScheduleSetupFlow), findsOneWidget);
  });

  testWidgets('system Back behaves like Skip', (t) async {
    final app = (await openPage(t)).app;
    await t.enterText(
      tf(0),
      '40',
    ); // typed but not confirmed: must not be saved
    await t.pump();
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(app.profile.profile.age, const UserProfile().age);
    expect(find.byType(ScheduleSetupFlow), findsOneWidget);
  });

  group('sign-up flow', () {
    Future<void> create(WidgetTester t) async {
      await t.enterText(find.byType(TextField).at(0), 'Sam');
      await t.enterText(find.byType(TextField).at(1), _pw);
      await t.pump();
      await t.tap(find.widgetWithText(SxButton, 'CREATE ACCOUNT'));
      await t.pumpAndSettle();
    }

    testWidgets(
      'Create account → About you → schedule setup → app, values saved',
      (t) async {
        final rig = OnlineRig();
        await pumpPage(
          t,
          const RegisterPage(),
          demo: false,
          controller: rig.app,
          size: const Size(390, 1600),
        );
        await rig.app.init();
        await create(t);
        expect(find.byType(AboutYouPage), findsOneWidget);
        expect(find.byType(ScheduleSetupFlow), findsNothing);
        expect(rig.app.profile.profile.isGuest, isFalse);
        await typeAll(t, age: '29', h: '170', w: '65');
        await t.tap(continueBtn());
        await t.pumpAndSettle();
        expect(find.byType(ScheduleSetupFlow), findsOneWidget);
        final p = rig.app.profile.profile;
        expect(
          (p.age, p.heightCm, p.weightKg, p.name, p.isGuest),
          (29, 170.0, 65.0, 'sam', false),
        );
        await t.tap(
          find.textContaining(RegExp('skip', caseSensitive: false)).first,
        );
        await t.pumpAndSettle();
        if (find.byType(MainShell).evaluate().isEmpty) {
          // A confirm may be shown on later steps; step 0 exits directly.
          fail('did not enter the app after skipping schedule setup');
        }
        expect(rig.app.profile.profile.age, 29);
      },
    );

    testWidgets(
      'a connection problem while creating the account creates nothing and says so',
      (t) async {
        final rig = OnlineRig();
        await pumpPage(
          t,
          const RegisterPage(),
          demo: false,
          controller: rig.app,
          size: const Size(390, 1800),
        );
        await rig.app.init();
        rig.remote.failAll = const RemoteException(RemoteFailure.offline);
        await create(t);
        expect(find.byType(AboutYouPage), findsNothing);
        expect(find.textContaining("Can't reach the server"), findsOneWidget);
        expect(rig.app.phase, SessionPhase.signedOut);
      },
    );

    testWidgets('Log in does NOT show it', (t) async {
      final rig = OnlineRig()..auth.seedUser('sam', _pw);
      await pumpPage(
        t,
        const LoginPage(),
        demo: false,
        controller: rig.app,
        size: const Size(390, 1200),
      );
      await rig.app.init();
      await t.enterText(find.byType(TextField).at(0), 'sam');
      await t.enterText(find.byType(TextField).at(1), _pw);
      await t.pump();
      await t.tap(find.widgetWithText(SxButton, 'LOG IN'));
      await t.pumpAndSettle();
      expect(find.byType(AboutYouPage), findsNothing);
      expect(find.byType(MainShell), findsOneWidget);
    });
  });

  group('quality', () {
    testWidgets(
      'no overflow at 320x568 text 1.3, imperial too, keyboard inset',
      (t) async {
        final h = t.ensureSemantics();
        await openPage(t, size: const Size(320, 568), scale: 1.3);
        expect(t.takeException(), isNull);
        await t.tap(find.text('IMPERIAL (FT, IN, LB)'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await t.enterText(tf(0), '3'); // error state
        await t.pumpAndSettle();
        t.view.viewInsets = const FakeViewPadding(bottom: 500); // keyboard open
        addTearDown(t.view.resetViewInsets);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await t.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        h.dispose();
      },
    );

    testWidgets('a11y: labels, 48dp targets', (t) async {
      final h = t.ensureSemantics();
      await openPage(t, size: const Size(320, 568), scale: 1.3);
      expect((await androidTapTargetGuideline.evaluate(t)).passed, isTrue);
      expect((await labeledTapTargetGuideline.evaluate(t)).passed, isTrue);
      h.dispose();
    });

    testWidgets('works with reduced motion', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final app = (await openPage(t)).app;
      await typeAll(t);
      await t.tap(continueBtn());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(app.profile.profile.age, 30);
    });
  });
}
