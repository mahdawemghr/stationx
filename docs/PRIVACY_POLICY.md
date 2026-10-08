# StationX — Privacy Policy

_Effective date: [YYYY-MM-DD — fill in before publishing]_
_Contact: [your contact email — fill in before publishing]_

> **Owner action required:** this draft accurately describes how the app is built today. Fill in the two
> placeholders, have it reviewed if you need legal assurance, and host it at a public HTTPS URL (the Google Play
> and App Store listings require one). Keep it in sync with `lib/features/profile/privacy_page.dart` and the
> store privacy forms (see `docs/RELEASE.md`). If data handling changes, update this policy FIRST.

StationX is a local-first strength and cardio tracker. It works fully offline. **Cloud backup is optional and off
by default.** This policy explains what the app stores, what it uploads (only if you opt in), and your choices.

## 1. Data stored on your device (always)
StationX stores the following in a database on your device:
- your profile and settings (name, an optional email for the local profile, body measurements you enter, units, preferences);
- your workouts and routines, the rotation position, logged sets / repetitions / weights, cardio sessions, goals,
  personal records and custom exercises or activities, with the dates you trained and notes you write.

Without a cloud account, **nothing leaves your device and the app makes no network requests.**
Your data is **not backed up by Android** (Auto Backup and device-to-device transfer are turned off for this app), so it is not copied
to your Google account. **Uninstalling the app removes everything stored on the device.** The local profile on the device is **not password protected**;
anyone who can unlock your phone and open the app can see it.

## 2. Optional cloud backup & sync (only if you sign in)
If you choose **Profile › Cloud backup & sync › Sign in or create account**, StationX uploads the data listed in section 1
(except anything marked "never uploaded" below) to a private cloud account so you can back it up and use more than one device.
- **What is uploaded (synced fields):** profile & settings (name, body measurements, units, theme, default sets/reps/rest, progression setting,
  **weekly session target**); your **training schedule** (workouts/routine days with their exercises, sets and rep ranges, cardio finishers, and the rotation position);
  workout and cardio history (dates trained, sets, weights, repetitions, RPE, durations, distances, heart-rate values you typed, **notes**), goals,
  **custom exercises** (names, muscles, equipment, instructions, **custom muscle targets**) and custom cardio activities, plus your account email
  (and the name you enter when creating the account). Imported workouts are uploaded like any other workout.
- **Never uploaded by StationX as health data:** your password (see below), the sleep / resting-heart-rate summary, and the built-in demo/sample data. Note: if you use the optional health features in section 3, a workout you **import** from Health Connect / Apple Health becomes an ordinary StationX cardio session, and heart-rate or calorie values you **accept** into a session become session data; with cloud sync ON these sync like any other session.
- **Where it is stored:** the cloud database is hosted by Supabase (PostgreSQL, region: Asia-Pacific / Tokyo). Supabase acts as our
  service provider; we do not sell your data or share it with advertisers or other third parties.
- **Who can read it:** access rules in the database restrict every row to the signed-in account that owns it. Data is encrypted in transit (HTTPS).
- **Your password:** it is sent to the authentication service only to create the account or sign in. StationX never stores or logs it;
  the service stores only a one-way hash.
- **Deleted items:** when you delete a workout, session, exercise or goal while signed in, the cloud copy is marked deleted and its content
  (names, notes, exercise logs) is erased from the cloud at the same time; only an empty marker with its id and timestamps remains until you delete the
  whole cloud account. [Applies once the server hardening migration `20261010000000_hardening.sql` is applied.]
- **Sync behaviour:** changes upload automatically while you are signed in and online; if you are offline they wait on the device and upload later.
  If you edit the same item on two devices, the most recent edit wins.

## 3. Optional health data (Health Connect / Apple Health, including Samsung Health data)
Everything here is **off by default**. StationX asks the operating system for access only after you open Profile › Health, read an explanation
and switch on a feature. Each feature is separate, can be switched off at any time, and asks only for the permissions it needs.
On Samsung phones, Samsung Health shares data with other apps through Health Connect (you enable that in Samsung Health › Settings › Health Connect);
StationX never talks to Samsung Health directly and uses no Samsung SDK.

- **Recovery summary (read):** sleep and resting heart rate, shown on the home screen. Kept in memory while the app runs; not saved, not uploaded.
- **Save workouts to Health Connect / Apple Health (write):** when you finish or edit a cardio session or strength workout, StationX saves one exercise
  session containing its type, the workout name or activity name, start time, duration, and **only** the distance and calories you logged yourself.
  Average heart rate, sets, reps and weights are never written. Editing a workout replaces the record StationX wrote; deleting it in StationX deletes that
  record. StationX can only remove records it created. Other apps (for example Samsung Health) can read what you saved, under their own policies.
  If the health store is unavailable, the save is queued on the device and retried; it never blocks logging.
- **Fill in heart rate and calories (read):** after a cardio session StationX can read heart-rate samples and calories from the health store for the
  session's time window and **suggest** an average heart rate and calories. Nothing is applied unless you confirm, and values you typed are never overwritten.
- **Import workouts (read):** StationX lists exercise sessions recorded by other apps or a watch in the last 30 days (up to 90 where the platform allows),
  shows a preview, and adds only the ones you confirm as cardio sessions (marked "Imported from Health Connect"). Strength history is never changed.

Health data that is read is processed on your device only; StationX does not send it to its own servers, advertisers or any third party. The only way
it can leave the device is the cloud sync described in section 2, and only for sessions or values you have imported or accepted into your history.
A small local file remembers your choices, which records StationX wrote, queued operations and which records were imported; it is never uploaded.
Turn a feature off in the app and remove access in your device settings (Android: Health Connect › App permissions; iOS: Settings › Health ›
Data Access & Devices › StationX). Records already saved to the health store stay there until you delete them in that app.

## 4. What StationX does not do
- It contains **no analytics, advertising, tracking or third-party crash-reporting** SDKs.
- It does not sell your data.

## 5. Exporting, deleting, and your choices
- **Export:** Profile › Export copies a JSON or CSV of your training data to your clipboard.
- **Import from Gym Tracker:** Profile › Import from Gym Tracker reads a file you choose (or text you paste, up to 10 MB) on your device and adds the completed workouts in it to your history, creating custom exercises for unknown names. It shows a preview first, never changes or deletes existing data, and shortens over-long names/notes to safe limits. Nothing is uploaded by the import itself; imported workouts follow the same rules as any other data (they sync only if you turned cloud sync on).
- **Sign out of cloud sync:** your data stays on the device (it is **not** erased) and nothing more is uploaded. If your sign-in expires or is revoked, the app signs you out the same way.
- **Delete your cloud account and all cloud data:** Profile › Cloud backup & sync › *Delete cloud account & data*. This permanently removes the
  account and everything stored in it; data on your device is kept. [Owner: also provide a public web page/email for account deletion requests — required by Google Play.]
- **Delete data on the device:** Profile › *Delete all local data* (and, if you are signed in, it also turns cloud sync off on that device).
  Uninstalling the app removes everything stored on the device.
Because deleted data cannot be recovered, export first if you may want it later.

## 6. Children
StationX is a general fitness tool and is not directed at children under 13. It does not knowingly collect personal information from children.

## 7. Changes to this policy
If the way the app handles data changes, this policy will be updated and the effective date changed.

## 8. Contact
[your contact email]
