import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/painting.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import '../helpers/pump.dart';
import '../helpers/screens.dart';

/// Every screen must lay out without overflow at the largest system font scale
/// (Android allows up to ~2.0) on a small phone.
void main() {
  setUpAll(loadAppFonts);
  for (final entry in screens.entries) {
    testWidgets('no overflow at 2.0x text: ${entry.key}', (t) async {
      await pumpPage(t, entry.value(), size: const Size(360, 640), textScale: 2.0);
      await t.pump(const Duration(milliseconds: 400));
      final e = t.takeException();
      expect(e, isNull, reason: e is FlutterError ? e.toStringDeep() : '$e');
    });
  }
}
