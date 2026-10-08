import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/features/progress/progress_widgets.dart';

import '../../core/_kit_harness.dart';

Widget _tile() => CountStatTile(label: 'Workouts', value: 12, format: (v) => v.round().toString());

void main() {
  testWidgets('headline number counts up from 0 to its end value', (t) async {
    await pumpKit(t, _tile());
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('12'), findsNothing);
    await t.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('reduced motion shows the final number immediately', (t) async {
    await pumpKit(t, _tile(), reduced: true);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('semantic label carries the final value, not the animated one', (t) async {
    final h = t.ensureSemantics();
    await pumpKit(t, _tile());
    await t.pump(const Duration(milliseconds: 50));
    expect(find.bySemanticsLabel(RegExp('Workouts: 12')), findsOneWidget);
    await t.pumpAndSettle();
    h.dispose();
  });
}
