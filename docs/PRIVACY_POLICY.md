# StationX — Privacy Policy

_Effective date: [DATE — fill in]_
_Contact: [CONTACT EMAIL — fill in]_

> **Owner action required:** the hosted copy is `docs/web/privacy.html` (see `docs/web/README.md`; edit THIS file first, then mirror the change there). This draft accurately describes how the app is built today. Fill in the two
> placeholders, have it reviewed if you need legal assurance, and host it at a public HTTPS URL (the Google Play
> and App Store listings require one). Keep it in sync with `lib/features/profile/privacy_page.dart` and the
> store privacy forms (see `docs/RELEASE.md`). If data handling changes, update this policy FIRST.

StationX is an online strength and cardio tracker. Your training data is saved to a private account on our server
(Supabase), so an internet connection is needed to log in, load and save it. This policy explains what the app stores,
where, and your choices.

## 1. Data stored on your device
Only temporary, device-level state is kept on the phone: the workout you are currently recording (a draft, removed when
you log out, when a different account signs in, or when you finish the workout), the optional health-integration settings,
and the sign-in session token managed by the authentication SDK. Your workouts,
history, goals and profile are **not** stored on the device; they are loaded from your account while you use the app and
removed from memory when you log out. Your data is not backed up by Android (Auto Backup is off for this app).

## 2. Your account and data on the server
- **What is stored:** profile & settings (name, age, height, weight, units, theme, defaults, weekly training-day goal, the equipment you said you can use, your experience level); your training program (routines, exercises,
  sets and rep ranges, cardio finishers, rotation order and position); workout and cardio history (dates, sets, weights, repetitions, RPE, durations,
  distances, heart-rate values you typed, route names, notes), goals, custom exercises (including muscle targets) and custom cardio activities, plus your **username**.
  Imported workouts are stored like any other workout.
- **Never stored on the server:** your password in readable form (see below), the workout draft, and the health-integration queues of this device.
- **Where:** Supabase (PostgreSQL, region Asia-Pacific / Tokyo), acting as our service provider. We do not sell your data or share it with advertisers or other third parties.
- **Who can read it:** database access rules restrict every row to the signed-in account that owns it. Data is encrypted in transit (HTTPS).
- **Your account is a username and a password, nothing else.** No e-mail address or phone number is collected and no e-mail is sent. To fit the authentication service the app turns your
  username into a private identifier `username@stationx.local`, which cannot receive mail and is never shown.
- **Password:** sent to the authentication service only to create the account or sign in; never stored or logged by the app; the service keeps only a one-way hash.
- **No password recovery:** because no e-mail is kept, a forgotten password cannot be reset. Keep it somewhere safe.
- **Deletion:** deleting an item removes the row from the server immediately. "Delete all my data" removes all your training data; "Delete account" removes the login and everything in it.
- **Saving:** a change is shown as saved only after the server confirmed it. If the connection fails, the app says so and nothing is saved.

## 3. Optional health data (Health Connect / Apple Health, including Samsung Health data)
Everything here is **off by default**. StationX asks the operating system for access only after you open Profile › Health, read an explanation
and switch on a feature. Each feature is separate, can be switched off at any time, and asks only for the permissions it needs.
On Samsung phones, Samsung Health shares data with other apps through Health Connect (you enable that in Samsung Health › Settings › Health Connect);
StationX never talks to Samsung Health directly and uses no Samsung SDK.

- **Save workouts to Health Connect / Apple Health (write):** when you finish or edit a cardio session or strength workout, StationX saves one exercise
  session containing its type, the workout name or activity name, start time, duration, and **only** the distance and calories you logged yourself.
  Average heart rate, sets, reps and weights are never written. Editing a workout replaces the record StationX wrote; deleting it in StationX deletes that
  record. StationX can only remove records it created. Other apps (for example Samsung Health) can read what you saved, under their own policies.
  If the health store is unavailable, the save is queued on the device and retried; it never blocks logging.
- **Fill in heart rate and calories (read):** after a cardio session StationX can read heart-rate samples and calories from the health store for the
  session's time window and **suggest** an average heart rate and calories. Nothing is applied unless you confirm, and values you typed are never overwritten.
- **Connecting (read):** connecting lets StationX read exercise sessions that other apps or a watch recorded. Sleep and resting heart rate are read only if you turn on the separate sleep-and-recovery feature below.
- **Import workouts (read):** StationX lists exercise sessions recorded by other apps or a watch (the last 30 days by default; up to all available history if you
  allow the separate "read older data" permission), shows a preview, and adds only the ones you confirm: cardio sessions as cardio, and watch strength sessions as
  strength sessions with duration and calories only (no exercises or sets; marked "Imported from Health Connect"). If you also turn on **automatic import**, new
  workouts are added without a preview when the app opens. Existing sessions are never changed.
- **Sleep and recovery (read):** with the sleep-and-recovery feature on, StationX reads last night's sleep and your resting heart rate (the last 7 days) from the health store (including deep, light and REM stages) and shows them on the Today screen with a plain verdict (ready, take it easy, or rest) worked out on your device from your own numbers, plus the reasons. If no resting heart rate was recorded and the heart-rate feature is on, it is estimated from your heart rate during sleep. These values are read when you open Today, are kept in memory for a few minutes, are not stored, not uploaded and never written back.
- **Heart rate on workouts (read):** with the heart-rate feature on, StationX reads heart-rate samples to show your average and max heart rate on a finished workout,
  a recent heart rate while you train, and a heart-rate trend. Averages and max values are kept in the local choices file (see below), are not uploaded, and are
  never written back to the health store. Trend charts are read on demand and not stored.

Health data that is read is processed on your device only; StationX does not send it to its own servers, advertisers or any third party. The only way
it can leave the device is by being saved into your account as described in section 2, and only for sessions or values you have imported or accepted into your history.
A small local file remembers your choices, which records StationX wrote, queued operations and which records were imported; it is never uploaded.
Turn a feature off in the app and remove access in your device settings (Android: Health Connect › App permissions; iOS: Settings › Health ›
Data Access & Devices › StationX). Records already saved to the health store stay there until you delete them in that app.

## 4. What StationX does not do
- It contains **no analytics, advertising, tracking or third-party crash-reporting** SDKs.
- It does not sell your data.

## 5. Exporting, deleting, and your choices
- **Export:** Profile › Export copies a JSON or CSV of your training data to your clipboard.
- **Import from Gym Tracker:** Profile › Import from Gym Tracker reads a file you choose (or pasted text, up to 10 MB), shows a preview, and adds the completed workouts to your account, creating custom exercises for unknown names. Existing data is never changed.
- **Log out:** removes your data from the phone (the draft is discarded); your data stays in your account.
- **Delete all my data:** Profile › *Delete all my data* permanently removes your workouts, sessions, cardio, goals and custom exercises from the server.
- **Delete your account:** Profile › *Delete account* permanently removes the account (username and password hash) and everything stored in it. Public deletion page: `docs/web/delete-account.html`.
Because deleted data cannot be recovered, export first if you may want it later.

## 6. Retention
Account data stays on the server until you delete it or the account. The device keeps only the temporary state in section 1. We keep no other copy of your data.

## 7. Children
StationX is a general fitness tool and is not directed at children under 13. It does not knowingly collect personal information from children. The app is intended for users aged 13 and over.

## 8. Changes to this policy
If the way the app handles data changes, this policy will be updated and the effective date changed.

## 9. Contact
[CONTACT EMAIL — fill in]
