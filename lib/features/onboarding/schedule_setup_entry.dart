import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';

/// Opens the schedule setup from Workouts / Profile. Saving replaces the rotation,
/// so when workouts already exist this explains that first.
Future<void> startScheduleSetup(BuildContext context) async {
  final app = context.app;
  if (app.workouts.rotation.workoutIds.isNotEmpty) {
    final ok = await showSxConfirm(
      context,
      title: 'Replace your rotation?',
      message: 'The new days become your rotation. Your previous workouts are archived, not deleted, and your history is kept. You can add them back from the Workouts tab.',
      confirmLabel: 'Continue',
      icon: Icons.swap_horiz,
    );
    if (!ok || !context.mounted) return;
  }
  await AppNav.scheduleSetup(context);
}

/// Session-only dismissal of the guest prompt (no persisted profile flag exists).
abstract final class ScheduleSetupPrompt {
  static final ValueNotifier<bool> dismissed = ValueNotifier(false);
}

/// Dismissible Today card for guests with no history who have not set a schedule.
class ScheduleSetupPromptCard extends StatelessWidget {
  const ScheduleSetupPromptCard({super.key});

  /// Whether the card should be part of the layout at all (parents omit it otherwise, so no empty gap remains).
  static bool shouldShow(AppController app) {
    final hasSchedule = app.workouts.workouts.any((w) => w.description == 'My schedule');
    return !ScheduleSetupPrompt.dismissed.value && app.profile.profile.isGuest && app.sessions.sessions.isEmpty && !hasSchedule;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([ScheduleSetupPrompt.dismissed, app.profile, app.sessions, app.workouts]),
      builder: (context, _) {
        if (!shouldShow(app)) return const SizedBox.shrink();
        final c = context.sx;
        return SxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.tune, color: c.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('Set up your schedule', style: SxText.headlineMd.copyWith(color: c.textHigh))),
              IconButton(
                tooltip: 'Dismiss',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.close, color: c.textMuted),
                onPressed: () => ScheduleSetupPrompt.dismissed.value = true,
              ),
            ]),
            Text('Pick a split and your exercises in a minute. Optional.', style: SxText.bodyMd.copyWith(color: c.textBody)),
            const SizedBox(height: 12),
            SxButton(label: 'Set up my schedule', variant: SxButtonVariant.secondary, onPressed: () => startScheduleSetup(context)),
          ]),
        );
      },
    );
  }
}
