import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' show SingleChildScrollView, Offset, Scrollable;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/import/gym_tracker_import.dart';
import 'package:stationx/data/import/import_file_source.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/features/profile/profile_page.dart';

import '../../helpers/pump.dart';

class FakeSource implements ImportFileSource {
  FakeSource(this.text, {this.error});
  String? text;
  Object? error;
  int calls = 0;
  @override
  Future<String?> pickJsonText() async {
    calls++;
    if (error != null) throw error!;
    return text;
  }
}

final fixtureText = File('test/fixtures/gym_tracker_export_sample.json').readAsStringSync();

Future<AppController> open(WidgetTester tester, FakeSource src, {double textScale = 1.0, Size size = const Size(390, 3200)}) async {
  final app = AppController(store: MemoryStore(SeedData.fresh()), importSource: src);
  await app.startGuest();
  await pumpPage(tester, const ProfilePage(), controller: app, textScale: textScale, size: size);
  return app;
}

Future<void> startImport(WidgetTester tester, String choice) async {
  await tester.scrollUntilVisible(find.text('IMPORT FROM GYM TRACKER'), 300, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('IMPORT FROM GYM TRACKER'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(choice));
  await tester.pumpAndSettle();
  await tester.tap(find.text(choice));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('choose file → preview with real counts → Import adds the workouts', (tester) async {
    final src = FakeSource(fixtureText);
    final app = await open(tester, src);
    await startImport(tester, 'CHOOSE FILE');
    expect(src.calls, 1);
    expect(find.text('IMPORT 19 WORKOUTS?'), findsOneWidget);
    expect(find.text('374'), findsOneWidget); // sets
    expect(find.textContaining('Chest Press Machine'), findsOneWidget); // a name with no built-in match stays a disclosed custom exercise (Zercher Squat is now a built-in alias)
    expect(app.sessions.sessions, isEmpty); // nothing changed before confirming
    await tester.tap(find.text('IMPORT'));
    await tester.pumpAndSettle();
    expect(app.sessions.sessions.length, 19);
    expect(app.workouts.rotation.currentIndex, 0); // rotation untouched unless ticked
    expect(find.text('Imported 19 workouts from Gym Tracker'), findsOneWidget);
  });

  testWidgets('cancel in the preview changes nothing', (tester) async {
    final app = await open(tester, FakeSource(fixtureText));
    await startImport(tester, 'CHOOSE FILE');
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(app.sessions.sessions, isEmpty);
    expect(app.exercises.all.where((e) => e.isCustom), isEmpty);
  });

  testWidgets('"continue where Gym Tracker left off" moves the rotation only when ticked', (tester) async {
    final app = await open(tester, FakeSource(fixtureText));
    await startImport(tester, 'CHOOSE FILE');
    await tester.tap(find.textContaining('Make "Back + Triceps" my next workout'));
    await tester.pump();
    await tester.tap(find.text('IMPORT'));
    await tester.pumpAndSettle();
    expect(app.workouts.currentWorkout!.name, 'Back + Triceps');
  });

  testWidgets('picker cancelled → no dialog, no change', (tester) async {
    final src = FakeSource(null);
    final app = await open(tester, src);
    await startImport(tester, 'CHOOSE FILE');
    expect(find.textContaining('IMPORT 19'), findsNothing);
    expect(find.text('CANCEL'), findsNothing);
    expect(app.sessions.sessions, isEmpty);
  });

  testWidgets('wrong file → friendly error, nothing imported', (tester) async {
    final app = await open(tester, FakeSource('{"hello": 1}'));
    await startImport(tester, 'CHOOSE FILE');
    expect(find.text('Can\'t import this file'), findsOneWidget);
    expect(find.textContaining('not made by Gym Tracker'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(app.sessions.sessions, isEmpty);
  });

  testWidgets('too large / unreadable file → friendly errors', (tester) async {
    await open(tester, FakeSource(null, error: const ImportException(ImportProblem.tooLarge)));
    await startImport(tester, 'CHOOSE FILE');
    expect(find.textContaining('too large'), findsOneWidget);
  });

  testWidgets('unexpected picker failure is reported, not thrown', (tester) async {
    await open(tester, FakeSource(null, error: const FileSystemException('denied')));
    await startImport(tester, 'CHOOSE FILE');
    expect(find.text('Couldn\'t read the file'), findsOneWidget);
  });

  testWidgets('pasting an oversized clipboard is refused before any parsing', (tester) async {
    final huge = 'x' * (GymTrackerImport.maxBytes + 1);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': huge};
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final app = await open(tester, FakeSource(null));
    await startImport(tester, 'PASTE COPIED DATA');
    expect(find.textContaining('too large'), findsOneWidget);
    expect(find.textContaining('10 MB'), findsOneWidget);
    expect(app.sessions.sessions, isEmpty);
  });

  testWidgets('paste copied data uses the clipboard', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': fixtureText};
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final src = FakeSource(null);
    final app = await open(tester, src);
    await startImport(tester, 'PASTE COPIED DATA');
    expect(src.calls, 0);
    await tester.tap(find.text('IMPORT'));
    await tester.pumpAndSettle();
    expect(app.sessions.sessions.length, 19);
  });

  testWidgets('second import of the same file says there is nothing new', (tester) async {
    final app = await open(tester, FakeSource(fixtureText));
    await startImport(tester, 'CHOOSE FILE');
    await tester.tap(find.text('IMPORT'));
    await tester.pumpAndSettle();
    await startImport(tester, 'CHOOSE FILE');
    expect(find.text('Nothing new to import'), findsOneWidget);
    expect(find.textContaining('already in StationX'), findsOneWidget);
    expect(app.sessions.sessions.length, 19);
  });

  testWidgets('preview dialog does not overflow at 2x text on a small phone', (tester) async {
    await open(tester, FakeSource(fixtureText), textScale: 2.0, size: const Size(360, 640));
    await startImport(tester, 'CHOOSE FILE');
    expect(find.text('IMPORT'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The whole preview can be scrolled to the end.
    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview lists exercises whose muscles need a check', (tester) async {
    final doc = jsonEncode({
      'format': 'gym_tracker_export', 'version': 1,
      'exercises': [{'name': 'Mystery Move Zz'}],
      'sessions': [
        {'id': 1, 'status': 'completed', 'startedAt': '2026-01-01T10:00:00Z', 'exercises': [
          {'exerciseName': 'Mystery Move Zz', 'sets': [{'setNumber': 1, 'weightKg': 10, 'reps': 5}]},
        ]},
      ],
    });
    await open(tester, FakeSource(doc));
    await startImport(tester, 'CHOOSE FILE');
    expect(find.textContaining('Check muscles for: Mystery Move Zz'), findsOneWidget);
    expect(find.textContaining('edit them later'), findsOneWidget);
  });

  testWidgets('no review note when every muscle is known', (tester) async {
    await open(tester, FakeSource(fixtureText));
    await startImport(tester, 'CHOOSE FILE');
    expect(find.textContaining('Check muscles for'), findsNothing);
  });
}
