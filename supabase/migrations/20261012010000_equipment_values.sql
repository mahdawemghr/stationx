-- Additive: 4 more Equipment values (kettlebell, band, smithMachine, other); stored/synced by enum `name`.
-- Re-creates the full list so it always equals the Dart enum (test/domain/equipment_values_test.dart checks the drift).
-- Old clients map unknown equipment to `bodyweight` on pull (sync_rows `_enum` fallback); no data is rewritten.
-- Apply BEFORE shipping a client that can use the new equipment, or those exercise rows fail to sync.
-- (The inline column CHECK of the initial schema is auto-named exercises_equipment_check.)
alter table public.exercises drop constraint if exists exercises_equipment_check;
alter table public.exercises add constraint exercises_equipment_check check (equipment in (
  'cable','dumbbell','barbell','machine','bodyweight','kettlebell','band','smithMachine','other'));
