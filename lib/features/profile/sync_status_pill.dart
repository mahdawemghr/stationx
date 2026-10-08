import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/sync/cloud_sync_controller.dart';

/// Plain-language sync state shown in the top bar pill.
enum SyncBadge { local, synced, syncing, offline, needsAttention }

SyncBadge syncBadgeFor(CloudSyncController cloud) {
  switch (cloud.phase) {
    case CloudSyncPhase.unavailable:
    case CloudSyncPhase.signedOut:
      return SyncBadge.local;
    case CloudSyncPhase.syncing:
      return SyncBadge.syncing;
    case CloudSyncPhase.error:
      return cloud.problem == CloudSyncProblem.offline ? SyncBadge.offline : SyncBadge.needsAttention;
    case CloudSyncPhase.idle:
      return SyncBadge.synced;
  }
}

String syncBadgeLabel(SyncBadge b) => switch (b) {
      SyncBadge.local => 'Local',
      SyncBadge.synced => 'Synced',
      SyncBadge.syncing => 'Syncing',
      SyncBadge.offline => 'Offline',
      SyncBadge.needsAttention => 'Needs attention',
    };

/// Top-bar pill that reflects the real cloud state (Local / Synced / Syncing /
/// Offline / Needs attention). Reusable by Today / SxBrandBar.
class SyncStatusPill extends StatelessWidget {
  const SyncStatusPill({super.key});

  @override
  Widget build(BuildContext context) {
    final cloud = context.app.cloud;
    final c = context.sx;
    return ListenableBuilder(
      listenable: cloud,
      builder: (context, _) {
        final b = syncBadgeFor(cloud);
        final color = switch (b) {
          SyncBadge.local || SyncBadge.synced => c.primary,
          SyncBadge.syncing => c.textBody,
          SyncBadge.offline => c.textMuted,
          SyncBadge.needsAttention => c.danger,
        };
        return StatusPill(syncBadgeLabel(b), dot: true, color: color);
      },
    );
  }
}
