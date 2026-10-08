-- Custom exercises keep the same structured muscle targets as built-ins:
-- [{"region":"back","muscle":"lats","role":"primary","emphasis":"...","weight":0.5}, ...]
-- Nullable + additive: rows from older clients simply have no targets. RLS, grants, the sx_touch trigger and
-- the pull index are table-level and need no change.
alter table public.exercises
  add column if not exists muscle_targets jsonb;

alter table public.exercises
  drop constraint if exists exercises_muscle_targets_shape;
alter table public.exercises
  add constraint exercises_muscle_targets_shape
  check (muscle_targets is null or (jsonb_typeof(muscle_targets) = 'array' and jsonb_array_length(muscle_targets) <= 12));
