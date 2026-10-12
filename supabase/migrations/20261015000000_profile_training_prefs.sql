-- Additive: the equipment the user can train with (onboarding question). NULL = never chosen (nothing is
-- filtered); an empty array = bodyweight only. Names equal the Dart `Equipment` enum (checked by
-- test/domain/equipment_values_test.dart). No existing row is rewritten, no policy changes: the profile
-- policies from 20261014000000 already cover the new column.
alter table public.profiles
  add column if not exists equipment text[];

alter table public.profiles drop constraint if exists profiles_equipment_check;
alter table public.profiles add constraint profiles_equipment_check check (
  equipment is null or (
    cardinality(equipment) <= 9
    and equipment <@ array['cable','dumbbell','barbell','machine','bodyweight','kettlebell','band','smithMachine','other']::text[]
  )
);
