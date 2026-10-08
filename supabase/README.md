# StationX — Supabase database

Cloud **backup / sync target**, used by the app's **optional** cloud sync. The app is local-first (Isar) and works
fully offline; it only talks to this database when the user signs in under *Profile › Cloud backup & sync*.

- Project: **StationX** — ref `fyigpfuddgegvkibnvgd`, region `ap-northeast-1`
  URL: `https://fyigpfuddgegvkibnvgd.supabase.co` (public)
- Schema: `migrations/20261008000000_initial_schema.sql` (applied 2026-10-08) `migrations/20261009000000_exercise_muscle_targets.sql` (**NOT YET APPLIED to the live project - MUST be applied, see below**) and `migrations/20261010000000_hardening.sql` (**NOT YET APPLIED; apply after the muscle-targets one**; jsonb byte-size CHECKs + tombstones blank their content) and `migrations/20261011000000_cardio_kinds.sql` (**NOT YET APPLIED**; widens the `cardio_sessions.kind` check with trailRun, hiking, spinBike, airBike, skiErg, arcTrainer, verticalClimber, swimming, handCycle, hiit, boxing; apply BEFORE shipping a client that can log them, or those rows fail to sync)
- Tests: `tests/rls_and_sync_test.sql` (SQL, rolls itself back; 24 checks, the last 3 need the hardening migration; written but NOT yet run - there was no database access when it was added) and the Flutter end-to-end test `test/e2e/supabase_e2e_test.dart` (real sign-in, two phones, RLS, account deletion)

## Tables ⇄ app models
Every table is per-user: composite primary key `(user_id, id)` where `id` is the **client-generated id**
(so offline-created rows upsert idempotently). Enum-like columns store the Dart enum `name` — the same
strings as the local Isar database.

| Postgres table | Isar entity / domain model | Notes |
|---|---|---|
| `profiles` | `ProfileEntity` / `UserProfile` | one row per user, created by a signup trigger. No password, no `isGuest` |
| `exercises` | `ExerciseEntity` / `Exercise` | **custom exercises only** (the built-in catalogue ships in the app). `muscle_targets` jsonb (nullable): `[{region, muscle?, role: primary\|secondary, emphasis?, weight?}]`, same structure as built-in profiles |
| `workouts` | `WorkoutEntity` / `Workout` | `exercises` + `cardio_finisher` as jsonb, `position` keeps list order |
| `rotations` | `RotationEntity` / `Rotation` | one row per user; the **index**, not the calendar, picks the next workout |
| `workout_sessions` | `SessionEntity` / `WorkoutSession` | `exercises` (logs/sets) and `cardio` as jsonb |
| `cardio_sessions` | `CardioSessionEntity` / `CardioSession` | typed columns (distance, speed, incline, resistance, calories, HR, RPE…) |
| `cardio_goals` | `CardioGoalEntity` / `CardioGoal` | |
| `custom_cardio_activities` | `CustomActivityEntity` / `CustomCardioActivity` | |

Sync columns on every table: `created_at` (when entered), `updated_at` (client edit time),
`server_updated_at` (server-set pull cursor), `deleted_at` (tombstone).
**`workout_date` ≠ `created_at`**: sessions keep *when you trained* (backdatable) separate from *when it was entered*.

## Security model
- **Row Level Security on every table**; one policy each: `user_id = auth.uid()` (read/write own rows only).
- `anon` has **no** privileges. Only signed-in (`authenticated`) users touch data, and only their own.
- `user_id` defaults to `auth.uid()` and the policy's `WITH CHECK` blocks writing rows for someone else.
- **Last-write-wins** trigger: an update whose `updated_at` is older than the stored row is ignored.
- Check constraints validate enums, ranges and jsonb shape (cheap abuse/garbage protection). `20261010000000_hardening.sql` adds
  `pg_column_size` caps on the big jsonb columns (sessions' `exercises` 2 MB, `cardio` 16 KB, workouts' `exercises` 256 KB, exercise
  `instructions` 128 KB / `muscle_targets` 32 KB, rotation `workout_ids` 64 KB). The app clamps every value to these limits before
  upload (`lib/data/sync/sync_rows.dart`, `text_limits.dart`), so local data can never wedge sync.
- **Tombstones blank their content**: the `*_blank_tombstone` triggers overwrite names, notes, exercise logs etc. as soon as `deleted_at`
  is set, so a deleted workout no longer lingers in the cloud until account deletion. Only ids, timestamps and `deleted_at` remain.
  A stale (older `updated_at`) tombstone is discarded by `sx_touch` together with its blanking.
- `public.delete_account()` (security definer, authenticated only) deletes the caller's auth user; everything
  cascades. Stores require in-app account deletion. Supabase's advisor flags it as a *warning*
  (`authenticated_security_definer_function_executable`) — **intentional**: it is the delete-account endpoint and can
  only ever delete `auth.uid()`.
- Triggers/helper functions are not executable through the API.

**Secrets:** never put a Supabase *access token* (`sbp_…`) or the *service_role* key in the app or this repo.
The app may only ever hold the project URL + the **publishable/anon** key (public by design — RLS protects the data).
Pass them at build time (`--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`), not in source.

## Applying / re-applying
```bash
# with the Supabase CLI (recommended)
supabase link --project-ref fyigpfuddgegvkibnvgd
supabase db push                       # applies migrations/
supabase db query -f supabase/tests/rls_and_sync_test.sql   # expect "TEST REPORT" with only PASS lines
```
Or paste a migration into the dashboard SQL editor. Add future changes as **new** migration files — never edit an applied one.

## REQUIRED before shipping the muscle-targets build
`migrations/20261009000000_exercise_muscle_targets.sql` adds `exercises.muscle_targets`. It **must be applied to the live
project before a client build that includes custom-exercise muscle targets is released** (`supabase db push`).
The client always sends `muscle_targets` in `exercises` upserts; against a server without the column PostgREST rejects the
exercises batch, which surfaces as the normal sync error state (rows stay dirty and are retried; nothing is lost, the field is
never silently dropped). Older clients keep working after the migration (the column is nullable); rows without it pull as "no targets".

## REQUIRED / recommended before release (apply in order)
1. `20261009000000_exercise_muscle_targets.sql` - required (see above).
2. `20261010000000_hardening.sql` - recommended; additive. Existing tombstones are blanked once (this bumps their `server_updated_at`, so
   devices re-pull them; applying tombstones is idempotent). Then re-run `tests/rls_and_sync_test.sql` (expect only PASS lines).

## How the app uses it (implemented)
- **Build config:** `flutter run --dart-define-from-file=env/supabase.json` (copy `env/supabase.example.json`; the real file is gitignored).
  Only the project URL + **publishable** key. `SupabaseConfig` *refuses* an `sbp_` token, an `sb_secret_` key or a `service_role` JWT.
  No config ⇒ the feature is absent and the app makes no network requests.
- **Auth:** e-mail + password via Supabase Auth (`SupabaseCloudAuth`). The app never stores the password.
- **Engine** (`lib/data/sync/sync_engine.dart`): PUSH dirty rows (batched upsert) → push tombstones → PULL per table since a stored
  `server_updated_at` cursor. Last-write-wins on `updated_at`, enforced by both the server trigger and the local store.
  Idempotent; a failure keeps progress and retries (1 min); at most one sync runs at a time. If the failure is a lost/expired session (`SyncAuthLostException`), the app signs out locally (data stays), stops retrying and asks the user to sign in again.
- **Triggers:** sign-in, debounced (8 s) after local changes, app resume (throttled 2 min), manual *Sync now*.
- **Clean defaults:** built-in workouts/rotation/demo rows have an epoch `updatedAt` and are never uploaded; they always lose to real cloud data,
  so a fresh install cannot overwrite a user's edited routines. A guest profile defers to the cloud profile on first link.
- **Account switch:** signing in as a *different* account on a device with data asks: keep & add to the new account, or replace with its cloud data.
- **Deletion:** local deletes queue tombstones (`deleted_at`) so other devices delete too. *Delete cloud account & data* calls `delete_account()`.
- **Wiping the device** while signed in also signs out and unlinks sync (otherwise the next sync would pull everything back); the cloud backup is kept.
- **Never synced:** passwords, Health Connect / Apple Health values, the built-in exercise catalogue.

## Verifying (end-to-end, against the real project)
```bash
SUPABASE_E2E=1 SBP=<access token> SUPABASE_URL=https://fyigpfuddgegvkibnvgd.supabase.co \
SUPABASE_ANON_KEY=<publishable key> flutter test test/e2e
```
The access token is used **only** by the test to create/delete two throwaway confirmed users (Management API); the app code under test uses the
publishable key like a phone. The test removes its users (and, by cascade, all their rows) and fails if any remain. Never run it with credentials in a shared CI log.

## Known limits / owner checklist
1. **Password reset** is not implemented in the app (needs a hosted web page to receive the link). Set the Supabase **Site URL** too — confirmation e-mails link to it
   (currently `http://localhost:3000`).
2. Auth settings left at defaults (min password length 6, default SMTP). Harden before release (see `docs/RELEASE.md` §5b).
3. Sync is **last-write-wins per row**: simultaneous offline edits of the *same* row on two devices keep the newer one and drop the older one (no field-level merge).
4. Clock skew: `updated_at` comes from the device clock; a phone with a badly wrong clock can win or lose conflicts unfairly. (`server_updated_at` is server-set and used only as the pull cursor.)
5. Data is not end-to-end encrypted: it is encrypted in transit and protected by RLS; Supabase can technically access it. Reflect that in the privacy policy (done).
6. Large histories sync in pages of 100 (push) / 500 (pull); very large first syncs take several round trips.
7. **Secrets hygiene:** the Supabase access token used to set this up was pasted into a chat — revoke it. The app and repo contain only the public publishable key.
