# StationX — Release guide & checklist

Status legend: ✅ done in the repo · 🟡 needs the owner · 🔴 blocked (needs hardware/accounts)

## Release blockers (current truth)
Done in the repo / project:
- ✅ Android Auto Backup and device transfer are off (`allowBackup=false`, backup rules).
- ✅ Release signing guard: release builds fail without `android/key.properties`; no debug-key fallback.
- ✅ Privacy wording matches the build (in-app page, `docs/PRIVACY_POLICY.md`: username + password accounts, no e-mail, optional age/height/weight, opt-in health data, retention, 13+).
- ✅ Supabase migrations: earlier ones inferred present from the live schema; **`20261014000000_online_first` and `20261015000000_profile_training_prefs` applied 2026-10-11** after a rolled-back dry run, and `supabase/tests/rls_and_rpc_test.sql` passed 22/22 against the live project (details: `supabase/README.md`). Re-verify before each release.
- ✅ Supabase auth settings (auto-confirm ON, min password 8, Site URL = deep link). Username-only auth: no e-mail, no SMTP needed.
- ✅ Hosted-page TEMPLATES ready: `docs/web/` (`privacy.html`, `delete-account.html`, `index.html`, `README.md` with hosting options and the exact URLs for Play Console).
- ✅ Play Console answer drafts: `docs/store/play_console_answers.md` (Data safety, Health Connect declaration, content rating, listing text, reviewer notes, asset checklist).
- ✅ Keystore helper `scripts/make_release_keystore.sh` + `android/key.properties.example`.
- ✅ Play graphics: icon, feature graphic, screenshots 1080x2160 in `docs/store/` (regenerate after final UI polish).

Remaining, OWNER ONLY:
1. 🟡 Host the two pages (`docs/web/README.md`) after filling the placeholders `[CONTACT EMAIL — fill in]`, `[DATE — fill in]`, `[OWNER: developer name — fill in]`, `[OWNER: N]` in `docs/web/*.html` and `docs/PRIVACY_POLICY.md`; keep the .md as the single source and mirror edits into `privacy.html`.
2. 🟡 Create the upload keystore: `bash scripts/make_release_keystore.sh` (outside the repo); BACK UP the file and passwords. Then build `flutter build appbundle --release --dart-define-from-file=env/supabase.json` (section 2).
3. 🟡 Play Console forms from `docs/store/play_console_answers.md`: Data safety, Health Connect declaration (+ video), content rating, target audience, store listing, app access.
4. 🟡 Closed testing (>= 12 testers for 14 days for new personal accounts), then production.
5. 🟡 **Revoke the Supabase personal access tokens (`sbp_`) that were pasted in chat** (dashboard > Account > Access tokens), including the one used on 2026-10-11, and create new ones only if needed.
6. 🔴 Test the release build on a real Android phone (device draft store, Health Connect, sign-up, onboarding, login, account deletion); the manual device checklist (section 5) is still open.
7. 🔴 iOS: build and test on a Mac with an Apple Developer account (section 4).
8. 🟡 Custom SMTP / e-mail templates only if e-mail features are ever added (none today). Leaked-password protection needs the Supabase Pro plan; CAPTCHA and rate limits are a dashboard action.
9. 🟡 Supabase has no backups on this plan (no PITR, `backups: []` on 2026-10-11): decide on a backup routine before real users arrive.

## 0. Decisions only the owner can make
| Item | Current | Action |
|---|---|---|
| ✅ Application ID / bundle ID | Android `applicationId` = `dev.mahdi_haji.stationx` (already set in `android/app/build.gradle.kts`, no longer a template value); iOS/macOS `dev.mahdi-haji.stationx` (iOS bundle ids cannot contain `_`, so the underscore became a hyphen) | Applied 2026-10-08. **Cannot be changed after publishing.** The two platforms' ids need not match. If you'd rather have one id everywhere, choose one without `_` (e.g. `dev.mahdiramadhan.stationx`) *before* the first upload. |
| 🟡 Developer accounts | — | Google Play Console ($25 one-time); Apple Developer Program ($99/yr) for iOS |
| 🟡 Privacy-policy URL + contact email | `docs/PRIVACY_POLICY.md` (source) and ready pages in `docs/web/` | Fill placeholders, host over HTTPS (`docs/web/README.md`); the account-deletion page is `docs/web/delete-account.html` |
| 🟡 App name / store listing text | "StationX" | Confirm the name is available on both stores |
| 🟡 Distribution scope | — | Which countries; free vs paid |

## 1. Versioning
`pubspec.yaml` → `version: 1.0.0+1` (`name+build`). Increment the build number for **every** upload (`1.0.0+2`, …). The version shows in Profile › App & safety.

## 2. Android signing (✅ wired, 🟡 key creation)
Release builds are **refused** without `android/key.properties` (both `flutter build apk --release` and `appbundle`; verified: the build fails with a clear message). There is no debug-key fallback. Debug builds are unaffected.
1. Create an upload keystore **once** and back it up somewhere safe (losing it = painful key reset):
   ```bash
   bash scripts/make_release_keystore.sh   # interactive; keystore goes to ~/keys/stationx-upload.jks, writes android/key.properties
   ```
   (Manual alternative: `keytool -genkeypair -v -keystore ~/keys/stationx-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.)
2. `android/key.properties` (template: `android/key.properties.example`; gitignored, as are `*.jks` / `*.keystore` — **never commit them**):
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
   Verify the signature of an APK: `apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk` (apksigner is in `$ANDROID_HOME/build-tools/<ver>/`); for an .aab: `keytool -printcert -jarfile app-release.aab`. Compare SHA-256 with `keytool -list -v -keystore <jks>`.
4. In Play Console enroll in **Play App Signing** (recommended) and upload the `.aab`.

## 3. Google Play Console checklist
- Ready-to-copy answers for everything below: `docs/store/play_console_answers.md`.
- **App content → Privacy policy:** the hosted URL (`<base>/privacy.html`).
- **App content → Data safety** (the app is online-first: an account is required, so nothing below is "optional" — re-check against the final build):
  - *Does the app collect or share user data?* → **Yes — collected, required for the app to work**.
  - Collected types: **Personal info → User IDs (the username)** (no e-mail address, no name, no phone); **Health and fitness → Health info** (age, height and weight the user enters, optional) and **Fitness info** (workouts, sets, cardio sessions, goals); **App info/Other → user-generated content** (notes).
  - Purpose: **App functionality** and **Account management**. **Not** used for advertising, analytics or personalisation.
  - *Shared with third parties?* → **No** (Supabase is a service provider processing data on our behalf; Google does not count that as "sharing").
  - Security: **data encrypted in transit: Yes**; **users can request data deletion: Yes** (in-app Profile › *Delete account* / *Delete all my data*).
  - **Account deletion web page:** `docs/web/delete-account.html` once hosted; enter its URL in the Data safety form.
  - Health Connect / Apple Health data is read/written on-device only and **never sent to StationX servers**. Caveat to state in the Data safety answers: sessions you *import* and values you *accept* become normal workout data and are saved to the user's account like any session.
- **App content → Health Connect permissions declaration.** The manifest requests (all opt-in, requested per feature only after an in-app explanation):
  | Permission | Used for |
  |---|---|
  | `WRITE_EXERCISE`, `WRITE_DISTANCE`, `WRITE_TOTAL_CALORIES_BURNED` | "Save workouts": one exercise session per finished workout, with only the distance/calories the user logged |
  | `READ_HEART_RATE`, `READ_ACTIVE_CALORIES_BURNED`, `READ_TOTAL_CALORIES_BURNED` | "Fill in heart rate and calories": user-confirmed suggestion for one cardio session's time window |
  | `READ_HEALTH_DATA_HISTORY` | "Import workouts": optional look-back beyond 30 days |
  | `READ_EXERCISE`, `READ_DISTANCE`, `READ_TOTAL_CALORIES_BURNED`, `READ_STEPS` | "Connect" and "Import workouts": list sessions from other apps (e.g. Samsung Health) for a user-confirmed import. `READ_STEPS` is required only because the `health` plugin's workout reader sums steps inside each session; steps are not stored or shown. |
  - Purpose text for each row: *"Core feature, user-initiated and off by default. Data is processed on-device, is not sold or shared, and is not sent to our servers. Imported sessions and accepted values become part of the user's own workout log."* Link the privacy policy (section 3). The rationale activity (`ACTION_SHOW_PERMISSIONS_RATIONALE`) and the Android 14 `VIEW_PERMISSION_USAGE` alias are declared.
  - Play may ask for a demo video / reviewer instructions: show Profile › Health › each toggle's explanation, then the system permission sheet.
  - **Verify on a device before submitting**: the plugin's exact permission requests vs. this table (declare nothing unused, request nothing undeclared), and that `READ_HEALTH_DATA_HISTORY` (now in the manifest, declared above) behaves as expected (without it Health Connect only returns data from up to 30 days before the first grant).
- **Target audience:** 13+ / general; **Ads:** none; **Content rating questionnaire:** fitness utility, no violence/UGC.
- **Store listing:** short description (≤80 chars) e.g. *"Strength & cardio log with a program built once, smart progression and PRs."*; full description (see below); 2–8 phone screenshots; **ready in `docs/store/`**: `play_icon_512.png`, `play_feature_graphic_1024x500.png`, and `screenshots/` (6 phone screenshots, **1080×2160 = 2:1**, the tallest ratio Play accepts; the earlier 1080×2400 = 2.22:1 would be rejected; from the seeded demo data). Regenerate with `STORE_SHOTS=1 flutter test test/store` (size `Size(360, 720)` at 3x; re-check them visually first; add your own device-frame/caption marketing if you like).
- **Testing:** use an Internal testing track first; Google requires a closed test (≥12 testers for 14 days) before production for new personal developer accounts.

### Suggested full description
> StationX is a strength and cardio tracker. Choose a split, tell it your equipment and training days, and get a program that is built once and then stays exactly as you saved it (you edit it, or regenerate it when you decide). Log every set, see what to lift next based on your last session, and track estimated 1RM and personal records. Add cardio on its own or as a finisher, backdate sessions, and review your history on a calendar. Your data lives in a private account (username and password, no e-mail) — no ads, no tracking. Optionally connect Health Connect (Samsung Health, watches) or Apple Health to import workouts, add heart rate to a session, or save your workouts there.

## 4. iOS / App Store (🔴 needs a Mac + Apple Developer account)
`flutter build ios` has **never been run** on this project (see roadmap §P). Do on a Mac:
1. `flutter build ios --release --no-codesign` then open `ios/Runner.xcworkspace` in Xcode.
2. Set the bundle id and Team (Signing & Capabilities); confirm **HealthKit** capability is present (entitlement file `ios/Runner/Runner.entitlements` is already wired) and that the hand-edited project loads cleanly.
3. Test on a real iPhone (permission sheet, reads, denied/empty path).
4. App Store Connect: privacy nutrition label → **Data Not Collected**; Health usage string is already in `Info.plist`; add the privacy-policy URL; screenshots for required device sizes.
5. App Review note: *"Training data is saved to the user's private account (username + password). Health access is optional and off by default: saving finished workouts to Apple Health and reading workouts/heart rate to fill in or import sessions. Each is a separate toggle with an explanation; health data is not sent to our servers. StationX does not read sleep or resting heart rate."*

## 5. Pre-release verification (🔴 needs devices — nothing below has been done)
- [ ] Release APK/AAB installs and launches on at least one low-end and one current Android phone (R8/minify can break plugins at runtime — **test the workout draft (Isar) and Health Connect in the *release* build**).
- [ ] Register → About you → equipment → program review/save; kill the app and relaunch: the same program is there. Log in on a second phone: same program.
- [ ] A workout draft survives force-stop and reboot; discarding it works.
- [ ] Health Connect on a real device: permission dialog, real data, deny path, revoke + restart; Samsung Health → Health Connect sharing path, both directions (log cardio in StationX and see it in Samsung Health; record in Samsung Health and import it); also toggle each of the three features on/off, deny each permission sheet, revoke and restart. Apple Health: build on a Mac (iOS path never compiled here), confirm HealthKit write authorization for workouts.
- [ ] Keyboard, safe areas, gesture navigation, text scale 1.3, dark/OLED, orientation lock behaviour.
- [ ] Performance: scroll the history/calendar with the demo data (Profile › Load demo data); profile with `flutter run --profile` + DevTools (target: no jank on active-workout and lists).
- [ ] Airplane mode: logging in and saving fail with a clear message and nothing is shown as saved; an in-progress workout keeps its draft; everything works again when back online.
- [ ] TalkBack walkthrough on a real device (code-level pass is done and tested — see roadmap §R): log a full workout, finish cardio, browse the calendar, change settings; check focus order, that nothing is read twice, and the set-done announcements. Also run Android's *Accessibility Scanner* and try *Switch Access*.

## 5b. Cloud sync release checklist (Supabase)
- The Supabase URL + publishable key are built in, so `flutter build appbundle --release` works as is. To target another project add `--dart-define-from-file=env/supabase.json` (publishable key only; the file is gitignored).
- Supabase auth settings are **already configured** (see "Supabase auth settings" below). Accounts are username + password; no e-mail is collected or sent, so SMTP and e-mail templates are irrelevant.
- **There is no password reset, by design** (no e-mail on file). The Create account screen and the privacy policy tell the user to keep the password safe.
- The live schema must contain every migration in `supabase/migrations/` before a build ships (see `supabase/README.md` for how to check). Without `20261014`/`20261015` a new account cannot be initialised and the app shows a load error.
- Run `supabase/tests/rls_and_rpc_test.sql` against the production project before shipping (it rolls itself back and prints only PASS/FAIL lines).
- Update the **Play Data safety form** and **App Store privacy label** (see §3 above); the App Store label is **not** "Data Not Collected" any more (username, health & fitness data are collected, linked to the user, for app functionality).

## 6. Build hygiene
- `flutter analyze` and `flutter test` must be clean before every release.
- Device-store tests download the Isar core on first run (gitignored `libisar.so`). Run `dart format lib test` before committing.
- Release APK is ~71 MB (3 ABIs, no R8); the Play App Bundle delivers per-ABI splits. For direct distribution use `flutter build apk --split-per-abi`.
- The Android release has the `INTERNET` permission (the app is online-first; it only talks to the StationX Supabase project). Verify the merged manifest before each release: no `READ_SLEEP` / `READ_RESTING_HEART_RATE`.

## 7. Known gaps relevant to release
Highlights: no at-rest database encryption; no schema migrations yet (additive changes only); iOS untested; privacy policy placeholders (date, e-mail; hosting via `docs/web`). The applicationId is set (see §0).


## Supabase auth settings (verified 2026-10-10)
- Applied: **e-mail auto-confirm ON** (sign-up returns a session immediately; the `<username>@stationx.local` identifier cannot receive mail).
- Applied: **minimum password length 8** (the app also requires a capital letter and a digit).
- Applied: **Site URL = `dev.mahdi-haji.stationx://auth-callback`** (no longer `http://localhost:3000`).
- Not needed: custom SMTP and e-mail templates (no e-mail is ever sent). Leaked-password protection needs the Pro plan.
- Still needed for Google Play: a public **account-deletion URL** (or process) to enter in the Data safety form, because accounts can be created in the app. In-app deletion exists (Profile › *Delete account*).
