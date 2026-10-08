# StationX — Release guide & checklist

Status legend: ✅ done in the repo · 🟡 needs the owner · 🔴 blocked (needs hardware/accounts)

## 0. Decisions only the owner can make
| Item | Current | Action |
|---|---|---|
| ✅ Application ID / bundle ID | Android `dev.mahdi_ramadhan.stationx`; iOS/macOS `dev.mahdi-ramadhan.stationx` (iOS bundle ids cannot contain `_`, so the underscore became a hyphen) | Applied 2026-10-08. **Cannot be changed after publishing.** The two platforms' ids need not match. If you'd rather have one id everywhere, choose one without `_` (e.g. `dev.mahdiramadhan.stationx`) *before* the first upload. |
| 🟡 Developer accounts | — | Google Play Console ($25 one-time); Apple Developer Program ($99/yr) for iOS |
| 🟡 Privacy-policy URL + contact email | draft in `docs/PRIVACY_POLICY.md` (now describes optional cloud sync) | Fill placeholders, host over HTTPS; also an **account-deletion page/email** for Google Play |
| 🟡 App name / store listing text | "StationX" | Confirm the name is available on both stores |
| 🟡 Distribution scope | — | Which countries; free vs paid |

## 1. Versioning
`pubspec.yaml` → `version: 1.0.0+1` (`name+build`). Increment the build number for **every** upload (`1.0.0+2`, …). The version shows in Profile › App & safety.

## 2. Android signing (✅ wired, 🟡 key creation)
1. Create an upload keystore **once** and back it up somewhere safe (losing it = painful key reset):
   ```bash
   keytool -genkeypair -v -keystore ~/stationx-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (gitignored — **never commit it or the keystore**):
   ```properties
   storePassword=********
   keyPassword=********
   keyAlias=upload
   storeFile=/absolute/path/to/stationx-upload.jks
   ```
3. Build:
   ```bash
   flutter build appbundle --release   # for Google Play (REFUSES to build without key.properties)
   flutter build apk --release         # for direct install/testing (falls back to debug signing if no key)
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`.
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
  - Health Connect / Apple Health data is read on-device and **never collected or uploaded**.
- **App content → Health Connect permissions declaration** (required because the manifest requests `READ_SLEEP` and `READ_RESTING_HEART_RATE`):
  - Purpose: *"Shows the user a recovery summary (last night's sleep and resting heart rate versus their 7-day average) on the home screen. Data is read on-device only, is not written back, stored, uploaded or shared. Access is optional and requested only after the user taps Connect and confirms an in-app explanation."*
  - Link to the privacy policy.
- **Target audience:** 13+ / general; **Ads:** none; **Content rating questionnaire:** fitness utility, no violence/UGC.
- **Store listing:** short description (≤80 chars) e.g. *"Offline strength & cardio log with smart progression and PRs."*; full description (see below); 2–8 phone screenshots; **ready in `docs/store/`**: `play_icon_512.png`, `play_feature_graphic_1024x500.png`, and `screenshots/` (6 phone screenshots, 1080×2160, from the seeded demo data). Regenerate screenshots with `STORE_SHOTS=1 flutter test test/store` (re-check them visually first; add your own device-frame/caption marketing if you like).
- **Testing:** use an Internal testing track first; Google requires a closed test (≥12 testers for 14 days) before production for new personal developer accounts.

### Suggested full description
> StationX is an offline-first strength and cardio tracker. Follow a rotating workout split, log every set, see what to lift next based on your last session, and track estimated 1RM and personal records. Add cardio (run, treadmill, bike and more) on its own or as a finisher, backdate sessions, and review your history on a calendar. Everything is stored on your device — no account, no ads, no tracking. Optionally connect Health Connect to see last night's sleep and resting heart rate.

## 4. iOS / App Store (🔴 needs a Mac + Apple Developer account)
`flutter build ios` has **never been run** on this project (see roadmap §P). Do on a Mac:
1. `flutter build ios --release --no-codesign` then open `ios/Runner.xcworkspace` in Xcode.
2. Set the bundle id and Team (Signing & Capabilities); confirm **HealthKit** capability is present (entitlement file `ios/Runner/Runner.entitlements` is already wired) and that the hand-edited project loads cleanly.
3. Test on a real iPhone (permission sheet, reads, denied/empty path).
4. App Store Connect: privacy nutrition label → **Data Not Collected**; Health usage string is already in `Info.plist`; add the privacy-policy URL; screenshots for required device sizes.
5. App Review note: *"All data is stored locally. Health access is optional, read-only (sleep and resting heart rate), and used only to show a recovery summary on-device."*

## 5. Pre-release verification (🔴 needs devices — nothing below has been done)
- [ ] Release APK/AAB installs and launches on at least one low-end and one current Android phone (R8/minify can break plugins at runtime — **test Isar and Health Connect in the *release* build**).
- [ ] Data survives force-stop and reboot; wipe + re-seed works.
- [ ] Health Connect on a real device: permission dialog, real data, deny path, revoke + restart; Samsung Health → Health Connect sharing path.
- [ ] Keyboard, safe areas, gesture navigation, text scale 1.3, dark/OLED, orientation lock behaviour.
- [ ] Performance: scroll the history/calendar with the demo data (Profile › Load demo data); profile with `flutter run --profile` + DevTools (target: no jank on active-workout and lists).
- [ ] Airplane mode: everything works (no network use).
- [ ] TalkBack walkthrough on a real device (code-level pass is done and tested — see roadmap §R): log a full workout, finish cardio, browse the calendar, change settings; check focus order, that nothing is read twice, and the rest-timer "Rest over" announcement. Also run Android's *Accessibility Scanner* and try *Switch Access*.

## 5b. Cloud sync release checklist (Supabase)
- Build with the cloud config: `flutter build appbundle --release --dart-define-from-file=env/supabase.json` (publishable key only; the file is gitignored). **Without it the cloud feature is absent from the build.**
- Supabase dashboard (not changed by the assistant): set **Site URL** (confirmation e-mails link there; `http://localhost:3000` is wrong for production), raise **minimum password length** (currently 6; the app requires 8), configure **custom SMTP** (the default mail sender is heavily rate-limited), review **e-mail templates**, enable **leaked-password protection** if available.
- **Password reset is not implemented in the app** (it needs a hosted page to receive the reset link). Until then a user who forgets the password can only reset it from the Supabase email flow with a web page you host.
- Run `SUPABASE_E2E=1 … flutter test test/e2e` (see `supabase/README.md`) against the production project before shipping.
- Update the **Play Data safety form** and **App Store privacy label** (see §3 above); re-test the release build with and without a cloud account.

## 6. Build hygiene
- `flutter analyze` and `flutter test` must be clean before every release.
- Persistence tests download the Isar core on first run (gitignored `libisar.so`).
- Release APK is ~61 MB (3 ABIs); the Play App Bundle delivers per-ABI splits. For direct distribution use `flutter build apk --split-per-abi`.
- The Android release now **has the `INTERNET` permission** (needed only for optional cloud sync; the app makes no requests unless the user signs in). Verify the merged manifest before each release.

## 7. Known gaps relevant to release
See `docs/STATIONX_UI_IMPLEMENTATION_ROADMAP.md` §H, §L, §O, §P. Highlights: no at-rest database encryption; no schema migrations yet (additive changes only); iOS untested; privacy policy placeholders; applicationId still a template value.
