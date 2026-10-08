import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/health/health_gateway.dart';
import '../../data/health/health_sync_service.dart';
import '../../domain/domain.dart';
import 'health_actions.dart';

/// "Health & workouts": three independent, opt-in switches for Health Connect / Apple Health.
class HealthSyncSettingsPage extends StatefulWidget {
  const HealthSyncSettingsPage({super.key});

  @override
  State<HealthSyncSettingsPage> createState() => _HealthSyncSettingsPageState();
}

class _HealthSyncSettingsPageState extends State<HealthSyncSettingsPage> {
  GatewayAvailability? _availability;
  bool _retrying = false;
  HealthFeature? _busy;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final sync = context.app.healthSync;
    GatewayAvailability a;
    try {
      a = await sync.availability();
    } catch (_) {
      a = GatewayAvailability.unsupported;
    }
    if (mounted) setState(() => _availability = a);
    await sync.refreshPermissions();
  }

  Future<void> _toggle(HealthFeature f, bool on) async {
    final sync = context.app.healthSync;
    if (!on) {
      await sync.disable(f);
      return;
    }
    setState(() => _busy = f);
    try {
      await enableHealthFeature(context, f);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    final sync = context.app.healthSync;
    try {
      await sync.refreshPermissions();
      await sync.retryPending();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.app.healthSync;
    final c = context.sx;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final p = sync.provider;
        final a = _availability;
        final ready = a == GatewayAvailability.available;
        return SxScaffold(
          topBar: const SxTopBar(title: 'Health & workouts', subtitle: 'INTEGRATIONS'),
          gap: SxSpace.md,
          children: [
            SxStagger(index: 0, child: _ProviderCard(provider: p, availability: a, onInstall: () => context.app.health.installProvider())),
            if (a != null && a != GatewayAvailability.unsupported)
              SxStagger(
                index: 1,
                child: SxCard(
                  padding: const EdgeInsets.symmetric(horizontal: SxSpace.md, vertical: SxSpace.sm),
                  child: Column(children: [
                    for (final (i, f) in HealthFeature.values.indexed) ...[
                      if (i > 0) Divider(height: 1, color: c.hairline),
                      _FeatureRow(
                        key: ValueKey('health-switch-${f.name}'),
                        title: healthFeatureTitle(f, p),
                        description: _description(f),
                        value: sync.isEnabled(f),
                        busy: _busy == f,
                        enabled: ready && _busy == null,
                        onChanged: (v) => _toggle(f, v),
                      ),
                    ],
                  ]),
                ),
              ),
            if (ready && sync.isEnabled(HealthFeature.importWorkouts))
              SxStagger(
                index: 2,
                child: SxButton(
                  label: 'Import workouts now',
                  icon: Icons.download_outlined,
                  variant: SxButtonVariant.secondary,
                  height: 48,
                  onPressed: () => AppNav.healthImport(context),
                ),
              ),
            if (ready && HealthFeature.values.any(sync.isEnabled))
              SxStagger(index: 3, child: _StatusCard(sync: sync, retrying: _retrying, onRetry: _retry)),
            SxStagger(index: 4, child: _Notes(provider: p)),
          ],
        );
      },
    );
  }

  static String _description(HealthFeature f) => switch (f) {
        HealthFeature.writeWorkouts =>
          'Saves each new or edited workout: its type, start and end time, plus distance and calories only if you logged them. Never heart rate.',
        HealthFeature.enrichCardio =>
          'After a cardio session, suggests the average heart rate and calories from your watch. You confirm first and only empty fields are filled.',
        HealthFeature.importWorkouts =>
          'Brings in cardio workouts recorded by other apps. You preview them first and nothing is added until you confirm.',
      };
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.availability, required this.onInstall});
  final HealthProvider provider;
  final GatewayAvailability? availability;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final name = provider == HealthProvider.none ? 'Health' : provider.label;
    final (String line, IconData icon, Color color) = switch (availability) {
      null => ('Checking...', Icons.hourglass_empty, c.textMuted),
      GatewayAvailability.unsupported => ('Not available on this device', Icons.block, c.textMuted),
      GatewayAvailability.notInstalled => ('$name is not installed', Icons.download_for_offline_outlined, c.textHigh),
      GatewayAvailability.available => ('Ready', Icons.check_circle_outline, c.primary),
    };
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md)),
            child: Icon(Icons.monitor_heart_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: SxText.bodyLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
              SxSwap(
                alignment: Alignment.centerLeft,
                child: Row(key: ValueKey(availability), children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(child: Text(line, style: SxText.bodySm.copyWith(color: c.textBody))),
                ]),
              ),
            ]),
          ),
        ]),
        if (provider == HealthProvider.healthConnect) ...[
          const SizedBox(height: SxSpace.sm),
          Text(
            'Samsung Health shares data through Health Connect. Turn on Health Connect sync inside Samsung Health.',
            style: SxText.bodySm.copyWith(color: c.textBody),
          ),
        ],
        if (availability == GatewayAvailability.notInstalled) ...[
          const SizedBox(height: SxSpace.md),
          SxButton(label: 'Install $name', icon: Icons.download_outlined, height: 48, onPressed: onInstall),
        ],
        if (availability == GatewayAvailability.unsupported) ...[
          const SizedBox(height: SxSpace.sm),
          Text('StationX works fully without it. Your workouts stay on this phone.', style: SxText.bodySm.copyWith(color: c.textBody)),
        ],
      ]),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.busy,
    required this.enabled,
    required this.onChanged,
  });
  final String title;
  final String description;
  final bool value;
  final bool busy;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      container: true,
      toggled: value,
      label: title,
      hint: description,
      onTap: enabled ? () => onChanged(!value) : null,
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: SxSpace.sm),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: SxText.bodyLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(description, style: SxText.bodySm.copyWith(color: c.textBody)),
                ]),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 52,
                height: 48,
                child: Center(
                  child: busy
                      ? const SxSpinner(size: 20)
                      : ExcludeSemantics(
                          child: Switch(
                            value: value,
                            onChanged: enabled ? onChanged : null,
                            activeThumbColor: c.canvas,
                            activeTrackColor: c.primary,
                          ),
                        ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.sync, required this.retrying, required this.onRetry});
  final HealthSyncService sync;
  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final pending = sync.pendingCount;
    final last = sync.lastSuccessAt;
    final issue = sync.issue;
    final writes = sync.isEnabled(HealthFeature.writeWorkouts);
    final (String headline, Color color) = switch (issue) {
      HealthSyncIssue.needsPermission => ('Permission needed', c.textHigh),
      HealthSyncIssue.retrying => ('Could not sync yet. StationX will try again.', c.textHigh),
      HealthSyncIssue.none => pending > 0 ? ('Waiting to sync', c.textHigh) : ('Everything is up to date', c.primary),
    };
    final lines = <String>[
      if (issue == HealthSyncIssue.needsPermission)
        healthFeatureDeniedMessage(sync.provider).replaceFirst('Nothing was turned on. T', 'T'),
      if (pending > 0) '$pending ${pending == 1 ? 'workout is' : 'workouts are'} waiting to sync. Will retry.',
      if (writes) '${sync.savedCount} saved by StationX',
      if (last != null) 'Last synced ${Fmt.relativeDay(last)} at ${Fmt.time(last)}',
    ];
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STATUS', style: SxText.labelCaps.copyWith(color: c.textBody)),
        const SizedBox(height: 6),
        SxSwap(
          alignment: Alignment.centerLeft,
          child: Column(
            key: ValueKey('$issue-$pending'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(liveRegion: true, child: Text(headline, style: SxText.bodyLg.copyWith(color: color, fontWeight: FontWeight.w600))),
              for (final l in lines) Padding(padding: const EdgeInsets.only(top: 4), child: Text(l, style: SxText.bodySm.copyWith(color: c.textBody))),
            ],
          ),
        ),
        if (issue != HealthSyncIssue.none || pending > 0) ...[
          const SizedBox(height: SxSpace.md),
          SxButton(
            label: issue == HealthSyncIssue.needsPermission ? 'Check again' : 'Retry now',
            icon: Icons.refresh,
            variant: SxButtonVariant.secondary,
            height: 48,
            loading: retrying,
            onPressed: retrying ? null : onRetry,
          ),
        ],
      ]),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.provider});
  final HealthProvider provider;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final name = provider == HealthProvider.none ? 'your health app' : provider.label;
    final style = SxText.bodySm.copyWith(color: c.textBody);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Removing a workout in StationX also removes the copy it saved. Copies already in $name can be deleted there.', style: style),
        const SizedBox(height: 8),
        Text('Everything is off until you turn it on. Your data stays on this device, and you can turn any switch off at any time.', style: style),
      ]),
    );
  }
}
