import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/bootstrap.dart';
import 'package:stationx/app/startup_error_app.dart';
import 'package:stationx/features/profile/privacy_page.dart';
import 'package:stationx/features/profile/profile_page.dart';
import '../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);

  group('Startup failure recovery', () {
    testWidgets('shows a recovery screen; retry calls back; reset needs confirmation', (t) async {
      var retries = 0, resets = 0;
      await t.pumpWidget(StartupErrorApp(onRetry: () async => retries++, onReset: () async => resets++));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.text("Couldn't open your data"), findsOneWidget);
      expect(find.textContaining('Your data has not been changed'), findsOneWidget);
      await t.tap(find.text('TRY AGAIN'));
      await t.pump();
      expect(retries, 1);
      // Reset is destructive: cancelling must not delete anything.
      await t.tap(find.text('RESET LOCAL DATA'));
      await t.pumpAndSettle();
      await t.tap(find.text('CANCEL'));
      await t.pumpAndSettle();
      expect(resets, 0);
      await t.tap(find.text('RESET LOCAL DATA'));
      await t.pumpAndSettle();
      await t.tap(find.text('DELETE EVERYTHING'));
      await t.pumpAndSettle();
      expect(resets, 1);
    });

    test('resetDatabaseFiles deletes only this app database files', () async {
      final dir = Directory.systemTemp.createTempSync('stationx_reset');
      addTearDown(() => dir.deleteSync(recursive: true));
      for (final n in ['stationx.isar', 'stationx.isar-lck', 'other.isar', 'notes.txt']) {
        File('${dir.path}/$n').writeAsStringSync('x');
      }
      await resetDatabaseFiles(dir.path);
      expect(File('${dir.path}/stationx.isar').existsSync(), isFalse);
      expect(File('${dir.path}/stationx.isar-lck').existsSync(), isFalse);
      expect(File('${dir.path}/other.isar').existsSync(), isTrue);
      expect(File('${dir.path}/notes.txt').existsSync(), isTrue);
      await resetDatabaseFiles(dir.path); // idempotent when files are gone
    });
  });

  group('Privacy', () {
    testWidgets('page states the local-first facts and works on a small screen', (t) async {
      await pumpPage(t, const PrivacyPage(), size: const Size(320, 568), textScale: 1.3);
      expect(find.text('Your data stays on your device'), findsOneWidget);
      expect(find.text('Optional cloud backup', skipOffstage: false), findsOneWidget);
      // The page is a lazy list: scroll to the later sections.
      await t.scrollUntilVisible(find.text('Optional health data'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Optional health data'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('Profile links to the privacy page', (t) async {
      await pumpPage(t, const ProfilePage());
      await t.scrollUntilVisible(find.text('Privacy'), 300, scrollable: find.byType(Scrollable).first);
      await t.drag(find.byType(Scrollable).first, const Offset(0, -250));
      await t.pumpAndSettle();
      await t.tap(find.text('Privacy'));
      await t.pumpAndSettle();
      expect(find.byType(PrivacyPage), findsOneWidget);
    });
  });
}
