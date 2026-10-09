import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import '../today/today_page.dart' show AutoEndNoticeCard;
import 'session_analysis.dart';
import 'widgets/cardio_block.dart' show cardioIcon;

/// Summary of a saved session. Used right after finishing (strength-only or
/// mixed with a cardio block) and when a past session is opened from history.
class WorkoutCompletePage extends StatefulWidget {
  const WorkoutCompletePage({super.key, required this.sessionId});
  final String sessionId;

  @override
  State<WorkoutCompletePage> createState() => _WorkoutCompletePageState();
}

class _WorkoutCompletePageState extends State<WorkoutCompletePage> {
  bool _details = false;
  final _detailsKey = GlobalKey();

  void _toggleDetails() {
    setState(() => _details = !_details);
    if (_details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _detailsKey.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: SxMotion.of(ctx, SxMotion.standard), curve: SxMotion.enter);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app, app.sessions, app.profile]),
      builder: (context, _) {
        final s = app.sessions.byId(widget.sessionId);
        if (s == null) {
          return const SxScaffold(
            topBar: SxTopBar(title: 'Workout Summary'),
            body: Center(child: ErrorState(message: 'This session could not be found. It may have been deleted.')),
          );
        }
        final unit = app.profile.profile.unit;
        final all = app.sessions.sessions;
        final names = {for (final e in app.exercises.all) e.id: e};
        final prs = SessionAnalysis.prs(s, all);
        final prog = SessionAnalysis.progression(s, all);
        final mixed = s.cardio != null;
        final planned = app.workouts.byId(s.workoutId)?.totalSets;
        final empty = s.exercises.isEmpty && s.cardio == null;

        return SxScaffold(
          topBar: SxTopBar(
            title: 'Workout Summary',
            showLogo: true,
            pill: const StatusPill('Complete', dot: true),
          ),
          bottom: Column(mainAxisSize: MainAxisSize.min, children: [
            SxButton(label: 'Done', icon: Icons.check, onPressed: () => AppNav.switchTab(context, 0)),
            const SizedBox(height: 8),
            SxButton(
              label: _details ? 'Hide workout details' : 'View workout details',
              variant: SxButtonVariant.secondary,
              height: 48,
              onPressed: empty ? null : _toggleDetails,
            ),
          ]),
          children: [
            if (app.pendingAutoEndNotice?.sessionId == s.id)
              AutoEndNoticeCard(notice: app.pendingAutoEndNotice!, onDismiss: app.clearAutoEndNotice),
            RepaintBoundary(
              child: SxFadeSlideIn(
                child: mixed
                    ? _MixedHeader(session: s, number: SessionAnalysis.sessionNumber(s, all))
                    : _Header(session: s, unit: unit, planned: planned, number: SessionAnalysis.sessionNumber(s, all)),
              ),
            ),
            if (mixed) _StrengthCardioTiles(session: s, unit: unit),
            if (empty)
              const EmptyState(icon: Icons.inbox_outlined, title: 'Nothing logged', message: 'No sets or cardio were saved for this session.'),
            if (mixed && s.exercises.isNotEmpty) _MuscleBreakdown(session: s, catalog: app.exercises.all),
            if (mixed) _CardioSummary(cardio: s.cardio!, useKm: app.profile.profile.cardioDistanceUnitKm),
            if (prs.isNotEmpty) _PrSection(prs: prs, names: names, unit: unit),
            if (prog.isNotEmpty) _ProgressionIndex(items: prog, names: names),
            if (_details && !empty) _DetailsLog(key: _detailsKey, session: s, names: names, unit: unit, catalog: app.exercises.all),
            if (_isFresh(s)) _NextUp(workout: app.workouts.currentWorkout),
          ],
        );
      },
    );
  }
}

/// Just saved (not a past session opened from history): the "Next up" line is only useful then.
bool _isFresh(WorkoutSession s) {
  final created = s.meta.createdAt;
  return DateTime.now().difference(created).inMinutes.abs() < 10;
}

/// "Next up: (workout name)" cross-fades when the rotation moves on.
class _NextUp extends StatelessWidget {
  const _NextUp({required this.workout});
  final Workout? workout;

  @override
  Widget build(BuildContext context) {
    final w = workout;
    if (w == null) return const SizedBox.shrink();
    final c = context.sx;
    return SxFadeSlideIn(
      delay: SxMotion.standard,
      child: SxSwap(
        child: Row(
          key: ValueKey<String>(w.id),
          children: [
            Icon(Icons.event_repeat, size: 18, color: c.textBody),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Next up: ${w.name}', maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.bodyMd.copyWith(color: c.textBody)),
            ),
          ],
        ),
      ),
    );
  }
}

String _when(DateTime d) {
  final base = Fmt.relativeDay(d);
  if (d.hour == 0 && d.minute == 0) return base;
  return '$base at ${Fmt.time(d)}';
}

String _durMin(int seconds) => seconds < 60 ? '<1' : '${(seconds / 60).round()}';

class _Header extends StatelessWidget {
  const _Header({required this.session, required this.unit, required this.planned, required this.number});
  final WorkoutSession session;
  final WeightUnit unit;
  final int? planned;
  final int number;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final done = session.doneSets;
    return SxCard(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Flexible(child: StatusPill('Workout complete', dot: true)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('SESSION #$number', textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(session.name, style: SxText.headlineLg.copyWith(color: c.textHigh)),
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.event_available, size: 16, color: c.textBody),
          const SizedBox(width: 6),
          Expanded(child: Text(_when(session.workoutDate), style: SxText.bodyMd.copyWith(color: c.textBody))),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _HeroTile(
              label: 'Duration',
              value: _durMin(session.durationSeconds),
              number: session.durationSeconds < 60 ? null : (session.durationSeconds / 60).round().toDouble(),
              unit: 'min',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HeroTile(
              label: 'Volume',
              value: Fmt.thousands(Fmt.toDisplayWeight(session.volume, unit)),
              number: Fmt.toDisplayWeight(session.volume, unit),
              unit: Fmt.unit(unit),
              accent: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HeroTile(
              label: 'Sets hit',
              value: '$done',
              number: done.toDouble(),
              unit: planned != null && planned! >= done && planned! > 0 ? '/$planned' : null,
            ),
          ),
        ]),
      ]),
    );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({required this.label, required this.value, this.number, this.unit, this.accent = false});
  final String label;
  final String value;

  /// Numeric form of [value]: counts up on entry (the final text is always [value]).
  final double? number;
  final String? unit;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md), border: Border.all(color: c.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelXs.copyWith(color: c.textBody)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisSize: MainAxisSize.min, children: [
            if (number == null)
              Text(value, style: SxText.metricLg.copyWith(color: accent ? c.primary : c.textHigh, fontSize: 26))
            else
              SxCountUp(
                value: number!,
                formatter: (v) => v >= number! ? value : Fmt.thousands(v),
                style: SxText.metricLg.copyWith(color: accent ? c.primary : c.textHigh, fontSize: 26),
              ),
            if (unit != null) Text(' $unit', style: SxText.bodySm.copyWith(color: c.textBody)),
          ]),
        ),
      ]),
    );
  }
}

class _MixedHeader extends StatelessWidget {
  const _MixedHeader({required this.session, required this.number});
  final WorkoutSession session;
  final int number;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Column(children: [
      // Cheap glow: a flat soft ring instead of a blurred shadow.
      SxPop(
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
            child: Icon(Icons.check, size: 36, color: c.onPrimary),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text('SESSION COMPLETE', style: SxText.labelCaps.copyWith(color: c.primary, letterSpacing: 1.4)),
      const SizedBox(height: 4),
      Text('WORKOUT COMPLETE', textAlign: TextAlign.center, style: SxText.headlineLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('${Fmt.dateLong(session.workoutDate)} • ${Fmt.clockHms(session.durationSeconds)} total time',
          textAlign: TextAlign.center, style: SxText.bodyMd.copyWith(color: c.textBody)),
      const SizedBox(height: 4),
      Text('${session.name} + ${session.cardio!.kind.label} • Session #$number',
          textAlign: TextAlign.center, style: SxText.bodyMd.copyWith(color: c.primary)),
    ]);
  }
}

class _StrengthCardioTiles extends StatelessWidget {
  const _StrengthCardioTiles({required this.session, required this.unit});
  final WorkoutSession session;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final cd = session.cardio!;
    Widget tile({required IconData icon, required String title, required String tag, required String value, required String unitText, required String caption, required Color color}) => Expanded(
          child: SxCard(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(title.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelXs.copyWith(color: c.textBody))),
              ]),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisSize: MainAxisSize.min, children: [
                  Text(value, style: SxText.metricLg.copyWith(color: c.textHigh)),
                  Text(' $unitText', style: SxText.bodySm.copyWith(color: c.textBody)),
                ]),
              ),
              const SizedBox(height: 2),
              Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
              const SizedBox(height: 8),
              SxLinearMeter(value: 1, height: 4, color: color),
            ]),
          ),
        );
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      tile(
        icon: Icons.fitness_center,
        title: 'Strength',
        tag: '${session.exercises.length} EX',
        value: Fmt.thousands(Fmt.toDisplayWeight(session.volume, unit)),
        unitText: Fmt.unit(unit),
        caption: '${session.doneSets} working sets',
        color: c.primary,
      ),
      const SizedBox(width: 8),
      tile(
        icon: cardioIcon(cd.kind),
        title: 'Cardio',
        tag: cd.kind.label,
        value: cd.distanceKm != null ? Fmt.km(cd.distanceKm) : Fmt.clock(cd.durationSeconds),
        unitText: cd.distanceKm != null ? 'km' : 'min',
        caption: '${Fmt.clock(cd.durationSeconds)} duration',
        color: c.positive,
      ),
    ]);
  }
}

class _MuscleBreakdown extends StatelessWidget {
  const _MuscleBreakdown({required this.session, required this.catalog});
  final WorkoutSession session;
  final List<Exercise> catalog;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final byId = {for (final e in catalog) e.id: e};
    final sets = VolumeService.setsByMuscle([session], catalog);
    final rows = sets.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (rows.isEmpty) return const SizedBox.shrink();
    final maxSets = rows.first.value;
    return SxCard(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Muscle volume', style: SxText.headlineSm.copyWith(color: c.textHigh))),
          StatusPill('${session.doneSets} sets total', color: c.textBody),
        ]),
        const SizedBox(height: 12),
        for (final r in rows) ...[
          Builder(builder: (_) {
            final ex = [
              for (final l in session.exercises)
                if (byId[l.exerciseId]?.primaryMuscle == r.key) byId[l.exerciseId]!.name,
            ];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(r.key.label, style: SxText.bodyLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w600))),
                  Text('${r.value} set${r.value == 1 ? '' : 's'}', style: SxText.metricSm.copyWith(color: c.textHigh)),
                ]),
                const SizedBox(height: 8),
                SxLinearMeter(value: maxSets == 0 ? 0 : r.value / maxSets, height: 6),
                const SizedBox(height: 6),
                Text(ex.join(', '), maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
              ]),
            );
          }),
          const SizedBox(height: 8),
        ],
      ]),
    );
  }
}

class _CardioSummary extends StatelessWidget {
  const _CardioSummary({required this.cardio, required this.useKm});
  final CardioSession cardio;
  final bool useKm;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final f = cardio.kind.fields;
    final cells = <(String, String, String)>[
      ('Duration', Fmt.clock(cardio.durationSeconds), 'min'),
      if (f.contains(CardioField.distance) && cardio.distanceKm != null) ('Distance', Fmt.km(cardio.distanceKm, miles: !useKm), useKm ? 'km' : 'mi'),
      if (f.contains(CardioField.speed) && cardio.avgSpeedKmh != null) ('Speed', Fmt.number(cardio.avgSpeedKmh!), 'km/h'),
      if (f.contains(CardioField.incline) && cardio.inclinePct != null) ('Incline', Fmt.number(cardio.inclinePct!), '%'),
      if (f.contains(CardioField.resistance) && cardio.resistance != null) ('Resistance', '${cardio.resistance}', 'lvl'),
      if (f.contains(CardioField.pace) && cardio.paceSecPerKm != null) ('Pace', Fmt.pace(cardio.paceSecPerKm), '/km'),
    ];
    return SxCard(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(cardioIcon(cardio.kind), color: c.positive),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cardio.kind.label, style: SxText.headlineSm.copyWith(color: c.textHigh)),
              Text('Cardio block • Completed', style: SxText.labelXs.copyWith(color: c.positive)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, cons) {
          final w = (cons.maxWidth - 8) / 2;
          return Wrap(spacing: 8, runSpacing: 8, children: [
            for (final cell in cells) SizedBox(width: w, child: _HeroTile(label: cell.$1, value: cell.$2, unit: cell.$3)),
          ]);
        }),
      ]),
    );
  }
}

class _PrSection extends StatelessWidget {
  const _PrSection({required this.prs, required this.names, required this.unit});
  final List<PrHighlight> prs;
  final Map<String, Exercise> names;
  final WeightUnit unit;

  String _delta(PrHighlight p) {
    if (p.loadDeltaKg > 0) return '+${Fmt.weight(p.loadDeltaKg, unit)} ${Fmt.unit(unit)} load PR';
    if (p.repDelta > 0) return '+${p.repDelta} rep${p.repDelta == 1 ? '' : 's'} PR';
    return '+${Fmt.weight(p.e1rmDeltaKg, unit)} ${Fmt.unit(unit)} est. 1RM';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.emoji_events, color: c.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text('Personal Records', style: SxText.headlineMd.copyWith(color: c.textHigh))),
        StatusPill('${prs.length} new PR${prs.length == 1 ? '' : 's'}'),
      ]),
      const SizedBox(height: 12),
      for (var i = 0; i < prs.length; i++) ...[
        _PrPop(
          index: i,
          child: Builder(builder: (context) {
        final p = prs[i];
        return SxCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(names[p.exerciseId]?.name ?? 'Exercise', maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.headlineSm.copyWith(color: c.textHigh))),
              const SizedBox(width: 8),
              Text(Fmt.setLabel(p.weightKg, p.reps, unit), style: SxText.metricMd.copyWith(color: c.textHigh)),
            ]),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.trending_up, size: 16, color: c.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Previous best: ${Fmt.setLabel(p.previousWeightKg, p.previousReps, unit)} (${_delta(p)})',
                    style: SxText.metricSm.copyWith(color: c.primary, fontSize: 12)),
              ),
            ]),
          ]),
        );
          }),
        ),
        const SizedBox(height: 8),
      ],
    ]);
  }
}

/// PR card entrance: a staggered pop (<= 450 ms in total, one haptic for the first PR only).
class _PrPop extends StatefulWidget {
  const _PrPop({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_PrPop> createState() => _PrPopState();
}

class _PrPopState extends State<_PrPop> {
  Timer? _t;
  bool _on = false;

  @override
  void initState() {
    super.initState();
    final delay = SxMotion.stagger * (widget.index > 3 ? 3 : widget.index);
    if (delay == Duration.zero) {
      _on = true;
    } else {
      _t = Timer(delay, () {
        if (mounted) setState(() => _on = true);
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SxPop(
      active: _on,
      haptic: widget.index == 0,
      peak: 1.03,
      duration: SxMotion.short,
      child: widget.child,
    );
  }
}

class _ProgressionIndex extends StatelessWidget {
  const _ProgressionIndex({required this.items, required this.names});
  final List<ExerciseProgress> items;
  final Map<String, Exercise> names;

  String _label(ExerciseProgress p) => switch (p.kind) {
        ProgressKind.load => '+${Fmt.number(p.value, decimals: 1)}% LOAD',
        ProgressKind.reps => '+${p.value.round()} REP VOL',
        ProgressKind.maintained => 'MAINTAINED',
        ProgressKind.lower => 'LOWER LOAD',
        ProgressKind.first => 'FIRST LOG',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final improved = items.where((i) => i.improved).length;
    return SxCard(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PROGRESSION INDEX', style: SxText.labelCaps.copyWith(color: c.textBody)),
              const SizedBox(height: 4),
              Text('$improved / ${items.length} Exercises Improved', style: SxText.headlineSm.copyWith(color: c.textHigh)),
            ]),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
            child: Icon(Icons.stacked_line_chart, color: c.primary),
          ),
        ]),
        const SizedBox(height: 12),
        SxLinearMeter(value: items.isEmpty ? 0 : improved / items.length, height: 6),
        const SizedBox(height: 12),
        for (final p in items)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.base)),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: p.improved ? c.primary : c.textBody, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(names[p.exerciseId]?.name ?? 'Exercise', maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.bodyMd.copyWith(color: c.textHigh))),
              const SizedBox(width: 8),
              Text(_label(p), style: SxText.labelXs.copyWith(color: p.improved ? c.primary : c.textBody, fontWeight: FontWeight.w700)),
            ]),
          ),
      ]),
    );
  }
}

class _DetailsLog extends StatelessWidget {
  const _DetailsLog({super.key, required this.session, required this.names, required this.unit, required this.catalog});
  final List<Exercise> catalog;
  final WorkoutSession session;
  final Map<String, Exercise> names;
  final WeightUnit unit;

  /// Muscle label per log index where a new muscle run starts (only with 2+ runs; logged order is kept).
  Map<int, String> _dividers() {
    final routine = [
      for (final l in session.exercises) RoutineExercise(exerciseId: l.exerciseId, sets: 1, repMin: 1, repMax: 1),
    ];
    final runs = WorkoutSections.groupContiguous(routine, catalog);
    if (runs.length < 2) return const {};
    return {for (final r in runs) r.startIndex: r.label};
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final dividers = _dividers();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader('Workout details', icon: Icons.list_alt),
      const SizedBox(height: 8),
      for (var li = 0; li < session.exercises.length; li++) ...[
        if (dividers[li] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2),
            child: Text(dividers[li]!.toUpperCase(), style: SxText.labelXs.copyWith(color: c.textMuted)),
          ),
        _card(context, session.exercises[li]),
        const SizedBox(height: 8),
      ],
    ]);
  }

  Widget _card(BuildContext context, ExerciseLog l) {
    final c = context.sx;
    return SxCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(names[l.exerciseId]?.name ?? 'Exercise', style: SxText.headlineSm.copyWith(color: c.textHigh))),
          Text(Fmt.volume(l.volume, u: unit), style: SxText.metricSm.copyWith(color: c.textBody)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < l.doneSets.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.base)),
              child: Text('${i + 1}  ${Fmt.setLabel(l.doneSets.elementAt(i).weightKg, l.doneSets.elementAt(i).reps, unit)}',
                  style: SxText.metricSm.copyWith(color: c.textHigh, fontSize: 12)),
            ),
        ]),
      ]),
    );
  }
}
