import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/domain/domain.dart';

final now = DateTime(2026, 10, 9, 12);

CardioSession cardio({
  String id = 'c1',
  CardioKind kind = CardioKind.outdoorRun,
  int secs = 1800,
  double? km,
  int? cal,
  int? hr,
  DateTime? at,
}) => CardioSession(
  id: id,
  kind: kind,
  workoutDate: at ?? DateTime(2026, 10, 9, 8),
  durationSeconds: secs,
  distanceKm: km,
  calories: cal,
  avgHeartRate: hr,
);

HealthWorkout hw(
  String id, {
  String type = 'RUNNING',
  String src = 'com.sec.android.app.shealth',
  Duration ago = const Duration(days: 2),
  Duration len = const Duration(minutes: 30),
  double? m = 5000,
  double? kcal = 300,
}) {
  final start = now.subtract(ago);
  return HealthWorkout(
    id: id,
    activityName: type,
    start: start,
    end: start.add(len),
    sourceName: src,
    distanceMeters: m,
    energyKcal: kcal,
  );
}

HealthImportPlan plan(List<HealthWorkout> w, {Set<String> imported = const {}, Set<String> own = const {}, Set<String> existing = const {}, int? days}) =>
    HealthImport.plan(w, ownSourceIds: {'dev.mahdi_ramadhan.stationx'}, ownRecordIds: own, alreadyImported: imported, existingSessionIds: existing, now: now, days: days);

void main() {
  group('WorkoutMapping', () {
    test('every CardioKind maps (custom -> other)', () {
      for (final k in CardioKind.values) {
        final a = WorkoutMapping.activityForCardio(k);
        if (k == CardioKind.custom) expect(a, HealthActivity.other);
      }
      expect(WorkoutMapping.activityForCardio(CardioKind.outdoorRun), HealthActivity.running);
      expect(WorkoutMapping.activityForCardio(CardioKind.treadmill), HealthActivity.runningTreadmill);
      expect(WorkoutMapping.activityForCardio(CardioKind.stationaryBike), HealthActivity.bikingStationary);
      expect(WorkoutMapping.activityForCardio(CardioKind.rowing), HealthActivity.rowingMachine);
      expect(WorkoutMapping.activityForCardio(CardioKind.swimming), HealthActivity.swimming);
      expect(WorkoutMapping.activityForCardio(CardioKind.jumpRope), HealthActivity.jumpRope);
      expect(WorkoutMapping.activityForCardio(CardioKind.hiit), HealthActivity.hiit);
    });
    test('unknown platform names are other; strength names are strength', () {
      expect(WorkoutMapping.activityFromName('TOTALLY_NEW'), HealthActivity.other);
      expect(WorkoutMapping.activityFromName('strength_training'), HealthActivity.strength);
      expect(WorkoutMapping.cardioKindFor(HealthActivity.strength), isNull);
      expect(WorkoutMapping.cardioKindFor(HealthActivity.other), isNull);
    });
    test('request: units converted, only logged numbers, no heart rate', () {
      final r = WorkoutMapping.forCardio(cardio(km: 5.25, cal: 320, hr: 150), now: now)!;
      expect(r.distanceMeters, 5250);
      expect(r.energyKcal, 320);
      expect(r.end.difference(r.start), const Duration(minutes: 30));
      expect(r.key, 'c:c1');
      final bare = WorkoutMapping.forCardio(cardio(), now: now)!;
      expect(bare.distanceMeters, isNull);
      expect(bare.energyKcal, isNull);
    });
    test('refuses what cannot be written honestly', () {
      expect(WorkoutMapping.forCardio(cardio(secs: 0), now: now), isNull);
      expect(WorkoutMapping.forCardio(cardio(secs: 90000), now: now), isNull);
      expect(WorkoutMapping.forCardio(cardio(at: now.add(const Duration(days: 1))), now: now), isNull);
      expect(WorkoutMapping.forCardio(cardio(km: 5000, secs: 60), now: now)!.distanceMeters, isNull);
      expect(WorkoutMapping.forCardio(cardio(km: -1), now: now)!.distanceMeters, isNull);
    });
    test('strength: duration required, finisher not separate', () {
      final s = WorkoutSession(id: 'w1', workoutId: 'x', name: 'Push', workoutDate: DateTime(2026, 10, 9, 7), exercises: const [], durationSeconds: 3000);
      final r = WorkoutMapping.forStrength(s, now: now)!;
      expect(r.activity, HealthActivity.strength);
      expect(r.key, 's:w1');
      expect(r.distanceMeters, isNull);
      expect(WorkoutMapping.forStrength(WorkoutSession(id: 'w2', workoutId: 'x', name: '', workoutDate: DateTime(2026, 10, 9), exercises: const []), now: now), isNull);
    });
  });

  group('HealthEnrichmentService', () {
    test('fills only empty fields, ignores outliers', () {
      final e = HealthEnrichmentService.suggest(cardio(), const HealthMetrics(heartRates: [140, 150, 999, 10], activeKcal: 250.4));
      expect(e.avgHeartRate, 145);
      expect(e.calories, 250);
    });
    test('never suggests over typed values', () {
      final e = HealthEnrichmentService.suggest(cardio(hr: 120, cal: 100), const HealthMetrics(heartRates: [150], activeKcal: 300));
      expect(e.isEmpty, isTrue);
      final applied = HealthEnrichmentService.apply(cardio(hr: 120), const HealthEnrichment(avgHeartRate: 150, calories: 200));
      expect(applied.avgHeartRate, 120);
      expect(applied.calories, 200);
    });
    test('falls back to total kcal; nothing when no data', () {
      expect(HealthEnrichmentService.suggest(cardio(), const HealthMetrics(totalKcal: 400)).calories, 400);
      expect(HealthEnrichmentService.suggest(cardio(), const HealthMetrics()).isEmpty, isTrue);
      expect(HealthEnrichmentService.suggest(cardio(), const HealthMetrics(activeKcal: 9e9)).calories, isNull);
    });
  });

  group('HealthImport', () {
    test('imports mapped sessions with source note, original start, createdAt now', () {
      final p = plan([hw('a'), hw('b', type: 'BIKING_STATIONARY', ago: const Duration(days: 3))]);
      expect(p.sessions.length, 2);
      expect(p.sessions.first.kind, CardioKind.stationaryBike); // oldest first
      final s = p.sessions.last;
      expect(s.id, startsWith('hc_'));
      expect(s.kind, CardioKind.outdoorRun);
      expect(s.workoutDate, now.subtract(const Duration(days: 2)));
      expect(s.meta.createdAt, now);
      expect(s.distanceKm, 5.0);
      expect(s.calories, 300);
      expect(s.notes, 'Imported from Health Connect (Samsung Health)');
      expect(p.sourceLabels, {'Samsung Health'});
    });
    test('excludes own records and own origin', () {
      final p = plan([hw('own1'), hw('x', src: 'dev.mahdi_ramadhan.stationx'), hw('ok')], own: {'own1'});
      expect(p.sessions.length, 1);
      expect(p.skippedOwn, 2);
    });
    test('idempotent: imported ids and existing session ids are skipped; apply twice adds once', () async {
      final repo = MemoryCardioRepository([], []);
      final p1 = plan([hw('a')]);
      expect(await HealthImport.apply(p1, repo), 1);
      expect(await HealthImport.apply(p1, repo), 0);
      final p2 = plan([hw('a')], existing: {for (final s in repo.sessions) s.id});
      expect(p2.sessions, isEmpty);
      expect(p2.skippedAlreadyImported, 1);
      expect(plan([hw('a')], imported: {'a'}).skippedAlreadyImported, 1);
      expect(HealthImport.sessionIdFor('a'), HealthImport.sessionIdFor('a'));
      expect(HealthImport.sessionIdFor('a'), isNot(HealthImport.sessionIdFor('b')));
    });
    test('only completed, sane, in-window sessions; unsupported counted', () {
      final p = plan([
        hw('future', ago: const Duration(minutes: -10)), // ends in the future
        hw('short', len: const Duration(seconds: 20)),
        hw('long', len: const Duration(hours: 30)),
        hw('old', ago: const Duration(days: 45)),
        hw('yoga', type: 'YOGA'),
        hw('dup'),
        hw('dup'),
      ]);
      expect(p.sessions.length, 1);
      expect(p.skippedUnsupported, 1);
      expect(p.skippedInvalid, 5); // future, short, long, old, repeated id
    });
    test('hostile numbers are dropped, not imported', () {
      final p = plan([
        hw('speed', m: 900000), // absurd speed
        hw('nan', m: double.nan, kcal: double.infinity),
        hw('neg', m: -5, kcal: -1),
        hw('huge', kcal: 1e12),
      ]);
      expect(p.sessions.length, 4);
      for (final s in p.sessions) {
        expect(s.distanceKm == null || (s.distanceKm! > 0 && s.distanceKm! < 1000), isTrue);
      }
      expect(p.sessions.every((s) => s.calories == null || s.calories! <= 20000), isTrue);
      expect(p.sessions.where((s) => s.distanceKm != null).length, 0 + 0 + 0 + 1);
    });
    test('hostile source name never reaches notes; days clamp', () {
      final p = plan([hw('a', src: '<script>alert(1)</script>')]);
      expect(p.sessions.single.notes, 'Imported from Health Connect');
      expect(HealthImport.clampDays(500), 90);
      expect(HealthImport.clampDays(null), 30);
      expect(HealthImport.clampDays(-3), 1);
      expect(plan([hw('a', ago: const Duration(days: 45))], days: 90).sessions.length, 1);
    });
  });
}
