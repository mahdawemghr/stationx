import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'cardio_goal_sheet.dart';
import 'cardio_manage_helpers.dart';

/// One goal in depth. Every figure is computed from logged sessions.
class CardioGoalDetailsPage extends StatelessWidget {
  const CardioGoalDetailsPage({super.key, required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: app.cardio,
      builder: (context, _) {
        CardioGoal? goal;
        for (final g in app.cardio.goals) {
          if (g.id == goalId) goal = g;
        }
        if (goal == null) {
          return const SxScaffold(
            topBar: SxTopBar(title: 'Goal Details'),
            body: Center(child: ErrorState(message: 'This goal no longer exists.')),
          );
        }
        return _Body(goal: goal, sessions: app.cardio.sessions);
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.goal, required this.sessions});
  final CardioGoal goal;
  final List<CardioSession> sessions;

  static const _periods = 6;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final now = DateTime.now();
    final g = goal;
    final range = goalPeriodRange(g.period, now);
    final inPeriod = sessionsInRange(sessions, range)..sort((a, b) => b.workoutDate.compareTo(a.workoutDate));
    final value = CardioMetrics.goalValue(g, inPeriod, kinds: goalKinds(g));
    final frac = g.target <= 0 ? 0.0 : value / g.target;
    final status = goalPaceStatus(g, value, now);
    final left = daysLeftInPeriod(g.period, now);
    final unit = goalMetricUnit(g.metric);
    final periodWord = g.period == GoalPeriod.week ? 'week' : 'month';

    // history: oldest → newest, last element is the current period
    final values = [for (var off = _periods - 1; off >= 0; off--) goalValueForPeriod(g, sessions, now, offset: off)];
    final labels = [
      for (var off = _periods - 1; off >= 0; off--)
        off == 0 ? 'Now' : (g.period == GoalPeriod.week ? Fmt.dateShort(goalPeriodRange(g.period, now, offset: off).$1) : Fmt.monthShort(goalPeriodRange(g.period, now, offset: off).$1.month))
    ];
    final prev = values[_periods - 2];
    final insights = <(IconData, String)>[
      (Icons.fitness_center, '${inPeriod.length} cardio session${inPeriod.length == 1 ? '' : 's'} logged this $periodWord.'),
      if (prev > 0)
        (
          value >= prev ? Icons.trending_up : Icons.trending_down,
          'This $periodWord is ${((value - prev) / prev * 100).abs().round()}% ${value >= prev ? 'above' : 'below'} last $periodWord (${goalNumber(g.metric, prev)} ${unit.toLowerCase()}).'
        ),
    ];
    // streak of consecutive met periods, counting back from the latest finished one
    var streak = 0;
    for (var off = 1; off <= 52; off++) {
      if (g.target > 0 && goalValueForPeriod(g, sessions, now, offset: off) >= g.target) {
        streak++;
      } else {
        break;
      }
    }
    var best = 0.0;
    for (var off = 0; off < 52; off++) {
      final v = goalValueForPeriod(g, sessions, now, offset: off);
      if (v > best) best = v;
    }

    return SxScaffold(
      topBar: SxTopBar(
        title: 'Goal Details',
        subtitle: 'GOAL TELEMETRY',
        actions: [SxIconButton(icon: Icons.tune, tooltip: 'Adjust goal', onPressed: () => _adjust(context))],
      ),
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        SxButton(label: 'Log cardio for this goal', icon: Icons.add_circle_outline, onPressed: () => AppNav.selectCardioActivity(context)),
      ]),
      children: [
        SxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (g.isPrimary) const StatusPill('Primary goal', icon: Icons.bolt),
              StatusPill(goalPeriodLabel(g.period), color: c.textBody),
            ]),
            const SizedBox(height: 10),
            Text(g.title, style: SxText.headlineLg.copyWith(color: c.textHigh)),
            Text('TARGET: ${goalNumber(g.metric, g.target)} $unit / ${periodWord.toUpperCase()}', style: SxText.labelXs.copyWith(color: c.textBody)),
            const SizedBox(height: SxSpace.md),
            Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 12, runSpacing: 8, children: [
              Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(goalNumber(g.metric, value), style: SxText.displayHero.copyWith(color: c.primary)),
                Flexible(child: Text(' / ${goalNumber(g.metric, g.target)} $unit', overflow: TextOverflow.ellipsis, style: SxText.metricMd.copyWith(color: c.textBody))),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${(frac * 100).round()}%', style: SxText.metricLg.copyWith(color: c.primary)),
                Text('COMPLETED', style: SxText.labelXs.copyWith(color: c.textBody)),
              ]),
            ]),
            const SizedBox(height: 12),
            SxLinearMeter(value: frac, height: 10),
            const SizedBox(height: 8),
            SxInset(
              child: Row(children: [
                Icon(Icons.timer_outlined, size: 18, color: c.textBody),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value >= g.target
                        ? 'Target reached • $left day${left == 1 ? '' : 's'} left in this $periodWord'
                        : '${goalNumber(g.metric, g.target - value)} ${unit.toLowerCase()} remaining • $left day${left == 1 ? '' : 's'} left',
                    style: SxText.bodySm.copyWith(color: c.textHigh),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            SxInset(
              child: Row(children: [
                Icon(status.good ? Icons.check_circle_outline : Icons.info_outline, size: 18, color: status.good ? c.primary : c.danger),
                const SizedBox(width: 8),
                Expanded(child: Text(status.text, style: SxText.bodySm.copyWith(color: c.textHigh))),
              ]),
            ),
          ]),
        ),
        SxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.show_chart, color: c.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Last $_periods ${periodWord}s', style: SxText.headlineSm.copyWith(color: c.textHigh))),
              Text(unit, style: SxText.labelXs.copyWith(color: c.textBody)),
            ]),
            const SizedBox(height: SxSpace.md),
            SxBarChart(values: values, labels: labels, target: g.target, highlightIndex: _periods - 1, height: 120),
            const SizedBox(height: SxSpace.md),
            for (final i in insights)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SxInset(
                  child: Row(children: [
                    Icon(i.$1, size: 18, color: c.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(i.$2, style: SxText.bodySm.copyWith(color: c.textHigh))),
                  ]),
                ),
              ),
          ]),
        ),
        SectionHeader('This $periodWord', trailingText: '${inPeriod.length} session${inPeriod.length == 1 ? '' : 's'}'),
        if (inPeriod.isEmpty)
          SxCard(child: Text('Nothing logged yet this $periodWord. Start a session or log a past one.', style: SxText.bodyMd.copyWith(color: c.textBody)))
        else
          for (final s in inPeriod)
            SxCard(
              onTap: () => AppNav.cardioDetails(context, s.id),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.base)),
                  child: Icon(cardioKindIcon(s.kind), color: c.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.kind.label, style: SxText.headlineSm.copyWith(color: c.textHigh), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(Fmt.dateLong(s.workoutDate), style: SxText.bodySm.copyWith(color: c.textBody), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                const SizedBox(width: 8),
                MetricValue(goalContribution(g, s), unit: unit.toLowerCase(), style: SxText.metricMd, color: c.primary),
              ]),
            ),
        SxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Milestones & history', style: SxText.headlineSm.copyWith(color: c.textHigh))),
              Icon(Icons.military_tech_outlined, color: c.primary),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Mile(label: 'Current streak', value: '$streak', unit: streak == 1 ? periodWord : '${periodWord}s', sub: 'Consecutive met')),
              const SizedBox(width: 8),
              Expanded(child: _Mile(label: 'Historical best', value: goalNumber(g.metric, best), unit: unit.toLowerCase(), sub: 'Best $periodWord')),
            ]),
          ]),
        ),
        SxButton(label: 'Adjust goal parameters', icon: Icons.tune, variant: SxButtonVariant.secondary, onPressed: () => _adjust(context)),
      ],
    );
  }

  Future<void> _adjust(BuildContext context) async {
    final nav = Navigator.of(context);
    final repo = context.app.cardio;
    await showCardioGoalSheet(context, goal: goal);
    if (!repo.goals.any((x) => x.id == goal.id) && nav.canPop()) nav.pop();
  }
}

class _Mile extends StatelessWidget {
  const _Mile({required this.label, required this.value, required this.unit, required this.sub});
  final String label;
  final String value;
  final String unit;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxInset(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: SxText.labelXs.copyWith(color: c.textBody), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: MetricValue(value, unit: unit, style: SxText.metricLg, color: c.primary)),
        Text(sub, style: SxText.bodySm.copyWith(color: c.textBody), overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
