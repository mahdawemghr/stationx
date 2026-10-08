import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/cardio/cardio_pace.dart';
import 'package:stationx/features/cardio/cardio_session_details_page.dart';
import 'package:stationx/features/cardio/select_activity_page.dart';

import '../../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);

  group('CardioPace conventions', () {
    test('rowing and ski erg per 500 m, swimming per 100 m, others per km/mi', () {
      // 2000 m in 8:00 -> 240 s/km -> 2:00 per 500 m.
      expect(CardioPace.withUnit(CardioKind.rowing, 240, miles: false), '2:00 /500m');
      expect(CardioPace.withUnit(CardioKind.skiErg, 240, miles: true), '2:00 /500m');
      // 400 m in 8:00 -> 1200 s/km -> 2:00 per 100 m.
      expect(CardioPace.withUnit(CardioKind.swimming, 1200, miles: false), '2:00 /100m');
      expect(CardioPace.withUnit(CardioKind.outdoorRun, 360, miles: false), '6:00 /km');
      expect(CardioPace.unit(CardioKind.outdoorRun, miles: true), '/mi');
      expect(CardioPace.text(CardioKind.outdoorRun, 360, miles: true), '9:39');
      expect(CardioPace.has(CardioKind.hiit), isFalse);
      expect(CardioPace.has(CardioKind.swimming), isTrue);
      expect(CardioPace.convert(CardioKind.rowing, null, miles: false), isNull);
    });
  });

  group('screens', () {
    testWidgets('rowing details show pace per 500 m, no overflow at 320x568', (t) async {
      final app = await pumpPage(t, const SizedBox(), size: const Size(320, 568), demo: false);
      await app.cardio.add(CardioSession(id: 'row1', kind: CardioKind.rowing, workoutDate: DateTime.now(), durationSeconds: 480, distanceKm: 2));
      await pumpPage(t, const CardioSessionDetailsPage(sessionId: 'row1'), size: const Size(320, 568), controller: app);
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('/500M'), findsWidgets);
      expect(find.text('2:00'), findsWidgets);
      expect(t.takeException(), isNull);
    });

    testWidgets('swimming details show pace per 100 m', (t) async {
      final app = await pumpPage(t, const SizedBox(), size: const Size(320, 568), demo: false);
      await app.cardio.add(CardioSession(id: 'sw1', kind: CardioKind.swimming, workoutDate: DateTime.now(), durationSeconds: 480, distanceKm: 0.4));
      await pumpPage(t, const CardioSessionDetailsPage(sessionId: 'sw1'), size: const Size(320, 568), controller: app);
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('/100M'), findsWidgets);
      expect(t.takeException(), isNull);
    });

    testWidgets('activity select list has no overflow with the new kinds at 320x568 @1.3x', (t) async {
      await pumpPage(t, const SelectCardioActivityPage(), size: const Size(320, 568), textScale: 1.3);
      expect(t.takeException(), isNull);
      await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });
}
