import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';

import '_kit_harness.dart';

double _w(WidgetTester t) => t.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor!;

void main() {
  testWidgets('SxLinearMeter animates from 0 on first build', (t) async {
    await pumpKit(t, const SizedBox(width: 200, child: SxLinearMeter(value: 0.8)));
    expect(_w(t), 0);
    await t.pump(const Duration(milliseconds: 150));
    expect(_w(t), inExclusiveRange(0, 0.8));
    await t.pumpAndSettle();
    expect(_w(t), closeTo(0.8, 1e-6));
  });

  testWidgets('SxLinearMeter reduced motion is immediate', (t) async {
    await pumpKit(t, const SizedBox(width: 200, child: SxLinearMeter(value: 0.8)), reduced: true);
    expect(_w(t), closeTo(0.8, 1e-6));
  });

  testWidgets('SxRing animates on first build', (t) async {
    await pumpKit(t, const SxRing(value: 1));
    expect(t.hasRunningAnimations, isTrue);
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpAndSettle();
    expect(t.hasRunningAnimations, isFalse);
    await pumpKit(t, const SxRing(value: 1), reduced: true);
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('SxBarChart grows bars on first build, staggered', (t) async {
    await pumpKit(t, const SizedBox(width: 300, child: SxBarChart(values: [10, 10, 10], labels: ['a', 'b', 'c'])));
    final bars = find.descendant(of: find.byType(LayoutBuilder), matching: find.byType(Container));
    double h(int i) => t.getSize(bars.at(i)).height;
    final full = [h(0), h(1), h(2)];
    expect(full.every((x) => x <= 4.0 + 0.01), isTrue, reason: 'starts collapsed');
    await t.pump(const Duration(milliseconds: 160));
    expect(h(0), greaterThan(h(2)), reason: 'first bar leads');
    await t.pumpAndSettle();
    expect(h(0), greaterThan(50));
    expect(h(2), closeTo(h(0), 0.5));
  });

  testWidgets('SxBarChart reduced motion: full height immediately', (t) async {
    await pumpKit(t, const SizedBox(width: 300, child: SxBarChart(values: [10], labels: ['a'])), reduced: true);
    expect(t.getSize(find.descendant(of: find.byType(LayoutBuilder), matching: find.byType(Container)).first).height, greaterThan(50));
  });

  testWidgets('SxSkeleton pulses, but is static under reduced motion', (t) async {
    await pumpKit(t, const SxSkeleton());
    expect(t.hasRunningAnimations, isTrue);
    await pumpKit(t, const SxSkeleton(), reduced: true);
    await t.pump();
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('SxSegmented and SxBottomNav indicator slide to the selected tab', (t) async {
    Widget seg(int i) => SizedBox(width: 300, child: SxSegmented(labels: const ['A', 'B', 'C'], index: i, onChanged: (_) {}));
    await pumpKit(t, seg(0));
    final a = t.widget<AnimatedAlign>(find.byType(AnimatedAlign));
    expect(a.alignment, const Alignment(-1, 0));
    await pumpKit(t, seg(2));
    expect(t.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, const Alignment(1, 0));
    await t.pumpAndSettle();
    await pumpKit(t, SxBottomNav(index: 1, onChanged: (_) {}), size: const Size(400, 200));
    expect((t.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment as Alignment).x, closeTo(-1 / 3, 1e-6));
  });

  testWidgets('new widgets do not overflow at 320x568@2x with large text', (t) async {
    await pumpKit(
      t,
      SizedBox(
        width: 320,
        child: ListView(children: [
          SxStepper.int(value: 5, label: 'Reps', unit: 'reps', onChanged: (_) {}),
          SxStepper.double(value: 102.5, unit: 'kg', onChanged: (_) {}),
          SxCheck(checked: true, onChanged: (_) {}),
          const SxTag('a very long status label that must truncate'),
          const SxSpinner(),
          const SxCountUp(value: 1234567, style: TextStyle(fontSize: 32)),
          SxSegmented(labels: const ['Weekly', 'Monthly', 'Yearly'], index: 1, onChanged: (_) {}),
          const SxBarChart(values: [1, 2, 3, 4, 5, 6, 7], labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S']),
          const SxRing(value: 0.5, size: 80),
        ]),
      ),
      size: const Size(320, 568),
      dpr: 2,
      textScale: 1.3,
    );
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
  });
}
