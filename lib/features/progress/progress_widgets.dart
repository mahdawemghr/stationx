import 'package:flutter/material.dart';

import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';

/// Stat tile whose headline number counts up on first build (and on change).
/// Same layout as [StatTile]; [value] is formatted by [format] on every frame.
class CountStatTile extends StatelessWidget {
  const CountStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.format,
    this.unit,
    this.icon,
    this.accent = false,
    this.height = 112,
    this.caption,
    this.delay = Duration.zero,
  });
  final String label;
  final double value;
  final String Function(double) format;
  final String? unit;
  final IconData? icon;
  final bool accent;
  final double height;
  final String? caption;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final valueColor = accent ? c.primary : c.textHigh;
    return Semantics(
      container: true,
      label: '$label: ${format(value)}${unit == null ? '' : ' $unit'}${caption == null ? '' : '. $caption'}',
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface1,
          borderRadius: BorderRadius.circular(SxRadius.lg),
          border: Border.all(color: c.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Expanded(
                child: Text(label.toUpperCase(), overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody)),
              ),
              if (icon != null) Icon(icon, size: 18, color: accent ? c.primary : c.textBody),
            ]),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SxCountUp(value: value, formatter: format, delay: delay, style: SxText.metricLg.copyWith(color: valueColor)),
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(unit!, style: SxText.bodySm.copyWith(color: accent ? c.primary : c.textBody)),
                ],
              ],
            ),
            if (caption != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(caption!, style: SxText.bodySm.copyWith(color: c.textMuted)),
              ),
          ],
        ),
      ),
    );
  }
}
