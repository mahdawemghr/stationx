import 'package:flutter/material.dart';

import '../core/theme/sx_colors.dart';
import '../core/theme/sx_theme.dart';
import '../core/theme/sx_typography.dart';
import '../core/widgets/widgets.dart';

/// Shown instead of a crash when the local database cannot be opened.
/// Offers a retry, and — after an explicit confirmation — a reset of the
/// database files (which deletes all local data).
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.onRetry, required this.onReset});

  final Future<void> Function() onRetry;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildStationXTheme(SxColors.obsidian),
      home: Builder(builder: (context) {
        final c = context.sx;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const SxLogo(size: 64),
                    const SizedBox(height: 24),
                    Text("Couldn't open your data", textAlign: TextAlign.center, style: SxText.headlineMd.copyWith(color: c.textHigh)),
                    const SizedBox(height: 8),
                    Text(
                      'StationX could not open its local database. Your data has not been changed. Try again; if it keeps failing you can reset the local database, which deletes all workouts and history on this device.',
                      textAlign: TextAlign.center,
                      style: SxText.bodyMd.copyWith(color: c.textBody),
                    ),
                    const SizedBox(height: 24),
                    SxButton(label: 'Try again', icon: Icons.refresh, onPressed: () => onRetry()),
                    const SizedBox(height: 8),
                    SxButton(
                      label: 'Reset local data',
                      variant: SxButtonVariant.ghost,
                      onPressed: () async {
                        final ok = await showSxConfirm(
                          context,
                          title: 'Reset local data?',
                          message: 'This permanently deletes every workout, cardio session, goal and setting stored on this device. It cannot be undone.',
                          confirmLabel: 'Delete everything',
                          destructive: true,
                          icon: Icons.delete_forever,
                        );
                        if (ok) await onReset();
                      },
                    ),
                  ]),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
