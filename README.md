# StationX

Online-first strength + cardio tracker built with Flutter and Supabase. Username + password account; the training program is generated once in onboarding (or when you ask), then only changes when you edit it. Sequential workout rotation, set logging with progression recommendations, estimated 1RM, PRs, cardio (standalone and as a finisher), history/calendar with backdating, and analytics. An internet connection is needed to log in and to save; only a temporary in-progress workout draft lives on the device (Isar).

## Run

```bash
flutter pub get
flutter run      # the public Supabase URL + publishable key are built in; override with --dart-define-from-file=env/supabase.json
flutter test                     # unit + widget + persistence tests
flutter analyze
dart run build_runner build      # after changing lib/data/isar/entities.dart
dart run flutter_launcher_icons  # after changing assets/icon/*
```

Device-store tests call `Isar.initializeIsarCore(download: true)`, which downloads a native library into the project root (`libisar.so`, gitignored) the first time they run — they need network once. Everything else runs against an in-memory Supabase (`test/helpers/online_fakes.dart`), no credentials needed.

## Import from Gym Tracker
The companion Gym Tracker app has Settings › Export Data (format: `gym_tracker/docs/EXPORT_FORMAT.md`). In StationX use **Profile › Import from Gym Tracker**, choose the file (or paste it), review the preview and confirm. Only completed workouts are added, each keeping the date you trained; importing the same file twice adds nothing; existing data is never changed. Exercises are matched by name (with a curated alias list); unknown ones become custom exercises. Code: `lib/data/import/`, `lib/features/profile/gym_tracker_import_flow.dart`.

## Architecture

```
lib/
  main.dart                 bootstrap: Supabase init, device store, starts the app
  app/                      AppController (session/account rules), AppScope, AppNav (all navigation)
  core/
    theme/                  design tokens (SxColors, SxText, SxSpace…) + ThemeData
    widgets/                shared components (SxCard, SxButton, charts, MuscleMap, sheets, states…)
    utils/                  formatters (Fmt), icons
  domain/                   pure Dart: models, repository interfaces, services
                            (rotation, Epley 1RM, progression, PRs, volume, Smart Swap, plate calc)
  data/
    data_store.dart         DataStore abstraction
    remote/                 Supabase gateway, row mappers, OnlineStore (server-first writes, in-memory read model)
    isar/                   device-only state (workout draft, Health Connect opt-in)
    memory/                 in-memory repositories (tests / previews)
    seed/                   exercise catalogue + demo data
  features/<feature>/       screens (today, workouts, active_workout, exercises, progress, history, cardio, profile, auth…)
assets/fonts, assets/icon
design_reference/           Stitch screenshots + HTML (visual source of truth)
docs/                       privacy policy, release checklist, store assets, hosted pages
```

Rules worth knowing:
- UI depends only on the repository **interfaces** and domain services. Never calculate 1RM/progression/PRs in widgets.
- **Rotation is index-based, not calendar-based.** It advances only when a workout is completed.
- `workoutDate` (when you trained, backdatable) is always separate from `createdAt` (when it was entered).
- Writes go to Supabase first; the screen changes only after the server confirmed. Fonts are bundled.
- **The saved program never changes on its own.** Generation (onboarding / explicit regeneration), the weekly training/rest-day goal (always 7 together) and the rotation pointer are three separate things.
- Use theme tokens (`context.sx`, `SxText`, `SxSpace`); avoid raw colours.

Optional wearable data (workout import, heart rate on workouts, write-back) is opt-in: Health Connect on Android, Apple Health on iOS (iOS path untested). Samsung Health and most fitness wearables sync into those two stores. Sleep and resting heart rate (the Today recovery card) are read only if you switch on the separate sleep-and-recovery option.

Backend (Supabase schema, RLS, functions, auth settings, tests): `supabase/README.md`.

Release steps (signing, store checklists, privacy policy): `docs/RELEASE.md`.

See the roadmap for status, deviations from the Stitch designs, and open work.
