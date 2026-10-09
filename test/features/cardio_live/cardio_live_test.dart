import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/app/app_scope.dart';
import 'package:stationx/core/theme/sx_colors.dart';
import 'package:stationx/core/theme/sx_theme.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/cardio/active_cardio_clock.dart';
import 'package:stationx/features/cardio/active_cardio_page.dart';
import 'package:stationx/features/cardio/cardio_complete_page.dart';
import 'package:stationx/features/cardio/cardio_delete_dialog.dart';
import 'package:stationx/features/cardio/cardio_home_view.dart';
import 'package:stationx/features/cardio/cardio_prepare_page.dart';
import 'package:stationx/features/cardio/select_activity_page.dart';

import '../../helpers/pump.dart';

Future<void> _unmount(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
}

void main() {
  setUpAll(loadAppFonts);
  tearDown(() => cardioNow = DateTime.now);

  group('home view', () {
    testWidgets('demo data: quick start, week, goal, recent', (t) async {
      await pumpPage(t, const Scaffold(body: CardioHomeView()), size: const Size(390, 2600));
      expect(find.text('Quick Start'), findsOneWidget);
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('WEEKLY AEROBIC GOAL'), findsOneWidget);
      expect(find.text('CUSTOM CARDIO ACTIVITY'), findsOneWidget);
      expect(find.text('Outdoor Run'), findsWidgets);
      await shot(t, 'cardio_home');
    });

    testWidgets('empty account shows the zero state, no fake numbers', (t) async {
      await pumpPage(t, const Scaffold(body: CardioHomeView()), demo: false);
      expect(find.text('NO CARDIO RECORDED YET'), findsOneWidget);
      expect(find.text('THIS WEEK'), findsNothing);
      await shot(t, 'cardio_home_empty');
    });

    testWidgets('long-press a recent card → delete dialog → deletes', (t) async {
      final app = await pumpPage(t, const Scaffold(body: CardioHomeView()));
      final before = app.cardio.sessions.length;
      await t.longPress(find.text('Outdoor Run').last);
      await t.pumpAndSettle();
      expect(find.text('DELETE CARDIO SESSION?'), findsOneWidget);
      await t.tap(find.text('DELETE SESSION'));
      await t.pumpAndSettle();
      expect(app.cardio.sessions.length, before - 1);
    });
  });

  group('select activity', () {
    testWidgets('lists activities and filters by search', (t) async {
      await pumpPage(t, const SelectCardioActivityPage(), size: const Size(390, 2600));
      expect(find.byKey(const Key('recent-strip')), findsOneWidget);
      expect(find.text('Outdoor Run'), findsNWidgets(2)); // recent chip + its section row
      expect(find.text('Treadmill Run'), findsWidgets);
      expect(find.text('Rowing Machine'), findsWidgets);
      await shot(t, 'cardio_select');
      await t.enterText(find.byType(TextField), 'tread');
      await t.pump();
      expect(find.text('Outdoor Run'), findsNothing);
      expect(find.text('Treadmill Run'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'zzzz');
      await t.pump();
      expect(find.text('No activity found'), findsOneWidget);
    });
  });

  group('prepare', () {
    testWidgets('outdoor run: time objective shows target + estimate from history', (t) async {
      await pumpPage(t, const CardioPreparePage(kind: CardioKind.outdoorRun));
      expect(find.text('DISTANCE'), findsNothing);
      await t.tap(find.text('TIME'));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('TARGET DURATION'), findsOneWidget);
      expect(find.textContaining('Estimated'), findsOneWidget);
      await t.tap(find.text('+ 15 min'));
      await t.pump();
      await shot(t, 'cardio_prepare');
    });

    testWidgets('no distance objective for duration-only activities', (t) async {
      await pumpPage(t, const CardioPreparePage(kind: CardioKind.jumpRope));
      expect(find.text('DIST'), findsNothing);
      expect(find.text('TIME'), findsOneWidget);
    });

    testWidgets('empty history hides estimate and hint', (t) async {
      await pumpPage(t, const CardioPreparePage(kind: CardioKind.outdoorRun), demo: false);
      await t.tap(find.text('TIME'));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Estimated'), findsNothing);
      expect(find.textContaining('LAST SESSION'), findsNothing);
    });
  });

  group('active tracker', () {
    testWidgets('fields adapt per kind', (t) async {
      await pumpPage(t, const ActiveCardioPage(kind: CardioKind.treadmill));
      expect(find.text('SPEED'), findsOneWidget);
      expect(find.text('INCLINE'), findsOneWidget);
      expect(find.text('AVG PACE'), findsNothing);
      expect(find.text('RESISTANCE'), findsNothing);
      await _unmount(t);

      await pumpPage(t, const ActiveCardioPage(kind: CardioKind.stationaryBike));
      expect(find.text('RESISTANCE'), findsOneWidget);
      expect(find.text('INCLINE'), findsNothing);
      await _unmount(t);

      await pumpPage(t, const ActiveCardioPage(kind: CardioKind.outdoorRun));
      expect(find.text('AVG PACE'), findsOneWidget);
      expect(find.byKey(const Key('cardio-distance')), findsOneWidget);
      await _unmount(t);

      await pumpPage(t, const ActiveCardioPage(kind: CardioKind.jumpRope));
      expect(find.byKey(const Key('cardio-distance')), findsNothing);
      await _unmount(t);
    });

    testWidgets('start → pause → resume → finish saves the right session', (t) async {
      var now = DateTime(2026, 5, 4, 7, 15);
      cardioNow = () => now;
      final app = await pumpPage(t, const ActiveCardioPage(kind: CardioKind.outdoorRun, targetMinutes: 30));
      final before = app.cardio.sessions.length;
      expect(find.text('GOAL: 30 MIN'), findsOneWidget);

      now = now.add(const Duration(seconds: 65));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('00:01:05'), findsOneWidget);

      // distance via keypad
      await t.tap(find.byKey(const Key('cardio-distance')));
      await t.pumpAndSettle();
      await t.tap(find.text('5').last);
      await t.tap(find.text('.').last);
      await t.tap(find.text('2').last);
      await t.tap(find.text('CONFIRM'));
      await t.pumpAndSettle();
      expect(find.text('5.2'), findsOneWidget);
      await shot(t, 'cardio_active');

      // pause: time stops, paused clock runs
      await t.tap(find.byKey(const Key('cardio-pause')));
      await t.pump();
      expect(find.text('WORKOUT PAUSED'), findsOneWidget);
      now = now.add(const Duration(seconds: 30));
      await t.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('cardio-clock-paused')), findsOneWidget);
      expect(tester0(t, const Key('cardio-clock-paused')), '01:05');
      await shot(t, 'cardio_active_paused');

      await t.tap(find.byKey(const Key('cardio-resume')));
      await t.pump();
      now = now.add(const Duration(seconds: 60));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('00:02:05'), findsOneWidget);

      await t.tap(find.byKey(const Key('cardio-finish')));
      await t.pumpAndSettle();
      expect(app.cardio.sessions.length, before + 1);
      final s = app.cardio.sessions.firstWhere((x) => x.id.startsWith('cardio_'));
      expect(s.kind, CardioKind.outdoorRun);
      expect(s.durationSeconds, 125);
      expect(s.distanceKm, closeTo(5.2, 1e-9));
      expect(s.workoutDate, DateTime(2026, 5, 4, 7, 15)); // start time, not entry time
      expect(s.meta.createdAt.isAfter(DateTime(2026, 5, 4, 7, 15)) || s.meta.createdAt.year >= 2026, isTrue);
      // replaced by the complete page
      expect(find.text('CARDIO COMPLETE'), findsOneWidget);
      await shot(t, 'cardio_complete_after_save');
      await _unmount(t);
    });

    testWidgets('finish with zero time is refused', (t) async {
      final app = await pumpPage(t, const ActiveCardioPage(kind: CardioKind.outdoorRun));
      final before = app.cardio.sessions.length;
      await t.tap(find.byKey(const Key('cardio-finish')));
      await t.pump();
      expect(app.cardio.sessions.length, before);
      expect(find.textContaining('Nothing recorded'), findsOneWidget);
      await _unmount(t);
    });

    testWidgets('back asks before discarding a dirty session', (t) async {
      var now = DateTime(2026, 5, 4, 7, 15);
      cardioNow = () => now;
      final app = await pumpPage(t, const ActiveCardioPage(kind: CardioKind.outdoorRun));
      final before = app.cardio.sessions.length;
      now = now.add(const Duration(seconds: 30));
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.byTooltip('Back'));
      await t.pumpAndSettle();
      expect(find.text('DISCARD SESSION?'), findsOneWidget);
      await t.tap(find.text('KEEP GOING'));
      await t.pumpAndSettle();
      expect(find.text('DISCARD SESSION?'), findsNothing);
      expect(app.cardio.sessions.length, before);
      await _unmount(t);
    });

    testWidgets('lock disables controls', (t) async {
      final app = await pumpPage(t, const ActiveCardioPage(kind: CardioKind.outdoorRun));
      await t.tap(find.byKey(const Key('cardio-lock')));
      await t.pump();
      await t.tap(find.byKey(const Key('cardio-pause')), warnIfMissed: false);
      await t.pump();
      expect(find.text('WORKOUT PAUSED'), findsNothing);
      expect(find.textContaining('HOLD TO UNLOCK'), findsOneWidget);
      expect(app.cardio.sessions, isNotEmpty);
      await _unmount(t);
    });
  });

  group('complete page', () {
    testWidgets('renders a saved session (run)', (t) async {
      final app = await pumpPage(t, const SizedBox());
      final s = app.cardio.sessions.firstWhere((x) => x.kind == CardioKind.outdoorRun);
      await pumpPage(t, CardioCompletePage(sessionId: s.id));
      expect(find.text('CARDIO COMPLETE'), findsOneWidget);
      expect(find.text('TOTAL DISTANCE'), findsOneWidget);
      expect(find.text('AVG PACE'), findsOneWidget);
      expect(find.text('Weekly cardio target'), findsOneWidget);
      await shot(t, 'cardio_complete');
    });

    testWidgets('missing session shows an error state', (t) async {
      await pumpPage(t, const CardioCompletePage(sessionId: 'nope'));
      expect(find.text('Unable to load'), findsOneWidget);
    });

    testWidgets('no goal → no weekly target card; cycling shows avg speed', (t) async {
      final app = AppController()..startDemo();
      for (final g in [...app.cardio.goals]) {
        await app.cardio.deleteGoal(g.id);
      }
      final s = app.cardio.sessions.firstWhere((x) => x.kind == CardioKind.cycling);
      await t.pumpWidget(AppScope(
        controller: app,
        child: MaterialApp(theme: buildStationXTheme(SxColors.obsidian), home: CardioCompletePage(sessionId: s.id)),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Weekly cardio target'), findsNothing);
      expect(find.text('AVG SPEED'), findsOneWidget);
      expect(find.text('AVG PACE'), findsNothing);
    });
  });

  group('delete dialog', () {
    testWidgets('confirm → true, cancel → false', (t) async {
      final app = await pumpPage(t, const SizedBox());
      final s = app.cardio.sessions.first;
      bool? result;
      await pumpPage(t, Builder(builder: (c) => Center(child: TextButton(onPressed: () async => result = await confirmDeleteCardio(c, s), child: const Text('go')))));
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      expect(find.text('DELETE CARDIO SESSION?'), findsOneWidget);
      expect(find.text(s.kind.label), findsOneWidget);
      await t.tap(find.text('CANCEL'));
      await t.pumpAndSettle();
      expect(result, isFalse);
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      await t.tap(find.text('DELETE SESSION'));
      await t.pumpAndSettle();
      expect(result, isTrue);
    });
  });

  group('small screen / large text: no overflow', () {
    const small = Size(320, 568);
    Future<void> check(WidgetTester t, Widget w, {bool demo = true}) async {
      await pumpPage(t, w, size: small, textScale: 1.3, demo: demo);
      expect(t.takeException(), isNull);
      await _unmount(t);
    }

    testWidgets('home', (t) async => check(t, const Scaffold(body: CardioHomeView())));
    testWidgets('home empty', (t) async => check(t, const Scaffold(body: CardioHomeView()), demo: false));
    testWidgets('select', (t) async => check(t, const SelectCardioActivityPage()));
    testWidgets('prepare time', (t) async {
      await pumpPage(t, const CardioPreparePage(kind: CardioKind.treadmill), size: small, textScale: 1.3);
      await t.tap(find.text('DIST'));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull);
      await _unmount(t);
    });
    testWidgets('active running', (t) async => check(t, const ActiveCardioPage(kind: CardioKind.treadmill, targetKm: 5)));
    testWidgets('active paused', (t) async {
      await pumpPage(t, const ActiveCardioPage(kind: CardioKind.outdoorRun), size: small, textScale: 1.3);
      await t.tap(find.byKey(const Key('cardio-pause')));
      await t.pump();
      expect(t.takeException(), isNull);
      await _unmount(t);
    });
    testWidgets('complete', (t) async {
      final app = await pumpPage(t, const SizedBox());
      await pumpPage(t, CardioCompletePage(sessionId: app.cardio.sessions.first.id), size: small, textScale: 1.3);
      expect(t.takeException(), isNull);
    });
  });
}

String? tester0(WidgetTester t, Key k) => (t.widget<Text>(find.byKey(k))).data;
