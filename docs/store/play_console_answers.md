# Google Play Console - ready-to-copy answers (StationX)

Drafts matching the app as built (see `docs/PRIVACY_POLICY.md`, `docs/RELEASE.md`). Anything marked `[OWNER: ...]` needs you. Re-check every answer against the final build before submitting.

Package: `dev.mahdi_haji.stationx` - App name: StationX - Category: Health & Fitness - Free, no ads, no in-app purchases (confirm).

## 1. App content basics
- Privacy policy URL: `[OWNER: https://.../privacy.html]`
- Ads: **No ads**.
- App access: **All or some functionality is restricted** — an account is required (username + password). Give the reviewer note in section 5, or a throwaway test account entered in Play Console only.
- Target audience: **13 and over** (select 13-15, 16-17, 18+; not "under 13"). Not designed for children; no Families policy.
- Developer name / contact e-mail / website on the store: `[OWNER: developer name]`, `[OWNER: contact e-mail]`, `[OWNER: website URL optional]`. If registered as an organisation: `[OWNER: legal entity]`.

## 2. Data safety form
**Data collection and security**
| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** (an account is required; training data is saved to it) |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS to Supabase) |
| Do you provide a way for users to request that their data be deleted? | **Yes** |
| Account creation methods | **Username and password** (no e-mail, no OAuth) |
| Delete account URL | `[OWNER: https://.../delete-account.html]` |
| Can users request that some data be deleted without deleting the account? | **Yes** (deleting a workout/session/exercise/goal removes the row; Profile › Delete all my data clears everything but the login) |
| Data encrypted at rest | Not a form question. Honest status: the cloud database is encrypted at rest by the provider; the device only holds a temporary workout draft (not encrypted). |
| Committed to the Play Families Policy | No |
| Independent security review | No |

**Data types** (declare each as *Collected*, **Not shared**, **required** - the app needs an account)
| Category > type | Collected | Shared | Optional | Purpose | Notes |
|---|---|---|---|---|---|
| Personal info > **User IDs** | Yes | No | No | App functionality, Account management | The username (an account id). Not shown to other users. |
| Personal info > Name / Email / Phone / Address | **No** | - | - | - | Not asked. The internal `username@stationx.local` is not a real address and cannot receive mail. |
| Health and fitness > **Health info** | Yes | No | No | App functionality | Age, height, weight (skippable at sign-up), heart-rate values the user typed or accepted, and sessions/values imported from Health Connect that are saved as normal workout data. Declare it because imported/accepted values are saved to the account. |
| Health and fitness > **Fitness info** | Yes | No | No | App functionality | Workouts, the training program, sets, reps, weights, cardio sessions, goals, personal records, and the equipment the user says they can use. |
| App activity > Other user-generated content | Yes | No | No | App functionality | Notes and custom exercise/activity names and instructions. |
| Everything else (location, contacts, photos, files, financial, messages, web history, device IDs, crash logs, diagnostics, ads data) | **No** | - | - | - | No analytics, ads, tracking or crash-reporting SDKs. |

- **Password:** it is sent to the authentication provider (Supabase Auth) only to sign up/in, never stored or logged by the app, and the provider keeps only a hash. Do not declare it as a separate data type beyond "User IDs / account credentials" handled by the provider; if the form asks about "Authentication", the answer is: processed by the service provider for account management only.
- **Shared = No** because Supabase is a service provider processing data on our behalf (Google's definition excludes this). It is named in the privacy policy.
- **Health Connect data itself** is read and processed on-device and not sent to our servers; only sessions/values the user imports or accepts become ordinary workout data saved to the account. Say this in the privacy policy (done).
- The workout draft kept on the device while a workout is running is temporary and not "collected" per Play's definition.

## 3. Health Connect permissions declaration
Core statement for every row: *"Core feature, user-initiated and off by default. Data is processed on-device, is not sold or shared, and is not sent to our servers. Imported sessions and accepted values become part of the user's own workout log. Requested only after an in-app explanation, per feature, and can be switched off at any time."* Privacy policy: section 3. `READ_SLEEP` and `READ_RESTING_HEART_RATE` are requested again (2026-10-15) only by the opt-in "Show sleep & recovery on Today" switch; keep their rows in the declaration.

| Permission | Purpose | User-facing feature | Opt-in |
|---|---|---|---|
| `WRITE_EXERCISE`, `WRITE_DISTANCE`, `WRITE_TOTAL_CALORIES_BURNED` | Save one exercise session per finished workout, with only the distance/calories the user logged, so other health apps show it. | "Save workouts to Health Connect" | Profile > Health > Save workouts toggle |
| `READ_HEART_RATE`, `READ_ACTIVE_CALORIES_BURNED`, `READ_TOTAL_CALORIES_BURNED` | Suggest average heart rate and calories for one session's time window; applied only after user confirmation. Also average/max heart rate on a finished workout and a trend. | "Fill in heart rate and calories", heart-rate on workouts | Profile > Health toggles + confirmation each time |
| `READ_EXERCISE`, `READ_DISTANCE`, `READ_TOTAL_CALORIES_BURNED`, `READ_STEPS` | Connect the integration; list sessions recorded by other apps/watches (e.g. Samsung Health) and add the ones the user confirms. `READ_STEPS` is needed only because the health plugin's workout reader sums steps inside each session; steps are not stored or shown. | "Import workouts" | Profile > Health > Import; preview then confirm (automatic import is a further opt-in) |
| `READ_SLEEP`, `READ_RESTING_HEART_RATE` | Show last night's sleep (with stages) and the resting heart rate vs the user's own recent normal as a ready / take it easy / rest verdict on Today. When no resting value exists it is estimated from the heart rate during sleep (`READ_HEART_RATE`, same heart-rate switch). Read on demand, not stored. | "Show sleep & recovery on Today" | Profile > Health > sleep & recovery toggle |
| `READ_HEALTH_DATA_HISTORY` | Let the import look back further than 30 days before the first grant. | "Import workouts" older history | Separate permission the user can decline |

The manifest declares the rationale activity (`ACTION_SHOW_PERMISSIONS_RATIONALE`) and the Android 14 `VIEW_PERMISSION_USAGE` alias. Reviewer video: Profile > Health, show each toggle's explanation, then the system permission sheet. `[OWNER: record the video on a real phone]`. Before submitting verify the merged manifest has nothing that is not in this table.

## 4. Content rating (IARC questionnaire)
Category: **Utility / reference / fitness (not a game)**. Answers: violence **No**; blood **No**; sexual content/nudity **No**; profanity **No**; controlled substances (drugs, alcohol, tobacco) **No**; gambling **No**; user-to-user communication or sharing **No** (no social features; a user's data is visible only to themselves); shares user location **No**; digital purchases **No**; unrestricted web access **No**. Health: the app logs workouts and does not give medical advice. Expected rating: **Everyone / PEGI 3** (target audience still 13+).

## 5. Reviewer instructions (App access)
> An account is required. Tap Create account and choose any username (3+ characters) and a password of 8+ characters with a capital letter and a digit. Then: About you (age, height, weight; can be skipped) → pick a split → say which equipment you have → choose training/rest days → review and save the program. The program is created once and then only changes when you edit it or ask to regenerate it. No e-mail, phone or verification is required. There is no password recovery by design. Account deletion: Profile > Delete account. Health Connect features are in Profile > Health and are off by default.

(If Play insists on credentials, create a throwaway account `[OWNER: username]` / `[OWNER: password]` and enter them in Play Console only, never in the repo.)

## 6. Store listing drafts
**App name:** StationX

**Short description (<= 80):** `Strength & cardio log: your program built once, smart progression, PRs.` (72)

**Full description (<= 4000):**
```
StationX is a strength and cardio tracker with a program that stays yours.

Build it once
- Pick Push/Pull/Legs, Upper/Lower, Full Body or your own split
- Tell StationX which equipment you have and how many days you train and rest
- Choose exercises yourself or let StationX suggest them, then review everything before saving
- Your saved program never changes on its own: no surprise swaps when you log in, restart or finish a workout. Edit any exercise, or regenerate only when you decide

Train your way
- A rotating workout sequence: skip a day and you simply continue with the next workout
- Log every set, rep and weight
- See what to lift next based on your last session (smart progression)
- Track estimated 1RM and personal records
- Add cardio (run, treadmill, bike, rowing, swimming and many more) on its own or as a finisher
- Backdate sessions and review your history on a calendar
- Create custom exercises and cardio activities
- Weekly goals and progress charts

Private by design
- Your data lives in a private account protected by a username and a password - no e-mail needed
- No ads, no tracking, no analytics
- Delete your account and data yourself, any time
- Export your data and import from Gym Tracker

Optional Health Connect integration (off by default)
- Import workouts recorded by your watch or other apps, after a preview
- Fill in heart rate and calories for a session, after you confirm
- Save finished workouts to Health Connect so Samsung Health and other apps can see them

Note: an internet connection is needed to log in and to save. There is no password recovery, because no e-mail is kept - keep your password safe. StationX is a logging tool and does not give medical advice.
```

**What's new (1.0.0):** `First release: program builder with equipment and training/rest days, workout and cardio logging, progression, PRs, calendar, and optional Health Connect integration.`

## 7. Assets checklist
| Asset | Spec | Status |
|---|---|---|
| App icon | 512x512 PNG, <= 1 MB | `docs/store/play_icon_512.png` |
| Feature graphic | 1024x500 PNG/JPG | `docs/store/play_feature_graphic_1024x500.png` |
| Phone screenshots | 2-8, 1080x2160 (2:1, max ratio Play accepts), PNG/JPG | 7 files in `docs/store/screenshots/` (01_today ... 07_workout_sections); regenerate after UI polish: `STORE_SHOTS=1 flutter test test/store` |
| Tablet screenshots | optional (7"/10") | `[OWNER: optional]` |
| Privacy policy URL | HTTPS, public | `[OWNER]` |
| Delete account URL | HTTPS, public | `[OWNER]` |
| Developer contact e-mail (public) | | `[OWNER]` |
| Signed `.aab` | `build/app/outputs/bundle/release/app-release.aab`, new versionCode each upload | `[OWNER: after keystore]` |
| Health Connect declaration + video | | `[OWNER]` |
| Closed test | >= 12 testers opted in for 14 days (new personal accounts) | `[OWNER]` |
| Countries, pricing | | `[OWNER]` |

## 8. Release notes (per track)
```
1.0.0 - First release.
- Log strength and cardio workouts, rotating split, progression, PRs
- Calendar history, goals, custom exercises
- Username + password account; program built once and kept
- Optional Health Connect: import workouts, heart rate, save workouts
```
