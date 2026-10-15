# Progress

## 2026-10-14
- Mapped the watch path (Health Connect / HealthKit via `health` 13.3.2). No BLE/Wear OS code, by design.
- Baseline: `flutter analyze lib/data/health lib/features/health lib/domain` clean; 99 health tests pass.
- Static audit: manifest permissions match `_featureTypes`; `ownSourceIds` package equals `applicationId` (dev.mahdi_haji.stationx); autoImport runs on start and on app resume (main_shell.dart); live HR chip polls every 15 s with single-flight guard; HR trend does one read per day on purpose (small calls; Health Connect rate-limits reads, so parallelising is risky and unmeasurable here).
- Blocked: no adb/phone; Android licenses not accepted. Real-device checks remain the open item in docs/RELEASE.md section 5 (line ~104).
- No source changes made.

## 2026-10-14 (later)
- Added heart-rate state to the connection check (off / noSamples / found) with a Turn on button; heart rate no longer requires the calories permission; metrics read in separate calls.
- User confirmed on a Galaxy: heart rate works, trend shows data, "1 saved by StationX" after finishing a workout (write-back works).
- Reviewed write/import logic: check is read-only; own records excluded from import by source and receipt id (tested); write queue is single-flight and crash-safe.
- Full suite: 1190 tests pass, analyze clean. Nothing committed.

## 2026-10-15
- User: heart rate + cardio write work; past Galaxy Watch data not imported.
- Findings: health plugin 13.3.2 swallows native read errors (returns []), reads distance/kcal/steps per session; page default window is 30 days; Android returns ~30 days unless history permission granted; unmapped types (Samsung "Other", yoga...) are skipped as unsupported.
- Change: import plan now reports skipped types by name; import page shows "Skipped types: ..." (test added). Behaviour of what is imported unchanged.
- Open: need user's Import page numbers (1 year / All) to know which cause applies.

## 2026-10-15 (sleep & recovery restored)
- User chose "Bring them back". Added HealthFeature.recovery, RecoverySnapshot, HealthSummary (pure), gateway sleep/RHR reads, service.recoverySnapshot(), RecoveryCard on Today, settings switch + explanation, manifest READ_SLEEP/READ_RESTING_HEART_RATE.
- Connection check now explains missing watch workouts; docs/policy/Play/iOS plist/README/FR/PROJECT_DETAILS updated; memory updated.
- Full suite 1213 tests pass, analyze clean. Nothing committed.

## 2026-10-15 (readiness verdict + sleep details + resting HR fallback)
- Research: Samsung does not backfill Health Connect; HC drops data older than 30d before first grant; no evidence Samsung writes RestingHeartRateRecord; readiness = sleep vs target + resting HR vs own baseline + sleep debt.
- Added ReadinessEngine (pure, tested), SleepNight/RecoveryReport models, HealthSummary.sleepNight/nightHistory/restingFromSleepHr, gateway sleepStages (deep/light/REM/asleep/awake), service.recoveryReport() with 5-min cache and recorded->estimated resting HR, RecoveryCard verdict + RecoveryDetailPage, import-page Samsung note. Docs/policy updated.
- Full suite 1241 tests pass, analyze clean. Nothing committed.

## 2026-10-15 (calendar sleep)
- User: works; wants past sleep in the calendar; Samsung workouts only yesterday (consistent with no-backfill finding).
- Added service.sleepDays(month), recoveryReport(day:) (per-day cache), calendar moon markers + legend + selected-day Sleep card -> details. Tests added.

## 2026-10-15 (plan reconciled)
- User pointed out task_plan.md still showed Phases 2-5 pending. Reconciled it with what was actually done; did the skipped performance work: per-day heart-rate trend cache (tests). Deferred: diagnose() read-failed vs empty (plugin swallows errors).
