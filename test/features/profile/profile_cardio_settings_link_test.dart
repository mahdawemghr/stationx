import 'package:flutter/material.dart' show Scrollable, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/data/seed/seed_data.dart';
import 'package:stationx/features/cardio/cardio_settings_page.dart';
import 'package:stationx/features/profile/profile_page.dart';

import '../../helpers/pump.dart';

void main() {
  testWidgets('Profile links to the cardio units & export screen', (t) async {
    final app = AppController(store: MemoryStore(SeedData.fresh()));
    await pumpPage(
      t,
      const ProfilePage(),
      controller: app,
      size: const Size(390, 3200),
    );
    await t.scrollUntilVisible(
      find.text('Cardio units & export'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.text('Cardio units & export'));
    await t.pumpAndSettle();
    expect(find.byType(CardioSettingsPage), findsOneWidget);
  });
}
