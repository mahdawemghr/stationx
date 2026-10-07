import 'package:flutter/material.dart';

import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../domain/domain.dart';

/// Icon used as the exercise "thumbnail" (no photo assets in the project).
IconData equipmentIcon(Equipment e) => switch (e) {
      Equipment.cable => Icons.cable,
      Equipment.dumbbell => Icons.fitness_center,
      Equipment.barbell => Icons.horizontal_rule,
      Equipment.machine => Icons.precision_manufacturing_outlined,
      Equipment.bodyweight => Icons.accessibility_new,
    };

/// "Lats • Biceps" style label.
String muscleLine(Exercise e) {
  final sec = e.secondaryMuscles.map((m) => m.label).join(', ');
  return sec.isEmpty ? e.primaryMuscle.label : '${e.primaryMuscle.label}  •  $sec';
}

/// Square thumbnail tile with equipment glyph + caps label.
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb(this.exercise, {super.key, this.size = 72});
  final Exercise exercise;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(SxRadius.md),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(equipmentIcon(exercise.equipment), color: c.primary, size: size * 0.38),
          const SizedBox(height: 4),
          Text(exercise.equipment.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SxText.labelCaps.copyWith(fontSize: 9, color: c.textBody)),
        ],
      ),
    );
  }
}

/// `Row(crossAxisAlignment: stretch)` that is safe inside scrolling parents
/// (equal-height tiles without an unbounded-height error). Pass Expanded/spacers.
class StretchRow extends StatelessWidget {
  const StretchRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
}
