import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import '../cardio/cardio_home_view.dart';
import 'workout_stats.dart';
import 'workout_templates.dart';

/// Workouts tab root: Strength (rotation, routines, templates) / Cardio.
class WorkoutsHubPage extends StatefulWidget {
  const WorkoutsHubPage({super.key});

  @override
  State<WorkoutsHubPage> createState() => _WorkoutsHubPageState();
}

class _WorkoutsHubPageState extends State<WorkoutsHubPage> {
  int _mode = 0; // 0 strength, 1 cardio
  int _tab = 0; // routines / templates / saved

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.profile, app.workouts, app.sessions, app.exercises]),
      builder: (context, _) {
        return SxScaffold(
          topBar: SxBrandBar(name: app.profile.profile.name, onAvatarTap: () => AppNav.switchTab(context, 3)),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(SxSpace.screenMargin, SxSpace.md, SxSpace.screenMargin, SxSpace.sm),
                child: Column(
                  children: [
                    _Header(onNew: () => AppNav.workoutEditor(context, 'new_${DateTime.now().microsecondsSinceEpoch}')),
                    const SizedBox(height: SxSpace.md),
                    SxSegmented(
                      labels: const ['Strength', 'Cardio'],
                      icons: const [Icons.fitness_center, Icons.directions_run],
                      index: _mode,
                      onChanged: (i) => setState(() => _mode = i),
                    ),
                    if (_mode == 0) ...[
                      const SizedBox(height: SxSpace.sm),
                      SxSegmented(
                        labels: const ['Routines', 'Templates', 'Saved'],
                        icons: const [Icons.format_list_bulleted, Icons.library_books_outlined, Icons.bookmark_border],
                        index: _tab,
                        onChanged: (i) => setState(() => _tab = i),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _mode == 1
                    ? const CardioHomeView()
                    : switch (_tab) {
                        0 => _RoutinesTab(app: app, onBrowseTemplates: () => setState(() => _tab = 1)),
                        1 => _TemplatesTab(app: app),
                        _ => const _SavedTab(),
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Workouts', style: SxText.headlineLg.copyWith(color: c.textHigh)),
              Text('Rotation, routines & cardio', style: SxText.bodySm.copyWith(color: c.textBody)),
            ],
          ),
        ),
        SxIconButton(icon: Icons.calendar_month_outlined, tooltip: 'History calendar', onPressed: () => AppNav.calendar(context)),
        const SizedBox(width: 8),
        SxButton(
          label: 'New',
          icon: Icons.add,
          variant: SxButtonVariant.secondary,
          expanded: false,
          height: 48,
          onPressed: onNew,
        ),
      ],
    );
  }
}

// ───────────────────────── Routines ─────────────────────────

class _RoutinesTab extends StatelessWidget {
  const _RoutinesTab({required this.app, required this.onBrowseTemplates});
  final AppController app;
  final VoidCallback onBrowseTemplates;

  @override
  Widget build(BuildContext context) {
    final WorkoutRepository workouts = app.workouts;
    final SessionRepository sessions = app.sessions;
    final ExerciseRepository exercises = app.exercises;
    final unit = app.profile.profile.unit;

    if (workouts.workouts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.fitness_center,
            eyebrow: 'No routines',
            title: 'Build your first workout',
            message: 'Create a routine or start from a built-in template. Your rotation follows the order of your workouts.',
            actionLabel: 'New routine',
            onAction: () => AppNav.workoutEditor(context, 'new_${DateTime.now().microsecondsSinceEpoch}'),
            secondaryLabel: 'Browse templates',
            onSecondary: onBrowseTemplates,
          ),
        ),
      );
    }

    final list = workouts.workouts;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(SxSpace.screenMargin, SxSpace.sm, SxSpace.screenMargin, SxSpace.lg),
      itemCount: list.length + 3,
      separatorBuilder: (_, i) => SizedBox(height: i == 0 ? SxSpace.sm : SxSpace.md),
      itemBuilder: (context, i) {
        if (i == 0) {
          final (day, total) = RotationService.dayOf(workouts.rotation);
          return SectionHeader('Active rotation', trailingText: total == 0 ? null : 'Day $day / $total');
        }
        if (i == 1) {
          return _RotationCard(workouts: workouts, sessions: sessions, exercises: exercises, unit: unit);
        }
        if (i == 2) {
          return Padding(
            padding: const EdgeInsets.only(top: SxSpace.sm),
            child: SectionHeader('My routines', trailingText: '${list.length} total'),
          );
        }
        final w = list[i - 3];
        return _RoutineCard(workout: w, workouts: workouts, sessions: sessions, unit: unit);
      },
    );
  }
}

class _RotationCard extends StatelessWidget {
  const _RotationCard({required this.workouts, required this.sessions, required this.exercises, required this.unit});
  final WorkoutRepository workouts;
  final SessionRepository sessions;
  final ExerciseRepository exercises;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final rot = workouts.rotation;
    final days = [for (final id in rot.workoutIds) workouts.byId(id)].whereType<Workout>().toList();
    final (day, total) = RotationService.dayOf(rot);
    final cur = rot.currentIndex % (rot.length == 0 ? 1 : rot.length);
    final current = workouts.currentWorkout;

    return SxCard(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$total-Day Rotation', style: SxText.headlineMd.copyWith(color: c.textHigh)),
                    const SizedBox(height: 4),
                    Text(
                      'Sequential: your next workout follows the last one you finished, not the calendar.',
                      style: SxText.bodySm.copyWith(color: c.textBody),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('POSITION', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
                  Text(total == 0 ? '—' : '$day/$total', style: SxText.metricLg.copyWith(color: c.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: SxSpace.md),
          SxLinearMeter(value: total == 0 ? 0 : day / total, height: 6),
          const SizedBox(height: SxSpace.md),
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const SizedBox(height: SxSpace.sm),
            _DayRow(
              index: i,
              workout: days[i],
              state: i < cur ? _DayState.done : (i == cur ? _DayState.next : _DayState.later),
              last: WorkoutStats.lastSessionOf(days[i].id, sessions.sessions),
              unit: unit,
            ),
          ],
          const SizedBox(height: SxSpace.md),
          Row(
            children: [
              Expanded(
                child: SxButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  variant: SxButtonVariant.secondary,
                  height: 48,
                  onPressed: current == null ? null : () => AppNav.workoutEditor(context, current.id),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SxButton(
                  label: 'Change next',
                  icon: Icons.swap_horiz,
                  variant: SxButtonVariant.secondary,
                  height: 48,
                  onPressed: days.length < 2 ? null : () => _showChangeNext(context, days, cur),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChangeNext(BuildContext context, List<Workout> days, int cur) {
    showSxSheet<void>(
      context,
      builder: (ctx) => _ChangeNextSheet(days: days, current: cur, onPick: (w) async {
        Navigator.pop(ctx);
        await workouts.setCurrentWorkout(w.id);
        if (context.mounted) showSxSnack(context, '${w.name} is now next in your rotation');
      }),
    );
  }
}

enum _DayState { done, next, later }

class _DayRow extends StatelessWidget {
  const _DayRow({required this.index, required this.workout, required this.state, required this.last, required this.unit});
  final int index;
  final Workout workout;
  final _DayState state;
  final WorkoutSession? last;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final isNext = state == _DayState.next;
    final num2 = (index + 1).toString().padLeft(2, '0');
    final subtitle = switch (state) {
      _DayState.later => '${workout.exercises.length} exercises • ${workout.totalSets} sets',
      _DayState.next => '${workout.exercises.length} exercises • ${workout.totalSets} sets • ~${workout.estimatedMinutes} min',
      _DayState.done => last == null
          ? 'Not logged yet'
          : 'Done ${WorkoutStats.ago(last!.workoutDate)}${last!.durationSeconds > 0 ? ' • ${last!.durationSeconds ~/ 60}m' : ''} • ${Fmt.volume(last!.volume, u: unit)}',
    };

    return Semantics(
      button: true,
      label: '${workout.name}, day $num2',
      child: Material(
        color: isNext ? c.surface2 : Colors.transparent,
        borderRadius: BorderRadius.circular(SxRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(SxRadius.md),
          onTap: () => AppNav.workoutPreview(context, workout.id),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SxRadius.md),
              border: Border.all(color: isNext ? c.primaryBorder : c.hairline),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isNext ? c.primary : c.surface2,
                    borderRadius: BorderRadius.circular(SxRadius.base),
                  ),
                  child: state == _DayState.done
                      ? Icon(Icons.check, size: 18, color: c.primary)
                      : Text(num2, style: SxText.metricSm.copyWith(color: isNext ? c.onAccent : c.textBody, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(workout.name, style: SxText.headlineSm.copyWith(color: c.textHigh, fontSize: 16)),
                          if (isNext) const StatusPill('Up next'),
                          if (state == _DayState.done && last != null) StatusPill('Logged', color: c.textBody),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: SxText.bodySm.copyWith(color: c.textBody), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(width: 8),
                  SxButton(
                    label: 'Launch',
                    expanded: false,
                    height: 40,
                    radius: SxRadius.base,
                    onPressed: () => AppNav.activeWorkout(context, workout.id),
                  ),
                ] else
                  Icon(Icons.chevron_right, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangeNextSheet extends StatelessWidget {
  const _ChangeNextSheet({required this.days, required this.current, required this.onPick});
  final List<Workout> days;
  final int current;
  final ValueChanged<Workout> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Change next workout', style: SxText.headlineMd.copyWith(color: c.textHigh)),
          const SizedBox(height: 4),
          Text('Pick which day comes up next. The rotation continues in order from there.',
              style: SxText.bodySm.copyWith(color: c.textBody)),
          const SizedBox(height: SxSpace.md),
          for (var i = 0; i < days.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SxInset(
                onTap: () => onPick(days[i]),
                borderColor: i == current ? c.primaryBorder : null,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Text((i + 1).toString().padLeft(2, '0'), style: SxText.metricMd.copyWith(color: i == current ? c.primary : c.textBody)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(days[i].name, style: SxText.headlineSm.copyWith(color: c.textHigh, fontSize: 16))),
                    if (i == current) const StatusPill('Next'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.workout, required this.workouts, required this.sessions, required this.unit});
  final Workout workout;
  final WorkoutRepository workouts;
  final SessionRepository sessions;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final all = sessions.sessions;
    final last = WorkoutStats.lastSessionOf(workout.id, all);
    final vol = WorkoutStats.recentVolume(workout.id, all);
    final avg = WorkoutStats.averageMinutes(workout.id, all);
    final count = WorkoutStats.sessionsOf(workout.id, all).length;
    final inRotation = workouts.rotation.workoutIds.contains(workout.id);

    return SxCard(
      onTap: () => AppNav.workoutPreview(context, workout.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(workout.name, style: SxText.headlineMd.copyWith(color: c.textHigh))),
              SxIconButton(icon: Icons.more_vert, tooltip: 'Routine options', filled: false, onPressed: () => _options(context, inRotation)),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _Meta(Icons.fitness_center, '${workout.exercises.length} exercises'),
              _Meta(Icons.layers_outlined, '${workout.totalSets} sets'),
              _Meta(Icons.history, last == null ? 'Not done yet' : 'Done ${WorkoutStats.ago(last.workoutDate)}'),
              if (workout.cardioFinisher != null) const _Meta(Icons.directions_run, 'Cardio finisher'),
            ],
          ),
          const SizedBox(height: SxSpace.md),
          Row(
            children: [
              Expanded(child: _Stat(label: '30D volume', value: vol > 0 ? Fmt.volume(vol, u: unit) : '—')),
              const SizedBox(width: 8),
              Expanded(child: _Stat(label: 'Avg session', value: avg == null ? '—' : '$avg min')),
              const SizedBox(width: 8),
              Expanded(child: _Stat(label: 'Sessions', value: '$count')),
            ],
          ),
        ],
      ),
    );
  }

  void _options(BuildContext context, bool inRotation) {
    showSxSheet<void>(
      context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetAction(icon: Icons.visibility_outlined, label: 'Preview', onTap: () {
                Navigator.pop(ctx);
                AppNav.workoutPreview(context, workout.id);
              }),
              _SheetAction(icon: Icons.tune, label: 'Edit structure', onTap: () {
                Navigator.pop(ctx);
                AppNav.workoutEditor(context, workout.id);
              }),
              if (inRotation)
                _SheetAction(icon: Icons.skip_next_outlined, label: 'Make next in rotation', onTap: () async {
                  Navigator.pop(ctx);
                  await workouts.setCurrentWorkout(workout.id);
                  if (context.mounted) showSxSnack(context, '${workout.name} is now next');
                }),
              _SheetAction(icon: Icons.delete_outline, label: 'Delete routine', destructive: true, onTap: () async {
                Navigator.pop(ctx);
                final ok = await showSxConfirm(
                  context,
                  title: 'Delete ${workout.name}?',
                  message: 'The routine is removed from your rotation. Logged sessions stay in your history.',
                  confirmLabel: 'Delete',
                  destructive: true,
                  icon: Icons.delete_forever,
                );
                if (ok) {
                  await workouts.deleteWorkout(workout.id);
                  if (context.mounted) showSxSnack(context, 'Routine deleted');
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({required this.icon, required this.label, required this.onTap, this.destructive = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final col = destructive ? c.danger : c.textHigh;
    return ListTile(
      minTileHeight: 52,
      leading: Icon(icon, color: col),
      title: Text(label, style: SxText.bodyLg.copyWith(color: col)),
      onTap: onTap,
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: c.textMuted),
      const SizedBox(width: 4),
      Flexible(child: Text(text, style: SxText.bodySm.copyWith(color: c.textBody))),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxInset(
      color: Colors.black.withValues(alpha: 0.25),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textMuted, fontSize: 9)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: SxText.metricSm.copyWith(color: c.textHigh, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

// ───────────────────────── Templates ─────────────────────────

class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final WorkoutRepository workouts = app.workouts;
    final ExerciseRepository exercises = app.exercises;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(SxSpace.screenMargin, SxSpace.sm, SxSpace.screenMargin, SxSpace.lg),
      itemCount: builtInTemplates.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: SxSpace.md),
      itemBuilder: (context, i) {
        if (i == 0) {
          return const SectionHeader('Built-in templates', trailingText: 'Local presets');
        }
        final t = builtInTemplates[i - 1];
        return _TemplateCard(template: t, workouts: workouts, exercises: exercises);
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.workouts, required this.exercises});
  final WorkoutTemplate template;
  final WorkoutRepository workouts;
  final ExerciseRepository exercises;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill('${template.days.length}-day rotation', dot: true),
          const SizedBox(height: 10),
          Text(template.name, style: SxText.headlineMd.copyWith(color: c.textHigh)),
          const SizedBox(height: 4),
          Text(template.blurb, style: SxText.bodyMd.copyWith(color: c.textBody)),
          const SizedBox(height: 6),
          Text('${template.exerciseCount} exercises • ${template.days.map((d) => d.name).join(' / ')}',
              style: SxText.bodySm.copyWith(color: c.textMuted)),
          const SizedBox(height: SxSpace.md),
          Row(
            children: [
              Expanded(child: SxButton(label: 'Preview', variant: SxButtonVariant.secondary, height: 44, onPressed: () => _preview(context))),
              const SizedBox(width: 8),
              Expanded(child: SxButton(label: 'Add', icon: Icons.add, height: 44, onPressed: () => _add(context))),
            ],
          ),
        ],
      ),
    );
  }

  void _preview(BuildContext context) {
    final c = context.sx;
    showSxSheet<void>(
      context,
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.name, style: SxText.headlineMd.copyWith(color: c.textHigh)),
            const SizedBox(height: SxSpace.md),
            for (final d in template.days) ...[
              Text(d.name.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.primary)),
              const SizedBox(height: 6),
              for (final re in d.exercises)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(child: Text(exercises.byId(re.exerciseId)?.name ?? re.exerciseId, style: SxText.bodyMd.copyWith(color: c.textHigh))),
                    Text(WorkoutStats.setsReps(re), style: SxText.metricSm.copyWith(color: c.textBody)),
                  ]),
                ),
              const SizedBox(height: SxSpace.md),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    var added = 0;
    for (var i = 0; i < template.days.length; i++) {
      final d = template.days[i];
      final valid = d.exercises.where((e) => exercises.byId(e.exerciseId) != null).toList();
      if (valid.isEmpty) continue;
      await workouts.saveWorkout(Workout(id: 'w_${stamp}_$i', name: d.name, description: '${template.name} template', exercises: valid));
      added++;
    }
    if (context.mounted) {
      showSxSnack(context, added == 0 ? 'No matching exercises in your library' : 'Added $added ${added == 1 ? 'workout' : 'workouts'} to your rotation');
    }
  }
}

class _SavedTab extends StatelessWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        child: EmptyState(
          icon: Icons.bookmark_border,
          title: 'Nothing saved yet',
          message: 'Bookmarking routines is not available yet. Everything you create appears under Routines.',
        ),
      ),
    );
  }
}
