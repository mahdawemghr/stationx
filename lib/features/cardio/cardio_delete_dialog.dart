import 'package:flutter/material.dart';

import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

/// Destructive confirmation shown before deleting a cardio session.
/// Resolves to true only when the user confirms. Does NOT delete anything
/// itself — callers delete via CardioRepository after a `true` result.
Future<bool> confirmDeleteCardio(BuildContext context, CardioSession session) {
  return showSxConfirm(
    context,
    title: 'Delete cardio session?',
    message: 'This workout will be permanently removed from your history, '
        'volume totals and weekly goals. This cannot be undone.',
    confirmLabel: 'Delete session',
    destructive: true,
    icon: Icons.delete_forever,
    preview: _SessionPreview(session: session),
  );
}

class _SessionPreview extends StatelessWidget {
  const _SessionPreview({required this.session});
  final CardioSession session;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxInset(
      child: Row(children: [
        Icon(Icons.directions_run, color: c.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(session.kind.label, overflow: TextOverflow.ellipsis, style: SxText.headlineSm.copyWith(color: c.textHigh)),
            Text('${Fmt.dateMedium(session.workoutDate)} • ${Fmt.time(session.workoutDate)}',
                overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(Fmt.clock(session.durationSeconds), style: SxText.metricSm.copyWith(color: c.textHigh)),
          if (session.distanceKm != null)
            Text('${Fmt.km(session.distanceKm)} km', style: SxText.bodySm.copyWith(color: c.textBody)),
        ]),
      ]),
    );
  }
}
