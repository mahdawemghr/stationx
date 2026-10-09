import 'package:flutter/material.dart';

import '../../core/theme/sx_colors.dart';
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
            ..._sections(c, days[i], byId),
          ]),
        ),
    ]);
  }

  /// The day as it will be saved: arranged, one section per muscle, main exercises first then sub-areas.
  List<Widget> _sections(SxColors c, SplitDayPlan day, Map<String, Exercise> byId) {
    final arranged = WorkoutSections.arrange(day.exercises, all, muscleOrder: day.sectionMuscles);
    final sections = WorkoutSections.group(arranged, all);
    final headers = WorkoutSections.showSectionHeaders(sections);
    Widget row(RoutineExercise re) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text(byId[re.exerciseId]?.name ?? re.exerciseId, style: SxText.bodyMd.copyWith(color: c.textHigh))),
            Text('${re.sets}×${re.repMin}–${re.repMax}', style: SxText.metricSm.copyWith(color: c.textBody)),
          ]),
        );
    return [
      for (final s in sections) ...[
        if (headers)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              header: true,
              child: Text('${s.label.toUpperCase()} · ${s.sets} ${s.sets == 1 ? 'set' : 'sets'}', style: SxText.labelCaps.copyWith(color: c.primary)),
            ),
          ),
        for (final g in s.groups) ...[
          if (g.label != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(g.label!, style: SxText.bodySm.copyWith(color: c.textMuted)),
            ),
          for (final re in g.items) row(re),
        ],
      ],
      for (final re in arranged)
        if (byId[re.exerciseId] == null) row(re),
    ];
  }
}
