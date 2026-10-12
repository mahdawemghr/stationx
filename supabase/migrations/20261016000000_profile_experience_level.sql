-- Additive: the user's experience level for exercise GENERATION (beginner / intermediate / advanced).
-- NULL = never chosen; the app treats NULL as 'intermediate'. Existing rows keep NULL, nothing is
-- rewritten, no policy changes (the profile policies of 20261014000000 already cover new columns),
-- and no saved program is ever touched by this value.
--
-- Deployment order: apply this BEFORE shipping a client that sends `experience_level` (the client only
-- sends the key after the user picked a level, so an older client keeps working either way).
-- Impact: one ALTER TABLE ... ADD COLUMN (metadata-only, instant, no table rewrite) + one CHECK.
alter table public.profiles
  add column if not exists experience_level text;

alter table public.profiles drop constraint if exists profiles_experience_level_check;
alter table public.profiles add constraint profiles_experience_level_check
  check (experience_level is null or experience_level in ('beginner', 'intermediate', 'advanced'));
