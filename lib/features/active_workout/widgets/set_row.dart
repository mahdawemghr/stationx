import 'package:flutter/material.dart';

import '../../../core/theme/sx_spacing.dart';
import '../../../core/theme/sx_theme.dart';
import '../../../core/theme/sx_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/domain.dart';
import '../active_workout_controller.dart';

const double _setColW = 24;
const double _doneColW = 48;

/// Column captions: SET · KG · REPS · DONE (PREV lives on each row's second line).
class SetTableHeader extends StatelessWidget {
  const SetTableHeader({super.key, required this.unit});
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final s = SxText.labelXs.copyWith(color: c.textBody);
    Widget cell(String t, int flex, {TextAlign a = TextAlign.center}) =>
        Expanded(flex: flex, child: Text(t, textAlign: a, maxLines: 1, overflow: TextOverflow.ellipsis, style: s));
    // Column headings are visual only: every value cell announces its own label.
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          SizedBox(width: _setColW, child: Text('SET', style: s, maxLines: 1, overflow: TextOverflow.clip)),
          const SizedBox(width: 6),
          cell(Fmt.unit(unit).toUpperCase(), 3),
          const SizedBox(width: 6),
          cell('REPS', 2),
          const SizedBox(width: 6),
          SizedBox(width: _doneColW, child: Text('DONE', textAlign: TextAlign.center, style: s, maxLines: 1)),
        ]),
      ),
    );
  }
}

/// One editable set row. Tapping KG / REPS opens the numeric keypad sheet
/// (handled by the caller); the check toggles completion. The previous
/// session's set is a small second line so KG / REPS / DONE keep >= 48dp even at
/// 320dp. The active row also shows inline +/- steppers (the keypad stays).
///
/// Motion: a short highlight flash when the set becomes done (SxCheck pops by
/// itself), the active-row border / accent bar cross-fade to the next row, and
/// weight / reps cross-fade when their value changes. Nothing here blocks input:
/// every animation is visual only and skipped under reduced motion.
class SetRowView extends StatefulWidget {
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
    this.onWeightStep,
    this.onRepsStep,
  });

  final int index;
  final SetDraft set;
  final SetLog? prev;
  final bool active;
  final WeightUnit unit;
  final VoidCallback onWeight;
  final VoidCallback onReps;
  final VoidCallback onToggle;

  /// +1 / -1 steppers (weight uses the unit's increment). Null hides the stepper line.
  final void Function(int direction)? onWeightStep;
  final void Function(int direction)? onRepsStep;

  @override
  State<SetRowView> createState() => _SetRowViewState();
}

class _SetRowViewState extends State<SetRowView> with SingleTickerProviderStateMixin {
  // Rests at 1 (flash overlay = reverse -> invisible); a completion plays 0 -> 1.
  late final AnimationController _flash = AnimationController(vsync: this, value: 1);
  late bool _wasDone = widget.set.done;

  @override
  void didUpdateWidget(SetRowView old) {
    super.didUpdateWidget(old);
    final done = widget.set.done;
    if (done && !_wasDone && !SxMotion.reduced(context)) {
      _flash.duration = SxMotion.short;
      _flash.forward(from: 0);
    }
    _wasDone = done;
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final set = widget.set;
    final prev = widget.prev;
    final unit = widget.unit;
    final active = widget.active;
    final num = (widget.index + 1).toString().padLeft(2, '0');
    final showSteppers = active && !set.done && widget.onWeightStep != null && widget.onRepsStep != null;
    final unitName = Fmt.unit(unit) == 'kg' ? 'kilograms' : 'pounds';
    return ClipRRect(
      borderRadius: BorderRadius.circular(SxRadius.md),
      child: Stack(children: [
        AnimatedContainer(
          duration: SxMotion.of(context, SxMotion.short),
          curve: SxMotion.enter,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(SxRadius.md),
            border: Border.all(color: active ? c.primaryBorder : c.hairline),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SizedBox(
                width: _setColW,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(num, semanticsLabel: 'Set ${widget.index + 1}', style: SxText.metricMd.copyWith(color: active ? c.primary : c.textMuted)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: _ValueCell(
                  label: 'Weight',
                  value: set.weightKg <= 0 ? '—' : Fmt.weight(set.weightKg, unit),
                  done: set.done,
                  onTap: widget.onWeight,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: _ValueCell(label: 'Reps', value: set.reps <= 0 ? '—' : '${set.reps}', done: set.done, onTap: widget.onReps),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: _doneColW,
                child: Center(
                  // The controller already fires the set-done haptic (DeviceFeedback).
                  child: SxCheck(
                    checked: set.done,
                    haptic: false,
                    semanticLabel: 'Set ${widget.index + 1} done',
                    onChanged: (_) => widget.onToggle(),
                  ),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(left: _setColW + 6, top: 2),
              child: Text(
                prev == null ? 'PREV —' : 'PREV ${Fmt.weight(prev.weightKg, unit)} × ${prev.reps}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                semanticsLabel: prev == null
                    ? 'No previous set'
                    : 'Previous ${Fmt.weight(prev.weightKg, unit)} $unitName, ${prev.reps} reps',
                style: SxText.labelXs.copyWith(color: c.textMuted),
              ),
            ),
            if (showSteppers)
              // Layout is instant (input is never delayed); only the content fades in.
              SxFadeSlideIn(
                duration: SxMotion.micro,
                dy: 4,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    Expanded(child: _StepButton(icon: Icons.remove, label: 'Decrease weight', onTap: () => widget.onWeightStep!(-1))),
                    const SizedBox(width: 4),
                    Expanded(child: _StepButton(icon: Icons.add, label: 'Increase weight', onTap: () => widget.onWeightStep!(1))),
                    const SizedBox(width: 12),
                    Expanded(child: _StepButton(icon: Icons.remove, label: 'Decrease reps', onTap: () => widget.onRepsStep!(-1))),
                    const SizedBox(width: 4),
                    Expanded(child: _StepButton(icon: Icons.add, label: 'Increase reps', onTap: () => widget.onRepsStep!(1))),
                  ]),
                ),
              ),
          ]),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 3,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: SxMotion.of(context, SxMotion.short),
            child: ColoredBox(color: c.primary),
          ),
        ),
        // Completion flash: fades out within SxMotion.short; ignores pointers.
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: ReverseAnimation(_flash),
              child: ColoredBox(color: c.primary.withValues(alpha: 0.18)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: SxPressable(
        semantics: false,
        onTap: onTap,
        scale: 0.94,
        focusRadius: SxRadius.base,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(SxRadius.base), border: Border.all(color: c.hairline)),
          child: Icon(icon, size: 20, color: c.textHigh),
        ),
      ),
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
      child: SxPressable(
        semantics: false,
        onTap: onTap,
        scale: 0.97,
        focusRadius: SxRadius.base,
        child: AnimatedContainer(
          duration: SxMotion.of(context, SxMotion.short),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: c.surface3,
            borderRadius: BorderRadius.circular(SxRadius.base),
            border: Border.all(color: done ? c.primaryBorder : c.hairline),
          ),
          // Cross-fade only when the value changes (keypad / stepper / suggestion), fixed footprint.
          child: AnimatedSwitcher(
            duration: SxMotion.of(context, SxMotion.micro),
            switchInCurve: SxMotion.enter,
            switchOutCurve: SxMotion.exit,
            child: FittedBox(
              key: ValueKey<String>(value),
              fit: BoxFit.scaleDown,
              child: Text(value, style: SxText.metricMd.copyWith(color: value == '—' ? c.textMuted : c.textHigh)),
            ),
          ),
        ),
      ),
    );
  }
}
