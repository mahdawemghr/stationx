import 'package:flutter/material.dart';

import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

Workout _asWorkout(SplitDayPlan d, int i) => Workout(id: 'setup_$i', name: d.name, exercises: d.exercises);

String _levelLabel(CoverageLevel l) => switch (l) {
      CoverageLevel.high => 'High',
      CoverageLevel.moderate => 'Moderate',
      CoverageLevel.low => 'Low',
      CoverageLevel.none => 'None',
    };

double _levelFill(CoverageLevel l) => switch (l) {
      CoverageLevel.high => 1,
      CoverageLevel.moderate => 0.6,
      CoverageLevel.low => 0.3,
      CoverageLevel.none => 0,
    };

/// Compact, collapsible weekly muscle-coverage summary for the Review step. All numbers come from
/// [MuscleCoverage] / [ExerciseRecommender]; this widget only draws them. Hints are optional, never demands.
class SetupCoverageSummary extends StatefulWidget {
  const SetupCoverageSummary({super.key, required this.days, required this.catalog, required this.perWeek});
  final List<SplitDayPlan> days;
  final List<Exercise> catalog;
  final int perWeek;

  @override
  State<SetupCoverageSummary> createState() => _SetupCoverageSummaryState();
}

class _SetupCoverageSummaryState extends State<SetupCoverageSummary> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final report = MuscleCoverage.ofProgram(
      [for (var i = 0; i < widget.days.length; i++) _asWorkout(widget.days[i], i)],
      widget.catalog,
      daysPerWeek: widget.perWeek,
    );
    final regions = [
      for (final r in MuscleRegion.values)
        if (report.levelOfRegion(r) != CoverageLevel.none) r,
    ];
    if (regions.isEmpty) return const SizedBox.shrink();
    final gaps = ExerciseRecommender.gaps(report, daysPerWeek: widget.perWeek);
    return SxCard(
      padding: const EdgeInsets.symmetric(horizontal: SxSpace.md, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
          button: true,
          expanded: _open,
          label: 'Muscle coverage, ${_open ? 'expanded' : 'collapsed'}',
          excludeSemantics: true,
          onTap: () => setState(() => _open = !_open),
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(children: [
                Expanded(child: Text('Muscle coverage', style: SxText.headlineSm.copyWith(color: c.textHigh))),
                Icon(_open ? Icons.expand_less : Icons.expand_more, color: c.textBody),
              ]),
            ),
          ),
        ),
        if (_open) ...[
          Text('A rough weekly picture of your program. Just a guide.', style: SxText.bodySm.copyWith(color: c.textMuted)),
          const SizedBox(height: 8),
          for (final r in regions) _CoverageRow(label: r.label, level: report.levelOfRegion(r)),
          if (gaps.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final g in gaps.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: c.textMuted),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Optional: ${g.note}', style: SxText.bodySm.copyWith(color: c.textBody))),
                ]),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ]),
    );
  }
}

class _CoverageRow extends StatelessWidget {
  const _CoverageRow({required this.label, required this.level});
  final String label;
  final CoverageLevel level;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$label coverage ${_levelLabel(level).toLowerCase()}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(flex: 4, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.bodyMd.copyWith(color: c.textHigh))),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: SxLinearMeter(
              value: _levelFill(level),
              height: 6,
              color: level == CoverageLevel.low ? c.textMuted : c.primary,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 72, child: Text(_levelLabel(level), textAlign: TextAlign.end, style: SxText.bodySm.copyWith(color: c.textBody))),
        ]),
      ),
    );
  }
}

/// One muted line for the day step, e.g. "Chest: well covered · Triceps: light". Null when nothing ticked.
String? dayCoverageHint(SplitDayPlan day, List<Exercise> catalog) {
  if (day.exercises.isEmpty) return null;
  final report = MuscleCoverage.ofWorkout(_asWorkout(day, 0), catalog);
  final parts = <String>[];
  for (final r in MuscleRegion.values) {
    final l = report.levelOfRegion(r);
    if (l == CoverageLevel.none) continue;
    parts.add('${r.label}: ${switch (l) {
      CoverageLevel.high => 'well covered',
      CoverageLevel.moderate => 'moderate',
      _ => 'light',
    }}');
  }
  return parts.isEmpty ? null : parts.join(' · ');
}
