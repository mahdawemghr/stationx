import 'package:flutter/material.dart';

import '../../../core/theme/sx_spacing.dart';
import '../../../core/theme/sx_theme.dart';
import '../../../core/theme/sx_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/domain.dart';

/// Plate breakdown per side for a barbell target. Plate math is metric (kg);
/// a lb user sees the lb equivalent of the target but plates stay in kg.
Future<void> showPlateCalculator(BuildContext context, {required double targetKg, required WeightUnit unit}) {
  return showSxSheet<void>(context, builder: (_) => _PlateBody(targetKg: targetKg, unit: unit));
}

class _PlateBody extends StatefulWidget {
  const _PlateBody({required this.targetKg, required this.unit});
  final double targetKg;
  final WeightUnit unit;

  @override
  State<_PlateBody> createState() => _PlateBodyState();
}

class _PlateBodyState extends State<_PlateBody> {
  late double _target = widget.targetKg > 0 ? widget.targetKg : 60;
  double _bar = 20;

  Future<void> _editTarget() async {
    final v = await showNumericKeypad(context,
        title: 'Target weight',
        initial: Fmt.toDisplayWeight(_target, widget.unit),
        step: widget.unit == WeightUnit.kg ? 2.5 : 5,
        unit: Fmt.unit(widget.unit));
    if (v != null && mounted) setState(() => _target = Fmt.fromDisplayWeight(v, widget.unit));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final plan = PlateCalculator.plan(targetKg: _target, barKg: _bar);
    final tooLight = _target < _bar;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.lg),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PLATE CALCULATOR', style: SxText.labelCaps.copyWith(color: c.textBody)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: SxInset(
              onTap: _editTarget,
              child: Row(children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('${Fmt.weight(_target, widget.unit)} ${Fmt.unit(widget.unit)}',
                        style: SxText.metricLg.copyWith(color: c.textHigh)),
                  ),
                ),
                Icon(Icons.edit, size: 18, color: c.textMuted),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Text('BAR', style: SxText.labelXs.copyWith(color: c.textBody)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final b in const [20.0, 15.0, 10.0])
            SxChip(label: '${Fmt.number(b)} kg', selected: _bar == b, onTap: () => setState(() => _bar = b)),
        ]),
        const SizedBox(height: SxSpace.md),
        Text('PER SIDE', style: SxText.labelXs.copyWith(color: c.textBody)),
        const SizedBox(height: 8),
        if (tooLight)
          Text('Target is lighter than the bar.', style: SxText.bodyMd.copyWith(color: c.danger))
        else if (plan.perSide.isEmpty)
          Text('Bar only.', style: SxText.bodyMd.copyWith(color: c.textBody))
        else
          Wrap(spacing: 8, runSpacing: 8, children: [for (final p in plan.perSide) _Plate(kg: p)]),
        if (plan.remainderKg > 0) ...[
          const SizedBox(height: 10),
          Text('Closest loadable weight is ${Fmt.number(_target - plan.remainderKg)} kg (${Fmt.number(plan.remainderKg)} kg short).',
              style: SxText.bodySm.copyWith(color: c.textBody)),
        ],
        if (widget.unit == WeightUnit.lb) ...[
          const SizedBox(height: 10),
          Text('Plates are shown in kg.', style: SxText.bodySm.copyWith(color: c.textMuted)),
        ],
      ]),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.kg});
  final double kg;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final size = 36.0 + (kg >= 20 ? 14 : kg >= 10 ? 8 : kg >= 5 ? 4 : 0);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surface2,
        shape: BoxShape.circle,
        border: Border.all(color: c.primaryBorder, width: 1.5),
      ),
      child: Text(Fmt.number(kg), style: SxText.metricSm.copyWith(color: c.primary, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
