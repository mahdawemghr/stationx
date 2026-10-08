# StationX — UI Implementation Roadmap

Living document. Last analysis: 2026-10-07. **Nothing in this repo has been committed by the implementing agent; all work is left uncommitted for review.**

Legend: `[ ]` not done · `[x]` done **and verified** · `[~]` done with a documented limitation.

---

## 0. Critical finding (read first)

The task brief describes an app that already has Isar, models, repositories, a workout engine, rotation, progression, 1RM, PR logic, cardio logic, Health Connect, sync scaffolding, tests. **None of that exists in this repository.** At analysis time `lib/` contained 3 files (407 lines):

| File | Content |
|---|---|
| `lib/main.dart` | `MaterialApp` → `LandingPage` |
| `lib/landing/landing_page.dart` | A rough, hand-styled landing page (lime `#BFFF00` on black, contains a placeholder-looking `calculateED` pill) |
| `lib/home/home_page.dart` | "Welcome to the Home Page" placeholder |
| `test/widget_test.dart` | Untouched Flutter counter template test (fails against current app) |

`pubspec.yaml` has no dependencies other than `cupertino_icons`. Git history is 3 commits (`start`, `landding`, `almost done landing`). There are no other branches, stashes, or Isar references anywhere.

**Decision (user, 2026-10-07): "Roadmap + UI only, mock data".** The Stitch UI is built against clearly-marked **in-memory repositories behind interfaces**, with domain services (rotation, 1RM, progression, PR, volume) in a pure-Dart domain layer so a real Isar implementation can be dropped in later without touching presentation code. Consequences:

* "Connect to real data" in this roadmap means "connect to the repository interfaces". **Update 2026-10-07: persistence is now implemented** — the app runs on an on-device Isar database (see §L). The in-memory repositories remain for tests/previews.
* Domain services that the brief says "already exist" had to be written. They are **provisional reference implementations**, isolated in `lib/domain/services/`, and flagged in §H. The UI never calculates 1RM/progression/PRs itself.
* No Isar / Health Connect / sync dependency was added. Fields `createdAt`, `updatedAt`, `syncStatus` and the `workoutDate` vs `createdAt` split are included in the domain models so the future data layer is compatible.

---

## A. Current project analysis

### Architecture (before this work)
* Flutter 3.47.6 / Dart ^3.11.5, single Material app, no state management, no router (direct `home:`), no theme (colors inline), no assets, no fonts, no tests of value.
* Platforms generated: android, ios, linux, macos, web, windows. Android package `com.example.stationx` (template default; no custom permissions in manifest).
* Reusable widgets: none. Design system: none (inline `Color(0xFFBFFF00)` and `Colors.grey[...]`).
* Technical debt relevant to UI work: stale template test, template `README`, `HomePage` placeholder unused by anything, `pubspec` description is the template string, `analysis_options.yaml` is the stock `flutter_lints` file.

### Target architecture (chosen)
```
lib/
  main.dart                      bootstrap
  app/                           StationXApp, routes, AppScope (dependency container)
  core/
    theme/                       tokens (colors, type, spacing, radii), ThemeData
    widgets/                     shared components (see §C)
    utils/                       formatters (duration, pace, weight, date)
  domain/
    models/                      pure Dart entities (+ createdAt/updatedAt/syncStatus)
    services/                    rotation, e1rm, progression, pr, volume, cardio metrics
    repositories/                abstract interfaces
  data/
    memory/                      in-memory implementations (MOCK, resets on restart)
    seed/                        mock seed data (isolated, clearly labelled)
  features/<feature>/            screens + feature widgets + feature controller (ChangeNotifier)
assets/fonts/                    Space Grotesk, Geist, JetBrains Mono (bundled, OFL) — no runtime font download
```
* **State management:** `ChangeNotifier` + `ListenableBuilder` and a tiny `InheritedWidget` (`AppScope`) for dependency lookup. No new package. (Rationale: zero new dependencies; screens only depend on repository interfaces + controllers, so it is easy to swap for Riverpod/Bloc later.)
* **Navigation:** Navigator 1.0 with a central `AppRoutes` table. A 4-tab shell (`Today · Workouts · Progress · Profile`) hosts tab roots in an `IndexedStack`; all other screens are pushed on the root navigator (bottom nav hidden on full-screen flows such as the active workout).
* **Database:** Isar (`isar_community`) behind the repository interfaces — see §L. In-memory repositories remain for tests/previews.

### Product rules that the UI must preserve (spec from the brief)
1. **Sequential rotation:** `currentWorkoutIndex` selects the next workout; completing a workout advances it `(i+1) % n`; skipping a calendar day does nothing. Preview screen copy "Rotation advances upon completion. Missed sessions stay queued in sequence." matches this and is kept. "Change Next Workout" sets the index explicitly.
2. **Backdating:** `workoutDate` (user-chosen) is stored separately from `createdAt` (now). The Stitch "Backdate" screens write `workoutDate` only.
3. **Cardio adapts by type:** treadmill = duration, distance, speed, incline; stationary bike = duration, distance, resistance; outdoor run = duration, distance, pace. Standalone cardio and a cardio block inside a strength workout are both supported.
4. **Progression/1RM/PR** come from domain services, never widgets.
5. **Local-first**: no network call anywhere; fonts are bundled.

---

## B. Stitch screen inventory

Source: `design_reference/<folder>/{screen.png, code.html}`. Two `DESIGN.md` files: `kinetic_obsidian` (lime `#B8F000`, canvas `#121416`/`#101214`) and `kinetic_oled` (cyan/purple, pure black). **Every one of the 35 screen HTMLs uses the Obsidian palette** (`primary-container #b8f000`, `background #121416`). `kinetic_oled` is only referenced by `kinetic_app_icon_oled_cyan_purple` → decision in §D.

All screens are **New** (no existing Flutter screen) except the landing page, which is **Existing and needs redesign** (`lib/landing/landing_page.dart`). `HomePage` is a placeholder superseded by the Today tab.

Phase numbers refer to §E.

### Auth / entry
| Folder | Screen | Flutter target | Status | Notes / discrepancies |
|---|---|---|---|---|
| `landing_page` | Landing | `features/landing/landing_page.dart` | Existing → redesign | "VMAX 0.82 m/s barbell velocity", "Auto RPE", "VO2 estimates", "10,480 kg moved" benchmark pod are marketing fiction (no velocity sensor). Keep copy that is true (local-first, strength/cardio/progress); show moved-kg only from real data else hide. "Continue as Guest (Offline Mode)" is the primary real path. |
| `login_page` | Sign in | `features/auth/login_page.dart` | New | No backend exists. Form validation UI (invalid email / required) is real; submit creates a **local profile session** only. Biometric/Passkey, "Continue with Google", "256-bit encrypted", "secure storage enclave" claims have no implementation → shown disabled/removed, not faked. Password never stored or logged. |
| `register_page` | Create account | `features/auth/register_page.dart` | New | Live password-strength rules + match check implemented. "Initial Split Setup" opens split picker (3-day rotation seed). Local profile only. |

### Shell tabs
| Folder | Screen | Target | Status | Notes |
|---|---|---|---|---|
| `today_home` | Today | `features/today/today_page.dart` | New | Next workout from rotation (not date). "DAY 2/3" = rotation index/length. Week stats from workout history. Recent progress from progression/PR service. Recovery card (sleep/HR/score) is **Health Connect territory** → empty "Connect Health Connect" state; not fabricated. Greeting uses profile name. |
| `workouts_hub_routines` | Workouts hub | `features/workouts/workouts_hub_page.dart` | New | Segmented "My Routines / Templates / Saved". Active rotation card with progress, "Launch", "Edit Routine", "Change Next Workout". "CYCLE 04", mesocycle, "2.4k Lifters" popularity are not product concepts → omitted/derived. Templates are static local template list (labelled templates, not fake social proof). |
| `progress_dashboard_analytics` | Progress (strength) | `features/progress/progress_page.dart` | New | Strength/Cardio switch (cardio_progress_analytics). "Weekly Velocity Index/Adaptive Surge/Peak Power" fiction → replaced by real weekly workouts/volume/sets/PR counters. Muscle volume dose bars from volume service (set targets configurable). "Analytical Insight" only when computable. |
| `profile_app_settings` | Profile & settings | `features/profile/profile_page.dart` | New | Metrics (weight/height/age) editable locally. Workout config (default sets, rep window, auto rest timer), units (kg/lb), theme (Dark/OLED/System), accent. Copy "SQLite Embedded" is wrong for this project → "Local database". Health Connect row shows true state (not connected). Export/Backup rows: export implemented as local JSON/CSV string share-less preview where possible, else documented "coming soon". "Delete All Local Data" with confirmation. "Strain Capacity 94%", "PRO" badge → removed (no source). |

### Strength workout flow
| Folder | Screen | Target | Status | Notes |
|---|---|---|---|---|
| `workout_preview` | Workout preview | `features/workouts/workout_preview_page.dart` | New | Target sequence with "Last session" from history. |
| `workout_editor` | Routine architecture | `features/workouts/workout_editor_page.dart` | New | Reorder (ReorderableListView), delete, edit sets/reps sheet, add exercise (library picker), rest default, save. |
| `swap_exercise_modal` | Smart Swap | `features/workouts/swap_exercise_sheet.dart` | New | **Smart Swap does not exist in the codebase.** Domain service `SmartSwapService` ranks alternatives from the exercise catalog by primary-muscle match, secondary overlap, movement pattern and equipment filter, and returns a *computed* match score. The Stitch "98% Match / strain overlap" numbers are therefore computed, not hardcoded. Catalog is mock → flagged §H. |
| `active_workout_logger` | Active workout | `features/active_workout/active_workout_page.dart` | New | Elapsed + rest timers (Ticker-light, `Stopwatch`+1s timer, isolated rebuilds), set table (prev/kg/reps/done), add set, plate calc sheet, Smart Overload card (from `ProgressionService`), swap, collapse/expand exercises, finish. **Tempo "3-0-1-0" and "RPE 7.5" are not in the spec** → shown only if the exercise defines them (optional field). Numeric entry via custom bottom-sheet keypad per DESIGN.md. |
| `workout_complete` | Workout complete | `features/active_workout/workout_complete_page.dart` | New | PRs, progression index from services. "+340 KCAL / Metabolic target" fiction → hidden unless kcal data exists. Saves with `workoutDate=now`, `createdAt=now`, advances rotation exactly once. |
| `active_mixed_workout_strength_cardio` | Mixed session | `features/active_workout/mixed_workout_page.dart` | New | Strength section collapse + cardio finisher block (treadmill fields: duration/distance/speed/incline). HR/cadence tiles are sensor-gated. |
| `workout_complete_strength_cardio` | Mixed complete | `features/active_workout/mixed_complete_page.dart` | New | Muscle volume breakdown from volume service; cardio block summary; weekly aerobic target. Calories split only when calories present. |

### Exercises
| Folder | Screen | Target | Status | Notes |
|---|---|---|---|---|
| `exercise_library` | Library | `features/exercises/exercise_library_page.dart` | New | Search, muscle chips (8 zones), equipment chips, PR badge per exercise, custom exercise. Lazy list. Used as picker for editor/swap. |
| `exercise_details` | Exercise details | `features/exercises/exercise_details_page.dart` | New | PR, est. 1RM, total volume, muscle profile, execution steps (static catalog text), "Library ID" derived. Stitch anatomical vector image has no asset → muscle-chip graphic drawn with Canvas/placeholder icon. |
| `exercise_history_strength_analytics` | Exercise history | `features/exercises/exercise_history_page.dart` | New | Metric tabs (weight/reps/volume/e1RM) chart (CustomPainter), session set logs, log set. |
| `personal_records_estimated_1rm` | PR board | `features/progress/personal_records_page.dart` | New | Filters by category and PR type; Epley shown (`W×(1+R/30)`). Stitch says "Epley/Brzycki hybrid" but displays Epley — only Epley implemented; copy corrected. Cardio PRs live on the cardio analytics screen. |

### Cardio
| Folder | Screen | Target | Status | Notes |
|---|---|---|---|---|
| `cardio_home` | Cardio home | `features/cardio/cardio_home_page.dart` | New | Quick start, week stats, weekly goal, recent. |
| `select_cardio_activity` | Select activity | `features/cardio/select_activity_page.dart` | New | Activity catalog with per-activity metric set. Sensor readiness banner shows true "no sensors" state. |
| `cardio_preparation_goal` | Prepare session | `features/cardio/cardio_prepare_page.dart` | New | Target duration/distance/open. Weather/Apple Watch/voice coach/GPS are not available → removed or "not connected" states. Progression hint from last session is real. |
| `active_cardio_tracker` | Live tracker | `features/cardio/active_cardio_page.dart` | New | Timer + manual distance entry (no GPS in architecture). Elevation profile/HR/cadence/voice pacer sensor-gated. Hold-to-lock control implemented. |
| `active_cardio_paused_state` | Paused | same page, paused state | New | |
| `cardio_complete_summary` | Complete | `features/cardio/cardio_complete_page.dart` | New | HR zones/splits/GPS map only when data exists; otherwise sections hidden. |
| `cardio_session_details` | Details | `features/cardio/cardio_session_details_page.dart` | New | Share is a no-op placeholder (no share package) → documented. Delete confirmation dialog. |
| `edit_cardio_session` | Edit | `features/cardio/edit_cardio_session_page.dart` | New | Recomputes pace live; "VO2 max / V_DOT" claims removed. |
| `backdate_cardio_session` | Backdate | `features/cardio/backdate_cardio_page.dart` | New | Writes `workoutDate` only; shows "Logged today" separately. |
| `cardio_history` | History | `features/cardio/cardio_history_page.dart` | New | Type filter chips, sort, month summary. |
| `cardio_progress_analytics` | Cardio progress | `features/progress/cardio_progress_view.dart` | New | Weekly duration bars, cardio PRs (longest duration/distance, fastest). |
| `cardio_goals_targets` | Goals | `features/cardio/cardio_goals_page.dart` | New | Create/edit goals, weekly aerobic duration + sub-targets. |
| `cardio_goal_details_insights` | Goal details | `features/cardio/cardio_goal_details_page.dart` | New | Derived insights only. |
| `create_custom_cardio_activity` | Custom activity | `features/cardio/create_custom_activity_page.dart` | New | Metric toggles map to supported fields only; interval engine (rounds) is **not in the data model** → UI present, persisted as optional template fields, flagged §H. |
| `cardio_settings_sensors` | Cardio settings | `features/cardio/cardio_settings_page.dart` | New | Units/pace format real; Polar/Health Connect/audio coach rows show "Not available" states. |
| `cardio_empty_states_confirmation` | Empty + delete dialog | shared `EmptyState` + `ConfirmDialog` used by cardio home/history | New | Component reference more than a screen. |

### History / calendar
| Folder | Screen | Target | Status | Notes |
|---|---|---|---|---|
| `calendar_workout_history` | Calendar + session log | `features/history/calendar_page.dart` | New | Month grid from `workoutDate`; day detail with exercise telemetry. Backdate button. |
| `calendar_activity_history_cardio_strength` | Calendar (strength+cardio) | same page, merged | New | Two Stitch variants merged into one page: filter chips All/Strength/Cardio/Mixed + dual dots. |

### Non-screen assets
| Folder | Use |
|---|---|
| `kinetic_app_icon_oled_cyan_purple` | App icon artwork (cyan/purple). Not wired to launcher icons in this pass (needs `flutter_launcher_icons` + exported PNG) → §H. |
| `kinetic_obsidian/DESIGN.md`, `kinetic_oled/DESIGN.md` | Design system docs; see §D. |

### Cross-cutting discrepancies Stitch ↔ StationX product
1. **Brand name:** Stitch says "KINETIC"; product is **StationX**. UI uses StationX wordmark; Stitch app-icon glyph kept. *(Decision, flagged for user.)*
2. **Mesocycle/Cycle/Phase/Week-of-cycle** language conflicts with the sequential-rotation model → replaced by rotation language (Day N / M).
3. **Sensor-dependent features** (GPS, HR, cadence, elevation, Polar, Apple Watch, voice pacer, barbell velocity, recovery score, strain) are not in the architecture → rendered only when data exists, otherwise explicit "not connected" state. Never fabricated.
4. **Dates in HTML (Sep 2026 / 2024 mixed)** are demo content; UI uses real dates.
5. **Demo persona "Alex Vance"**, "PRO", follower counts, "Facility A" → removed.
6. **Auth/Google/biometrics** → UI only; see Login row.
7. **Icon set:** Stitch uses Material Symbols Outlined; Flutter's built-in `Icons` is used (closest equivalents, no new font dependency). A few glyphs have no equivalent and map to nearest.
8. **Two canvas colors:** `DESIGN.md` says `#101214`, every HTML/screenshot uses `#121416` → follow screenshots.

---

## C. Component inventory (`lib/core/widgets/`)

Create (no equivalents exist today):
- [ ] `SxButton` (primary lime pill/rect, secondary, ghost, destructive; press scale 0.99 per spec)
- [ ] `SxCard` (surface-1, 1px hairline, r16), `SxInset` (surface-2 cell r8)
- [ ] `SxTextField` (label caps, icon, error/valid states)
- [ ] `SxChip` / `FilterChipRow` / `SegmentedTabs`
- [ ] `SectionHeader` (mono caps label + trailing action)
- [ ] `StatTile` (label, value, unit, icon) and `MetricValue` (mono tabular)
- [ ] `ProgressBarSegments` (exercise-step segments), `LinearMeter`, `RingProgress`
- [ ] `SxBottomNav` (4 tabs, mono caps labels, per Stitch)
- [ ] `SxAppBar` (logo, title, status pill, avatar)
- [ ] `PrBadge`, `DeltaBadge`, `StatusPill`
- [ ] `ExerciseCard` (library row), `SetRow`, `NumericKeypadSheet`
- [ ] `ProgressionRecommendationCard`
- [ ] `PlateCalculatorSheet`
- [ ] `CardioMetricTile`, `ActivityTile`
- [ ] `SxChart` family via `CustomPainter`: `LineChart`, `BarChart`, `Sparkline`, `MonthHeatmap`
- [ ] `EmptyState`, `LoadingSkeleton`, `ErrorState`, `ConfirmDialog`, `SxSnack`
- [ ] `RestTimerBar`, `ElapsedClock` (isolated `ValueListenable` rebuilds)
- [ ] `HoldToLockButton`

---

## D. Design system (extracted from `kinetic_obsidian/DESIGN.md` + HTML Tailwind configs + screenshots)

**Decision:** Obsidian palette is the source of truth (all screens). A "OLED" theme variant (true `#000000` canvas, same lime accent) is provided for the Profile › Interface Theme toggle. The cyan/purple OLED DESIGN.md palette is **not** applied (no screen uses it); recorded here as a possible future theme.

| Token | Value |
|---|---|
| canvas | `#121416` (screens) · OLED variant `#000000` |
| surface-1 (cards) | `#191C20` (HTML: surface-container-low `#1A1C1E`) |
| surface-2 (insets) | `#20252A` |
| surface-3 (sheets/dock) | `#252B31` |
| hairline | `#2A3036` |
| primary (lime) | `#B8F000`, on-primary `#101214`/`#273500`, pressed `#A2D400` |
| tertiary (positive) | `#7BF1A8` |
| error | `#FFB4AB` / container `#93000A`; destructive fill `#EF4444`-like per delete dialog |
| text high / body / muted | `#FFFFFF` / `#A6B0BA` / `#606A74` |
| fonts | Space Grotesk (headlines), Geist (body/controls), JetBrains Mono (metrics/labels), all bundled TTF variable fonts |
| type scale | display-hero 56/40m, headline-lg 32/26m, headline-md 22, headline-sm 18, body-lg 16, body-md 14, body-sm 12, metric-xl 48, metric-lg 32, metric-md 20, label-caps 11 (+0.08em), label-ui 13 |
| radius | sm 4, default 8, md 12, lg 16, xl 24, full 9999 |
| spacing | 4-pt: xs 4, sm 8, md 16, lg 24, xl 40; screen margin 16 |
| elevation | tonal stacking + 1px hairline; sheets: `0 12 32 -4 rgba(0,0,0,.7)` + 1px `rgba(255,255,255,.08)` top highlight; no other shadows |
| set checkbox | 28×28, r6, lime fill + dark check when done |
| bottom nav | 4 tabs, mono caps, active lime |
| motion | 150–250 ms ease-out; press scale 0.99; sheet slide; progress width tween |
| responsive | compact <600 single column; ≥600 centered max-width 640 content; text-scale safe (no fixed-height text containers) |

Centralised in `lib/core/theme/` (`sx_colors.dart`, `sx_typography.dart`, `sx_spacing.dart`, `sx_theme.dart`). Screens may not use raw hex values.

---

## E. Implementation phases

Order differs slightly from the template because the data layer had to be created first.

- [x] **Phase 0 — Analysis** (this document)
- [x] **Phase 1 — Foundations**: `pubspec` fonts/assets, remove stale template test, design tokens + theme, formatters
- [x] **Phase 2 — Domain + mock data**: models, services (rotation, e1RM, progression, PR, volume, smart swap, cardio metrics), repository interfaces, in-memory impls, seed data, **unit tests**
- [x] **Phase 3 — Shared components** (§C)
- [x] **Phase 4 — App shell & navigation** (routes, bottom nav, AppScope)
- [x] **Phase 5 — Entry**: Landing, Login, Register
- [x] **Phase 6 — Today**
- [x] **Phase 7 — Workouts**: hub, preview, editor, smart swap
- [x] **Phase 8 — Active workout**: logger, keypad, plate calc, complete
- [x] **Phase 9 — Exercise system**: library, details, history, PR board
- [x] **Phase 10 — Cardio**: home, select, prepare, live/paused, complete, details, edit, backdate, history, goals, goal details, custom activity, settings, empty/delete
- [x] **Phase 11 — Mixed workout** (strength + cardio finisher, complete)
- [x] **Phase 12 — Progress** (strength + cardio analytics)
- [x] **Phase 13 — History/Calendar**
- [x] **Phase 14 — Profile/Settings**
- [x] **Phase 15 — States** (empty/loading/error verification across screens)
- [~] **Phase 16 — Animation & responsive polish**
- [x] **Phase 17 — Security review**
- [x] **Phase 18 — Testing** (`flutter analyze`, unit + widget tests, build)
- [~] **Phase 19 — Final audit & cleanup**

---

## F. Acceptance criteria

Global "done" definition per screen — all must be true to tick the screen:
`UI` matches screenshot · `Nav` entry/exit/back verified · `Data` from repositories/services (no hardcoded demo values) · `Empty` · `Loading` · `Error` · `Resp` no overflow at 320×568, 360×800, 412×915, text scale 1.3 · `OLED` ok on both canvases · `Anim` · `Perf` (lists lazy, timers isolated).

Per-screen tracker (cells: UI · Nav · Data · States · Resp). Ticked only after verification.

| Screen | UI | Nav | Data | States | Resp |
|---|---|---|---|---|---|
| landing_page | [x] | [x] | [x] | [x] | [x] |
| login_page | [x] | [x] | [x] | [x] | [x] |
| register_page | [x] | [x] | [x] | [x] | [x] |
| today_home | [x] | [x] | [x] | [x] | [x] |
| workouts_hub_routines | [x] | [x] | [x] | [x] | [x] |
| workout_preview | [x] | [x] | [x] | [x] | [x] |
| workout_editor | [x] | [x] | [x] | [x] | [x] |
| swap_exercise_modal | [x] | [x] | [x] | [x] | [x] |
| active_workout_logger | [x] | [x] | [x] | [x] | [x] |
| workout_complete | [x] | [x] | [x] | [x] | [x] |
| active_mixed_workout_strength_cardio | [x] | [x] | [x] | [x] | [x] |
| workout_complete_strength_cardio | [x] | [x] | [x] | [x] | [x] |
| exercise_library | [x] | [x] | [x] | [x] | [x] |
| exercise_details | [x] | [x] | [x] | [x] | [x] |
| exercise_history_strength_analytics | [x] | [x] | [x] | [x] | [x] |
| personal_records_estimated_1rm | [x] | [x] | [x] | [x] | [x] |
| progress_dashboard_analytics | [x] | [x] | [x] | [x] | [x] |
| cardio_progress_analytics | [x] | [x] | [x] | [x] | [x] |
| cardio_home | [x] | [x] | [x] | [x] | [x] |
| select_cardio_activity | [x] | [x] | [x] | [x] | [x] |
| cardio_preparation_goal | [x] | [x] | [x] | [x] | [x] |
| active_cardio_tracker | [x] | [x] | [x] | [x] | [x] |
| active_cardio_paused_state | [x] | [x] | [x] | [x] | [x] |
| cardio_complete_summary | [x] | [x] | [x] | [x] | [x] |
| cardio_session_details | [x] | [x] | [x] | [x] | [x] |
| edit_cardio_session | [x] | [x] | [x] | [x] | [x] |
| backdate_cardio_session | [x] | [x] | [x] | [x] | [x] |
| cardio_history | [x] | [x] | [x] | [x] | [x] |
| cardio_goals_targets | [x] | [x] | [x] | [x] | [x] |
| cardio_goal_details_insights | [x] | [x] | [x] | [x] | [x] |
| create_custom_cardio_activity | [x] | [x] | [x] | [x] | [x] |
| cardio_settings_sensors | [x] | [x] | [x] | [x] | [x] |
| cardio_empty_states_confirmation | [x] | [x] | [x] | [x] | [x] |
| calendar_workout_history | [x] | [x] | [x] | [x] | [x] |
| calendar_activity_history_cardio_strength | [x] | [x] | [x] | [x] | [x] |
| profile_app_settings | [x] | [x] | [x] | [x] | [x] |

Additional global criteria:
- [x] `flutter analyze` clean (no suppressed warnings) — "No issues found"
- [x] `flutter test` green — see §J for counts
- [x] `flutter build apk --debug` succeeds (verified)
- [x] Rotation unit tests: skip day → no advance; complete → advance once; wrap-around
- [x] Backdating unit test: `workoutDate` ≠ `createdAt`
- [x] No network access in app code; fonts bundled
- [x] No git commit/push created

---

## G. Security review

Performed on the pre-existing code (Phase 17 repeats it on the final tree).

| Item | Finding | Severity | Status |
|---|---|---|---|
| Hardcoded secrets/keys/tokens | None found in `lib/`, `android/`, `ios/`, config files | — | OK |
| Network config / cleartext | No network code; Android manifest has no `INTERNET`/custom permissions (debug/profile manifests carry the Flutter default `INTERNET` for tooling only) | Info | OK |
| Logging | No `print`/`debugPrint` of data | — | OK |
| Local storage | None exists | — | n/a |
| Auth | None existed; the Stitch login/register screens would imply auth. **Risk:** shipping a UI that appears to authenticate/encrypt but doesn't. Mitigation: local-profile-only flow, no password persistence, security claims removed from copy. | Medium (product-honesty) | Mitigated: login/register are local-only, password lives in a TextEditingController and is cleared, never stored/logged |
| Android `applicationId` | was `com.example.stationx` | Low | Fixed 2026-10-08 → `dev.mahdi_ramadhan.stationx` (§T) |
| Fonts | Bundled OFL fonts, licences copied into `assets/fonts/` | — | OK |

---

## H. Known limitations / missing implementations (kept current)

- ~~No persistence~~ — **done, see §L.** Remaining persistence work: schema migrations (none needed yet), at-rest encryption, backup/export to file.
- Provisional domain services (rotation, Epley 1RM, double-progression, PR, volume, Smart Swap) — to be reconciled with the real engine when it exists.
- Health Connect (sleep + resting heart rate, read-only, opt-in) is implemented for Android (§O). iOS Apple Health is implemented but **untested** (§P). Still not implemented: GPS / live HR / cadence / elevation / direct cloud APIs for Garmin/Fitbit/Whoop/Oura/Polar.
- Auth: the local profile is still local-only; an optional separate Supabase cloud account provides backup/sync (§U).
- ~~App launcher icon not regenerated~~ — done (§M).
- Share/export actions limited (no share/file packages added).
- Custom cardio activity interval-engine (rounds) fields are not part of the persisted cardio model.

- Only one cardio block per strength session (`WorkoutSession.cardio` is singular); "add another cardio" not offered.
- Treadmill distance in mixed workouts is estimated speed × time when not typed (labelled "EST.").
- Cardio live tracker uses manual distance entry; no GPS/HR/cadence/elevation/voice pacer/weather/Polar/Apple Watch.
- Plate calculator is metric (lb users see kg plates with a note).
- Share actions omitted (no share package). Export = JSON/CSV text sheet with clipboard copy.
- Register's "Initial Split" card is informational (`startFresh` has no split argument).
- Saved-routines tab is an honest empty state (no bookmark concept in the model).
- Goals count every cardio session in the period regardless of kind.
- Custom cardio interval template is stored on `CustomCardioActivity` only, not on logged sessions.
- `android/gradle.properties` was modified by the Flutter tool migrator during `flutter build apk` (adds `android.builtInKotlin=false`/`newDsl`); review before committing. `analysis_options.yaml` / `pubspec.lock` changes pre-date this work or are tool-generated.
- Smart Swap match scores differ from Stitch's static numbers because they are computed (§B).
- Not verified on a physical device / emulator: frame timing, real keyboard behaviour, system navigation insets (verified only in widget tests + rendered PNGs).
- Candidate refactor: `active_workout/session_analysis.dart` (PR / progression-vs-previous) could move into `domain/services`.

## I. Change log
_(updated as work lands)_
- 2026-10-07 — Analysis complete, roadmap created.
- 2026-10-07 — Foundation: fonts bundled (Space Grotesk, Geist, JetBrains Mono, OFL), design tokens/theme, shared widgets, pure-Dart domain (models, rotation, Epley 1RM, double-progression, PR, volume, Smart Swap, plate calc, cardio metrics), repository interfaces + in-memory implementations + mock seed, app shell/`AppNav`.
- 2026-10-07 — All 35 Stitch screens implemented by feature (entry/Today/Profile; Workouts hub/preview/editor/swap; Active workout + complete + mixed; Exercises/Progress/PRs/Calendar; Cardio live flow; Cardio management). Old `lib/landing`, `lib/home` removed (unreferenced). Stale counter test replaced.
- 2026-10-07 — Fixed shared-widget issues found by feature work: `SxBrandBar` overflow at narrow width/large text, `SxBottomCta` caption layout, lint infos.

## L. Isar persistence (added 2026-10-07)
**Package decision:** `isar_community` 3.3.2 (+ `isar_community_flutter_libs`, `isar_community_generator`, `path_provider`, dev `build_runner`) instead of the original `isar` 3.1.0, which was last published in 2023 and whose generator cannot resolve against the current analyzer. `isar_community` is the maintained, API-compatible fork. If the project later targets Isar 4, only `lib/data/isar/` changes.

**Architecture**
- `lib/data/isar/entities.dart` (+ generated `entities.g.dart`, excluded from analysis): `@collection` entities mirroring the domain models — Exercise, Workout, Rotation (singleton), Session, CardioSession, CardioGoal, CustomActivity, Profile (singleton), AppMeta (singleton: `signedIn`, `schemaVersion`). Nested data uses `@embedded` (sets, exercise logs, routine exercises, cardio target, meta). Every entity keeps `createdAt/updatedAt/syncStatus`; sessions index `workoutDate` and keep it separate from `meta.createdAt`.
- `lib/data/isar/mappers.dart`: the only place that knows both shapes. The rest of the app never imports Isar.
- `lib/data/isar/isar_store.dart`: `IsarStore` implements the new `DataStore` abstraction (`lib/data/data_store.dart`). Each Isar repository = the in-memory repository (synchronous read cache) + **write-through**: Isar is written first, the cache/listeners update only after the write succeeds. Everything is loaded once at `open`, so UI getters stay synchronous and no query runs per frame.
- First launch seeds the exercise catalogue + default 3-day rotation (no history). Re-opening never re-seeds.
- `main()` opens the store in the app documents directory; `StationXApp` routes returning (signed-in) users straight to the shell.

**Behaviour decisions (flag for review)**
- **Guest is now an empty local profile**, not demo data (persisting fake history would pollute real use). Sample data is an explicit, confirmed action: Profile › "Load demo data".
- **Sign-out keeps local data.** "Continue as Guest" never overwrites existing data. Registering as a guest attaches the guest's data to the account.
- **There is still no server**: sign-in only restores the single local account by email (case-insensitive) and cannot verify a password; it says so when there is no local account. A second, different account on the same device is refused with a clear message. Passwords are never stored.
- "Delete all local data" keeps the profile and restores the default catalogue + rotation.
- Rotation index is persisted only through rotation writes (completion/"change next"/workout delete); unrelated writes never move it (tested).

**Tests:** `test/data/isar_store_test.dart` (9: seeding, nested session round-trip, workoutDate≠createdAt, rotation persistence/wrap, completion service, workout edits+order, cardio/goals/custom activities incl. update/delete, profile/settings/signedIn/custom exercise, demo replace + wipe, listener timing) and `test/data/app_controller_isar_test.dart` (4: guest/restart, register keeps data, account rules, demo+wipe). Each writes, **closes, reopens** the database, then asserts. These tests call `Isar.initializeIsarCore(download: true)`, which downloads the native core into the project root as `libisar.so` (gitignored; test-only — the app uses the binaries bundled by `isar_community_flutter_libs`).

**Verified:** `flutter analyze` clean; full suite passes; `flutter build apk --debug` bundles `libisar.so` for arm64-v8a/armeabi-v7a/x86_64; `flutter build linux --debug` launched and created its database with no errors (debug builds print the Isar Inspector banner — debug only).

**Known limits / future:** no at-rest encryption (Isar 3 has none; use OS full-disk/app sandbox or add SQLCipher-style layer later); schema changes beyond additive ones need a migration keyed on `AppMetaEntity.schemaVersion` (none yet); not exercised on a physical Android/iOS device here (only Linux desktop + Android build).

- 2026-10-08 — **Cloud sync client** (§U): engine, Isar sync store, Supabase auth/gateway, UI, privacy rewrite, INTERNET permission, 100+ new tests incl. real-database end-to-end.
- 2026-10-08 — App id `dev.mahdi_ramadhan.stationx` applied; Supabase schema + RLS + tests applied/verified (§T).
- 2026-10-08 — Large-history performance tests (§S): 4-year dataset timings, Isar load/write timings, regression budgets.
- 2026-10-07 — Accessibility / TalkBack pass (§R): 48 dp targets, contrast token fix, semantics, large-text layout, gesture alternatives; ~125 new tests (30 screen sweeps, 30 large-text, 12 state, 4 gesture, 52 contrast).
- 2026-10-07 — Release readiness (§Q): signing guard, dark launch screen, startup-failure recovery, release error widget, real version label, privacy page + policy draft, `docs/RELEASE.md`.
- 2026-10-07 — **Apple Health (iOS)** support (untested on iOS, §P): provider-aware UI, remembered consent, entitlements, iOS 15 target.
- 2026-10-07 — **Health Connect** read-only integration (§O): domain/data/UI, Android config (minSdk 26), 21 tests.
- 2026-10-07 — Muscle-map illustrations, vector brand mark, launcher icon (§M).
- 2026-10-07 — **Isar persistence** (§L): entities, mappers, `IsarStore`, `DataStore`, async `AppController` (persisted sign-in; guest/register/sign-in rules), Profile "Load demo data", 13 persistence tests.

## M. Muscle-map illustrations, brand mark, launcher icon (added 2026-10-07)
- **`MuscleMap`** (`lib/core/widgets/muscle_map.dart`): vector front/back figure (CustomPainter, no assets, offline) highlighting primary muscles in the accent colour and secondary muscles dimmed; `auto` view picks back for back/triceps. Replaces the equipment-icon placeholders on the exercise library thumbnails, Exercise Details hero, the active-workout exercise header and the Today hero badge (all primary muscles of the day's workout). It is a simplified diagram mapped to the app's 7 `MuscleGroup`s, not anatomical art. Semantics label lists primary/secondary muscles. Tested for every group.
- **`SxLogo`** is now the real brand mark painted as vector (cyan/violet chevrons + ring), matching the Stitch header.
- **Launcher icon** generated from `design_reference/kinetic_app_icon_oled_cyan_purple` into Android (adaptive, background `#0B0C10`) and iOS via `flutter_launcher_icons` (`dart run flutter_launcher_icons`; sources in `assets/icon/`). App label fixed to "StationX" (Android + iOS).
- **Design conflict (flag):** the icon/logo use the cyan/violet "OLED" palette while all screens use the lime Obsidian palette. This mirrors Stitch (its screens show the cyan/violet mark beside lime UI), so it was kept; revisit if you want a lime-based mark.
- Not changed: Android `applicationId` is still `com.example.stationx` (release identity/signing is an owner decision).

## N. Final audit notes (2026-10-07)
- **Design tokens:** raw colours removed from feature code; added `SxColors.onAccent` (text/icon on the lime fill). Only intentional literals remain: the brand-mark painter, the danger-button foreground, and the system navigation-bar colour in `main.dart` (fixed to Obsidian; does not follow the OLED toggle — minor).
- **Duplicates removed:** `equipmentIcon` existed twice → single `core/utils/equipment_icons.dart`. No unreferenced Dart files found.
- **Performance (by inspection; not profiled on a device):** all 1-second timers live in small isolated widgets and are cancelled in `dispose`; screens read data through synchronous repository caches (no per-frame queries); charts and the muscle map are wrapped in `RepaintBoundary`; long lists use lazy builders; the few `shrinkWrap` lists are small (sheets/chip rows).
- **README** rewritten (architecture, commands, rules).
- **Health Connect:** approved by the owner and implemented — see §O.

## O. Health Connect (added 2026-10-07, owner-approved)
**Scope:** optional, opt-in, **read-only**: last night's sleep and resting heart rate (+ 7-day average). Nothing is written to Health Connect, nothing is uploaded, no network. Android only; iOS/desktop use `NoopHealthRepository` (status `unsupported`, UI hidden).

**Design**
- Domain: `HealthStatus` (unsupported / notInstalled / notConnected / connected), `HealthSnapshot`, `HealthRepository` interface, pure `HealthSummary` (merges overlapping sleep intervals from several sources, picks stage data over session data, filters impossible HR values, last-night window 18:00→14:00).
- Data: `HealthGateway` (thin boundary), `PluginHealthGateway` (the `health` package 13.x; swallows errors, logs only the exception type, never data), `HealthConnectRepository` (state machine, 5-minute refresh throttle, failures keep the previous snapshot), `NoopHealthRepository`.
- `AppController.health`; `main()` builds the real repository only on Android and calls `init()` without blocking startup; `StationXApp` refreshes on app resume.
- UI: Today recovery card (hidden when unsupported; Connect / Install / "Reading…" / empty / values with delta vs 7-day average; **no invented recovery score**); Profile › Health Connect row (Connect / Disconnect / Install). Connecting first shows an explanation (what is read, read-only, stays on device), and only after confirmation asks the system for permission. Disconnect clears the cache and revokes (Android may need an app restart for the revoke to fully apply).
- Android: `minSdk` raised **24→26** (device reach: Android 8.0+), `MainActivity` → `FlutterFragmentActivity`, manifest: `READ_SLEEP`, `READ_RESTING_HEART_RATE`, `<queries>` for Health Connect, `ACTION_SHOW_PERMISSIONS_RATIONALE` intent filter and `ViewPermissionUsageActivity` alias (Android 14 privacy link; both open the app).

**Verified:** 12 unit tests (`test/data/health_test.dart`: interval merging, source fallback, HR outliers, every status transition, throttle, failure handling, disconnect) and 9 UI tests (`test/features/health/`: hidden on unsupported, explanation before permission, cancel never requests, denied, data, empty, not-installed, Profile connect/disconnect, 320×568 @1.3×). Merged debug manifest contains only the two health permissions (+ Flutter's debug-only `INTERNET`).

**NOT verified (needs a physical Android device with Health Connect):** the real permission dialog, real data reads, Android 14 behaviour, the revoke-then-restart flow. `PluginHealthGateway` is the only untested layer and is deliberately minimal. **Before a Play Store release** you must complete the Play Console Health Connect permissions declaration and provide a privacy policy URL (the app currently links to itself for the rationale). iOS HealthKit is not implemented (the `health` plugin is linked on iOS but never invoked; confirm App Store review expectations before shipping iOS).

## P. Apple Health (iOS) and other wearables (added 2026-10-07) — UNTESTED ON iOS
**Status:** code + project configuration written and unit-tested at the logic level, but **never compiled or run on a Mac/Xcode or an iPhone** (development machine is Linux). Treat as untested until built and exercised on a device.

**What was added**
- Same `HealthRepository`/UI as Android; `HealthProvider` (Health Connect / Apple Health) drives wording ("Connect Apple Health?", Settings path instead of "restart the app").
- `PluginHealthGateway` iOS path (`health` plugin → HealthKit): types `SLEEP_ASLEEP` + `SLEEP_IN_BED` (fallback; iOS has no sleep-session type) + `RESTING_HEART_RATE`, read-only.
- **HealthKit hides whether READ access was granted.** So on iOS the app never queries permission state: `HealthConsentStore` (persisted in Isar `AppMetaEntity.healthConnected`, additive field) remembers the opt-in; `connected` therefore means "user opted in", and "no data" can mean denied *or* nothing recorded — the card says so and shows `Settings › Health › Data Access & Devices › StationX`. iOS cannot revoke programmatically, so Disconnect clears the cache + consent and points the user to Settings.
- Android keeps the real OS permission as the source of truth (consent flag mirrors it).
- iOS project: `NSHealthShareUsageDescription` in `Info.plist` (no update/write string — read-only), new `ios/Runner/Runner.entitlements` (`com.apple.developer.healthkit`) wired into the three Runner build configurations in `project.pbxproj`, deployment target raised **13.0 → 15.0** (plugin requirement).
- Tests: 8 new logic tests (remembered consent, never queries OS permission on iOS, restart reconnects, empty-but-connected, disconnect forgets, Android consent mirrors OS) + 3 UI wording tests + Isar consent persistence.

**To do before shipping iOS (needs a Mac):** `flutter build ios`; in Xcode confirm the HealthKit capability appears under Signing & Capabilities and a team/provisioning profile with HealthKit is selected; run on a real iPhone (simulator has no real Health data) and verify the permission sheet, reads, and the denied/empty path; App Store privacy/Health usage review. The hand-edited `project.pbxproj` entries (file reference `A1B2C3D4E5F60718293A4B5C`, `CODE_SIGN_ENTITLEMENTS`) should be opened once in Xcode to confirm they load cleanly.

**Samsung Health:** no direct integration needed — it syncs sleep/heart rate into Health Connect (One UI 5+/Android 14+; user enables sharing in Samsung Health settings). The Samsung Health Data SDK requires partner approval and has no maintained Flutter package.
**Garmin / Fitbit / Whoop / Oura / Polar:** these normally sync into Health Connect / Apple Health, so they already work through the two integrations. Direct cloud APIs (OAuth) would need network + accounts, conflicting with local-first; not planned. Live Bluetooth heart-rate straps and GPS belong to the cardio-tracker feature, not this integration.

## Q. Release readiness (added 2026-10-07) — see `docs/RELEASE.md`
**Done in the repo**
- **Android signing:** `build.gradle.kts` reads gitignored `android/key.properties`; without it APK builds fall back to debug signing (testing only) and **`flutter build appbundle --release` is refused** (verified: build fails with a clear message). Keystore/`key.properties` are already gitignored.
- **No white launch flash:** Android launch background/theme and iOS launch screen use the app canvas colour.
- **Crash resilience:** `bootstrap()` installs global error handling (release: friendly error widget instead of the red screen; only exception *types* are logged, never data) and a **startup-failure recovery screen** (retry, or confirmed reset of the database files) instead of crashing if Isar can't open. Tested, including that reset deletes only this app's DB files.
- **Real version label** in Profile (package info) instead of a hardcoded string. (`package_info_plus` 10.x; 8.x conflicted with `health`.)
- **Privacy:** in-app Privacy page (Profile › Privacy) + `docs/PRIVACY_POLICY.md` draft (placeholders for contact email/date).
- **Docs:** `docs/RELEASE.md` — decisions needed, signing steps, Play Console checklist (data-safety answers, Health Connect declaration text, listing text), App Store checklist, device verification checklist.
- **Store assets** generated in `docs/store/` (512 icon, 1024×500 feature graphic, 6 phone screenshots 1080×2160). Rendering them at 360 dp exposed and fixed two narrow-phone bugs: the brand header truncated "StationX" (text/spacer flex contention; pill now only ≥400 dp) and the Active Workout title truncated (logo/avatar hidden <400 dp).
- Verified: release APK builds (61.5 MB, 3 ABIs); release merged manifest has no `INTERNET`; 188 tests pass, analyzer clean.

**Blocked / owner actions (not done)**
- ~~`applicationId` still the template id~~ — set 2026-10-08 (§T).
- Create upload keystore + `key.properties`; developer accounts; hosted privacy-policy URL; store listing assets (screenshots, 512 icon, feature graphic).
- **Never verified at runtime:** the *release* build (R8 minification can break plugins — test Isar + Health Connect in release on a real phone), Health Connect/HealthKit on devices, performance profiling, TalkBack pass.
- iOS build has never been run.

## R. Accessibility / TalkBack pass (added 2026-10-07) — code-level; NOT yet verified with a real screen reader
**Automated coverage (all green):** `test/a11y/`
- *Guideline sweep* over all 30 screens at 360×720: Android 48 dp tap targets, labelled tap targets, and text contrast (≥13 dp text; see note).
- *Token contrast* (`token_contrast_test.dart`, 52 checks): every text/icon colour token ≥ WCAG AA 4.5:1 on all four surface tiers, both palettes. The pixel-based checker under-reports 10–12 dp glyphs (antialiasing), so contrast is proven from the tokens instead.
- *Large text*: every screen lays out without overflow at 2.0× font scale on a 360×640 phone.
- *Interactive states* at 1.0 / 1.3 / 2.0×: running rest timer, numeric keypad, swap sheet, confirmation dialog — tap targets, labels, overflow.
- *Gesture alternatives*: swipe-to-remove a set → "Remove set" action; long-press delete of a cardio session → "Delete session" action; hold-to-unlock → single activation when a screen reader is on.

**Fixes made**
- `textMuted` lightened `#606A74 → #8B959F` (was 3.3:1; now ≥4.7:1 on every surface). *Deviation from Stitch, deliberate.*
- All buttons/chips/segments/steppers/avatars/set-row inputs/KM-MI toggle/pickers have ≥48 dp hit areas (visuals unchanged where possible; calendar grid uses an 8 dp page margin so 7 day-cells reach 48 dp on 360 dp phones). `SxButton` enforces a 48 dp minimum height globally.
- Duplicate announcements removed (`excludeSemantics` on labelled controls; logo decorative next to the wordmark; progression card read once). Controls are their own semantic nodes (`container: true`) so cards no longer swallow their buttons; stat tiles read as "Done: 1 ses".
- Semantics added: screen/section titles are headings; charts (`line`/`bar`) announce a data summary; meters/rings/segment strips announce progress; muscle map announces primary/secondary muscles; set rows read "Set 1 … Previous 45 kilograms, 11 reps"; set checkbox is a checkbox; column headings are not read; profile avatar is "Profile, <name>".
- Rest timer: end of rest announced once via a live region (Android has deprecated announcement events); countdown is read on focus only; Skip / +30 s are 48 dp "Skip rest" / "Add 30 seconds".
- Fixed-height bars (top bar, bottom nav) cap text scaling at 1.3× like Material; confirm dialogs scroll; several rows made flexible so 2× text never overflows.
- Reduced motion: meter/ring/bar/segment animations and the rest-tile resize honour the system "remove animations" setting.

**Not done / needs a human with TalkBack (see `docs/RELEASE.md` §5):** real-device TalkBack walkthrough of the main flows (log a workout, cardio, calendar), focus-order sanity on every screen, Switch Access, and Android's Accessibility Scanner. Known judgement calls: fixed 1.3× cap on bar labels; the cardio hold-to-lock still needs a hold for sighted users; `ses` is read literally on the Today stat tile.

## S. Performance with a large history (added 2026-10-08) — `test/perf/`
Synthetic heavy-use dataset: **4 years, 832 strength sessions (~15k sets) + 624 cardio sessions** (4 strength + 3 cardio per week). Measured in the Flutter test VM (debug/JIT, headless — several times slower than a release build on a phone), so treat numbers as an upper bound / regression guard, not device frame times.

| Case | Time |
|---|---|
| First build: Today / Workouts hub / Progress / Exercise history / Personal records / Calendar | 85–125 ms (Today ~540 ms incl. VM warm-up; 100 ms warm) |
| First build: Exercise library (38 exercises, PR badge each) | ~205–230 ms |
| Library: each search keystroke (full list rebuild) | 29–125 ms (first keystroke warms up) |
| Progress → "All time" period; Calendar month change | ~85–90 ms |
| Isar: bulk write 1,456 sessions / cold open + load all into memory | 61 ms / 55 ms |
| Isar: add one session with the big history loaded | 6 ms |

Conclusions: screens compute their stats synchronously from the in-memory cache and stay well inside a 16 ms-frame budget *per rebuild on a release build is expected but unverified*; startup loading everything is cheap at this scale (≈ linear; ~100k+ sessions would need paging/lazy loading — not a realistic personal-use size). Micro-optimisation made: `PrService.forExercise` now filters to relevant sessions before sorting. Regression budgets are asserted in the tests (first build < 2.5 s, Isar cold load < 5 s, single add < 0.5 s — deliberately loose to avoid flaky CI).
**Still needs a device:** real frame timing with `flutter run --profile` + DevTools (active-workout page with the 1-second tickers, scrolling the calendar/history lists, chart repaint), memory over a long session, and low-end Android.

## T. App id + Supabase database (added 2026-10-08)
**Application id:** Android `applicationId`/`namespace`/Kotlin package → `dev.mahdi_ramadhan.stationx` (MainActivity moved to `kotlin/dev/mahdi_ramadhan/stationx/`). iOS/macOS bundle ids → `dev.mahdi-ramadhan.stationx` (+ `.RunnerTests`) because **iOS bundle identifiers cannot contain underscores**; Linux app id `dev.mahdi_ramadhan.stationx`; copyright/company strings updated. Debug APK builds with the new id. iOS/macOS builds not run (no Xcode).

**Supabase (project `StationX`, ref `fyigpfuddgegvkibnvgd`)** — see `supabase/README.md`.
- Verified the project was empty (0 tables, 0 users) before applying `supabase/migrations/20261008000000_initial_schema.sql`: 8 per-user tables mirroring the domain models (profiles, exercises[custom], workouts, rotations, workout_sessions, cardio_sessions, cardio_goals, custom_cardio_activities), sync columns (`created_at`, `updated_at`, `server_updated_at`, `deleted_at`), `workout_date` separate from `created_at`, enum/range/jsonb check constraints, indexes for incremental pulls and by-date queries, RLS on every table (owner-only), `anon` revoked, last-write-wins trigger, signup→profile trigger, `delete_account()` RPC.
- Verified with `supabase/tests/rls_and_sync_test.sql` (self-rolling-back): **21/21 PASS** — signup trigger, backdating, spoofing blocked, stale-write ignored, constraints, user isolation (read/update/delete), anon denied, account deletion cascade. No test data left behind.
- Supabase advisors: 1 *intentional* security warning (`delete_account` callable by signed-in users — it only deletes `auth.uid()`), performance notes are "unused index" on an empty DB.
- **Not done:** the Flutter app does **not** talk to Supabase (no client, no auth flow, no sync service, still no `INTERNET` permission). Turning sync on requires the client work plus privacy-policy / data-safety / privacy-label updates (checklist in `supabase/README.md`). Auth settings left unchanged (recommended: set Site URL, raise min password length from 6).
- **Security incident to handle:** a Supabase *personal access token* (account-wide) was pasted into the chat. It was used only for the calls above and was **not written to any file**. **Revoke it** (Supabase dashboard → Account → Access Tokens) and create a new one only when needed.

## U. Cloud sync client (added 2026-10-08) — optional, off by default
The app can now back up and sync to the Supabase database from §T. **It is inert unless the build has a Supabase URL + publishable key (`--dart-define-from-file=env/supabase.json`) *and* the user signs in.** Without either, the app makes no network requests.

**Architecture** (`lib/data/sync/`, `lib/data/isar/isar_sync_store.dart`, `lib/features/cloud/`)
- `SupabaseConfig` (refuses `sbp_`/`sb_secret_`/`service_role` credentials) · `CloudAuth` (+Supabase impl, friendly error mapping, delete-account RPC) · `SyncGateway` (+Supabase impl) · `SyncLocalStore` (+Isar impl: dirty rows, outbox of deletions, last-write-wins apply, state/cursors) · `SyncEngine` (push → tombstones → pull, idempotent, failure-tolerant) · `CloudSyncController` (status, debounce, resume throttle, retry, single-flight, account-switch decision) · row mappers (`sync_rows.dart`).
- Isar schema additions (additive): `SyncStateEntity`, `SyncDeletionEntity` (tombstone outbox), `updatedAt`/`syncStatus` on profile & rotation. Seed/default/demo rows are "clean" (epoch `updatedAt`, synced) so they never upload and always lose to real cloud data.
- UI: Profile › *Cloud backup & sync* card (status, Sync now, Sign out, Delete cloud account & data); `CloudAuthPage` (sign in / create account / e-mail-confirmation step / account-switch sheet); "Restore from cloud backup" on the welcome screen (hidden when not configured). Wipe-device dialog explains it also unlinks sync. Privacy page + policy rewritten.
- Android manifest: **`INTERNET` permission added** (the release build previously had none).

**Verified**
- 7 mapper tests, 22 engine tests (two Isar "phones" + a fake server with the same LWW rules: push/pull, backdating preserved, edit/delete propagation, conflicts both orders, stale writes, resurrect-after-delete, defaults vs. edited routines, first-link profile rules, account switch merge/replace, mid-push network failure + retry, edit during in-flight push, pagination, regression for UTC-vs-local `DateTime` equality), 14 controller tests, 18 cloud UI tests, 4 config-guard tests.
- **End-to-end against the real Supabase project** (opt-in `test/e2e`): real GoTrue sign-in (wrong/right password), two phones converge through the real database (rows verified via SQL: user_id, workout_date ≠ created_at, nested cardio, tombstones), idempotent re-sync, stale-edit rejection, RLS (another user reads nothing, spoofing blocked, cannot update/delete others' rows, anonymous denied), account deletion cascades to every table. The run **caught a real bug** (singleton rows re-"pulled" every sync due to `DateTime ==` comparing the UTC flag) which is fixed and has a regression test. Test users are deleted afterwards; the DB was verified empty.
- Full suite 393 passing, analyzer clean, debug APK builds with the cloud config.

**Not done / owner decisions** (also in `supabase/README.md`, `docs/RELEASE.md` §5b): password reset flow (needs a hosted page); Supabase Site URL / min password length / SMTP; Play account-deletion URL; Data-safety form & App Store privacy label updates; field-level conflict merge (currently newest-row-wins); real-phone testing of sign-in/sync UX, flaky networks, token refresh over long idle periods, iOS (unbuilt). The Supabase access token pasted in chat should be **revoked**.

## V. Import from Gym Tracker (added 2026-10-08)
- **gym_tracker** (separate repo, uncommitted changes): Settings › Data › *Export Data* writes a versioned `gym_tracker_export` v1 JSON (all completed/unfinished sessions with sets in kg, exercises, templates, PRs, settings) via the system "Save as" dialog, with a "Copy instead" fallback; spec in its `docs/EXPORT_FORMAT.md`; 12 new tests.
- **StationX**: `lib/data/import/gym_tracker_import.dart` (pure plan → apply), `exercise_aliases.dart`, `import_file_source.dart` (file_picker, fakeable), UI `lib/features/profile/gym_tracker_import_flow.dart` (source sheet → preview with counts/new exercises/optional "continue where Gym Tracker left off" → result).
- **Rules**: only completed workouts; `workoutDate` = start time, `createdAt` = now; ids `gt_s<id>` make re-imports idempotent; nothing existing is modified; rotation changes only if ticked; PRs/1RM recomputed by the domain layer; achievements ignored; weights are kg both sides (no conversion); malformed entries skipped individually; 50 MB cap; hostile names sanitised into ids; one batched Isar write (single notify).
- **Tests**: 20 importer tests against a fixture produced by the REAL exporter (incl. Isar restart persistence) + 10 UI-flow tests.
- **Not verified**: on a real phone (file picker / SAF), and with the user's real Gym Tracker data (the desktop DB was nearly empty).

## J. Verification record (2026-10-07)
- `flutter analyze`: No issues found.
- `flutter test`: all pass (domain 11 + feature widget tests across entry, workouts, active workout, exercises, progress, history, cardio live, cardio manage; includes 320×568 @1.3× overflow checks and empty-account states).
- `flutter build apk --debug`: success.
- Visual comparison: each feature agent rendered PNGs via `test/helpers/pump.dart` and compared them with `design_reference/*/screen.png`; strength logger, Today, hub, library etc. match closely. Deviations are listed per screen in §B and below.
- Security scan: no secrets, no network code, no logging; passwords never persisted.

## K. Final report
**Completed:** design system, domain + mock data layer, 35 screens, tests. **Changed:** brand KINETIC→StationX; Stitch's sensor/mesocycle/social copy replaced by honest states. **Fixed:** shared widget overflow issues. **Security:** none found; auth is local-only by design. **Remaining:** Health Connect, sensors/GPS, launcher icon, device profiling, share/export files. **Git:** NO COMMIT WAS CREATED (user-level Claude settings now also deny `git commit`/`git push`).
