import 'package:flutter/material.dart';

import '../../domain/domain.dart';

IconData equipmentIcon(Equipment e) => switch (e) {
  Equipment.cable => Icons.cable,
  Equipment.dumbbell => Icons.fitness_center,
  Equipment.barbell => Icons.horizontal_rule,
  Equipment.machine => Icons.precision_manufacturing_outlined,
  Equipment.bodyweight => Icons.accessibility_new,
  Equipment.kettlebell => Icons.sports_gymnastics,
  Equipment.band => Icons.all_inclusive,
  Equipment.smithMachine => Icons.view_column_outlined,
  Equipment.other => Icons.category_outlined,
};
