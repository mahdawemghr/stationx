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
        'Workouts, cardio sessions, goals, personal records and settings are stored in a database on this device only. StationX has no server, no account system and no analytics.'),
    ('No network',
        'StationX does not need an internet connection and does not send your data anywhere. The release app does not request the INTERNET permission.'),
    ('Optional health data',
        'If you choose to connect Health Connect (Android) or Apple Health (iOS), StationX READS your sleep and resting heart rate to show a recovery summary. It never writes to those apps, keeps the values only in memory while the app is running, and never shares them. You can disconnect at any time.'),
    ('Export and sharing',
        'Nothing is shared unless you export it yourself (Profile › Export). Exports are copied to your clipboard and are yours to place anywhere.'),
    ('Deleting your data',
        'Profile › Delete all local data removes your workouts, cardio and goals. Uninstalling the app removes everything it stored.'),
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
