import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// What happened on one calendar day (by `workoutDate`).
class _DayData {
  final strength = <WorkoutSession>[]; // strength only
  final mixed = <WorkoutSession>[]; // strength + attached cardio
  final cardio = <CardioSession>[]; // standalone cardio
  bool get isEmpty => strength.isEmpty && mixed.isEmpty && cardio.isEmpty;
}

/// Training log: month calendar + per-day session detail + backdating entry points.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected = _dateOnly(DateTime.now());
  int _filter = 0; // 0 all, 1 strength only, 2 cardio only, 3 mixed

  void _shiftMonth(int d) => setState(() {
        _month = DateTime(_month.year, _month.month + d);
        final today = _dateOnly(DateTime.now());
        // Keep the selection inside the visible month.
        _selected = (today.year == _month.year && today.month == _month.month) ? today : DateTime(_month.year, _month.month, 1);
      });

  void _goToday() => setState(() {
        final t = DateTime.now();
        _month = DateTime(t.year, t.month);
        _selected = _dateOnly(t);
      });

  Map<DateTime, _DayData> _collect(AppController app) {
    final out = <DateTime, _DayData>{};
    for (final s in app.sessions.sessions) {
      final d = out.putIfAbsent(_dateOnly(s.workoutDate), _DayData.new);
      (s.cardio != null ? d.mixed : d.strength).add(s);
    }
    for (final c in app.cardio.sessions) {
      out.putIfAbsent(_dateOnly(c.workoutDate), _DayData.new).cardio.add(c);
    }
    return out;
  }

  Future<void> _logHistoricalLift() async {
    final app = context.app;
    final workouts = app.workouts.workouts;
    if (workouts.isEmpty) {
      showSxSnack(context, 'Create a workout first', icon: Icons.info_outline);
      return;
    }
    final picked = await showSxSheet<Workout>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.md),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('LOG HISTORICAL LIFT', style: SxText.headlineMd.copyWith(color: ctx.sx.textHigh)),
          const SizedBox(height: 4),
          Text('Which workout did you do on ${Fmt.dateLong(_selected)}?', style: SxText.bodyMd.copyWith(color: ctx.sx.textBody)),
          const SizedBox(height: SxSpace.md),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: workouts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => SxCard(
                padding: const EdgeInsets.all(14),
                onTap: () => Navigator.pop(ctx, workouts[i]),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(workouts[i].name, style: SxText.headlineSm.copyWith(color: ctx.sx.textHigh)),
                      Text('${workouts[i].exercises.length} exercises · ${workouts[i].totalSets} sets', style: SxText.bodySm.copyWith(color: ctx.sx.textBody)),
                    ]),
                  ),
                  Icon(Icons.chevron_right, color: ctx.sx.textBody),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
    if (picked != null && mounted) {
      // Backdated entry: only workoutDate is chosen here; createdAt stays "now".
      await AppNav.activeWorkout(context, picked.id, backdate: _selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.sessions, app.cardio, app.exercises, app.profile, app.workouts]),
      builder: (context, _) {
        final c = context.sx;
        final data = _collect(app);
        final today = _dateOnly(DateTime.now());
        final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

        // Counts for the visible month, per kind.
        var nStrength = 0, nCardio = 0, nMixed = 0;
        for (var d = 1; d <= daysInMonth; d++) {
          final x = data[DateTime(_month.year, _month.month, d)];
          if (x == null) continue;
          nStrength += x.strength.length;
          nCardio += x.cardio.length;
          nMixed += x.mixed.length;
        }
        final counts = [nStrength + nCardio + nMixed, nStrength, nCardio, nMixed];

        final day = data[_selected] ?? _DayData();
        final strengthList = [if (_filter == 0 || _filter == 1) ...day.strength, if (_filter == 0 || _filter == 3) ...day.mixed]
          ..sort((a, b) => a.workoutDate.compareTo(b.workoutDate));
        final cardioList = (_filter == 0 || _filter == 2) ? day.cardio : <CardioSession>[];
        final isFuture = _selected.isAfter(today);

        var totalSeconds = 0;
        for (final s in strengthList) {
          totalSeconds += s.durationSeconds + (s.cardio?.durationSeconds ?? 0);
        }
        for (final x in cardioList) {
          totalSeconds += x.durationSeconds;
        }
        final sessionCount = strengthList.length + cardioList.length;

        // Weekly density (real): sessions this week vs target.
        final ws = VolumeService.startOfWeek(DateTime.now());
        final we = DateTime(ws.year, ws.month, ws.day + 7);
        final weekCount = app.sessions.between(ws, we).length + app.cardio.between(ws, we).length;
        final target = app.profile.profile.weeklySessionTarget;

        final isCurrentMonth = _month.year == today.year && _month.month == today.month;

        return SxScaffold(
          topBar: const SxTopBar(title: 'Training Log', showLogo: true),
          children: [
            _MonthHeader(month: _month, showToday: !isCurrentMonth || _selected != today, onPrev: () => _shiftMonth(-1), onNext: () => _shiftMonth(1), onToday: _goToday),
            _FilterRow(index: _filter, counts: counts, onChanged: (i) => setState(() => _filter = i)),
            _MonthGrid(month: _month, selected: _selected, today: today, data: data, filter: _filter, onSelect: (d) => setState(() => _selected = d)),
            SxCard(
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(SxRadius.md)),
                  child: Icon(Icons.local_fire_department_outlined, color: c.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('This week', style: SxText.headlineSm.copyWith(color: c.textHigh)),
                    Text('$weekCount of $target sessions', style: SxText.bodySm.copyWith(color: c.textBody)),
                  ]),
                ),
                if (weekCount >= target) const StatusPill('Goal met', icon: Icons.check),
              ]),
            ),
            _DayHeader(date: _selected, isToday: _selected == today, sessionCount: sessionCount, seconds: totalSeconds),
            if (sessionCount == 0)
              SxCard(
                child: Column(children: [
                  Icon(isFuture ? Icons.event_outlined : Icons.event_busy_outlined, size: 32, color: c.textMuted),
                  const SizedBox(height: 8),
                  Text(isFuture ? 'Upcoming day' : (day.isEmpty ? 'Rest day' : 'Nothing matches this filter'),
                      style: SxText.headlineSm.copyWith(color: c.textHigh)),
                  const SizedBox(height: 4),
                  Text(
                    isFuture ? 'Future dates can\'t be logged. Your rotation, not the calendar, decides the next workout.' : (day.isEmpty ? 'No sessions logged. Add a past workout below if you trained.' : 'Change the filter to see this day\'s sessions.'),
                    textAlign: TextAlign.center,
                    style: SxText.bodySm.copyWith(color: c.textBody),
                  ),
                ]),
              ),
            for (final s in strengthList) _StrengthCard(session: s),
            for (final x in cardioList) _CardioCard(session: x),
            const SectionHeader('Record retroactive data'),
            Row(children: [
              Expanded(child: SxButton(label: 'Log lift', icon: Icons.fitness_center, variant: SxButtonVariant.secondary, height: 52, onPressed: isFuture ? null : _logHistoricalLift)),
              const SizedBox(width: 8),
              Expanded(child: SxButton(label: 'Backdate cardio', icon: Icons.directions_run, variant: SxButtonVariant.secondary, height: 52, onPressed: isFuture ? null : () => AppNav.backdateCardio(context, date: _selected))),
            ]),
            if (isFuture) Text('Pick today or an earlier date to log past activity.', textAlign: TextAlign.center, style: SxText.bodySm.copyWith(color: c.textMuted)),
          ],
        );
      },
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.showToday, required this.onPrev, required this.onNext, required this.onToday});
  final DateTime month;
  final bool showToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(children: [
        SxIconButton(icon: Icons.chevron_left, tooltip: 'Previous month', onPressed: onPrev),
        Expanded(
          child: Column(children: [
            Text('HISTORICAL LOG', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text('${Fmt.monthName(month.month)} ${month.year}', style: SxText.headlineMd.copyWith(color: c.textHigh))),
            if (showToday)
              TextButton(onPressed: onToday, style: TextButton.styleFrom(minimumSize: const Size(48, 32), padding: const EdgeInsets.symmetric(horizontal: 12)), child: Text('TODAY', style: SxText.labelCaps.copyWith(color: c.primary))),
          ]),
        ),
        SxIconButton(icon: Icons.chevron_right, tooltip: 'Next month', onPressed: onNext),
      ]),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.index, required this.counts, required this.onChanged});
  final int index;
  final List<int> counts;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['All activity', 'Strength only', 'Cardio only', 'Mixed'];
    final c = context.sx;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = i == index;
          return Material(
            color: sel ? c.primary : c.surface2,
            shape: StadiumBorder(side: BorderSide(color: sel ? c.primary : c.hairline)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onChanged(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(labels[i], style: SxText.labelUi.copyWith(color: sel ? const Color(0xFF101214) : c.textBody, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text('${counts[i]}', style: SxText.metricSm.copyWith(color: sel ? const Color(0xFF101214) : c.textMuted, fontSize: 12)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.selected, required this.today, required this.data, required this.filter, required this.onSelect});
  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final Map<DateTime, _DayData> data;
  final int filter;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final first = DateTime(month.year, month.month, 1);
    final offset = first.weekday - 1;
    final dim = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((offset + dim) / 7).ceil();
    return SxCard(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Column(children: [
        Row(children: [
          for (var i = 1; i <= 7; i++)
            Expanded(child: Center(child: Text(Fmt.dayShort(i).substring(0, 1).toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody)))),
        ]),
        const SizedBox(height: 8),
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(builder: (_) {
                    final n = r * 7 + col - offset + 1;
                    if (n < 1 || n > dim) return const SizedBox(height: 48);
                    final d = DateTime(month.year, month.month, n);
                    return _DayCell(day: d, selected: d == selected, isToday: d == today, future: d.isAfter(today), info: data[d], filter: filter, onTap: () => onSelect(d));
                  }),
                ),
            ]),
          ),
        const SizedBox(height: 8),
        Wrap(spacing: 16, runSpacing: 6, alignment: WrapAlignment.center, children: [
          _Legend(color: c.primary, label: 'Cardio'),
          _Legend(color: c.textHigh, label: 'Strength'),
          _Legend(color: c.primary, second: c.textHigh, label: 'Mixed'),
        ]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.second});
  final Color color;
  final Color? second;
  final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        _Dot(color),
        if (second != null) ...[const SizedBox(width: 2), _Dot(second!)],
        const SizedBox(width: 6),
        Text(label, style: SxText.labelCaps.copyWith(color: context.sx.textBody, fontSize: 10)),
      ]);
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.selected, required this.isToday, required this.future, required this.info, required this.filter, required this.onTap});
  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool future;
  final _DayData? info;
  final int filter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final showStrength = info != null && info!.strength.isNotEmpty && (filter == 0 || filter == 1);
    final showCardio = info != null && info!.cardio.isNotEmpty && (filter == 0 || filter == 2);
    final showMixed = info != null && info!.mixed.isNotEmpty && (filter == 0 || filter == 3);
    final dots = <Color>[
      if (showStrength || showMixed) c.textHigh,
      if (showCardio || showMixed) c.primary,
    ];
    final label = '${Fmt.dateLong(day)}${dots.isEmpty ? '' : ', activity logged'}';
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: selected ? c.surface3 : c.surface2.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SxRadius.md), side: BorderSide(color: selected ? c.primary : Colors.transparent)),
          child: InkWell(
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SxRadius.md)),
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${day.day}',
                    style: SxText.metricSm.copyWith(
                        color: isToday ? c.primary : (future ? c.textMuted : c.textHigh),
                        fontWeight: isToday || selected ? FontWeight.w700 : FontWeight.w500)),
                const SizedBox(height: 3),
                SizedBox(
                  height: 6,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < dots.length; i++) ...[if (i > 0) const SizedBox(width: 3), _Dot(dots[i])],
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.isToday, required this.sessionCount, required this.seconds});
  final DateTime date;
  final bool isToday;
  final int sessionCount;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final sub = sessionCount == 0 ? 'No sessions' : '$sessionCount completed ${sessionCount == 1 ? 'session' : 'sessions'}${seconds > 0 ? ' • ${Fmt.durationShort(seconds)} total time' : ''}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: isToday ? c.primary : c.textMuted, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(Fmt.dateLong(date), style: SxText.headlineMd.copyWith(color: c.textHigh))),
      ]),
      const SizedBox(height: 4),
      Text(sub, style: SxText.bodySm.copyWith(color: c.textBody)),
    ]);
  }
}

class _StrengthCard extends StatelessWidget {
  const _StrengthCard({required this.session});
  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    final unit = app.profile.profile.unit;
    final u = Fmt.unit(unit);
    final byId = {for (final e in app.exercises.all) e.id: e};
    final prIds = PrService.newPrExerciseIds(session, app.sessions.sessions);
    final logs = session.exercises.where((l) => l.doneSets.isNotEmpty).toList();
    final firstPr = prIds.isEmpty ? null : byId[prIds.first]?.name;
    final hasTime = session.workoutDate.hour != 0 || session.workoutDate.minute != 0;
    final cardio = session.cardio;
    return SxCard(
      onTap: () => AppNav.viewWorkoutSession(context, session.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const StatusPill('Strength', icon: Icons.fitness_center),
          if (hasTime) ...[const SizedBox(width: 8), Text(Fmt.time(session.workoutDate), style: SxText.metricSm.copyWith(color: c.textBody, fontSize: 12))],
          const Spacer(),
          if (firstPr != null)
            Flexible(
              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: PrBadge(prIds.length > 1 ? '$firstPr +${prIds.length - 1}' : '$firstPr PR')),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text(session.name, style: SxText.headlineMd.copyWith(color: c.textHigh))),
          Icon(Icons.arrow_forward, size: 20, color: c.textBody),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Mini(label: 'Volume', value: Fmt.thousands(Fmt.toDisplayWeight(session.volume, unit)), unit: u)),
          const SizedBox(width: 8),
          Expanded(child: _Mini(label: 'Sets', value: '${session.doneSets}', unit: '')),
          const SizedBox(width: 8),
          Expanded(child: _Mini(label: 'Duration', value: session.durationSeconds > 0 ? Fmt.durationShort(session.durationSeconds) : '—', unit: '')),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Text('EXERCISE TELEMETRY (${logs.length})', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10))),
          Text('TOTAL LOAD', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
        ]),
        const SizedBox(height: 8),
        for (var i = 0; i < logs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SxInset(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text('${i + 1}. ${byId[logs[i].exerciseId]?.name ?? logs[i].exerciseId}', overflow: TextOverflow.ellipsis, style: SxText.bodyMd.copyWith(color: c.textHigh, fontWeight: FontWeight.w600))),
                      if (prIds.contains(logs[i].exerciseId)) ...[const SizedBox(width: 6), const PrBadge()],
                    ]),
                    Builder(builder: (_) {
                      final top = logs[i].doneSets.reduce((a, b) => b.weightKg > a.weightKg ? b : a);
                      return Text('${logs[i].doneSets.length} sets · ${Fmt.setLabel(top.weightKg, top.reps, unit)}', style: SxText.bodySm.copyWith(color: c.textBody));
                    }),
                  ]),
                ),
                const SizedBox(width: 8),
                Text('${Fmt.thousands(Fmt.toDisplayWeight(logs[i].volume, unit))} $u', style: SxText.metricSm.copyWith(color: c.textHigh)),
              ]),
            ),
          ),
        if (cardio != null)
          SxInset(
            color: c.primarySoft,
            borderColor: c.primaryBorder,
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Icon(Icons.directions_run, size: 18, color: c.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('${cardio.kind.label} finisher · ${Fmt.durationShort(cardio.durationSeconds)}${cardio.distanceKm != null ? ' · ${Fmt.km(cardio.distanceKm)} km' : ''}', style: SxText.bodySm.copyWith(color: c.textHigh))),
            ]),
          ),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;
  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxInset(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: MetricValue(value, unit: unit.isEmpty ? null : unit)),
      ]),
    );
  }
}

class _CardioCard extends StatelessWidget {
  const _CardioCard({required this.session});
  final CardioSession session;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final miles = !context.app.profile.profile.cardioDistanceUnitKm;
    final hasTime = session.workoutDate.hour != 0 || session.workoutDate.minute != 0;
    final dist = session.distanceKm;
    final pace = session.paceSecPerKm;
    return SxCard(
      onTap: () => AppNav.cardioDetails(context, session.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const StatusPill('Cardio', icon: Icons.directions_run),
          if (hasTime) ...[const SizedBox(width: 8), Text(Fmt.time(session.workoutDate), style: SxText.metricSm.copyWith(color: c.textBody, fontSize: 12))],
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text(session.kind.label, style: SxText.headlineMd.copyWith(color: c.textHigh))),
          Icon(Icons.arrow_forward, size: 20, color: c.textBody),
        ]),
        if (session.routeName.isNotEmpty) Text(session.routeName, style: SxText.bodySm.copyWith(color: c.textBody)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Mini(label: 'Time', value: Fmt.clock(session.durationSeconds), unit: 'min')),
          if (dist != null) ...[const SizedBox(width: 8), Expanded(child: _Mini(label: 'Distance', value: Fmt.km(miles ? dist * 0.621371 : dist), unit: miles ? 'mi' : 'km'))],
          if (pace != null) ...[const SizedBox(width: 8), Expanded(child: _Mini(label: 'Pace', value: Fmt.pace(miles ? pace * 1.609344 : pace), unit: '/${miles ? 'mi' : 'km'}'))],
        ]),
      ]),
    );
  }
}
