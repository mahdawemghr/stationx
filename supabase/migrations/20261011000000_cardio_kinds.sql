-- Additive: widen the allowed CardioKind values (stored/synced by enum `name`).
-- Old clients map unknown kinds to `custom`; no data is rewritten.
-- The inline column check from the initial schema is auto-named cardio_sessions_kind_check.
-- (cardio_goals has no kind column.)
alter table public.cardio_sessions drop constraint if exists cardio_sessions_kind_check;
alter table public.cardio_sessions add constraint cardio_sessions_kind_check check (kind in (
  'outdoorRun','outdoorWalk','treadmill','cycling','stationaryBike','elliptical','rowing','stairClimber','jumpRope',
  'trailRun','hiking','spinBike','airBike','skiErg','arcTrainer','verticalClimber','swimming','handCycle','hiit','boxing',
  'custom'));
