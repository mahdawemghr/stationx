import 'package:flutter/material.dart';

import '../../domain/domain.dart';

IconData equipmentIcon(Equipment e) => switch (e) {
  Equipment.cable => Icons.cable,
  Equipment.dumbbell => Icons.fitness_center,
  Equipment.barbell => Icons.horizontal_rule,
  Equipment.machine => Icons.precision_manufacturing_outlined,
  Equipment.bodyweight => Icons.accessibility_new,
};
