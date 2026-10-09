import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/cardio/backdate_cardio_page.dart';
import 'package:stationx/features/cardio/cardio_goal_details_page.dart';
import 'package:stationx/features/cardio/cardio_goals_page.dart';
import 'package:stationx/features/cardio/cardio_history_page.dart';
import 'package:stationx/features/cardio/cardio_session_details_page.dart';
import 'package:stationx/features/cardio/cardio_settings_page.dart';
import 'package:stationx/features/cardio/create_custom_activity_page.dart';
import 'package:stationx/features/cardio/edit_cardio_session_page.dart';

import '../../helpers/pump.dart';

/// Launches [page] on top of a root route so pop() is observable.
Widget _onTop(Widget page) => Builder(
      builder: (c) => Scaffold(
        body: Center(
          child: TextButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page)), child: const Text('open')),
        ),
      ),
    );

Future<void> _open(WidgetTester t) async {
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('Backdate', () {
    testWidgets('saves workoutDate = picked past date, createdAt = now, never overwritten', (t) async {
      final app = await pumpPage(t, _onTop(const BackdateCardioPage()), size: const Size(390, 1600), demo: false);
      await _open(t);
      // empty duration → validation error, nothing saved
      await t.tap(find.text('LOG HISTORICAL CARDIO'));
      await t.pump();
      expect(find.text('DURATION REQUIRED'), findsOneWidget);
      expect(app.cardio.sessions, isEmpty);

      final tf = find.byType(TextField);
      await t.enterText(tf.at(1), '32'); // minutes
      await t.enterText(tf.at(2), '18'); // seconds
      await t.enterText(tf.at(3), '5.2'); // distance
      final before = DateTime.now();
      await t.tap(find.text('LOG HISTORICAL CARDIO'));
      await t.pumpAndSettle();
      expect(app.cardio.sessions, hasLength(1));
      final s = app.cardio.sessions.single;
      expect(s.durationSeconds, 32 * 60 + 18);
      expect(s.distanceKm, closeTo(5.2, 1e-9));
      expect(s.workoutDate.isBefore(DateTime(before.year, before.month, before.day)), isTrue, reason: 'default is yesterday');
      expect(s.meta.createdAt.isBefore(before), isFalse);
      expect(s.workoutDate, isNot(equals(s.meta.createdAt)));
      expect(find.text('open'), findsOneWidget, reason: 'page popped after save');
    });

    testWidgets('fields adapt to activity (treadmill → speed/incline, bike → resistance)', (t) async {
      await pumpPage(t, const BackdateCardioPage(kind: CardioKind.treadmill), size: const Size(390, 1600), demo: false);
      expect(find.text('BELT SPEED'), findsOneWidget);
      expect(find.text('INCLINE'), findsOneWidget);
      expect(find.text('RESISTANCE LEVEL'), findsNothing);
      await t.drag(find.text('Outdoor Walk'), const Offset(-500, 0));
      await t.pump();
      await t.tap(find.text('Upright Bike'));
      await t.pump();
      expect(find.text('RESISTANCE LEVEL'), findsOneWidget);
      expect(find.text('BELT SPEED'), findsNothing);
      await t.drag(find.text('Upright Bike'), const Offset(900, 0));
      await t.pump();
      await t.tap(find.text('Outdoor Run'));
      await t.pump();
      expect(find.text('CALCULATED AVG PACE'), findsOneWidget);
    });
  });

  group('Edit', () {
    testWidgets('custom activity session keeps its distance when the activity has no distance field', (t) async {
      final app = await pumpPage(t, _onTop(const EditCardioSessionPage(sessionId: 'cust1')), size: const Size(390, 1600), demo: false);
      await app.cardio.addCustomActivity(CustomCardioActivity(id: 'ca', name: 'Stroll', fields: const [CardioField.duration]));
      await app.cardio.add(CardioSession(
        id: 'cust1',
        kind: CardioKind.custom,
        workoutDate: DateTime.now().subtract(const Duration(days: 1)),
        durationSeconds: 1800,
        distanceKm: 3.5,
        customActivityId: 'ca',
      ));
      await _open(t);
      expect(find.text('DISTANCE COVERED'), findsOneWidget);
      await t.tap(find.text('SAVE CHANGES'));
      await t.pumpAndSettle();
      expect(app.cardio.byId('cust1')!.distanceKm, closeTo(3.5, 1e-9));
    });

    testWidgets('custom session without a distance stays distance-free', (t) async {
      final app = await pumpPage(t, _onTop(const EditCardioSessionPage(sessionId: 'cust2')), size: const Size(390, 1600), demo: false);
      await app.cardio.addCustomActivity(CustomCardioActivity(id: 'cb', name: 'Yoga flow', fields: const [CardioField.duration]));
      await app.cardio.add(CardioSession(
        id: 'cust2',
        kind: CardioKind.custom,
        workoutDate: DateTime.now().subtract(const Duration(days: 1)),
        durationSeconds: 1800,
        customActivityId: 'cb',
      ));
      await _open(t);
      expect(find.text('DISTANCE COVERED'), findsNothing);
    });

    testWidgets('recomputes pace live and saves, keeping createdAt', (t) async {
      final app = await pumpPage(t, _onTop(const EditCardioSessionPage(sessionId: 'seed_c0')), size: const Size(390, 1600));
      final original = app.cardio.byId('seed_c0')!;
      await _open(t);
      expect(find.text('6:13'), findsOneWidget); // 32:18 over 5.2 km
      final tf = find.byType(TextField);
      await t.enterText(tf.at(3), '6'); // distance → 6 km
      await t.pump();
      expect(find.text('5:23'), findsOneWidget); // 1938 s / 6 km
      await t.tap(find.text('SAVE CHANGES'));
      await t.pumpAndSettle();
      final s = app.cardio.byId('seed_c0')!;
      expect(s.distanceKm, 6);
      expect(s.meta.createdAt, original.meta.createdAt);
      expect(s.workoutDate, original.workoutDate);
      expect(s.meta.updatedAt.isBefore(original.meta.updatedAt), isFalse);
    });

    testWidgets('delete asks for confirmation then removes and pops', (t) async {
      final app = await pumpPage(t, _onTop(const EditCardioSessionPage(sessionId: 'seed_c1')), size: const Size(390, 1600));
      await _open(t);
      final n = app.cardio.sessions.length;
      await t.tap(find.byIcon(Icons.delete_outline).last);
      await t.pumpAndSettle();
      await t.tap(find.text('CANCEL'));
      await t.pumpAndSettle();
      expect(app.cardio.sessions.length, n);
      await t.tap(find.byIcon(Icons.delete_outline).last);
      await t.pumpAndSettle();
      await t.tap(find.text('DELETE SESSION'));
      await t.pumpAndSettle();
      expect(app.cardio.sessions.length, n - 1);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('unknown id shows error state', (t) async {
      await pumpPage(t, const EditCardioSessionPage(sessionId: 'nope'));
      expect(find.byType(ErrorState), findsOneWidget);
    });
  });

  group('Details', () {
    testWidgets('shows per-kind fields only', (t) async {
      await pumpPage(t, const CardioSessionDetailsPage(sessionId: 'seed_c2'), size: const Size(390, 1200)); // treadmill
      expect(find.text('INCLINE'), findsOneWidget);
      expect(find.text('AVG PACE'), findsNothing);
      expect(find.textContaining('not available in this build'), findsOneWidget);
    });

    testWidgets('delete from details pops, and unknown id errors', (t) async {
      final app = await pumpPage(t, _onTop(const CardioSessionDetailsPage(sessionId: 'seed_c3')), size: const Size(390, 1200));
      await _open(t);
      await t.tap(find.text('Delete session entry'));
      await t.pumpAndSettle();
      await t.tap(find.text('DELETE SESSION'));
      await t.pumpAndSettle();
      expect(app.cardio.byId('seed_c3'), isNull);
      expect(find.text('open'), findsOneWidget);
      await pumpPage(t, const CardioSessionDetailsPage(sessionId: 'zzz'));
      expect(find.byType(ErrorState), findsOneWidget);
    });
  });

  group('History', () {
    testWidgets('kind filter narrows list; empty account shows empty state with CTA', (t) async {
      final app = await pumpPage(t, const CardioHistoryPage(), size: const Size(390, 2400));
      final latest = app.cardio.sessions.first.workoutDate;
      int inMonth(bool Function(CardioSession) f) =>
          app.cardio.sessions.where((x) => x.workoutDate.year == latest.year && x.workoutDate.month == latest.month && f(x)).length;
      expect(find.text('Details'), findsNWidgets(inMonth((_) => true)));
      await t.tap(find.widgetWithText(SxChip, 'Cycling'));
      await t.pumpAndSettle();
      expect(inMonth((x) => x.kind == CardioKind.cycling), greaterThan(0));
      expect(find.text('Details'), findsNWidgets(inMonth((x) => x.kind == CardioKind.cycling)));
      await pumpPage(t, const CardioHistoryPage(), demo: false);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('START CARDIO'), findsOneWidget);
    });
  });

  group('Goals', () {
    testWidgets('create, edit and delete a goal', (t) async {
      final app = await pumpPage(t, const CardioGoalsPage(), size: const Size(390, 2000));
      final n = app.cardio.goals.length;
      await t.tap(find.text('ADD ANOTHER CARDIO GOAL'));
      await t.pumpAndSettle();
      await t.tap(find.text('CREATE GOAL'));
      await t.pump();
      expect(app.cardio.goals.length, n, reason: 'validation blocks empty goal');
      await t.enterText(find.byType(TextField).at(0), 'Monthly Distance');
      await t.enterText(find.byType(TextField).at(1), '60');
      await t.tap(find.text('Distance').last);
      await t.pump();
      await t.tap(find.text('CREATE GOAL'));
      await t.pumpAndSettle();
      expect(app.cardio.goals.length, n + 1);
      final g = app.cardio.goals.last;
      expect(g.metric, GoalMetric.distanceKm);
      expect(g.target, 60);
      // delete
      await app.cardio.deleteGoal(g.id);
      await t.pumpAndSettle();
      expect(app.cardio.goals.length, n);
    });

    testWidgets('empty state and goal details error state', (t) async {
      await pumpPage(t, const CardioGoalsPage(), demo: false);
      expect(find.byType(EmptyState), findsOneWidget);
      await pumpPage(t, const CardioGoalDetailsPage(goalId: 'missing'));
      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('goal details renders computed progress', (t) async {
      await pumpPage(t, const CardioGoalDetailsPage(goalId: 'g_week'), size: const Size(390, 1600));
      expect(find.text('Weekly Aerobic Duration'), findsOneWidget);
      expect(find.textContaining('Last 6 weeks'), findsOneWidget);
    });
  });

  group('Custom activity', () {
    testWidgets('requires a name, saves supported fields + interval template', (t) async {
      final app = await pumpPage(t, _onTop(const CreateCustomCardioActivityPage()), size: const Size(390, 2000));
      await _open(t);
      await t.tap(find.text('SAVE CUSTOM ACTIVITY'));
      await t.pump();
      expect(app.cardio.customActivities, isEmpty);
      await t.enterText(find.byType(TextField).first, 'Heavy bag');
      await t.tap(find.text('Calories'));
      await t.tap(find.text('Rounds & intervals'));
      await t.pump();
      expect(find.text('19:00'), findsOneWidget); // 5×3:00 + 4×1:00
      await t.tap(find.text('SAVE CUSTOM ACTIVITY'));
      await t.pumpAndSettle();
      final a = app.cardio.customActivities.single;
      expect(a.name, 'Heavy bag');
      expect(a.fields, containsAll([CardioField.duration, CardioField.calories]));
      expect(a.rounds, 5);
    });
  });

  group('Settings', () {
    testWidgets('unit switch persists to profile; sensors shown as unavailable', (t) async {
      final app = await pumpPage(t, const CardioSettingsPage(), size: const Size(390, 1600));
      expect(app.profile.profile.cardioDistanceUnitKm, isTrue);
      await t.tap(find.text('MILES'));
      await t.pumpAndSettle();
      expect(app.profile.profile.cardioDistanceUnitKm, isFalse);
      expect(find.text('NOT AVAILABLE'), findsNWidgets(4));
      expect(find.textContaining('Connected'), findsNothing);
      await t.tap(find.text('JSON'));
      await t.pumpAndSettle();
      expect(find.text('Copy to clipboard'.toUpperCase()), findsOneWidget);
    });
  });

  group('Small screen + large text', () {
    final pages = <String, Widget>{
      'details': const CardioSessionDetailsPage(sessionId: 'seed_c0'),
      'edit': const EditCardioSessionPage(sessionId: 'seed_c0'),
      'backdate': const BackdateCardioPage(),
      'history': const CardioHistoryPage(),
      'goals': const CardioGoalsPage(),
      'goal_details': const CardioGoalDetailsPage(goalId: 'g_week'),
      'custom': const CreateCustomCardioActivityPage(),
      'settings': const CardioSettingsPage(),
    };
    for (final e in pages.entries) {
      testWidgets('${e.key} 320x568 @1.3x has no overflow', (t) async {
        await pumpPage(t, e.value, size: const Size(320, 568), textScale: 1.3);
        expect(t.takeException(), isNull);
        await shot(t, 'd2_small_${e.key}');
      });
    }
  });
}
