import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/profile/profile_page.dart';
import 'package:stationx/features/today/today_page.dart';
import '../../helpers/pump.dart';

class FakeHealth extends ChangeNotifier implements HealthRepository {
  FakeHealth(this._status, [this._snap, this._provider = HealthProvider.healthConnect]);
  final HealthProvider _provider;
  HealthStatus _status;
  HealthSnapshot? _snap;
  bool grant = true;
  int connects = 0, disconnects = 0, installs = 0;

  @override
  HealthProvider get provider => _provider;
  @override
  HealthStatus get status => _status;
  @override
  HealthSnapshot? get snapshot => _snap;
  @override
  bool get busy => false;
  @override
  Future<void> init() async {}
  @override
  Future<bool> connect() async {
    connects++;
    _status = grant ? HealthStatus.connected : HealthStatus.notConnected;
    if (grant) _snap = HealthSnapshot(fetchedAt: DateTime.now(), sleepMinutes: 460, restingHr: 54, restingHrAvg7d: 56);
    notifyListeners();
    return grant;
  }

  @override
  Future<void> refresh({bool force = false}) async {}
  @override
  Future<void> disconnect() async {
    disconnects++;
    _status = HealthStatus.notConnected;
    _snap = null;
    notifyListeners();
  }

  @override
  Future<void> installProvider() async => installs++;
}

void main() {
  setUpAll(loadAppFonts);

  group('Today recovery card', () {
    testWidgets('hidden where Health Connect cannot exist', (t) async {
      await pumpPage(t, const TodayPage(), health: FakeHealth(HealthStatus.unsupported));
      expect(find.text('Recovery'), findsNothing);
    });

    testWidgets('not connected → explains, then asks permission after confirmation', (t) async {
      final h = FakeHealth(HealthStatus.notConnected);
      await pumpPage(t, const TodayPage(), health: h);
      await t.scrollUntilVisible(find.text('Recovery'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Connect Health Connect to see sleep'), findsOneWidget);
      await t.tap(find.text('Recovery'));
      await t.pumpAndSettle();
      expect(find.textContaining('READ your sleep and resting heart rate'), findsOneWidget);
      expect(find.textContaining('never writes'), findsOneWidget);
      expect(h.connects, 0); // nothing requested before the user confirms
      await t.tap(find.text('CONTINUE'));
      await t.pumpAndSettle();
      expect(h.connects, 1);
      // Real values, no invented score.
      expect(find.text('Sleep 7h 40m · Resting HR 54 bpm'), findsOneWidget);
      expect(find.textContaining('Recovery Score'), findsNothing); // no invented score
    });

    testWidgets('cancelling the explanation never requests permission', (t) async {
      final h = FakeHealth(HealthStatus.notConnected);
      await pumpPage(t, const TodayPage(), health: h);
      await t.scrollUntilVisible(find.text('Recovery'), 300, scrollable: find.byType(Scrollable).first);
      await t.tap(find.text('Recovery'));
      await t.pumpAndSettle();
      await t.tap(find.text('CANCEL'));
      await t.pumpAndSettle();
      expect(h.connects, 0);
    });

    testWidgets('denied permission shows a calm message and stays disconnected', (t) async {
      final h = FakeHealth(HealthStatus.notConnected)..grant = false;
      await pumpPage(t, const TodayPage(), health: h);
      await t.scrollUntilVisible(find.text('Recovery'), 300, scrollable: find.byType(Scrollable).first);
      await t.tap(find.text('Recovery'));
      await t.pumpAndSettle();
      await t.tap(find.text('CONTINUE'));
      await t.pumpAndSettle();
      // Copy carries the concrete next step, not just the refusal.
      expect(find.textContaining('Access was not granted'), findsOneWidget);
      expect(find.textContaining('Health Connect › App permissions'), findsOneWidget);
      expect(h.status, HealthStatus.notConnected);
    });

    testWidgets('connected with data shows sleep, resting HR and the delta vs 7-day average', (t) async {
      final h = FakeHealth(HealthStatus.connected, HealthSnapshot(fetchedAt: DateTime.now(), sleepMinutes: 400, restingHr: 52, restingHrAvg7d: 56));
      await pumpPage(t, const TodayPage(), health: h);
      await t.scrollUntilVisible(find.text('Recovery'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Sleep 6h 40m · Resting HR 52 bpm'), findsOneWidget);
      expect(find.text('vs 7-day average 56 bpm'), findsOneWidget);
      expect(find.text('4 bpm'), findsOneWidget);
    });

    testWidgets('connected but empty → honest empty state', (t) async {
      final h = FakeHealth(HealthStatus.connected, HealthSnapshot(fetchedAt: DateTime.now()));
      await pumpPage(t, const TodayPage(), health: h);
      await t.scrollUntilVisible(find.text('Recovery'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('no sleep or heart-rate data recorded yet'), findsOneWidget);
    });

    testWidgets('not installed offers install', (t) async {
      final h = FakeHealth(HealthStatus.notInstalled);
      await pumpPage(t, const TodayPage(), health: h);
      await t.scrollUntilVisible(find.text('Recovery'), 300, scrollable: find.byType(Scrollable).first);
      await t.tap(find.text('Recovery'));
      await t.pump();
      expect(h.installs, 1);
    });
  });

  group('Profile Health Connect row', () {
    Future<void> showRow(WidgetTester t) async {
      await t.scrollUntilVisible(find.text('Health Connect'), 300, scrollable: find.byType(Scrollable).first);
    }

    testWidgets('unsupported platform: no action, honest text', (t) async {
      await pumpPage(t, const ProfilePage(), health: FakeHealth(HealthStatus.unsupported));
      await showRow(t);
      expect(find.text('Not available on this device'), findsOneWidget);
    });

    testWidgets('connect then disconnect with confirmations', (t) async {
      final h = FakeHealth(HealthStatus.notConnected);
      await pumpPage(t, const ProfilePage(), health: h);
      await showRow(t);
      await t.tap(find.widgetWithText(SxButton, 'CONNECT'));
      await t.pumpAndSettle();
      await t.tap(find.text('CONTINUE'));
      await t.pumpAndSettle();
      expect(h.status, HealthStatus.connected);
      await showRow(t);
      await t.tap(find.widgetWithText(SxButton, 'DISCONNECT'));
      await t.pumpAndSettle();
      expect(find.textContaining('restarted'), findsOneWidget);
      await t.tap(find.text('DISCONNECT').last);
      await t.pumpAndSettle();
      expect(h.disconnects, 1);
      expect(h.status, HealthStatus.notConnected);
    });
  });

  group('iOS wording (Apple Health)', () {
    testWidgets('explains Apple Health, asks only after confirmation, shows Settings path when empty', (t) async {
      final h = FakeHealth(HealthStatus.notConnected, null, HealthProvider.appleHealth);
      await pumpPage(t, const TodayPage(), health: h);
      await t.scrollUntilVisible(find.text('Recovery'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Connect Apple Health to see sleep'), findsOneWidget);
      expect(find.textContaining('Health Connect'), findsNothing);
      await t.tap(find.text('Recovery'));
      await t.pumpAndSettle();
      expect(find.text('CONNECT APPLE HEALTH?'), findsOneWidget);
      expect(find.textContaining('iOS will ask which data to share'), findsOneWidget);
      expect(h.connects, 0);
    });

    testWidgets('connected but empty tells the user where to enable access', (t) async {
      final h = FakeHealth(HealthStatus.connected, HealthSnapshot(fetchedAt: DateTime.now()), HealthProvider.appleHealth);
      await pumpPage(t, const TodayPage(), health: h);
      await t.scrollUntilVisible(find.text('Recovery'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Settings › Health › Data Access & Devices › StationX'), findsOneWidget);
    });

    testWidgets('Profile row says Apple Health and the disconnect dialog points to Settings', (t) async {
      final h = FakeHealth(HealthStatus.connected, HealthSnapshot(fetchedAt: DateTime.now(), restingHr: 55), HealthProvider.appleHealth);
      await pumpPage(t, const ProfilePage(), health: h);
      await t.scrollUntilVisible(find.text('Apple Health'), 300, scrollable: find.byType(Scrollable).first);
      await t.tap(find.widgetWithText(SxButton, 'DISCONNECT'));
      await t.pumpAndSettle();
      expect(find.textContaining('To fully remove access, open Settings › Health'), findsOneWidget);
    });
  });

  testWidgets('small screen: connected card does not overflow at 320x568 @1.3x', (t) async {
    final h = FakeHealth(HealthStatus.connected, HealthSnapshot(fetchedAt: DateTime.now(), sleepMinutes: 455, restingHr: 61, restingHrAvg7d: 58));
    await pumpPage(t, const TodayPage(), health: h, size: const Size(320, 568), textScale: 1.3);
    await t.scrollUntilVisible(find.text('Recovery'), 300, scrollable: find.byType(Scrollable).first);
    expect(t.takeException(), isNull);
  });
}
