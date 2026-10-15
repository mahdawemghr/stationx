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
    (
      'Your data lives in your account',
      'Workouts, cardio sessions, goals, personal records, custom exercises and settings are saved to a private online account (Supabase). StationX needs an internet connection to load and save them. There are no analytics, no ads and no tracking.',
    ),
    (
      'Who can read it',
      'Access rules in the database let only the signed-in account that owns a row read or change it. Data is encrypted in transit (HTTPS). Logging out removes your data from the phone; logging in loads it again.',
    ),
    (
      'What stays on this phone',
      'Only temporary things: the workout you are recording right now (so a lost connection or a closed app does not lose it until you finish) and, if you opt in, the Health Connect setting. A draft is discarded when you log out.',
    ),
    (
      'Your password',
      'Your password is sent to the server only to sign you in. StationX never stores it on the device and never logs it. There is no e-mail, so a forgotten password cannot be reset.',
    ),
    (
      'Optional health data',
      'If you choose to connect Health Connect (Android) or Apple Health (iOS), StationX READS the workouts recorded there (and, if you turn it on, heart rate during them) so you can import them. It never writes to those apps unless you turn that on, keeps the values only in memory while the app is running, and never shares them. Sleep and resting heart rate are read only if you turn on the separate "Show sleep & recovery on Today" switch; they are shown on Today, not stored and never shared. You can disconnect at any time.',
    ),
    (
      'Export and sharing',
      'Nothing is shared unless you export it yourself (Profile › Export). Exports are saved as a file you choose (or copied to your clipboard) and are yours to place anywhere.',
    ),
    (
      'Deleting your data',
      'Profile › Delete all my data removes your workouts, cardio and goals from your account. Profile › Delete account permanently removes your login and everything in it from the server.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxScaffold(
      topBar: const SxTopBar(title: 'Privacy', subtitle: 'ONLINE ACCOUNT'),
      gap: SxSpace.md,
      children: [
        for (final (title, body) in sections)
          SxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SxText.headlineSm.copyWith(color: c.textHigh),
                ),
                const SizedBox(height: 6),
                Text(body, style: SxText.bodyMd.copyWith(color: c.textBody)),
              ],
            ),
          ),
      ],
    );
  }
}
