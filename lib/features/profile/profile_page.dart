import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../app/app_version.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import '../cloud/cloud_sync_card.dart';
import '../health/health_actions.dart';
import '../landing/landing_page.dart';
import 'gym_tracker_import_flow.dart';
import 'privacy_page.dart';
import 'export_builder.dart';


/// Profile & settings tab (Stitch: profile_app_settings). Every control is
/// persisted through [ProfileRepository.update].
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.profile, app.sessions, app.workouts]),
      builder: (context, _) {
        final p = app.profile.profile;
        Future<void> save(UserProfile n) => app.profile.update(n);
        return SxScaffold(
          topBar: const SxTopBar(title: 'Profile', showBack: false, showLogo: true, pill: StatusPill('Local', dot: true)),
          gap: SxSpace.sm,
          padding: const EdgeInsets.fromLTRB(SxSpace.md, SxSpace.md, SxSpace.md, SxSpace.xl),
          children: [
            _IdentityCard(profile: p, sessionCount: app.sessions.sessions.length, rotation: app.workouts.rotation, onEdit: () => _editName(context, p, save)),
            const SizedBox(height: SxSpace.sm),
            SectionHeader('Your data', icon: Icons.straighten, trailingText: 'Tap to edit'),
            _MetricsRow(profile: p, onSave: save),
            const SizedBox(height: SxSpace.sm),
            const SectionHeader('Workout configuration', icon: Icons.tune),
            _WorkoutConfig(profile: p, onSave: save),
            const SizedBox(height: SxSpace.sm),
            const SectionHeader('Preferences', icon: Icons.palette_outlined),
            _Preferences(profile: p, onSave: save),
            const SizedBox(height: SxSpace.sm),
            const SectionHeader('Integrations & storage', icon: Icons.storage_outlined),
            _Integrations(
              onExport: () => _showExport(context, app.profile.profile, app.sessions.sessions, app.cardio.sessions),
            ),
            const SizedBox(height: SxSpace.sm),
            SectionHeader('App & safety', icon: Icons.terminal, trailing: const _VersionLabel()),
            _Safety(
              onPrivacy: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PrivacyPage())),
              onWipe: () async {
                final ok = await showSxConfirm(
                  context,
                  title: 'Delete all local data?',
                  message: app.cloud.user == null
                      ? 'This permanently removes every workout, cardio session and goal stored on this device. It cannot be undone.'
                      : 'This permanently removes every workout, cardio session and goal stored on THIS device and turns cloud sync off here. '
                          'Your cloud backup is kept — delete it separately under Cloud backup & sync. It cannot be undone.',
                  confirmLabel: 'Delete everything',
                  destructive: true,
                  icon: Icons.delete_forever,
                );
                if (ok && context.mounted) {
                  await app.wipeAllData();
                  if (context.mounted) showSxSnack(context, 'All local data deleted');
                }
              },
              onLoadDemo: () async {
                final ok = await showSxConfirm(
                  context,
                  title: 'Load demo data?',
                  message: 'Replaces ALL data on this device with about 8 weeks of sample workouts and cardio, so you can explore the app. Your profile is kept. This cannot be undone.',
                  confirmLabel: 'Replace with demo data',
                  destructive: true,
                  icon: Icons.science_outlined,
                );
                if (ok && context.mounted) {
                  await app.loadDemoData();
                  if (context.mounted) showSxSnack(context, 'Demo data loaded');
                }
              },
              onSignOut: () async {
                await app.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const LandingPage()), (_) => false);
              },
            ),
            const SizedBox(height: SxSpace.md),
            Center(
              child: Text('STATIONX • LOCAL-FIRST STRENGTH & CARDIO LOG',
                  textAlign: TextAlign.center, style: SxText.labelCaps.copyWith(color: context.sx.textMuted, fontSize: 10)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editName(BuildContext context, UserProfile p, Future<void> Function(UserProfile) save) async {
    final ctl = TextEditingController(text: p.name);
    final name = await showSxSheet<String>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(SxSpace.md),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SxTextField(label: 'Display name', controller: ctl, icon: Icons.person_outline, textInputAction: TextInputAction.done, onSubmitted: (v) => Navigator.pop(ctx, v)),
          const SizedBox(height: SxSpace.md),
          SxButton(label: 'Save', onPressed: () => Navigator.pop(ctx, ctl.text)),
        ]),
      ),
    );
    ctl.dispose();
    if (name != null && name.trim().isNotEmpty) await save(p.copyWith(name: name.trim()));
  }

  void _showExport(BuildContext context, UserProfile p, List<WorkoutSession> s, List<CardioSession> c) {
    showSxSheet<void>(context, builder: (_) => _ExportSheet(profile: p, sessions: s, cardio: c));
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile, required this.sessionCount, required this.rotation, required this.onEdit});
  final UserProfile profile;
  final int sessionCount;
  final Rotation rotation;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final (day, total) = RotationService.dayOf(rotation);
    return SxCard(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(children: [
        Row(children: [
          SxAvatar(profile.name, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(profile.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.headlineMd.copyWith(color: c.textHigh)),
              const SizedBox(height: 4),
              Text(profile.isGuest ? 'Guest · demo data' : (profile.email.isEmpty ? 'Local profile' : profile.email),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
          SxIconButton(icon: Icons.edit_outlined, tooltip: 'Edit name', onPressed: onEdit),
        ]),
        const SizedBox(height: SxSpace.md),
        Row(children: [
          Expanded(child: _MiniStat(icon: Icons.history, label: 'Sessions logged', value: '$sessionCount')),
          const SizedBox(width: 8),
          Expanded(child: _MiniStat(icon: Icons.sync_alt, label: 'Rotation', value: total == 0 ? '—' : 'Day $day / $total')),
        ]),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxInset(
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        Icon(icon, size: 20, color: c.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 9)),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: SxText.metricSm.copyWith(color: c.textHigh))),
          ]),
        ),
      ]),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.profile, required this.onSave});
  final UserProfile profile;
  final Future<void> Function(UserProfile) onSave;

  @override
  Widget build(BuildContext context) {
    final u = profile.unit;
    Future<void> edit(String title, double initial, String unit, double step, void Function(double) apply, {double? min, double? max, bool decimal = true}) async {
      final v = await showNumericKeypad(context, title: title, initial: initial, unit: unit, step: step, allowDecimal: decimal, min: min, max: max);
      if (v != null && v > 0) apply(v);
    }

    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        child: _MetricTile(
          label: 'Weight',
          value: Fmt.weight(profile.weightKg, u),
          unit: Fmt.unit(u),
          onTap: () => edit('Body weight', double.parse(Fmt.weight(profile.weightKg, u)), Fmt.unit(u), 0.5, (v) => onSave(profile.copyWith(weightKg: Fmt.fromDisplayWeight(v, u))), max: 400),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _MetricTile(
          label: 'Height',
          value: Fmt.number(profile.heightCm, decimals: 0),
          unit: 'cm',
          caption: _feetInches(profile.heightCm),
          onTap: () => edit('Height', profile.heightCm, 'cm', 1, (v) => onSave(profile.copyWith(heightCm: v)), max: 260, decimal: false),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _MetricTile(
          label: 'Age',
          value: '${profile.age}',
          unit: 'y/o',
          onTap: () => edit('Age', profile.age.toDouble(), 'years', 1, (v) => onSave(profile.copyWith(age: v.round())), max: 120, decimal: false),
        ),
      ),
    ]));
  }

  static String _feetInches(double cm) {
    final totalIn = (cm / 2.54).round();
    return '${totalIn ~/ 12}\'${totalIn % 12}"';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, required this.unit, required this.onTap, this.caption});
  final String label;
  final String value;
  final String unit;
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: SxText.metricLg.copyWith(color: c.textHigh)))),
          const SizedBox(width: 3),
          Text(unit, style: SxText.bodySm.copyWith(color: c.textBody)),
        ]),
        if (caption != null) Text(caption!, style: SxText.bodySm.copyWith(color: c.textMuted)),
      ]),
    );
  }
}

class _WorkoutConfig extends StatelessWidget {
  const _WorkoutConfig({required this.profile, required this.onSave});
  final UserProfile profile;
  final Future<void> Function(UserProfile) onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final p = profile;
    return SxCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        _Row(
          title: 'Default working sets',
          subtitle: 'Baseline for new exercises',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            _Step(icon: Icons.remove, label: 'Decrease sets', onTap: p.defaultSets > 1 ? () => onSave(p.copyWith(defaultSets: p.defaultSets - 1)) : null),
            SizedBox(width: 32, child: Center(child: Text('${p.defaultSets}', style: SxText.metricMd.copyWith(color: c.primary)))),
            _Step(icon: Icons.add, label: 'Increase sets', onTap: p.defaultSets < 10 ? () => onSave(p.copyWith(defaultSets: p.defaultSets + 1)) : null),
          ]),
        ),
        Divider(height: 1, color: c.hairline),
        _Row(
          title: 'Default rep window',
          subtitle: 'Target range for new exercises',
          onTap: () => _repWindow(context),
          trailing: SxInset(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text('${p.defaultRepMin} – ${p.defaultRepMax} REPS', style: SxText.metricSm.copyWith(color: c.textHigh))),
        ),
        Divider(height: 1, color: c.hairline),
        _Row(
          title: 'Progression engine',
          subtitle: 'Recommends weight & reps from your last session',
          trailing: Switch(
            value: p.progressionEnabled,
            onChanged: (v) => onSave(p.copyWith(progressionEnabled: v)),
            activeThumbColor: c.canvas,
            activeTrackColor: c.primary,
          ),
        ),
        Divider(height: 1, color: c.hairline),
        _Row(
          title: 'Auto rest timer',
          subtitle: 'Starts after each logged set',
          onTap: () => _rest(context),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            SxInset(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text('${p.autoRestSeconds}s', style: SxText.metricSm.copyWith(color: c.primary))),
            Icon(Icons.chevron_right, color: c.textMuted),
          ]),
        ),
        Divider(height: 1, color: c.hairline),
        _Row(
          title: 'Weekly session target',
          subtitle: 'Shown on Today',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            _Step(icon: Icons.remove, label: 'Decrease target', onTap: p.weeklySessionTarget > 1 ? () => onSave(p.copyWith(weeklySessionTarget: p.weeklySessionTarget - 1)) : null),
            SizedBox(width: 32, child: Center(child: Text('${p.weeklySessionTarget}', style: SxText.metricMd.copyWith(color: c.primary)))),
            _Step(icon: Icons.add, label: 'Increase target', onTap: p.weeklySessionTarget < 14 ? () => onSave(p.copyWith(weeklySessionTarget: p.weeklySessionTarget + 1)) : null),
          ]),
        ),
      ]),
    );
  }

  Future<void> _repWindow(BuildContext context) async {
    var lo = profile.defaultRepMin, hi = profile.defaultRepMax;
    final res = await showSxSheet<(int, int)>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.all(SxSpace.md),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('DEFAULT REP WINDOW', style: SxText.labelCaps.copyWith(color: ctx.sx.textBody)),
            const SizedBox(height: SxSpace.md),
            _Stepper(label: 'Min reps', value: lo, onChanged: (v) => set(() { lo = v.clamp(1, hi); })),
            const SizedBox(height: 8),
            _Stepper(label: 'Max reps', value: hi, onChanged: (v) => set(() { hi = v.clamp(lo, 50); })),
            const SizedBox(height: SxSpace.md),
            SxButton(label: 'Save', onPressed: () => Navigator.pop(ctx, (lo, hi))),
          ]),
        ),
      ),
    );
    if (res != null) await onSave(profile.copyWith(defaultRepMin: res.$1, defaultRepMax: res.$2));
  }

  Future<void> _rest(BuildContext context) async {
    final choice = await showSxSheet<int>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(SxSpace.md),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AUTO REST TIMER', style: SxText.labelCaps.copyWith(color: ctx.sx.textBody)),
          const SizedBox(height: SxSpace.md),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in const [45, 60, 90, 120, 150, 180, 240])
              SxChip(label: '${s}s', selected: s == profile.autoRestSeconds, onTap: () => Navigator.pop(ctx, s)),
            SxChip(
              label: 'Custom',
              icon: Icons.edit_outlined,
              onTap: () async {
                final v = await showNumericKeypad(ctx, title: 'Rest (seconds)', initial: profile.autoRestSeconds.toDouble(), unit: 's', step: 5, allowDecimal: false, max: 900);
                if (ctx.mounted && v != null && v > 0) Navigator.pop(ctx, v.round());
              },
            ),
          ]),
        ]),
      ),
    );
    if (choice != null) await onSave(profile.copyWith(autoRestSeconds: choice));
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(children: [
      Expanded(child: Text(label, style: SxText.bodyLg.copyWith(color: c.textHigh))),
      _Step(icon: Icons.remove, label: 'Decrease $label', onTap: () => onChanged(value - 1)),
      SizedBox(width: 44, child: Center(child: Text('$value', style: SxText.metricMd.copyWith(color: c.primary)))),
      _Step(icon: Icons.add, label: 'Increase $label', onTap: () => onChanged(value + 1)),
    ]);
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: c.surface2,
        borderRadius: BorderRadius.circular(SxRadius.base),
        child: InkWell(
          borderRadius: BorderRadius.circular(SxRadius.base),
          onTap: onTap,
          child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 20, color: onTap == null ? c.textMuted : c.textHigh)),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.subtitle, required this.trailing, this.onTap});
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SxSpace.md, vertical: 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: SxText.bodyLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
          const SizedBox(width: 12),
          trailing,
        ]),
      ),
    );
  }
}

class _Preferences extends StatelessWidget {
  const _Preferences({required this.profile, required this.onSave});
  final UserProfile profile;
  final Future<void> Function(UserProfile) onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Measurement unit', style: SxText.bodyLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w600))),
          Text('METRIC / IMPERIAL', style: SxText.labelCaps.copyWith(color: c.textMuted, fontSize: 10)),
        ]),
        const SizedBox(height: 10),
        SxSegmented(
          labels: const ['kg (Kilograms)', 'lb (Pounds)'],
          index: profile.unit == WeightUnit.kg ? 0 : 1,
          onChanged: (i) => onSave(profile.copyWith(unit: i == 0 ? WeightUnit.kg : WeightUnit.lb)),
        ),
        const SizedBox(height: SxSpace.md),
        Text('Interface theme', style: SxText.bodyLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SxSegmented(
          labels: const ['Dark', 'OLED', 'System'],
          index: profile.themeMode.index,
          onChanged: (i) => onSave(profile.copyWith(themeMode: SxThemeMode.values[i])),
        ),
        const SizedBox(height: 6),
        Text('OLED uses a true-black canvas. System follows Dark (the app is dark-only).', style: SxText.bodySm.copyWith(color: c.textMuted)),
      ]),
    );
  }
}

class _Integrations extends StatelessWidget {
  const _Integrations({required this.onExport});
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(children: [
        const _HealthRow(),
        const SizedBox(height: SxSpace.md),
        const CloudSyncCard(),
        Row(children: [
          _IconBox(Icons.offline_bolt_outlined, c.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Local-first engine', style: SxText.bodyLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
              Text('Offline ready • Isar database stored on this device', style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
        ]),
        const SizedBox(height: SxSpace.md),
        SxButton(label: 'Export CSV / JSON', icon: Icons.file_download_outlined, variant: SxButtonVariant.secondary, height: 48, onPressed: onExport),
        const SizedBox(height: 8),
        SxButton(label: 'Import from Gym Tracker', icon: Icons.file_upload_outlined, variant: SxButtonVariant.secondary, height: 48, onPressed: () => importFromGymTracker(context)),
      ]),
    );
  }
}

/// Health Connect status + connect/disconnect (read-only sleep & resting HR).
class _HealthRow extends StatelessWidget {
  const _HealthRow();

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final health = context.app.health;
    return ListenableBuilder(
      listenable: health,
      builder: (context, _) {
        final (String subtitle, String? action, VoidCallback? onTap) = switch (health.status) {
          HealthStatus.unsupported => ('Not available on this device', null, null),
          HealthStatus.notInstalled => ('${health.provider.label} is not installed', 'Install', () => connectHealthConnect(context)),
          HealthStatus.notConnected => ('Not connected · reads sleep & resting heart rate (read-only)', 'Connect', () => connectHealthConnect(context)),
          HealthStatus.connected => (
              'Connected · read-only${health.snapshot?.hasData == true ? '' : ' · no data recorded yet'}',
              'Disconnect',
              () => disconnectHealthConnect(context)
            ),
        };
        return Row(children: [
          _IconBox(Icons.monitor_heart_outlined, health.status == HealthStatus.connected ? c.primary : c.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(health.provider.label, style: SxText.bodyLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
              Text(subtitle, style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            SxButton(
              label: action,
              onPressed: health.busy ? null : onTap,
              variant: health.status == HealthStatus.connected ? SxButtonVariant.ghost : SxButtonVariant.secondary,
              expanded: false,
              height: 40,
            ),
          ],
        ]);
      },
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon, this.color);
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: context.sx.surface2, borderRadius: BorderRadius.circular(SxRadius.md)),
        child: Icon(icon, color: color),
      );
}

class _Safety extends StatelessWidget {
  const _Safety({required this.onWipe, required this.onSignOut, required this.onLoadDemo, required this.onPrivacy});
  final VoidCallback onWipe;
  final VoidCallback onSignOut;
  final VoidCallback onLoadDemo;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        _Row(
          title: 'Privacy',
          subtitle: 'What StationX stores and what it never sends',
          onTap: onPrivacy,
          trailing: Icon(Icons.privacy_tip_outlined, color: c.textBody),
        ),
        Divider(height: 1, color: c.hairline),
        _Row(
          title: 'Sign out',
          subtitle: 'Return to the welcome screen',
          onTap: onSignOut,
          trailing: Icon(Icons.logout, color: c.textBody),
        ),
        Divider(height: 1, color: c.hairline),
        _Row(
          title: 'Load demo data',
          subtitle: 'Fills the app with sample history to explore (replaces data)',
          onTap: onLoadDemo,
          trailing: Icon(Icons.science_outlined, color: c.textBody),
        ),
        Divider(height: 1, color: c.hairline),
        _Row(
          title: 'Delete all local data',
          subtitle: 'Wipes workouts, cardio and goals from this device',
          onTap: onWipe,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: c.dangerContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(SxRadius.base), border: Border.all(color: c.danger.withValues(alpha: 0.4))),
            child: Text('PURGE', style: SxText.labelCaps.copyWith(color: c.danger, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.profile, required this.sessions, required this.cardio});
  final UserProfile profile;
  final List<WorkoutSession> sessions;
  final List<CardioSession> cardio;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  int _fmt = 0;

  String get _text => _fmt == 0
      ? ExportBuilder.json(profile: widget.profile, sessions: widget.sessions, cardio: widget.cardio)
      : ExportBuilder.csv(sessions: widget.sessions, cardio: widget.cardio);

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final empty = widget.sessions.isEmpty && widget.cardio.isEmpty;
    final text = _text;
    return Padding(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EXPORT DATA', style: SxText.labelCaps.copyWith(color: c.textBody)),
        const SizedBox(height: 10),
        SxSegmented(labels: const ['JSON', 'CSV'], index: _fmt, onChanged: (i) => setState(() => _fmt = i)),
        const SizedBox(height: 10),
        if (empty)
          const EmptyState(icon: Icons.inbox_outlined, title: 'Nothing to export', message: 'Log a workout or cardio session first.')
        else
          Flexible(
            child: SxInset(
              child: SingleChildScrollView(child: SelectableText(text, style: SxText.metricSm.copyWith(color: c.textBody, fontSize: 11, height: 1.4))),
            ),
          ),
        const SizedBox(height: SxSpace.md),
        SxButton(
          label: 'Copy to clipboard',
          icon: Icons.copy,
          onPressed: empty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    Navigator.pop(context);
                    showSxSnack(context, 'Copied ${_fmt == 0 ? 'JSON' : 'CSV'} to clipboard');
                  }
                },
        ),
      ]),
    );
  }
}

/// Installed app version (from the platform package info), shown in the section header.
class _VersionLabel extends StatelessWidget {
  const _VersionLabel();

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: appVersionLabel(),
        builder: (context, snap) => Text(snap.data ?? '',
            style: SxText.bodySm.copyWith(color: context.sx.textBody)),
      );
}
