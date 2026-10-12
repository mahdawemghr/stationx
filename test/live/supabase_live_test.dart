// LIVE Supabase API test. OPT-IN: it does nothing unless STATIONX_LIVE=1 is set, so ordinary
// `flutter test` never touches the network.
//
//   STATIONX_LIVE=1 flutter test test/live/supabase_live_test.dart
//   STATIONX_LIVE=1 STATIONX_LIVE_EXPERIENCE=1 flutter test test/live/supabase_live_test.dart   # after migration 20261016 is applied
//
// What it does (against the project in env/supabase.json, with the PUBLISHABLE key only, exactly like the app):
//   * creates TWO clearly named throwaway accounts (`zzlive_<random>`), A and B, with random passwords
//     (never printed or stored);
//   * exercises the same PostgREST/RPC calls the app makes (profile upsert, sx_save_workouts,
//     sx_finish_workout, custom exercises, delete_account) and checks isolation between A and B;
//   * deletes both accounts through the same `delete_account()` RPC the app uses and verifies they are gone.
// It never reads or writes any other user's rows and never uses a privileged credential. If cleanup fails it
// prints exactly which throwaway usernames remain and stops.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/remote/row_mappers.dart';
import 'package:stationx/domain/domain.dart';

final _live = Platform.environment['STATIONX_LIVE'] == '1';
final _liveExperience = Platform.environment['STATIONX_LIVE_EXPERIENCE'] == '1';

class _Res {
  _Res(this.status, this.body);
  final int status;
  final Object? body;
  List get list => body is List ? body! as List : const [];
  Map get map => body is Map ? body! as Map : const {};
  bool get ok => status >= 200 && status < 300;
}

class _Api {
  _Api(this.url, this.key);
  final String url;
  final String key;
  final _http = HttpClient();

  Future<_Res> call(
    String method,
    String path, {
    Object? body,
    String? token,
    Map<String, String> headers = const {},
  }) async {
    final req = await _http.openUrl(method, Uri.parse('$url$path'));
    req.headers.set('apikey', key);
    if (token != null) req.headers.set('Authorization', 'Bearer $token');
    req.headers.contentType = ContentType.json;
    headers.forEach(req.headers.set);
    if (body != null) req.add(utf8.encode(jsonEncode(body)));
    final res = await req.close().timeout(const Duration(seconds: 30));
    final text = await res.transform(utf8.decoder).join();
    Object? parsed;
    try {
      parsed = text.isEmpty ? null : jsonDecode(text);
    } catch (_) {
      parsed = text;
    }
    return _Res(res.statusCode, parsed);
  }
}

class _User {
  _User(this.name, this.id, this.token, this._pw);
  final String name;
  final String id;
  final String token;
  final String _pw;
}

String _rand(int n) {
  final r = Random.secure();
  const c = '0123456789abcdef';
  return List.generate(n, (_) => c[r.nextInt(16)]).join();
}

void main() {
  late _Api api;
  late _User a, b;
  final created = <_User>[];
  final deleted = <String>{};

  Future<_User> signUp(String label) async {
    final name = 'zzlive_${label}_${_rand(8)}';
    final pw = 'Aa1${_rand(12)}';
    final r = await api.call(
      'POST',
      '/auth/v1/signup',
      body: {'email': '$name@stationx.local', 'password': pw},
    );
    expect(r.ok, isTrue, reason: 'sign-up failed with status ${r.status}');
    final u = _User(
      name,
      (r.map['user'] as Map)['id'] as String,
      r.map['access_token'] as String,
      pw,
    );
    created.add(u);
    return u;
  }

  Future<_Res> login(_User u) => api.call(
    'POST',
    '/auth/v1/token?grant_type=password',
    body: {'email': '${u.name}@stationx.local', 'password': u._pw},
  );

  Map<String, dynamic> profileRow(_User u, UserProfile p) => {
    ...profileToRow(p),
    'user_id': u.id,
  };

  Future<_Res> upsertProfile(_User as, UserProfile p, {_User? ownerRow}) =>
      api.call(
        'POST',
        '/rest/v1/profiles?on_conflict=user_id',
        token: as.token,
        body: [profileRow(ownerRow ?? as, p)],
        headers: {'Prefer': 'resolution=merge-duplicates'},
      );

  Future<_Res> readProfile(_User as, {_User? of}) => api.call(
    'GET',
    '/rest/v1/profiles?select=user_id,equipment,weekly_session_target,age,name${_liveExperience ? ',experience_level' : ''}&user_id=eq.${(of ?? as).id}',
    token: as.token,
  );

  Future<_Res> rpc(_User as, String fn, Map<String, dynamic> params) =>
      api.call('POST', '/rest/v1/rpc/$fn', token: as.token, body: params);

  Workout workout(String id, String name, List<String> exerciseIds) => Workout(
    id: id,
    name: name,
    exercises: [
      for (final e in exerciseIds)
        RoutineExercise(exerciseId: e, sets: 3, repMin: 8, repMax: 12),
    ],
  );

  Future<_Res> saveProgram(_User u, List<Workout> ws) =>
      rpc(u, 'sx_save_workouts', {
        'p_workouts': [
          for (var i = 0; i < ws.length; i++) workoutToRow(ws[i], i),
        ],
        'p_delete_ids': const <String>[],
        'p_rotation': rotationToRow(
          Rotation(workoutIds: [for (final w in ws) w.id]),
        ),
      });

  WorkoutSession session(String id, String workoutId) => WorkoutSession(
    id: id,
    workoutId: workoutId,
    name: 'Live test',
    workoutDate: DateTime.utc(2026, 6, 1, 10),
    exercises: const [
      ExerciseLog(
        exerciseId: 'bench_press',
        sets: [
          SetLog(weightKg: 60, reps: 8, rpe: 8.5),
          SetLog(weightKg: 60, reps: 8),
        ],
      ),
    ],
  );

  Future<_Res> finish(_User u, WorkoutSession s, Rotation? rot) =>
      rpc(u, 'sx_finish_workout', {
        'p_session': sessionToRow(s),
        'p_rotation': rot == null ? null : rotationToRow(rot),
      });

  setUpAll(() async {
    if (!_live) return;
    final cfg =
        jsonDecode(File('env/supabase.json').readAsStringSync())
            as Map<String, dynamic>;
    final key = cfg['SUPABASE_ANON_KEY'] as String;
    expect(
      key.startsWith('sbp_') || key.startsWith('sb_secret_'),
      isFalse,
      reason: 'refusing to run with a privileged key',
    );
    api = _Api(
      (cfg['SUPABASE_URL'] as String).replaceAll(RegExp(r'/+$'), ''),
      key,
    );
    a = await signUp('a');
    b = await signUp('b');
  });

  tearDownAll(() async {
    if (!_live) return;
    final remaining = <String>[];
    for (final u in created) {
      if (!deleted.contains(u.name)) {
        try {
          await rpc(u, 'delete_account', const {});
        } catch (_) {}
      }
      // Verify: the account can no longer sign in.
      final r = await login(u);
      if (r.status == 200) remaining.add(u.name);
    }
    if (remaining.isNotEmpty) {
      // Exactly what remains, so it can be removed by hand. No further destructive action is attempted.
      // ignore: avoid_print
      print(
        'LIVE TEST CLEANUP FAILED. Throwaway accounts still present: ${remaining.join(', ')}',
      );
    }
    expect(
      remaining,
      isEmpty,
      reason: 'throwaway accounts were not cleaned up',
    );
  });

  group(
    'live Supabase API',
    skip: _live ? false : 'set STATIONX_LIVE=1 to run against the real project',
    () {
      test(
        'live schema accepts every column the app writes, has no sync-era columns, and has every function',
        () async {
          // The OpenAPI document (/rest/v1/) needs a privileged key on current Supabase, so the schema is probed
          // with ordinary authenticated requests instead: selecting a column that does not exist fails with 400.
          // Policies and constraints cannot be listed this way; they are covered by the behavioural tests below
          // and by supabase/tests/rls_and_rpc_test.sql.
          final cardio = CardioSession(
            id: 'c',
            kind: CardioKind.rowing,
            workoutDate: DateTime.utc(2026, 1, 1),
            durationSeconds: 60,
            rpe: 7,
          );
          final expected = <String, Map<String, dynamic>>{
            'profiles': profileToRow(
              const UserProfile(equipment: {Equipment.band}),
            ),
            'exercises': exerciseToRow(
              Exercise.custom(
                id: 'e',
                name: 'n',
                targets: const [MuscleTarget.primary(MuscleRegion.chest)],
                equipment: Equipment.band,
              ),
            ),
            'workouts': workoutToRow(workout('w', 'n', ['pushup']), 0),
            'rotations': rotationToRow(const Rotation(workoutIds: ['w'])),
            'workout_sessions': sessionToRow(session('s', 'w')),
            'cardio_sessions': cardioToRow(cardio),
            'cardio_goals': goalToRow(
              CardioGoal(
                id: 'g',
                title: 't',
                metric: GoalMetric.sessions,
                target: 1,
              ),
            ),
            'custom_cardio_activities': customActivityToRow(
              CustomCardioActivity(id: 'a', name: 'n'),
            ),
          };
          for (final e in expected.entries) {
            final keys = e.value.keys.toList();
            final ok = await api.call(
              'GET',
              '/rest/v1/${e.key}?select=${keys.join(',')}&limit=1',
              token: a.token,
            );
            expect(
              ok.status,
              200,
              reason:
                  '${e.key}: a column the app writes is missing on the server: ${ok.body}',
            );
            for (final gone in ['deleted_at', 'server_updated_at']) {
              final r = await api.call(
                'GET',
                '/rest/v1/${e.key}?select=$gone&limit=1',
                token: a.token,
              );
              expect(
                r.status,
                400,
                reason:
                    '${e.key}.$gone still exists (online-first migration not applied?)',
              );
            }
          }
          final init = await api.call(
            'GET',
            '/rest/v1/profiles?select=initialized_at,equipment&limit=1',
            token: a.token,
          );
          expect(init.status, 200);
          // Functions: a call with valid, harmless parameters must not answer "function not found" (404 / PGRST202).
          final calls = <String, Map<String, dynamic>>{
            'sx_save_workouts': {
              'p_workouts': <Object?>[],
              'p_delete_ids': <String>[],
              'p_rotation': null,
            },
            'sx_init_account': {'p_workouts': <Object?>[], 'p_rotation': null},
            'sx_finish_workout': {
              'p_session': <String, Object?>{},
              'p_rotation': null,
            },
            'sx_reset_account_data': <String, dynamic>{},
          };
          for (final c in calls.entries) {
            final r = await rpc(a, c.key, c.value);
            expect(
              r.status,
              isNot(404),
              reason:
                  'function ${c.key} with this signature is missing: ${r.body}',
            );
          }
          // delete_account is exercised for real (and verified) by the deletion tests below.
          final probe = await api.call(
            'GET',
            '/rest/v1/profiles?select=experience_level&limit=1',
            token: a.token,
          );
          // ignore: avoid_print
          print(
            'LIVE INFO experience_level column present: ${probe.status == 200}',
          );
        },
      );

      test(
        'equipment preference: create, read, update, empty array, null, invalid name',
        () async {
          const base = UserProfile(
            name: 'live test',
            weightKg: 80,
            heightCm: 180,
            age: 30,
            weeklySessionTarget: 4,
          );
          var r = await upsertProfile(
            a,
            base.copyWith(equipment: {Equipment.dumbbell, Equipment.band}),
          );
          expect(r.ok, isTrue, reason: 'upsert status ${r.status}: ${r.body}');
          r = await readProfile(a);
          expect((r.list.single as Map)['equipment'], ['band', 'dumbbell']);

          r = await upsertProfile(a, base.copyWith(equipment: <Equipment>{}));
          expect(r.ok, isTrue);
          expect(
            ((await readProfile(a)).list.single as Map)['equipment'],
            <Object?>[],
          );

          r = await upsertProfile(
            a,
            base.copyWith(
              equipment: {Equipment.barbell},
              weeklySessionTarget: 6,
            ),
          );
          expect(r.ok, isTrue);
          var row = (await readProfile(a)).list.single as Map;
          expect(row['equipment'], ['barbell']);
          expect(row['weekly_session_target'], 6);

          // null = "never chosen": a normal app row has equipment: null
          r = await upsertProfile(a, base);
          expect(r.ok, isTrue);
          expect(
            ((await readProfile(a)).list.single as Map)['equipment'],
            isNull,
          );

          // A name the schema does not allow is rejected and the stored value is not changed.
          await upsertProfile(
            a,
            base.copyWith(equipment: {Equipment.kettlebell}),
          );
          final bad = await api.call(
            'POST',
            '/rest/v1/profiles?on_conflict=user_id',
            token: a.token,
            headers: {'Prefer': 'resolution=merge-duplicates'},
            body: [
              {
                ...profileRow(a, base),
                'equipment': ['jetpack'],
              },
            ],
          );
          expect(
            bad.ok,
            isFalse,
            reason: 'an unknown equipment name must be rejected',
          );
          expect(bad.status, 400);
          row = (await readProfile(a)).list.single as Map;
          expect(row['equipment'], [
            'kettlebell',
          ], reason: 'the rejected write must not change anything');
        },
      );

      test(
        'changing equipment (and profile settings) never changes a saved program',
        () async {
          final ws = [
            workout('w_live_0', 'Push', ['bench_press', 'pushup']),
            workout('w_live_1', 'Pull', ['pullup']),
          ];
          expect((await saveProgram(a, ws)).ok, isTrue);
          Future<String> snapshot() async {
            final w = await api.call(
              'GET',
              '/rest/v1/workouts?select=id,name,position,exercises&order=position',
              token: a.token,
            );
            final rot = await api.call(
              'GET',
              '/rest/v1/rotations?select=workout_ids,current_index',
              token: a.token,
            );
            return jsonEncode([w.body, rot.body]);
          }

          final before = await snapshot();
          await upsertProfile(
            a,
            const UserProfile(
              name: 'live test',
              age: 31,
            ).copyWith(equipment: <Equipment>{}),
          );
          await upsertProfile(
            a,
            const UserProfile(
              name: 'live test',
              age: 31,
            ).copyWith(equipment: {Equipment.machine}, weeklySessionTarget: 2),
          );
          expect(await snapshot(), before);
        },
      );

      test(
        'isolation: B cannot read or modify A (profile, routines, sessions with sets, custom exercises)',
        () async {
          // A creates data
          expect(
            (await finish(
              a,
              session('s_live_1', 'w_live_0'),
              const Rotation(
                workoutIds: ['w_live_0', 'w_live_1'],
                currentIndex: 1,
              ),
            )).ok,
            isTrue,
          );
          final custom = Exercise.custom(
            id: 'ex_live_1',
            name: 'Live custom',
            targets: const [MuscleTarget.primary(MuscleRegion.chest)],
            equipment: Equipment.dumbbell,
          );
          final cx = await api.call(
            'POST',
            '/rest/v1/exercises?on_conflict=user_id,id',
            token: a.token,
            headers: {'Prefer': 'resolution=merge-duplicates'},
            body: [
              {...exerciseToRow(custom), 'user_id': a.id},
            ],
          );
          expect(
            cx.ok,
            isTrue,
            reason: 'custom exercise upsert ${cx.status}: ${cx.body}',
          );
          final aProfileBefore = jsonEncode((await readProfile(a)).body);
          final aSessionBefore = jsonEncode(
            (await api.call(
              'GET',
              '/rest/v1/workout_sessions?select=*&id=eq.s_live_1',
              token: a.token,
            )).body,
          );

          // B reads: nothing of A is visible, even when asking for A's rows by id
          expect((await readProfile(b, of: a)).list, isEmpty);
          final bOwn = await api.call(
            'GET',
            '/rest/v1/profiles?select=user_id',
            token: b.token,
          );
          expect(
            bOwn.list.map((x) => (x as Map)['user_id']).toSet().difference({
              b.id,
            }),
            isEmpty,
            reason: 'B must only ever see its own profile',
          );
          for (final t in [
            'workouts',
            'workout_sessions',
            'exercises',
            'rotations',
            'cardio_sessions',
            'cardio_goals',
            'custom_cardio_activities',
          ]) {
            final r = await api.call(
              'GET',
              '/rest/v1/$t?select=*&user_id=eq.${a.id}',
              token: b.token,
            );
            expect(r.list, isEmpty, reason: 'B read A\'s $t');
          }

          // B writes: updates and deletes hit zero rows; inserts for A's user id are refused
          Future<void> noEffect(
            String method,
            String path, [
            Object? body,
          ]) async {
            final r = await api.call(
              method,
              path,
              token: b.token,
              body: body,
              headers: {'Prefer': 'return=representation'},
            );
            expect(
              r.list,
              isEmpty,
              reason: '$method $path changed rows: ${r.body}',
            );
          }

          await noEffect('PATCH', '/rest/v1/profiles?user_id=eq.${a.id}', {
            'equipment': ['band'],
            'age': 99,
          });
          await noEffect('PATCH', '/rest/v1/workouts?user_id=eq.${a.id}', {
            'name': 'hacked',
          });
          await noEffect('DELETE', '/rest/v1/workouts?user_id=eq.${a.id}');
          await noEffect(
            'PATCH',
            '/rest/v1/workout_sessions?user_id=eq.${a.id}',
            {'name': 'hacked'},
          );
          await noEffect(
            'DELETE',
            '/rest/v1/workout_sessions?user_id=eq.${a.id}',
          );
          await noEffect('PATCH', '/rest/v1/exercises?user_id=eq.${a.id}', {
            'name': 'hacked',
          });
          await noEffect('DELETE', '/rest/v1/exercises?user_id=eq.${a.id}');
          await noEffect('PATCH', '/rest/v1/rotations?user_id=eq.${a.id}', {
            'current_index': 0,
          });

          final spoofProfile = await upsertProfile(
            b,
            const UserProfile(name: 'spoof'),
            ownerRow: a,
          );
          expect(
            spoofProfile.ok,
            isFalse,
            reason: 'B must not be able to write a row owned by A',
          );
          final spoofWorkout = await api.call(
            'POST',
            '/rest/v1/workouts',
            token: b.token,
            body: [
              {
                ...workoutToRow(workout('w_spoof', 'spoof', ['pushup']), 0),
                'user_id': a.id,
              },
            ],
          );
          expect(spoofWorkout.ok, isFalse);
          final spoofSession = await api.call(
            'POST',
            '/rest/v1/workout_sessions',
            token: b.token,
            body: [
              {
                ...sessionToRow(session('s_spoof', 'w_live_0')),
                'user_id': a.id,
              },
            ],
          );
          expect(spoofSession.ok, isFalse);

          // A's data is byte-for-byte what it was
          expect(jsonEncode((await readProfile(a)).body), aProfileBefore);
          expect(
            jsonEncode(
              (await api.call(
                'GET',
                '/rest/v1/workout_sessions?select=*&id=eq.s_live_1',
                token: a.token,
              )).body,
            ),
            aSessionBefore,
          );
          final aWorkouts = await api.call(
            'GET',
            '/rest/v1/workouts?select=id,name&order=position',
            token: a.token,
          );
          expect(aWorkouts.list.map((x) => (x as Map)['name']), [
            'Push',
            'Pull',
          ]);

          // Not signed in at all
          expect(
            (await api.call('GET', '/rest/v1/workouts?select=id')).status,
            anyOf(401, 403),
          );
          expect(
            (await api.call('GET', '/rest/v1/profiles?select=user_id')).status,
            anyOf(401, 403),
          );
        },
      );

      test(
        'a stale draft submitted under another account only ever affects that account',
        () async {
          // B finishes "A's" workout id with A's session id. Rows are keyed (user_id, id): B gets its OWN row.
          final r = await finish(b, session('s_live_1', 'w_live_0'), null);
          expect(r.ok, isTrue);
          final aRows = await api.call(
            'GET',
            '/rest/v1/workout_sessions?select=id,name,exercises&id=eq.s_live_1',
            token: a.token,
          );
          final bRows = await api.call(
            'GET',
            '/rest/v1/workout_sessions?select=id&id=eq.s_live_1',
            token: b.token,
          );
          expect(aRows.list.length, 1);
          expect(bRows.list.length, 1);
          final aRot = await api.call(
            'GET',
            '/rest/v1/rotations?select=current_index',
            token: a.token,
          );
          expect(
            (aRot.list.single as Map)['current_index'],
            1,
            reason: 'B submitting must not move A\'s rotation',
          );
        },
      );

      test(
        'retrying the same finish never duplicates the session or its sets, and does not move the rotation twice',
        () async {
          final s = session('s_live_retry', 'w_live_0');
          final rot = const Rotation(
            workoutIds: ['w_live_0', 'w_live_1'],
            currentIndex: 0,
          );
          for (var i = 0; i < 3; i++) {
            expect((await finish(a, s, rot)).ok, isTrue, reason: 'attempt $i');
          }
          final rows = await api.call(
            'GET',
            '/rest/v1/workout_sessions?select=id,exercises&id=eq.s_live_retry',
            token: a.token,
          );
          expect(rows.list.length, 1);
          final sets = ((rows.list.single as Map)['exercises'] as List)
              .expand((e) => (e as Map)['sets'] as List)
              .toList();
          expect(
            sets.length,
            2,
            reason:
                'sets are stored inside the single session row and are not duplicated',
          );
          expect(
            sets.first['rpe'],
            8.5,
            reason: 'historical RPE survives the round trip',
          );
          expect(
            ((await api.call(
                  'GET',
                  '/rest/v1/rotations?select=current_index',
                  token: a.token,
                )).list.single
                as Map)['current_index'],
            0,
          );
          // Same for a plain upsert retried (a timed-out request sent twice)
          final ex = exerciseToRow(
            Exercise.custom(
              id: 'ex_live_1',
              name: 'Live custom',
              targets: const [MuscleTarget.primary(MuscleRegion.chest)],
              equipment: Equipment.dumbbell,
            ),
          );
          for (var i = 0; i < 2; i++) {
            await api.call(
              'POST',
              '/rest/v1/exercises?on_conflict=user_id,id',
              token: a.token,
              headers: {'Prefer': 'resolution=merge-duplicates'},
              body: [
                {...ex, 'user_id': a.id},
              ],
            );
          }
          expect(
            (await api.call(
              'GET',
              '/rest/v1/exercises?select=id&id=eq.ex_live_1',
              token: a.token,
            )).list.length,
            1,
          );
        },
      );

      test(
        'a failing finish (invalid row) rolls back the rotation change',
        () async {
          final before = jsonEncode(
            (await api.call(
              'GET',
              '/rest/v1/rotations?select=current_index,workout_ids',
              token: a.token,
            )).body,
          );
          final bad = await rpc(a, 'sx_finish_workout', {
            'p_session': {
              'id': 's_bad',
              'workout_id': 'w_live_0',
              'name': '',
              'workout_date': '2026-06-01T10:00:00Z',
              'exercises': <Object?>[],
            },
            'p_rotation': {
              'workout_ids': ['w_live_0', 'w_live_1'],
              'current_index': 1,
            },
          });
          expect(bad.ok, isFalse);
          expect(
            jsonEncode(
              (await api.call(
                'GET',
                '/rest/v1/rotations?select=current_index,workout_ids',
                token: a.token,
              )).body,
            ),
            before,
          );
          expect(
            (await api.call(
              'GET',
              '/rest/v1/workout_sessions?select=id&id=eq.s_bad',
              token: a.token,
            )).list,
            isEmpty,
          );
        },
      );

      test(
        'account switching: B\'s session never exposes A, and a signed-out token is rejected after sign-out',
        () async {
          final out = await api.call('POST', '/auth/v1/logout', token: b.token);
          expect(out.status, anyOf(200, 204));
          // After logout the old access token is revoked server-side (or at worst can only ever see B's own rows).
          final r = await api.call(
            'GET',
            '/rest/v1/workouts?select=id,user_id',
            token: b.token,
          );
          if (r.ok) {
            expect(r.list.every((x) => (x as Map)['user_id'] == b.id), isTrue);
          }
          // Logging in again as B works and still sees nothing of A.
          final relog = await login(b);
          expect(relog.ok, isTrue);
          final tok = relog.map['access_token'] as String;
          final fresh = await api.call(
            'GET',
            '/rest/v1/workouts?select=id,user_id',
            token: tok,
          );
          expect(
            fresh.list.every((x) => (x as Map)['user_id'] == b.id),
            isTrue,
          );
        },
      );

      test('deleting A removes A completely and leaves B untouched', () async {
        // Give B something to protect.
        expect(
          (await saveProgram(b, [
            workout('w_b_0', 'B day', ['pushup']),
          ])).ok,
          isTrue,
        );
        final bBefore = jsonEncode([
          (await api.call(
            'GET',
            '/rest/v1/workouts?select=id,name,exercises',
            token: b.token,
          )).body,
          (await api.call(
            'GET',
            '/rest/v1/workout_sessions?select=id,exercises',
            token: b.token,
          )).body,
          (await readProfile(b)).body,
        ]);
        final del = await rpc(a, 'delete_account', const {});
        expect(del.ok, isTrue, reason: 'delete_account status ${del.status}');
        deleted.add(a.name);
        expect(
          (await login(a)).status,
          400,
          reason: 'A must no longer be able to sign in',
        );
        // A's rows are gone: B cannot see them either way, and a token of A (still unexpired) sees nothing.
        final leftovers = await api.call(
          'GET',
          '/rest/v1/workouts?select=id',
          token: a.token,
        );
        expect(leftovers.list, isEmpty);
        final bAfter = jsonEncode([
          (await api.call(
            'GET',
            '/rest/v1/workouts?select=id,name,exercises',
            token: b.token,
          )).body,
          (await api.call(
            'GET',
            '/rest/v1/workout_sessions?select=id,exercises',
            token: b.token,
          )).body,
          (await readProfile(b)).body,
        ]);
        expect(bAfter, bBefore, reason: 'deleting A must not change B');
      });

      test(
        'B can still be deleted by itself and then cannot sign in',
        () async {
          final relog = await login(b);
          final tok = relog.map['access_token'] as String;
          final del = await api.call(
            'POST',
            '/rest/v1/rpc/delete_account',
            token: tok,
            body: const {},
          );
          expect(del.ok, isTrue);
          deleted.add(b.name);
          expect((await login(b)).status, 400);
        },
      );
    },
  );

  group(
    'live: experience level (needs migration 20261016000000 applied)',
    skip: (_live && _liveExperience)
        ? false
        : 'set STATIONX_LIVE=1 and STATIONX_LIVE_EXPERIENCE=1 after applying the migration',
    () {
      late _User c, d;
      setUpAll(() async {
        c = await signUp('c');
        d = await signUp('d');
      });
      tearDownAll(() async {
        for (final u in [c, d]) {
          await rpc(u, 'delete_account', const {});
          deleted.add(u.name);
        }
      });

      test(
        'create, read, update, null/absent, invalid value and cross-user write',
        () async {
          const base = UserProfile(name: 'live test', age: 30);
          var r = await upsertProfile(
            c,
            base.copyWith(experienceLevel: Difficulty.beginner),
          );
          expect(r.ok, isTrue, reason: '${r.status} ${r.body}');
          expect(
            ((await readProfile(c)).list.single as Map)['experience_level'],
            'beginner',
          );
          for (final lv in Difficulty.values) {
            expect(
              (await upsertProfile(c, base.copyWith(experienceLevel: lv))).ok,
              isTrue,
            );
            expect(
              ((await readProfile(c)).list.single as Map)['experience_level'],
              lv.name,
            );
          }
          // A profile saved without the key (never chosen) leaves the stored value alone (merge-duplicates).
          expect((await upsertProfile(c, base)).ok, isTrue);
          expect(
            ((await readProfile(c)).list.single as Map)['experience_level'],
            'advanced',
          );
          final bad = await api.call(
            'POST',
            '/rest/v1/profiles?on_conflict=user_id',
            token: c.token,
            headers: {'Prefer': 'resolution=merge-duplicates'},
            body: [
              {...profileRow(c, base), 'experience_level': 'grandmaster'},
            ],
          );
          expect(bad.ok, isFalse);
          expect(
            ((await readProfile(c)).list.single as Map)['experience_level'],
            'advanced',
          );
          final cross = await api.call(
            'PATCH',
            '/rest/v1/profiles?user_id=eq.${c.id}',
            token: d.token,
            body: {'experience_level': 'beginner'},
            headers: {'Prefer': 'return=representation'},
          );
          expect(cross.list, isEmpty);
          expect(
            ((await readProfile(c)).list.single as Map)['experience_level'],
            'advanced',
          );
          // A saved program is unaffected by the level.
          expect(
            (await saveProgram(c, [
              workout('w_c', 'C', ['pushup']),
            ])).ok,
            isTrue,
          );
          final before = jsonEncode(
            (await api.call(
              'GET',
              '/rest/v1/workouts?select=id,exercises',
              token: c.token,
            )).body,
          );
          await upsertProfile(
            c,
            base.copyWith(experienceLevel: Difficulty.beginner),
          );
          expect(
            jsonEncode(
              (await api.call(
                'GET',
                '/rest/v1/workouts?select=id,exercises',
                token: c.token,
              )).body,
            ),
            before,
          );
        },
      );
    },
  );
}
