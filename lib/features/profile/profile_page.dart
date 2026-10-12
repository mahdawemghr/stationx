import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../app/app_version.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/remote_ops.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import '../cloud/sign_out_flow.dart';
import '../health/health_actions.dart';
import '../onboarding/schedule_setup_entry.dart';
import '../onboarding/setup_equipment_step.dart';
import '../onboarding/setup_experience_step.dart';
import 'export_saver.dart';
import 'gym_tracker_import_flow.dart';
import 'export_builder.dart';

/// Profile & settings tab (Stitch: profile_app_settings). Every control is saved to the server through
/// [ProfileRepository.update]; the control shows the new value only after the server confirmed it.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.exportSaver = saveExportWithFilePicker});

  /// Injectable so tests (and platforms without a save dialog) can replace the file save.
  final ExportSaver exportSaver;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.profile, app.sessions, app.workouts]),
      builder: (context, _) {
        final p = app.profile.profile;
        Future<void> save(UserProfile n) => runRemote(
          context,
          () => app.profile.update(n),
          what: 'save your profile',
          key: 'profile',
        ).then((_) {});
        return SxScaffold(
          topBar: const SxTopBar(
            title: 'Profile',
            showBack: false,
            showLogo: true,
          ),
          gap: SxSpace.sm,
          padding: const EdgeInsets.fromLTRB(
            SxSpace.md,
            SxSpace.md,
            SxSpace.md,
            SxSpace.xl,
          ),
          children: [
            _IdentityCard(
              profile: p,
              sessionCount: app.sessions.sessions.length,
              rotation: app.workouts.rotation,
              onEdit: () => _editName(context, p, save),
            ),
            const SizedBox(height: SxSpace.sm),
            SectionHeader(
              'Your data',
              icon: Icons.straighten,
              trailingText: 'Tap to edit',
            ),
            _MetricsRow(profile: p, onSave: save),
            const SizedBox(height: SxSpace.sm),
            SectionHeader(
              'Workout configuration',
              icon: Icons.tune,
              trailing: TextButton(
                onPressed: () => startScheduleSetup(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Set up my schedule',
                  style: SxText.labelUi.copyWith(color: context.sx.primary),
                ),
              ),
            ),
            _WorkoutConfig(profile: p, onSave: save),
            const SizedBox(height: SxSpace.sm),
            const SectionHeader('Preferences', icon: Icons.palette_outlined),
            _Preferences(profile: p, onSave: save),
            const SizedBox(height: SxSpace.sm),
            const SectionHeader(
              'Integrations & storage',
              icon: Icons.storage_outlined,
            ),
            _Integrations(
              onExport: () => _showExport(
                context,
                app.profile.profile,
                app.sessions.sessions,
                app.cardio.sessions,
              ),
            ),
            const SizedBox(height: SxSpace.sm),
            SectionHeader(
              'App & safety',
              icon: Icons.terminal,
              trailing: const _VersionLabel(),
            ),
            _Safety(
              username: app.username,
              onPrivacy: () => AppNav.privacy(context),
              onWipe: () async {
                final ok = await showSxConfirm(
                  context,
                  title: 'Delete all my data?',
                  message:
                      'This permanently deletes every workout, session, cardio entry, goal and custom exercise in your account, '
                      'and restores the default routines. Your login and profile settings stay. It cannot be undone.',
                  confirmLabel: 'Delete everything',
                  destructive: true,
                  icon: Icons.delete_forever,
                );
                if (ok && context.mounted) {
                  await runRemote(
                    context,
                    app.deleteAllData,
                    what: 'delete your data',
                    success: 'All your data was deleted',
                    key: 'wipe',
                  );
                }
              },
              onSignOut: () => confirmAndSignOut(context),
              onDeleteAccount: () => confirmAndDeleteAccount(context),
            ),
            const SizedBox(height: SxSpace.md),
            Center(
              child: Text(
                'STATIONX • STRENGTH & CARDIO LOG',
                textAlign: TextAlign.center,
                style: SxText.labelXs.copyWith(color: context.sx.textMuted),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editName(
    BuildContext context,
    UserProfile p,
    Future<void> Function(UserProfile) save,
  ) async {
    final name = await showSxSheet<String>(
      context,
      builder: (ctx) => _EditNameSheet(initial: p.name),
    );
    if (name != null && name.trim().isNotEmpty) {
      await save(p.copyWith(name: name.trim()));
    }
  }

  void _showExport(
    BuildContext context,
    UserProfile p,
    List<WorkoutSession> s,
    List<CardioSession> c,
  ) {
    showSxSheet<void>(
      context,
      builder: (_) =>
          _ExportSheet(profile: p, sessions: s, cardio: c, saver: exportSaver),
    );
  }
}

/// Owns (and disposes) its own controller; scrolls when the keyboard or large text needs room.
class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({required this.initial});
  final String initial;

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _ctl = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(SxSpace.md),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SxTextField(
          label: 'Display name',
          controller: _ctl,
          icon: Icons.person_outline,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        const SizedBox(height: SxSpace.md),
        SxButton(
          label: 'Save',
          onPressed: () => Navigator.pop(context, _ctl.text),
        ),
      ],
    ),
  );
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.profile,
    required this.sessionCount,
    required this.rotation,
    required this.onEdit,
  });
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
      child: Column(
        children: [
          Row(
            children: [
              SxAvatar(profile.name, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SxText.headlineMd.copyWith(color: c.textHigh),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SxText.bodySm.copyWith(color: c.textBody),
                    ),
                  ],
                ),
              ),
              SxIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit name',
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: SxSpace.md),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.history,
                  label: 'Sessions logged',
                  value: '$sessionCount',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  icon: Icons.sync_alt,
                  label: 'Rotation',
                  value: total == 0 ? '—' : 'Day $day / $total',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxInset(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SxText.labelXs.copyWith(color: c.textBody),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: SxText.metricSm.copyWith(color: c.textHigh),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    Future<void> edit(
      String title,
      double initial,
      String unit,
      double step,
      void Function(double) apply, {
      double? min,
      double? max,
      bool decimal = true,
    }) async {
      final v = await showNumericKeypad(
        context,
        title: title,
        initial: initial,
        unit: unit,
        step: step,
        allowDecimal: decimal,
        min: min,
        max: max,
      );
      if (v != null && v > 0) apply(v);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MetricTile(
              label: 'Weight',
              value: Fmt.weight(profile.weightKg, u),
              unit: Fmt.unit(u),
              onTap: () => edit(
                'Body weight',
                double.parse(Fmt.weight(profile.weightKg, u)),
                Fmt.unit(u),
                0.5,
                (v) => onSave(
                  profile.copyWith(weightKg: Fmt.fromDisplayWeight(v, u)),
                ),
                max: 400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricTile(
              label: 'Height',
              value: Fmt.number(profile.heightCm, decimals: 0),
              unit: 'cm',
              caption: _feetInches(profile.heightCm),
              onTap: () => edit(
                'Height',
                profile.heightCm,
                'cm',
                1,
                (v) => onSave(profile.copyWith(heightCm: v)),
                max: 260,
                decimal: false,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricTile(
              label: 'Age',
              value: '${profile.age}',
              unit: 'y/o',
              onTap: () => edit(
                'Age',
                profile.age.toDouble(),
                'years',
                1,
                (v) => onSave(profile.copyWith(age: v.round())),
                max: 120,
                decimal: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _feetInches(double cm) {
    final totalIn = (cm / 2.54).round();
    return '${totalIn ~/ 12}\'${totalIn % 12}"';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.onTap,
    this.caption,
  });
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SxText.labelXs.copyWith(color: c.textBody),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: SxText.metricLg.copyWith(color: c.textHigh),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Text(unit, style: SxText.bodySm.copyWith(color: c.textBody)),
            ],
          ),
          if (caption != null)
            Text(caption!, style: SxText.bodySm.copyWith(color: c.textMuted)),
        ],
      ),
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
      child: Column(
        children: [
          _Row(
            title: 'Default working sets',
            subtitle: 'Baseline for new exercises',
            trailing: SxStepper.int(
              label: 'sets',
              value: p.defaultSets,
              min: 1,
              max: 10,
              onChanged: (v) => onSave(p.copyWith(defaultSets: v)),
            ),
          ),
          Divider(height: 1, color: c.hairline),
          _Row(
            title: 'Default rep window',
            subtitle: 'Target range for new exercises',
            onTap: () => _repWindow(context),
            trailing: SxInset(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '${p.defaultRepMin} – ${p.defaultRepMax} REPS',
                style: SxText.metricSm.copyWith(color: c.textHigh),
              ),
            ),
          ),
          Divider(height: 1, color: c.hairline),
          _Row(
            title: 'Suggest weights & reps',
            subtitle:
                'Recommends your next weight and reps from your last session',
            trailing: Switch(
              value: p.progressionEnabled,
              onChanged: (v) => onSave(p.copyWith(progressionEnabled: v)),
              activeThumbColor: c.canvas,
              activeTrackColor: c.primary,
            ),
          ),
          Divider(height: 1, color: c.hairline),
          _Row(
            title: 'Training days per week',
            subtitle: 'Weekly goal shown on Today',
            trailing: SxStepper.int(
              label: 'training days',
              value: WeekPlan.training(p.weeklySessionTarget),
              min: WeekPlan.minTraining,
              max: WeekPlan.maxTraining,
              onChanged: (v) =>
                  onSave(p.copyWith(weeklySessionTarget: WeekPlan.training(v))),
            ),
          ),
          Divider(height: 1, color: c.hairline),
          _Row(
            title: 'Rest days per week',
            subtitle: 'Always 7 together with training days',
            trailing: SxStepper.int(
              label: 'rest days',
              value: WeekPlan.rest(p.weeklySessionTarget),
              min: WeekPlan.daysInWeek - WeekPlan.maxTraining,
              max: WeekPlan.daysInWeek - WeekPlan.minTraining,
              onChanged: (v) => onSave(
                p.copyWith(weeklySessionTarget: WeekPlan.trainingForRest(v)),
              ),
            ),
          ),
          Divider(height: 1, color: c.hairline),
          _Row(
            title: 'Equipment',
            subtitle:
                'Used when suggesting exercises. Saved programs never change.',
            onTap: () => _equipment(context),
            trailing: SxInset(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                _equipmentSummary(p.equipment),
                style: SxText.metricSm.copyWith(color: c.textHigh),
              ),
            ),
          ),
          Divider(height: 1, color: c.hairline),
          _Row(
            title: 'Experience level',
            subtitle:
                'Used when suggesting exercises. Saved programs never change.',
            onTap: () => _experience(context),
            trailing: SxInset(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                p.effectiveExperience.label.toUpperCase(),
                style: SxText.metricSm.copyWith(color: c.textHigh),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _equipmentSummary(Set<Equipment>? e) {
    if (e == null || e.length >= EquipmentAccess.choosable.length) {
      return 'FULL GYM';
    }
    if (e.isEmpty) return 'BODYWEIGHT';
    return '${e.length} TYPES';
  }

  Future<void> _experience(BuildContext context) async {
    var chosen = profile.effectiveExperience;
    final res = await showSxSheet<Difficulty>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.all(SxSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXPERIENCE LEVEL',
                style: SxText.labelCaps.copyWith(color: ctx.sx.textBody),
              ),
              const SizedBox(height: 4),
              Text(
                'Only shapes suggested exercises. Your saved program never changes.',
                style: SxText.bodySm.copyWith(color: ctx.sx.textMuted),
              ),
              const SizedBox(height: SxSpace.md),
              ExperiencePicker(
                selected: chosen,
                onChanged: (v) => set(() => chosen = v),
              ),
              const SizedBox(height: SxSpace.md),
              SxButton(
                label: 'Save',
                onPressed: () => Navigator.pop(ctx, chosen),
              ),
            ],
          ),
        ),
      ),
    );
    if (res != null) await onSave(profile.copyWith(experienceLevel: res));
  }

  Future<void> _equipment(BuildContext context) async {
    var chosen = profile.equipment ?? {...EquipmentAccess.choosable};
    final res = await showSxSheet<Set<Equipment>>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.all(SxSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR EQUIPMENT',
                style: SxText.labelCaps.copyWith(color: ctx.sx.textBody),
              ),
              const SizedBox(height: 4),
              Text(
                'Bodyweight exercises are always available.',
                style: SxText.bodySm.copyWith(color: ctx.sx.textMuted),
              ),
              const SizedBox(height: SxSpace.md),
              EquipmentPicker(
                selected: chosen,
                onChanged: (v) => set(() => chosen = v),
              ),
              const SizedBox(height: SxSpace.md),
              SxButton(
                label: 'Save',
                onPressed: () => Navigator.pop(ctx, chosen),
              ),
            ],
          ),
        ),
      ),
    );
    if (res != null) await onSave(profile.copyWith(equipment: res));
  }

  Future<void> _repWindow(BuildContext context) async {
    var lo = profile.defaultRepMin, hi = profile.defaultRepMax;
    final res = await showSxSheet<(int, int)>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.all(SxSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DEFAULT REP WINDOW',
                style: SxText.labelCaps.copyWith(color: ctx.sx.textBody),
              ),
              const SizedBox(height: SxSpace.md),
              _StepperRow(
                label: 'Min reps',
                value: lo,
                min: 1,
                max: hi,
                onChanged: (v) => set(() => lo = v),
              ),
              const SizedBox(height: 8),
              _StepperRow(
                label: 'Max reps',
                value: hi,
                min: lo,
                max: 50,
                onChanged: (v) => set(() => hi = v),
              ),
              const SizedBox(height: SxSpace.md),
              SxButton(
                label: 'Save',
                onPressed: () => Navigator.pop(ctx, (lo, hi)),
              ),
            ],
          ),
        ),
      ),
    );
    if (res != null) {
      await onSave(
        profile.copyWith(defaultRepMin: res.$1, defaultRepMax: res.$2),
      );
    }
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value, min, max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: SxText.bodyLg.copyWith(color: context.sx.textHigh),
        ),
      ),
      SxStepper.int(
        label: label,
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    ],
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });
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
        padding: const EdgeInsets.symmetric(
          horizontal: SxSpace.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SxText.bodyLg.copyWith(
                      color: c.textHigh,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SxSwap(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle,
                      key: ValueKey(subtitle),
                      style: SxText.bodySm.copyWith(color: c.textBody),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Measurement unit',
                  style: SxText.bodyLg.copyWith(
                    color: c.textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'METRIC / IMPERIAL',
                style: SxText.labelXs.copyWith(color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SxSegmented(
            labels: const ['kg (Kilograms)', 'lb (Pounds)'],
            index: profile.unit == WeightUnit.kg ? 0 : 1,
            onChanged: (i) => onSave(
              profile.copyWith(unit: i == 0 ? WeightUnit.kg : WeightUnit.lb),
            ),
          ),
          const SizedBox(height: SxSpace.md),
          Text(
            'Interface theme',
            style: SxText.bodyLg.copyWith(
              color: c.textHigh,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SxSegmented(
            labels: const ['Dark', 'OLED', 'System'],
            index: profile.themeMode.index,
            onChanged: (i) =>
                onSave(profile.copyWith(themeMode: SxThemeMode.values[i])),
          ),
          const SizedBox(height: 6),
          Text(
            'OLED uses a true-black canvas. System follows Dark (the app is dark-only).',
            style: SxText.bodySm.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: SxSpace.sm),
          InkWell(
            onTap: () => AppNav.cardioSettings(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.directions_run, size: 20, color: c.textBody),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cardio units & export',
                      style: SxText.bodyLg.copyWith(
                        color: c.textHigh,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: c.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
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
      child: Column(
        children: [
          const _HealthRow(),
          const SizedBox(height: SxSpace.md),
          const _HealthSyncRow(),
          const SizedBox(height: SxSpace.md),
          Row(
            children: [
              _IconBox(Icons.cloud_done_outlined, c.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved to your account',
                      style: SxText.bodyLg.copyWith(
                        color: c.textHigh,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Your training is stored online and needs a connection to save',
                      style: SxText.bodySm.copyWith(color: c.textBody),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: SxSpace.md),
          SxButton(
            label: 'Export your data',
            icon: Icons.file_download_outlined,
            variant: SxButtonVariant.secondary,
            height: 48,
            onPressed: onExport,
          ),
          const SizedBox(height: 8),
          SxButton(
            label: 'Import from Gym Tracker',
            icon: Icons.file_upload_outlined,
            variant: SxButtonVariant.secondary,
            height: 48,
            onPressed: () => importFromGymTracker(context),
          ),
        ],
      ),
    );
  }
}

/// Health Connect status + connect/disconnect (read-only).
class _HealthRow extends StatelessWidget {
  const _HealthRow();

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final health = context.app.health;
    return ListenableBuilder(
      listenable: health,
      builder: (context, _) {
        final (
          String subtitle,
          String? action,
          VoidCallback? onTap,
        ) = switch (health.status) {
          HealthStatus.unsupported => (
            'Not available on this device',
            null,
            null,
          ),
          HealthStatus.notInstalled => (
            '${health.provider.label} is not installed',
            'Install',
            () => connectHealthConnect(context),
          ),
          HealthStatus.notConnected => (
            'Not connected · imports workouts from your watch (read-only)',
            'Connect',
            () => connectHealthConnect(context),
          ),
          HealthStatus.connected => (
            'Connected · read-only',
            'Disconnect',
            () => disconnectHealthConnect(context),
          ),
        };
        return Row(
          children: [
            _IconBox(
              Icons.monitor_heart_outlined,
              health.status == HealthStatus.connected ? c.primary : c.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    health.provider.label,
                    style: SxText.bodyLg.copyWith(
                      color: c.textHigh,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: SxText.bodySm.copyWith(color: c.textBody),
                  ),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 8),
              SxButton(
                label: action,
                onPressed: health.busy ? null : onTap,
                variant: health.status == HealthStatus.connected
                    ? SxButtonVariant.ghost
                    : SxButtonVariant.secondary,
                expanded: false,
                height: 40,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Opens the opt-in "Health & workouts" sync settings.
class _HealthSyncRow extends StatelessWidget {
  const _HealthSyncRow();

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final sync = context.app.healthSync;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final on = HealthFeature.values.where(sync.isEnabled).length;
        return InkWell(
          onTap: () => AppNav.healthSyncSettings(context),
          borderRadius: BorderRadius.circular(SxRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                _IconBox(Icons.sync_alt, on > 0 ? c.primary : c.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health & workouts',
                        style: SxText.bodyLg.copyWith(
                          color: c.textHigh,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        on == 0
                            ? 'Off · save, fill in and import workouts'
                            : '$on of 3 turned on',
                        style: SxText.bodySm.copyWith(color: c.textBody),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.textMuted),
              ],
            ),
          ),
        );
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
    decoration: BoxDecoration(
      color: context.sx.surface2,
      borderRadius: BorderRadius.circular(SxRadius.md),
    ),
    child: Icon(icon, color: color),
  );
}

class _Safety extends StatelessWidget {
  const _Safety({
    required this.username,
    required this.onWipe,
    required this.onSignOut,
    required this.onDeleteAccount,
    required this.onPrivacy,
  });
  final String username;
  final VoidCallback onWipe;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _Row(
            title: 'Privacy',
            subtitle: 'What StationX stores and what it never sends',
            onTap: onPrivacy,
            trailing: Icon(Icons.privacy_tip_outlined, color: c.textBody),
          ),
          Divider(height: 1, color: c.hairline),
          _Row(
            title: 'Log out',
            subtitle:
                'Signed in as $username. Your data stays safe in your account',
            onTap: onSignOut,
            trailing: Icon(Icons.logout, color: c.textBody),
          ),
          Divider(height: 1, color: c.hairline),
          _Row(
            title: 'Delete all my data',
            subtitle: 'Wipes workouts, cardio and goals from your account',
            onTap: onWipe,
            trailing: Icon(Icons.delete_outline, color: c.danger),
          ),
          Divider(height: 1, color: c.hairline),
          _Row(
            title: 'Delete account',
            subtitle: 'Permanently deletes your login and everything in it',
            onTap: onDeleteAccount,
            trailing: Icon(Icons.person_remove_outlined, color: c.danger),
          ),
        ],
      ),
    );
  }
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({
    required this.profile,
    required this.sessions,
    required this.cardio,
    required this.saver,
  });
  final UserProfile profile;
  final List<WorkoutSession> sessions;
  final List<CardioSession> cardio;
  final ExportSaver saver;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  int _fmt = 0;

  String get _ext => _fmt == 0 ? 'json' : 'csv';

  String get _text => _fmt == 0
      ? ExportBuilder.json(
          profile: widget.profile,
          sessions: widget.sessions,
          cardio: widget.cardio,
        )
      : ExportBuilder.csv(sessions: widget.sessions, cardio: widget.cardio);

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      Navigator.pop(context);
      showSxSnack(context, 'Copied ${_ext.toUpperCase()} to clipboard');
    }
  }

  Future<void> _save(String text) async {
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    try {
      final saved = await widget.saver('stationx-export-$stamp.$_ext', text);
      if (saved && mounted) {
        Navigator.pop(context);
        showSxSnack(context, 'Export saved');
      }
    } catch (_) {
      // No save dialog on this device: fall back to the clipboard.
      await _copy(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final empty = widget.sessions.isEmpty && widget.cardio.isEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXPORT DATA',
            style: SxText.labelCaps.copyWith(color: c.textBody),
          ),
          const SizedBox(height: 10),
          SxSegmented(
            labels: const ['JSON', 'CSV'],
            index: _fmt,
            onChanged: (i) => setState(() => _fmt = i),
          ),
          const SizedBox(height: 10),
          if (empty)
            const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Nothing to export',
              message: 'Log a workout or cardio session first.',
            )
          else ...[
            SxInset(
              child: Text(
                '${widget.sessions.length} workout${widget.sessions.length == 1 ? '' : 's'} and ${widget.cardio.length} cardio session${widget.cardio.length == 1 ? '' : 's'} '
                'will be exported as ${_ext.toUpperCase()}. ${_fmt == 0 ? 'JSON keeps everything, including your profile.' : 'CSV opens in any spreadsheet app.'}',
                style: SxText.bodyMd.copyWith(color: c.textBody),
              ),
            ),
            const SizedBox(height: SxSpace.md),
            SxButton(
              label: 'Save as file',
              icon: Icons.save_alt,
              onPressed: () => _save(_text),
            ),
            const SizedBox(height: 8),
            SxButton(
              label: 'Copy to clipboard',
              icon: Icons.copy,
              variant: SxButtonVariant.secondary,
              onPressed: () => _copy(_text),
            ),
          ],
        ],
      ),
    );
  }
}

/// Installed app version (from the platform package info), shown in the section header.
class _VersionLabel extends StatelessWidget {
  const _VersionLabel();

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: appVersionLabel(),
    builder: (context, snap) => Text(
      snap.data ?? '',
      style: SxText.bodySm.copyWith(color: context.sx.textBody),
    ),
  );
}
