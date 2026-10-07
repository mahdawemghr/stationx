import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/features/active_workout/active_workout_page.dart';
import 'package:stationx/features/cardio/active_cardio_page.dart';
import 'package:stationx/features/cardio/cardio_home_view.dart';
import 'package:stationx/domain/domain.dart';
import '../helpers/pump.dart';

Finder withAction(String label) => find.byWidgetPredicate(
    (w) => w is Semantics && (w.properties.customSemanticsActions?.keys.any((a) => a.label == label) ?? false));

/// Gesture-only features must have a screen-reader equivalent.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('swipe-to-remove a set is also a named "Remove set" action', (t) async {
    final h = t.ensureSemantics();
    await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'));
    expect(withAction('Remove set'), findsNWidgets(3)); // one per set row of the open exercise
    h.dispose();
  });

  testWidgets('long-press delete of a cardio session is also a named "Delete session" action, and it works', (t) async {
    final h = t.ensureSemantics();
    final app = await pumpPage(t, const Scaffold(body: CardioHomeView()));
    final before = app.cardio.sessions.length;
    final finder = withAction('Delete session');
    expect(finder, findsWidgets);
    final action = (t.widget<Semantics>(finder.first).properties.customSemanticsActions!).entries.first.value;
    action(); // what TalkBack's actions menu invokes
    await t.pumpAndSettle();
    await t.tap(find.text('DELETE SESSION'));
    await t.pumpAndSettle();
    expect(app.cardio.sessions.length, before - 1);
    h.dispose();
  });

  testWidgets('hold-to-unlock: with a screen reader a single activation unlocks; without one it requires a hold', (t) async {
    // Without a screen reader: tap locks, a quick tap does NOT unlock.
    await pumpPage(t, const ActiveCardioPage(kind: CardioKind.treadmill));
    await t.pump(const Duration(milliseconds: 200));
    await t.tap(find.byKey(const Key('cardio-lock')));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('LOCKED • HOLD TO UNLOCK'), findsOneWidget);
    await t.tap(find.byKey(const Key('cardio-lock')));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('LOCKED • HOLD TO UNLOCK'), findsOneWidget);
  });

  testWidgets('hold-to-unlock with a screen reader: one tap unlocks', (t) async {
    await pumpPage(t, const ActiveCardioPage(kind: CardioKind.treadmill), screenReader: true);
    await t.pump(const Duration(milliseconds: 200));
    await t.tap(find.byKey(const Key('cardio-lock')));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('LOCKED • HOLD TO UNLOCK'), findsOneWidget);
    await t.tap(find.byKey(const Key('cardio-lock')));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('TAP TO LOCK SCREEN CONTROLS'), findsOneWidget);
  });
}
