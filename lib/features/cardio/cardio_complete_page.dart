import 'package:flutter/material.dart';

import 'cardio_pace.dart';
import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import '../health/health_enrichment_card.dart';
import 'cardio_home_support.dart';

/// Summary shown right after a cardio session is saved (session already
/// persisted by the tracker / backdate flow).
class CardioCompletePage extends StatelessWidget {
  const CardioCompletePage({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.cardio, app.profile]),
      builder: (context, _) {
        final s = app.cardio.byId(sessionId);
        if (s == null) {
          return SxScaffold(
            topBar: const SxTopBar(title: 'Session Summary'),
            body: const Center(child: ErrorState(message: 'This cardio session could not be found. It may have been deleted.')),
          );
        }
        final miles = !app.profile.profile.cardioDistanceUnitKm;
        final all = app.cardio.sessions;
        final custom = _customName(app.cardio, s);
        return SxScaffold(
          topBar: const SxTopBar(title: 'Session Summary', subtitle: 'CARDIO'),
          bottom: Column(mainAxisSize: MainAxisSize.min, children: [
            SxButton(label: 'Done', icon: Icons.check, onPressed: () => AppNav.switchTab(context, 1)),
            const SizedBox(height: 8),
            SxButton(
                label: 'Edit session details',
                icon: Icons.edit_note,
                variant: SxButtonVariant.secondary,
                height: 48,
                onPressed: () => AppNav.editCardio(context, s.id)),
          ]),
          gap: SxSpace.md,
          children: [
            SxStagger(index: 0, child: _Header(session: s, number: all.length - all.indexWhere((x) => x.id == s.id), name: custom ?? s.kind.label)),
            SxStagger(index: 1, child: _Totals(session: s, miles: miles)),
            SxStagger(index: 2, child: _Tiles(session: s, miles: miles)),
            SxStagger(index: 3, child: HealthEnrichmentCard(key: ValueKey('enrich-${s.id}'), sessionId: s.id)),
            SxStagger(index: 3, child: _PrRow(session: s, all: all, miles: miles)),
            SxStagger(index: 4, child: _WeeklyTarget(session: s, repo: app.cardio)),
          ],
        );
      },
    );
  }

  String? _customName(CardioRepository repo, CardioSession s) {
    if (s.customActivityId == null) return null;
    for (final a in repo.customActivities) {
      if (a.id == s.customActivityId) return a.name;
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session, required this.number, required this.name});
  final CardioSession session;
  final int number;
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('SESSION #$number • COMPLETED', style: SxText.labelCaps.copyWith(color: c.primary))),
          Icon(Icons.check_circle_outline, size: 16, color: c.primary),
        ]),
        const SizedBox(height: SxSpace.sm),
        Row(children: [
          // Completion moment: one pop + haptic (no-op scale under reduced motion).
          SxPop(
            haptic: true,
            peak: 1.2,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(SxRadius.md)),
              child: Icon(Icons.done_all, color: c.onAccent, size: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CARDIO COMPLETE', style: SxText.headlineMd.copyWith(color: c.textHigh), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('$name • ${Fmt.dateLong(session.workoutDate)} • ${Fmt.time(session.workoutDate)}',
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
        ]),
        if (session.routeName.isNotEmpty || session.rpe != null) ...[
          const SizedBox(height: SxSpace.sm),
          Divider(height: 1, color: c.hairline),
          const SizedBox(height: SxSpace.sm),
          Row(children: [
            if (session.routeName.isNotEmpty) ...[
              Icon(Icons.near_me_outlined, size: 16, color: c.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(session.routeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.bodyMd.copyWith(color: c.textBody))),
            ] else
              const Spacer(),
            if (session.rpe != null) StatusPill('RPE ${Fmt.number(session.rpe!)}', color: c.textBody),
          ]),
        ],
      ]),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.session, required this.miles});
  final CardioSession session;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final hasDist = session.distanceKm != null;
    return SxCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (hasDist)
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TOTAL DISTANCE', style: SxText.labelCaps.copyWith(color: c.textBody)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  SxCountUp(
                    value: session.distanceKm!,
                    formatter: (v) => Fmt.km(v, miles: miles),
                    style: SxText.metricXl.copyWith(color: c.textHigh),
                  ),
                  const SizedBox(width: 4),
                  Text(miles ? 'MI' : 'KM', style: SxText.bodySm.copyWith(color: c.textBody)),
                ]),
              ),
            ]),
          ),
        Column(crossAxisAlignment: hasDist ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          Text('DURATION', style: SxText.labelCaps.copyWith(color: c.textBody)),
          const SizedBox(height: 6),
          SxCountUp(
            key: const Key('complete-duration'),
            value: session.durationSeconds.toDouble(),
            formatter: (v) => Fmt.clock(v.round()),
            style: (hasDist ? SxText.metricLg : SxText.metricXl).copyWith(color: c.primary),
          ),
        ]),
      ]),
    );
  }
}

/// Only tiles the session actually has data for (adapted to the activity).
class _Tiles extends StatelessWidget {
  const _Tiles({required this.session, required this.miles});
  final CardioSession session;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final f = session.kind.fields;
    final tiles = <Widget>[];
    if (CardioPace.has(session.kind) && session.paceSecPerKm != null) {
      tiles.add(StatTile(label: 'Avg pace', value: CardioPace.text(session.kind, session.paceSecPerKm, miles: miles), unit: CardioPace.unit(session.kind, miles: miles), icon: Icons.speed));
    }
    if (f.contains(CardioField.speed) && session.avgSpeedKmh != null) {
      tiles.add(StatTile(label: 'Avg speed', value: Fmt.number(miles ? session.avgSpeedKmh! * 0.621371 : session.avgSpeedKmh!), unit: miles ? 'mph' : 'km/h', icon: Icons.speed));
    }
    if (session.inclinePct != null) tiles.add(StatTile(label: 'Incline', value: Fmt.number(session.inclinePct!), unit: '%', icon: Icons.landscape_outlined));
    if (session.resistance != null) tiles.add(StatTile(label: 'Resistance', value: '${session.resistance}', unit: 'lvl', icon: Icons.tune));
    if (session.calories != null) tiles.add(StatTile(label: 'Energy', value: Fmt.thousands(session.calories!), unit: 'kcal', icon: Icons.local_fire_department_outlined));
    if (session.avgHeartRate != null) tiles.add(StatTile(label: 'Avg HR', value: '${session.avgHeartRate}', unit: 'bpm', icon: Icons.favorite_border));
    if (tiles.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, cons) {
      const gap = 12.0;
      final w = (cons.maxWidth - gap) / 2;
      return Wrap(spacing: gap, runSpacing: gap, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
    });
  }
}

/// PR badges for records this session holds (needs at least two sessions to be meaningful).
class _PrRow extends StatelessWidget {
  const _PrRow({required this.session, required this.all, required this.miles});
  final CardioSession session;
  final List<CardioSession> all;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    if (all.length < 2) return const SizedBox.shrink();
    final prs = PrService.cardio(all).where((p) => p.sessionId == session.id).toList();
    if (prs.isEmpty) return const SizedBox.shrink();
    final c = context.sx;
    return SxCard(
      borderColor: c.primaryBorder,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.emoji_events_outlined, color: c.primary),
          const SizedBox(width: 8),
          Text('PERSONAL RECORD', style: SxText.labelCaps.copyWith(color: c.primary)),
        ]),
        const SizedBox(height: SxSpace.sm),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in prs)
            SxPop(
              child: PrBadge(switch (p.type) {
                CardioPrType.longestDuration => 'Longest • ${Fmt.durationShort(p.value.round())}',
                CardioPrType.longestDistance => 'Longest • ${Fmt.km(p.value, miles: miles)} ${miles ? 'mi' : 'km'}',
                CardioPrType.fastestPace => 'Fastest • ${CardioPace.withUnit(CardioKind.values.firstWhere((k) => k.label == p.kindLabel, orElse: () => CardioKind.custom), p.value, miles: miles)}',
              }),
            ),
        ]),
      ]),
    );
  }
}

class _WeeklyTarget extends StatelessWidget {
  const _WeeklyTarget({required this.session, required this.repo});
  final CardioSession session;
  final CardioRepository repo;

  @override
  Widget build(BuildContext context) {
    final goal = weeklyDurationGoal(repo.goals);
    if (goal == null || goal.target <= 0) return const SizedBox.shrink();
    final c = context.sx;
    final w = cardioWeek(session.workoutDate);
    final week = VolumeService.cardioIn(repo.sessions, w.from, w.to);
    final total = VolumeService.cardioMinutes(week);
    final added = (session.durationSeconds / 60).round();
    final previous = (total - added).clamp(0, total);
    final pct = (total / goal.target * 100).round();
    final remaining = (goal.target - total).clamp(0, double.infinity);
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.flag_outlined, color: c.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('Weekly cardio target', style: SxText.headlineSm.copyWith(color: c.textHigh))),
          StatusPill('+$added min added'),
        ]),
        const SizedBox(height: SxSpace.sm),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text('$total', style: SxText.metricLg.copyWith(color: c.textHigh)),
          const SizedBox(width: 6),
          Expanded(child: Text('/ ${Fmt.number(goal.target)} min', style: SxText.bodyMd.copyWith(color: c.textBody))),
          Text('$pct% COMPLETED', style: SxText.labelCaps.copyWith(color: c.textBody)),
        ]),
        const SizedBox(height: SxSpace.sm),
        _TwoToneMeter(previous: previous / goal.target, added: added / goal.target),
        const SizedBox(height: SxSpace.sm),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Previous: $previous min', style: SxText.bodySm.copyWith(color: c.textBody)),
          Text(remaining <= 0 ? 'Weekly goal met' : '${Fmt.number(remaining.roundToDouble())} min to weekly goal', style: SxText.bodySm.copyWith(color: c.textBody)),
        ]),
      ]),
    );
  }
}

class _TwoToneMeter extends StatelessWidget {
  const _TwoToneMeter({required this.previous, required this.added});
  final double previous;
  final double added;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final p = previous.clamp(0.0, 1.0);
    final a = added.clamp(0.0, 1.0 - p);
    return SxGrow(
      value: 1,
      duration: SxMotion.emphasis,
      builder: (_, g) => ClipRRect(
        borderRadius: BorderRadius.circular(SxRadius.full),
        child: Container(
          height: 8,
          color: c.surface3,
          alignment: Alignment.centerLeft,
          child: Stack(children: [
            FractionallySizedBox(widthFactor: (p + a) * g, child: Container(height: 8, color: c.primary)),
            FractionallySizedBox(widthFactor: p * g, child: Container(height: 8, color: Color.alphaBlend(c.primary.withValues(alpha: 0.5), c.surface3))),
          ]),
        ),
      ),
    );
  }
}
