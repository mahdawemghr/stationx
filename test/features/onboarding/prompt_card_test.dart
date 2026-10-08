import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/features/onboarding/schedule_setup_entry.dart';

void main() {
  test('prompt card is only part of the layout while it is visible', () {
    final app = AppController();
    addTearDown(() => ScheduleSetupPrompt.dismissed.value = false);
    ScheduleSetupPrompt.dismissed.value = false;
    expect(ScheduleSetupPromptCard.shouldShow(app), app.profile.profile.isGuest && app.sessions.sessions.isEmpty);
    ScheduleSetupPrompt.dismissed.value = true;
    expect(ScheduleSetupPromptCard.shouldShow(app), isFalse);
  });
}
