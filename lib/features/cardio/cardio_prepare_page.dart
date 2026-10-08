import 'package:flutter/material.dart';

import 'cardio_pace.dart';
import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_colors.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'cardio_home_support.dart';

enum _Objective { open, time, distance }

/// Pre-session setup: objective (open / time / distance), target and a hint
/// derived from the user's last session of the same activity.
class CardioPreparePage extends StatefulWidget {
  const CardioPreparePage({super.key, required this.kind, this.customActivityId});
  final CardioKind kind;
  final String? customActivityId;

  @override
  State<CardioPreparePage> createState() => _CardioPreparePageState();
}

class _CardioPreparePageState extends State<CardioPreparePage> {
  _Objective _obj = _Objective.open;
  int _minutes = 30;
  double _km = 5;
  bool _seeded = false;

  CardioSession? _last(CardioRepository repo) =>
      lastOfKind(repo.sessions, widget.kind, customId: widget.customActivityId);

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.cardio, app.profile]),
      builder: (context, _) {
        final miles = !app.profile.profile.cardioDistanceUnitKm;
        final last = _last(app.cardio);
        if (!_seeded) {
          _seeded = true;
          if (last != null) {
            _minutes = ((last.durationSeconds / 60 / 5).round() * 5).clamp(5, 300);
            if (last.distanceKm != null && last.distanceKm! > 0) _km = (last.distanceKm! * 2).round() / 2;
          }
        }
        CustomCardioActivity? custom;
        for (final a in app.cardio.customActivities) {
          if (a.id == widget.customActivityId) custom = a;
        }
        final name = custom?.name ?? widget.kind.label;
        final icon = custom != null ? cardioIconForKey(custom.iconKey) : cardioKindIcon(widget.kind);
        final hasDistance = custom != null ? custom.fields.contains(CardioField.distance) : widget.kind.hasDistance;
        final objectives = [
          _Objective.open,
          _Objective.time,
          if (hasDistance) _Objective.distance,
        ];
        if (!objectives.contains(_obj)) _obj = _Objective.open;

        return SxScaffold(
          topBar: SxTopBar(title: name, subtitle: 'PREPARE SESSION'),
          gap: SxSpace.md,
          bottom: SxButton(
            label: 'Start $name',
            trailingIcon: Icons.play_arrow,
            onPressed: _start,
          ),
          children: [
            SxCard(
              child: Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(SxRadius.md)),
                  child: Icon(icon, color: c.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('DISCIPLINE', style: SxText.labelCaps.copyWith(color: c.textBody)),
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.headlineMd.copyWith(color: c.textHigh)),
                  ]),
                ),
              ]),
            ),
            SectionHeader('Select objective', trailingText: switch (_obj) {
              _Objective.open => 'Open session',
              _Objective.time => 'Target duration',
              _Objective.distance => 'Target distance',
            }),
            Row(children: [
              for (var i = 0; i < objectives.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _ObjectiveTile(
                    icon: switch (objectives[i]) {
                      _Objective.open => Icons.all_inclusive,
                      _Objective.time => Icons.timer_outlined,
                      _Objective.distance => Icons.straighten,
                    },
                    label: switch (objectives[i]) {
                      _Objective.open => 'Open',
                      _Objective.time => 'Time',
                      _Objective.distance => 'Dist',
                    },
                    selected: objectives[i] == _obj,
                    onTap: () => setState(() => _obj = objectives[i]),
                  ),
                ),
              ],
            ]),
            if (_obj == _Objective.time) _timeTarget(c, last, miles),
            if (_obj == _Objective.distance) _distanceTarget(c, last, miles),
            if (_obj == _Objective.open)
              SxCard(
                child: Row(children: [
                  Icon(Icons.all_inclusive, color: c.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Open session: no target. Track time${hasDistance ? ' and log distance' : ''} and finish whenever you are done.',
                        style: SxText.bodyMd.copyWith(color: c.textBody)),
                  ),
                ]),
              ),
            if (last != null) _HintCard(last: last, kind: widget.kind, miles: miles),
          ],
        );
      },
    );
  }

  Widget _timeTarget(SxColors c, CardioSession? last, bool miles) {
    final pace = last?.paceSecPerKm;
    return SxCard(
      child: Column(children: [
        Align(alignment: Alignment.centerLeft, child: Text('TARGET DURATION', style: SxText.labelCaps.copyWith(color: c.textBody))),
        const SizedBox(height: SxSpace.md),
        _Stepper(
          value: '$_minutes',
          unit: 'MIN',
          onMinus: () => setState(() => _minutes = (_minutes - 5).clamp(5, 600)),
          onPlus: () => setState(() => _minutes = (_minutes + 5).clamp(5, 600)),
          onEdit: () async {
            final v = await showNumericKeypad(context, title: 'Target duration', initial: _minutes.toDouble(), allowDecimal: false, unit: 'min', min: 1, max: 600);
            if (v != null && v > 0) setState(() => _minutes = v.round());
          },
        ),
        const SizedBox(height: SxSpace.sm),
        Wrap(spacing: 8, children: [
          for (final d in const [-5, 5, 15])
            ActionChip(
              label: Text('${d > 0 ? '+' : '−'} ${d.abs()} min', style: SxText.metricSm.copyWith(color: c.textBody)),
              backgroundColor: c.surface2,
              side: BorderSide(color: c.hairline),
              onPressed: () => setState(() => _minutes = (_minutes + d).clamp(5, 600)),
            ),
        ]),
        if (pace != null && last!.distanceKm != null) ...[
          Divider(height: SxSpace.lg, color: c.hairline),
          Row(children: [
            Icon(Icons.analytics_outlined, size: 18, color: c.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Estimated ~${Fmt.number(_minutes * 60 / pace * (miles ? 0.621371 : 1), decimals: 1)} ${miles ? 'mi' : 'km'} at ${Fmt.pace(miles ? pace * 1.609344 : pace)}/${miles ? 'mi' : 'km'} (your last pace)',
                  style: SxText.bodyMd.copyWith(color: c.textBody)),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _distanceTarget(SxColors c, CardioSession? last, bool miles) {
    final pace = last?.paceSecPerKm;
    final shown = miles ? _km * 0.621371 : _km;
    final u = miles ? 'MI' : 'KM';
    void bump(double d) => setState(() => _km = (_km + d).clamp(0.5, 500).toDouble());
    return SxCard(
      child: Column(children: [
        Align(alignment: Alignment.centerLeft, child: Text('TARGET DISTANCE', style: SxText.labelCaps.copyWith(color: c.textBody))),
        const SizedBox(height: SxSpace.md),
        _Stepper(
          value: Fmt.number(shown),
          unit: u,
          onMinus: () => bump(-0.5),
          onPlus: () => bump(0.5),
          onEdit: () async {
            final v = await showNumericKeypad(context, title: 'Target distance', initial: shown, unit: u.toLowerCase(), min: 0.1, max: 500);
            if (v != null && v > 0) setState(() => _km = miles ? v / 0.621371 : v);
          },
        ),
        const SizedBox(height: SxSpace.sm),
        Wrap(spacing: 8, children: [
          for (final d in const [-1.0, 1.0, 5.0])
            ActionChip(
              label: Text('${d > 0 ? '+' : '−'} ${d.abs().round()} ${u.toLowerCase()}', style: SxText.metricSm.copyWith(color: c.textBody)),
              backgroundColor: c.surface2,
              side: BorderSide(color: c.hairline),
              onPressed: () => bump(miles ? d / 0.621371 : d),
            ),
        ]),
        if (pace != null) ...[
          Divider(height: SxSpace.lg, color: c.hairline),
          Row(children: [
            Icon(Icons.analytics_outlined, size: 18, color: c.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Estimated ~${Fmt.durationShort((_km * pace).round())} at ${Fmt.pace(miles ? pace * 1.609344 : pace)}/${miles ? 'mi' : 'km'} (your last pace)',
                  style: SxText.bodyMd.copyWith(color: c.textBody)),
            ),
          ]),
        ],
      ]),
    );
  }

  void _start() {
    AppNav.activeCardio(
      context,
      widget.kind,
      targetMinutes: _obj == _Objective.time ? _minutes : null,
      targetKm: _obj == _Objective.distance ? double.parse(_km.toStringAsFixed(2)) : null,
      customActivityId: widget.customActivityId,
      replace: true,
    );
  }
}

class _ObjectiveTile extends StatelessWidget {
  const _ObjectiveTile({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final fg = selected ? c.onAccent : c.textBody;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? c.primary : c.surface1,
        borderRadius: BorderRadius.circular(SxRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(SxRadius.lg),
          onTap: onTap,
          child: Container(
            height: 72,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(SxRadius.lg), border: Border.all(color: selected ? c.primary : c.hairline)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: fg),
              const SizedBox(height: 6),
              Text(label.toUpperCase(), style: SxText.labelCaps.copyWith(color: fg, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.unit, required this.onMinus, required this.onPlus, required this.onEdit});
  final String value;
  final String unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(children: [
      SxIconButton(icon: Icons.remove, tooltip: 'Decrease', size: 56, onPressed: onMinus),
      Expanded(
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(SxRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(value, style: SxText.metricXl.copyWith(color: c.textHigh, fontSize: 56)),
                const SizedBox(width: 6),
                Text(unit, style: SxText.metricMd.copyWith(color: c.primary)),
              ]),
            ),
          ),
        ),
      ),
      SxIconButton(icon: Icons.add, tooltip: 'Increase', size: 56, onPressed: onPlus),
    ]);
  }
}

/// "Last session" progression hint — facts from history only.
class _HintCard extends StatelessWidget {
  const _HintCard({required this.last, required this.kind, required this.miles});
  final CardioSession last;
  final CardioKind kind;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final pace = last.paceSecPerKm;
    final parts = <String>['${(last.durationSeconds / 60).round()} min'];
    if (last.distanceKm != null) parts.add('${Fmt.km(last.distanceKm, miles: miles)} ${miles ? 'mi' : 'km'}');
    final tip = (pace != null && CardioPace.has(kind))
        ? ' Try holding ${CardioPace.withUnit(kind, pace, miles: miles)} again for a steady aerobic session.'
        : '';
    return SxCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(SxRadius.base)),
          child: Icon(Icons.history, color: c.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LAST SESSION • ${Fmt.relativeDay(last.workoutDate).toUpperCase()}', style: SxText.labelCaps.copyWith(color: c.primary)),
            const SizedBox(height: 4),
            Text('${parts.join(' • ')}.$tip', style: SxText.bodyMd.copyWith(color: c.textHigh)),
          ]),
        ),
      ]),
    );
  }
}
