import 'package:flutter/material.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import '../theme/sx_typography.dart';

class SxNavItem {
  const SxNavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

const sxTabs = [
  SxNavItem('Today', Icons.local_fire_department_outlined),
  SxNavItem('Workouts', Icons.fitness_center),
  SxNavItem('Progress', Icons.trending_up),
  SxNavItem('Profile', Icons.person_outline),
];

/// Bottom navigation: surface-1, hairline top border, mono caps labels,
/// lime active state.
class SxBottomNav extends StatelessWidget {
  const SxBottomNav({super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: SafeArea(
        top: false,
        // Fixed-height bar: labels are capped at 1.3× (as Material's NavigationBar does).
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: SizedBox(
            height: 64,
            child: Stack(
              children: [
                // Single sliding indicator (top edge) shared by all tabs.
                Positioned.fill(
                  child: AnimatedAlign(
                    duration: SxMotion.of(context, SxMotion.short),
                    curve: SxMotion.enter,
                    alignment: Alignment(
                      sxTabs.length <= 1
                          ? 0
                          : -1 +
                                2 *
                                    index.clamp(0, sxTabs.length - 1) /
                                    (sxTabs.length - 1),
                      -1,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 1 / sxTabs.length,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 32,
                          height: 3,
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(SxRadius.sm),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < sxTabs.length; i++)
                      Expanded(
                        child: Semantics(
                          container: true,
                          button: true,
                          selected: i == index,
                          label: sxTabs[i].label,
                          excludeSemantics: true,
                          onTap: () => onChanged(i),
                          child: InkWell(
                            onTap: () => onChanged(i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: i == index ? 1.08 : 1,
                                  duration: SxMotion.of(
                                    context,
                                    SxMotion.micro,
                                  ),
                                  curve: SxMotion.enter,
                                  child: Icon(
                                    sxTabs[i].icon,
                                    size: 24,
                                    color: i == index ? c.primary : c.textBody,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sxTabs[i].label.toUpperCase(),
                                  style: SxText.labelXs.copyWith(
                                    color: i == index ? c.primary : c.textBody,
                                    fontWeight: i == index
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
