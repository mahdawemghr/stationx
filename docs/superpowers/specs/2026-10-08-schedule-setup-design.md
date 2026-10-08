# Schedule setup (post-registration) — design

Goal: after the user registers (or any time later, optionally for guests) StationX asks how they train, lets them pick a
split or build a custom one, choose exercises per muscle grouped into sub-sections, add their own exercises, and saves the result
as real workouts + rotation. Rules kept: rotation is index-based; offline; no fake data; no commits.

## Flow
1. Pick: Push/Pull/Legs · Upper/Lower · Full Body · Bro split · Custom. Cards show their days and a "days/week" text hint.
2. Per day, per muscle: sub-sections (Back → Lats / Upper back & traps / Lower back; Legs → Quads / Hamstrings & glutes / Calves; …).
   Preset picks are pre-ticked with a one-line reason; user ticks/unticks, edits sets/reps, taps "+ Add exercise"
   (reuses `showCreateExerciseSheet`; the new exercise is ticked immediately and listed under "Your exercises").
3. Review: days in order, sets + minutes per day. Save → `ScheduleBuilder.save`. Land on Today.
Skippable at every step ("Skip for now"); leaving midway asks before discarding. Custom: user names days and picks muscles per day.
Entry points: after Create account; optional prompt for guests; "Set up my schedule" in Workouts tab and Profile.

## Contracts (already in the repo)
* `lib/domain/services/split_models.dart`: `SplitSection`, `SplitDayPlan`, `SplitPreset`.
* `lib/domain/services/schedule_builder.dart`: `ScheduleBuilder.validate/save` (finished).
* `lib/domain/services/split_catalog.dart`: `SplitCatalog.presets / sectionsFor / sectionIdOf / grouped / reasonFor / suggest` (skeleton; catalog task fills it).
Sub-sections are a static map in code keyed by exercise id (no schema/Isar/Supabase change). Custom exercises → "Your exercises" section.

## Tasks (parallel, disjoint files)
* **Catalog task** owns `lib/domain/**`, `lib/data/**`, `test/domain`, `test/data`.
* **UI task** owns `lib/features/**`, `lib/app/nav.dart`, `test/features`, `test/a11y`.

# Muscle taxonomy & recommendation system (added)

Decisions
* Detailed taxonomy lives in `lib/domain/models/muscle.dart`: `MuscleRegion` (11) → `Muscle` (leaf subdivisions, the user's hierarchy) + `MuscleTarget` (region, optional leaf, primary/secondary, optional emphasis, weight) + `ExerciseMuscleProfile` (many targets). The legacy 7-way `MuscleGroup` stays as the broad layer used by storage/sync/simple UI (each region maps to one via `legacy`) — **no Isar/Supabase schema change**.
* Built-in exercises: detailed profiles in `MuscleProfiles.builtIn(id)` (static data, like the split sections). Custom exercises: region-level profile derived from their stored broad fields (no fake precision). Persisting detailed targets for custom exercises = a later schema change (Isar field + Supabase column + migration) — NOT in this version.
* No fake precision: when a leaf can't be assigned defensibly, the target is region-level (`muscle == null`).
* Contribution model: primary 1.0, secondary 0.5 (`MuscleWeights`, single place); "direct" coverage counts primary only, "weighted" adds secondary.
* `MuscleCoverage` (workout / program / history → `CoverageReport` with per-leaf and per-region numbers and `CoverageLevel` per week), `ExerciseRecommender` (`forDay`, `replacements`, `gaps`) — one engine for generation, replacement, coverage, future coach. `SmartSwapService` keeps its public API but delegates ranking. `SplitCatalog` sections/suggestions derive from the profiles (consistency test) and `suggest`/presets use coverage so a day does not stack exercises on already-covered muscles.
* `gaps` is informational: considers frequency/volume/program; "low" never auto-adds exercises.
* Equipment: recommender accepts `allowedEquipment` (null = all); no onboarding UI for it yet.
* UI stays simplified: library sub-muscle filter chips, details show primary/secondary, replace sheet uses the engine, onboarding review shows coverage. Full balance dashboards are later.
