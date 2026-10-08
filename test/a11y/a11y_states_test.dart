import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/features/active_workout/active_workout_page.dart';
import 'package:stationx/features/shell/main_shell.dart';
import '../helpers/pump.dart';

/// Interactive states the static sweep cannot reach: running rest timer, keypad,
/// bottom sheets and dialogs — touch targets, labels, overflow at 1.3× and 2.0×.
Future<List<String>> problems(WidgetTester t) async {
  final out = <String>[];
  for (final g in <String, AccessibilityGuideline>{'tap target 48dp': androidTapTargetGuideline, 'labeled tap target': labeledTapTargetGuideline}.entries) {
    final r = await g.value.evaluate(t);
    if (!r.passed) out.add('[${g.key}] ${r.reason}');
  }
  final e = t.takeException();
  if (e != null) out.add('exception: ${e is FlutterError ? e.toStringDeep() : e}');
  return out;
}

void main() {
  setUpAll(loadAppFonts);

  for (final scale in [1.0, 1.3, 2.0]) {
    group('scale $scale', () {
      final size = scale == 2.0 ? const Size(360, 640) : const Size(360, 720);

      testWidgets('active workout: rest timer running', (t) async {
        final h = t.ensureSemantics();
        await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), size: size, textScale: scale);
        if (scale >= 1.3) {
          // Large text (and the taller set rows) push the first set row below the fold.
          await t.dragUntilVisible(find.bySemanticsLabel('Set 1 done'), find.byType(Scrollable).first, const Offset(0, -80));
          await t.pump(const Duration(milliseconds: 300));
        }
        await t.tap(find.bySemanticsLabel('Set 1 done').first);
        await t.pump(const Duration(milliseconds: 400));
        // The rest chip with +30s / SKIP is pinned in the footer: always reachable.
        expect(find.text('SKIP'), findsOneWidget);
        expect(await problems(t), isEmpty);
        h.dispose();
      });

      testWidgets('numeric keypad sheet', (t) async {
        final h = t.ensureSemantics();
        await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), size: size, textScale: scale);
        await t.ensureVisible(find.bySemanticsLabel(RegExp('^Weight')).first);
        await t.pump(const Duration(milliseconds: 300));
        await t.tap(find.bySemanticsLabel(RegExp('^Weight')).first);
        await t.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(await problems(t), isEmpty);
        h.dispose();
      });

      testWidgets('swap exercise sheet', (t) async {
        final h = t.ensureSemantics();
        await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'), size: size, textScale: scale);
        await t.ensureVisible(find.bySemanticsLabel('Swap exercise').first);
        await t.pump(const Duration(milliseconds: 300));
        await t.tap(find.bySemanticsLabel('Swap exercise').first);
        await t.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(await problems(t), isEmpty);
        h.dispose();
      });

      testWidgets('confirm dialog (delete all data)', (t) async {
        final h = t.ensureSemantics();
        await pumpPage(t, const MainShell(initialIndex: 3), size: size, textScale: scale);
        await t.scrollUntilVisible(find.text('Delete all local data'), 300, scrollable: find.byType(Scrollable).first);
        await t.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await t.pumpAndSettle();
        await t.tap(find.text('Delete all local data'));
        await t.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        expect(await problems(t), isEmpty);
        h.dispose();
      });
    });
  }
}
