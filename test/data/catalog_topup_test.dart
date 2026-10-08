import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/data/isar/entities.dart';
import 'package:stationx/data/isar/isar_store.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  late Directory dir;
  setUpAll(() async => Isar.initializeIsarCore(download: true));
  setUp(() => dir = Directory.systemTemp.createTempSync('stationx_topup_test'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test(
    'restart adds missing seed exercises without touching existing or custom ones',
    () async {
      var s = await IsarStore.open(directory: dir.path, name: 'topup');
      final total = seedExercises().length;
      expect(s.exercises.all.length, total);

      // Simulate an older install: drop some newer seed rows, edit one existing row, add a custom one.
      await s.exercises.addCustom(
        Exercise(
          id: 'my_ex',
          name: 'Mine',
          primaryMuscle: MuscleGroup.back,
          equipment: Equipment.cable,
          isCustom: true,
        ),
      );
      await s.db.writeTxn(() async {
        await s.db.exerciseEntitys.deleteByUid('hip_thrust');
        await s.db.exerciseEntitys.deleteByUid('back_extension');
        final bench = (await s.db.exerciseEntitys.getByUid('bench_press'))!
          ..name = 'Edited bench';
        await s.db.exerciseEntitys.putByUid(bench);
      });
      await s.close();

      s = await IsarStore.open(directory: dir.path, name: 'topup');
      expect(s.exercises.byId('hip_thrust'), isNotNull);
      expect(s.exercises.byId('back_extension'), isNotNull);
      expect(s.exercises.byId('bench_press')!.name, 'Edited bench');
      expect(s.exercises.byId('my_ex')!.isCustom, isTrue);
      expect(s.exercises.all.length, total + 1);

      final row = (await s.db.exerciseEntitys.getByUid('hip_thrust'))!;
      expect(row.isCustom, isFalse);
      expect(row.meta.syncStatus, SyncStatus.synced);

      // A third open adds nothing.
      expect(await IsarStore.topUpCatalog(s.db), 0);
      await s.close();
    },
  );
}
