import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import '../exercises/exercise_stats.dart';

const _typeLabels = ['All', 'Heaviest Weight', 'Most Reps', 'Est. max', 'Highest Volume'];
const _types = [PrType.estimated1Rm, PrType.heaviestWeight, PrType.mostReps, PrType.estimated1Rm, PrType.highestVolume];
/// Filter chips derive from the domain taxonomy: "All" + every [MuscleGroup].
final _muscleLabels = ['All', for (final m in MuscleGroup.values) m.label];

bool _inCategory(int i, MuscleGroup m) => i == 0 || MuscleGroup.values[i - 1] == m;

/// Personal records board: strength PRs by type, with Epley-estimated 1RM.
class PersonalRecordsPage extends StatefulWidget {
  const PersonalRecordsPage({super.key});

  @override
  State<PersonalRecordsPage> createState() => _PersonalRecordsPageState();
}

class _PersonalRecordsPageState extends State<PersonalRecordsPage> {
  int _type = 0;
  int _muscle = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.sessions, app.exercises, app.profile]),
      builder: (context, _) {
        final unit = app.profile.profile.unit;
        final u = Fmt.unit(unit);
        final sessions = app.sessions.sessions;
        final byId = {for (final e in app.exercises.all) e.id: e};
        const topBar = SxTopBar(title: 'Personal Records', showLogo: true);

        if (sessions.isEmpty) {
          return const SxScaffold(
            topBar: topBar,
            children: [
              EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No records yet',
                message: 'Personal records are calculated from your logged sets. Complete a workout to set your first one.',
              ),
            ],
          );
        }

        final hero = PrService.all(PrType.estimated1Rm, sessions).firstOrNull;
        final prs = PrService.all(_types[_type], sessions).where((p) {
          final m = byId[p.exerciseId]?.primaryMuscle;
          return m != null && _inCategory(_muscle, m);
        }).toList();

        final children = <Widget>[
          if (hero != null) _Hero(pr: hero, name: byId[hero.exerciseId]?.name ?? hero.exerciseId, sessions: sessions, unit: unit),
          SxChipRow(padding: EdgeInsets.zero, labels: _typeLabels, selectedIndex: _type, onSelected: (i) => setState(() => _type = i)),
          SxChipRow(padding: EdgeInsets.zero, labels: _muscleLabels, selectedIndex: _muscle, onSelected: (i) => setState(() => _muscle = i)),
          if (prs.isEmpty)
            const EmptyState(icon: Icons.filter_alt_off_outlined, title: 'No records here', message: 'No logged exercises match this filter yet.')
          else
            for (final (i, p) in prs.indexed)
              SxStagger(
                key: ValueKey('${_types[_type].name}-${p.exerciseId}'),
                index: i,
                child: _PrCard(
                  pr: p,
                  exercise: byId[p.exerciseId],
                  type: _types[_type],
                  unit: unit,
                  onTap: () => AppNav.exerciseHistory(context, p.exerciseId),
                ),
              ),
        ];

        return SxScaffold(
          topBar: topBar,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Personal Records', style: SxText.headlineLg.copyWith(color: c.textHigh)),
              Text('Milestones & maximal strength  ·  $u', style: SxText.bodyMd.copyWith(color: c.textBody)),
            ]),
            ...children,
          ],
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.pr, required this.name, required this.sessions, required this.unit});
  final StrengthPr pr;
  final String name;
  final List<WorkoutSession> sessions;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final series = [for (final s in statsFor(pr.exerciseId, sessions)) Fmt.toDisplayWeight(s.e1rm, unit)];
    final pct = pr.previousValue != null && pr.previousValue! > 0 ? (pr.value - pr.previousValue!) / pr.previousValue! * 100 : null;
    return SxCard(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.analytics_outlined, size: 16, color: c.textBody),
          const SizedBox(width: 6),
          Expanded(child: Text('ESTIMATED ONE-REP MAX', maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody))),
        ]),
        const SizedBox(height: 4),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.headlineSm.copyWith(color: c.textHigh)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisSize: MainAxisSize.min, children: [
            SxCountUp(value: pr.value, formatter: (v) => Fmt.weight(v, unit), style: SxText.metricXl.copyWith(color: c.primary, fontSize: 56)),
            const SizedBox(width: 6),
            Text(Fmt.unit(unit), style: SxText.headlineMd.copyWith(color: c.textBody)),
          ]),
        ),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Text('Based on your best set: ${Fmt.setLabel(pr.weightKg, pr.reps, unit)}', style: SxText.bodySm.copyWith(color: c.textBody))),
          if (pct != null) DeltaBadge('${pct.toStringAsFixed(1)}%', positive: pct >= 0),
          const SizedBox(width: 8),
          if (series.length > 1) SxSparkline(values: series),
        ]),
        const SizedBox(height: 12),
        SxInset(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Icon(Icons.functions, color: c.textBody),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('HOW IT IS CALCULATED', style: SxText.labelXs.copyWith(color: c.textBody)),
                Text('Epley: W × (1 + R / 30)', style: SxText.metricSm.copyWith(color: c.textHigh)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.info_outline, size: 14, color: c.textMuted),
          const SizedBox(width: 6),
          Expanded(child: Text('An estimate from your logged sets, not a tested one-rep max.', style: SxText.bodySm.copyWith(color: c.textBody))),
        ]),
      ]),
    );
  }
}

class _PrCard extends StatelessWidget {
  const _PrCard({required this.pr, required this.exercise, required this.type, required this.unit, required this.onTap});
  final StrengthPr pr;
  final Exercise? exercise;
  final PrType type;
  final WeightUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final u = Fmt.unit(unit);
    final recent = DateTime.now().difference(pr.date).inDays <= 14;
    final delta = pr.delta;
    String? badge;
    if (delta != null && delta > 0 && recent) {
      badge = switch (type) {
        PrType.mostReps => 'Rep PR +${delta.round()}',
        PrType.highestVolume => 'Volume record',
        _ => 'New PR +${Fmt.weight(delta, unit)}$u',
      };
    }
    final peakLabel = type == PrType.highestVolume ? 'Session volume' : 'Peak performance';
    return SxCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exercise?.name ?? pr.exerciseId, style: SxText.headlineSm.copyWith(color: c.textHigh)),
              const SizedBox(height: 2),
              Text('Set ${Fmt.dateMedium(pr.date)}', style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
          if (exercise != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(SxRadius.sm)),
                child: Text(exercise!.primaryMuscle.label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelXs.copyWith(color: c.textBody)),
              ),
            ),
          ],
          if (badge != null) ...[const SizedBox(width: 8), Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: SxPop(child: PrBadge(badge))))],
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: SxInset(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(peakLabel.toUpperCase(), style: SxText.labelXs.copyWith(color: c.textBody)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: type == PrType.highestVolume
                      ? MetricValue(Fmt.thousands(Fmt.toDisplayWeight(pr.value, unit)), unit: u)
                      : MetricValue(Fmt.weight(pr.weightKg, unit), unit: '$u × ${pr.reps}'),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SxInset(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ESTIMATED MAX', style: SxText.labelXs.copyWith(color: c.textBody)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: () {
                    // estimateOneRepMax is 0 above 12 reps: show a dash, never "0".
                    final e1 = estimateOneRepMax(pr.weightKg, pr.reps);
                    return e1 > 0
                        ? MetricValue(Fmt.weight(e1, unit), unit: u, color: c.primary)
                        : MetricValue('—', color: c.textMuted);
                  }(),
                ),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}
