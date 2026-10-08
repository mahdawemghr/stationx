-- Server hardening (additive; safe to apply on top of 20261008000000 and 20261009000000).
--
--  1. Byte-size CHECKs on the big jsonb / array columns. The earlier checks cap element COUNTS but not
--     the SIZE of each element, so one row could still be megabytes. Caps are generous (several times
--     what the app can produce: <= 100 exercises x <= 100 sets) so legitimate data never hits them.
--     `pg_column_size` measures the stored (possibly compressed) value, so the effective limit on raw
--     JSON is at least this large.
--  2. Length caps on a few text columns that had none.
--  3. Tombstones blank their content. A deleted row used to keep every note / name / exercise log in
--     the cloud until the whole account was deleted. A BEFORE UPDATE trigger now overwrites the content
--     columns the moment `deleted_at` is set (sync only needs id + deleted_at + timestamps). Existing
--     tombstones are blanked once at the end of this file.
--
-- The client (lib/data/sync/sync_rows.dart) clamps every value to these limits before sending, so no
-- local data can fail a CHECK and wedge sync.

-- ───────────────────────── 1. jsonb / array size caps ─────────────────────────
alter table public.workout_sessions drop constraint if exists workout_sessions_exercises_bytes;
alter table public.workout_sessions add constraint workout_sessions_exercises_bytes
  check (pg_column_size(exercises) <= 2097152);   -- 2 MB
alter table public.workout_sessions drop constraint if exists workout_sessions_cardio_bytes;
alter table public.workout_sessions add constraint workout_sessions_cardio_bytes
  check (cardio is null or pg_column_size(cardio) <= 16384);   -- 16 KB
alter table public.workout_sessions drop constraint if exists workout_sessions_workout_id_len;
alter table public.workout_sessions add constraint workout_sessions_workout_id_len
  check (char_length(workout_id) <= 100);

alter table public.workouts drop constraint if exists workouts_exercises_bytes;
alter table public.workouts add constraint workouts_exercises_bytes
  check (pg_column_size(exercises) <= 262144);    -- 256 KB
alter table public.workouts drop constraint if exists workouts_cardio_finisher_bytes;
alter table public.workouts add constraint workouts_cardio_finisher_bytes
  check (cardio_finisher is null or pg_column_size(cardio_finisher) <= 8192);   -- 8 KB

alter table public.exercises drop constraint if exists exercises_instructions_bytes;
alter table public.exercises add constraint exercises_instructions_bytes
  check (pg_column_size(instructions) <= 131072);   -- 128 KB
alter table public.exercises drop constraint if exists exercises_muscle_targets_bytes;
alter table public.exercises add constraint exercises_muscle_targets_bytes
  check (muscle_targets is null or pg_column_size(muscle_targets) <= 32768);    -- 32 KB

alter table public.rotations drop constraint if exists rotations_workout_ids_size;
alter table public.rotations add constraint rotations_workout_ids_size
  check (cardinality(workout_ids) <= 500 and pg_column_size(workout_ids) <= 65536);   -- 64 KB

-- ───────────────────────── 2. text length caps that were missing ─────────────────────────
alter table public.cardio_sessions drop constraint if exists cardio_sessions_custom_activity_id_len;
alter table public.cardio_sessions add constraint cardio_sessions_custom_activity_id_len
  check (custom_activity_id is null or char_length(custom_activity_id) <= 100);

-- ───────────────────────── 3. tombstones blank their content ─────────────────────────
-- Runs BEFORE sx_touch (trigger names fire alphabetically: *_blank_tombstone < *_touch). If sx_touch then
-- rejects the write as stale it returns the OLD row, which discards this blanking too - so a stale
-- tombstone can neither delete nor blank anything. Re-activating a row (deleted_at = null, full content
-- sent by the client) is untouched.
create or replace function public.sx_blank_tombstone()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.deleted_at is null then
    return new;
  end if;
  case tg_table_name
    when 'workout_sessions' then
      new.workout_id := '';
      new.name := '-';
      new.exercises := '[]'::jsonb;
      new.cardio := null;
      new.notes := '';
    when 'cardio_sessions' then
      new.distance_km := null;
      new.speed_kmh := null;
      new.incline_pct := null;
      new.resistance := null;
      new.calories := null;
      new.avg_heart_rate := null;
      new.rpe := null;
      new.route_name := '';
      new.notes := '';
      new.custom_activity_id := null;
    when 'cardio_goals' then
      new.title := '-';
    when 'custom_cardio_activities' then
      new.name := '-';
      new.category := '';
      new.icon_key := '';
    when 'exercises' then
      new.name := '-';
      new.secondary_muscles := '{}';
      new.movement_pattern := '';
      new.instructions := '[]'::jsonb;
      new.tempo := null;
      new.muscle_targets := null;
    when 'workouts' then
      new.name := '-';
      new.description := '';
      new.exercises := '[]'::jsonb;
      new.cardio_finisher := null;
    else
      null; -- profiles / rotations are singletons and are never tombstoned individually
  end case;
  return new;
end;
$$;

revoke all on function public.sx_blank_tombstone() from public, anon, authenticated;

drop trigger if exists workout_sessions_blank_tombstone on public.workout_sessions;
create trigger workout_sessions_blank_tombstone before update on public.workout_sessions
  for each row when (new.deleted_at is not null) execute function public.sx_blank_tombstone();
drop trigger if exists cardio_sessions_blank_tombstone on public.cardio_sessions;
create trigger cardio_sessions_blank_tombstone before update on public.cardio_sessions
  for each row when (new.deleted_at is not null) execute function public.sx_blank_tombstone();
drop trigger if exists cardio_goals_blank_tombstone on public.cardio_goals;
create trigger cardio_goals_blank_tombstone before update on public.cardio_goals
  for each row when (new.deleted_at is not null) execute function public.sx_blank_tombstone();
drop trigger if exists custom_cardio_activities_blank_tombstone on public.custom_cardio_activities;
create trigger custom_cardio_activities_blank_tombstone before update on public.custom_cardio_activities
  for each row when (new.deleted_at is not null) execute function public.sx_blank_tombstone();
drop trigger if exists exercises_blank_tombstone on public.exercises;
create trigger exercises_blank_tombstone before update on public.exercises
  for each row when (new.deleted_at is not null) execute function public.sx_blank_tombstone();
drop trigger if exists workouts_blank_tombstone on public.workouts;
create trigger workouts_blank_tombstone before update on public.workouts
  for each row when (new.deleted_at is not null) execute function public.sx_blank_tombstone();

-- One-off: blank tombstones that already exist (no-op update fires the trigger; it also bumps
-- server_updated_at, so devices simply re-pull those tombstones, which they apply idempotently).
update public.workout_sessions set deleted_at = deleted_at where deleted_at is not null;
update public.cardio_sessions set deleted_at = deleted_at where deleted_at is not null;
update public.cardio_goals set deleted_at = deleted_at where deleted_at is not null;
update public.custom_cardio_activities set deleted_at = deleted_at where deleted_at is not null;
update public.exercises set deleted_at = deleted_at where deleted_at is not null;
update public.workouts set deleted_at = deleted_at where deleted_at is not null;
