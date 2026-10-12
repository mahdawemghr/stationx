import 'package:flutter/material.dart';

import '../core/theme/sx_colors.dart';
import '../core/theme/sx_theme.dart';
import '../core/theme/sx_typography.dart';
import '../core/widgets/widgets.dart';

/// Shown instead of a crash when the app cannot start: the Supabase configuration is missing, the
/// client could not initialise, or the small device database (draft + preferences, never your
/// workouts) cannot be opened. The reset option only exists for the database case and only deletes
/// that device-local state.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.onRetry, this.onReset})
    : title = "Couldn't start StationX",
      message =
          'StationX could not start. Check your connection and try again.';

  /// Build without the Supabase URL / publishable key: nothing to retry.
  const StartupErrorApp.notConfigured({super.key})
    : onRetry = null,
      onReset = null,
      title = 'StationX is not configured',
      message =
          'The server configuration of this build is invalid. Check SUPABASE_URL and '
          'SUPABASE_ANON_KEY (publishable key only) in env/supabase.json (see supabase/README.md).';

  final String title;
  final String message;
  final Future<void> Function()? onRetry;
  final Future<void> Function()? onReset;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildStationXTheme(SxColors.obsidian),
      home: Builder(
        builder: (context) {
          final c = context.sx;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SxLogo(size: 64),
                        const SizedBox(height: 24),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: SxText.headlineMd.copyWith(color: c.textHigh),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: SxText.bodyMd.copyWith(color: c.textBody),
                        ),
                        if (onRetry != null) ...[
                          const SizedBox(height: 24),
                          SxButton(
                            label: 'Try again',
                            icon: Icons.refresh,
                            onPressed: () => onRetry!(),
                          ),
                        ],
                        if (onReset != null) ...[
                          const SizedBox(height: 8),
                          SxButton(
                            label: 'Reset device storage',
                            variant: SxButtonVariant.ghost,
                            onPressed: () async {
                              final ok = await showSxConfirm(
                                context,
                                title: 'Reset device storage?',
                                message:
                                    'Deletes the unfinished-workout draft and preferences stored on this device. '
                                    'Your account data on the server is not affected.',
                                confirmLabel: 'Reset',
                                destructive: true,
                                icon: Icons.delete_forever,
                              );
                              if (ok) await onReset!();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
