import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'cardio_delete_dialog.dart';
import 'cardio_home_support.dart';

/// Body of the Cardio side of the Workouts tab. No Scaffold / bottom nav: it is
/// hosted by the Workouts hub. Scrolls inside the host's scroll view if given
/// bounded height, otherwise provides its own ListView via [shrinkWrap].
class CardioHomeView extends StatefulWidget {
  const CardioHomeView({super.key});

  @override
  State<CardioHomeView> createState() => _CardioHomeViewState();
}

class _CardioHomeViewState extends State<CardioHomeView> {
  static const _quick = [
    CardioKind.outdoorRun,
    CardioKind.treadmill,
    CardioKind.cycling,
    CardioKind.rowing,
    CardioKind.stairClimber,
    CardioKind.jumpRope,
  ];
  CardioKind _kind = CardioKind.outdoorRun;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.cardio, app.profile]),
      builder: (context, _) {
        final sessions = app.cardio.sessions;
        final miles = !app.profile.profile.cardioDistanceUnitKm;
        final goal = weeklyDurationGoal(app.cardio.goals);
        final children = <Widget>[
          if (sessions.isEmpty)
            _EmptyHero(kind: _kind, onKind: (k) => setState(() => _kind = k), goal: goal)
          else ...[
            _QuickStart(kind: _kind, kinds: _quick, onKind: (k) => setState(() => _kind = k)),
            _WeekCard(sessions: sessions, goal: goal, miles: miles),
            if (goal != null) _WeeklyGoalCard(sessions: sessions, goal: goal) else const _NoGoalCard(),
            _VolumeInsight(sessions: sessions),
            SectionHeader('Recent cardio',
                icon: Icons.history, trailingText: 'VIEW ALL', onTrailingTap: () => AppNav.cardioHistory(context)),
            for (final s in sessions.take(3)) _RecentCard(session: s, miles: miles),
          ],
          SxButton(
            label: 'Custom Cardio Activity',
            icon: Icons.add_circle_outline,
            variant: SxButtonVariant.secondary,
            onPressed: () => AppNav.createCustomCardio(context),
          ),
        ];
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(SxSpace.screenMargin, SxSpace.sm, SxSpace.screenMargin, SxSpace.lg),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(height: SxSpace.md),
          itemBuilder: (_, i) => children[i],
        );
      },
    );
  }
}

class _QuickStart extends StatelessWidget {
  const _QuickStart({required this.kind, required this.kinds, required this.onKind});
  final CardioKind kind;
  final List<CardioKind> kinds;
  final ValueChanged<CardioKind> onKind;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CARDIO ENGINE', style: SxText.labelCaps.copyWith(color: c.primary)),
              const SizedBox(height: 2),
              Text('Quick Start', style: SxText.headlineLg.copyWith(color: c.textHigh)),
            ]),
          ),
          SxIconButton(icon: Icons.apps, tooltip: 'All activities', onPressed: () => AppNav.selectCardioActivity(context)),
        ]),
        const SizedBox(height: SxSpace.md),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kinds.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => SxChip(
                label: kinds[i].label, icon: cardioKindIcon(kinds[i]), selected: kinds[i] == kind, onTap: () => onKind(kinds[i])),
          ),
        ),
        const SizedBox(height: SxSpace.md),
        SxButton(label: 'Start cardio', icon: Icons.play_arrow, onPressed: () => AppNav.cardioPrepare(context, kind)),
      ]),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.sessions, required this.goal, required this.miles});
  final List<CardioSession> sessions;
  final CardioGoal? goal;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final now = DateTime.now();
    final w = cardioWeek(now);
    final week = VolumeService.cardioIn(sessions, w.from, w.to);
    final minutes = VolumeService.cardioMinutes(week);
    final km = VolumeService.cardioKm(week);
    final kcal = week.fold<int>(0, (a, s) => a + (s.calories ?? 0));
    // "On track" is derived from the weekly goal and the day of the week.
    String? status;
    if (goal != null && goal!.target > 0) {
      final expected = goal!.target * (now.weekday / 7);
      status = minutes >= goal!.target ? 'GOAL MET' : (minutes >= expected * 0.8 ? 'ON TRACK' : 'BEHIND');
    }
    final tiles = <Widget>[
      _MiniStat('Sessions', '${week.length}'),
      _MiniStat('Time', Fmt.durationShort(minutes * 60)),
      _MiniStat('Dist', Fmt.km(km, miles: miles), miles ? 'mi' : 'km'),
      if (kcal > 0) _MiniStat('Energy', Fmt.thousands(kcal), 'kcal', true),
    ];
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.equalizer, size: 18, color: c.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('THIS WEEK', style: SxText.labelCaps.copyWith(color: c.textBody, letterSpacing: 1.2))),
          if (status != null) StatusPill(status, color: status == 'BEHIND' ? c.danger : c.primary),
        ]),
        const SizedBox(height: SxSpace.md),
        LayoutBuilder(builder: (context, cons) {
          final cols = cons.maxWidth < 300 ? 2 : tiles.length;
          final gap = 8.0;
          final width = (cons.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(spacing: gap, runSpacing: gap, children: [for (final t in tiles) SizedBox(width: width, child: t)]);
        }),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, [this.unit, this.accent = false]);
  final String label;
  final String value;
  final String? unit;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxInset(
      padding: const EdgeInsets.all(10),
      color: c.surface2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: MetricValue(value, unit: unit, color: accent ? c.primary : c.textHigh),
        ),
      ]),
    );
  }
}

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard({required this.sessions, required this.goal});
  final List<CardioSession> sessions;
  final CardioGoal goal;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final w = cardioWeek(DateTime.now());
    final week = VolumeService.cardioIn(sessions, w.from, w.to);
    final done = CardioMetrics.goalValue(goal, week);
    final pct = goal.target <= 0 ? 0.0 : done / goal.target;
    final remaining = (goal.target - done).clamp(0, double.infinity);
    final days = {for (final s in week) '${s.workoutDate.year}-${s.workoutDate.month}-${s.workoutDate.day}'}.length;
    return SxCard(
      onTap: () => AppNav.cardioGoalDetails(context, goal.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.flag_outlined, size: 18, color: c.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('WEEKLY AEROBIC GOAL', style: SxText.labelCaps.copyWith(color: c.textBody, letterSpacing: 1.2))),
          Text('${(pct * 100).round()}% REACHED', style: SxText.labelCaps.copyWith(color: c.primary)),
        ]),
        const SizedBox(height: SxSpace.sm),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(Fmt.number(done.roundToDouble()), style: SxText.metricXl.copyWith(color: c.textHigh)),
          const SizedBox(width: 6),
          Expanded(child: Text('/ ${Fmt.number(goal.target)} min', style: SxText.bodyLg.copyWith(color: c.textBody))),
          Flexible(
            child: Text(remaining <= 0 ? 'Goal reached' : '${Fmt.number(remaining.roundToDouble())} min remaining',
                textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
          ),
        ]),
        const SizedBox(height: SxSpace.sm),
        SxLinearMeter(value: pct, height: 8),
        const SizedBox(height: SxSpace.sm),
        Row(children: [
          Icon(Icons.schedule, size: 16, color: c.primary),
          const SizedBox(width: 6),
          Expanded(child: Text('$days active ${days == 1 ? 'day' : 'days'} this week', style: SxText.bodySm.copyWith(color: c.textBody))),
        ]),
      ]),
    );
  }
}

class _NoGoalCard extends StatelessWidget {
  const _NoGoalCard();
  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      onTap: () => AppNav.cardioGoals(context),
      child: Row(children: [
        Icon(Icons.flag_outlined, color: c.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Set a weekly aerobic goal', style: SxText.headlineSm.copyWith(color: c.textHigh)),
            Text('Track weekly minutes against a target.', style: SxText.bodySm.copyWith(color: c.textBody)),
          ]),
        ),
        Icon(Icons.chevron_right, color: c.textBody),
      ]),
    );
  }
}

/// Week-over-week change in cardio minutes — shown only when last week has data.
class _VolumeInsight extends StatelessWidget {
  const _VolumeInsight({required this.sessions});
  final List<CardioSession> sessions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tw = cardioWeek(now), lw = cardioWeek(now, offsetWeeks: -1);
    final cur = VolumeService.cardioMinutes(VolumeService.cardioIn(sessions, tw.from, tw.to));
    final prev = VolumeService.cardioMinutes(VolumeService.cardioIn(sessions, lw.from, lw.to));
    if (prev <= 0) return const SizedBox.shrink();
    final pct = ((cur - prev) / prev * 100).round();
    final c = context.sx;
    final up = pct >= 0;
    return SxCard(
      color: c.surface3,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(SxRadius.base)),
          child: Icon(up ? Icons.trending_up : Icons.trending_down, color: up ? c.primary : c.danger),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(up ? 'VOLUME SURGE' : 'VOLUME DIP', style: SxText.labelCaps.copyWith(color: up ? c.primary : c.danger)),
            const SizedBox(height: 4),
            Text('Cardio time is ${up ? 'up' : 'down'} ${pct.abs()}% vs last week (${Fmt.durationShort(cur * 60)} vs ${Fmt.durationShort(prev * 60)}).',
                style: SxText.bodyMd.copyWith(color: c.textHigh)),
          ]),
        ),
      ]),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.session, required this.miles});
  final CardioSession session;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final metrics = cardioSummaryMetrics(session, miles: miles);
    return SxCard(
      onTap: () => AppNav.cardioDetails(context, session.id),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () async {
          final repo = context.app.cardio;
          if (await confirmDeleteCardio(context, session) && context.mounted) {
            await repo.delete(session.id);
            if (context.mounted) showSxSnack(context, 'Session deleted');
          }
        },
        child: Column(children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(SxRadius.md)),
              child: Icon(cardioKindIcon(session.kind), color: c.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(session.kind.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.headlineSm.copyWith(color: c.textHigh)),
                Text('${Fmt.dateShort(session.workoutDate)} • ${Fmt.time(session.workoutDate)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
              ]),
            ),
            if (session.paceSecPerKm != null && session.kind.fields.contains(CardioField.pace))
              StatusPill('${Fmt.pace(session.paceSecPerKm)} /km', icon: Icons.speed),
          ]),
          const SizedBox(height: SxSpace.sm),
          Row(children: [
            for (var i = 0; i < metrics.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: SxInset(
                  color: c.canvas,
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(metrics[i].label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
                    const SizedBox(height: 4),
                    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: MetricValue(metrics[i].value, unit: metrics[i].unit)),
                  ]),
                ),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}

/// Zero state (Stitch "No cardio recorded yet").
class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.kind, required this.onKind, required this.goal});
  final CardioKind kind;
  final ValueChanged<CardioKind> onKind;
  final CardioGoal? goal;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    const dispatch = [CardioKind.outdoorRun, CardioKind.treadmill, CardioKind.cycling, CardioKind.rowing];
    final target = goal?.target ?? 150;
    return Column(children: [
      SxCard(
        child: Column(children: [
          const SizedBox(height: SxSpace.sm),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.xl), border: Border.all(color: c.hairline)),
            child: Icon(Icons.show_chart, size: 32, color: c.primary),
          ),
          const SizedBox(height: SxSpace.md),
          Text('AEROBIC FOUNDATION', style: SxText.labelCaps.copyWith(color: c.primary)),
          const SizedBox(height: 6),
          Text('NO CARDIO RECORDED YET', textAlign: TextAlign.center, style: SxText.headlineMd.copyWith(color: c.textHigh)),
          const SizedBox(height: 8),
          Text('Start your first cardio session to track endurance and build aerobic volume alongside your lifting.',
              textAlign: TextAlign.center, style: SxText.bodyMd.copyWith(color: c.textBody)),
          const SizedBox(height: SxSpace.md),
          Align(alignment: Alignment.centerLeft, child: Text('QUICK START', style: SxText.labelCaps.copyWith(color: c.textBody))),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, cons) {
            final w = (cons.maxWidth - 8) / 2;
            return Wrap(spacing: 8, runSpacing: 8, children: [
              for (final k in dispatch)
                SizedBox(
                  width: w,
                  child: SxInset(
                    onTap: () => onKind(k),
                    borderColor: k == kind ? c.primary : null,
                    child: Row(children: [
                      Icon(cardioKindIcon(k), size: 20, color: c.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(k.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelUi.copyWith(color: c.textHigh))),
                    ]),
                  ),
                ),
            ]);
          }),
          const SizedBox(height: SxSpace.md),
          SxButton(label: 'Start first cardio session', icon: Icons.play_arrow, onPressed: () => AppNav.cardioPrepare(context, kind)),
        ]),
      ),
      const SizedBox(height: SxSpace.md),
      SxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.timer_outlined, color: c.primary),
            const SizedBox(width: 12),
            Expanded(child: Text('NO SESSIONS THIS WEEK', style: SxText.headlineSm.copyWith(color: c.textHigh))),
            StatusPill('0 / ${Fmt.number(target)}m', color: c.textBody),
          ]),
          const SizedBox(height: SxSpace.sm),
          const SxLinearMeter(value: 0),
          const SizedBox(height: SxSpace.sm),
          Text('Your weekly target of ${Fmt.number(target)} minutes is waiting. Log a workout or start a quick session today.',
              style: SxText.bodyMd.copyWith(color: c.textBody)),
          const SizedBox(height: SxSpace.md),
          Row(children: [
            Expanded(
                child: SxButton(
                    label: 'Log past',
                    height: 48,
                    icon: Icons.history,
                    variant: SxButtonVariant.secondary,
                    onPressed: () => AppNav.backdateCardio(context))),
            const SizedBox(width: 8),
            Expanded(
                child: SxButton(
                    label: 'Set target',
                    height: 48,
                    icon: Icons.tune,
                    variant: SxButtonVariant.secondary,
                    onPressed: () => AppNav.cardioGoals(context))),
          ]),
        ]),
      ),
    ]);
  }
}
