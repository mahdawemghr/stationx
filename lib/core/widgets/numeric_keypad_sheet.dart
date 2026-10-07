import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import '../theme/sx_typography.dart';
import 'sx_button.dart';
import 'sx_sheet.dart';

/// Custom numeric keypad sheet (avoids native keyboard layout bounce).
/// Returns the entered value, or null when dismissed.
Future<double?> showNumericKeypad(
  BuildContext context, {
  required String title,
  double? initial,
  bool allowDecimal = true,
  double step = 1,
  String? unit,
  double? min = 0,
  double? max,
}) {
  return showSxSheet<double>(
    context,
    builder: (_) => _KeypadBody(
      title: title,
      initial: initial,
      allowDecimal: allowDecimal,
      step: step,
      unit: unit,
      min: min,
      max: max,
    ),
  );
}

class _KeypadBody extends StatefulWidget {
  const _KeypadBody({
    required this.title,
    this.initial,
    required this.allowDecimal,
    required this.step,
    this.unit,
    this.min,
    this.max,
  });
  final String title;
  final double? initial;
  final bool allowDecimal;
  final double step;
  final String? unit;
  final double? min;
  final double? max;

  @override
  State<_KeypadBody> createState() => _KeypadBodyState();
}

class _KeypadBodyState extends State<_KeypadBody> {
  late String _text;
  bool _fresh = true; // first key replaces the prefilled value

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _text = i == null || i == 0
        ? ''
        : (i == i.roundToDouble() ? i.toStringAsFixed(0) : i.toString());
  }

  double get _value => double.tryParse(_text) ?? 0;

  void _key(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_fresh) {
        _text = '';
        _fresh = false;
      }
      if (k == '.') {
        if (!widget.allowDecimal || _text.contains('.')) return;
        _text = _text.isEmpty ? '0.' : '$_text.';
      } else {
        if (_text.length >= 7) return;
        _text = _text == '0' ? k : '$_text$k';
      }
    });
  }

  void _back() => setState(() {
    _fresh = false;
    if (_text.isNotEmpty) _text = _text.substring(0, _text.length - 1);
  });

  void _step(double d) => setState(() {
    _fresh = false;
    var v = _value + d;
    if (widget.min != null && v < widget.min!) v = widget.min!;
    if (widget.max != null && v > widget.max!) v = widget.max!;
    _text = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Padding(
      padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title.toUpperCase(),
            style: SxText.labelCaps.copyWith(color: c.textBody),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _StepBtn(
                icon: Icons.remove,
                label: 'Decrease',
                onTap: () => _step(-widget.step),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: FittedBox(
                  child: Text(
                    _text.isEmpty ? '0' : _text,
                    style: SxText.metricXl.copyWith(
                      color: _text.isEmpty ? c.textMuted : c.textHigh,
                    ),
                  ),
                ),
              ),
              if (widget.unit != null) ...[
                const SizedBox(width: 6),
                Text(
                  widget.unit!,
                  style: SxText.bodyLg.copyWith(color: c.textBody),
                ),
              ],
              const SizedBox(width: 12),
              _StepBtn(
                icon: Icons.add,
                label: 'Increase',
                onTap: () => _step(widget.step),
              ),
            ],
          ),
          const SizedBox(height: SxSpace.md),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            _row(row.map((k) => _Key(label: k, onTap: () => _key(k))).toList()),
          _row([
            _Key(
              label: widget.allowDecimal ? '.' : '',
              onTap: widget.allowDecimal ? () => _key('.') : null,
            ),
            _Key(label: '0', onTap: () => _key('0')),
            _Key(
              icon: Icons.backspace_outlined,
              semanticLabel: 'Delete',
              onTap: _back,
              onLongPress: () => setState(() => _text = ''),
            ),
          ]),
          const SizedBox(height: SxSpace.sm),
          SxButton(
            label: 'Confirm',
            icon: Icons.check,
            onPressed: () => Navigator.pop(context, _value),
          ),
        ],
      ),
    );
  }

  Widget _row(List<Widget> kids) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        for (final k in kids)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: k,
            ),
          ),
      ],
    ),
  );
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.onTap,
    required this.label,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    onPressed: onTap,
    tooltip: label,
    icon: Icon(icon),
    style: IconButton.styleFrom(
      backgroundColor: context.sx.surface2,
      foregroundColor: context.sx.textHigh,
      minimumSize: const Size(48, 48),
    ),
  );
}

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.icon,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
  });
  final String? semanticLabel;
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Material(
        color: onTap == null ? Colors.transparent : c.surface2,
        borderRadius: BorderRadius.circular(SxRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(SxRadius.md),
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            height: 52,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: c.textHigh)
                  : Text(
                      label ?? '',
                      style: SxText.metricMd.copyWith(color: c.textHigh),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
