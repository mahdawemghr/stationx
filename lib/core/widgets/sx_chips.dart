import 'package:flutter/material.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import '../theme/sx_typography.dart';
import 'sx_motion_widgets.dart';

/// Filter/option chip (pill).
class SxChip extends StatelessWidget {
  const SxChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final fg = selected ? c.onAccent : c.textBody;
    // 36dp visual pill inside a 48dp touch target.
    return SxPressable(
      selected: selected,
      semanticLabel: label,
      excludeChildSemantics: true,
      onTap: onTap,
      enabled: onTap != null,
      scale: 0.97,
      focusRadius: SxRadius.full,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(
          widthFactor: 1,
          child: Material(
            color: selected ? c.primary : c.surface2,
            animationDuration: SxMotion.of(context, SxMotion.micro),
            shape: StadiumBorder(
              side: BorderSide(color: selected ? c.primary : c.hairline),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: SxText.labelUi.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling single-select chip row.
class SxChipRow extends StatelessWidget {
  const SxChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: SxSpace.screenMargin),
  });
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => SxChip(
          label: labels[i],
          selected: i == selectedIndex,
          onTap: () => onSelected(i),
        ),
      ),
    );
  }
}

/// Segmented control (tabs on surface-2 with lime selected pill).
class SxSegmented extends StatelessWidget {
  const SxSegmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.icons,
    this.dense = false,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final List<IconData>? icons;

  /// Tighter label padding for 4+ segments on narrow screens.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    // Outer 48dp row = touch target; the 40dp pill slides inside it with a 4dp gap.
    final n = labels.length;
    final alignX = n <= 1 ? 0.0 : -1 + 2 * index.clamp(0, n - 1) / (n - 1);
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(SxRadius.md),
        border: Border.all(color: c.hairline),
      ),
      child: Stack(
        children: [
          if (n > 0)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedAlign(
                  duration: SxMotion.of(context, SxMotion.short),
                  curve: SxMotion.enter,
                  alignment: Alignment(alignX, 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / n,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(SxRadius.base),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Semantics(
                    container: true,
                    button: true,
                    selected: i == index,
                    label: labels[i],
                    excludeSemantics: true,
                    onTap: () => onChanged(i),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 40),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: dense ? 2 : 8,
                              ),
                              child: TweenAnimationBuilder<Color?>(
                                tween: ColorTween(
                                  end: i == index ? c.onAccent : c.textBody,
                                ),
                                duration: SxMotion.of(context, SxMotion.short),
                                builder: (_, col, _) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (icons != null) ...[
                                      Icon(icons![i], size: 16, color: col),
                                      const SizedBox(width: 6),
                                    ],
                                    Flexible(
                                      child: Text(
                                        labels[i].toUpperCase(),
                                        overflow: TextOverflow.ellipsis,
                                        style: SxText.labelCaps.copyWith(
                                          color: col,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
