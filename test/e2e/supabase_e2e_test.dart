import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/data/isar/isar_store.dart';
import 'package:stationx/data/isar/isar_sync_store.dart';
import 'package:stationx/data/sync/cloud_auth.dart';
import 'package:stationx/data/sync/supabase_sync_gateway.dart';
import 'package:stationx/data/sync/sync_engine.dart';
import 'package:stationx/data/sync/sync_tables.dart';
import 'package:stationx/domain/domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// END-TO-END against the real Supabase project. Opt-in (never runs in normal `flutter test`):
///
///   SUPABASE_E2E=1 SBP=ACCESS_TOKEN SUPABASE_URL=https://REF.supabase.co \
///   SUPABASE_ANON_KEY=PUBLISHABLE_KEY flutter test test/e2e
///
/// The access token is used ONLY to create/delete two throwaway, e-mail-confirmed test users via
/// the Management API (and to inspect rows). The app code under test uses the publishable key,
/// exactly like a phone would. Test users (and, by cascade, all their rows) are removed afterwards.
void main() {
  // Real network round trips (and a Management API call per assertion) take a while.
  const slow = Timeout(Duration(minutes: 4));
  final env = Platform.environment;
  final enabled = env['SUPABASE_E2E'] == '1' && (env['SBP'] ?? '').isNotEmpty && (env['SUPABASE_URL'] ?? '').isNotEmpty && (env['SUPABASE_ANON_KEY'] ?? '').isNotEmpty;
  final url = env['SUPABASE_URL'] ?? '';
  final key = env['SUPABASE_ANON_KEY'] ?? '';
  final ref = Uri.tryParse(url)?.host.split('.').first ?? '';
  const password = 'E2e-Test-Pass-1';
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final emailA = 'e2e.a.$stamp@stationx-test.invalid';
  final emailB = 'e2e.b.$stamp@stationx-test.invalid';
  final tempDirs = <Directory>[];

  Future<dynamic> sql(String q) async {
    final c = HttpClient();
    try {
      final req = await c.postUrl(Uri.parse('https://api.supabase.com/v1/projects/$ref/database/query'));
      req.headers.set('Authorization', 'Bearer ${env['SBP']}');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'query': q}));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode >= 300) throw StateError('SQL failed (${res.statusCode}): $body');
      return jsonDecode(body);
    } finally {
      c.close();
    }
  }

  Future<String> createUser(String email) async {
    final r = await sql('''
      with u as (
        insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
          raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
          confirmation_token, recovery_token, email_change_token_new, email_change)
        values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', '$email',
          crypt('$password', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"name":"E2E"}', now(), now(), '', '', '', '')
        returning id, email)
      insert into auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
      select id::text, id, jsonb_build_object('sub', id::text, 'email', email, 'email_verified', true), 'email', now(), now(), now() from u
      returning user_id''');
    return (r as List).first['user_id'] as String;
  }

  Future<int> countRows(String table, String userId) async {
    final r = await sql("select count(*)::int as n from public.$table where user_id = '$userId'");
    return (r as List).first['n'] as int;
  }

  Future<SupabaseClient> clientFor() async => SupabaseClient(url, key);

  late String idA;

  setUpAll(() async {
    if (!enabled) return;
    HttpOverrides.global = null; // flutter_test blocks real HTTP by default
    await Isar.initializeIsarCore(download: true);
    idA = await createUser(emailA);
    await createUser(emailB);
  });

  tearDownAll(() async {
    if (!enabled) return;
    for (final d in tempDirs) {
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
    await sql("delete from auth.users where email in ('$emailA','$emailB')"); // cascades to every table
    final left = await sql("select count(*)::int as n from auth.users where email like 'e2e.%@stationx-test.invalid'");
    expect((left as List).first['n'], 0, reason: 'test users must not be left behind');
  });

  Future<({IsarStore store, IsarSyncLocalStore local, SyncEngine engine, CloudSyncUser user})> phone(SupabaseClient client, String name) async {
    final dir = Directory.systemTemp.createTempSync('stationx_e2e_$name');
    tempDirs.add(dir);
    final store = await IsarStore.open(directory: dir.path, name: name);
    final local = IsarSyncLocalStore(store);
    return (store: store, local: local, engine: SyncEngine(local, SupabaseSyncGateway(client)), user: CloudSyncUser(client.auth.currentUser!.id));
  }

  test('auth: wrong password rejected, correct password signs in (real GoTrue)', skip: !enabled ? 'set SUPABASE_E2E=1 …' : false, timeout: slow, () async {
    final bad = SupabaseCloudAuth(await clientFor());
    final r = await bad.signIn(emailA, 'definitely-wrong');
    expect(r.status, CloudAuthStatus.invalidCredentials);
    final good = SupabaseCloudAuth(await clientFor());
    final ok = await good.signIn(emailA, password);
    expect(ok.ok, isTrue, reason: ok.message);
    expect(good.user!.id, idA);
    await good.signOut();
    expect(good.user, isNull);
  });

  test('two phones: push, pull, edit, delete converge through the real database', skip: !enabled ? 'set SUPABASE_E2E=1 …' : false, timeout: slow, () async {
    final clientA1 = await clientFor();
    expect((await SupabaseCloudAuth(clientA1).signIn(emailA, password)).ok, isTrue);
    final p1 = await phone(clientA1, 'a1');
    final clientA2 = await clientFor();
    expect((await SupabaseCloudAuth(clientA2).signIn(emailA, password)).ok, isTrue);
    final p2 = await phone(clientA2, 'a2');

    // Phone 1 creates data (incl. a backdated session whose workout_date differs from created_at).
    final trained = DateTime.utc(2024, 3, 1, 18, 30);
    await p1.store.sessions.add(WorkoutSession(
      id: 'e2e_s1',
      workoutId: 'w2',
      name: 'Back + Triceps',
      workoutDate: trained,
      durationSeconds: 3300,
      exercises: const [ExerciseLog(exerciseId: 'lat_pulldown', sets: [SetLog(weightKg: 50, reps: 8), SetLog(weightKg: 47.5, reps: 10, rpe: 8.5)])],
      cardio: CardioSession(id: 'e2e_nested', kind: CardioKind.treadmill, workoutDate: trained, durationSeconds: 1200, distanceKm: 2.5, speedKmh: 7.5, inclinePct: 3),
    ));
    await p1.store.cardio.add(CardioSession(id: 'e2e_c1', kind: CardioKind.outdoorRun, workoutDate: DateTime.utc(2026, 9, 1, 7), durationSeconds: 1938, distanceKm: 5.2, calories: 324, avgHeartRate: 144, rpe: 7.5, routeName: 'Loop'));
    await p1.store.cardio.saveGoal(CardioGoal(id: 'e2e_g1', title: 'Weekly minutes', metric: GoalMetric.durationMinutes, target: 150, isPrimary: true));
    await p1.store.cardio.addCustomActivity(CustomCardioActivity(id: 'e2e_a1', name: 'Boxing', fields: const [CardioField.duration, CardioField.heartRate], rounds: 5));
    await p1.store.exercises.addCustom(Exercise(id: 'e2e_x1', name: 'My Press', primaryMuscle: MuscleGroup.shoulders, equipment: Equipment.dumbbell, isCustom: true, tempo: '3-0-1-0'));
    final w1 = p1.store.workouts.byId('w1')!;
    await p1.store.workouts.saveWorkout(w1.copyWith(name: 'Chest Day (e2e)'));
    await p1.store.workouts.advanceRotation();
    await p1.store.profile.update(p1.store.profile.profile.copyWith(name: 'E2E Sam', weightKg: 81, unit: WeightUnit.lb, isGuest: false));

    final r1 = await p1.engine.run(userId: p1.user.id);
    expect(r1.ok, isTrue, reason: '${r1.error}');
    expect(r1.pushed, greaterThanOrEqualTo(8));
    expect(await p1.local.pendingCount(), 0);

    // The real database really holds it, under the right user, with the right dates.
    final row = (await sql("select workout_date, created_at, user_id, jsonb_array_length(exercises) as n, cardio->>'kind' as ck from public.workout_sessions where id = 'e2e_s1'") as List).single as Map;
    expect(row['user_id'], idA);
    expect(DateTime.parse(row['workout_date'] as String).isAtSameMomentAs(trained), isTrue);
    expect(DateTime.parse(row['created_at'] as String).isAfter(DateTime.utc(2025)), isTrue); // entered now ≠ trained in 2024
    expect((row['n'], row['ck']), (1, 'treadmill'));
    expect(await countRows('cardio_goals', idA), 1);
    expect(await countRows('rotations', idA), 1);
    expect(await countRows('profiles', idA), 1);
    // Built-in catalogue and seed workouts are not uploaded; only the edited one.
    expect(await countRows('exercises', idA), 1);
    expect((await sql("select count(*)::int as n from public.workouts where user_id='$idA'") as List).single['n'], 1);

    // Phone 2 (fresh install) pulls everything.
    final r2 = await p2.engine.run(userId: p2.user.id, preferCloudSingletons: true);
    expect(r2.ok, isTrue, reason: '${r2.error}');
    final got = p2.store.sessions.byId('e2e_s1')!;
    expect(got.workoutDate.isAtSameMomentAs(trained), isTrue);
    expect(got.exercises.single.sets[1].rpe, 8.5);
    expect(got.cardio!.inclinePct, 3);
    expect(p2.store.cardio.byId('e2e_c1')!.calories, 324);
    expect(p2.store.cardio.goals.map((g) => g.id), contains('e2e_g1'));
    expect(p2.store.exercises.byId('e2e_x1')!.tempo, '3-0-1-0');
    expect(p2.store.workouts.byId('w1')!.name, 'Chest Day (e2e)');
    expect(p2.store.workouts.rotation.currentIndex, 1);
    expect(p2.store.profile.profile.name, 'E2E Sam');
    expect(p2.store.profile.profile.unit, WeightUnit.lb);
    expect(await p2.local.pendingCount(), 0);

    // Idempotent.
    final again = await p2.engine.run(userId: p2.user.id);
    expect((again.pushed, again.deleted, again.pulled), (0, 0, 0));

    // Edit on phone 2 → phone 1.
    await p2.store.cardio.update(p2.store.cardio.byId('e2e_c1')!.copyWith(notes: 'edited on phone 2'));
    expect((await p2.engine.run(userId: p2.user.id)).ok, isTrue);
    expect((await p1.engine.run(userId: p1.user.id)).ok, isTrue);
    expect(p1.store.cardio.byId('e2e_c1')!.notes, 'edited on phone 2');

    // Stale write: phone 1 edits offline BEFORE phone 2's later edit; the server keeps the newer one.
    await p1.store.cardio.update(p1.store.cardio.byId('e2e_c1')!.copyWith(notes: 'older edit'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await p2.store.cardio.update(p2.store.cardio.byId('e2e_c1')!.copyWith(notes: 'newer edit'));
    expect((await p2.engine.run(userId: p2.user.id)).ok, isTrue);
    expect((await p1.engine.run(userId: p1.user.id)).ok, isTrue);
    expect(p1.store.cardio.byId('e2e_c1')!.notes, 'newer edit');
    expect(((await sql("select notes from public.cardio_sessions where id='e2e_c1'")) as List).single['notes'], 'newer edit');

    // Delete on phone 1 → phone 2 (tombstone), row kept as tombstone server-side.
    await p1.store.sessions.delete('e2e_s1');
    expect((await p1.engine.run(userId: p1.user.id)).ok, isTrue);
    expect((await p2.engine.run(userId: p2.user.id)).ok, isTrue);
    expect(p2.store.sessions.byId('e2e_s1'), isNull);
    expect(((await sql("select deleted_at is not null as d from public.workout_sessions where id='e2e_s1'")) as List).single['d'], isTrue);

    await p1.store.close();
    await p2.store.close();
  });

  test('row-level security: another signed-in user sees nothing and cannot write as someone else', skip: !enabled ? 'set SUPABASE_E2E=1 …' : false, timeout: slow, () async {
    final b = await clientFor();
    expect((await SupabaseCloudAuth(b).signIn(emailB, password)).ok, isTrue);
    for (final t in SyncTable.values) {
      final rows = await b.from(t.name).select();
      expect(rows.where((r) => r['user_id'] == idA), isEmpty, reason: 'B can read A\'s ${t.name}');
    }
    // Spoofing user_id is rejected by RLS.
    await expectLater(
      b.from('workout_sessions').insert({'user_id': idA, 'id': 'spoof', 'workout_id': 'w1', 'name': 'x', 'workout_date': DateTime.now().toUtc().toIso8601String()}),
      throwsA(isA<PostgrestException>()),
    );
    // Updating/deleting A's rows affects nothing.
    await b.from('cardio_sessions').update({'notes': 'HACKED'}).eq('id', 'e2e_c1');
    await b.from('cardio_sessions').delete().eq('id', 'e2e_c1');
    expect(((await sql("select notes from public.cardio_sessions where id='e2e_c1'")) as List).single['notes'], 'newer edit');
    // Not signed in at all: no access.
    final anon = await clientFor();
    final anonRows = await anon.from('workout_sessions').select().onError<Object>((e, _) => <Map<String, dynamic>>[]);
    expect(anonRows, isEmpty);
  });

  test('account deletion removes the account and every row; local data would be untouched', skip: !enabled ? 'set SUPABASE_E2E=1 …' : false, timeout: slow, () async {
    final client = await clientFor();
    final auth = SupabaseCloudAuth(client);
    expect((await auth.signIn(emailA, password)).ok, isTrue);
    expect(await countRows('cardio_sessions', idA), greaterThan(0));
    final r = await auth.deleteAccount();
    expect(r.ok, isTrue, reason: r.message);
    expect(auth.user, isNull);
    for (final t in SyncTable.values) {
      expect(await countRows(t.name, idA), 0, reason: '${t.name} rows must cascade-delete');
    }
    expect(((await sql("select count(*)::int as n from auth.users where id='$idA'")) as List).single['n'], 0);
    final again = await SupabaseCloudAuth(await clientFor()).signIn(emailA, password);
    expect(again.ok, isFalse);
  });
}

/// Tiny holder so the helper above can return the signed-in user id with the phone.
class CloudSyncUser {
  const CloudSyncUser(this.id);
  final String id;
}
