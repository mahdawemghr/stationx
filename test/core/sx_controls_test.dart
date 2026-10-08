import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';

import '_kit_harness.dart';

void main() {
  group('SxStepper', () {
    testWidgets('int: bounds, steps, 48dp targets, semantics', (t) async {
      final h = t.ensureSemantics();
      var v = 1;
      late StateSetter set;
      await pumpKit(t, StatefulBuilder(builder: (_, s) {
        set = s;
        return SxStepper.int(value: v, min: 0, max: 2, label: 'Sets', onChanged: (n) => set(() => v = n));
      }));
      for (final label in ['Decrease Sets', 'Increase Sets']) {
        final r = t.getRect(find.bySemanticsLabel(label));
        expect(r.width, greaterThanOrEqualTo(48));
        expect(r.height, greaterThanOrEqualTo(48));
      }
      await t.tap(find.bySemanticsLabel('Increase Sets'));
      await t.pump();
      expect(v, 2);
      // At max the increase button is disabled.
      expect(t.getSemantics(find.bySemanticsLabel('Increase Sets')), matchesSemantics(label: 'Increase Sets', isButton: true, hasEnabledState: true, isEnabled: false));
      await t.tap(find.bySemanticsLabel('Increase Sets'));
      await t.pump();
      expect(v, 2);
      await t.tap(find.bySemanticsLabel('Decrease Sets'));
      await t.pump();
      await t.tap(find.bySemanticsLabel('Decrease Sets'));
      await t.pump();
      expect(v, 0);
      await t.tap(find.bySemanticsLabel('Decrease Sets'));
      expect(v, 0);
      h.dispose();
    });

    testWidgets('double: rounds step, shows unit, onTapValue', (t) async {
      var v = 20.0;
      var edits = 0;
      late StateSetter set;
      await pumpKit(t, StatefulBuilder(builder: (_, s) {
        set = s;
        return SxStepper.double(value: v, step: 2.5, unit: 'kg', label: 'Weight', onTapValue: () => edits++, onChanged: (n) => set(() => v = n));
      }));
      expect(find.textContaining('20 kg'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Increase Weight'));
      await t.pump();
      expect(v, 22.5);
      expect(find.textContaining('22.5 kg'), findsOneWidget);
      await t.tap(find.textContaining('22.5 kg'));
      expect(edits, 1);
    });

    testWidgets('long press repeats and stops', (t) async {
      var v = 0;
      late StateSetter set;
      await pumpKit(t, StatefulBuilder(builder: (_, s) {
        set = s;
        return SxStepper.int(value: v, max: 100, onChanged: (n) => set(() => v = n));
      }));
      final g = await t.startGesture(t.getCenter(find.byIcon(Icons.add)));
      for (var i = 0; i < 50; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump();
      final held = v;
      expect(held, greaterThan(2));
      await t.pump(const Duration(seconds: 1));
      expect(v, held);
    });
  });

  group('SxCheck', () {
    testWidgets('28dp box in 48dp target, checked semantics, toggles', (t) async {
      final h = t.ensureSemantics();
      var on = false;
      late StateSetter set;
      await pumpKit(t, StatefulBuilder(builder: (_, s) {
        set = s;
        return SxCheck(checked: on, semanticLabel: 'Set 1 done', haptic: false, onChanged: (v) => set(() => on = v));
      }));
      expect(t.getSize(find.byType(SxCheck)), const Size(48, 48));
      expect(t.getSize(find.byType(AnimatedContainer)), const Size(28, 28));
      expect(t.getSemantics(find.byType(SxCheck)), matchesSemantics(label: 'Set 1 done', hasCheckedState: true, isChecked: false, hasEnabledState: true, isEnabled: true, hasTapAction: true));
      await t.tap(find.byType(SxCheck));
      await t.pumpAndSettle();
      expect(on, isTrue);
      expect(find.byIcon(Icons.check), findsOneWidget);
      h.dispose();
    });
  });

  testWidgets('SxTag / SxPill / SxSpinner render', (t) async {
    await pumpKit(t, const Column(children: [SxTag('pr', icon: Icons.star), SxPill('x', filled: true), SxSpinner()]));
    expect(find.text('PR'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
