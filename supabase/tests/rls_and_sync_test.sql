-- StationX Supabase behaviour test. Runs entirely inside one transaction that is
-- ROLLED BACK at the end (the final `raise exception` carries the report), so it
-- leaves no users or rows behind. Every line must say PASS.
--
-- Run:  supabase db query -f supabase/tests/rls_and_sync_test.sql
--  or paste into the SQL editor. Expected outcome: an exception whose message starts
--  with "TEST REPORT" and contains only PASS lines (no FAIL).
do $$
declare
  a uuid := '00000000-0000-0000-0000-00000000000a';
  b uuid := '00000000-0000-0000-0000-00000000000b';
  r text := '';
  n int;
  t0 timestamptz;
  t1 timestamptz;
  v text;
begin
  -- helpers ---------------------------------------------------------------------------
  insert into auth.users (id, aud, role, email, raw_user_meta_data)
  values (a, 'authenticated', 'authenticated', 'a@test.local', '{"name":"Alice"}'),
         (b, 'authenticated', 'authenticated', 'b@test.local', '{}');

  -- 1. signup trigger created profiles
  select count(*) into n from public.profiles where user_id in (a, b);
  r := r || E'\n' || (case when n = 2 then 'PASS' else 'FAIL' end) || ' profiles auto-created on signup (' || n || '/2)';
  select name into v from public.profiles where user_id = a;
  r := r || E'\n' || (case when v = 'Alice' then 'PASS' else 'FAIL' end) || ' profile name taken from signup metadata (' || coalesce(v,'null') || ')';

  -- act as user A ---------------------------------------------------------------------
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  set local role authenticated;

  -- 2. A inserts a backdated session: workout_date (when trained) independent of created_at (entered)
  insert into public.workout_sessions (id, workout_id, name, workout_date, exercises, created_at, updated_at)
  values ('s1', 'w2', 'Back + Triceps', '2024-03-01 18:30+00',
          '[{"exerciseId":"lat_pulldown","sets":[{"weightKg":50,"reps":8,"done":true}]}]',
          now(), '2026-01-01 00:00+00');
  select count(*) into n from public.workout_sessions
   where id = 's1' and workout_date = '2024-03-01 18:30+00' and created_at > workout_date + interval '1 year';
  r := r || E'\n' || (case when n = 1 then 'PASS' else 'FAIL' end) || ' workout_date kept separate from created_at (backdating)';

  -- 3. user_id defaults to the caller
  select count(*) into n from public.workout_sessions where id = 's1' and user_id = a;
  r := r || E'\n' || (case when n = 1 then 'PASS' else 'FAIL' end) || ' user_id defaults to auth.uid()';

  -- 4. A cannot insert a row for B (spoofing)
  begin
    insert into public.workout_sessions (user_id, id, workout_id, name, workout_date)
    values (b, 'spoof', 'w1', 'x', now());
    r := r || E'\n' || 'FAIL A could insert a row owned by B';
  exception when others then
    r := r || E'\n' || 'PASS A cannot insert rows owned by another user (' || sqlstate || ')';
  end;

  -- 5. server_updated_at is server-controlled
  select server_updated_at into t0 from public.workout_sessions where id = 's1';
  r := r || E'\n' || (case when t0 > now() - interval '1 minute' then 'PASS' else 'FAIL' end) || ' server_updated_at set by server';

  -- 6. last-write-wins: a stale edit (older updated_at) is ignored, a newer one applies
  update public.workout_sessions set name = 'STALE', updated_at = '2025-01-01 00:00+00' where id = 's1';
  select name into v from public.workout_sessions where id = 's1';
  r := r || E'\n' || (case when v = 'Back + Triceps' then 'PASS' else 'FAIL' end) || ' stale update ignored (name=' || v || ')';
  update public.workout_sessions set name = 'Newer', updated_at = '2026-06-01 00:00+00' where id = 's1';
  select name, server_updated_at into v, t1 from public.workout_sessions where id = 's1';
  r := r || E'\n' || (case when v = 'Newer' and t1 >= t0 then 'PASS' else 'FAIL' end) || ' newer update applied (name=' || v || ')';

  -- 7. constraints
  begin
    insert into public.cardio_sessions (id, kind, workout_date, duration_seconds) values ('c-bad', 'notAKind', now(), 100);
    r := r || E'\n' || 'FAIL invalid cardio kind accepted';
  exception when check_violation then r := r || E'\n' || 'PASS invalid cardio kind rejected'; end;
  begin
    insert into public.cardio_sessions (id, kind, workout_date, duration_seconds) values ('c-swim', 'swimming', now(), 100);
    r := r || E'\n' || 'PASS new cardio kind (20261011) accepted';
  exception when check_violation then r := r || E'\n' || 'FAIL new cardio kind rejected (migration 20261011 not applied?)'; end;
  begin
    insert into public.cardio_sessions (id, kind, workout_date, duration_seconds) values ('c-walkpad', 'indoorWalk', now(), 100);
    r := r || E'\n' || 'PASS new cardio kind (20261012) accepted';
  exception when check_violation then r := r || E'\n' || 'FAIL new cardio kind rejected (migration 20261012 not applied?)'; end;
  begin
    insert into public.exercises (id, name, primary_muscle, equipment)
    values ('x-kb', 'Kettlebell Swing', 'legs', 'kettlebell'), ('x-smith', 'Smith Squat', 'legs', 'smithMachine');
    r := r || E'\n' || 'PASS new equipment (20261012010000) accepted';
  exception when check_violation then r := r || E'\n' || 'FAIL new equipment rejected (migration 20261012010000 not applied?)'; end;
  begin
    insert into public.exercises (id, name, primary_muscle, equipment) values ('x-bad-eq', 'x', 'legs', 'spaceship');
    r := r || E'\n' || 'FAIL unknown equipment accepted';
  exception when check_violation then r := r || E'\n' || 'PASS unknown equipment rejected'; end;
  begin
    insert into public.workouts (id, name, exercises) values ('w-bad', 'x', '{"not":"an array"}');
    r := r || E'\n' || 'FAIL non-array exercises accepted';
  exception when check_violation then r := r || E'\n' || 'PASS non-array exercises rejected'; end;
  begin
    insert into public.exercises (id, name, primary_muscle, equipment, muscle_targets)
    values ('x-ok', 'Lat Pulldown Variation', 'back', 'cable', '[{"region":"back","muscle":"lats","role":"primary"}]');
    r := r || E'\n' || 'PASS exercise muscle_targets array accepted';
  exception when others then r := r || E'\n' || 'FAIL exercise muscle_targets array rejected: ' || sqlerrm; end;
  begin
    insert into public.exercises (id, name, primary_muscle, equipment, muscle_targets)
    values ('x-bad', 'x', 'back', 'cable', '{"not":"an array"}');
    r := r || E'\n' || 'FAIL non-array muscle_targets accepted';
  exception when check_violation then r := r || E'\n' || 'PASS non-array muscle_targets rejected'; end;
  -- 7b. hardening migration (20261010000000): byte-size caps + tombstones blank their content
  begin
    insert into public.workouts (id, name, exercises)
    values ('w-huge', 'x', (select jsonb_agg(jsonb_build_object('exerciseId', 'e', 'pad', repeat('x', 4000))) from generate_series(1, 90)));
    r := r || E'\n' || 'FAIL oversized (byte-size) workouts.exercises accepted';
  exception when check_violation then r := r || E'\n' || 'PASS oversized workouts.exercises rejected by the byte-size CHECK'; end;
  insert into public.workout_sessions (id, workout_id, name, workout_date, exercises, notes, updated_at)
  values ('s-tomb', 'w1', 'Secret name', now(), '[{"exerciseId":"bench","sets":[{"weightKg":100,"reps":5}]}]', 'private note', '2026-07-01 00:00+00');
  update public.workout_sessions set deleted_at = '2026-07-02 00:00+00', updated_at = '2026-07-02 00:00+00' where id = 's-tomb';
  select count(*) into n from public.workout_sessions
   where id = 's-tomb' and deleted_at is not null and notes = '' and name = '-' and exercises = '[]'::jsonb and cardio is null;
  r := r || E'\n' || (case when n = 1 then 'PASS' else 'FAIL' end) || ' tombstone blanked name/notes/exercises';
  -- a stale tombstone must neither delete nor blank
  update public.workout_sessions set name = 'Alive', notes = 'keep', exercises = '[]', deleted_at = null, updated_at = '2026-07-03 00:00+00' where id = 's-tomb';
  update public.workout_sessions set deleted_at = '2026-07-01 12:00+00', updated_at = '2026-07-01 12:00+00' where id = 's-tomb';
  select count(*) into n from public.workout_sessions where id = 's-tomb' and deleted_at is null and notes = 'keep' and name = 'Alive';
  r := r || E'\n' || (case when n = 1 then 'PASS' else 'FAIL' end) || ' stale tombstone neither deleted nor blanked the row';

  insert into public.cardio_sessions (id, kind, workout_date, duration_seconds, distance_km)
  values ('c1', 'treadmill', now() - interval '3 days', 1800, 4.2);
  insert into public.rotations (workout_ids, current_index) values ('{w1,w2,w3}', 1)
  on conflict (user_id) do update set current_index = excluded.current_index;
  select count(*) into n from public.rotations where current_index = 1;
  r := r || E'\n' || (case when n = 1 then 'PASS' else 'FAIL' end) || ' rotation row upserts (one per user)';

  -- act as user B: must see nothing of A's -------------------------------------------
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  select count(*) into n from public.workout_sessions;
  r := r || E'\n' || (case when n = 0 then 'PASS' else 'FAIL' end) || ' B sees none of A''s sessions (' || n || ')';
  select count(*) into n from public.cardio_sessions;
  r := r || E'\n' || (case when n = 0 then 'PASS' else 'FAIL' end) || ' B sees none of A''s cardio (' || n || ')';
  select count(*) into n from public.profiles;
  r := r || E'\n' || (case when n = 1 then 'PASS' else 'FAIL' end) || ' B sees only own profile (' || n || ')';
  update public.workout_sessions set name = 'HACKED';
  get diagnostics n = row_count;
  r := r || E'\n' || (case when n = 0 then 'PASS' else 'FAIL' end) || ' B cannot update A''s rows (' || n || ' affected)';
  delete from public.workout_sessions;
  get diagnostics n = row_count;
  r := r || E'\n' || (case when n = 0 then 'PASS' else 'FAIL' end) || ' B cannot delete A''s rows (' || n || ' affected)';

  -- anon (not logged in) has no access --------------------------------------------------
  reset role;
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  set local role anon;
  begin
    perform 1 from public.workout_sessions limit 1;
    r := r || E'\n' || 'FAIL anon can read workout_sessions';
  exception when insufficient_privilege then r := r || E'\n' || 'PASS anon has no access to workout_sessions'; end;
  begin
    perform public.delete_account();
    r := r || E'\n' || 'FAIL anon can call delete_account';
  exception when insufficient_privilege then r := r || E'\n' || 'PASS anon cannot call delete_account'; end;

  -- account deletion cascades ---------------------------------------------------------
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  set local role authenticated;
  perform public.delete_account();
  reset role;
  select count(*) into n from auth.users where id = a;
  r := r || E'\n' || (case when n = 0 then 'PASS' else 'FAIL' end) || ' delete_account removed the auth user';
  select (select count(*) from public.workout_sessions where user_id = a)
       + (select count(*) from public.cardio_sessions where user_id = a)
       + (select count(*) from public.rotations where user_id = a)
       + (select count(*) from public.profiles where user_id = a) into n;
  r := r || E'\n' || (case when n = 0 then 'PASS' else 'FAIL' end) || ' all of A''s data cascaded away (' || n || ' rows left)';
  select count(*) into n from auth.users where id = b;
  r := r || E'\n' || (case when n = 1 then 'PASS' else 'FAIL' end) || ' B untouched by A''s deletion';

  -- rollback everything (test users included) and return the report
  raise exception E'TEST REPORT\n%', r;
end $$;
