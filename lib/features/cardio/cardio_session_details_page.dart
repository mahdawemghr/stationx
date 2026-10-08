import 'package:flutter/material.dart';

import 'cardio_pace.dart';
import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'cardio_delete_dialog.dart';
import 'cardio_manage_helpers.dart';

/// Read-only view of one logged cardio session. Shows only what was logged;
/// sensor sections (HR zones, splits, map) are not part of this build.
class CardioSessionDetailsPage extends StatefulWidget {
  const CardioSessionDetailsPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  State<CardioSessionDetailsPage> createState() => _CardioSessionDetailsPageState();
}

class _CardioSessionDetailsPageState extends State<CardioSessionDetailsPage> {
  bool _hadSession = false;
  bool _popping = false;

  Future<void> _delete(CardioSession s) async {
    if (!await confirmDeleteCardio(context, s) || !mounted) return;
    final nav = Navigator.of(context);
    _popping = true;
    await context.app.cardio.delete(s.id);
    if (!mounted) return;
    showSxSnack(context, 'Session deleted');
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.cardio, app.profile]),
      builder: (context, _) {
        final s = app.cardio.byId(widget.sessionId);
        if (s == null) {
          // Deleted from the edit screen on top of us: leave as well.
          if (_hadSession && !_popping) {
            _popping = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).maybePop();
            });
          }
          return const SxScaffold(
            topBar: SxTopBar(title: 'Session Summary'),
            body: Center(child: ErrorState(message: 'This session no longer exists.')),
          );
        }
        _hadSession = true;
        return _body(context, s, app);
      },
    );
  }

  Widget _body(BuildContext context, CardioSession s, AppController app) {
    final c = context.sx;
    final units = CardioUnits(app.profile.profile.cardioDistanceUnitKm);
    final all = app.cardio.sessions;
    final n = cardioSessionNumber(all, s);
    final pr = cardioPrLabel(s, all);
    final tiles = _tiles(s, units);
    final prev = _previousSameKind(all, s);

    return SxScaffold(
      topBar: SxTopBar(
        title: 'Session Summary',
        subtitle: 'SESSION #$n',
        actions: [
          SxIconButton(icon: Icons.edit_outlined, tooltip: 'Edit session', onPressed: () => AppNav.editCardio(context, s.id)),
          SxIconButton(icon: Icons.delete_outline, tooltip: 'Delete session', onPressed: () => _delete(s), iconColor: c.danger),
        ],
      ),
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        SxButton(label: 'Edit session metrics', icon: Icons.tune, variant: SxButtonVariant.secondary, onPressed: () => AppNav.editCardio(context, s.id)),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => _delete(s),
          child: Text('Delete session entry', style: SxText.bodyMd.copyWith(color: c.danger)),
        ),
      ]),
      children: [
        SxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(cardioKindIcon(s.kind), color: c.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(s.kind.label, style: SxText.headlineMd.copyWith(color: c.textHigh), overflow: TextOverflow.ellipsis)),
              if (pr != null) SxPop(child: PrBadge(pr)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: c.textBody),
              const SizedBox(width: 6),
              Expanded(
                child: Text('${Fmt.dateLong(s.workoutDate)}, ${s.workoutDate.year} • ${Fmt.time(s.workoutDate)}',
                    style: SxText.bodySm.copyWith(color: c.textBody), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ]),
            if (!Fmt.sameDay(s.workoutDate, s.meta.createdAt))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('BACKDATED • ENTERED ${Fmt.dateMedium(s.meta.createdAt).toUpperCase()}',
                    style: SxText.labelXs.copyWith(color: c.primary)),
              ),
            const SizedBox(height: SxSpace.md),
            _grid(context, tiles),
          ]),
        ),
        if (s.routeName.isNotEmpty)
          SxCard(
            child: Row(children: [
              Icon(Icons.place_outlined, color: c.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ROUTE', style: SxText.labelCaps.copyWith(color: c.textBody)),
                  Text(s.routeName, style: SxText.headlineSm.copyWith(color: c.textHigh), overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),
        if (prev != null) _delta(context, s, prev, units),
        if (s.notes.isNotEmpty)
          SxCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SESSION NOTES', style: SxText.labelCaps.copyWith(color: c.textBody)),
              const SizedBox(height: 6),
              Text(s.notes, style: SxText.bodyMd.copyWith(color: c.textHigh)),
            ]),
          ),
        SxCard(
          color: c.surface2,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.sensors_off_outlined, color: c.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'GPS route, heart-rate zones, cadence, elevation and kilometre splits need a connected sensor, which is not available in this build.',
                style: SxText.bodySm.copyWith(color: c.textBody),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  List<_Tile> _tiles(CardioSession s, CardioUnits u) {
    final f = s.kind.fields;
    final out = <_Tile>[_Tile('Duration', Fmt.clock(s.durationSeconds), s.durationSeconds >= 3600 ? 'H:M:S' : 'MIN', false)];
    if (s.distanceKm != null) out.add(_Tile('Distance', u.distanceText(s.distanceKm), u.distanceUnit.toUpperCase(), true));
    if (CardioPace.has(s.kind) && s.paceSecPerKm != null) {
      out.add(_Tile('Avg pace', CardioPace.text(s.kind, s.paceSecPerKm, miles: !u.km), CardioPace.unit(s.kind, miles: !u.km).toUpperCase(), false));
    }
    final speed = s.kind == CardioKind.treadmill ? (s.speedKmh ?? s.avgSpeedKmh) : (f.contains(CardioField.speed) ? s.avgSpeedKmh : null);
    if (speed != null) out.add(_Tile('Avg speed', u.speedText(speed), u.speedUnit.toUpperCase(), false));
    if (s.inclinePct != null) out.add(_Tile('Incline', Fmt.number(s.inclinePct!), '%', false));
    if (s.resistance != null) out.add(_Tile('Resistance', '${s.resistance}', 'LEVEL', false));
    if (s.calories != null) out.add(_Tile('Energy burn', Fmt.thousands(s.calories!), 'KCAL', false));
    if (s.avgHeartRate != null) out.add(_Tile('Avg heart rate', '${s.avgHeartRate}', 'BPM', false));
    if (s.rpe != null) out.add(_Tile('Effort (RPE)', Fmt.number(s.rpe!), '/ 10', false));
    return out;
  }

  Widget _grid(BuildContext context, List<_Tile> tiles) {
    final c = context.sx;
    return LayoutBuilder(builder: (context, cons) {
      final w = (cons.maxWidth - 8) / 2;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in tiles)
          SizedBox(
            width: w,
            child: SxInset(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.label.toUpperCase(), style: SxText.labelXs.copyWith(color: c.textBody), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MetricValue(t.value, unit: t.unit, style: SxText.metricLg, color: t.accent ? c.primary : c.textHigh),
                ),
              ]),
            ),
          ),
      ]);
    });
  }

  CardioSession? _previousSameKind(List<CardioSession> all, CardioSession s) {
    CardioSession? best;
    for (final x in all) {
      if (x.id == s.id || x.kind != s.kind || !x.workoutDate.isBefore(s.workoutDate)) continue;
      if (best == null || x.workoutDate.isAfter(best.workoutDate)) best = x;
    }
    return best;
  }

  Widget _delta(BuildContext context, CardioSession s, CardioSession p, CardioUnits u) {
    final c = context.sx;
    final rows = <Widget>[];
    Widget chip(String text, bool good) {
      final col = good ? c.primary : c.danger;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: col.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(SxRadius.sm)),
        child: Text(text, style: SxText.labelCaps.copyWith(color: col, fontWeight: FontWeight.w700)),
      );
    }

    final sp = s.paceSecPerKm, pp = p.paceSecPerKm;
    if (sp != null && pp != null && CardioPace.has(s.kind)) {
      final d = (CardioPace.convert(s.kind, sp, miles: !u.km)! - CardioPace.convert(s.kind, pp, miles: !u.km)!).round();
      if (d != 0) rows.add(chip('${d.abs()}s${CardioPace.unit(s.kind, miles: !u.km)} ${d < 0 ? 'faster' : 'slower'}', d < 0));
    }
    if (s.distanceKm != null && p.distanceKm != null) {
      final d = u.distance(s.distanceKm!) - u.distance(p.distanceKm!);
      if (d.abs() >= 0.01) rows.add(chip('${Fmt.number(d.abs(), decimals: 2)} ${u.distanceUnit} ${d > 0 ? 'further' : 'shorter'}', d > 0));
    }
    final dd = s.durationSeconds - p.durationSeconds;
    if (dd.abs() >= 30) rows.add(chip('${Fmt.durationShort(dd.abs())} ${dd > 0 ? 'longer' : 'shorter'}', dd > 0));
    final prevLine = p.distanceKm != null
        ? '${u.distanceText(p.distanceKm)} ${u.distanceUnit} • ${Fmt.clock(p.durationSeconds)}'
        : Fmt.clock(p.durationSeconds);
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('HISTORICAL DELTA', style: SxText.labelCaps.copyWith(color: c.textBody))),
          Icon(Icons.trending_up, size: 16, color: c.primary),
        ]),
        const SizedBox(height: 8),
        Text('Previous ${s.kind.label} (${Fmt.dateShort(p.workoutDate)})', style: SxText.bodySm.copyWith(color: c.textBody)),
        const SizedBox(height: 4),
        Text(prevLine, style: SxText.metricMd.copyWith(color: c.textHigh)),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: rows),
        ],
      ]),
    );
  }
}

class _Tile {
  const _Tile(this.label, this.value, this.unit, this.accent);
  final String label;
  final String value;
  final String unit;
  final bool accent;
}
