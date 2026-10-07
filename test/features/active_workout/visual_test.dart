import 'package:flutter/material.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/features/active_workout/active_workout_page.dart';
import 'package:stationx/features/active_workout/workout_complete_page.dart';

import '../../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('strength logger renders', (t) async {
    await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w2'));
    await shot(t, 'aw_strength');
    expect(t.takeException(), isNull);
  });

  testWidgets('mixed logger renders', (t) async {
    await pumpPage(t, const ActiveWorkoutPage(workoutId: 'w1'), size: const Size(390, 1100));
    await shot(t, 'aw_mixed');
    expect(t.takeException(), isNull);
  });

  testWidgets('complete (strength) renders', (t) async {
    final app = await pumpPage(t, WorkoutCompletePage(sessionId: 'seed_s2'), size: const Size(390, 1200));
    expect(app.sessions.byId('seed_s2'), isNotNull);
    await shot(t, 'aw_complete');
    expect(t.takeException(), isNull);
  });
}
