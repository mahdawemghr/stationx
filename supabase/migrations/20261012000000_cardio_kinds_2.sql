-- Additive: 13 more CardioKind values (indoorWalk ... martialArts); stored/synced by enum `name`.
-- Re-creates the full list so it always equals the Dart enum (test/domain/cardio_kinds_test.dart checks the drift).
-- Old clients map unknown kinds to `custom`; no data is rewritten.
-- Apply BEFORE shipping a client that can log the new kinds, or those rows fail to sync.
alter table public.cardio_sessions drop constraint if exists cardio_sessions_kind_check;
alter table public.cardio_sessions add constraint cardio_sessions_kind_check check (kind in (
  'outdoorRun','outdoorWalk','treadmill','cycling','stationaryBike','elliptical','rowing','stairClimber','jumpRope',
  'trailRun','hiking','spinBike','airBike','skiErg','arcTrainer','verticalClimber','swimming','handCycle','hiit',
  'boxing','indoorWalk','nordicWalk','rucking','recumbentBike','indoorTrainer','crossCountrySki','openWaterSwim',
  'outdoorRowing','paddling','danceCardio','skating','climbing','martialArts','custom'));
