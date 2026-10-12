import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';

import '_kit_harness.dart';

void main() {
  testWidgets('SxLineChart grows in on first build and settles', (t) async {
    await pumpKit(t, const SxLineChart(values: [1, 3, 2, 5]));
    expect(t.hasRunningAnimations, isTrue);
    expect(
      find.descendant(
        of: find.byType(SxLineChart),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
    await t.pump(const Duration(milliseconds: 200));
    expect(t.hasRunningAnimations, isTrue);
    await t.pumpAndSettle();
    expect(t.hasRunningAnimations, isFalse);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'SxLineChart reduced motion draws at once; empty and single value are safe',
    (t) async {
      await pumpKit(t, const SxLineChart(values: [1, 3, 2]), reduced: true);
      expect(t.hasRunningAnimations, isFalse);
      await pumpKit(t, const SxLineChart(values: []));
      await t.pumpAndSettle();
      await pumpKit(t, const SxLineChart(values: [4]));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'StatTile.number counts up and settles on the same text as a static tile',
    (t) async {
      await pumpKit(
        t,
        const StatTile.number(label: 'Sets', value: 42, unit: 'sets'),
      );
      expect(find.text('0'), findsOneWidget);
      await t.pumpAndSettle();
      expect(find.text('42'), findsOneWidget);
      expect(find.bySemanticsLabel('Sets: 42 sets'), findsOneWidget);
      await pumpKit(
        t,
        const StatTile(label: 'Sets', value: '42', unit: 'sets'),
      );
      expect(find.text('42'), findsOneWidget);
    },
  );

  testWidgets(
    'StatTile.number uses the formatter; reduced motion shows the final value',
    (t) async {
      await pumpKit(
        t,
        StatTile.number(
          label: 'Vol',
          value: 1234.5,
          formatter: (v) => v.toStringAsFixed(1),
        ),
        reduced: true,
      );
      expect(find.text('1234.5'), findsOneWidget);
    },
  );
}
