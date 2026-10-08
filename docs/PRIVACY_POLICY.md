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

## 2. Optional cloud backup & sync (only if you sign in)
If you choose **Profile › Cloud backup & sync › Sign in or create account**, StationX uploads the data listed in section 1
(except anything marked "never uploaded" below) to a private cloud account so you can back it up and use more than one device.
- **What is uploaded:** profile & settings, workouts/routines and rotation position, workout and cardio history, goals,
  custom exercises/activities, with their dates and notes, plus your account email (and the name you enter when creating the account).
- **Never uploaded:** your password (see below), data from Health Connect / Apple Health, and the built-in demo/sample data.
- **Where it is stored:** the cloud database is hosted by Supabase (PostgreSQL, region: Asia-Pacific / Tokyo). Supabase acts as our
  service provider; we do not sell your data or share it with advertisers or other third parties.
- **Who can read it:** access rules in the database restrict every row to the signed-in account that owns it. Data is encrypted in transit (HTTPS).
- **Your password:** it is sent to the authentication service only to create the account or sign in. StationX never stores or logs it;
  the service stores only a one-way hash.
- **Sync behaviour:** changes upload automatically while you are signed in and online; if you are offline they wait on the device and upload later.
  If you edit the same item on two devices, the most recent edit wins.

## 3. Optional health data (Health Connect / Apple Health)
If — and only if — you choose "Connect", StationX asks the operating system for **read-only** access to **sleep** and **resting heart rate**
to show a recovery summary. StationX never writes to these services. The values are kept in memory while the app runs; they are **not saved,
not uploaded and not shared**, even if cloud sync is on. Disconnect any time in the app (Profile) and remove access in your device settings
(Android: Health Connect › App permissions; iOS: Settings › Health › Data Access & Devices › StationX).

## 4. What StationX does not do
- It contains **no analytics, advertising, tracking or third-party crash-reporting** SDKs.
- It does not sell your data.

## 5. Exporting, deleting, and your choices
- **Export:** Profile › Export copies a JSON or CSV of your training data to your clipboard.
- **Import from Gym Tracker:** Profile › Import from Gym Tracker reads a file you choose (or text you paste) on your device and adds the completed workouts in it to your history. Nothing is uploaded by the import itself; imported workouts follow the same rules as any other data (they sync only if you turned cloud sync on).
- **Sign out of cloud sync:** your data stays on the device; nothing more is uploaded.
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
