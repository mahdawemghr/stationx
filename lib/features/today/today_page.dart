import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

/// Today tab (Stitch: today_home). The hero is the *next workout in the
/// rotation* (index based, never date based).
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.workouts, app.sessions, app.exercises, app.profile]),
      builder: (context, _) {
        final profile = app.profile.profile;
        final now = DateTime.now();
        final workout = app.workouts.currentWorkout;
        final next = app.workouts.nextWorkout;
        final rotation = app.workouts.rotation;
        final weekStart = VolumeService.startOfWeek(now);
        final weekEnd = weekStart.add(const Duration(days: 7));
        final week = app.sessions.between(weekStart, weekEnd);
        final recent = _recentProgress(app.sessions.sessions, app.exercises);
        final c = context.sx;

        return SxScaffold(
          topBar: _TodayBar(name: profile.name, onAvatarTap: () => AppNav.switchTab(context, 3)),
          gap: SxSpace.md,
          children: [
            _DateHeader(now: now, name: profile.name.split(' ').first, workout: workout),
            if (workout == null)
              EmptyState(
                icon: Icons.fitness_center,
                title: 'No workouts yet',
                message: 'Create a workout to start your rotation.',
                actionLabel: 'Open Workouts',
                onAction: () => AppNav.switchTab(context, 1),
              )
            else
              _HeroCard(workout: workout, rotation: rotation),
            SectionHeader('This week', icon: Icons.calendar_view_week, trailingText: 'Target: ${profile.weeklySessionTarget} sessions'),
            Row(children: [
              Expanded(child: StatTile(label: 'Done', value: '${week.length}', unit: 'ses', icon: Icons.check_circle_outline)),
              const SizedBox(width: 8),
              Expanded(child: _VolumeTile(sessions: week, unit: profile.unit)),
              const SizedBox(width: 8),
              Expanded(child: _PrTile(sessions: app.sessions.sessions, from: weekStart, to: weekEnd)),
            ]),
            if (recent != null)
              _RecentProgress(data: recent, unit: profile.unit, onTap: () => AppNav.exerciseHistory(context, recent.exercise.id))
            else if (app.sessions.sessions.isEmpty)
              SxCard(
                child: Row(children: [
                  Icon(Icons.trending_up, color: c.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Complete a workout to see your progress here.', style: SxText.bodyMd.copyWith(color: c.textBody))),
                ]),
              ),
            if (next != null && workout != null && next.id != workout.id) ...[
              const SectionHeader('Up next', trailingText: 'In rotation'),
              _UpNext(workout: next, rotation: rotation, onTap: () => AppNav.workoutPreview(context, next.id)),
            ],
            _RecoveryCard(onTap: () => AppNav.switchTab(context, 3)),
          ],
        );
      },
    );
  }

  /// Latest estimated-1RM PR that improved on a previous best.
  _Recent? _recentProgress(List<WorkoutSession> sessions, ExerciseRepository ex) {
    for (final pr in PrService.all(PrType.estimated1Rm, sessions)) {
      final prev = pr.previousValue;
      final e = ex.byId(pr.exerciseId);
      if (prev == null || e == null || prev <= 0) continue;
      return _Recent(e, pr, (pr.value - prev) / prev * 100);
    }
    return null;
  }
}

class _Recent {
  const _Recent(this.exercise, this.pr, this.percent);
  final Exercise exercise;
  final StrengthPr pr;
  final double percent;
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.now, required this.name, required this.workout});
  final DateTime now;
  final String name;
  final Workout? workout;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Fmt.dateLong(now).toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody)),
          const SizedBox(height: 2),
          Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 8, children: [
            Text('Today', style: SxText.headlineLg.copyWith(color: c.textHigh)),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('· ${Fmt.greeting(now)}, $name', style: SxText.bodySm.copyWith(color: c.textBody)),
            ),
          ]),
        ]),
      ),
      PopupMenuButton<String>(
        tooltip: 'Quick options',
        color: c.surface3,
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(SxRadius.md), border: Border.all(color: c.hairline)),
          child: Icon(Icons.more_horiz, size: 20, color: c.textBody),
        ),
        onSelected: (v) {
          switch (v) {
            case 'calendar':
              AppNav.calendar(context);
            case 'edit':
              if (workout != null) AppNav.workoutEditor(context, workout!.id);
            case 'library':
              AppNav.exerciseLibrary(context);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'calendar', child: Text('Calendar & history')),
          if (workout != null) const PopupMenuItem(value: 'edit', child: Text('Edit this workout')),
          const PopupMenuItem(value: 'library', child: Text('Exercise library')),
        ],
      ),
    ]);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.workout, required this.rotation});
  final Workout workout;
  final Rotation rotation;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final (day, total) = RotationService.dayOf(rotation);
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.circular(SxRadius.xl),
        border: Border.all(color: c.hairline),
        gradient: RadialGradient(center: const Alignment(1.0, -1.0), radius: 1.2, colors: [c.primary.withValues(alpha: 0.05), c.surface1]),
      ),
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              StatusPill('Day $day / $total', dot: true),
              const SizedBox(height: 8),
              Text(workout.name, style: SxText.headlineLg.copyWith(color: c.textHigh)),
              const SizedBox(height: 4),
              if (workout.description.isNotEmpty) Text(workout.description, style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(SxRadius.lg)),
            child: Stack(alignment: Alignment.center, children: [
              Icon(Icons.accessibility_new, size: 36, color: c.primary.withValues(alpha: 0.9)),
              Positioned(right: 8, bottom: 8, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle))),
            ]),
          ),
        ]),
        const SizedBox(height: SxSpace.md),
        Row(children: [
          Expanded(child: _Pill(icon: Icons.fitness_center, value: '${workout.exercises.length}', label: 'Exercises')),
          const SizedBox(width: 8),
          Expanded(child: _Pill(icon: Icons.layers_outlined, value: '${workout.totalSets}', label: 'Sets')),
          const SizedBox(width: 8),
          Expanded(child: _Pill(icon: Icons.timer_outlined, value: '~${workout.estimatedMinutes}', label: 'Minutes')),
        ]),
        const SizedBox(height: SxSpace.md),
        SxButton(
          label: 'Start workout',
          trailingIcon: Icons.play_arrow,
          onPressed: workout.exercises.isEmpty ? null : () => AppNav.activeWorkout(context, workout.id),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: () => AppNav.workoutPreview(context, workout.id),
            style: TextButton.styleFrom(minimumSize: const Size(48, 40)),
            child: Text('Preview workout', style: SxText.bodyMd.copyWith(color: c.textBody)),
          ),
        ),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: c.surface3.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(SxRadius.md)),
      child: Row(children: [
        Icon(icon, size: 18, color: c.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: SxText.metricMd.copyWith(color: c.textHigh))),
            Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 9)),
          ]),
        ),
      ]),
    );
  }
}

class _VolumeTile extends StatelessWidget {
  const _VolumeTile({required this.sessions, required this.unit});
  final List<WorkoutSession> sessions;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final kg = VolumeService.totalVolume(sessions);
    final display = Fmt.toDisplayWeight(kg, unit);
    final big = display >= 1000;
    return StatTile(
      label: 'Volume',
      value: big ? Fmt.number(display / 1000) : Fmt.number(display, decimals: 0),
      unit: big ? 't' : Fmt.unit(unit),
      icon: Icons.equalizer,
    );
  }
}

class _PrTile extends StatelessWidget {
  const _PrTile({required this.sessions, required this.from, required this.to});
  final List<WorkoutSession> sessions;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final n = PrService.setBetween(sessions, from, to).length;
    return StatTile(label: 'Records', value: '$n', unit: 'PRs', icon: Icons.emoji_events_outlined, accent: n > 0);
  }
}

class _RecentProgress extends StatelessWidget {
  const _RecentProgress({required this.data, required this.unit, required this.onTap});
  final _Recent data;
  final WeightUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final pr = data.pr;
    return SxCard(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(SxRadius.base)),
          child: Icon(Icons.trending_up, color: c.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text('RECENT PROGRESS', style: SxText.labelCaps.copyWith(color: c.textBody)),
              DeltaBadge('+${Fmt.number(data.percent, decimals: 1)}%'),
            ]),
            const SizedBox(height: 2),
            Text(data.exercise.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.headlineSm.copyWith(color: c.textHigh)),
            const SizedBox(height: 2),
            Text('Est. 1RM ${Fmt.weight(pr.previousValue!, unit)} → ${Fmt.weight(pr.value, unit)} ${Fmt.unit(unit)}',
                style: SxText.metricSm.copyWith(color: c.primary)),
            Text('Best set ${Fmt.setLabel(pr.weightKg, pr.reps, unit)}', style: SxText.bodySm.copyWith(color: c.textBody)),
          ]),
        ),
        Icon(Icons.chevron_right, color: c.textMuted),
      ]),
    );
  }
}

class _UpNext extends StatelessWidget {
  const _UpNext({required this.workout, required this.rotation, required this.onTap});
  final Workout workout;
  final Rotation rotation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final idx = rotation.workoutIds.indexOf(workout.id) + 1;
    return SxCard(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(SxRadius.md)),
          child: Icon(Icons.sports_gymnastics, color: c.textBody),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DAY $idx OF ${rotation.length}', style: SxText.labelCaps.copyWith(color: c.textBody)),
            Text(workout.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.headlineMd.copyWith(color: c.textHigh)),
            Text('${workout.exercises.length} exercises · ${workout.totalSets} sets', style: SxText.bodySm.copyWith(color: c.textBody)),
          ]),
        ),
        Icon(Icons.chevron_right, color: c.textMuted),
      ]),
    );
  }
}

/// Honest placeholder: Health Connect is not integrated yet, so no sleep /
/// heart-rate / readiness numbers are shown.
class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Icon(Icons.bedtime_outlined, color: c.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Recovery', style: SxText.bodyLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
            Text('Connect Health Connect to see sleep and resting heart rate.', style: SxText.bodySm.copyWith(color: c.textBody)),
          ]),
        ),
        const SizedBox(width: 8),
        Flexible(child: StatusPill('Not connected', color: c.textMuted)),
      ]),
    );
  }
}

/// Brand header. Local copy of SxBrandBar that drops the "LOCAL" pill on
/// narrow / large-text layouts instead of overflowing (core SxBrandBar's pill
/// overflows at 320dp × 1.3 text scale).
class _TodayBar extends StatelessWidget implements PreferredSizeWidget {
  const _TodayBar({required this.name, required this.onAvatarTap});
  final String name;
  final VoidCallback onAvatarTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      color: c.canvas,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SxSpace.screenMargin),
            child: LayoutBuilder(builder: (context, box) {
              final showPill = box.maxWidth / MediaQuery.textScalerOf(context).scale(1) >= 340;
              return Row(children: [
                const SxLogo(size: 40),
                const SizedBox(width: 12),
                Flexible(child: Text('StationX', maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.headlineMd.copyWith(color: c.textHigh, fontWeight: FontWeight.w700))),
                if (showPill) ...[const SizedBox(width: 10), const StatusPill('Local', dot: true)],
                const Spacer(),
                GestureDetector(onTap: onAvatarTap, child: SxAvatar(name, size: 40)),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
