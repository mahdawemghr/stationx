import 'package:flutter/material.dart';

import '../../../core/theme/sx_spacing.dart';
import '../../../core/theme/sx_theme.dart';
import '../../../core/theme/sx_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/domain.dart';
import '../../cardio/cardio_kind_presentation.dart';
import '../active_workout_controller.dart';
import 'timers.dart';

const _kmPerMile = 1.609344;

IconData cardioIcon(CardioKind k) => cardioKindGlyph(k);

String _targetLine(CardioDraft d) {
  final parts = <String>[
    if (d.targetMinutes != null) '${d.targetMinutes} min',
    if (d.speedKmh != null && d.kind.fields.contains(CardioField.speed)) '${Fmt.number(d.speedKmh!)} km/h',
    if (d.inclinePct != null && d.kind.fields.contains(CardioField.incline)) '${Fmt.number(d.inclinePct!)}% Incline',
    if (d.resistance != null && d.kind.fields.contains(CardioField.resistance)) 'Resistance ${d.resistance}',
  ];
  return parts.isEmpty ? 'No target set' : 'Target: ${parts.join(' • ')}';
}

/// Cardio finisher (or extra cardio) block of a running session. Fields adapt
/// to [CardioKind.fields]; no sensor metrics are shown (none are available).
class CardioBlock extends StatelessWidget {
  const CardioBlock({super.key, required this.draft, required this.useKm, required this.onRemove});
  final CardioDraft draft;
  final bool useKm;
  final VoidCallback onRemove;

  String _dist(double? km) => km == null ? '—' : Fmt.km(km, miles: !useKm);

  Future<void> _editDistance(BuildContext context) async {
    final cur = draft.distanceKm;
    final v = await showNumericKeypad(context,
        title: 'Distance (${useKm ? 'km' : 'mi'})',
        initial: cur == null ? null : (useKm ? cur : cur / _kmPerMile),
        step: 0.1,
        unit: useKm ? 'km' : 'mi');
    if (v != null) draft.update(distanceKm: useKm ? v : v * _kmPerMile);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final k = draft.kind;
    final hasAdjust = k.fields.any((f) => f == CardioField.speed || f == CardioField.incline || f == CardioField.resistance);
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        final tiles = <Widget>[
          _TimeTile(draft: draft),
          if (k.hasDistance)
            _Tile(
              label: 'Distance',
              icon: Icons.straighten,
              value: _dist(draft.distanceKm),
              unit: useKm ? 'KM' : 'MI',
              caption: _distanceCaption(),
              onTap: () => _editDistance(context),
            ),
          if (k.fields.contains(CardioField.speed) || k.fields.contains(CardioField.incline))
            _Tile(
              label: k.fields.contains(CardioField.incline) ? 'Speed / Incline' : 'Speed',
              icon: Icons.speed,
              value: draft.speedKmh == null ? '—' : Fmt.number(draft.speedKmh!),
              unit: 'KM/H',
              caption: k.fields.contains(CardioField.incline)
                  ? 'Incline: ${draft.inclinePct == null ? '—' : '${Fmt.number(draft.inclinePct!)}%'}'
                  : null,
            ),
          if (k.fields.contains(CardioField.resistance))
            _Tile(
              label: 'Resistance',
              icon: Icons.tune,
              value: draft.resistance == null ? '—' : '${draft.resistance}',
              unit: 'LVL',
            ),
          if (k.fields.contains(CardioField.pace))
            SecondTicker(
              active: draft.running,
              builder: (_, _) => _Tile(
                label: 'Pace',
                icon: Icons.speed,
                value: Fmt.pace(CardioMetrics.paceSecPerKm(draft.seconds, draft.distanceKm)),
                unit: '/KM',
              ),
            ),
        ];
        return SxCard(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(cardioIcon(k), color: c.primary, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(k.label.toUpperCase(),
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.headlineMd.copyWith(color: c.textHigh, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              StatusPill(draft.running ? 'Live' : (draft.started ? 'Paused' : 'Ready'),
                  dot: true, color: draft.running ? c.primary : c.textBody),
            ]),
            const SizedBox(height: 4),
            Text(_targetLine(draft), style: SxText.bodyMd.copyWith(color: c.textBody)),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, cons) {
              final w = (cons.maxWidth - 8) / 2;
              return Wrap(spacing: 8, runSpacing: 8, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
            }),
            const SizedBox(height: 12),
            SxButton(
              label: draft.running ? 'Pause' : (draft.started ? 'Resume' : 'Start cardio'),
              icon: draft.running ? Icons.pause : Icons.play_arrow,
              height: 48,
              variant: draft.running ? SxButtonVariant.secondary : SxButtonVariant.primary,
              onPressed: draft.toggle,
            ),
            const SizedBox(height: 8),
            Row(children: [
              if (hasAdjust)
                Expanded(
                  child: _BlockAction(
                    icon: Icons.tune,
                    label: k.fields.contains(CardioField.resistance) && !k.fields.contains(CardioField.speed)
                        ? 'Adjust Resistance'
                        : 'Adjust Speed/Incline',
                    onTap: () => showSxSheet<void>(context, builder: (_) => _AdjustSheet(draft: draft)),
                  ),
                ),
              if (hasAdjust && draft.targetMinutes != null) const SizedBox(width: 8),
              if (draft.targetMinutes != null)
                Expanded(
                  child: _BlockAction(
                    icon: Icons.more_time,
                    label: '+ Add 5 min',
                    highlight: true,
                    onTap: () => draft.update(targetMinutes: draft.targetMinutes! + 5),
                  ),
                ),
            ]),
            if (!draft.started)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onRemove,
                  icon: Icon(Icons.close, size: 16, color: c.textMuted),
                  label: Text('Remove cardio block', style: SxText.bodySm.copyWith(color: c.textMuted)),
                ),
              ),
          ]),
        );
      },
    );
  }

  String? _distanceCaption() {
    final pace = CardioMetrics.paceSecPerKm(draft.seconds, draft.distanceKm);
    final parts = <String>[
      if (draft.distanceIsEstimate && draft.distanceKm != null) 'EST. FROM SPEED',
      if (pace != null) 'Pace: ${Fmt.pace(pace)}/km',
    ];
    return parts.isEmpty ? 'Tap to enter' : parts.join(' • ');
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.draft});
  final CardioDraft draft;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final target = draft.targetMinutes;
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md), border: Border.all(color: c.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('RUNNING TIME', maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelXs.copyWith(color: c.textBody))),
          Icon(Icons.schedule, size: 16, color: c.textBody),
        ]),
        const SizedBox(height: 6),
        SecondTicker(
          active: draft.running,
          builder: (_, _) {
            final s = draft.seconds;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisSize: MainAxisSize.min, children: [
                  Text(Fmt.clock(s), style: SxText.metricLg.copyWith(color: c.primary)),
                  if (target != null) Text(' / ${Fmt.clock(target * 60)}', style: SxText.metricSm.copyWith(color: c.textBody)),
                ]),
              ),
              if (target != null) ...[
                const SizedBox(height: 8),
                SxLinearMeter(value: target == 0 ? 0 : s / (target * 60), height: 4),
              ],
            ]);
          },
        ),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.icon, required this.value, this.unit, this.caption, this.onTap});
  final String label;
  final IconData icon;
  final String value;
  final String? unit;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      button: onTap != null,
      label: '$label $value ${unit ?? ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SxRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md), border: Border.all(color: c.hairline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelXs.copyWith(color: c.textBody))),
              Icon(icon, size: 16, color: c.textBody),
            ]),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisSize: MainAxisSize.min, children: [
                Text(value, style: SxText.metricLg.copyWith(color: value == '—' ? c.textMuted : c.textHigh)),
                if (unit != null) Text(' $unit', style: SxText.labelXs.copyWith(color: c.textBody)),
              ]),
            ),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(caption!, maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _BlockAction extends StatelessWidget {
  const _BlockAction({required this.icon, required this.label, required this.onTap, this.highlight = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SxRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md), border: Border.all(color: c.hairline)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: highlight ? c.primary : c.textBody),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SxText.labelUi.copyWith(color: highlight ? c.primary : c.textHigh, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Speed / incline / resistance steppers for the live block.
class _AdjustSheet extends StatelessWidget {
  const _AdjustSheet({required this.draft});
  final CardioDraft draft;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final f = draft.kind.fields;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ADJUST ${draft.kind.label.toUpperCase()}', style: SxText.labelCaps.copyWith(color: c.textBody)),
          const SizedBox(height: 12),
          if (f.contains(CardioField.speed))
            _Stepper(
              label: 'Speed',
              unit: 'km/h',
              value: draft.speedKmh ?? 0,
              step: 0.1,
              max: 40,
              onChanged: (v) => draft.update(speedKmh: v),
            ),
          if (f.contains(CardioField.incline))
            _Stepper(
              label: 'Incline',
              unit: '%',
              value: draft.inclinePct ?? 0,
              step: 0.5,
              max: 30,
              onChanged: (v) => draft.update(inclinePct: v),
            ),
          if (f.contains(CardioField.resistance))
            _Stepper(
              label: 'Resistance',
              unit: 'lvl',
              value: (draft.resistance ?? 0).toDouble(),
              step: 1,
              max: 50,
              decimals: false,
              onChanged: (v) => draft.update(resistance: v.round()),
            ),
          const SizedBox(height: 8),
          SxButton(label: 'Done', onPressed: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.unit, required this.value, required this.step, required this.max, required this.onChanged, this.decimals = true});
  final String label;
  final String unit;
  final double value;
  final double step;
  final double max;
  final bool decimals;
  final ValueChanged<double> onChanged;

  double _clamp(double v) => double.parse(v.clamp(0, max).toStringAsFixed(2));

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(child: Text(label.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textHigh))),
        SxIconButton(icon: Icons.remove, tooltip: 'Decrease $label', onPressed: () => onChanged(_clamp(value - step))),
        InkWell(
          onTap: () async {
            final v = await showNumericKeypad(context, title: '$label ($unit)', initial: value, allowDecimal: decimals, step: step, max: max);
            if (v != null) onChanged(_clamp(v));
          },
          child: Container(
            constraints: const BoxConstraints(minWidth: 84, minHeight: 48),
            alignment: Alignment.center,
            child: Text('${Fmt.number(value)} $unit', style: SxText.metricMd.copyWith(color: c.primary)),
          ),
        ),
        SxIconButton(icon: Icons.add, tooltip: 'Increase $label', onPressed: () => onChanged(_clamp(value + step))),
      ]),
    );
  }
}

/// Pick the kind of cardio block to add to a strength session.
Future<CardioKind?> showCardioKindPicker(BuildContext context) {
  return showSxSheet<CardioKind>(
    context,
    builder: (ctx) {
      final c = ctx.sx;
      final kinds = CardioKind.values.where((k) => k != CardioKind.custom).toList();
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.lg),
        children: [
          Text('ADD CARDIO BLOCK', style: SxText.labelCaps.copyWith(color: c.textBody)),
          const SizedBox(height: 8),
          for (final k in kinds)
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 52,
              leading: Icon(cardioIcon(k), color: c.primary),
              title: Text(k.label, style: SxText.bodyLg.copyWith(color: c.textHigh)),
              onTap: () => Navigator.pop(ctx, k),
            ),
        ],
      );
    },
  );
}
