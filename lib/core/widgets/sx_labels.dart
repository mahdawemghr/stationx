import 'package:flutter/material.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import '../theme/sx_typography.dart';

/// Mono caps section label with optional icon + trailing action/text.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.icon,
    this.trailingText,
    this.onTrailingTap,
    this.trailing,
  });
  final String title;
  final IconData? icon;
  final String? trailingText;
  final VoidCallback? onTrailingTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: c.textBody),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: SxText.labelCaps.copyWith(
                  color: c.textBody,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          ?trailing,
          if (trailingText != null)
            InkWell(
              onTap: onTrailingTap,
              borderRadius: BorderRadius.circular(SxRadius.base),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: onTrailingTap == null ? 8 : 14,
                  horizontal: 4,
                ),
                child: Text(
                  trailingText!,
                  style: SxText.bodySm.copyWith(
                    color: onTrailingTap == null ? c.textBody : c.primary,
                    fontWeight: onTrailingTap == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Stat tile: caps label + icon on top, big mono value + unit below.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.accent = false,
    this.height = 96,
    this.caption,
  });
  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final bool accent;
  final double? height;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final valueColor = accent ? c.primary : c.textHigh;
    return Semantics(
      container: true,
      label:
          '$label: $value${unit == null ? '' : ' $unit'}${caption == null ? '' : '. $caption'}',
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minHeight: height ?? 0),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: SxText.labelCaps.copyWith(color: c.textBody),
                  ),
                ),
                if (icon != null)
                  Icon(icon, size: 18, color: accent ? c.primary : c.textBody),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: SxText.metricLg.copyWith(color: valueColor),
                    ),
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit!,
                    style: SxText.bodySm.copyWith(
                      color: accent ? c.primary : c.textBody,
                    ),
                  ),
                ],
              ],
            ),
            if (caption != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  caption!,
                  style: SxText.bodySm.copyWith(color: c.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small pill: optional dot + mono caps text.
class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    super.key,
    this.color,
    this.dot = false,
    this.filled = false,
    this.icon,
  });
  final String label;
  final Color? color;
  final bool dot;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final col = color ?? c.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              decoration: BoxDecoration(
                color: filled ? c.onAccent : col,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? c.onAccent : col),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: SxText.labelXs.copyWith(
                color: filled ? c.onAccent : col,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// PR / milestone chip: black fill, lime outline, diamond icon.
class PrBadge extends StatelessWidget {
  const PrBadge([this.label = 'PR', Key? key]) : super(key: key);
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(SxRadius.full),
        border: Border.all(color: c.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond_outlined, size: 11, color: c.primary),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: SxText.labelXs.copyWith(
              color: c.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// "+11%" / "+5 kg" delta badge.
class DeltaBadge extends StatelessWidget {
  const DeltaBadge(this.text, {super.key, this.positive = true});
  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final col = positive ? c.primary : c.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SxRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 11,
            color: col,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: SxText.labelCaps.copyWith(
              color: col,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mono "label : value" metric used inside cards.
class MetricValue extends StatelessWidget {
  const MetricValue(this.value, {super.key, this.unit, this.style, this.color});
  final String value;
  final String? unit;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final s = (style ?? SxText.metricMd).copyWith(color: color ?? c.textHigh);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(value, style: s, overflow: TextOverflow.ellipsis),
        ),
        if (unit != null) ...[
          const SizedBox(width: 4),
          Text(unit!, style: SxText.bodySm.copyWith(color: c.textBody)),
        ],
      ],
    );
  }
}
