# StationX — Release guide & checklist

Status legend: ✅ done in the repo · 🟡 needs the owner · 🔴 blocked (needs hardware/accounts)

## Release blockers (mirrors roadmap X.7 - manual actions outside the code)
- 🟡 **Apply the Supabase migrations** `20261009000000_exercise_muscle_targets.sql` (**MUST**, see §5b) and `20261010000000_hardening.sql`; run `supabase/tests/rls_and_sync_test.sql` (the 3 new checks have never been run) and `SUPABASE_E2E=1` e2e.
- 🟡 Supabase dashboard: Site URL, min password length, SMTP, templates, leaked-password protection; **revoke the old `sbp_` token**.
- 🟡 Create + back up the upload keystore and `android/key.properties` (release builds now refuse to run without it); test the release build (R8/Isar/Health Connect) on devices.
- 🟡 Host the privacy policy (fill date + e-mail) and a public account-deletion page/e-mail.
- 🟡 Play Console: Data safety, Health Connect declaration, content rating, target audience, closed test (>=12 testers, 14 days).
- ✅ Play screenshots regenerated at 1080x2160 (2:1) in `docs/store/screenshots` - regenerate again after the final UI polish.
- 🔴 iOS: build and test on a Mac. 🔴 No Android device was available: the manual device checklist (roadmap X.6) is still open.

## 0. Decisions only the owner can make
| Item | Current | Action |
|---|---|---|
| ✅ Application ID / bundle ID | Android `applicationId` = `dev.mahdi_ramadhan.stationx` (already set in `android/app/build.gradle.kts`, no longer a template value); iOS/macOS `dev.mahdi-ramadhan.stationx` (iOS bundle ids cannot contain `_`, so the underscore became a hyphen) | Applied 2026-10-08. **Cannot be changed after publishing.** The two platforms' ids need not match. If you'd rather have one id everywhere, choose one without `_` (e.g. `dev.mahdiramadhan.stationx`) *before* the first upload. |
| 🟡 Developer accounts | — | Google Play Console ($25 one-time); Apple Developer Program ($99/yr) for iOS |
| 🟡 Privacy-policy URL + contact email | draft in `docs/PRIVACY_POLICY.md` (now describes optional cloud sync) | Fill placeholders, host over HTTPS; also an **account-deletion page/email** for Google Play |
| 🟡 App name / store listing text | "StationX" | Confirm the name is available on both stores |
| 🟡 Distribution scope | — | Which countries; free vs paid |

## 1. Versioning
`pubspec.yaml` → `version: 1.0.0+1` (`name+build`). Increment the build number for **every** upload (`1.0.0+2`, …). The version shows in Profile › App & safety.

## 2. Android signing (✅ wired, 🟡 key creation)
Release builds are **refused** without `android/key.properties` (both `flutter build apk --release` and `appbundle`; verified: the build fails with a clear message). There is no debug-key fallback. Debug builds are unaffected.
1. Create an upload keystore **once** and back it up somewhere safe (losing it = painful key reset):
   ```bash
   keytool -genkeypair -v -keystore ~/stationx-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (gitignored, as are `*.jks` / `*.keystore` — **never commit them**):
   ```properties
   storePassword=********
   keyPassword=********
   keyAlias=upload
   storeFile=/absolute/path/to/stationx-upload.jks
   ```
3. Build:
   ```bash
   flutter build appbundle --release --dart-define-from-file=env/supabase.json   # Google Play
   flutter build apk --release --dart-define-from-file=env/supabase.json         # direct install/testing
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`.
   **R8 shrinking is OFF by default.** A build with `-Pstationx.minify=true` (keep rules in `android/app/proguard-rules.pro`) compiles and is signed, but it has **not been run on a device** here, so Isar / Health Connect / sync under R8 are unverified. Enable it only after testing a minified build on a phone (cost of leaving it off: ~71 MB universal APK instead of ~66 MB).
4. In Play Console enroll in **Play App Signing** (recommended) and upload the `.aab`.

## 3. Google Play Console checklist
- **App content → Privacy policy:** the hosted URL.
- **App content → Data safety** (answers change because of the optional cloud account — re-check against the final build):
  - *Does the app collect or share user data?* → **Yes — collected, optional** (only when the user creates a cloud account).
  - Collected types: **Personal info → Email address, Name**; **Health and fitness → Fitness info** (workouts, sets, cardio sessions, goals); **App info/Other → user-generated content** (notes).
    Mark them **optional** (users can use the whole app without an account).
  - Purpose: **App functionality** and **Account management**. **Not** used for advertising, analytics or personalisation.
  - *Shared with third parties?* → **No** (Supabase is a service provider processing data on our behalf; Google does not count that as "sharing").
  - Security: **data encrypted in transit: Yes**; **users can request data deletion: Yes** (in-app *Delete cloud account & data*).
  - **Account deletion web page:** Google Play requires a public URL (or email process) where users can request account deletion — **owner must provide it** and enter it in the Data safety form.
  - Health Connect / Apple Health data is read/written on-device only and **never sent to StationX servers**. Caveat to state in the Data safety answers: sessions you *import* and values you *accept* become normal workout data and sync like any session if the user turns on cloud sync.
- **App content → Health Connect permissions declaration.** The manifest requests (all opt-in, requested per feature only after an in-app explanation):
  | Permission | Used for |
  |---|---|
  | `READ_SLEEP`, `READ_RESTING_HEART_RATE` | Recovery summary (sleep + resting HR vs 7-day average) |
  | `WRITE_EXERCISE`, `WRITE_DISTANCE`, `WRITE_TOTAL_CALORIES_BURNED` | "Save workouts": one exercise session per finished workout, with only the distance/calories the user logged |
  | `READ_HEART_RATE`, `READ_ACTIVE_CALORIES_BURNED`, `READ_TOTAL_CALORIES_BURNED` | "Fill in heart rate and calories": user-confirmed suggestion for one cardio session's time window |
  | `READ_EXERCISE`, `READ_DISTANCE`, `READ_TOTAL_CALORIES_BURNED`, `READ_STEPS` | "Import workouts": list sessions from other apps (e.g. Samsung Health) for a user-confirmed import. `READ_STEPS` is required only because the `health` plugin's workout reader sums steps inside each session; steps are not stored or shown. |
  - Purpose text for each row: *"Core feature, user-initiated and off by default. Data is processed on-device, is not sold or shared, and is not sent to our servers. Imported sessions and accepted values become part of the user's own workout log."* Link the privacy policy (section 3). The rationale activity (`ACTION_SHOW_PERMISSIONS_RATIONALE`) and the Android 14 `VIEW_PERMISSION_USAGE` alias are declared.
  - Play may ask for a demo video / reviewer instructions: show Profile › Health › each toggle's explanation, then the system permission sheet.
  - **Verify on a device before submitting**: the plugin's exact permission requests vs. this table (declare nothing unused, request nothing undeclared), and that no `READ_HEALTH_DATA_HISTORY` is needed (without it Health Connect only returns data from up to 30 days before the first grant, so the 90-day import window is effectively 30 days on Android).
- **Target audience:** 13+ / general; **Ads:** none; **Content rating questionnaire:** fitness utility, no violence/UGC.
- **Store listing:** short description (≤80 chars) e.g. *"Offline strength & cardio log with smart progression and PRs."*; full description (see below); 2–8 phone screenshots; **ready in `docs/store/`**: `play_icon_512.png`, `play_feature_graphic_1024x500.png`, and `screenshots/` (6 phone screenshots, **1080×2160 = 2:1**, the tallest ratio Play accepts; the earlier 1080×2400 = 2.22:1 would be rejected; from the seeded demo data). Regenerate with `STORE_SHOTS=1 flutter test test/store` (size `Size(360, 720)` at 3x; re-check them visually first; add your own device-frame/caption marketing if you like).
- **Testing:** use an Internal testing track first; Google requires a closed test (≥12 testers for 14 days) before production for new personal developer accounts.

### Suggested full description
> StationX is an offline-first strength and cardio tracker. Follow a rotating workout split, log every set, see what to lift next based on your last session, and track estimated 1RM and personal records. Add cardio (run, treadmill, bike and more) on its own or as a finisher, backdate sessions, and review your history on a calendar. Everything is stored on your device — no account needed, no ads, no tracking; an optional cloud account can back up and sync your data. Optionally connect Health Connect (Samsung Health, watches) or Apple Health to see recovery data, save your workouts there, or import sessions from other apps.

## 4. iOS / App Store (🔴 needs a Mac + Apple Developer account)
`flutter build ios` has **never been run** on this project (see roadmap §P). Do on a Mac:
1. `flutter build ios --release --no-codesign` then open `ios/Runner.xcworkspace` in Xcode.
2. Set the bundle id and Team (Signing & Capabilities); confirm **HealthKit** capability is present (entitlement file `ios/Runner/Runner.entitlements` is already wired) and that the hand-edited project loads cleanly.
3. Test on a real iPhone (permission sheet, reads, denied/empty path).
4. App Store Connect: privacy nutrition label → **Data Not Collected**; Health usage string is already in `Info.plist`; add the privacy-policy URL; screenshots for required device sizes.
5. App Review note: *"All data is stored locally. Health access is optional and off by default: sleep/resting heart rate for a recovery summary, saving finished workouts to Apple Health, and reading workouts/heart rate to fill in or import sessions. Each is a separate toggle with an explanation; nothing is sent to our servers."*

## 5. Pre-release verification (🔴 needs devices — nothing below has been done)
- [ ] Release APK/AAB installs and launches on at least one low-end and one current Android phone (R8/minify can break plugins at runtime — **test Isar and Health Connect in the *release* build**).
- [ ] Data survives force-stop and reboot; wipe + re-seed works.
- [ ] Health Connect on a real device: permission dialog, real data, deny path, revoke + restart; Samsung Health → Health Connect sharing path, both directions (log cardio in StationX and see it in Samsung Health; record in Samsung Health and import it); also toggle each of the three features on/off, deny each permission sheet, revoke and restart. Apple Health: build on a Mac (iOS path never compiled here), confirm HealthKit write authorization for workouts.
- [ ] Keyboard, safe areas, gesture navigation, text scale 1.3, dark/OLED, orientation lock behaviour.
- [ ] Performance: scroll the history/calendar with the demo data (Profile › Load demo data); profile with `flutter run --profile` + DevTools (target: no jank on active-workout and lists).
- [ ] Airplane mode: everything works (no network use).
- [ ] TalkBack walkthrough on a real device (code-level pass is done and tested — see roadmap §R): log a full workout, finish cardio, browse the calendar, change settings; check focus order, that nothing is read twice, and the rest-timer "Rest over" announcement. Also run Android's *Accessibility Scanner* and try *Switch Access*.

## 5b. Cloud sync release checklist (Supabase)
- Build with the cloud config: `flutter build appbundle --release --dart-define-from-file=env/supabase.json` (publishable key only; the file is gitignored). **Without it the cloud feature is absent from the build.**
- Supabase dashboard (not changed by the assistant): set **Site URL** (confirmation e-mails link there; `http://localhost:3000` is wrong for production), raise **minimum password length** (currently 6; the app requires 8), configure **custom SMTP** (the default mail sender is heavily rate-limited), review **e-mail templates**, enable **leaked-password protection** if available.
- **Password reset is not implemented in the app** (it needs a hosted page to receive the reset link). Until then a user who forgets the password can only reset it from the Supabase email flow with a web page you host.
- **MUST apply `supabase/migrations/20261009000000_exercise_muscle_targets.sql` to the live project (`supabase db push`) BEFORE shipping a build with custom-exercise muscle targets.** Otherwise pushing custom exercises fails (sync shows its error state; local data is safe and retried once the column exists).
- Run `SUPABASE_E2E=1 … flutter test test/e2e` (see `supabase/README.md`) against the production project before shipping.
- Update the **Play Data safety form** and **App Store privacy label** (see §3 above); re-test the release build with and without a cloud account.

## 6. Build hygiene
- `flutter analyze` and `flutter test` must be clean before every release.
- Persistence tests download the Isar core on first run (gitignored `libisar.so`).
- Release APK is ~71 MB (3 ABIs, no R8); the Play App Bundle delivers per-ABI splits. For direct distribution use `flutter build apk --split-per-abi`.
- The Android release now **has the `INTERNET` permission** (needed only for optional cloud sync; the app makes no requests unless the user signs in). Verify the merged manifest before each release.

## 7. Known gaps relevant to release
See `docs/STATIONX_UI_IMPLEMENTATION_ROADMAP.md` §H, §L, §O, §P. Highlights: no at-rest database encryption; no schema migrations yet (additive changes only); iOS untested; privacy policy placeholders (date, e-mail, hosting). The applicationId is set (see §0).
