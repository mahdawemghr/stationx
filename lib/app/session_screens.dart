import 'package:flutter/material.dart';

import '../core/theme/sx_theme.dart';
import '../core/theme/sx_typography.dart';
import '../core/widgets/widgets.dart';
import '../data/remote/remote_exception.dart';
import 'app_scope.dart';

/// Full-screen state while the saved session is restored / the user's data is loaded.
class SessionSplash extends StatelessWidget {
  const SessionSplash({super.key, this.label = 'Loading your training…'});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Scaffold(
      backgroundColor: c.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SxLogo(size: 64),
            const SizedBox(height: 24),
            SxSpinner(size: 24, color: c.primary, semanticLabel: label),
            const SizedBox(height: 16),
            Text(label, style: SxText.bodyMd.copyWith(color: c.textBody)),
          ],
        ),
      ),
    );
  }
}

/// Signed in, but the data could not be loaded. Retry, or log out (never shows stale/other data).
class LoadFailedScreen extends StatefulWidget {
  const LoadFailedScreen({super.key});

  @override
  State<LoadFailedScreen> createState() => _LoadFailedScreenState();
}

class _LoadFailedScreenState extends State<LoadFailedScreen> {
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    await context.app.retryLoad();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final e = context.app.loadError;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    e?.kind == RemoteFailure.offline
                        ? Icons.cloud_off_outlined
                        : Icons.error_outline,
                    size: 48,
                    color: c.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Couldn't load your data",
                    textAlign: TextAlign.center,
                    style: SxText.headlineMd.copyWith(color: c.textHigh),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e?.userMessage ?? 'Something went wrong. Please try again.',
                    textAlign: TextAlign.center,
                    style: SxText.bodyMd.copyWith(color: c.textBody),
                  ),
                  const SizedBox(height: 24),
                  SxButton(
                    label: 'Try again',
                    icon: Icons.refresh,
                    loading: _busy,
                    onPressed: _busy ? null : _retry,
                  ),
                  const SizedBox(height: 8),
                  SxButton(
                    label: 'Log out',
                    variant: SxButtonVariant.ghost,
                    onPressed: _busy ? null : () => context.app.signOut(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
