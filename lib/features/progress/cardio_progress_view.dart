import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import '../exercises/exercise_widgets.dart';
import 'progress_period.dart';

/// Body-only cardio analytics (hosted by the Progress tab).
/// Heart-rate zones, GPS and sensors are not in the data model → omitted.
class CardioProgressView extends StatelessWidget {
  const CardioProgressView({super.key, this.period = ProgressPeriod.week});
  final ProgressPeriod period;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.cardio, app.profile]),
      builder: (context, _) {
        final all = app.cardio.sessions;
        final miles = !app.profile.profile.cardioDistanceUnitKm;
        if (all.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: EmptyState(
                icon: Icons.directions_run,
                eyebrow: 'Cardio engine',
                title: 'No cardio recorded yet',
                message: 'Log a run, ride or treadmill session to see weekly duration, distance and personal bests.',
                actionLabel: 'Start cardio session',
                onAction: () => AppNav.selectCardioActivity(context),
                secondaryLabel: 'Log past session',
                onSecondary: () => AppNav.backdateCardio(context),
              ),
            ),
          );
        }
        final now = DateTime.now();
        final w = windowFor(period, now);
        final prevW = comparablePreviousWindow(period, w, now);
        final inW = all.where((s) => w.contains(s.workoutDate)).toList();
        final inPrev = prevW == null ? <CardioSession>[] : all.where((s) => prevW.contains(s.workoutDate)).toList();
        final minutes = VolumeService.cardioMinutes(inW);
        final km = VolumeService.cardioKm(inW);
        final prevKm = VolumeService.cardioKm(inPrev);
        final kcal = inW.fold(0, (a, s) => a + (s.calories ?? 0));
        final hrs = inW.where((s) => s.avgHeartRate != null).toList();
        final avgHr = hrs.isEmpty ? null : hrs.fold(0, (a, s) => a + s.avgHeartRate!) ~/ hrs.length;
        final weeklyGoal = app.cardio.goals.where((g) => g.metric == GoalMetric.durationMinutes && g.period == GoalPeriod.week).firstOrNull;
        final prs = PrService.cardio(all);
        final recent = all.first;

        final children = <Widget>[
          _DurationCard(sessions: inW, period: period, window: w, minutes: minutes, goalMinutes: weeklyGoal?.target.round()),
          StretchRow(children: [
            Expanded(
              child: StatTile(
                label: 'Distance',
                icon: Icons.route,
                value: Fmt.number(miles ? km * 0.621371 : km),
                unit: miles ? 'mi' : 'km',
                caption: prevKm > 0 ? '${km >= prevKm ? '+' : ''}${((km - prevKm) / prevKm * 100).round()}% vs previous' : null,
                height: 104,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: StatTile(label: 'Sessions', icon: Icons.timer_outlined, value: '${inW.length}', unit: 'workouts', height: 104)),
          ]),
          if (kcal > 0 || avgHr != null)
            StretchRow(children: [
              if (kcal > 0) Expanded(child: StatTile(label: 'Energy burn', icon: Icons.local_fire_department_outlined, value: Fmt.thousands(kcal), unit: 'kcal', height: 104)),
              if (kcal > 0 && avgHr != null) const SizedBox(width: 8),
              if (avgHr != null) Expanded(child: StatTile(label: 'Avg heart rate', icon: Icons.favorite_border, value: '$avgHr', unit: 'BPM', height: 104)),
            ]),
          SxCard(
            onTap: () => AppNav.cardioDetails(context, recent.id),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md)),
                child: Icon(Icons.directions_run, color: c.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('RECENT SESSION', style: SxText.labelCaps.copyWith(color: c.primary, fontSize: 10)),
                  Text(recent.kind.label, style: SxText.headlineSm.copyWith(color: c.textHigh)),
                  Text('${Fmt.durationShort(recent.durationSeconds)}${recent.distanceKm != null ? ' · ${Fmt.km(miles ? recent.distanceKm! * 0.621371 : recent.distanceKm)} ${miles ? 'mi' : 'km'}' : ''}',
                      style: SxText.bodySm.copyWith(color: c.textBody)),
                ]),
              ),
              StatusPill(Fmt.dateShort(recent.workoutDate), color: c.textBody),
            ]),
          ),
          if (prs.isNotEmpty) _Milestones(prs: prs, sessions: all, miles: miles),
          SxButton(label: 'Log aerobic workout', icon: Icons.add_circle_outline, onPressed: () => AppNav.selectCardioActivity(context)),
        ];
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.lg),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(height: SxSpace.md),
          itemBuilder: (_, i) => children[i],
        );
      },
    );
  }
}

class _Bucket {
  _Bucket(this.label, this.minutes);
  final String label;
  final int minutes;
}

class _DurationCard extends StatelessWidget {
  const _DurationCard({required this.sessions, required this.period, required this.window, required this.minutes, required this.goalMinutes});
  final List<CardioSession> sessions;
  final ProgressPeriod period;
  final PeriodWindow window;
  final int minutes;
  final int? goalMinutes;

  List<_Bucket> _buckets() {
    int sum(Iterable<CardioSession> s) => s.fold(0, (a, c) => a + c.durationSeconds) ~/ 60;
    switch (period) {
      case ProgressPeriod.week:
        return [
          for (var i = 0; i < 7; i++)
            _Bucket(Fmt.dayShort(i + 1).substring(0, 1), sum(sessions.where((s) => s.workoutDate.weekday == i + 1))),
        ];
      case ProgressPeriod.month:
      case ProgressPeriod.threeMonths:
        final weeks = <DateTime>[];
        var d = VolumeService.startOfWeek(window.from);
        while (d.isBefore(window.to)) {
          weeks.add(d);
          d = DateTime(d.year, d.month, d.day + 7);
        }
        return [
          for (final ws in weeks)
            _Bucket(weeks.length > 6 ? '' : '${ws.month}/${ws.day}', sum(sessions.where((s) {
              final e = DateTime(ws.year, ws.month, ws.day + 7);
              return !s.workoutDate.isBefore(ws) && s.workoutDate.isBefore(e);
            }))),
        ];
      case ProgressPeriod.year:
      case ProgressPeriod.all:
        final now = DateTime.now();
        return [
          for (var i = 11; i >= 0; i--)
            _monthBucket(i, now, sessions, sum),
        ];
    }
  }

  _Bucket _monthBucket(int back, DateTime now, List<CardioSession> s, int Function(Iterable<CardioSession>) sum) {
    final m = DateTime(now.year, now.month - back);
    return _Bucket(Fmt.monthShort(m.month).substring(0, 1), sum(s.where((x) => x.workoutDate.year == m.year && x.workoutDate.month == m.month)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final buckets = _buckets();
    final weekly = period == ProgressPeriod.week;
    final showTarget = goalMinutes != null && (weekly || period == ProgressPeriod.month || period == ProgressPeriod.threeMonths);
    final met = weekly && goalMinutes != null && minutes >= goalMinutes!;
    final title = switch (period) {
      ProgressPeriod.week => 'Weekly aerobic duration',
      ProgressPeriod.month => 'Aerobic duration · weekly',
      ProgressPeriod.threeMonths => 'Aerobic duration · weekly',
      _ => 'Aerobic duration · monthly',
    };
    final hours = minutes ~/ 60, mins = minutes % 60;
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(title.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody))),
          if (met) StatusPill('Goal met (${(minutes * 100 / goalMinutes!).round()}%)', icon: Icons.check_circle_outline),
        ]),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(hours > 0 ? '${hours}h ${mins}m' : '${mins}m', style: SxText.metricLg.copyWith(color: c.textHigh)),
          if (weekly && goalMinutes != null) Text('  / $goalMinutes min', style: SxText.bodySm.copyWith(color: c.textBody)),
        ]),
        const SizedBox(height: 12),
        SxBarChart(
          values: [for (final b in buckets) b.minutes.toDouble()],
          labels: [for (final b in buckets) b.label],
          target: showTarget ? goalMinutes!.toDouble() : null,
          valueLabels: buckets.length <= 8 ? [for (final b in buckets) b.minutes > 0 ? '${b.minutes}m' : ''] : null,
          highlightIndex: weekly ? DateTime.now().weekday - 1 : null,
          height: 150,
        ),
        if (showTarget) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('TARGET: $goalMinutes MIN / WEEK', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10))),
            if (weekly)
              Text(minutes >= goalMinutes! ? '+${minutes - goalMinutes!} MIN SURPLUS' : '${goalMinutes! - minutes} MIN TO GO', style: SxText.labelCaps.copyWith(color: minutes >= goalMinutes! ? c.primary : c.textBody, fontSize: 10)),
          ]),
        ],
      ]),
    );
  }
}

class _Milestones extends StatelessWidget {
  const _Milestones({required this.prs, required this.sessions, required this.miles});
  final List<CardioPr> prs;
  final List<CardioSession> sessions;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    String title(CardioPrType t) => switch (t) {
          CardioPrType.longestDuration => 'Longest session',
          CardioPrType.longestDistance => 'Longest distance',
          CardioPrType.fastestPace => 'Fastest pace',
        };
    String value(CardioPr p) => switch (p.type) {
          CardioPrType.longestDuration => Fmt.durationShort(p.value.round()),
          CardioPrType.longestDistance => '${Fmt.number(miles ? p.value * 0.621371 : p.value)} ${miles ? 'mi' : 'km'}',
          CardioPrType.fastestPace => '${Fmt.pace(miles ? p.value * 1.609344 : p.value)} /${miles ? 'mi' : 'km'}',
        };
    IconData icon(CardioPrType t) => switch (t) {
          CardioPrType.longestDuration => Icons.hourglass_top,
          CardioPrType.longestDistance => Icons.straighten,
          CardioPrType.fastestPace => Icons.speed,
        };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader('Cardio milestones', icon: Icons.military_tech_outlined, trailingText: 'ALL-TIME BESTS'),
      const SizedBox(height: 8),
      SxCard(
        child: Column(children: [
          for (var i = 0; i < prs.length; i++) ...[
            if (i > 0) Divider(height: 16, color: c.hairline),
            InkWell(
              onTap: () => AppNav.cardioDetails(context, prs[i].sessionId),
              borderRadius: BorderRadius.circular(SxRadius.base),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
                    child: Icon(icon(prs[i].type), size: 18, color: c.textBody),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title(prs[i].type), style: SxText.bodyMd.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
                      Text('${prs[i].kindLabel} · ${Fmt.dateShort(prs[i].date)}', style: SxText.bodySm.copyWith(color: c.textBody)),
                    ]),
                  ),
                  Text(value(prs[i]), style: SxText.metricMd.copyWith(color: c.primary)),
                ]),
              ),
            ),
          ],
        ]),
      ),
    ]);
  }
}
