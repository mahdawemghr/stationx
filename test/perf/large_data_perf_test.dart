import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/data/isar/isar_store.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/exercises/exercise_history_page.dart';
import 'package:stationx/features/exercises/exercise_library_page.dart';
import 'package:stationx/features/history/calendar_page.dart';
import 'package:stationx/features/progress/personal_records_page.dart';
import 'package:stationx/features/shell/main_shell.dart';
import '../helpers/pump.dart';

/// ~4 years of heavy use: 4 sessions/week strength + 3/week cardio.
SeedData bigSeed({int weeks = 208}) {
  final base = SeedData.fresh();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sessions = <WorkoutSession>[];
  final cardio = <CardioSession>[];
  for (var w = 0; w < weeks; w++) {
    for (var d = 0; d < 4; d++) {
      final workout = base.workouts[(w * 4 + d) % 3];
      final date = today.subtract(Duration(days: w * 7 + d * 2 + 1)).add(const Duration(hours: 18));
      sessions.add(WorkoutSession(
        id: 's_${w}_$d',
        workoutId: workout.id,
        name: workout.name,
        workoutDate: date,
        durationSeconds: 3600,
        exercises: [
          for (final re in workout.exercises)
            ExerciseLog(exerciseId: re.exerciseId, sets: [
              for (var s = 0; s < re.sets; s++) SetLog(weightKg: 20 + (weeks - w) * 0.25 + s * 2.5, reps: re.repMax - s),
            ]),
        ],
      ));
    }
    for (var d = 0; d < 3; d++) {
      cardio.add(CardioSession(
        id: 'c_${w}_$d',
        kind: CardioKind.values[d],
        workoutDate: today.subtract(Duration(days: w * 7 + d * 2 + 2)).add(const Duration(hours: 7)),
        durationSeconds: 1800 + d * 300,
        distanceKm: 5.0 + d,
      ));
    }
  }
  return SeedData(exercises: base.exercises, workouts: base.workouts, rotation: base.rotation, sessions: sessions, cardio: cardio, goals: base.goals);
}

void main() {
  setUpAll(loadAppFonts);
  final seed = bigSeed();

  test('seed is large', () {
    expect(seed.sessions.length, 832);
    expect(seed.cardio.length, 624);
  });

  /// Builds [page] over the big dataset; returns milliseconds for first build + settle.
  Future<int> measure(WidgetTester t, String name, Widget page) async {
    final controller = AppController(store: MemoryStore(seed));
    final sw = Stopwatch()..start();
    await pumpPage(t, page, controller: controller, size: const Size(390, 844));
    sw.stop();
    // ignore: avoid_print
    print('PERF $name: ${sw.elapsedMilliseconds} ms');
    expect(t.takeException(), isNull);
    // Generous regression budget (debug/JIT test VM is several times slower than a release build).
    expect(sw.elapsedMilliseconds, lessThan(2500), reason: '$name first build');
    return sw.elapsedMilliseconds;
  }

  final screens = <String, Widget Function()>{
    'today': () => const MainShell(),
    'workouts hub': () => const MainShell(initialIndex: 1),
    'progress (this week)': () => const MainShell(initialIndex: 2),
    'exercise library': () => const ExerciseLibraryPage(),
    'exercise history': () => const ExerciseHistoryPage(exerciseId: 'lat_pulldown'),
    'personal records': () => const PersonalRecordsPage(),
    'calendar': () => const CalendarPage(),
  };
  for (final e in screens.entries) {
    testWidgets('perf ${e.key}', (t) async {
      await measure(t, e.key, e.value());
    });
  }

  Future<int> timed(WidgetTester t, String name, Future<void> Function() action) async {
    final sw = Stopwatch()..start();
    await action();
    await t.pump();
    sw.stop();
    // ignore: avoid_print
    print('PERF $name: ${sw.elapsedMilliseconds} ms');
    return sw.elapsedMilliseconds;
  }

  testWidgets('perf: today (warm)', (t) async {
    await measure(t, 'today warmup', const MainShell());
    await measure(t, 'today warm', const MainShell());
  });

  testWidgets('perf: library — each search keystroke rebuilds the list', (t) async {
    final controller = AppController(store: MemoryStore(seed));
    await pumpPage(t, const ExerciseLibraryPage(), controller: controller);
    final field = find.byType(TextField).first;
    var worst = 0;
    for (final q in ['l', 'la', 'lat', 'lat ', 'lat p']) {
      final ms = await timed(t, 'library keystroke "$q"', () => t.enterText(field, q));
      if (ms > worst) worst = ms;
    }
    // ignore: avoid_print
    print('PERF library worst keystroke: $worst ms');
  });

  testWidgets('perf: progress — switching period to a long range', (t) async {
    final controller = AppController(store: MemoryStore(seed));
    await pumpPage(t, const MainShell(initialIndex: 2), controller: controller);
    await t.tap(find.byTooltip('Change period'));
    await t.pumpAndSettle();
    await timed(t, 'progress → all time', () async {
      await t.tap(find.text('All time').last);
      await t.pump(const Duration(milliseconds: 50));
    });
  });

  testWidgets('perf: calendar — month change', (t) async {
    final controller = AppController(store: MemoryStore(seed));
    await pumpPage(t, const CalendarPage(), controller: controller);
    await timed(t, 'calendar prev month', () async {
      await t.tap(find.byIcon(Icons.chevron_left).first);
      await t.pump(const Duration(milliseconds: 50));
    });
  });

  test('Isar: write and cold-load ~1,450 sessions (startup cost)', () async {
    await Isar.initializeIsarCore(download: true);
    final dir = Directory.systemTemp.createTempSync('stationx_perf');
    addTearDown(() => dir.deleteSync(recursive: true));
    var store = await IsarStore.open(directory: dir.path, name: 'perf');
    final write = Stopwatch()..start();
    await store.replaceAll(seed, const UserProfile());
    write.stop();
    await store.close();
    final load = Stopwatch()..start();
    store = await IsarStore.open(directory: dir.path, name: 'perf');
    load.stop();
    // ignore: avoid_print
    print('PERF isar bulk write: ${write.elapsedMilliseconds} ms, cold open+load: ${load.elapsedMilliseconds} ms');
    expect(store.sessions.sessions.length, seed.sessions.length);
    expect(store.cardio.sessions.length, seed.cardio.length);
    // One new session (the common write): must stay cheap even with a big history.
    final one = Stopwatch()..start();
    await store.sessions.add(WorkoutSession(id: 'new', workoutId: 'w1', name: 'x', workoutDate: DateTime.now(), exercises: seed.sessions.first.exercises));
    one.stop();
    // ignore: avoid_print
    print('PERF isar single session add: ${one.elapsedMilliseconds} ms');
    expect(load.elapsedMilliseconds, lessThan(5000));
    expect(one.elapsedMilliseconds, lessThan(500));
    await store.close();
  });
}
