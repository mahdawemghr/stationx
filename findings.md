# Findings

## Architecture
- Gateway boundary: `lib/data/health/health_gateway.dart` (abstract, inert default). Real impl `plugin_health_gateway.dart` (untested, device only).
- Service: `health_sync_service.dart` (677 lines): write queue (single-flight), import, auto import (6h), HR stats, `diagnose()`.
- UI: `lib/features/health/watch_setup_page.dart` ("Check my connection").

## Candidate issues (from code reading, unverified until tests written)
1. `heartRateTrend(days)` makes `days` sequential platform calls (health_sync_service.dart ~513).
2. `PluginHealthGateway._read` returns `[]` on exception, so `diagnose()` reports "Connected, but no recent watch data" for a failed read (misleading). `diagnose` catch also maps any exception to noRecentData.
3. `latestHeartRate` runs permission check + read on each call (live chip polling cost).
4. `_attachHeartRates` is sequential per imported session.
5. R8/minify, iOS compile, Isar+Health under release build all unverified on device (docs/RELEASE.md).

## Environment
- No adb, no phone; `flutter devices` shows Linux desktop only.
