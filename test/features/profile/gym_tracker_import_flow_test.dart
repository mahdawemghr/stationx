import 'dart:io';

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

Future<AppController> open(WidgetTester tester, FakeSource src, {double textScale = 1.0}) async {
  final app = AppController(store: MemoryStore(SeedData.fresh()), importSource: src);
  await app.startGuest();
  await pumpPage(tester, const ProfilePage(), controller: app, textScale: textScale, size: const Size(390, 3200));
  return app;
}

Future<void> startImport(WidgetTester tester, String choice) async {
  await tester.tap(find.text('IMPORT FROM GYM TRACKER'));
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
    expect(find.textContaining('Zercher Squat'), findsOneWidget); // new custom exercise is disclosed
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
    await open(tester, FakeSource(fixtureText), textScale: 2.0);
    await startImport(tester, 'CHOOSE FILE');
    expect(find.text('IMPORT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
