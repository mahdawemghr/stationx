import 'package:flutter/material.dart';

import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

/// "LEGS  ·  3 exercises · 9 sets" header for one [WorkoutSection]. Grouping itself comes from the
/// domain ([WorkoutSections.group]); this widget only renders it. With [onToggle] the header becomes a
/// collapse toggle (chevron + button semantics).
class WorkoutSectionHeader extends StatelessWidget {
  const WorkoutSectionHeader({super.key, required this.section, this.collapsed = false, this.onToggle});
  final WorkoutSection section;
  final bool collapsed;
  final VoidCallback? onToggle;

  static String summary(WorkoutSection s) {
    final n = s.items.length;
    return '$n ${n == 1 ? 'exercise' : 'exercises'} · ${s.sets} ${s.sets == 1 ? 'set' : 'sets'}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final label = '${section.label}, ${summary(section)}';
    final content = Padding(
      padding: const EdgeInsets.only(top: SxSpace.xs, bottom: SxSpace.xs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Row(
          children: [
            Container(width: 3, height: 14, decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(SxRadius.full))),
            const SizedBox(width: 8),
            Flexible(
              child: Text(section.label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.primary)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(summary(section), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
            ),
            if (onToggle != null)
              AnimatedRotation(
                turns: collapsed ? -0.25 : 0,
                duration: SxMotion.of(context, SxMotion.short),
                child: Icon(Icons.expand_more, size: 20, color: c.textBody),
              ),
          ],
        ),
      ),
    );
    if (onToggle == null) {
      return Semantics(header: true, label: label, excludeSemantics: true, child: content);
    }
    return Semantics(
      header: true,
      child: SxPressable(
        onTap: onToggle,
        semanticLabel: '$label, ${collapsed ? 'collapsed' : 'expanded'}',
        excludeChildSemantics: true,
        scale: 0.99,
        child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 48), child: Align(alignment: Alignment.centerLeft, child: content)),
      ),
    );
  }
}
