import 'package:flutter/material.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import '../theme/sx_typography.dart';

/// Filter/option chip (pill).
class SxChip extends StatelessWidget {
  const SxChip({super.key, required this.label, this.selected = false, this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final fg = selected ? const Color(0xFF101214) : c.textBody;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? c.primary : c.surface2,
        shape: StadiumBorder(side: BorderSide(color: selected ? c.primary : c.hairline)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
                Text(label, style: SxText.labelUi.copyWith(color: fg, fontWeight: FontWeight.w600)),
              ]),
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
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => SxChip(label: labels[i], selected: i == selectedIndex, onTap: () => onSelected(i)),
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
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final List<IconData>? icons;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(SxRadius.md),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                label: labels[i],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: SxMotion.base,
                    curve: Curves.easeOut,
                    constraints: const BoxConstraints(minHeight: 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: i == index ? c.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(SxRadius.base),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (icons != null) ...[
                        Icon(icons![i], size: 16, color: i == index ? const Color(0xFF101214) : c.textBody),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(labels[i].toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: SxText.labelCaps.copyWith(
                                color: i == index ? const Color(0xFF101214) : c.textBody,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
