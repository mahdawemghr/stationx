import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/profile/profile_page.dart';
import 'package:stationx/features/today/today_page.dart';
import '../../helpers/pump.dart';

class FakeHealth extends ChangeNotifier implements HealthRepository {
  FakeHealth(this._status, [this._provider = HealthProvider.healthConnect]);
  final HealthProvider _provider;
  HealthStatus _status;
  bool grant = true;
  int connects = 0, disconnects = 0, installs = 0;

  @override
  HealthProvider get provider => _provider;
  @override
  HealthStatus get status => _status;
  @override
  bool get busy => false;
  @override
  Future<void> init() async {}
  @override
  Future<bool> connect() async {
    connects++;
    _status = grant ? HealthStatus.connected : HealthStatus.notConnected;
    notifyListeners();
    return grant;
  }

  @override
  Future<void> disconnect() async {
    disconnects++;
    _status = HealthStatus.notConnected;
    notifyListeners();
  }

  @override
  Future<void> installProvider() async => installs++;
}

void main() {
  setUpAll(loadAppFonts);

  group('Today has no recovery summary', () {
    for (final status in HealthStatus.values) {
      testWidgets(
        'status ${status.name}: no Recovery card, no sleep or resting heart rate',
        (t) async {
          await pumpPage(t, const TodayPage(), health: FakeHealth(status));
          await t.pumpAndSettle();
          expect(find.text('Recovery'), findsNothing);
          expect(find.textContaining('Sleep'), findsNothing);
          expect(find.textContaining('Resting HR'), findsNothing);
          expect(find.textContaining('sleep'), findsNothing);
        },
      );
    }

    testWidgets(
      'small screen: Today does not overflow at 320x568 @1.3x with Health Connect connected',
      (t) async {
        await pumpPage(
          t,
          const TodayPage(),
          health: FakeHealth(HealthStatus.connected),
          size: const Size(320, 568),
          textScale: 1.3,
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      },
    );
  });

  group('Profile Health Connect row', () {
    Future<void> showRow(WidgetTester t) async {
      await t.scrollUntilVisible(
        find.text('Health Connect'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }

    testWidgets('unsupported platform: no action, honest text', (t) async {
      await pumpPage(
        t,
        const ProfilePage(),
        health: FakeHealth(HealthStatus.unsupported),
      );
      await showRow(t);
      expect(find.text('Not available on this device'), findsOneWidget);
    });

    testWidgets('the row no longer talks about sleep or resting heart rate', (
      t,
    ) async {
      await pumpPage(
        t,
        const ProfilePage(),
        health: FakeHealth(HealthStatus.notConnected),
      );
      await showRow(t);
      expect(find.textContaining('sleep'), findsNothing);
      expect(find.textContaining('resting'), findsNothing);
      expect(find.textContaining('imports workouts'), findsOneWidget);
    });

    testWidgets('connect then disconnect with confirmations', (t) async {
      final h = FakeHealth(HealthStatus.notConnected);
      await pumpPage(t, const ProfilePage(), health: h);
      await showRow(t);
      await t.ensureVisible(find.widgetWithText(SxButton, 'CONNECT'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(SxButton, 'CONNECT'));
      await t.pumpAndSettle();
      expect(find.textContaining('READ the workouts'), findsOneWidget);
      expect(find.textContaining('sleep'), findsNothing);
      expect(h.connects, 0); // nothing requested before the user confirms
      await t.tap(find.text('CONTINUE'));
      await t.pumpAndSettle();
      expect(h.status, HealthStatus.connected);
      await showRow(t);
      await t.ensureVisible(find.widgetWithText(SxButton, 'DISCONNECT'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(SxButton, 'DISCONNECT'));
      await t.pumpAndSettle();
      expect(find.textContaining('restarted'), findsOneWidget);
      await t.tap(find.text('DISCONNECT').last);
      await t.pumpAndSettle();
      expect(h.disconnects, 1);
      expect(h.status, HealthStatus.notConnected);
    });

    testWidgets('cancelling the explanation never requests permission', (
      t,
    ) async {
      final h = FakeHealth(HealthStatus.notConnected);
      await pumpPage(t, const ProfilePage(), health: h);
      await showRow(t);
      await t.ensureVisible(find.widgetWithText(SxButton, 'CONNECT'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(SxButton, 'CONNECT'));
      await t.pumpAndSettle();
      await t.tap(find.text('CANCEL'));
      await t.pumpAndSettle();
      expect(h.connects, 0);
    });

    testWidgets(
      'denied permission shows a calm message with the concrete next step',
      (t) async {
        final h = FakeHealth(HealthStatus.notConnected)..grant = false;
        await pumpPage(t, const ProfilePage(), health: h);
        await showRow(t);
        await t.ensureVisible(find.widgetWithText(SxButton, 'CONNECT'));
        await t.pumpAndSettle();
        await t.tap(find.widgetWithText(SxButton, 'CONNECT'));
        await t.pumpAndSettle();
        await t.tap(find.text('CONTINUE'));
        await t.pumpAndSettle();
        expect(find.textContaining('Access was not granted'), findsOneWidget);
        expect(
          find.textContaining('Health Connect › App permissions'),
          findsOneWidget,
        );
        expect(h.status, HealthStatus.notConnected);
      },
    );

    testWidgets('not installed offers install', (t) async {
      final h = FakeHealth(HealthStatus.notInstalled);
      await pumpPage(t, const ProfilePage(), health: h);
      await showRow(t);
      await t.ensureVisible(find.widgetWithText(SxButton, 'INSTALL'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(SxButton, 'INSTALL'));
      await t.pump();
      expect(h.installs, 1);
    });
  });

  group('iOS wording (Apple Health)', () {
    testWidgets('explains Apple Health and asks only after confirmation', (
      t,
    ) async {
      final h = FakeHealth(
        HealthStatus.notConnected,
        HealthProvider.appleHealth,
      );
      await pumpPage(t, const ProfilePage(), health: h);
      await t.scrollUntilVisible(
        find.text('Apple Health'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(find.widgetWithText(SxButton, 'CONNECT'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(SxButton, 'CONNECT'));
      await t.pumpAndSettle();
      expect(find.text('CONNECT APPLE HEALTH?'), findsOneWidget);
      expect(
        find.textContaining('iOS will ask which data to share'),
        findsOneWidget,
      );
      expect(h.connects, 0);
    });

    testWidgets(
      'Profile row says Apple Health and the disconnect dialog points to Settings',
      (t) async {
        final h = FakeHealth(
          HealthStatus.connected,
          HealthProvider.appleHealth,
        );
        await pumpPage(t, const ProfilePage(), health: h);
        await t.scrollUntilVisible(
          find.text('Apple Health'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await t.ensureVisible(find.widgetWithText(SxButton, 'DISCONNECT'));
        await t.pumpAndSettle();
        await t.tap(find.widgetWithText(SxButton, 'DISCONNECT'));
        await t.pumpAndSettle();
        expect(
          find.textContaining('To fully remove access, open Settings › Health'),
          findsOneWidget,
        );
      },
    );
  });
}
