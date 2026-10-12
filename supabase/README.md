# StationX — Supabase backend

Supabase is the **only** source of truth for user data (online-first). The app keeps no copy of it on the device
except a session-scoped in-memory read model and, in Isar, a temporary in-progress-workout draft + the Health Connect opt-in.

* Project ref `fyigpfuddgegvkibnvgd`, URL `https://fyigpfuddgegvkibnvgd.supabase.co` (public).
* **Never** put a `service_role` key, `sb_secret_` key or `sbp_` access token in the app or repo. `SupabaseConfig` refuses them.
  The app has the project URL + publishable key built in, so a plain `flutter run` works. To point a build at another project,
  override them: `flutter run --dart-define-from-file=env/supabase.json` (copy `env/supabase.example.json`; the real file is git-ignored).

## Schema (see `migrations/`, apply in order)
`20261008…initial_schema` … `20261013…sync_gaps` are the earlier migrations; **`20261014000000_online_first.sql`** is the online-first change:
drops tombstones/`deleted_at`/`server_updated_at`/last-write-wins, makes `updated_at` server-owned, makes `user_id`/`created_at` immutable,
adds `profiles.initialized_at`, restricts profile policies (no delete), adds history indexes and the atomic functions below.
**`20261015000000_profile_training_prefs.sql`** adds `profiles.equipment` (nullable `text[]`; NULL = never chosen, empty = bodyweight only).
**`20261016000000_profile_experience_level.sql`** adds `profiles.experience_level` (nullable text, CHECK beginner/intermediate/advanced; NULL = never chosen = treated as intermediate). Additive, metadata-only, no policy change. The client sends the key only after the user picked a level, so it works before or after the migration; apply it before relying on the Profile › Experience level setting. Already present on the live project.
**Back up first and apply together with the online-first client** (old sync clients stop working by design):
`supabase db dump -f backup.sql && supabase db push`.

**Applied state (verified 2026-10-11 against the live project, read-only queries):** 20261008…20261013 present (inferred from the
schema; the project has no `supabase_migrations` history table), and 20261014 + 20261015 were applied on 2026-10-11 after a dry run
inside a rolled-back transaction. Re-check with `select proname from pg_proc where proname like 'sx\_%'` and
`select column_name from information_schema.columns where table_name='profiles' and column_name in ('initialized_at','equipment')`.

| Table | Notes |
|---|---|
| `profiles` | one row per user, created by the signup trigger; no DELETE for clients. Legacy column `auto_rest_seconds` is unused (the rest timer was removed) and kept so no data is dropped |
| `exercises` | custom exercises only (built-in catalogue ships in the app) |
| `workouts`, `rotations` | routines (`position` = order) and the single rotation row. Legacy column `workouts.rest_seconds` is unused and kept |
| `workout_sessions`, `cardio_sessions` | history; `workout_date` (when trained) ≠ `created_at` |
| `cardio_goals`, `custom_cardio_activities` | |

Logical references without FK (intentional, so history survives deleting a routine/activity): `workout_sessions.workout_id`,
`cardio_sessions.custom_activity_id`, `rotations.workout_ids[]`.

## Functions (SECURITY INVOKER, no user-id parameter, `authenticated` only)
`sx_save_workouts(workouts, delete_ids, rotation)` · `sx_finish_workout(session, rotation)` · `sx_init_account(workouts, rotation)` (idempotent, row-locked; the client passes NO routines, so a new account starts empty and the program is generated only in onboarding)
· `sx_reset_account_data()` · `delete_account()` (security definer, deletes only `auth.uid()`).

## Security model
RLS on every table, `user_id = auth.uid()` for read/write; `anon` has no privileges (verified against the live API on 2026-10-10: every table → 401/42501).
Check constraints validate enums, ranges and jsonb size. No Storage buckets are used.

## Auth
Username + password through Supabase Auth; the username maps to a private `<username>@stationx.local` identifier. Confirm-e-mail is OFF (auto-confirm),
min password length 8, **no password reset** (no e-mail is stored). Because anyone can sign up, keep Supabase rate limits on and consider CAPTCHA.

## Tests
* Dart (no credentials): `flutter test` — an in-memory Supabase (`test/helpers/online_fakes.dart`) covers registration, login, logout/account switch, reads, writes, failures, expired sessions, stale responses.
* SQL (manual, after applying the migration): `supabase db query -f supabase/tests/rls_and_rpc_test.sql` → expect only `PASS` lines.

## Manual dashboard checklist
1. Apply the migration (above) and run the SQL test.
2. Authentication → confirm "Confirm e-mail" is off, min password 8, rate limits on.
3. Revoke any access token that was ever pasted into chat (a personal access token `sbp_…` was pasted into the Claude Code session that applied 2026-10-11's migrations: revoke it in Dashboard › Account › Access tokens).
4. Authentication › Attack protection: turn on CAPTCHA and check the rate limits; Authentication › Providers › Email: turn on leaked-password protection if the plan allows it (advisor warning `auth_leaked_password_protection`).
5. The advisor warning `authenticated_security_definer_function_executable` for `delete_account()` is intentional: it is how a user deletes their own account; the function deletes only `auth.uid()`.
