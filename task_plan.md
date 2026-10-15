# Task Plan: Smartwatch connection audit and performance pass

## Goal
Verify the watch -> Health Connect / Apple Health -> StationX path works correctly and performs well. Fix real defects found. Leave all changes uncommitted (global rule).

## Context
- No direct BLE/watch code exists by design. Path: watch app -> Health Connect (Android) / HealthKit (iOS) -> `health` plugin 13.3.2 -> `PluginHealthGateway` -> `HealthSyncService` -> UI (`watch_setup_page`, `health_sync_settings_page`, import, enrichment, HR widgets).
- Baseline (2026-10-14): `flutter analyze` on health code clean; 99 health tests pass.
- Environment limits: no `adb`, no attached phone, only Linux desktop device. Real-watch behaviour CANNOT be verified here. `PluginHealthGateway` is untested by design (needs device); iOS never compiled.
- Unrelated dirty files (do not touch): `lib/features/workouts/workout_editor_page.dart`, `test/features/workouts/workouts_test.dart`.

## Phases

### Phase 1: Baseline and mapping
- [x] Locate all health/watch code, run analyze + health tests
- **Status:** complete

### Phase 2: Static audit (correctness of the connection path) - DONE (one item deferred)
- [x] Manifest vs `_featureTypes` permission parity (now includes READ_SLEEP / READ_RESTING_HEART_RATE for the recovery switch)
- [ ] DEFERRED: `diagnose()` "read failed" vs "empty". The health plugin's native code swallows every read error and returns an empty list, so the app cannot tell them apart without a plugin change; the check now explains the real causes instead (heart-rate state, "no workouts from your watch")
- [x] iOS path read through (hasPermissions is always false there; diagnose/refresh only rely on it on Android). Not compiled or run: no Mac
- [x] App lifecycle: auto-import runs on start and on resume (main_shell.dart)
- [x] Source filtering: `ownSourceIds` matches applicationId; own records excluded from import and heart rate (tested)
- [x] Duplicate import protection: deterministic ids, importedIds, own-record ids (tested)
- **Status:** complete

### Phase 3: Performance audit - DONE
- [x] `heartRateTrend`: kept one read per day on purpose (Health Connect rate-limits reads); ADDED a per-day cache (finished days 30 min, today always fresh): reopening reads 1 day instead of 7-30, switching 7/14/30 reuses days (tests)
- [x] `latestHeartRate`: reviewed, single-flight 15 s poll, no change needed
- [x] `readMetrics`: split into separate reads so one denied type does not lose the others
- [x] `_attachHeartRates`: reviewed, runs in the background after an import, bounded by the import size
- [x] `autoImport`: reviewed, 6 h throttle, silent on failure
- [x] Recovery: report cached 5 min (today) / 30 min (past days), months cached, at most 8 sequential reads only when resting HR must be estimated
- **Status:** complete

### Phase 4: Fixes - DONE
- [x] Heart rate off / no samples now reported by the connection check, with a "Turn on heart rate" button (tests)
- [x] Heart rate no longer needs the calories permission (gateway)
- [x] "No workouts from your watch yet" explanation; import page lists skipped types and explains Samsung's no-backfill
- [x] Recovery restored, verdict + details, resting HR estimate, calendar sleep (Phases 6 and 8)
- **Status:** complete

### Phase 5: Verification - DONE (real-device part with the user)
- [x] `flutter analyze` clean; full `flutter test` passes (see progress.md for the latest count)
- [x] `docs/RELEASE.md` device checklist updated (watch heart rate, recovery permissions)
- [x] Manual checklist handed to the user; the user confirmed on a Galaxy: heart rate, cardio write-back, sleep and recovery work
- [ ] STILL OPEN (needs hardware): iOS build, minified release build, Garmin / Fitbit
- **Status:** complete

### Phase 6: Restore sleep + recovery (user decision 2026-10-15: "Bring them back")
- [x] Study old impl: `git show b974fa9:lib/domain/services/health_summary.dart`, health_connect_repository.dart, today_page.dart `_RecoveryCard`
- [x] Domain: `HealthFeature.recovery`, snapshot model + pure `HealthSummary` (sleep minutes merge, resting HR latest/7d avg) with tests first
- [x] Gateway: sleepAsleep / sleepSessions / restingHeartRate (plugin + inert + fakes), Android types SLEEP_ASLEEP+SLEEP_SESSION+RESTING_HEART_RATE, iOS SLEEP_IN_BED
- [x] Service: `recoverySnapshot()` gated by feature + permissions; own opt-in switch + explanation in settings page
- [x] UI: Today recovery card (hidden when switch off), settings switch, watch check mentions it
- [x] Manifest: READ_SLEEP, READ_RESTING_HEART_RATE
- [x] Docs reversal: PRIVACY_POLICY.md, docs/web/privacy.html, privacy_page.dart, play_console_answers.md, RELEASE.md (line 122 says verify NO sleep perms), README, FUNCTIONAL_REQUIREMENTS FR-HLT-01, PROJECT_DETAILS, memory file
- **Status:** complete (code + tests + docs; real-device check pending)

### Phase 7: Watch workouts missing (done part)
- [x] Connection check explains "no workouts from your watch" (Samsung Health shares only new workouts after Exercise sharing is on); import page names skipped types
- **Status:** complete

### Phase 8: Resting HR fallback + readiness verdict + sleep details (user request 2026-10-15)
Research: Samsung does not backfill Health Connect; HC readRecords silently drops data older than 30d before first grant; no evidence Samsung writes RestingHeartRateRecord; readiness = sleep duration/quality vs target + resting HR vs personal baseline (+ sleep debt). Samsung writes sleep STAGES (light/deep/REM/awake), current code only reads generic ASLEEP + session.
- [x] Domain models: SleepStage, SleepNight, NightSummary, RecoveryVerdict, SleepQuality, RecoveryReport, RecoveryReason
- [x] Pure `ReadinessEngine` (tests first): sleep points (duration 55, deep 20, efficiency 15, REM 10, re-weighted when stages missing), RHR delta adjustment, sleep-debt adjustment, <5h override; verdict ready/takeItEasy/needRest/noData; plain-language reasons
- [x] Pure resting-HR-from-sleep estimator (lowest ~15% of samples inside the sleep window, >=8 samples)
- [x] Gateway: `sleepStages()` (deep/light/rem/asleep/awake), drop `sleepAsleep`; service `recoveryReport()` with 5-min cache, history from one sessions call
- [x] UI: RecoveryCard becomes verdict card (tap -> RecoveryDetailPage with stage bar, rows, reasons, 7-night history)
- [x] Import page / check: Samsung "does not copy older workouts" hint + point to Samsung export
- [x] Docs wording: "no invented score" -> plain verdict from your own numbers; RHR estimated from sleep heart rate
- **Status:** complete (code + tests + docs; needs real-device check)

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| Treat "smartwatch connection" as the Health Connect / HealthKit integration | No BLE/Wear OS code exists; privacy policy states no direct watch access |
| Do not add direct BLE or Wear OS app | Out of scope, contradicts product/privacy decisions |
| No commits | Global CLAUDE.md rule |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| `adb: command not found` | 1 | No device available; real-device checks handed to user checklist |

## Next Step
Nothing pending in code. Open items need hardware: iOS build, minified release build, Garmin/Fitbit.
