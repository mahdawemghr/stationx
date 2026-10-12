import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/active_workout/active_workout_controller.dart';
import 'package:stationx/features/cardio/active_cardio_clock.dart';
import 'package:stationx/features/cardio/active_cardio_page.dart';
import 'package:stationx/features/today/today_page.dart';

import '../../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);
  tearDown(() => cardioNow = DateTime.now);

  test('ActiveCardioDraft survives a JSON round trip', () {
    final d = ActiveCardioDraft(
      kind: CardioKind.treadmill,
      startedAt: DateTime(2026, 10, 12, 8),
      activeMs: 90000,
      pausedMs: 5000,
      pausedSince: DateTime(2026, 10, 12, 8, 2),
      targetMinutes: 30,
      km: 2.5,
      speedKmh: 9,
      inclinePct: 1.5,
      saveId: 'cardio_1',
    );
    final back = MemoryCardioDraftStore.decode(
      (MemoryCardioDraftStore()..save(d)).rawJson,
    );
    // save() is async-free in memory, so the JSON is already stored.
    expect(back, isNotNull);
    expect(back!.kind, CardioKind.treadmill);
    expect(back.activeMs, 90000);
    expect(back.paused, isTrue);
    expect(back.km, 2.5);
    expect(back.saveId, 'cardio_1');
  });

  test('a corrupt cardio draft reads as no draft', () {
    expect(MemoryCardioDraftStore.decode('{nope'), isNull);
  });

  testWidgets('live cardio is saved, restored after a restart,', (t) async {
    var now = DateTime(2026, 10, 12, 8);
    cardioNow = () => now;
    final app = AppController();
    await app.startDemo();
    await pumpPage(
      t,
      const ActiveCardioPage(kind: CardioKind.treadmill),
      controller: app,
    );
    await t.pump();
    expect(app.cardioDraft.current, isNotNull);
    now = now.add(const Duration(minutes: 5));
    // Pause: the persisted state now carries the 5 active minutes.
    await t.tap(
      find.textContaining(RegExp('pause', caseSensitive: false)).first,
    );
    await t.pump();
    final saved = app.cardioDraft.current!;
    expect(saved.paused, isTrue);
    expect(saved.activeSeconds, 300);

    // "Restart": a brand new page over the same store restores the session.
    await t.pumpWidget(const SizedBox());
    await pumpPage(
      t,
      const ActiveCardioPage(kind: CardioKind.treadmill),
      controller: app,
    );
    await t.pump();
    expect(app.cardioDraft.current!.activeSeconds, 300);
    expect(
      find.textContaining(RegExp('paused', caseSensitive: false)),
      findsWidgets,
    );
  });

  testWidgets('Today shows Resume cardio for a surviving session', (t) async {
    final app = AppController();
    await app.startDemo();
    await app.cardioDraft.save(
      ActiveCardioDraft(
        kind: CardioKind.rowing,
        startedAt: DateTime(2026, 10, 12, 8),
        activeMs: 600000,
        pausedMs: 0,
        pausedSince: DateTime(2026, 10, 12, 8, 10),
      ),
    );
    await pumpPage(t, const TodayPage(), controller: app);
    expect(find.text('Resume cardio'), findsOneWidget);
    expect(find.textContaining('paused'), findsWidgets);
  });

  test('cardio finisher state is part of the workout draft', () async {
    final app = AppController();
    await app.startDemo();
    final ctl = ActiveWorkoutController(
      workout: app.workouts.byId('w2')!,
      catalog: app.exercises.all,
      sessions: app.sessions,
      profile: app.profile.profile,
      draftStore: app.workoutDraft,
    );
    ctl.addCardio(CardioKind.cycling);
    ctl.cardio!.update(distanceKm: 4.2);
    ctl.toggleSet(ctl.drafts[0], 0);
    await ctl.flushDraft();
    final saved = app.workoutDraft.current!;
    expect(saved.cardio, isNotNull);
    ctl.dispose();

    final restored = ActiveWorkoutController(
      workout: app.workouts.byId('w2')!,
      catalog: app.exercises.all,
      sessions: app.sessions,
      profile: app.profile.profile,
      draftStore: app.workoutDraft,
      restoreFrom: saved,
    );
    expect(restored.cardio, isNotNull);
    expect(restored.cardio!.kind, CardioKind.cycling);
    expect(restored.cardio!.manualDistanceKm, 4.2);
    restored.dispose();
  });
}
