# StationX

Local-first strength + cardio tracker built with Flutter. Sequential workout rotation, set logging with progression recommendations, estimated 1RM, PRs, cardio (standalone and as a finisher), history/calendar with backdating, and analytics — all stored on-device with Isar and fully usable offline.

## Run

```bash
flutter pub get
flutter run                      # on a device / emulator (offline-only build)
flutter run --dart-define-from-file=env/supabase.json   # with optional cloud sync (see supabase/README.md)
flutter test                     # unit + widget + persistence tests
flutter analyze
dart run build_runner build      # after changing lib/data/isar/entities.dart
dart run flutter_launcher_icons  # after changing assets/icon/*
```

Persistence tests call `Isar.initializeIsarCore(download: true)`, which downloads a native library into the project root (`libisar.so`, gitignored) the first time they run — they need network once.

## Import from Gym Tracker
The companion Gym Tracker app has Settings › Export Data (format: `gym_tracker/docs/EXPORT_FORMAT.md`). In StationX use **Profile › Import from Gym Tracker**, choose the file (or paste it), review the preview and confirm. Only completed workouts are added, each keeping the date you trained; importing the same file twice adds nothing; existing data is never changed. Exercises are matched by name (with a curated alias list); unknown ones become custom exercises. Code: `lib/data/import/`, `lib/features/profile/gym_tracker_import_flow.dart`.

## Architecture

```
lib/
  main.dart                 opens the Isar store, starts the app
  app/                      AppController (session/account rules), AppScope, AppNav (all navigation)
  core/
    theme/                  design tokens (SxColors, SxText, SxSpace…) + ThemeData
    widgets/                shared components (SxCard, SxButton, charts, MuscleMap, sheets, states…)
    utils/                  formatters (Fmt), icons
  domain/                   pure Dart: models, repository interfaces, services
                            (rotation, Epley 1RM, progression, PRs, volume, Smart Swap, plate calc)
  data/
    data_store.dart         DataStore abstraction
    isar/                   Isar entities, mappers, IsarStore (write-through repositories)
    memory/                 in-memory repositories (tests / previews)
    seed/                   exercise catalogue + demo data
  features/<feature>/       screens (today, workouts, active_workout, exercises, progress, history, cardio, profile, auth…)
assets/fonts, assets/icon
design_reference/           Stitch screenshots + HTML (visual source of truth)
docs/STATIONX_UI_IMPLEMENTATION_ROADMAP.md   living roadmap, decisions, known limitations
```

Rules worth knowing:
- UI depends only on the repository **interfaces** and domain services. Never calculate 1RM/progression/PRs in widgets.
- **Rotation is index-based, not calendar-based.** It advances only when a workout is completed.
- `workoutDate` (when you trained, backdatable) is always separate from `createdAt` (when it was entered).
- No network access anywhere in the app; fonts are bundled.
- Use theme tokens (`context.sx`, `SxText`, `SxSpace`); avoid raw colours.

Optional wearable data (sleep, resting heart rate) is read-only and opt-in: Health Connect on Android, Apple Health on iOS (iOS path untested — see roadmap §P). Samsung Health and most fitness wearables sync into those two stores.

Optional cloud backup/sync (Supabase, off unless configured *and* the user signs in): `supabase/README.md`.

Release steps (signing, store checklists, privacy policy): `docs/RELEASE.md`.

See the roadmap for status, deviations from the Stitch designs, and open work.
