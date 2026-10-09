# Plan: workout sections & sorting · more cardio · more exercises (2026-10-09)

Status: PLAN — nothing implemented yet. Source: three read-only planning agents (code + web research). Approve (or change) the
decisions in §5, then execution starts.

## 1. Workout sections & sorting (what is wrong today → rules)
Found by probing the real seeded workouts/presets:
* w3 "Legs + Shoulders" prints FIVE sections (Legs, Shoulders, Legs, Shoulders, Legs): sections only merge neighbours.
* Chest sub-areas are ordered Upper → Mid → Lower → Flyes, so the general chest work is second (the "sorting" bug).
* Setup saves exercises in TAP order, so the saved workout differs from what the setup screen showed; editor "+ Add" appends at the end
  (creates a second header for the same muscle); no screen shows sub-headers; w2 "Back + Triceps" shows a lone "Shoulders" section (Face Pull).
Rules:
1. One section per broad muscle: Chest, Back, Shoulders, Biceps, Triceps, Forearms, Legs, Core. Section order = order of first appearance
   (= the order the user chose muscles in). Push day = 3 sections, Upper/Full body = 5 — no cap.
2. Inside a section: MAIN exercises first (general/compound, no sub-header — "just chest"), then sub-areas in canonical order with a small
   sub-header (Chest: Mid* → Upper → Lower → Flyes; Back: Lats*+Upper back* → Traps → Lower back; Shoulders: Front/press* → Side → Rear;
   Biceps: Mass* → Peak → Brachialis; Triceps: Presses/dips* → Overhead → Pushdowns; Legs: Quads* → Lunges/quad isolation → Hamstrings →
   Glutes → Calves; Core: Abs* → Stability). No fake precision: region-level profiles are "main".
3. A section header shows when the workout has ≥ 2 sections (same rule on EVERY screen); single-muscle workouts show no section header but keep sub-headers.
4. Custom exercises: sectioned by their muscle targets like built-ins; no curated sub-area → main.
5. Saved order is canonical: `ScheduleBuilder.save` and the editor/setup insertion use `WorkoutSections.arrange / insertionIndex`.
   Existing workouts: arranged ON READ (preview/editor/new sessions), never bulk-rewritten; drafts in progress are NEVER reordered.
Work packages: A domain (workout_sections.dart + a `mainSectionIds` set there, ScheduleBuilder; blocks the rest) → B preview+hub+header widgets,
C editor (+ swap sheet), D logger + complete page, E setup day/review steps, F optional polish (Today tags, library pick mode). B–F run in parallel.

## 2. More cardio (13 new kinds, enum 33 incl. custom)
Add: Indoor Walk / Walking Pad (speed+incline; distinct from treadmill so walks don't pollute run PRs/goals), Nordic Walking, Rucking,
Recumbent Bike, Bike Trainer/Zwift, Cross-Country Skiing, Open Water Swim, Rowing (On Water), Kayak/Canoe/SUP, Dance/Zumba/Aerobics,
Skating/Rollerblading, Climbing/Bouldering, Kickboxing/Martial Arts. Relabel: Treadmill → "Treadmill Run", Swimming → "Pool Swim",
Stationary Bike → "Upright Bike", Stair Climber → "Stair Climber / Stepper", HIIT → "HIIT / Circuit / Conditioning".
Aliases (search only, no kind): 12-3-30, incline walk, stepmill, stairs, peloton, zwift, concept2, battle ropes, sled, metcon, crossfit,
zumba, padel, kayak, sup, bouldering, muay thai. Team/racket sports → one-tap templates in the custom-activity flow (no migration).
No new stored fields (existing CardioField set only). Bike/skating kinds stop getting a run-style pace PR (pace PR gated to kinds with a pace basis).
Select-activity screen with 33 kinds: search over label+aliases+blurb, RECENT strip, group headers (Walk & Run, Cycling, Machines, Water,
Outdoor & Winter, Classes & Conditioning, Custom), compact 64 px rows, "Create custom 'q'" on no result, collapsed sensor banner; one shared icon helper
(3 duplicated exhaustive switches today). Health Connect/HealthKit mapping extended (plugin gaps documented). Migration `20261012000000_cardio_kinds_2.sql`.
Work packages: A domain/data/DB (enum, Health mapping, PR gate, migration) → B helpers (icons/groups/aliases dedupe) → C select-activity UX → D custom templates (parallel with C).

## 3. More exercises (212 → ~380) + equipment
~165 core new exercises (+~25 optional advanced `~` rows), every one with seed row, structured muscle profile (leaf only when defensible), section, and Gym Tracker
alias where a likely name exists: Hammer-Strength/plate-loaded machines (iso-lateral/high/low row, chest/incline/shoulder press, lat pulldown, V-squat, reverse hack,
horizontal leg press, ab coaster, torso rotation, standing glute kickback, machine shrug/back extension), cable variants, Smith-machine variants, kettlebell
(clean, snatch, get-up, press, row, windmill, thruster), band, landmine, calisthenics progressions (archer, scapular, ring, L-sit, Nordic…), grip/forearm,
adductor/tibialis/calf variants, core/rotation, sled/carries.
Equipment: add `kettlebell`, `band`, `smithMachine`, `other` (appended to the enum; Isar stores by name; library chips/create sheet derive from the enum; swap-sheet groups,
equipment icons, progression (band not load-tracked, KB increments) and Gym Tracker import detection updated; ~13 existing seed rows re-mapped via a safe
insert/refresh pass in `topUpCatalog` for NON-custom rows only). Server CHECK on equipment ⇒ migration `20261012010000_equipment_values.sql` (apply BEFORE the app update).
Library at 380 exercises: lazy list + cached PRs already fine; add search normalisation + synonyms (RDL, OHP, skullcrusher, KB…), token matching, ranking,
result count, "Recent" chip (computed, no storage). Favorites need storage → later.
Work packages: WP0 scaffolding (split seed/profiles/sections into per-region part files so agents don't collide + equipment enum + infra) → region packs A–D and library UX F in parallel → G aliases/integrity tests.

## 4. Order of execution
Phase 1 (parallel, disjoint files): cardio A→(B,C,D) · exercises WP0+E · sections A (domain).
Phase 2 (parallel): exercise region packs A–D + library F · sections B–F (screens).
Phase 3: aliases + integrity tests; full analyzer/tests/APK; apply the two migrations with the Supabase token (dry-run first, e2e after); regenerate screenshots; update docs.

## 5. Decisions needed from the user (recommendation first)
1. Sections: "Back" has two main areas (Lats + Upper back both main)? → yes. Main exercises get no sub-header? → yes. Drag-reorder only inside the same muscle section (snap + toast otherwise)? → yes.
2. Treadmill relabel + treadmill walking imports as Indoor Walk? → yes. Team/racket sports as templates only? → yes.
3. Add the 4 equipment values (needs server migration)? → yes.
4. Include the ~25 advanced/niche exercises now? → later (first batch without them). Also: send me GPT's exercise/cardio lists if you want them merged (verified before adding).

## 6. DECISIONS (user answered 2026-10-09) — plan APPROVED
1. Sections: ONE section per muscle — Chest, Back, Shoulders, Biceps, Triceps, **Forearms (سواعد / "Sawaed")**, Legs, Core. **Back is ONE section**: Lats + Upper back
   are its main (no sub-header) group, then Traps and Lower back as small sub-headers inside the Back section. Main exercises have no sub-header.
   Drag-reorder only inside the same muscle section.
   Forearms must be a first-class muscle everywhere: workout sections, library filter, setup/custom-day muscle picker (a domain `SectionMuscle` enum of these 8 broad
   muscles replaces the 7-way `MuscleGroup` in UI-level pickers/filters; storage keeps `MuscleGroup` unchanged — no schema change).
2. Cardio: treadmill relabel + import walking as Indoor Walk — yes; team/racket sports as templates only — yes.
3. Equipment: add kettlebell, band, smithMachine, other — yes. Extra source: GPT's list, saved at
   `/tmp/claude-1000/-home-mahdi-Desktop-projects-stationx/339cc30e-0371-4279-bf5e-c9a94eeb7cc4/scratchpad/gpt_exercises.md` — treat as UNVERIFIED candidates: de-duplicate by normalized
   name vs the catalog, verify unfamiliar names/muscles with web search, fix wrong labels; do not add near-duplicates. Forearm exercises (wrist curls, reverse curls, farmer's carry,
   dead hang, grip work…) MUST be added (user's explicit reminder).
4. Advanced/niche extras (`~` rows): include only what appears in either list; skip the rest.
## 7. Execution phases
Phase 1 (parallel, disjoint files): Cardio-1 (domain+helpers+migration, not applied) · Exercises WP0 (part-file split + equipment infra + migration, not applied) · Sections-domain (SectionMuscle, arrange/group/insertionIndex, builder).
Phase 2 (parallel): Exercise region packs ×4 + library UX · Sections screens (preview/hub, editor, logger, setup, polish incl. Forearms filters) · Cardio-2 (select UX + templates).
Phase 3: aliases + integrity tests; full analyzer/tests/APK; dry-run + apply the two migrations (token, e2e after); regenerate screenshots; docs.
