-- StationX — initial Supabase schema (cloud backup / sync target).
--
-- The app is local-first (Isar on device). This database mirrors the app's domain
-- models so a sync layer can push/pull per-user rows. Nothing here is required for the
-- app to work offline, and the app does NOT connect to it yet (see supabase/README.md).
--
-- Conventions
--  * `id` is the client-generated id (text) — natural key together with `user_id`, so
--    offline-created rows upsert idempotently.
--  * Enum-like columns store the Dart enum `name` (same strings as the local Isar DB).
--  * `created_at` = when the record was entered; sessions also have `workout_date` =
--    when the user trained (backdatable). They are NEVER the same concept.
--  * `updated_at` is the client's edit time (last-write-wins); `server_updated_at` is set by
--    the server and is the cursor for incremental pulls (client clocks are not trusted).
--  * `deleted_at` is a tombstone so deletions propagate to other devices.
--  * Row Level Security: every row is private to its owner (`user_id = auth.uid()`).
--    The `anon` role has no access.

-- ───────────────────────── helpers ─────────────────────────
create or replace function public.sx_touch()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Last-write-wins: ignore a stale edit coming from a device with an older copy.
  if tg_op = 'UPDATE' and new.updated_at < old.updated_at then
    return old;
  end if;
  new.server_updated_at := now();
  return new;
end;
$$;

-- ───────────────────────── profiles ─────────────────────────
create table public.profiles (
  user_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  name text not null default 'Athlete' check (char_length(name) <= 100),
  email text check (char_length(email) <= 320),
  weight_kg numeric(6,2) not null default 74 check (weight_kg > 0 and weight_kg < 700),
  height_cm numeric(5,1) not null default 175 check (height_cm > 0 and height_cm < 300),
  age int not null default 25 check (age between 1 and 130),
  unit text not null default 'kg' check (unit in ('kg','lb')),
  theme_mode text not null default 'dark' check (theme_mode in ('dark','oled','system')),
  default_sets int not null default 3 check (default_sets between 1 and 20),
  default_rep_min int not null default 8 check (default_rep_min between 1 and 100),
  default_rep_max int not null default 12 check (default_rep_max between 1 and 100),
  auto_rest_seconds int not null default 90 check (auto_rest_seconds between 0 and 3600),
  progression_enabled boolean not null default true,
  weekly_session_target int not null default 4 check (weekly_session_target between 0 and 21),
  cardio_distance_unit_km boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  server_updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint profiles_rep_range check (default_rep_min <= default_rep_max)
);
create index profiles_pull_idx on public.profiles (user_id, server_updated_at);

-- ───────────────────────── custom exercises (the built-in catalogue is in the app) ─────────────────────────
create table public.exercises (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null check (char_length(id) between 1 and 100),
  name text not null check (char_length(name) between 1 and 200),
  primary_muscle text not null check (primary_muscle in ('chest','back','shoulders','biceps','triceps','legs','core')),
  secondary_muscles text[] not null default '{}' check (secondary_muscles <@ array['chest','back','shoulders','biceps','triceps','legs','core']::text[]),
  equipment text not null check (equipment in ('cable','dumbbell','barbell','machine','bodyweight')),
  movement_pattern text not null default '' check (char_length(movement_pattern) <= 100),
  instructions jsonb not null default '[]' check (jsonb_typeof(instructions) = 'array' and jsonb_array_length(instructions) <= 30),
  is_custom boolean not null default true,
  tempo text check (char_length(tempo) <= 20),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  server_updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, id)
);
create index exercises_pull_idx on public.exercises (user_id, server_updated_at);

-- ───────────────────────── workouts (routine days) + rotation ─────────────────────────
create table public.workouts (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null check (char_length(id) between 1 and 100),
  name text not null check (char_length(name) between 1 and 200),
  description text not null default '' check (char_length(description) <= 1000),
  position int not null default 0,
  exercises jsonb not null default '[]' check (jsonb_typeof(exercises) = 'array' and jsonb_array_length(exercises) <= 100),
  rest_seconds int not null default 90 check (rest_seconds between 0 and 3600),
  cardio_finisher jsonb check (cardio_finisher is null or jsonb_typeof(cardio_finisher) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  server_updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, id)
);
create index workouts_pull_idx on public.workouts (user_id, server_updated_at);

-- Sequential rotation: the INDEX (not the calendar) decides the next workout. One row per user.
create table public.rotations (
  user_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  workout_ids text[] not null default '{}',
  current_index int not null default 0 check (current_index >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  server_updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index rotations_pull_idx on public.rotations (user_id, server_updated_at);

-- ───────────────────────── strength sessions ─────────────────────────
create table public.workout_sessions (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null check (char_length(id) between 1 and 100),
  workout_id text not null,
  name text not null check (char_length(name) between 1 and 200),
  workout_date timestamptz not null,
  duration_seconds int not null default 0 check (duration_seconds between 0 and 172800),
  exercises jsonb not null default '[]' check (jsonb_typeof(exercises) = 'array' and jsonb_array_length(exercises) <= 100),
  cardio jsonb check (cardio is null or jsonb_typeof(cardio) = 'object'),
  notes text not null default '' check (char_length(notes) <= 5000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  server_updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, id)
);
create index workout_sessions_pull_idx on public.workout_sessions (user_id, server_updated_at);
create index workout_sessions_date_idx on public.workout_sessions (user_id, workout_date desc);

-- ───────────────────────── cardio ─────────────────────────
create table public.cardio_sessions (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null check (char_length(id) between 1 and 100),
  kind text not null check (kind in ('outdoorRun','outdoorWalk','treadmill','cycling','stationaryBike','elliptical','rowing','stairClimber','jumpRope','custom')),
  workout_date timestamptz not null,
  duration_seconds int not null check (duration_seconds between 0 and 172800),
  distance_km numeric(8,3) check (distance_km >= 0 and distance_km < 100000),
  speed_kmh numeric(6,2) check (speed_kmh >= 0 and speed_kmh < 500),
  incline_pct numeric(5,2) check (incline_pct between -50 and 100),
  resistance int check (resistance between 0 and 1000),
  calories int check (calories between 0 and 100000),
  avg_heart_rate int check (avg_heart_rate between 20 and 260),
  rpe numeric(3,1) check (rpe between 0 and 10),
  route_name text not null default '' check (char_length(route_name) <= 200),
  notes text not null default '' check (char_length(notes) <= 5000),
  custom_activity_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  server_updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, id)
);
create index cardio_sessions_pull_idx on public.cardio_sessions (user_id, server_updated_at);
create index cardio_sessions_date_idx on public.cardio_sessions (user_id, workout_date desc);

create table public.cardio_goals (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null check (char_length(id) between 1 and 100),
  title text not null check (char_length(title) between 1 and 200),
  metric text not null check (metric in ('durationMinutes','distanceKm','sessions','calories')),
  target numeric(10,2) not null check (target > 0),
  period text not null default 'week' check (period in ('week','month')),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  server_updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, id)
);
create index cardio_goals_pull_idx on public.cardio_goals (user_id, server_updated_at);

create table public.custom_cardio_activities (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null check (char_length(id) between 1 and 100),
  name text not null check (char_length(name) between 1 and 200),
  category text not null default 'Custom' check (char_length(category) <= 100),
  icon_key text not null default 'fitness_center' check (char_length(icon_key) <= 60),
  fields text[] not null default '{duration}' check (fields <@ array['duration','distance','pace','speed','incline','resistance','calories','heartRate','rpe']::text[]),
  round_seconds int check (round_seconds > 0),
  rest_seconds int check (rest_seconds >= 0),
  rounds int check (rounds > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  server_updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, id)
);
create index custom_cardio_activities_pull_idx on public.custom_cardio_activities (user_id, server_updated_at);

-- ───────────────────────── triggers (server cursor + last-write-wins) ─────────────────────────
create trigger profiles_touch before insert or update on public.profiles
  for each row execute function public.sx_touch();
create trigger exercises_touch before insert or update on public.exercises
  for each row execute function public.sx_touch();
create trigger workouts_touch before insert or update on public.workouts
  for each row execute function public.sx_touch();
create trigger rotations_touch before insert or update on public.rotations
  for each row execute function public.sx_touch();
create trigger workout_sessions_touch before insert or update on public.workout_sessions
  for each row execute function public.sx_touch();
create trigger cardio_sessions_touch before insert or update on public.cardio_sessions
  for each row execute function public.sx_touch();
create trigger cardio_goals_touch before insert or update on public.cardio_goals
  for each row execute function public.sx_touch();
create trigger custom_cardio_activities_touch before insert or update on public.custom_cardio_activities
  for each row execute function public.sx_touch();

-- ───────────────────────── Row Level Security ─────────────────────────
alter table public.profiles enable row level security;
create policy "profiles: owner full access" on public.profiles
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
revoke all on public.profiles from anon;
alter table public.exercises enable row level security;
create policy "exercises: owner full access" on public.exercises
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
revoke all on public.exercises from anon;
alter table public.workouts enable row level security;
create policy "workouts: owner full access" on public.workouts
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
revoke all on public.workouts from anon;
alter table public.rotations enable row level security;
create policy "rotations: owner full access" on public.rotations
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
revoke all on public.rotations from anon;
alter table public.workout_sessions enable row level security;
create policy "workout_sessions: owner full access" on public.workout_sessions
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
revoke all on public.workout_sessions from anon;
alter table public.cardio_sessions enable row level security;
create policy "cardio_sessions: owner full access" on public.cardio_sessions
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
revoke all on public.cardio_sessions from anon;
alter table public.cardio_goals enable row level security;
create policy "cardio_goals: owner full access" on public.cardio_goals
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
revoke all on public.cardio_goals from anon;
alter table public.custom_cardio_activities enable row level security;
create policy "custom_cardio_activities: owner full access" on public.custom_cardio_activities
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
revoke all on public.custom_cardio_activities from anon;

-- ───────────────────────── account lifecycle ─────────────────────────
-- Create the profile row when a user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, email, name)
  values (
    new.id,
    new.email,
    left(coalesce(nullif(trim(new.raw_user_meta_data ->> 'name'), ''), 'Athlete'), 100)
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Store policies (Google Play / App Store) require in-app account deletion.
-- Deleting the auth user cascades to every table above.
create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

-- Trigger/security-definer functions must not be callable through the API.
revoke all on function public.sx_touch() from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
