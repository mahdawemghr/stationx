import 'package:flutter/material.dart';

import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';

/// In-app privacy summary. Keep in sync with docs/PRIVACY_POLICY.md (the full
/// policy text that must also be hosted at a public URL for the stores).
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const sections = <(String, String)>[
    ('Your data stays on your device',
        'Workouts, cardio sessions, goals, personal records and settings are stored in a database on this device. StationX works fully offline, with no analytics, no ads and no tracking.'),
    ('Optional cloud backup',
        'Only if you choose to sign in under Profile › Cloud backup & sync, your training data (workouts, sessions, goals, custom exercises and settings) is uploaded to a private cloud account so you can back it up and use more than one device. It is protected so only your account can read it. Until you sign in, the app makes no network requests. You can sign out at any time, and delete your cloud account and all its data from the same screen.'),
    ('Your password',
        'Your password is sent to the server only to sign you in. StationX never stores it on the device and never logs it.'),
    ('Optional health data',
        'If you choose to connect Health Connect (Android) or Apple Health (iOS), StationX READS your sleep and resting heart rate to show a recovery summary. It never writes to those apps, keeps the values only in memory while the app is running, and never shares them. You can disconnect at any time.'),
    ('Export and sharing',
        'Nothing is shared unless you export it yourself (Profile › Export). Exports are saved as a file you choose (or copied to your clipboard) and are yours to place anywhere.'),
    ('Deleting your data',
        'Profile › Delete all local data removes your workouts, cardio and goals from this phone. It keeps your name and email so you stay signed in. Uninstalling the app removes everything it stored.'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxScaffold(
      topBar: const SxTopBar(title: 'Privacy', subtitle: 'LOCAL-FIRST'),
      gap: SxSpace.md,
      children: [
        for (final (title, body) in sections)
          SxCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: SxText.headlineSm.copyWith(color: c.textHigh)),
              const SizedBox(height: 6),
              Text(body, style: SxText.bodyMd.copyWith(color: c.textBody)),
            ]),
          ),
      ],
    );
  }
}
