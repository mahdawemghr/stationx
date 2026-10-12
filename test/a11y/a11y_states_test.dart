import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/features/active_workout/active_workout_page.dart';
import 'package:stationx/features/onboarding/schedule_setup_flow.dart';
import 'package:stationx/features/shell/main_shell.dart';
import '../helpers/pump.dart';

/// Interactive states the static sweep cannot reach: keypad,
/// bottom sheets and dialogs — touch targets, labels, overflow at 1.3× and 2.0×.
/// Case-insensitive text finder (buttons upper-case their labels).
Finder ci(String s) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').toLowerCase() == s.toLowerCase(),
);

Future<List<String>> problems(WidgetTester t) async {
  final out = <String>[];
  for (final g in <String, AccessibilityGuideline>{
    'tap target 48dp': androidTapTargetGuideline,
    'labeled tap target': labeledTapTargetGuideline,
  }.entries) {
    final r = await g.value.evaluate(t);
    if (!r.passed) out.add('[${g.key}] ${r.reason}');
  }
  final e = t.takeException();
  if (e != null) {
    out.add('exception: ${e is FlutterError ? e.toStringDeep() : e}');
  }
  return out;
}

void main() {
  setUpAll(loadAppFonts);

  for (final scale in [1.0, 1.3, 2.0]) {
    group('scale $scale', () {
      final size = scale == 2.0 ? const Size(360, 640) : const Size(360, 720);

      testWidgets('active workout: a logged set', (t) async {
        final h = t.ensureSemantics();
        await pumpPage(
          t,
          const ActiveWorkoutPage(workoutId: 'w2'),
          size: size,
          textScale: scale,
        );
        if (scale >= 1.3) {
          // Large text (and the taller set rows) push the first set row below the fold.
          await t.dragUntilVisible(
            find.bySemanticsLabel('Set 1 done'),
            find.byType(Scrollable).first,
            const Offset(0, -80),
          );
          await t.pump(const Duration(milliseconds: 300));
        }
        await t.tap(find.bySemanticsLabel('Set 1 done').first);
        await t.pump(const Duration(milliseconds: 400));
        // Logging a set starts no timer, so there is no rest chip to reach.
        expect(find.text('SKIP'), findsNothing);
        expect(await problems(t), isEmpty);
        h.dispose();
      });

      testWidgets('setup: equipment step and training/rest days step', (
        t,
      ) async {
        final h = t.ensureSemantics();
        await pumpPage(
          t,
          const ScheduleSetupFlow(afterSignup: true),
          demo: false,
          size: size,
          textScale: scale,
        );
        await t.tap(ci('Full Body'));
        await t.pumpAndSettle();
        await t.dragUntilVisible(
          ci('Quick start'),
          find.byType(Scrollable).first,
          const Offset(0, -120),
        );
        await t.ensureVisible(ci('Quick start'));
        await t.pumpAndSettle();
        await t.tap(ci('Quick start'));
        await t.pumpAndSettle();
        expect(
          find.text('Your equipment', skipOffstage: false).evaluate(),
          isNotEmpty,
        );
        expect(await problems(t), isEmpty, reason: 'equipment step');
        await t.tap(ci('Continue').first);
        await t.pumpAndSettle();
        expect(
          find.text('Your experience', skipOffstage: false).evaluate(),
          isNotEmpty,
        );
        expect(await problems(t), isEmpty, reason: 'experience step');
        await t.tap(ci('Continue').first);
        await t.pumpAndSettle();
        expect(find.bySemanticsLabel('Increase training days'), findsOneWidget);
        expect(find.bySemanticsLabel('Increase rest days'), findsOneWidget);
        expect(await problems(t), isEmpty, reason: 'week step');
        h.dispose();
      });

      testWidgets('numeric keypad sheet', (t) async {
        final h = t.ensureSemantics();
        await pumpPage(
          t,
          const ActiveWorkoutPage(workoutId: 'w2'),
          size: size,
          textScale: scale,
        );
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
        await pumpPage(
          t,
          const ActiveWorkoutPage(workoutId: 'w2'),
          size: size,
          textScale: scale,
        );
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
        await pumpPage(
          t,
          const MainShell(initialIndex: 3),
          size: size,
          textScale: scale,
        );
        await t.scrollUntilVisible(
          find.text('Delete all my data'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await t.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await t.pumpAndSettle();
        await t.tap(find.text('Delete all my data'));
        await t.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        expect(await problems(t), isEmpty);
        h.dispose();
      });
    });
  }
}
