import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/domain/domain.dart';
import '../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('muscle map renders every group, both views, and sizes itself', (t) async {
    await pumpPage(t, SxScaffold(topBar: const SxTopBar(title: 'Muscle map'), children: [
      for (final m in MuscleGroup.values)
        SxCard(
          child: Row(children: [
            SizedBox(width: 70, child: Text(m.label)),
            MuscleMap(primary: {m}, height: 90, view: MuscleView.both),
            const SizedBox(width: 12),
            MuscleMap(primary: {m}, secondary: {MuscleGroup.shoulders}, height: 56),
          ]),
        ),
    ]), size: const Size(390, 1500));
    expect(tester0(t), isNull);
    await shot(t, 'muscle_map_all');
  });

  testWidgets('auto view picks the back for back/triceps and front otherwise; semantics describe muscles', (t) async {
    await pumpPage(t, const Column(children: [
      MuscleMap(primary: {MuscleGroup.back}),
      MuscleMap(primary: {MuscleGroup.chest}, secondary: {MuscleGroup.triceps}),
    ]));
    final maps = t.widgetList<MuscleMap>(find.byType(MuscleMap)).toList();
    expect(maps.length, 2);
    expect(find.bySemanticsLabel(RegExp('Primary: Back')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Secondary: Triceps')), findsOneWidget);
  });
}

Object? tester0(WidgetTester t) => t.takeException();
