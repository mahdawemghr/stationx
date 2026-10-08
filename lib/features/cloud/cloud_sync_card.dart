import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/sync/cloud_sync_controller.dart';
import 'cloud_auth_page.dart';
import 'cloud_strings.dart';

/// Profile › Integrations: optional cloud backup & sync. Hidden when the build has no cloud config.
class CloudSyncCard extends StatelessWidget {
  const CloudSyncCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ctl = context.app.cloud;
    return ListenableBuilder(
      listenable: ctl,
      builder: (context, _) {
        if (ctl.phase == CloudSyncPhase.unavailable) return const SizedBox.shrink();
        final c = context.sx;
        final signedIn = ctl.user != null;
        final (String subtitle, Color color) = _status(ctl, c.textBody, c.danger, c.primary);
        return Padding(
          padding: const EdgeInsets.only(bottom: SxSpace.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md), border: Border.all(color: c.hairline)),
                child: Icon(signedIn ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, color: signedIn ? c.primary : c.textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cloud backup & sync', style: SxText.bodyLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
                  Text(signedIn ? ctl.user!.email : 'Off — your data stays on this device', style: SxText.bodySm.copyWith(color: c.textBody)),
                ]),
              ),
            ]),
            if (signedIn) ...[
              const SizedBox(height: 10),
              Semantics(
                liveRegion: true,
                child: Row(children: [
                  if (ctl.phase == CloudSyncPhase.syncing)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: c.primary)),
                    ),
                  Expanded(child: Text(subtitle, style: SxText.bodySm.copyWith(color: color))),
                ]),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: SxButton(
                    label: 'Sync now',
                    icon: Icons.sync,
                    variant: SxButtonVariant.secondary,
                    height: 48,
                    onPressed: ctl.phase == CloudSyncPhase.syncing ? null : () => ctl.syncNow(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SxButton(
                    label: 'Sign out',
                    variant: SxButtonVariant.ghost,
                    height: 48,
                    onPressed: () async {
                      await ctl.signOut();
                      if (context.mounted) showSxSnack(context, 'Signed out of cloud sync. Data stays on this device.');
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => _deleteAccount(context, ctl),
                  child: Text('Delete cloud account & data', style: SxText.bodyMd.copyWith(color: c.danger, fontWeight: FontWeight.w600)),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                'Optional. Back up your training and sync it across devices with a private account. '
                'Nothing is uploaded until you sign in.',
                style: SxText.bodySm.copyWith(color: c.textBody),
              ),
              const SizedBox(height: 10),
              SxButton(
                label: 'Sign in or create account',
                icon: Icons.cloud_upload_outlined,
                variant: SxButtonVariant.secondary,
                height: 48,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<bool>(builder: (_) => const CloudAuthPage())),
              ),
            ],
          ]),
        );
      },
    );
  }

  (String, Color) _status(CloudSyncController ctl, Color body, Color danger, Color ok) {
    switch (ctl.phase) {
      case CloudSyncPhase.syncing:
        return ('Syncing…', body);
      case CloudSyncPhase.error:
        return (cloudProblemMessage(ctl.problem ?? CloudSyncProblem.server), danger);
      default:
        final parts = <String>[
          if (ctl.lastSyncAt != null) 'Synced ${timeAgo(ctl.lastSyncAt!)}' else 'Not synced yet',
          if (ctl.pending > 0) '${ctl.pending} change${ctl.pending == 1 ? '' : 's'} waiting to upload',
        ];
        return (parts.join(' · '), ctl.pending > 0 ? body : ok);
    }
  }

  Future<void> _deleteAccount(BuildContext context, CloudSyncController ctl) async {
    final ok = await showSxConfirm(
      context,
      title: 'Delete cloud account?',
      message: 'This permanently deletes your cloud account and every backup stored in it. '
          'Workouts and history on THIS device are kept. This cannot be undone.',
      confirmLabel: 'Delete account',
      destructive: true,
      icon: Icons.delete_forever,
    );
    if (!ok || !context.mounted) return;
    final r = await ctl.deleteCloudAccount();
    if (!context.mounted) return;
    showSxSnack(context, r.ok ? 'Cloud account deleted. Your data on this device is unchanged.' : cloudAuthMessage(r.status),
        icon: r.ok ? Icons.check_circle : Icons.error_outline);
  }
}
