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
import 'cardio_progress_view.dart';
import 'progress_period.dart';

/// Progress tab root: Strength / Cardio switch + period selector.
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  int _mode = 0; // 0 strength, 1 cardio
  ProgressPeriod _period = ProgressPeriod.week;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    return ListenableBuilder(
      listenable: app.profile,
      builder: (context, _) => Scaffold(
        backgroundColor: c.canvas,
        appBar: SxBrandBar(name: app.profile.profile.name, onAvatarTap: () => AppNav.switchTab(context, 3)),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SxSpace.maxContentWidth),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(SxSpace.md, 4, SxSpace.md, 8),
                child: Row(children: [
                  Expanded(child: Text('Progress', style: SxText.headlineLg.copyWith(color: c.textHigh))),
                  if (_mode == 0) _PeriodMenu(period: _period, onChanged: (p) => setState(() => _period = p)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SxSpace.md),
                child: SxSegmented(
                  labels: const ['Strength', 'Cardio'],
                  icons: const [Icons.fitness_center, Icons.directions_run],
                  index: _mode,
                  onChanged: (i) => setState(() => _mode = i),
                ),
              ),
              if (_mode == 1)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SxChipRow(
                    labels: [for (final p in ProgressPeriod.values) p.chipLabel],
                    selectedIndex: _period.index,
                    onSelected: (i) => setState(() => _period = ProgressPeriod.values[i]),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: SxMotion.base,
                  child: _mode == 0
                      ? _StrengthView(key: const ValueKey('s'), period: _period)
                      : CardioProgressView(key: const ValueKey('c'), period: _period),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PeriodMenu extends StatelessWidget {
  const _PeriodMenu({required this.period, required this.onChanged});
  final ProgressPeriod period;
  final ValueChanged<ProgressPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return PopupMenuButton<ProgressPeriod>(
      tooltip: 'Change period',
      color: c.surface3,
      onSelected: onChanged,
      itemBuilder: (_) => [for (final p in ProgressPeriod.values) PopupMenuItem(value: p, child: Text(p.label))],
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.base), border: Border.all(color: c.hairline)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(period.label.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textHigh)),
          const SizedBox(width: 4),
          Icon(Icons.expand_more, size: 18, color: c.textBody),
        ]),
      ),
    );
  }
}

class _StrengthView extends StatelessWidget {
  const _StrengthView({super.key, required this.period});
  final ProgressPeriod period;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.sessions, app.exercises, app.profile]),
      builder: (context, _) {
        final profile = app.profile.profile;
        final unit = profile.unit;
        final all = app.sessions.sessions;
        if (all.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: EmptyState(
                icon: Icons.insights,
                title: 'No training data yet',
                message: 'Finish your first workout and your volume, PRs and muscle balance will show up here.',
                actionLabel: 'Go to workouts',
                onAction: () => AppNav.switchTab(context, 1),
              ),
            ),
          );
        }
        final now = DateTime.now();
        final w = windowFor(period, now);
        final prevW = comparablePreviousWindow(period, w, now);
        final inW = all.where((s) => w.contains(s.workoutDate)).toList();
        final inPrev = prevW == null ? <WorkoutSession>[] : all.where((s) => prevW.contains(s.workoutDate)).toList();
        final volume = VolumeService.totalVolume(inW);
        final prevVolume = VolumeService.totalVolume(inPrev);
        final sets = VolumeService.totalSets(inW);
        final newPrs = PrService.setBetween(all, w.from, w.to);
        final catalog = app.exercises.all;

        final target = profile.weeklySessionTarget;
        final ahead = inW.length - target;

        final children = <Widget>[
          StretchRow(children: [
            Expanded(
              child: StatTile(
                label: 'Workouts',
                icon: Icons.fitness_center,
                value: '${inW.length}',
                unit: period == ProgressPeriod.week ? '/ $target target' : 'sessions',
                caption: period == ProgressPeriod.week ? (ahead >= 0 ? (ahead == 0 ? 'On target' : '+$ahead ahead') : '${-ahead} to go') : null,
                accent: period == ProgressPeriod.week && ahead >= 0,
                height: 112,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatTile(
                label: 'Total volume',
                icon: Icons.scale_outlined,
                value: Fmt.number(Fmt.toDisplayWeight(volume, unit) / 1000),
                unit: 't',
                caption: prevVolume > 0 ? '${volume >= prevVolume ? '+' : ''}${((volume - prevVolume) / prevVolume * 100).round()}% vs previous' : null,
                height: 112,
              ),
            ),
          ]),
          StretchRow(children: [
            Expanded(child: StatTile(label: 'Sets hit', icon: Icons.checklist, value: '$sets', unit: 'sets', height: 112)),
            const SizedBox(width: 8),
            Expanded(
              child: StatTile(label: 'New PRs', icon: Icons.emoji_events_outlined, value: '${newPrs.length}', unit: 'records', accent: newPrs.isNotEmpty, height: 112),
            ),
          ]),
        ];

        if (inW.isEmpty) {
          children.add(SxCard(
            child: Row(children: [
              Icon(Icons.info_outline, color: c.textBody),
              const SizedBox(width: 12),
              Expanded(child: Text('No workouts logged in this period.', style: SxText.bodyMd.copyWith(color: c.textBody))),
            ]),
          ));
        } else {
          children.addAll(_strengthDelta(context, all, inW, w, newPrs, catalog, unit));
          children.addAll(_muscleDose(context, inW, w, catalog));
        }
        children.addAll(_prFeed(context, all, catalog, unit));
        final insight = inW.isEmpty ? null : _insight(inW, catalog);
        if (insight != null) children.add(_InsightCard(text: insight));

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.lg),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(height: SxSpace.md),
          itemBuilder: (_, i) => children[i],
        );
      },
    );
  }

  List<Widget> _strengthDelta(BuildContext context, List<WorkoutSession> all, List<WorkoutSession> inW, PeriodWindow w, List<StrengthPr> newPrs, List<Exercise> catalog, WeightUnit unit) {
    final c = context.sx;
    final byId = {for (final e in catalog) e.id: e};
    final prIds = {for (final p in newPrs) p.exerciseId};
    double topOf(WorkoutSession s, String id) {
      var best = 0.0;
      for (final l in s.exercises.where((l) => l.exerciseId == id)) {
        for (final st in l.doneSets) {
          if (st.weightKg > best) best = st.weightKg;
        }
      }
      return best;
    }

    final ids = {for (final s in inW) for (final l in s.exercises) l.exerciseId};
    final rows = <({String id, double from, double to})>[];
    for (final id in ids) {
      final within = inW.where((s) => s.exercises.any((l) => l.exerciseId == id && l.doneSets.isNotEmpty)).toList()
        ..sort((a, b) => a.workoutDate.compareTo(b.workoutDate));
      if (within.isEmpty) continue;
      final before = all.where((s) => s.workoutDate.isBefore(w.from) && s.exercises.any((l) => l.exerciseId == id && l.doneSets.isNotEmpty)).toList()
        ..sort((a, b) => b.workoutDate.compareTo(a.workoutDate));
      final from = before.isNotEmpty ? topOf(before.first, id) : topOf(within.first, id);
      final to = topOf(within.last, id);
      if (from > 0 && to > from) rows.add((id: id, from: from, to: to));
    }
    rows.sort((a, b) => ((b.to - b.from) / b.from).compareTo((a.to - a.from) / a.from));
    final top = rows.take(3).toList();
    if (top.isEmpty) return const [];
    final u = Fmt.unit(unit);
    return [
      SectionHeader('Strength delta', icon: Icons.show_chart, trailingText: '${top.length} top lifts'),
      Column(children: [
        for (final r in top)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SxCard(
              onTap: () => AppNav.exerciseHistory(context, r.id),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(byId[r.id]?.name ?? r.id, overflow: TextOverflow.ellipsis, style: SxText.headlineSm.copyWith(color: c.textHigh))),
                      if (prIds.contains(r.id)) ...[const SizedBox(width: 6), const PrBadge()],
                    ]),
                    const SizedBox(height: 4),
                    Text.rich(TextSpan(children: [
                      TextSpan(text: '${Fmt.weight(r.from, unit)} $u', style: SxText.metricMd.copyWith(color: c.textMuted, decoration: TextDecoration.lineThrough, fontSize: 16)),
                      TextSpan(text: '  →  ', style: SxText.metricMd.copyWith(color: c.textBody, fontSize: 16)),
                      TextSpan(text: '${Fmt.weight(r.to, unit)} $u', style: SxText.metricMd.copyWith(color: c.primary, fontSize: 16)),
                    ])),
                  ]),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('+${((r.to - r.from) / r.from * 100).round()}%', style: SxText.metricMd.copyWith(color: c.primary)),
                  Text('+${Fmt.weight(r.to - r.from, unit)} $u', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
                ]),
              ]),
            ),
          ),
      ]),
    ];
  }

  List<Widget> _muscleDose(BuildContext context, List<WorkoutSession> inW, PeriodWindow w, List<Exercise> catalog) {
    final c = context.sx;
    final sets = VolumeService.setsByMuscle(inW, catalog);
    final weeks = period == ProgressPeriod.week ? 1.0 : (w.days / 7).clamp(1.0, 520.0);
    final perWeek = period != ProgressPeriod.week;
    return [
      SectionHeader('Muscle volume dose', icon: Icons.equalizer, trailingText: perWeek ? 'AVG SETS / WEEK' : 'SETS THIS WEEK'),
      SxCard(
        child: Column(children: [
          for (final m in MuscleGroup.values)
            Builder(builder: (_) {
              final (min, max) = VolumeService.weeklyRange(m);
              final v = (sets[m] ?? 0) / weeks;
              final shown = perWeek ? v.toStringAsFixed(1) : v.round().toString();
              final (label, color) = v > max
                  ? ('High', c.danger)
                  : v >= min
                      ? ('Optimal', c.primary)
                      : v >= min * 0.75
                          ? ('Approaching', c.textBody)
                          : (v == 0 ? 'None' : 'Low', c.textMuted);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  Row(children: [
                    Text(m.label, style: SxText.bodyMd.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.sm)),
                      child: Text(label.toUpperCase(), style: SxText.labelCaps.copyWith(fontSize: 9, color: color)),
                    ),
                    const Spacer(),
                    Text(shown, style: SxText.metricMd.copyWith(color: color == c.primary ? c.primary : c.textHigh)),
                    Text(' / $min-$max sets', style: SxText.bodySm.copyWith(color: c.textBody)),
                  ]),
                  const SizedBox(height: 6),
                  SxLinearMeter(value: v / max, height: 6, color: color == c.textMuted ? c.textBody : color),
                ]),
              );
            }),
        ]),
      ),
    ];
  }

  List<Widget> _prFeed(BuildContext context, List<WorkoutSession> all, List<Exercise> catalog, WeightUnit unit) {
    final c = context.sx;
    final byId = {for (final e in catalog) e.id: e};
    final prs = PrService.all(PrType.estimated1Rm, all).take(3).toList();
    if (prs.isEmpty) return const [];
    return [
      SectionHeader('Recent PR milestones', icon: Icons.verified_outlined, trailingText: 'VIEW ALL', onTrailingTap: () => AppNav.personalRecords(context)),
      Column(children: [
        for (final p in prs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SxCard(
              onTap: () => AppNav.exerciseDetails(context, p.exerciseId),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(Fmt.relativeDay(p.date).toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
                      const SizedBox(width: 8),
                      if (p.delta != null) const PrBadge('New PR'),
                    ]),
                    const SizedBox(height: 4),
                    Text(byId[p.exerciseId]?.name ?? p.exerciseId, overflow: TextOverflow.ellipsis, style: SxText.headlineSm.copyWith(color: c.textHigh)),
                    Text(Fmt.setLabel(p.weightKg, p.reps, unit), style: SxText.metricMd.copyWith(color: c.primary, fontSize: 16)),
                  ]),
                ),
                SxInset(
                  padding: const EdgeInsets.all(10),
                  child: Column(children: [
                    Text('EST. 1RM', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 9)),
                    Text(Fmt.weight(p.value, unit), style: SxText.metricMd.copyWith(color: c.textHigh)),
                    Text(Fmt.unit(unit), style: SxText.bodySm.copyWith(color: c.textBody)),
                  ]),
                ),
              ]),
            ),
          ),
      ]),
    ];
  }

  /// Push/pull balance — only when computable from logged sets.
  String? _insight(List<WorkoutSession> inW, List<Exercise> catalog) {
    final m = VolumeService.setsByMuscle(inW, catalog);
    final pull = (m[MuscleGroup.back] ?? 0) + (m[MuscleGroup.biceps] ?? 0);
    final push = (m[MuscleGroup.chest] ?? 0) + (m[MuscleGroup.shoulders] ?? 0) + (m[MuscleGroup.triceps] ?? 0);
    if (pull == 0 || push == 0) return null;
    final ratio = pull / push;
    final tag = (ratio >= 0.8 && ratio <= 1.25) ? 'Balanced.' : (ratio > 1.25 ? 'Pull-dominant.' : 'Push-dominant.');
    return 'Pulling volume is $pull sets vs $push pushing sets (${ratio.toStringAsFixed(1)} : 1). $tag';
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      color: c.surface2,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(SxRadius.md)),
          child: Icon(Icons.psychology_outlined, color: c.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Analytical insight', style: SxText.headlineSm.copyWith(color: c.textHigh)),
            const SizedBox(height: 4),
            Text(text, style: SxText.bodyMd.copyWith(color: c.textBody)),
          ]),
        ),
      ]),
    );
  }
}
