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

/// Cardio goals: primary target with weekly strip, sub-targets, past
/// achievements. Progress = every logged cardio session in the goal period.
class CardioGoalsPage extends StatelessWidget {
  const CardioGoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: app.cardio,
      builder: (context, _) {
        final goals = app.cardio.goals;
        final sessions = app.cardio.sessions;
        final now = DateTime.now();
        final topBar = SxTopBar(
          title: 'Cardio Goals',
          actions: [SxIconButton(icon: Icons.add, tooltip: 'New goal', onPressed: () => showCardioGoalSheet(context))],
        );
        if (goals.isEmpty) {
          return SxScaffold(
            topBar: topBar,
            body: Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.flag_outlined,
                  eyebrow: 'No targets yet',
                  title: 'Set your first cardio goal',
                  message: 'Pick weekly minutes, distance, sessions or calories and track progress from your logged sessions.',
                  actionLabel: 'New goal',
                  onAction: () => showCardioGoalSheet(context),
                ),
              ),
            ),
          );
        }
        final primary = goals.firstWhere((g) => g.isPrimary, orElse: () => goals.first);
        final others = goals.where((g) => g.id != primary.id).toList();
        final done = _achievements(goals, sessions, now);
        return SxScaffold(
          topBar: topBar,
          children: [
            _PrimaryCard(goal: primary, sessions: sessions, now: now),
            if (others.isNotEmpty) SectionHeader('Sub-targets', trailingText: '${others.length} active'),
            for (final g in others) _SubGoalCard(goal: g, sessions: sessions, now: now),
            if (done.isNotEmpty) ...[
              const SectionHeader('Completed periods'),
              for (final d in done) _Achievement(d),
            ],
            SxButton(label: 'Add another cardio goal', icon: Icons.add_circle_outline, variant: SxButtonVariant.secondary, onPressed: () => showCardioGoalSheet(context)),
          ],
        );
      },
    );
  }

  /// Past periods (not the current one) in which a goal was met, newest first.
  List<_Done> _achievements(List<CardioGoal> goals, List<CardioSession> sessions, DateTime now) {
    final out = <_Done>[];
    for (final g in goals) {
      for (var off = 1; off <= 12; off++) {
        if (goalValueForPeriod(g, sessions, now, offset: off) >= g.target && g.target > 0) {
          final r = goalPeriodRange(g.period, now, offset: off);
          out.add(_Done(g, r.$1, g.period == GoalPeriod.week ? 'Week of ${Fmt.dateShort(r.$1)}' : '${Fmt.monthName(r.$1.month)} ${r.$1.year}'));
        }
      }
    }
    out.sort((a, b) => b.start.compareTo(a.start));
    return out.take(3).toList();
  }
}

class _Done {
  const _Done(this.goal, this.start, this.label);
  final CardioGoal goal;
  final DateTime start;
  final String label;
}

class _Achievement extends StatelessWidget {
  const _Achievement(this.d);
  final _Done d;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      onTap: () => AppNav.cardioGoalDetails(context, d.goal.id),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.base)),
          child: Icon(Icons.military_tech_outlined, color: c.textBody),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.goal.title, style: SxText.headlineSm.copyWith(color: c.textHigh), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('ACHIEVED • ${d.label.toUpperCase()}', style: SxText.labelCaps.copyWith(color: c.primary, fontSize: 10), overflow: TextOverflow.ellipsis),
          ]),
        ),
        Icon(Icons.verified_outlined, color: c.textMuted),
      ]),
    );
  }
}

class _PrimaryCard extends StatelessWidget {
  const _PrimaryCard({required this.goal, required this.sessions, required this.now});
  final CardioGoal goal;
  final List<CardioSession> sessions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final value = goalValueForPeriod(goal, sessions, now);
    final frac = goal.target <= 0 ? 0.0 : value / goal.target;
    final status = goalPaceStatus(goal, value, now);
    final left = daysLeftInPeriod(goal.period, now);
    return SxCard(
      onTap: () => AppNav.cardioGoalDetails(context, goal.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const StatusPill('Primary target', icon: Icons.timer_outlined),
          const SizedBox(width: 8),
          Expanded(child: Text('$left day${left == 1 ? '' : 's'} left', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10), overflow: TextOverflow.ellipsis)),
          SxIconButton(icon: Icons.more_horiz, tooltip: 'Adjust goal', filled: false, onPressed: () => showCardioGoalSheet(context, goal: goal)),
        ]),
        Text(goalPeriodLabel(goal.period).toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody)),
        const SizedBox(height: 2),
        Text(goal.title, style: SxText.headlineLg.copyWith(color: c.textHigh)),
        const SizedBox(height: SxSpace.md),
        Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 10, runSpacing: 8, children: [
          Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(goalNumber(goal.metric, value), style: SxText.metricXl.copyWith(color: c.textHigh)),
            Text(' / ${goalNumber(goal.metric, goal.target)} ${goalMetricUnit(goal.metric)}', style: SxText.metricMd.copyWith(color: c.textBody)),
          ]),
          DeltaBadge('${(frac * 100).round()}% completed', positive: true),
        ]),
        const SizedBox(height: 12),
        SxLinearMeter(value: frac, height: 10),
        const SizedBox(height: 6),
        _Ticks(goal: goal),
        if (goal.period == GoalPeriod.week) ...[
          const SizedBox(height: 12),
          _DayStrip(sessions: sessions, now: now),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Icon(status.good ? Icons.check_circle : Icons.info_outline, color: status.good ? c.primary : c.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(status.text, style: SxText.bodyMd.copyWith(color: c.textHigh))),
        ]),
      ]),
    );
  }
}

class _Ticks extends StatelessWidget {
  const _Ticks({required this.goal});
  final CardioGoal goal;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final suffix = goal.metric == GoalMetric.durationMinutes ? 'm' : '';
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      for (var i = 0; i <= 5; i++)
        Text('${goalNumber(goal.metric, goal.target * i / 5)}$suffix', style: SxText.labelCaps.copyWith(color: c.textMuted, fontSize: 9)),
    ]);
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.sessions, required this.now});
  final List<CardioSession> sessions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final start = goalPeriodRange(GoalPeriod.week, now).$1;
    final today = DateTime(now.year, now.month, now.day);
    return Row(children: [
      for (var i = 0; i < 7; i++)
        Expanded(
          child: Builder(builder: (context) {
            final day = start.add(Duration(days: i));
            final mins = sessions.where((s) => Fmt.sameDay(s.workoutDate, day)).fold(0, (a, s) => a + s.durationSeconds) ~/ 60;
            final isToday = Fmt.sameDay(day, today);
            final future = day.isAfter(today);
            final IconData icon = mins > 0 ? Icons.check_circle_outline : (future ? Icons.hourglass_empty : (isToday ? Icons.directions_run : Icons.bed_outlined));
            final label = mins > 0 ? '${mins}m' : (future ? 'Open' : (isToday ? 'Today' : 'Rest'));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isToday ? c.primarySoft : c.surface2,
                  borderRadius: BorderRadius.circular(SxRadius.base),
                  border: Border.all(color: isToday ? c.primary : c.hairline),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(Fmt.dayShort(day.weekday).toUpperCase(), style: SxText.labelCaps.copyWith(fontSize: 9, color: isToday ? c.primary : c.textBody)),
                  const SizedBox(height: 4),
                  Icon(icon, size: 16, color: mins > 0 ? c.primary : c.textMuted),
                  const SizedBox(height: 4),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: SxText.labelCaps.copyWith(fontSize: 9, color: mins > 0 ? c.textHigh : c.textMuted))),
                ]),
              ),
            );
          }),
        ),
    ]);
  }
}

class _SubGoalCard extends StatelessWidget {
  const _SubGoalCard({required this.goal, required this.sessions, required this.now});
  final CardioGoal goal;
  final List<CardioSession> sessions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final value = goalValueForPeriod(goal, sessions, now);
    final frac = goal.target <= 0 ? 0.0 : value / goal.target;
    final remaining = (goal.target - value).clamp(0, double.infinity);
    final left = daysLeftInPeriod(goal.period, now);
    final isFreq = goal.metric == GoalMetric.sessions;
    final inPeriod = sessionsInRange(sessions, goalPeriodRange(goal.period, now)).length;
    return SxCard(
      onTap: () => AppNav.cardioGoalDetails(context, goal.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md)),
            child: Icon(goalMetricIcon(goal.metric), color: c.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(goal.title, style: SxText.headlineSm.copyWith(color: c.textHigh), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text('${goalPeriodLabel(goal.period)} • ${goalMetricLabel(goal.metric)}', style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
          SxIconButton(icon: Icons.more_vert, tooltip: 'Adjust goal', filled: false, onPressed: () => showCardioGoalSheet(context, goal: goal)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(goalNumber(goal.metric, value), style: SxText.metricLg.copyWith(color: c.textHigh)),
                Text(' / ${goalNumber(goal.metric, goal.target)} ${goalMetricUnit(goal.metric)}', style: SxText.metricSm.copyWith(color: c.textBody)),
              ]),
            ),
          ),
          Text('${(frac * 100).toStringAsFixed(frac * 100 == (frac * 100).roundToDouble() ? 0 : 1)}%', style: SxText.labelCaps.copyWith(color: c.primary)),
        ]),
        const SizedBox(height: 10),
        if (isFreq)
          Row(children: [
            for (var i = 0; i < goal.target.round().clamp(0, 10); i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i < value ? c.primary : c.surface3),
                  child: i < value ? Icon(Icons.check, size: 14, color: c.onPrimary) : null,
                ),
              ),
          ])
        else
          SxLinearMeter(value: frac, height: 8),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
            child: Text(remaining <= 0 ? 'Target met' : '${goalNumber(goal.metric, remaining.toDouble())} ${goalMetricUnit(goal.metric).toLowerCase()} remaining',
                style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(isFreq ? '$left day${left == 1 ? '' : 's'} left' : '$inPeriod session${inPeriod == 1 ? '' : 's'} logged',
                style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10), overflow: TextOverflow.ellipsis),
          ),
        ]),
      ]),
    );
  }
}
