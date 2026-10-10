import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../history/session_delete_dialog.dart';
import 'workout_stats.dart';

/// Past sessions of one workout (newest first) with edit / delete, shown on the workout page
/// opened from the schedule. Tapping a row opens the session summary.
class WorkoutHistorySection extends StatelessWidget {
  const WorkoutHistorySection({super.key, required this.workoutId, this.limit = 10});
  final String workoutId;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.sx;
    final unit = app.profile.profile.unit;
    final all = WorkoutStats.sessionsOf(workoutId, app.sessions.sessions);
    final shown = all.take(limit).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader('History', trailingText: all.isEmpty ? null : '${all.length} logged'),
      const SizedBox(height: 8),
      if (all.isEmpty)
        const SxCard(child: EmptyState(icon: Icons.history, title: 'No history yet', message: 'Sessions you log for this workout appear here, where you can edit or delete them.'))
      else
        for (final s in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SxCard(
              key: ValueKey('history_${s.id}'),
              padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
              onTap: () => AppNav.viewWorkoutSession(context, s.id),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Fmt.dateMedium(s.workoutDate), style: SxText.headlineSm.copyWith(color: c.textHigh)),
                    Text('${s.doneSets} sets • ${Fmt.volume(s.volume, u: unit)}', style: SxText.bodySm.copyWith(color: c.textBody)),
                  ]),
                ),
                SxIconButton(icon: Icons.edit_outlined, tooltip: 'Edit ${Fmt.dateMedium(s.workoutDate)} session', filled: false, onPressed: () => AppNav.editWorkoutSession(context, s.id)),
                SxIconButton(icon: Icons.delete_outline, tooltip: 'Delete ${Fmt.dateMedium(s.workoutDate)} session', filled: false, iconColor: c.danger, onPressed: () => deleteSessionWithConfirm(context, s)),
              ]),
            ),
          ),
    ]);
  }
}
