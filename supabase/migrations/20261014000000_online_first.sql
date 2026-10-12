-- StationX — online-first migration.
--
-- Supabase becomes the ONLY source of truth for user data (no offline queue, no local copy that can
-- diverge). This removes everything that existed purely for offline sync and adds the server-side
-- pieces an online client needs: atomic multi-row operations, one-time account initialisation,
-- server-authoritative timestamps and tighter privileges.
--
-- !! Apply TOGETHER WITH the online-first client build. Clients from the offline-first era (they read
-- !! `deleted_at` / `server_updated_at`) stop working against this schema - that is intentional.
-- !! Back up first:  supabase db dump -f backup.sql
--
-- Effects on existing data
--   * Tombstoned rows (deleted_at is not null) are deleted for good. They were already blanked by the
--     hardening migration (no user content left) and only existed so other devices would delete too.
--   * Every live row is kept untouched. Columns dropped: deleted_at, server_updated_at (all tables).
--
-- Not applied by committing this file. Run it: `supabase db push`, or paste into the SQL editor.

-- ───────────────────────── 1. drop the offline-sync machinery ─────────────────────────
drop trigger if exists workout_sessions_blank_tombstone on public.workout_sessions;
drop trigger if exists cardio_sessions_blank_tombstone on public.cardio_sessions;
drop trigger if exists cardio_goals_blank_tombstone on public.cardio_goals;
drop trigger if exists custom_cardio_activities_blank_tombstone on public.custom_cardio_activities;
drop trigger if exists exercises_blank_tombstone on public.exercises;
drop trigger if exists workouts_blank_tombstone on public.workouts;
drop function if exists public.sx_blank_tombstone();

delete from public.workout_sessions where deleted_at is not null;
delete from public.cardio_sessions where deleted_at is not null;
delete from public.cardio_goals where deleted_at is not null;
delete from public.custom_cardio_activities where deleted_at is not null;
delete from public.exercises where deleted_at is not null;
delete from public.workouts where deleted_at is not null;
delete from public.rotations where deleted_at is not null;

-- Dropping a column also drops the indexes that contain it (the *_pull_idx / *_keyset_idx ones).
alter table public.profiles drop column if exists deleted_at, drop column if exists server_updated_at;
alter table public.exercises drop column if exists deleted_at, drop column if exists server_updated_at;
alter table public.workouts drop column if exists deleted_at, drop column if exists server_updated_at;
alter table public.rotations drop column if exists deleted_at, drop column if exists server_updated_at;
alter table public.workout_sessions drop column if exists deleted_at, drop column if exists server_updated_at;
alter table public.cardio_sessions drop column if exists deleted_at, drop column if exists server_updated_at;
alter table public.cardio_goals drop column if exists deleted_at, drop column if exists server_updated_at;
alter table public.custom_cardio_activities drop column if exists deleted_at, drop column if exists server_updated_at;

-- ───────────────────────── 2. server-authoritative timestamps + immutable ownership ─────────────────────────
-- Before: an UPDATE with an older client `updated_at` was silently turned into a no-op (last-write-wins),
-- which would let an online client believe a write succeeded when nothing changed. Now every write is
-- applied and `updated_at` is the server clock. user_id and created_at can never change.
create or replace function public.sx_touch()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    if new.user_id is distinct from old.user_id then
      raise exception 'user_id is immutable' using errcode = '42501';
    end if;
    new.created_at := old.created_at;
  end if;
  new.updated_at := now();
  return new;
end;
$$;
revoke all on function public.sx_touch() from public, anon, authenticated;

-- ───────────────────────── 3. profile: initialisation marker + tighter policies ─────────────────────────
alter table public.profiles add column if not exists initialized_at timestamptz;

-- Accounts that already hold data (created in the offline-first era) count as initialised.
update public.profiles p set initialized_at = now()
 where initialized_at is null
   and (exists (select 1 from public.workouts w where w.user_id = p.user_id)
        or exists (select 1 from public.rotations r where r.user_id = p.user_id));

-- A user must not be able to delete their own profile row (the app assumes it exists; account
-- deletion goes through delete_account() which cascades from auth.users).
drop policy if exists "profiles: owner full access" on public.profiles;
create policy "profiles: owner select" on public.profiles
  for select to authenticated using (user_id = (select auth.uid()));
create policy "profiles: owner insert" on public.profiles
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy "profiles: owner update" on public.profiles
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
revoke delete on public.profiles from authenticated;

-- Defence in depth: RLS is the control, but TRUNCATE / REFERENCES / TRIGGER are never needed by the app.
revoke truncate, references, trigger on
  public.profiles, public.exercises, public.workouts, public.rotations, public.workout_sessions,
  public.cardio_sessions, public.cardio_goals, public.custom_cardio_activities
  from authenticated, anon;

-- ───────────────────────── 4. indexes for keyset paging of history ─────────────────────────
create index if not exists workout_sessions_hist_idx on public.workout_sessions (user_id, workout_date desc, id);
create index if not exists cardio_sessions_hist_idx on public.cardio_sessions (user_id, workout_date desc, id);
create index if not exists workouts_pos_idx on public.workouts (user_id, position, id);
drop index if exists public.workout_sessions_date_idx;   -- prefix of the *_hist_idx above
drop index if exists public.cardio_sessions_date_idx;

-- ───────────────────────── 5. atomic operations (SECURITY INVOKER: RLS stays in force) ─────────────────────────
-- None of these take a user id: ownership is always auth.uid().

-- Saves/deletes routines and the rotation in ONE transaction (a routine and the rotation that points at it
-- can never be half-written).
create or replace function public.sx_save_workouts(
  p_workouts jsonb default '[]'::jsonb,
  p_delete_ids text[] default '{}',
  p_rotation jsonb default null
) returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if jsonb_typeof(p_workouts) is distinct from 'array' then
    raise exception 'p_workouts must be a json array' using errcode = '22023';
  end if;

  insert into public.workouts (user_id, id, name, description, position, exercises, rest_seconds, cardio_finisher, created_at)
  select uid, w.id, w.name, coalesce(w.description, ''), coalesce(w.position, 0),
         coalesce(w.exercises, '[]'::jsonb), coalesce(w.rest_seconds, 90), w.cardio_finisher,
         coalesce(w.created_at, now())
    from jsonb_to_recordset(p_workouts) as w(
      id text, name text, description text, position int, exercises jsonb,
      rest_seconds int, cardio_finisher jsonb, created_at timestamptz)
  on conflict (user_id, id) do update set
    name = excluded.name,
    description = excluded.description,
    position = excluded.position,
    exercises = excluded.exercises,
    rest_seconds = excluded.rest_seconds,
    cardio_finisher = excluded.cardio_finisher;

  if cardinality(p_delete_ids) > 0 then
    delete from public.workouts where user_id = uid and id = any (p_delete_ids);
  end if;

  if p_rotation is not null then
    insert into public.rotations (user_id, workout_ids, current_index)
    values (
      uid,
      coalesce(array(select jsonb_array_elements_text(p_rotation -> 'workout_ids')), '{}'::text[]),
      coalesce((p_rotation ->> 'current_index')::int, 0))
    on conflict (user_id) do update set
      workout_ids = excluded.workout_ids,
      current_index = excluded.current_index;
  end if;
end;
$$;

-- Saves a finished workout AND moves the rotation together (finishing never leaves the rotation behind).
-- Idempotent on the session id, so a retry after a lost response cannot create a duplicate.
create or replace function public.sx_finish_workout(
  p_session jsonb,
  p_rotation jsonb default null
) returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if jsonb_typeof(p_session) is distinct from 'object' then
    raise exception 'p_session must be a json object' using errcode = '22023';
  end if;

  insert into public.workout_sessions (user_id, id, workout_id, name, workout_date, duration_seconds, exercises, cardio, notes, created_at)
  select uid, s.id, s.workout_id, s.name, s.workout_date, coalesce(s.duration_seconds, 0),
         coalesce(s.exercises, '[]'::jsonb), s.cardio, coalesce(s.notes, ''), coalesce(s.created_at, now())
    from jsonb_to_record(p_session) as s(
      id text, workout_id text, name text, workout_date timestamptz, duration_seconds int,
      exercises jsonb, cardio jsonb, notes text, created_at timestamptz)
  on conflict (user_id, id) do update set
    workout_id = excluded.workout_id,
    name = excluded.name,
    workout_date = excluded.workout_date,
    duration_seconds = excluded.duration_seconds,
    exercises = excluded.exercises,
    cardio = excluded.cardio,
    notes = excluded.notes;

  if p_rotation is not null then
    insert into public.rotations (user_id, workout_ids, current_index)
    values (
      uid,
      coalesce(array(select jsonb_array_elements_text(p_rotation -> 'workout_ids')), '{}'::text[]),
      coalesce((p_rotation ->> 'current_index')::int, 0))
    on conflict (user_id) do update set
      workout_ids = excluded.workout_ids,
      current_index = excluded.current_index;
  end if;
end;
$$;

-- One-time account initialisation, exactly once per account. The profile row is locked, so two devices
-- signing in at the same moment cannot both initialise. The client passes NO routines: a training
-- program is generated only by the user in onboarding (or when they ask for it), never behind their back.
-- Returns true when it initialised the account, false when it was already initialised (or already had
-- routines).
create or replace function public.sx_init_account(
  p_workouts jsonb default '[]'::jsonb,
  p_rotation jsonb default null
) returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  done timestamptz;
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  -- The signup trigger creates the profile; self-heal if it is somehow missing.
  insert into public.profiles (user_id) values (uid) on conflict (user_id) do nothing;
  select initialized_at into done from public.profiles where user_id = uid for update;
  if done is not null then
    return false;
  end if;

  if exists (select 1 from public.workouts where user_id = uid)
     or exists (select 1 from public.rotations where user_id = uid) then
    update public.profiles set initialized_at = now() where user_id = uid;
    return false;
  end if;

  perform public.sx_save_workouts(p_workouts, '{}'::text[], p_rotation);
  update public.profiles set initialized_at = now() where user_id = uid;
  return true;
end;
$$;

-- "Delete all my data": removes every training row of the caller but keeps the account and the profile
-- settings. initialized_at is cleared so the next sign-in re-initialises the account (still without any routines).
create or replace function public.sx_reset_account_data()
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  delete from public.workout_sessions where user_id = uid;
  delete from public.cardio_sessions where user_id = uid;
  delete from public.cardio_goals where user_id = uid;
  delete from public.custom_cardio_activities where user_id = uid;
  delete from public.exercises where user_id = uid;
  delete from public.workouts where user_id = uid;
  delete from public.rotations where user_id = uid;
  update public.profiles set initialized_at = null where user_id = uid;
end;
$$;

revoke all on function public.sx_save_workouts(jsonb, text[], jsonb) from public, anon;
revoke all on function public.sx_finish_workout(jsonb, jsonb) from public, anon;
revoke all on function public.sx_init_account(jsonb, jsonb) from public, anon;
revoke all on function public.sx_reset_account_data() from public, anon;
grant execute on function public.sx_save_workouts(jsonb, text[], jsonb) to authenticated;
grant execute on function public.sx_finish_workout(jsonb, jsonb) to authenticated;
grant execute on function public.sx_init_account(jsonb, jsonb) to authenticated;
grant execute on function public.sx_reset_account_data() to authenticated;
