import 'package:flutter/material.dart';

import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'setup_coverage.dart';
import 'setup_week_step.dart';
import 'setup_widgets.dart';

/// Step 3: days in order with sets and minutes; validation shown inline.
class SetupReviewStep extends StatelessWidget {
  const SetupReviewStep({super.key, required this.days, required this.all, required this.error, required this.onEdit, required this.perWeek});
  final int perWeek;
  final List<SplitDayPlan> days;
  final List<Exercise> all;
  final String? error;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final byId = {for (final e in all) e.id: e};
    return SetupList(children: [
      Text('Review', style: SxText.headlineLg.copyWith(color: c.textHigh)),
      Text('Your program runs in this order, one workout after another. Goal: $perWeek ${perWeek == 1 ? 'day' : 'days'} a week.', style: SxText.bodyMd.copyWith(color: c.textBody)),
      Text(sequenceNote, style: SxText.bodySm.copyWith(color: c.textMuted)),
      if (error != null)
        Semantics(
          liveRegion: true,
          child: SxCard(
            color: c.dangerContainer,
            child: Row(children: [
              Icon(Icons.error_outline, color: c.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(error!, style: SxText.bodyMd.copyWith(color: c.textHigh))),
            ]),
          ),
        ),
      SetupCoverageSummary(days: days, catalog: all, perWeek: perWeek),
      for (var i = 0; i < days.length; i++)
        SxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('${i + 1}. ${days[i].name.trim().isEmpty ? 'Unnamed day' : days[i].name}',
                    style: SxText.headlineMd.copyWith(color: c.textHigh)),
              ),
              TextButton(
                onPressed: () => onEdit(i),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text('Edit', semanticsLabel: 'Edit day ${i + 1}', style: SxText.labelUi.copyWith(color: c.primary)),
              ),
            ]),
            Text('${days[i].exercises.length} exercises · ${days[i].totalSets} sets · ~${days[i].estimatedMinutes} min',
                style: SxText.bodySm.copyWith(color: c.textBody)),
            const SizedBox(height: 6),
            for (final re in days[i].exercises)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Expanded(child: Text(byId[re.exerciseId]?.name ?? re.exerciseId, style: SxText.bodyMd.copyWith(color: c.textHigh))),
                  Text('${re.sets}×${re.repMin}–${re.repMax}', style: SxText.metricSm.copyWith(color: c.textBody)),
                ]),
              ),
          ]),
        ),
    ]);
  }
}
