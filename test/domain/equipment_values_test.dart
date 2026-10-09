import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/utils/equipment_icons.dart';
import 'package:stationx/data/import/gym_tracker_import.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  test('equipment enum: original 5 keep their order, 4 appended', () {
    expect(Equipment.values.map((e) => e.name).toList(), [
      'cable',
      'dumbbell',
      'barbell',
      'machine',
      'bodyweight',
      'kettlebell',
      'band',
      'smithMachine',
      'other',
    ]);
    expect(Equipment.smithMachine.label, 'Smith machine');
  });

  test('drift: latest equipment migration lists exactly the enum names', () {
    final files =
        Directory('supabase/migrations')
            .listSync()
            .whereType<File>()
            .where(
              (f) => f.path.endsWith('.sql') && f.path.contains('equipment'),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final sql = files.last.readAsStringSync();
    final list = RegExp(
      r'check \(equipment in \(([^)]*)\)',
    ).firstMatch(sql)!.group(1)!;
    final names = RegExp(
      r"'(\w+)'",
    ).allMatches(list).map((m) => m.group(1)!).toList();
    expect(names, Equipment.values.map((e) => e.name).toList());
  });

  test('every equipment has an icon', () {
    for (final e in Equipment.values) {
      expect(equipmentIcon(e), isNotNull);
    }
  });

  test('bands and bodyweight are unloaded; kettlebell increments 2 kg', () {
    Exercise ex(String n, Equipment q) => Exercise(
      id: n,
      name: n,
      primaryMuscle: MuscleGroup.legs,
      equipment: q,
      movementPattern: 'Hinge',
    );
    expect(Equipment.band.isUnloaded, isTrue);
    expect(Equipment.bodyweight.isUnloaded, isTrue);
    expect(Equipment.kettlebell.isUnloaded, isFalse);
    expect(
      ProgressionService.isLoadTracked(ex('Band Row', Equipment.band)),
      isFalse,
    );
    expect(
      ProgressionService.isLoadTracked(ex('KB Swing', Equipment.kettlebell)),
      isTrue,
    );
    expect(
      ProgressionService.incrementFor(ex('KB Swing', Equipment.kettlebell)),
      2,
    );
    expect(
      ProgressionService.incrementFor(
        ex('Smith Squat', Equipment.smithMachine),
      ),
      2.5,
    );
  });

  test(
    'Gym Tracker import detects kettlebell/band/smith before the generic machine rule',
    () {
      Equipment eq(String n) => GymTrackerImport.equipmentForName(n);
      expect(eq('Kettlebell Swing'), Equipment.kettlebell);
      expect(eq('Smith Machine Squat'), Equipment.smithMachine);
      expect(eq('Band Pull Apart'), Equipment.band);
      expect(eq('Leg Press Machine'), Equipment.machine);
      expect(eq('Barbell Squat'), Equipment.barbell);
      expect(eq('Cable Row'), Equipment.cable);
    },
  );
}
