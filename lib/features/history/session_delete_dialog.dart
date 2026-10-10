import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

/// Destructive confirmation shown before deleting a logged strength session.
/// Resolves to true only when the user confirms. Does NOT delete anything itself;
/// callers delete via SessionRepository after a `true` result. The rotation is never touched.
Future<bool> confirmDeleteSession(BuildContext context, WorkoutSession session) {
  return showSxConfirm(
    context,
    title: 'Delete workout?',
    message: 'This session will be permanently removed from your history, volume totals, '
        'records and weekly goals. Your schedule and rotation are not changed. This cannot be undone.',
    confirmLabel: 'Delete workout',
    destructive: true,
    icon: Icons.delete_forever,
    preview: _SessionPreview(session: session),
  );
}

class _SessionPreview extends StatelessWidget {
  const _SessionPreview({required this.session});
  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final unit = context.app.profile.profile.unit;
    return SxInset(
      child: Row(children: [
        Icon(Icons.fitness_center, color: c.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(session.name, overflow: TextOverflow.ellipsis, style: SxText.headlineSm.copyWith(color: c.textHigh)),
            Text(Fmt.dateMedium(session.workoutDate), overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${session.doneSets} sets', style: SxText.metricSm.copyWith(color: c.textHigh)),
          Text(Fmt.volume(session.volume, u: unit), style: SxText.bodySm.copyWith(color: c.textBody)),
        ]),
      ]),
    );
  }
}

/// Confirm, delete and report. Returns true when the session was deleted.
Future<bool> deleteSessionWithConfirm(BuildContext context, WorkoutSession session) async {
  if (!await confirmDeleteSession(context, session) || !context.mounted) return false;
  final app = context.app;
  final messenger = ScaffoldMessenger.of(context);
  await app.sessions.delete(session.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Workout deleted')));
  return true;
}
