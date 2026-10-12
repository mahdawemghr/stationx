-- StationX online-first behaviour test. Runs in ONE transaction that is rolled back by the final exception
-- (the message is the report; every line must say PASS). Needs migration 20261014000000 applied.
-- Run: supabase db query -f supabase/tests/rls_and_rpc_test.sql
do $$
declare
  a uuid := '00000000-0000-0000-0000-00000000000a';
  b uuid := '00000000-0000-0000-0000-00000000000b';
  r text := '';
  n int;
  v text;
  ok boolean;
begin
  insert into auth.users (id, aud, role, email, raw_user_meta_data)
  values (a, 'authenticated', 'authenticated', 'a@test.local', '{}'),
         (b, 'authenticated', 'authenticated', 'b@test.local', '{}');
  select count(*) into n from public.profiles where user_id in (a, b);
  r := r || E'\n' || (case when n = 2 then 'PASS' else 'FAIL' end) || ' profiles auto-created on signup';

  -- ── as A ──
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  set local role authenticated;

  -- init is idempotent
  select public.sx_init_account('[{"id":"w1","name":"Day 1","position":0,"exercises":[]},{"id":"w2","name":"Day 2","position":1,"exercises":[]}]'::jsonb,
                                '{"workout_ids":["w1","w2"],"current_index":0}'::jsonb) into ok;
  r := r || E'\n' || (case when ok then 'PASS' else 'FAIL' end) || ' first sx_init_account created defaults';
  select public.sx_init_account('[{"id":"w9","name":"X","position":0,"exercises":[]}]'::jsonb, null) into ok;
  select count(*) into n from public.workouts where user_id = a;
  r := r || E'\n' || (case when not ok and n = 2 then 'PASS' else 'FAIL' end) || ' second sx_init_account is a no-op (' || n || ' workouts)';

  -- atomic save: delete + rotation together
  perform public.sx_save_workouts('[{"id":"w1","name":"Day 1b","position":0,"exercises":[]}]'::jsonb, array['w2'], '{"workout_ids":["w1"],"current_index":0}'::jsonb);
  select name into v from public.workouts where user_id = a and id = 'w1';
  select count(*) into n from public.workouts where user_id = a;
  r := r || E'\n' || (case when v = 'Day 1b' and n = 1 then 'PASS' else 'FAIL' end) || ' sx_save_workouts upserts+deletes';

  -- finish workout is idempotent and moves rotation
  perform public.sx_finish_workout('{"id":"s1","workout_id":"w1","name":"Day 1","workout_date":"2026-01-01T10:00:00Z","exercises":[]}'::jsonb, '{"workout_ids":["w1"],"current_index":0}'::jsonb);
  perform public.sx_finish_workout('{"id":"s1","workout_id":"w1","name":"Day 1","workout_date":"2026-01-01T10:00:00Z","exercises":[]}'::jsonb, null);
  select count(*) into n from public.workout_sessions where user_id = a;
  r := r || E'\n' || (case when n = 1 then 'PASS' else 'FAIL' end) || ' sx_finish_workout idempotent on id';

  -- a failing finish (bad row) rolls back the rotation change
  begin
    perform public.sx_finish_workout('{"id":"s2","workout_id":"w1","name":"","workout_date":"2026-01-01T10:00:00Z"}'::jsonb, '{"workout_ids":["w1"],"current_index":5}'::jsonb);
    r := r || E'\n' || 'FAIL empty name accepted';
  exception when others then
    select current_index into n from public.rotations where user_id = a;
    r := r || E'\n' || (case when n = 0 then 'PASS' else 'FAIL' end) || ' failed finish leaves rotation untouched';
  end;

  -- server owns updated_at; user_id/created_at immutable
  update public.workout_sessions set name = 'Renamed', updated_at = '2000-01-01' where id = 's1';
  select count(*) into n from public.workout_sessions where id = 's1' and name = 'Renamed' and updated_at > now() - interval '1 minute';
  r := r || E'\n' || (case when n = 1 then 'PASS' else 'FAIL' end) || ' update applied; updated_at is server time (no silent LWW drop)';
  begin
    update public.workout_sessions set user_id = b where id = 's1';
    r := r || E'\n' || 'FAIL user_id changed';
  exception when others then
    r := r || E'\n' || 'PASS user_id cannot be changed (' || sqlstate || ')';
  end;
  begin
    insert into public.workout_sessions (user_id, id, workout_id, name, workout_date) values (b, 'spoof', 'w1', 'x', now());
    r := r || E'\n' || 'FAIL inserted a row for B';
  exception when others then
    r := r || E'\n' || 'PASS cannot insert rows owned by another user (' || sqlstate || ')';
  end;

  -- profile cannot be deleted by the client
  begin
    delete from public.profiles where user_id = a;
  exception when insufficient_privilege then
    null; -- DELETE is revoked for clients: a hard error is the expected, safe outcome
  end;
  select count(*) into n from public.profiles where user_id = a;
  r := r || E'\n' || (case when n = 1 then 'PASS' else 'FAIL' end) || ' client cannot delete own profile';

  -- ── as B ──
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  select count(*) into n from public.workout_sessions;
  r := r || E'\n' || (case when n = 0 then 'PASS' else 'FAIL' end) || ' B sees none of A''s sessions';
  update public.workout_sessions set name = 'hacked' where id = 's1';
  delete from public.workouts where id = 'w1';
  reset role;
  select count(*) into n from public.workout_sessions where user_id = a and name = 'Renamed';
  r := r || E'\n' || (case when n = 1 and exists (select 1 from public.workouts where user_id = a and id = 'w1') then 'PASS' else 'FAIL' end) || ' B cannot update or delete A''s rows';

  -- ── anon ──
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  set local role anon;
  begin
    perform count(*) from public.workout_sessions;
    r := r || E'\n' || 'FAIL anon can read';
  exception when others then
    r := r || E'\n' || 'PASS anon has no access (' || sqlstate || ')';
  end;
  begin
    perform public.sx_reset_account_data();
    r := r || E'\n' || 'FAIL anon can call sx_reset_account_data';
  exception when others then
    r := r || E'\n' || 'PASS anon cannot call sx_* functions (' || sqlstate || ')';
  end;
  reset role;

  -- ── reset wipes only the caller ──
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  set local role authenticated;
  perform public.sx_reset_account_data();
  select count(*) into n from public.workouts where user_id = a;
  r := r || E'\n' || (case when n = 0 then 'PASS' else 'FAIL' end) || ' sx_reset_account_data clears caller data';
  reset role;

  -- ── a new account is initialised WITHOUT any routine ──
  declare c uuid := '00000000-0000-0000-0000-00000000000c'; begin
    insert into auth.users (id, aud, role, email, raw_user_meta_data) values (c, 'authenticated', 'authenticated', 'c@test.local', '{}');
    perform set_config('request.jwt.claims', json_build_object('sub', c, 'role', 'authenticated')::text, true);
    set local role authenticated;
    select public.sx_init_account('[]'::jsonb, null) into ok;
    select count(*) into n from public.workouts where user_id = c;
    r := r || E'\n' || (case when ok and n = 0 and not exists (select 1 from public.rotations where user_id = c) then 'PASS' else 'FAIL' end) || ' sx_init_account with no routines creates none';
    r := r || E'\n' || (case when (select initialized_at from public.profiles where user_id = c) is not null then 'PASS' else 'FAIL' end) || ' account marked initialised';
    select public.sx_init_account('[{"id":"w1","name":"X","position":0,"exercises":[]}]'::jsonb, null) into ok;
    select count(*) into n from public.workouts where user_id = c;
    r := r || E'\n' || (case when not ok and n = 0 then 'PASS' else 'FAIL' end) || ' re-init never creates a program later';

    -- equipment preference: null, empty (bodyweight only) and a valid set are accepted
    update public.profiles set equipment = array['dumbbell','band'] where user_id = c;
    update public.profiles set equipment = '{}' where user_id = c;
    update public.profiles set equipment = null where user_id = c;
    r := r || E'\n' || 'PASS equipment accepts null, empty and valid names';
    begin
      update public.profiles set equipment = array['jetpack'] where user_id = c;
      r := r || E'\n' || 'FAIL unknown equipment accepted';
    exception when others then
      r := r || E'\n' || 'PASS unknown equipment rejected (' || sqlstate || ')';
    end;

    -- experience level (needs migration 20261016000000): null, the three levels, and rejection of junk
    if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'profiles' and column_name = 'experience_level') then
      update public.profiles set experience_level = 'beginner' where user_id = c;
      update public.profiles set experience_level = 'advanced' where user_id = c;
      update public.profiles set experience_level = null where user_id = c;
      begin
        update public.profiles set experience_level = 'grandmaster' where user_id = c;
        r := r || E'\n' || 'FAIL unknown experience level accepted';
      exception when others then
        r := r || E'\n' || 'PASS unknown experience level rejected (' || sqlstate || ')';
      end;
    else
      r := r || E'\n' || 'SKIP experience_level column not present (migration 20261016000000 not applied)';
    end if;

    -- account deletion removes only the caller
    perform public.delete_account();
    reset role;
    r := r || E'\n' || (case when not exists (select 1 from auth.users where id = c) and exists (select 1 from auth.users where id = b) then 'PASS' else 'FAIL' end) || ' delete_account removes only the caller';
    r := r || E'\n' || (case when not exists (select 1 from public.profiles where user_id = c) then 'PASS' else 'FAIL' end) || ' delete_account cascades to the profile';
  end;

  raise exception E'TEST REPORT%', r;
end $$;
