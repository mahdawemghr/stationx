-- Sync completeness pass (additive and backward compatible; no data is rewritten, nothing is dropped).
--
-- The audit found NO missing data column: every persisted field already has a
-- column and the client clamps to the CHECKs. What was missing is an index for exact keyset paging.
--
-- The app now pulls with a (server_updated_at, id) keyset instead of "server_updated_at >= cursor":
--   where server_updated_at > :ts or (server_updated_at = :ts and id > :id)
--   order by server_updated_at, id limit :n
-- `now()` is the TRANSACTION time, so every row of one batch upsert (or one bulk UPDATE such as the
-- hardening migration's tombstone blanking) carries the same server_updated_at; a plain cursor cannot
-- page through thousands of such rows. This index serves that query for every id-keyed table.
-- (Singleton tables profiles / rotations have one row per user and keep their existing index.)
--
-- Old clients keep working: they only use `server_updated_at >= cursor`, which the same index also serves.
-- Also relied on by the client (no schema change needed): a tombstone for a row that was never uploaded
-- is sent as an INSERT of a minimal row that already has deleted_at set (all NOT NULL columns have values).
create index if not exists exercises_keyset_idx on public.exercises (user_id, server_updated_at, id);
create index if not exists workouts_keyset_idx on public.workouts (user_id, server_updated_at, id);
create index if not exists workout_sessions_keyset_idx on public.workout_sessions (user_id, server_updated_at, id);
create index if not exists cardio_sessions_keyset_idx on public.cardio_sessions (user_id, server_updated_at, id);
create index if not exists cardio_goals_keyset_idx on public.cardio_goals (user_id, server_updated_at, id);
create index if not exists custom_cardio_activities_keyset_idx on public.custom_cardio_activities (user_id, server_updated_at, id);

-- The (user_id, server_updated_at) indexes are now prefixes of the keyset indexes: drop the redundant ones.
drop index if exists public.exercises_pull_idx;
drop index if exists public.workouts_pull_idx;
drop index if exists public.workout_sessions_pull_idx;
drop index if exists public.cardio_sessions_pull_idx;
drop index if exists public.cardio_goals_pull_idx;
drop index if exists public.custom_cardio_activities_pull_idx;
