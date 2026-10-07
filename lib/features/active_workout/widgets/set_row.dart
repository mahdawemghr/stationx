import 'package:flutter/material.dart';

import '../../../core/theme/sx_spacing.dart';
import '../../../core/theme/sx_theme.dart';
import '../../../core/theme/sx_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/domain.dart';
import '../active_workout_controller.dart';

const double _setColW = 34;
const double _doneColW = 48;

/// Column captions: SET · PREV · KG · REPS · DONE.
class SetTableHeader extends StatelessWidget {
  const SetTableHeader({super.key, required this.unit});
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final s = SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10);
    Widget cell(String t, int flex, {TextAlign a = TextAlign.center}) =>
        Expanded(flex: flex, child: Text(t, textAlign: a, maxLines: 1, overflow: TextOverflow.ellipsis, style: s));
    // Column headings are visual only: every value cell announces its own label.
    return ExcludeSemantics(
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(children: [
        SizedBox(width: _setColW, child: Text('SET', style: s, maxLines: 1)),
        const SizedBox(width: 6),
        cell('PREV', 2),
        const SizedBox(width: 6),
        cell(Fmt.unit(unit).toUpperCase(), 3),
        const SizedBox(width: 6),
        cell('REPS', 2),
        const SizedBox(width: 6),
        SizedBox(width: _doneColW, child: Text('DONE', textAlign: TextAlign.center, style: s, maxLines: 1)),
      ]),
    ));
  }
}

/// One editable set row. Tapping KG / REPS opens the numeric keypad sheet
/// (handled by the caller); the 28px squircle toggles completion.
class SetRowView extends StatelessWidget {
  const SetRowView({
    super.key,
    required this.index,
    required this.set,
    required this.prev,
    required this.active,
    required this.unit,
    required this.onWeight,
    required this.onReps,
    required this.onToggle,
  });

  final int index;
  final SetDraft set;
  final SetLog? prev;
  final bool active;
  final WeightUnit unit;
  final VoidCallback onWeight;
  final VoidCallback onReps;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final num = (index + 1).toString().padLeft(2, '0');
    return ClipRRect(
      borderRadius: BorderRadius.circular(SxRadius.md),
      child: Stack(children: [
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(SxRadius.md),
            border: Border.all(color: active ? c.primaryBorder : c.hairline),
          ),
      child: Row(children: [
        SizedBox(
          width: _setColW,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(num, semanticsLabel: 'Set ${index + 1}', style: SxText.metricMd.copyWith(color: active ? c.primary : c.textMuted)),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              prev == null ? '—' : '${Fmt.weight(prev!.weightKg, unit)} × ${prev!.reps}',
              semanticsLabel: prev == null
                  ? 'No previous set'
                  : 'Previous ${Fmt.weight(prev!.weightKg, unit)} ${Fmt.unit(unit) == 'kg' ? 'kilograms' : 'pounds'}, ${prev!.reps} reps',
              style: SxText.metricSm.copyWith(color: c.textMuted),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 3,
          child: _ValueCell(
            label: 'Weight',
            value: set.weightKg <= 0 ? '—' : Fmt.weight(set.weightKg, unit),
            done: set.done,
            onTap: onWeight,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: _ValueCell(label: 'Reps', value: set.reps <= 0 ? '—' : '${set.reps}', done: set.done, onTap: onReps),
        ),
        const SizedBox(width: 6),
        SizedBox(width: _doneColW, child: Center(child: _DoneBox(done: set.done, onTap: onToggle, index: index))),
      ]),
        ),
        if (active) Positioned(left: 0, top: 0, bottom: 0, width: 3, child: ColoredBox(color: c.primary)),
      ]),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.label, required this.value, required this.done, required this.onTap});
  final String label;
  final String value;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      container: true,
      button: true,
      label: '$label $value',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SxRadius.base),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: c.surface3,
            borderRadius: BorderRadius.circular(SxRadius.base),
            border: Border.all(color: done ? c.primaryBorder : c.hairline),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: SxText.metricMd.copyWith(color: value == '—' ? c.textMuted : c.textHigh)),
          ),
        ),
      ),
    );
  }
}

class _DoneBox extends StatelessWidget {
  const _DoneBox({required this.done, required this.onTap, required this.index});
  final bool done;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      container: true,
      checked: done,
      label: 'Set ${index + 1} done',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SxRadius.md),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: SxMotion.fast,
              curve: Curves.easeOut,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? c.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: done ? c.primary : c.hairline, width: 1.5),
              ),
              child: AnimatedSwitcher(
                duration: SxMotion.fast,
                child: done
                    ? Icon(Icons.check, key: const ValueKey('c'), size: 20, color: c.onPrimary)
                    : const SizedBox.shrink(key: ValueKey('e')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
