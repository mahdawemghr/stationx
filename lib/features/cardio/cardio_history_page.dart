import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'cardio_manage_helpers.dart';

/// All logged cardio: totals, kind filter, month range, sort, summary + cards.
class CardioHistoryPage extends StatefulWidget {
  const CardioHistoryPage({super.key});

  @override
  State<CardioHistoryPage> createState() => _CardioHistoryPageState();
}

class _CardioHistoryPageState extends State<CardioHistoryPage> {
  CardioKind? _kind;
  bool _newestFirst = true;

  /// Selected month (1st of month). Null = all time. `_rangeInit` lets the
  /// first build default to the most recent month that has data.
  DateTime? _month;
  bool _rangeInit = false;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.cardio, app.profile]),
      builder: (context, _) {
        final all = app.cardio.sessions;
        final units = CardioUnits(app.profile.profile.cardioDistanceUnitKm);
        if (!_rangeInit && all.isNotEmpty) {
          final d = all.first.workoutDate;
          _month = DateTime(d.year, d.month);
          _rangeInit = true;
        }
        final topBar = SxTopBar(
          title: 'Cardio History',
          actions: [SxIconButton(icon: Icons.add_circle_outline, tooltip: 'Backdate cardio', onPressed: () => AppNav.backdateCardio(context))],
        );
        if (all.isEmpty) {
          return SxScaffold(
            topBar: topBar,
            body: Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.directions_run,
                  eyebrow: 'No cardio recorded yet',
                  title: 'Your cardio history starts here',
                  message: 'Start a session, or log one you already did on the date it happened.',
                  actionLabel: 'Start cardio',
                  onAction: () => AppNav.selectCardioActivity(context),
                  secondaryLabel: 'Log past session',
                  onSecondary: () => AppNav.backdateCardio(context),
                ),
              ),
            ),
          );
        }
        final kinds = CardioKind.values.where((k) => all.any((s) => s.kind == k)).toList();
        if (_kind != null && !kinds.contains(_kind)) _kind = null;
        final byKind = _kind == null ? all : all.where((s) => s.kind == _kind).toList();
        final inRange = _month == null
            ? byKind
            : byKind.where((s) => s.workoutDate.year == _month!.year && s.workoutDate.month == _month!.month).toList();
        final list = [...inRange]..sort((a, b) => _newestFirst ? b.workoutDate.compareTo(a.workoutDate) : a.workoutDate.compareTo(b.workoutDate));
        final months = _monthsWithData(all);
        final rows = _rows(list);

        return SxScaffold(
          topBar: topBar,
          bottom: SxButton(label: 'Log past cardio', icon: Icons.add_task, onPressed: () => AppNav.backdateCardio(context)),
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(SxSpace.md, SxSpace.md, SxSpace.md, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _Hero(all: all, units: units),
                    const SizedBox(height: SxSpace.md),
                    SxChipRow(
                      padding: EdgeInsets.zero,
                      labels: ['All', for (final k in kinds) k.label],
                      selectedIndex: _kind == null ? 0 : kinds.indexOf(_kind!) + 1,
                      onSelected: (i) => setState(() => _kind = i == 0 ? null : kinds[i - 1]),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _Dropdown(label: 'Sort', value: _newestFirst ? 'Newest' : 'Oldest', onTap: _pickSort)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Dropdown(
                          label: 'Range',
                          value: _month == null ? 'All time' : '${Fmt.monthShort(_month!.month)} ${_month!.year}',
                          onTap: () => _pickRange(months),
                        ),
                      ),
                    ]),
                    const SizedBox(height: SxSpace.md),
                    _Summary(sessions: list, all: byKind, month: _month, units: units),
                    const SizedBox(height: SxSpace.md),
                  ]),
                ),
              ),
              if (rows.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(icon: Icons.filter_alt_off_outlined, title: 'No sessions match', message: 'Try another activity type or date range.'),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(SxSpace.md, 0, SxSpace.md, SxSpace.lg),
                  sliver: SliverList.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      if (r.header != null) return _MonthHeader(r.header!, r.count);
                      return _SessionCard(session: r.session!, all: all, units: units);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<_Row> _rows(List<CardioSession> list) {
    final out = <_Row>[];
    String? cur;
    for (var i = 0; i < list.length; i++) {
      final d = list[i].workoutDate;
      final key = '${d.year}-${d.month}';
      if (key != cur) {
        cur = key;
        final n = list.where((s) => s.workoutDate.year == d.year && s.workoutDate.month == d.month).length;
        out.add(_Row.header('${Fmt.monthName(d.month)} ${d.year}', n));
      }
      out.add(_Row.session(list[i]));
    }
    return out;
  }

  List<DateTime> _monthsWithData(List<CardioSession> all) {
    final set = <DateTime>{for (final s in all) DateTime(s.workoutDate.year, s.workoutDate.month)};
    return set.toList()..sort((a, b) => b.compareTo(a));
  }

  Future<void> _pickSort() async {
    final r = await _choose<bool>('Sort by', [(true, 'Newest first'), (false, 'Oldest first')], _newestFirst);
    if (r != null) setState(() => _newestFirst = r.value);
  }

  Future<void> _pickRange(List<DateTime> months) async {
    final r = await _choose<DateTime?>('Range', [
      (null, 'All time'),
      for (final m in months) (m, '${Fmt.monthName(m.month)} ${m.year}'),
    ], _month);
    if (r != null) setState(() => _month = r.value);
  }

  /// Option sheet. Wraps the result so a chosen `null` ("All time") is
  /// distinguishable from a dismissed sheet.
  Future<_Pick<T>?> _choose<T>(String title, List<(T, String)> options, T current) {
    return showSxSheet<_Pick<T>>(
      context,
      builder: (ctx) {
        final c = ctx.sx;
        return SafeArea(
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.md), children: [
            Text(title.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody)),
            const SizedBox(height: 8),
            for (final o in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(o.$2, style: SxText.bodyLg.copyWith(color: c.textHigh)),
                trailing: o.$1 == current ? Icon(Icons.check, color: c.primary) : null,
                onTap: () => Navigator.pop(ctx, _Pick<T>(o.$1)),
              ),
          ]),
        );
      },
    );
  }
}

class _Pick<T> {
  const _Pick(this.value);
  final T value;
}

class _Row {
  _Row.header(this.header, this.count) : session = null;
  _Row.session(this.session)
      : header = null,
        count = 0;
  final String? header;
  final int count;
  final CardioSession? session;
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxInset(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(children: [
        Flexible(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$label: ', style: SxText.bodySm.copyWith(color: c.textBody)),
              TextSpan(text: value, style: SxText.labelUi.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
            ]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(Icons.expand_more, size: 18, color: c.textBody),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.all, required this.units});
  final List<CardioSession> all;
  final CardioUnits units;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final km = VolumeService.cardioKm(all);
    final paced = all.where((s) => s.kind.fields.contains(CardioField.pace) && (s.distanceKm ?? 0) > 0);
    final pDur = paced.fold(0, (a, s) => a + s.durationSeconds);
    final pKm = paced.fold(0.0, (a, s) => a + s.distanceKm!);
    final kcal = all.fold(0, (a, s) => a + (s.calories ?? 0));
    final totalSec = all.fold(0, (a, s) => a + s.durationSeconds);
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const StatusPill('Local log', dot: true),
        const SizedBox(height: 10),
        Text('Cardio History', style: SxText.headlineLg.copyWith(color: c.textHigh)),
        const SizedBox(height: 4),
        Text('${all.length} total sessions • ${units.distanceText(km)} ${units.distanceUnit} logged', style: SxText.bodySm.copyWith(color: c.textBody)),
        const SizedBox(height: SxSpace.md),
        Row(children: [
          Expanded(child: _HeroStat('Avg pace', pKm > 0 ? units.paceText(pDur / pKm) : '—', pKm > 0 ? units.paceUnit : null)),
          Expanded(child: _HeroStat('Total time', Fmt.durationShort(totalSec), null, accent: true)),
          Expanded(child: _HeroStat(kcal > 0 ? 'Logged burn' : 'Total dist.', kcal > 0 ? Fmt.thousands(kcal) : units.distanceText(km), kcal > 0 ? 'kcal' : units.distanceUnit)),
        ]),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(this.label, this.value, this.unit, {this.accent = false});
  final String label;
  final String value;
  final String? unit;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: SxText.bodySm.copyWith(color: c.textBody), overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: MetricValue(value, unit: unit, style: SxText.metricMd, color: accent ? c.primary : c.textHigh)),
    ]);
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.sessions, required this.all, required this.month, required this.units});
  final List<CardioSession> sessions;
  final List<CardioSession> all;
  final DateTime? month;
  final CardioUnits units;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final sec = sessions.fold(0, (a, s) => a + s.durationSeconds);
    final km = VolumeService.cardioKm(sessions);
    final kcal = sessions.fold(0, (a, s) => a + (s.calories ?? 0));

    final List<double> bars;
    final List<String> labels;
    String? delta;
    if (month != null) {
      final days = DateTime(month!.year, month!.month + 1, 0).day;
      final weeks = ((days + 6) ~/ 7);
      bars = List.filled(weeks, 0);
      for (final s in sessions) {
        final w = ((s.workoutDate.day - 1) ~/ 7).clamp(0, weeks - 1);
        bars[w] += s.durationSeconds / 60;
      }
      labels = [for (var i = 0; i < weeks; i++) 'W${i + 1}'];
      final prev = DateTime(month!.year, month!.month - 1);
      final prevMin = all.where((s) => s.workoutDate.year == prev.year && s.workoutDate.month == prev.month).fold(0, (a, s) => a + s.durationSeconds) / 60;
      if (prevMin > 0) {
        final pct = ((sec / 60 - prevMin) / prevMin * 100).round();
        delta = '${pct >= 0 ? '+' : ''}$pct% vs ${Fmt.monthShort(prev.month)}';
      }
    } else {
      final now = DateTime.now();
      final ms = [for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i)];
      bars = [
        for (final m in ms) sessions.where((s) => s.workoutDate.year == m.year && s.workoutDate.month == m.month).fold(0, (a, s) => a + s.durationSeconds) / 60
      ];
      labels = [for (final m in ms) Fmt.monthShort(m.month)];
    }
    var maxI = 0;
    for (var i = 1; i < bars.length; i++) {
      if (bars[i] > bars[maxI]) maxI = i;
    }
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.insights, size: 16, color: c.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(month == null ? 'ALL-TIME SUMMARY' : 'MONTHLY PERFORMANCE SUMMARY', style: SxText.labelCaps.copyWith(color: c.primary), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 16, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.end, children: [
          MetricValue(Fmt.durationShort(sec), unit: 'total', style: SxText.metricLg),
          MetricValue(units.distanceText(km), unit: units.distanceUnit, style: SxText.metricLg, color: c.primary),
          if (kcal > 0) MetricValue(Fmt.thousands(kcal), unit: 'kcal', style: SxText.metricLg),
        ]),
        const SizedBox(height: 4),
        Text('${sessions.length} session${sessions.length == 1 ? '' : 's'}', style: SxText.bodySm.copyWith(color: c.textBody)),
        const SizedBox(height: SxSpace.md),
        Row(children: [
          Expanded(child: Text(month == null ? 'Minutes per month' : 'Volume distribution', style: SxText.bodySm.copyWith(color: c.textBody))),
          if (delta != null) Text(delta, style: SxText.labelCaps.copyWith(color: c.primary, fontSize: 10)),
        ]),
        const SizedBox(height: 8),
        SxBarChart(values: bars, labels: labels, height: 96, highlightIndex: bars.every((b) => b == 0) ? null : maxI),
      ]),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader(this.title, this.count);
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(children: [
      Icon(Icons.calendar_month, size: 18, color: c.primary),
      const SizedBox(width: 8),
      Expanded(child: Text(title.toUpperCase(), style: SxText.headlineSm.copyWith(color: c.textHigh), overflow: TextOverflow.ellipsis)),
      Text('$count logged', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
    ]);
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.all, required this.units});
  final CardioSession session;
  final List<CardioSession> all;
  final CardioUnits units;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final s = session;
    final pr = cardioPrLabel(s, all);
    final f = s.kind.fields;
    final cols = <(String, String, String?, bool)>[
      ('Time', '${(s.durationSeconds / 60).round()}', 'min', false),
      if (s.distanceKm != null) ('Distance', units.distanceText(s.distanceKm), units.distanceUnit, true),
      if (f.contains(CardioField.pace) && s.paceSecPerKm != null)
        ('Pace', units.paceText(s.paceSecPerKm), null, false)
      else if (s.avgSpeedKmh != null && (f.contains(CardioField.speed)))
        ('Speed', units.speedText(s.avgSpeedKmh), units.speedUnit, false),
      if (s.inclinePct != null) ('Incline', Fmt.number(s.inclinePct!), '%', false),
      if (s.resistance != null) ('Resist.', '${s.resistance}', null, false),
      if (s.calories != null) ('Burn', Fmt.thousands(s.calories!), 'kcal', false),
    ].take(4).toList();
    return SxCard(
      onTap: () => AppNav.cardioDetails(context, s.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md)),
            child: Icon(cardioKindIcon(s.kind), color: c.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.kind.label, style: SxText.headlineSm.copyWith(color: c.textHigh), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${Fmt.dateMedium(s.workoutDate)} • ${Fmt.time(s.workoutDate)}', style: SxText.bodySm.copyWith(color: c.textBody), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (pr != null) Flexible(flex: 0, child: PrBadge(pr)),
        ]),
        const SizedBox(height: 12),
        SxInset(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            for (final col in cols)
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(col.$1, style: SxText.bodySm.copyWith(color: c.textBody), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: MetricValue(col.$2, unit: col.$3, style: SxText.metricMd, color: col.$4 ? c.primary : c.textHigh)),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          if (s.avgHeartRate != null) ...[
            Icon(Icons.favorite_border, size: 14, color: c.textBody),
            const SizedBox(width: 6),
            Text('${s.avgHeartRate} bpm avg', style: SxText.bodySm.copyWith(color: c.textBody)),
          ] else if (s.routeName.isNotEmpty) ...[
            Icon(Icons.place_outlined, size: 14, color: c.textBody),
            const SizedBox(width: 6),
            Flexible(child: Text(s.routeName, style: SxText.bodySm.copyWith(color: c.textBody), overflow: TextOverflow.ellipsis)),
          ],
          const Spacer(),
          Text('Details', style: SxText.labelUi.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward, size: 14, color: c.primary),
        ]),
      ]),
    );
  }
}
