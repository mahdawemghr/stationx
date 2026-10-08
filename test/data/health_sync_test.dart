import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/health/health_gateway.dart';
import 'package:stationx/data/health/health_sync_service.dart';
import 'package:stationx/data/health/health_sync_store.dart';
import 'package:stationx/data/memory/memory_repositories.dart';
import 'package:stationx/domain/domain.dart';

class FakeHc extends HealthGateway {
  int calls = 0;
  bool grant = true;
  bool failWrites = false;
  final Map<String, HealthWriteRequest> records = {}; // workoutId -> request
  final List<HealthWorkout> external = [];
  HealthMetrics? metrics;
  int _n = 0;
  final granted = <HealthFeature>{};

  @override
  HealthProvider get provider => HealthProvider.healthConnect;
  @override
  bool get canQueryPermissions => true;
  @override
  Set<String> get ownSourceIds => const {'dev.mahdi_ramadhan.stationx'};
  @override
  Future<GatewayAvailability> availability() async => GatewayAvailability.available;
  @override
  Future<bool> hasPermissions() async => true;
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<List<TimeSpan>> sleepAsleep(DateTime a, DateTime b) async => const [];
  @override
  Future<List<TimeSpan>> sleepSessions(DateTime a, DateTime b) async => const [];
  @override
  Future<List<BpmPoint>> restingHeartRate(DateTime a, DateTime b) async => const [];
  @override
  Future<void> revoke() async => granted.clear();
  @override
  Future<void> installProvider() async {}

  @override
  Future<bool> hasFeaturePermissions(HealthFeature f) async {
    calls++;
    return granted.contains(f);
  }

  @override
  Future<bool> requestFeaturePermissions(HealthFeature f) async {
    calls++;
    if (grant) granted.add(f);
    return grant;
  }

  @override
  Future<HealthWriteReceipt?> writeWorkout(HealthWriteRequest r) async {
    calls++;
    if (failWrites) return null;
    final id = 'hc${_n++}';
    records[id] = r;
    return HealthWriteReceipt(workoutId: id);
  }

  @override
  Future<bool> deleteWorkout(HealthWriteReceipt r) async {
    calls++;
    if (failWrites) return false;
    records.remove(r.workoutId);
    return true;
  }

  @override
  Future<List<HealthWorkout>> readWorkouts(DateTime a, DateTime b) async {
    calls++;
    return external;
  }

  @override
  Future<HealthMetrics?> readMetrics(DateTime a, DateTime b) async {
    calls++;
    return metrics;
  }
}

final base = DateTime.now();
CardioSession run(String id, {int secs = 1800, double? km, int? cal, DateTime? at}) => CardioSession(
  id: id,
  kind: CardioKind.outdoorRun,
  workoutDate: at ?? base.subtract(const Duration(hours: 1)),
  durationSeconds: secs,
  distanceKm: km,
  calories: cal,
);

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late FakeHc hc;
  late MemoryHealthSyncStore store;
  late HealthSyncService svc;
  setUp(() {
    hc = FakeHc();
    store = MemoryHealthSyncStore();
    svc = HealthSyncService(hc, store);
  });

  test('everything defaults OFF and makes no health-store call', () async {
    for (final f in HealthFeature.values) {
      expect(svc.isEnabled(f), isFalse);
    }
    svc.onCardioSaved(run('c1'));
    svc.onCardioDeleted('c1');
    await svc.retryPending();
    expect(await svc.suggestEnrichment(run('c1')), isNull);
    expect(await svc.planImport(MemoryCardioRepository([], [])), isNull);
    expect(hc.calls, 0);
  });

  test('toggles are independent, need permission, and persist across restart', () async {
    final dir = await Directory.systemTemp.createTemp('hsync');
    addTearDown(() => dir.delete(recursive: true));
    var fs = await FileHealthSyncStore.open(dir.path);
    var s = HealthSyncService(hc, fs);
    hc.grant = false;
    expect(await s.enable(HealthFeature.writeWorkouts), isFalse);
    expect(s.isEnabled(HealthFeature.writeWorkouts), isFalse);
    hc.grant = true;
    expect(await s.enable(HealthFeature.enrichCardio), isTrue);
    expect(s.isEnabled(HealthFeature.enrichCardio), isTrue);
    expect(s.isEnabled(HealthFeature.writeWorkouts), isFalse);
    expect(s.isEnabled(HealthFeature.importWorkouts), isFalse);
    fs = await FileHealthSyncStore.open(dir.path); // "restart"
    s = HealthSyncService(hc, fs);
    expect(s.isEnabled(HealthFeature.enrichCardio), isTrue);
    expect(s.isEnabled(HealthFeature.writeWorkouts), isFalse);
    await s.disable(HealthFeature.enrichCardio);
    s = HealthSyncService(hc, await FileHealthSyncStore.open(dir.path));
    expect(s.isEnabled(HealthFeature.enrichCardio), isFalse);
  });

  test('corrupt state file reads as everything off', () async {
    final dir = await Directory.systemTemp.createTemp('hsync');
    addTearDown(() => dir.delete(recursive: true));
    File('${dir.path}/health_sync.json').writeAsStringSync('{not json');
    final s = HealthSyncService(hc, await FileHealthSyncStore.open(dir.path));
    expect(s.isEnabled(HealthFeature.writeWorkouts), isFalse);
  });

  test('write: one record; re-save updates, never duplicates', () async {
    await svc.enable(HealthFeature.writeWorkouts);
    svc.onCardioSaved(run('c1', km: 5, cal: 300));
    await svc.retryPending();
    expect(hc.records.length, 1);
    expect(hc.records.values.single.distanceMeters, 5000);
    svc.onCardioSaved(run('c1', secs: 2400, km: 6));
    await svc.retryPending();
    expect(hc.records.length, 1);
    expect(hc.records.values.single.distanceMeters, 6000);
    expect(hc.records.values.single.energyKcal, isNull);
    expect(svc.pendingCount, 0);
  });

  test('delete removes only the record StationX wrote', () async {
    await svc.enable(HealthFeature.writeWorkouts);
    hc.records['foreign'] = WorkoutMapping.forCardio(run('x'))!; // someone else's record
    svc.onCardioSaved(run('c1'));
    await svc.retryPending();
    svc.onCardioDeleted('c1');
    svc.onCardioDeleted('never-written');
    await svc.retryPending();
    expect(hc.records.keys, ['foreign']);
  });

  test('failure is queued, never throws, retried later', () async {
    await svc.enable(HealthFeature.writeWorkouts);
    hc.failWrites = true;
    svc.onCardioSaved(run('c1'));
    await svc.retryPending();
    expect(hc.records, isEmpty);
    expect(svc.pendingCount, 1);
    expect(svc.issue, HealthSyncIssue.retrying);
    hc.failWrites = false;
    await svc.retryPending();
    expect(hc.records.length, 1);
    expect(svc.pendingCount, 0);
    expect(svc.issue, HealthSyncIssue.none);
  });

  test('queued writes survive a restart', () async {
    await svc.enable(HealthFeature.writeWorkouts);
    hc.failWrites = true;
    svc.onCardioSaved(run('c1'));
    await svc.retryPending();
    final s2 = HealthSyncService(hc, HealthSyncState.parse(store.load().toJsonString()).let(MemoryHealthSyncStore.new));
    hc.failWrites = false;
    await s2.retryPending();
    expect(hc.records.length, 1);
  });

  test('permission revoked: nothing written, flagged', () async {
    await svc.enable(HealthFeature.writeWorkouts);
    hc.granted.clear();
    svc.onCardioSaved(run('c1'));
    await svc.retryPending();
    expect(hc.records, isEmpty);
    expect(svc.issue, HealthSyncIssue.needsPermission);
  });

  test('write off: saves are not queued; disabling drops queued writes', () async {
    await svc.enable(HealthFeature.writeWorkouts);
    hc.failWrites = true;
    svc.onCardioSaved(run('c1'));
    await svc.retryPending();
    await svc.disable(HealthFeature.writeWorkouts);
    expect(svc.pendingCount, 0);
    final before = hc.calls;
    svc.onCardioSaved(run('c2'));
    await svc.retryPending();
    expect(hc.calls, before);
  });

  test('observer mirrors new, edited and deleted sessions; ignores old/foreign', () async {
    final cardio = MemoryCardioRepository([run('old', at: base.subtract(const Duration(days: 10)))], []);
    final sessions = MemorySessionRepository([]);
    await svc.enable(HealthFeature.writeWorkouts);
    svc.attach(cardio: cardio, sessions: sessions);
    await cardio.add(run('c1'));
    await settle();
    expect(hc.records.length, 1);
    await cardio.update(run('c1', secs: 3600).copyWith(notes: 'x'));
    await settle();
    expect(hc.records.length, 1);
    await cardio.add(CardioSession(id: 'hc_abc', kind: CardioKind.outdoorRun, workoutDate: base, durationSeconds: 600));
    await cardio.add(CardioSession(id: 'gt_s1', kind: CardioKind.outdoorRun, workoutDate: base, durationSeconds: 600));
    await settle();
    expect(hc.records.length, 1);
    await cardio.delete('c1');
    await settle();
    expect(hc.records, isEmpty);
    await cardio.delete('old'); // never written -> nothing to delete
    await settle();
    await sessions.add(WorkoutSession(id: 'w1', workoutId: 'x', name: 'Push', workoutDate: base.subtract(const Duration(hours: 2)), exercises: const [], durationSeconds: 3000));
    await settle();
    expect(hc.records.values.single.activity, HealthActivity.strength);
    svc.detach();
  });

  test('enrichment: suggestion only, empty fields only', () async {
    await svc.enable(HealthFeature.enrichCardio);
    hc.metrics = const HealthMetrics(heartRates: [140, 160], activeKcal: 280);
    final s = run('c1', cal: 100);
    final e = await svc.suggestEnrichment(s);
    expect(e!.avgHeartRate, 150);
    expect(e.calories, isNull);
    expect(s.avgHeartRate, isNull); // untouched
    hc.metrics = null;
    expect(await svc.suggestEnrichment(s), isNull);
  });

  test('import via service: excludes own, idempotent across apply + restart-like re-plan', () async {
    await svc.enable(HealthFeature.importWorkouts);
    await svc.enable(HealthFeature.writeWorkouts);
    final repo = MemoryCardioRepository([], []);
    svc.onCardioSaved(run('mine'));
    await svc.retryPending();
    final ownId = hc.records.keys.single;
    final start = DateTime.now().subtract(const Duration(days: 1));
    HealthWorkout w(String id, String src) => HealthWorkout(id: id, activityName: 'RUNNING', start: start, end: start.add(const Duration(minutes: 40)), sourceName: src, distanceMeters: 7000);
    hc.external
      ..add(w(ownId, 'whatever'))
      ..add(w('sh1', 'com.sec.android.app.shealth'));
    final plan = (await svc.planImport(repo))!;
    expect(plan.sessions.length, 1);
    expect(plan.skippedOwn, 1);
    expect(repo.sessions, isEmpty); // preview changes nothing
    expect(await svc.applyImport(plan, repo), 1);
    expect(repo.sessions.single.notes, contains('Samsung Health'));
    await repo.delete(repo.sessions.single.id); // user deletes it...
    final again = (await svc.planImport(repo))!;
    expect(again.sessions, isEmpty); // ...and it is not re-offered
    expect(again.skippedAlreadyImported, 1);
  });
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
