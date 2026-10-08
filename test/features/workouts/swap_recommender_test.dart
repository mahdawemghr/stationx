import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/workouts/swap_exercise_sheet.dart';

import '../../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);

  late List<Exercise> catalog;
  late Exercise lat;
  setUp(() {
    final a = AppController()..startDemo();
    catalog = a.exercises.all;
    lat = a.exercises.byId('lat_pulldown')!;
  });

  testWidgets('uses the recommender: first card is a Lats exercise with the engine reason', (t) async {
    final expected = ExerciseRecommender.replacements(current: lat, catalog: catalog);
    expect(expected, isNotEmpty);
    expect(MuscleProfiles.of(expected.first.exercise).targets.any((x) => x.muscle == Muscle.lats), isTrue);
    await pumpPage(t, Scaffold(body: SwapExerciseBody(current: lat, catalog: catalog, sets: 4, repRange: '8-12', onClose: () {}, onReplace: (_) {})));
    expect(find.text('${expected.length} available'), findsOneWidget);
    expect(find.text(expected.first.reason), findsWidgets);
    Exercise? picked;
    await pumpPage(t, Scaffold(body: SwapExerciseBody(current: lat, catalog: catalog, sets: 4, repRange: '8-12', onClose: () {}, onReplace: (e) => picked = e)));
    await t.tap(find.text('REPLACE EXERCISE'));
    await t.pump();
    expect(picked!.id, expected.first.exercise.id);
  });

  testWidgets('exclusions are honored', (t) async {
    final first = ExerciseRecommender.replacements(current: lat, catalog: catalog).first.exercise;
    Exercise? picked;
    await pumpPage(t, Scaffold(body: SwapExerciseBody(current: lat, catalog: catalog, sets: 4, repRange: '8-12', excludeIds: {first.id}, onClose: () {}, onReplace: (e) => picked = e)));
    await t.tap(find.text('REPLACE EXERCISE'));
    await t.pump();
    expect(picked!.id, isNot(first.id));
  });
}
