import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import '../theme/sx_typography.dart';
import 'sx_motion_widgets.dart';

/// Themed circular progress indicator (the app's only spinner).
class SxSpinner extends StatelessWidget {
  const SxSpinner({
    super.key,
    this.size = 20,
    this.strokeWidth = 2,
    this.color,
    this.semanticLabel,
  });
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(
      strokeWidth: strokeWidth,
      color: color ?? context.sx.primary,
      semanticsLabel: semanticLabel,
    ),
  );
}

/// 28dp "set done" box inside a 48dp touch target. Pops (and optionally buzzes)
/// when it becomes checked.
class SxCheck extends StatelessWidget {
  const SxCheck({
    super.key,
    required this.checked,
    required this.onChanged,
    this.semanticLabel,
    this.size = 28,
    this.haptic = true,
  });
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;
  final double size;
  final bool haptic;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final enabled = onChanged != null;
    final box = SxPop(
      active: checked,
      playOnMount: false,
      haptic: haptic,
      child: AnimatedContainer(
        duration: SxMotion.of(context, SxMotion.micro),
        curve: SxMotion.enter,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checked ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(SxRadius.base),
          border: Border.all(
            color: checked ? c.primary : c.textMuted,
            width: 2,
          ),
        ),
        child: checked
            ? Icon(Icons.check, size: size * 0.68, color: c.onAccent)
            : null,
      ),
    );
    return Semantics(
      container: true,
      checked: checked,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: enabled ? () => onChanged!(!checked) : null,
      child: SxPressable(
        semantics: false,
        enabled: enabled,
        scale: 0.9,
        focusRadius: SxRadius.base,
        onTap: enabled ? () => onChanged!(!checked) : null,
        child: SizedBox(width: 48, height: 48, child: Center(child: box)),
      ),
    );
  }
}

/// Small mono-caps pill (status / category). Uses the 10sp label token.
class SxTag extends StatelessWidget {
  const SxTag(
    this.label, {
    super.key,
    this.color,
    this.filled = false,
    this.icon,
    this.dot = false,
  });
  final String label;
  final Color? color;
  final bool filled;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final col = color ?? c.primary;
    final fg = filled ? c.onAccent : col;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? col : col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SxRadius.full),
        border: Border.all(color: filled ? col : col.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SxText.labelXs.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef SxPill = SxTag;

/// - / value / + control with 48dp targets and optional long-press repeat.
/// Use [SxStepper.int] or [SxStepper.double]; tap the value via [onTapValue]
/// (e.g. to open the numeric keypad).
class SxStepper extends StatelessWidget {
  SxStepper.int({
    super.key,
    required int value,
    required ValueChanged<int> onChanged,
    int min = 0,
    int max = 9999,
    int step = 1,
    this.label,
    this.unit,
    this.onTapValue,
    this.longPressRepeat = true,
    this.formatter,
  }) : _value = value.toDouble(),
       _min = min.toDouble(),
       _max = max.toDouble(),
       _step = step.toDouble(),
       _decimals = 0,
       _onChanged = ((d) => onChanged(d.round()));

  // ignore: prefer_const_constructors_in_immutables
  SxStepper.double({
    super.key,
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0,
    double max = 9999,
    double step = 0.5,
    int decimals = 1,
    this.label,
    this.unit,
    this.onTapValue,
    this.longPressRepeat = true,
    this.formatter,
  }) : _value = value,
       _min = min,
       _max = max,
       _step = step,
       _decimals = decimals,
       _onChanged = onChanged;

  final double _value, _min, _max, _step;
  final int _decimals;
  final ValueChanged<double> _onChanged;

  /// Spoken name, e.g. "Weight" -> "Increase Weight".
  final String? label;
  final String? unit;
  final VoidCallback? onTapValue;
  final bool longPressRepeat;
  final String Function(double)? formatter;

  double _round(double v) {
    var p = 1.0;
    for (var i = 0; i < _decimals; i++) {
      p *= 10;
    }
    return (v * p).round() / p;
  }

  String _fmt(double v) {
    if (formatter != null) return formatter!(v);
    if (_decimals == 0) return v.round().toString();
    final s = v.toStringAsFixed(_decimals);
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }

  void _bump(double dir) =>
      _onChanged(_round((_value + dir * _step).clamp(_min, _max)));

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final name = label == null ? '' : ' $label';
    final shown = _fmt(_value);
    final valueText = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: shown,
            style: SxText.metricMd.copyWith(color: c.textHigh),
          ),
          if (unit != null)
            TextSpan(
              text: ' $unit',
              style: SxText.bodySm.copyWith(color: c.textBody),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
    Widget value = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Center(child: valueText),
    );
    value = onTapValue == null
        ? Semantics(
            label: label,
            value: '$shown${unit == null ? '' : ' $unit'}',
            excludeSemantics: true,
            child: value,
          )
        : SxPressable(
            onTap: onTapValue,
            scale: 0.985,
            semanticLabel:
                '${label ?? 'Value'} $shown${unit == null ? '' : ' $unit'}, tap to edit',
            excludeChildSemantics: true,
            child: value,
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          label: 'Decrease$name',
          enabled: _value > _min,
          repeat: longPressRepeat,
          onStep: () => _bump(-1),
        ),
        Flexible(child: value),
        _StepButton(
          icon: Icons.add,
          label: 'Increase$name',
          enabled: _value < _max,
          repeat: longPressRepeat,
          onStep: () => _bump(1),
        ),
      ],
    );
  }
}

class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.repeat,
    required this.onStep,
  });
  final IconData icon;
  final String label;
  final bool enabled;
  final bool repeat;
  final VoidCallback onStep;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  Timer? _hold;
  bool _repeated = false;

  void _stop() {
    _hold?.cancel();
    _hold = null;
  }

  void _startHold() {
    _repeated = false;
    if (!widget.repeat || !widget.enabled) return;
    _stop();
    _hold = Timer(const Duration(milliseconds: 400), () {
      _hold = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted || !widget.enabled) return _stop();
        _repeated = true;
        widget.onStep();
      });
      _repeated = true;
      widget.onStep();
    });
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Listener(
      onPointerDown: (_) => _startHold(),
      onPointerUp: (_) => _stop(),
      onPointerCancel: (_) => _stop(),
      child: SxPressable(
        enabled: widget.enabled,
        semanticLabel: widget.label,
        excludeChildSemantics: true,
        haptic: true,
        onTap: () {
          if (_repeated) {
            _repeated = false;
            return;
          }
          widget.onStep();
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(SxRadius.base),
                border: Border.all(color: c.hairline),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: widget.enabled ? c.textHigh : c.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
