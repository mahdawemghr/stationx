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

* "Connect to real data" in this roadmap means "connect to the repository interfaces". Persistence across app restart is **not** available until an Isar-backed repository exists (§H, Known limitations).
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
* **Database:** none. In-memory repositories only (see §0).

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
| edit_cardio_session | [x] | [x] | [x] | [x] | [~] |
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
| Android `applicationId` | `com.example.stationx` is template default | Low | Documented, not changed (release-signing decision for owners) |
| Fonts | Bundled OFL fonts, licences copied into `assets/fonts/` | — | OK |

---

## H. Known limitations / missing implementations (kept current)

- No persistence (mock in-memory repos) — **Isar implementation outstanding**; interfaces in `lib/domain/repositories/`.
- Provisional domain services (rotation, Epley 1RM, double-progression, PR, volume, Smart Swap) — to be reconciled with the real engine when it exists.
- Health Connect / wearables / GPS / HR / cadence: not implemented; UI shows explicit not-connected states.
- Auth is local-profile only; no real accounts/sync.
- App launcher icon not regenerated from `kinetic_app_icon…`.
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
- Edit-cardio bottom bar is tall at 320×568 @1.3× text and its delete label truncates (status [~]).
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

## J. Verification record (2026-10-07)
- `flutter analyze`: No issues found.
- `flutter test`: all pass (domain 11 + feature widget tests across entry, workouts, active workout, exercises, progress, history, cardio live, cardio manage; includes 320×568 @1.3× overflow checks and empty-account states).
- `flutter build apk --debug`: success.
- Visual comparison: each feature agent rendered PNGs via `test/helpers/pump.dart` and compared them with `design_reference/*/screen.png`; strength logger, Today, hub, library etc. match closely. Deviations are listed per screen in §B and below.
- Security scan: no secrets, no network code, no logging; passwords never persisted.

## K. Final report
**Completed:** design system, domain + mock data layer, 35 screens, tests. **Changed:** brand KINETIC→StationX; Stitch's sensor/mesocycle/social copy replaced by honest states. **Fixed:** shared widget overflow issues. **Security:** none found; auth is local-only by design. **Remaining:** Isar persistence, Health Connect, sensors/GPS, launcher icon, device profiling, share/export files. **Git:** NO COMMIT WAS CREATED (user-level Claude settings now also deny `git commit`/`git push`).
