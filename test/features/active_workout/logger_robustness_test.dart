import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/data_store.dart';
import 'package:stationx/data/device/device_services.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/active_workout/active_workout_controller.dart';
import 'package:stationx/features/active_workout/active_workout_page.dart';
import 'package:stationx/features/active_workout/workout_complete_page.dart';

import '../../helpers/pump.dart';
import 'active_workout_test.dart' show pumpPushed, tapDone;

class FakeFeedback implements DeviceFeedback {
  int setDones = 0;
  int restEnds = 0;
  @override
  void setDone() => setDones++;
  @override
  void restEnded() => restEnds++;
}

class FakeKeepAwake implements KeepAwake {
  final log = <String>[];
  @override
  Future<void> enable() async => log.add('on');
  @override
  Future<void> disable() async => log.add('off');
}

class FlakySessions extends MemorySessionRepository {
  FlakySessions(super.seed);
  bool failAdd = true;
  @override
  Future<void> add(WorkoutSession s) async {
    if (failAdd) throw StateError('disk full');
    return super.add(s);
  }
}

class FlakyWorkouts extends MemoryWorkoutRepository {
  FlakyWorkouts(super.w, super.r);
  bool failAdvance = false;
  int advances = 0;
  @override
  Future<void> setRotation(Rotation r) async {
    if (failAdvance) throw StateError('disk full');
    advances++;
    return super.setRotation(r);
  }
}

/// Store whose session/workout repositories can be made to fail.
class FlakyStore implements DataStore {
  FlakyStore(SeedData seed)
      : inner = MemoryStore(seed),
        sessions = FlakySessions(seed.sessions),
        workouts = FlakyWorkouts(seed.workouts, seed.rotation);
  final MemoryStore inner;
  @override
  final FlakySessions sessions;
  @override
  final FlakyWorkouts workouts;
  @override
  ExerciseRepository get exercises => inner.exercises;
  @override
  CardioRepository get cardio => inner.cardio;
  @override
  ProfileRepository get profile => inner.profile;
  @override
  WorkoutDraftStore get workoutDraft => inner.workoutDraft;
  @override
  bool get signedIn => inner.signedIn;
  @override
  Future<void> setSignedIn(bool v) => inner.setSignedIn(v);
  @override
  Future<void> replaceAll(SeedData seed, UserProfile profile) => inner.replaceAll(seed, profile);
  @override
  Future<void> close() => inner.close();
}

ActiveWorkoutController makeCtl(AppController app,
    {String id = 'w2', FakeFeedback? fb, WorkoutDraft? restore, bool store = true}) {
  return ActiveWorkoutController(
    workout: app.workouts.byId(id)!,
    catalog: app.exercises.all,
    sessions: app.sessions,
    profile: app.profile.profile,
    feedback: fb ?? FakeFeedback(),
    draftStore: store ? app.workoutDraft : null,
    restoreFrom: restore,
  );
}

void main() {
  setUpAll(loadAppFonts);

  group('controller rules', () {
    late AppController app;
    setUp(() => app = AppController()..startDemo());

    test('prefills LAST weights, never a silently increased one; suggestion is explicit', () {
      final c = makeCtl(app);
      for (final d in c.drafts) {
        for (var i = 0; i < d.sets.length; i++) {
          final prev = d.prevSets.isEmpty ? null : d.prevSets[i < d.prevSets.length ? i : d.prevSets.length - 1];
          if (prev != null) expect(d.sets[i].weightKg, prev.weightKg);
        }
      }
      final withRec = c.drafts.where((d) => d.recommendation != null);
      for (final d in withRec) {
        final before = d.sets.first.weightKg;
        c.useSuggestion(d);
        expect(d.sets.every((s) => s.weightKg == d.recommendation!.weightKg), isTrue);
        expect(d.suggestionUsed, isTrue);
        expect(before, isNot(isNaN));
      }
      c.dispose();
    });

    test('edits copy forward to later undone sets still holding the old value', () {
      final c = makeCtl(app);
      final d = c.drafts.first;
      d.sets[0].weightKg = 50;
      d.sets[1].weightKg = 50;
      d.sets[2].weightKg = 45; // manually different: must not follow
      c.setWeight(d, 0, 60);
      expect(d.sets.map((s) => s.weightKg), [60, 60, 45]);
      d.sets[1].done = true;
      c.setReps(d, 0, 7);
      expect(d.sets[1].reps, isNot(7)); // done sets never change
      c.dispose();
    });

    test('same as last set copies weight and reps', () {
      final c = makeCtl(app);
      final d = c.drafts.first;
      d.sets[0]
        ..weightKg = 70
        ..reps = 6;
      c.sameAsLast(d, 1);
      expect(d.sets[1].weightKg, 70);
      expect(d.sets[1].reps, 6);
      c.dispose();
    });

    test('steppers use the unit increment (2.5 kg / 5 lb) and reps +-1', () {
      final c = makeCtl(app);
      final d = c.drafts.first;
      d.sets[0]
        ..weightKg = 50
        ..reps = 8;
      c.stepWeight(d, 0, 1, WeightUnit.kg);
      expect(d.sets[0].weightKg, 52.5);
      c.stepWeight(d, 0, -1, WeightUnit.kg);
      c.stepReps(d, 0, 1);
      expect(d.sets[0].reps, 9);
      d.sets[0].weightKg = 100 / 2.2046226218;
      c.stepWeight(d, 0, 1, WeightUnit.lb);
      expect(d.sets[0].weightKg * 2.2046226218, closeTo(105, 0.01));
      c.dispose();
    });

    test('0 kg on weighted equipment is not logged; bodyweight is', () {
      final c = makeCtl(app);
      final d = c.drafts.first;
      d.sets[0].weightKg = 0;
      expect(c.needsWeight(d, 0), isTrue);
      expect(c.toggleSet(d, 0), isFalse);
      expect(d.sets[0].done, isFalse);
      d.exercise = Exercise(id: 'bw', name: 'Pull-Up', primaryMuscle: MuscleGroup.back, equipment: Equipment.bodyweight);
      expect(c.toggleSet(d, 0), isTrue);
      expect(d.sets[0].done, isTrue);
      c.dispose();
    });

    test('haptic on set done, double haptic when the rest ends, rest continues between exercises', () async {
      final fb = FakeFeedback();
      final c = makeCtl(app, fb: fb);
      final d = c.drafts.first;
      for (var i = 0; i < d.sets.length; i++) {
        c.toggleSet(d, i);
      }
      expect(fb.setDones, d.sets.length);
      expect(c.rest.value, isNotNull); // exercise done, workout is not
      c.skipRest();
      expect(c.rest.value, isNull);
      c.dispose();
    });
  });

  testWidgets('rest end fires the haptic once; skip cancels it', (t) async {
    final fb = FakeFeedback();
    final app = AppController(feedback: fb);
    await app.startDemo();
    await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), controller: app);
    await tapDone(t, 1);
    expect(fb.setDones, 1);
    expect(fb.restEnds, 0);
    await t.pump(const Duration(seconds: 91));
    expect(fb.restEnds, 1);
    await tapDone(t, 2);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('SKIP'));
    await t.pump(const Duration(seconds: 120));
    expect(fb.restEnds, 1);
  });

  group('draft persistence', () {
    test('debounced save on every mutation, cleared on discard', () async {
      final app = AppController()..startDemo();
      final c = makeCtl(app);
      c.toggleSet(c.drafts[0], 0);
      expect(app.workoutDraft.current, isNull); // debounced
      await Future<void>.delayed(const Duration(milliseconds: 650));
      final d = app.workoutDraft.current!;
      expect(d.workoutId, 'w2');
      expect(d.doneSets, 1);
      c.setWeight(c.drafts[0], 1, 77.5);
      await c.flushDraft();
      expect(app.workoutDraft.current!.exercises[0].sets[1].weightKg, 77.5);
      await c.discardDraft();
      expect(app.workoutDraft.current, isNull);
      c.dispose();
      expect(app.workoutDraft.current, isNull); // a discarded draft never comes back on dispose
    });

    test('restart: a new controller restores sets, current index, start time', () async {
      final app = AppController()..startDemo();
      final c = makeCtl(app);
      for (var i = 0; i < c.drafts[0].sets.length; i++) {
        c.toggleSet(c.drafts[0], i);
      }
      c.setWeight(c.drafts[1], 0, 33);
      await c.flushDraft();
      final started = c.startedAt;
      c.dispose();

      final saved = app.workoutDraft.current!;
      final r = makeCtl(app, restore: saved);
      expect(r.startedAt, started);
      expect(r.drafts[0].complete, isTrue);
      expect(r.drafts[1].sets[0].weightKg, 33);
      expect(r.doneSets, c.doneSets);
      expect(r.currentIndex, 1);
      expect(r.drafts[1].expanded, isTrue);
      r.dispose();
    });

    test('nothing logged is not worth resuming (draft cleared)', () async {
      final app = AppController()..startDemo();
      final c = makeCtl(app);
      c.toggleSet(c.drafts[0], 0);
      await c.flushDraft();
      expect(app.workoutDraft.current, isNotNull);
      c.toggleSet(c.drafts[0], 0); // undo
      await c.flushDraft();
      expect(app.workoutDraft.current, isNull);
      c.dispose();
    });

    test('a pending change is flushed when the controller is disposed', () async {
      final app = AppController()..startDemo();
      final c = makeCtl(app);
      c.toggleSet(c.drafts[0], 0);
      c.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(app.workoutDraft.current?.doneSets, 1);
    });

    test('draft of a deleted workout is rebuilt from its own snapshot', () async {
      final app = AppController()..startDemo();
      final c = makeCtl(app);
      c.toggleSet(c.drafts[0], 0);
      await c.flushDraft();
      c.dispose();
      final draft = app.workoutDraft.current!;
      await app.workouts.deleteWorkout('w2');
      expect(app.workouts.byId('w2'), isNull);
      final w = workoutFromDraft(draft);
      final r = ActiveWorkoutController(
        workout: w,
        catalog: app.exercises.all,
        sessions: app.sessions,
        profile: app.profile.profile,
        restoreFrom: draft,
      );
      expect(r.doneSets, 1);
      expect(r.workout.name, draft.workoutName);
      r.dispose();
    });

    test('wipeAllData and loadDemoData clear the draft', () async {
      final app = AppController()..startDemo();
      final c = makeCtl(app);
      c.toggleSet(c.drafts[0], 0);
      await c.flushDraft();
      c.dispose();
      expect(app.workoutDraft.current, isNotNull);
      await app.wipeAllData();
      expect(app.workoutDraft.current, isNull);

      final c2 = makeCtl(app);
      c2.toggleSet(c2.drafts[0], 0);
      await c2.flushDraft();
      c2.dispose();
      expect(await app.loadDemoData(replaceExisting: true), isTrue);
      expect(app.workoutDraft.current, isNull);
    });
  });

  testWidgets('suggestion chip: last weights are prefilled, the increase applies only when tapped', (t) async {
    final app = AppController();
    await app.startDemo();
    final re = app.workouts.byId('w2')!.exercises.first;
    final now = DateTime.now();
    for (var k = 1; k <= 2; k++) {
      await app.sessions.add(WorkoutSession(
        id: 'hist$k',
        workoutId: 'w2',
        name: 'Back',
        workoutDate: now.subtract(Duration(days: k)),
        exercises: [
          ExerciseLog(exerciseId: re.exerciseId, sets: [for (var i = 0; i < re.sets; i++) SetLog(weightKg: 100, reps: re.repMax)]),
        ],
      ));
    }
    final c = makeCtl(app);
    final d = c.drafts.first;
    expect(d.recommendation!.isIncrease, isTrue);
    expect(d.sets.every((s) => s.weightKg == 100), isTrue); // not 102.5/105 silently
    c.dispose();

    await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), controller: app);
    expect(find.text('SMART OVERLOAD'), findsNothing);
    expect(find.text('SUGGESTION'), findsOneWidget);
    final chip = find.textContaining('Use 10');
    expect(chip, findsOneWidget);
    await t.tap(chip);
    await t.pump();
    expect(find.text('SUGGESTION'), findsNothing);
  });

  group('page', () {
    testWidgets('keeps the screen awake while open and releases it on leave', (t) async {
      final ka = FakeKeepAwake();
      final app = AppController(keepAwake: ka);
      await app.startDemo();
      await pumpPage(t, Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const ActiveWorkoutPage(workoutId: 'w2'))), child: const Text('go')))), controller: app);
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      expect(ka.log, ['on']);
      await t.tap(find.byIcon(Icons.arrow_back));
      await t.pumpAndSettle();
      expect(ka.log, ['on', 'off']);
    });

    testWidgets('back with nothing logged leaves silently (no dialog)', (t) async {
      await pumpPushed(t, const ActiveWorkoutPage(workoutId: 'w2'));
      await t.tap(find.byIcon(Icons.arrow_back));
      await t.pumpAndSettle();
      expect(find.text('DISCARD WORKOUT?'), findsNothing);
      expect(find.byType(ActiveWorkoutPage), findsNothing);
    });

    testWidgets('restart mid-workout: reopening the logger restores the logged sets', (t) async {
      final app = AppController();
      await app.startDemo();
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), controller: app);
      await tapDone(t, 1);
      await t.pump(const Duration(milliseconds: 700)); // debounce
      expect(app.workoutDraft.current?.doneSets, 1);
      // "Kill" the app: fresh widget tree, same persisted store.
      await t.pumpWidget(const SizedBox());
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), controller: app);
      expect(find.text('17 OF 18 SETS REMAINING'), findsOneWidget);
    });

    testWidgets('starting another workout with an unfinished draft asks before discarding it', (t) async {
      final app = AppController();
      await app.startDemo();
      final c = makeCtl(app);
      c.toggleSet(c.drafts[0], 0);
      await c.flushDraft();
      c.dispose();
      await pumpPushed(t, const ActiveWorkoutPage(workoutId: 'w3'), controller: app);
      expect(find.text('UNFINISHED WORKOUT'), findsOneWidget);
      await t.tap(find.text('RESUME IT'));
      await t.pumpAndSettle();
      // The unfinished workout is now open, with its set restored.
      expect(find.text('17 OF 18 SETS REMAINING'), findsOneWidget);
      expect(app.workoutDraft.current?.workoutId, 'w2');
    });

    testWidgets('finish failure: friendly text, sets kept, button recovers, retry saves exactly once', (t) async {
      final store = FlakyStore(SeedData.demo());
      final app = AppController(store: store);
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), controller: app);
      final n = store.sessions.sessions.length;
      final idx = app.workouts.rotation.currentIndex;
      await tapDone(t, 1);
      await t.tap(find.text('FINISH WORKOUT'));
      await t.pumpAndSettle();
      await t.tap(find.text('FINISH'));
      await t.pumpAndSettle();
      expect(find.textContaining("Couldn't save. Your sets are still here. Try again."), findsOneWidget);
      expect(find.byType(ActiveWorkoutPage), findsOneWidget);
      expect(store.sessions.sessions.length, n);
      expect(app.workouts.rotation.currentIndex, idx);
      expect(find.text('17 OF 18 SETS REMAINING'), findsOneWidget);

      // Retry: the session saves, the rotation advances once.
      await t.pump(const Duration(seconds: 6));
      await t.pumpAndSettle();
      store.sessions.failAdd = false;
      await t.tap(find.text('FINISH WORKOUT'));
      await t.pumpAndSettle();
      await t.tap(find.text('FINISH'));
      await t.pumpAndSettle();
      expect(store.sessions.sessions.length, n + 1);
      expect(store.workouts.advances, 1);
      expect(find.byType(WorkoutCompletePage), findsOneWidget);
      expect(app.workoutDraft.current, isNull);
    });

    testWidgets('rotation failure after the session saved: retry advances once and never duplicates', (t) async {
      final store = FlakyStore(SeedData.demo());
      store.sessions.failAdd = false;
      store.workouts.failAdvance = true;
      final app = AppController(store: store);
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), controller: app);
      final n = store.sessions.sessions.length;
      await tapDone(t, 1);
      await t.tap(find.text('FINISH WORKOUT'));
      await t.pumpAndSettle();
      await t.tap(find.text('FINISH'));
      await t.pumpAndSettle();
      expect(find.textContaining("Couldn't save"), findsOneWidget);
      await t.pump(const Duration(seconds: 6)); // snackbar leaves the footer
      await t.pumpAndSettle();
      store.workouts.failAdvance = false;
      await t.tap(find.text('FINISH WORKOUT'));
      await t.pumpAndSettle();
      await t.tap(find.text('FINISH'));
      await t.pumpAndSettle();
      expect(store.sessions.sessions.length, n + 1);
      expect(store.workouts.advances, 1);
    });

    testWidgets('inline +/- steppers change reps and weight of the active set', (t) async {
      final h = t.ensureSemantics();
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'));
      String reps() => t.getSemantics(find.bySemanticsLabel(RegExp(r'^Reps')).first).label;
      String weight() => t.getSemantics(find.bySemanticsLabel(RegExp(r'^Weight')).first).label;
      await t.ensureVisible(find.bySemanticsLabel('Increase reps'));
      await t.pump();
      final r0 = reps(), w0 = weight();
      await t.tap(find.bySemanticsLabel('Increase reps'));
      await t.pump();
      expect(reps(), isNot(r0));
      await t.tap(find.bySemanticsLabel('Increase weight'));
      await t.pump();
      expect(weight(), isNot(w0));
      await t.tap(find.bySemanticsLabel('Decrease weight'));
      await t.pump();
      expect(weight(), w0);
      h.dispose();
    });

    testWidgets('removing a logged set offers Undo', (t) async {
      final h = t.ensureSemantics();
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'));
      await tapDone(t, 1);
      await t.drag(find.text('01').first, const Offset(-500, 0));
      await t.pumpAndSettle();
      expect(find.text('17 OF 17 SETS REMAINING'), findsOneWidget); // the logged set is gone
      expect(find.text('Undo'), findsOneWidget);
      await t.tap(find.text('Undo'));
      await t.pumpAndSettle();
      expect(find.text('17 OF 18 SETS REMAINING'), findsOneWidget);
      h.dispose();
    });

    testWidgets('320dp set row keeps KG, REPS and DONE at least 48dp', (t) async {
      final h = t.ensureSemantics();
      await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), size: const Size(320, 700));
      await t.ensureVisible(find.bySemanticsLabel(RegExp('^Weight')).first);
      await t.pump();
      for (final label in [RegExp('^Weight'), RegExp('^Reps'), RegExp(r'^Set 1 done')]) {
        final r = t.getRect(find.bySemanticsLabel(label).first);
        expect(r.width, greaterThanOrEqualTo(47.9), reason: '$label');
        expect(r.height, greaterThanOrEqualTo(47.9), reason: '$label');
      }
      h.dispose();
    });
  });
}
