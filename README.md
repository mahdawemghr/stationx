# StationX

Local-first strength + cardio tracker built with Flutter. Sequential workout rotation, set logging with progression recommendations, estimated 1RM, PRs, cardio (standalone and as a finisher), history/calendar with backdating, and analytics — all stored on-device with Isar and fully usable offline.

## Run

```bash
flutter pub get
flutter run                      # on a device / emulator
flutter test                     # unit + widget + persistence tests
flutter analyze
dart run build_runner build      # after changing lib/data/isar/entities.dart
dart run flutter_launcher_icons  # after changing assets/icon/*
```

Persistence tests call `Isar.initializeIsarCore(download: true)`, which downloads a native library into the project root (`libisar.so`, gitignored) the first time they run — they need network once.

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

Release steps (signing, store checklists, privacy policy): `docs/RELEASE.md`.

See the roadmap for status, deviations from the Stitch designs, and open work.
