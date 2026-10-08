import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'exercise_widgets.dart';
import 'exercise_stats.dart';

enum _Metric { weight, reps, volume, e1rm }

/// Per-exercise history: milestones, trend chart and set-by-set session log.
class ExerciseHistoryPage extends StatefulWidget {
  const ExerciseHistoryPage({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  State<ExerciseHistoryPage> createState() => _ExerciseHistoryPageState();
}

class _ExerciseHistoryPageState extends State<ExerciseHistoryPage> {
  _Metric _metric = _Metric.weight;
  static const _maxChartPoints = 12;

  double _value(ExerciseSessionStat s, WeightUnit unit) => switch (_metric) {
        _Metric.weight => Fmt.toDisplayWeight(s.topWeight, unit),
        _Metric.reps => s.topReps.toDouble(),
        _Metric.volume => Fmt.toDisplayWeight(s.volume, unit),
        _Metric.e1rm => Fmt.toDisplayWeight(s.e1rm, unit),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.exercises, app.sessions, app.profile, app.workouts]),
      builder: (context, _) {
        final ex = app.exercises.byId(widget.exerciseId);
        if (ex == null) {
          return const SxScaffold(topBar: SxTopBar(title: 'Exercise History'), children: [ErrorState(message: 'This exercise no longer exists.')]);
        }
        final unit = app.profile.profile.unit;
        final u = Fmt.unit(unit);
        final all = app.sessions.sessions;
        final stats = statsFor(ex.id, all);
        final prs = PrService.forExercise(ex.id, all);
        final best = prs[PrType.heaviestWeight];
        final e1rmPr = prs[PrType.estimated1Rm];
        final e1rm = e1rmPr != null && e1rmPr.value > 0 ? e1rmPr : null;
        final routine = app.workouts.workouts.where((w) => w.exercises.any((r) => r.exerciseId == ex.id)).toList();
        final recent = stats.reversed.toList();

        // A 0 estimate means "no reliable estimate" (e.g. > 12 reps): such sessions are left out of the
        // e1RM chart and trend instead of being plotted as 0 or compared with a real value.
        final plotted = _metric == _Metric.e1rm ? [for (final s in stats) if (s.e1rm > 0) s] : stats;
        final chartStats = plotted.length > _maxChartPoints ? plotted.sublist(plotted.length - _maxChartPoints) : plotted;
        final values = [for (final s in chartStats) _value(s, unit)];
        final labels = [
          for (var i = 0; i < chartStats.length; i++)
            (i == 0 || i == chartStats.length - 1 || (chartStats.length > 4 && i == chartStats.length ~/ 2)) ? Fmt.dateShort(chartStats[i].date).toUpperCase() : '',
        ];
        double? trendPct;
        if (values.length >= 2 && values.first > 0) trendPct = (values.last - values.first) / values.first * 100;

        return SxScaffold(
          topBar: SxTopBar(title: ex.name, subtitle: '${ex.primaryMuscle.label} · ${ex.equipment.label}'.toUpperCase()),
          bottom: Row(children: [
            Expanded(
              child: SxButton(
                label: routine.isEmpty ? 'Add to a routine' : 'Start ${routine.first.name}',
                icon: routine.isEmpty ? Icons.add : Icons.play_arrow,
                onPressed: () => routine.isEmpty ? AppNav.exerciseDetails(context, ex.id) : AppNav.activeWorkout(context, routine.first.id),
              ),
            ),
            const SizedBox(width: 12),
            SxIconButton(icon: Icons.menu_book_outlined, tooltip: 'Exercise details', size: 52, onPressed: () => AppNav.exerciseDetails(context, ex.id)),
          ]),
          children: stats.isEmpty
              ? [
                  EmptyState(
                    icon: Icons.history,
                    title: 'No history yet',
                    message: 'Complete a workout containing ${ex.name} and its sessions, PRs and trends will appear here.',
                    actionLabel: 'Exercise details',
                    onAction: () => AppNav.exerciseDetails(context, ex.id),
                  ),
                ]
              : [
                  _Milestones(bestWeight: best, e1rm: e1rm, unit: unit),
                  SxChipRow(
                    padding: EdgeInsets.zero,
                    labels: ['Weight ($u)', 'Reps', 'Volume ($u)', 'Est. 1RM'],
                    selectedIndex: _metric.index,
                    onSelected: (i) => setState(() => _metric = _Metric.values[i]),
                  ),
                  SxCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${chartStats.length}-SESSION TREND', style: SxText.labelCaps.copyWith(color: c.textBody)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Expanded(
                          child: Text(
                            trendPct == null ? 'Log more sessions to see a trend' : '${trendPct >= 0 ? '+' : ''}${trendPct.toStringAsFixed(1)}% ${switch (_metric) { _Metric.weight => 'top weight', _Metric.reps => 'top reps', _Metric.volume => 'volume', _Metric.e1rm => 'est. 1RM' }}',
                            style: SxText.headlineMd.copyWith(color: c.textHigh),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      SxLineChart(values: values, labels: labels, height: 170),
                    ]),
                  ),
                  SectionHeader('Recent sessions', icon: Icons.history, trailingText: 'SET-BY-SET LOG'),
                  for (final s in recent.take(10)) _SessionCard(stat: s, unit: unit, isPr: PrService.newPrExerciseIds(s.session, all).contains(ex.id)),
                  if (recent.length > 10)
                    Center(child: Text('Showing latest 10 of ${recent.length} sessions', style: SxText.bodySm.copyWith(color: c.textMuted))),
                ],
        );
      },
    );
  }
}

class _Milestones extends StatelessWidget {
  const _Milestones({required this.bestWeight, required this.e1rm, required this.unit});
  final StrengthPr? bestWeight;
  final StrengthPr? e1rm;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final u = Fmt.unit(unit);
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('KEY MILESTONES', style: SxText.labelCaps.copyWith(color: c.textBody))),
          if (bestWeight != null) Flexible(child: StatusPill('All-time PR: ${Fmt.weight(bestWeight!.value, unit)} $u', icon: Icons.emoji_events_outlined)),
        ]),
        const SizedBox(height: 12),
        StretchRow(children: [
          Expanded(
            child: SxInset(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CURRENT BEST', style: SxText.labelXs.copyWith(color: c.textBody)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MetricValue(bestWeight == null ? '—' : Fmt.weight(bestWeight!.value, unit), unit: bestWeight == null ? null : '$u × ${bestWeight!.reps}', style: SxText.metricLg, color: c.primary),
                ),
                const SizedBox(height: 4),
                Text(bestWeight == null ? '' : 'Recorded ${Fmt.dateShort(bestWeight!.date)}', style: SxText.bodySm.copyWith(color: c.textBody)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SxInset(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ESTIMATED 1RM', style: SxText.labelXs.copyWith(color: c.textBody)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MetricValue(e1rm == null ? '—' : Fmt.weight(e1rm!.value, unit), unit: e1rm == null ? null : u, style: SxText.metricLg),
                ),
                const SizedBox(height: 4),
                if ((e1rm?.delta ?? 0) > 0)
                  FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: DeltaBadge('+${Fmt.weight(e1rm!.delta!, unit)} $u'))
                else
                  Text('Epley estimate', style: SxText.bodySm.copyWith(color: c.textBody)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.stat, required this.unit, required this.isPr});
  final ExerciseSessionStat stat;
  final WeightUnit unit;
  final bool isPr;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final u = Fmt.unit(unit);
    final sets = stat.sets;
    final rpe = stat.rpe;
    return SxCard(
      onTap: () => AppNav.viewWorkoutSession(context, stat.session.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: isPr ? c.primary : c.textMuted, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(Fmt.dateMedium(stat.date), style: SxText.headlineSm.copyWith(color: c.textHigh))),
          if (isPr) const PrBadge('PR set'),
          if (rpe != null) ...[const SizedBox(width: 8), StatusPill('RPE ${Fmt.number(rpe)}', color: c.textBody)],
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < sets.length; i++)
            SizedBox(
              width: 96,
              child: SxInset(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(children: [
                  Text('SET ${i + 1}', style: SxText.labelXs.copyWith(color: c.textBody)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${Fmt.weight(sets[i].weightKg, unit)}$u ×${sets[i].reps}', style: SxText.metricSm.copyWith(color: c.textHigh, fontSize: 14)),
                  ),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text('${sets.length} sets completed', style: SxText.labelXs.copyWith(color: c.textBody))),
          Flexible(child: Text('Total volume: ${Fmt.volume(stat.volume, u: unit)}', style: SxText.labelXs.copyWith(color: c.primary), overflow: TextOverflow.ellipsis)),
        ]),
      ]),
    );
  }
}
