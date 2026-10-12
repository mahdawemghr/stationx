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
import '../onboarding/schedule_setup_entry.dart';

/// Today tab (Stitch: today_home). The hero is the *next workout in the
/// rotation* (index based, never date based).
///
/// Perf: the week range, the week's sessions, the PR count and the "recent
/// progress" lookup are computed once and re-computed only when the sessions or
/// the exercise catalog change (or the calendar day rolls over), never per build.
class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayData {
  const _TodayData({
    required this.day,
    required this.weekStart,
    required this.weekEnd,
    required this.week,
    required this.prCount,
    required this.recent,
  });
  final DateTime day;
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<WorkoutSession> week;
  final int prCount;
  final _Recent? recent;
}

class _TodayPageState extends State<TodayPage> {
  _TodayData? _data;
  Listenable? _watched;
  AppController? _app;

  void _invalidate() => _data = null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.app;
    if (identical(app, _app)) return;
    _watched?.removeListener(_invalidate);
    _app = app;
    _watched = Listenable.merge([app.sessions, app.exercises])
      ..addListener(_invalidate);
    _data = null;
  }

  @override
  void dispose() {
    _watched?.removeListener(_invalidate);
    super.dispose();
  }

  _TodayData _derive(AppController app, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final cached = _data;
    if (cached != null && cached.day == today) return cached;
    final weekStart = VolumeService.startOfWeek(now);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final all = app.sessions.sessions;
    return _data = _TodayData(
      day: today,
      weekStart: weekStart,
      weekEnd: weekEnd,
      week: app.sessions.between(weekStart, weekEnd),
      prCount: PrService.setBetween(all, weekStart, weekEnd).length,
      recent: _recentProgress(all, app.exercises),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([
        app,
        app.workouts,
        app.sessions,
        app.exercises,
        app.profile,
        app.health,
        app.workoutDraft,
        app.cardioDraft,
        ScheduleSetupPrompt.dismissed,
      ]),
      builder: (context, _) {
        final profile = app.profile.profile;
        final now = DateTime.now();
        final workout = app.workouts.currentWorkout;
        final next = app.workouts.nextWorkout;
        final rotation = app.workouts.rotation;
        final data = _derive(app, now);
        final week = data.week;
        final recent = data.recent;
        final draft = app.workoutDraft.current;
        final cardioDraft = app.cardioDraft.current;
        final c = context.sx;

        return SxScaffold(
          topBar: _TodayBar(
            name: profile.name,
            onAvatarTap: () => AppNav.switchTab(context, 3),
          ),
          gap: SxSpace.md,
          animateIn: true,
          children: [
            _DateHeader(
              now: now,
              name: profile.name.split(' ').first,
              workout: workout,
            ),
            // Omitted (not a zero-height child) when hidden so it adds no extra gap.
            if (ScheduleSetupPromptCard.shouldShow(app))
              const ScheduleSetupPromptCard(),
            // Resume card + hero share one slot so the card can animate in/out without leaving a gap.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: SxMotion.of(context, SxMotion.short),
                  curve: SxMotion.enter,
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SxSwap(
                        alignment: Alignment.topCenter,
                        child: draft == null
                            ? const SizedBox(
                                key: ValueKey('no-resume'),
                                width: double.infinity,
                              )
                            : Padding(
                                key: const ValueKey('resume'),
                                padding: const EdgeInsets.only(
                                  bottom: SxSpace.md,
                                ),
                                child: ResumeWorkoutCard(draft: draft),
                              ),
                      ),
                    ],
                  ),
                ),
                if (cardioDraft != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: SxSpace.md),
                    child: ResumeCardioCard(draft: cardioDraft),
                  ),
                SxSwap(
                  alignment: Alignment.topCenter,
                  child: workout == null
                      ? EmptyState(
                          key: const ValueKey('empty'),
                          icon: Icons.fitness_center,
                          title: 'No workouts yet',
                          message: 'Create a workout to start your rotation.',
                          actionLabel: 'Open Workouts',
                          onAction: () => AppNav.switchTab(context, 1),
                        )
                      : RepaintBoundary(
                          key: ValueKey('hero-${workout.id}'),
                          child: _HeroCard(
                            workout: workout,
                            rotation: rotation,
                          ),
                        ),
                ),
              ],
            ),
            SectionHeader(
              'This week',
              icon: Icons.calendar_view_week,
              trailingText:
                  'Goal: ${WeekPlan.summary(profile.weeklySessionTarget)}',
            ),
            Row(
              children: [
                Expanded(
                  child: _CountStat(
                    label: 'Sessions',
                    icon: Icons.check_circle_outline,
                    unit: 'done',
                    value: week.length.toDouble(),
                    format: (v) => '${v.round()}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _volumeTile(week, profile.unit)),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountStat(
                    label: 'Records',
                    icon: Icons.emoji_events_outlined,
                    unit: 'PRs',
                    accent: data.prCount > 0,
                    value: data.prCount.toDouble(),
                    format: (v) => '${v.round()}',
                  ),
                ),
              ],
            ),
            if (recent != null)
              _RecentProgress(
                data: recent,
                unit: profile.unit,
                onTap: () =>
                    AppNav.exerciseHistory(context, recent.exercise.id),
              )
            else if (app.sessions.sessions.isEmpty)
              SxCard(
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: c.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complete a workout to see your progress here.',
                        style: SxText.bodyMd.copyWith(color: c.textBody),
                      ),
                    ),
                  ],
                ),
              ),
            if (next != null && workout != null && next.id != workout.id) ...[
              const SectionHeader('Up next', trailingText: 'In rotation'),
              _UpNext(
                workout: next,
                rotation: rotation,
                onTap: () => AppNav.workoutPreview(context, next.id),
              ),
            ],
            // Only where Health Connect can exist (Android); hidden elsewhere.
          ],
        );
      },
    );
  }

  Widget _volumeTile(List<WorkoutSession> sessions, WeightUnit unit) {
    final display = Fmt.toDisplayWeight(
      VolumeService.totalVolume(sessions),
      unit,
    );
    final big = display >= 1000;
    return _CountStat(
      label: 'Volume',
      icon: Icons.equalizer,
      unit: big ? 't' : Fmt.unit(unit),
      value: big ? display / 1000 : display,
      format: (v) => big ? Fmt.number(v) : Fmt.number(v, decimals: 0),
    );
  }

  /// Latest estimated-1RM PR that improved on a previous best.
  _Recent? _recentProgress(
    List<WorkoutSession> sessions,
    ExerciseRepository ex,
  ) {
    for (final pr in PrService.all(PrType.estimated1Rm, sessions)) {
      final prev = pr.previousValue;
      final e = ex.byId(pr.exerciseId);
      if (prev == null || e == null || prev <= 0) continue;
      return _Recent(e, pr, PercentChange.of(prev, pr.value)!);
    }
    return null;
  }
}

/// StatTile look-alike whose number counts up on first build and on later changes.
class _CountStat extends StatelessWidget {
  const _CountStat({
    required this.label,
    required this.icon,
    required this.unit,
    required this.value,
    required this.format,
    this.accent = false,
  });
  final String label;
  final IconData icon;
  final String unit;
  final double value;
  final String Function(double) format;
  final bool accent;

  @override
  Widget build(BuildContext context) => StatTile.number(
    label: label,
    icon: icon,
    unit: unit,
    value: value,
    formatter: format,
    accent: accent,
  );
}

class _Recent {
  const _Recent(this.exercise, this.pr, this.percent);
  final Exercise exercise;
  final StrengthPr pr;
  final double percent;
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.now,
    required this.name,
    required this.workout,
  });
  final DateTime now;
  final String name;
  final Workout? workout;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Fmt.dateLong(now).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SxText.labelCaps.copyWith(color: c.textBody),
              ),
              const SizedBox(height: 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8,
                children: [
                  Text(
                    'Today',
                    style: SxText.headlineLg.copyWith(color: c.textHigh),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '· ${Fmt.greeting(now)}, $name',
                      style: SxText.bodySm.copyWith(color: c.textBody),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Quick options',
          color: c.surface3,
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.surface1,
              borderRadius: BorderRadius.circular(SxRadius.md),
              border: Border.all(color: c.hairline),
            ),
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
            const PopupMenuItem(
              value: 'calendar',
              child: Text('Calendar & history'),
            ),
            if (workout != null)
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit this workout'),
              ),
            const PopupMenuItem(
              value: 'library',
              child: Text('Exercise library'),
            ),
          ],
        ),
      ],
    );
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
    final catalog = context.app.exercises;
    // Muscle tags in section order (Forearms included), one per muscle.
    final tags = [
      for (final g in WorkoutSections.group(
        workout.exercises,
        catalog.all,
        mode: ArrangeMode.musclesOnly,
      ))
        g.label,
    ];
    final workoutMuscles = <MuscleGroup>{
      for (final re in workout.exercises)
        ?catalog.byId(re.exerciseId)?.primaryMuscle,
    };
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.circular(SxRadius.xl),
        border: Border.all(color: c.hairline),
        gradient: RadialGradient(
          center: const Alignment(1.0, -1.0),
          radius: 1.2,
          colors: [c.primary.withValues(alpha: 0.035), c.surface1],
        ),
      ),
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
                    StatusPill('Day $day / $total', dot: true),
                    const SizedBox(height: 8),
                    Text(
                      workout.name,
                      style: SxText.headlineLg.copyWith(color: c.textHigh),
                    ),
                    const SizedBox(height: 4),
                    if (workout.description.isNotEmpty)
                      Text(
                        workout.description,
                        style: SxText.bodySm.copyWith(color: c.textBody),
                      ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tags.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SxText.labelXs.copyWith(color: c.primary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: c.surface3,
                  borderRadius: BorderRadius.circular(SxRadius.lg),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MuscleMap(
                      primary: workoutMuscles,
                      height: 46,
                      view: MuscleView.both,
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: SxSpace.md),
          Row(
            children: [
              Expanded(
                child: _Pill(
                  icon: Icons.fitness_center,
                  value: '${workout.exercises.length}',
                  label: 'Exercises',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Pill(
                  icon: Icons.layers_outlined,
                  value: '${workout.totalSets}',
                  label: 'Sets',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Pill(
                  icon: Icons.timer_outlined,
                  value: '~${workout.estimatedMinutes}',
                  label: 'Minutes',
                ),
              ),
            ],
          ),
          const SizedBox(height: SxSpace.md),
          SxButton(
            label: 'Start workout',
            trailingIcon: Icons.play_arrow,
            onPressed: workout.exercises.isEmpty
                ? null
                : () => AppNav.activeWorkout(context, workout.id),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => AppNav.workoutPreview(context, workout.id),
              style: TextButton.styleFrom(minimumSize: const Size(48, 40)),
              child: Text(
                'Preview workout',
                style: SxText.bodyMd.copyWith(color: c.textBody),
              ),
            ),
          ),
        ],
      ),
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
      decoration: BoxDecoration(
        color: c.surface3.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(SxRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: SxText.metricMd.copyWith(color: c.textHigh),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    style: SxText.labelXs.copyWith(color: c.textBody),
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

class _RecentProgress extends StatelessWidget {
  const _RecentProgress({
    required this.data,
    required this.unit,
    required this.onTap,
  });
  final _Recent data;
  final WeightUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final pr = data.pr;
    return SxCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.surface3,
              borderRadius: BorderRadius.circular(SxRadius.base),
            ),
            child: Icon(Icons.trending_up, color: c.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'RECENT PROGRESS',
                      style: SxText.labelCaps.copyWith(color: c.textBody),
                    ),
                    DeltaBadge('+${Fmt.number(data.percent, decimals: 1)}%'),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  data.exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SxText.headlineSm.copyWith(color: c.textHigh),
                ),
                const SizedBox(height: 2),
                Text(
                  'Est. 1RM ${Fmt.weight(pr.previousValue!, unit)} → ${Fmt.weight(pr.value, unit)} ${Fmt.unit(unit)}',
                  style: SxText.metricSm.copyWith(color: c.primary),
                ),
                Text(
                  'Best set ${Fmt.setLabel(pr.weightKg, pr.reps, unit)}',
                  style: SxText.bodySm.copyWith(color: c.textBody),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: c.textMuted),
        ],
      ),
    );
  }
}

class _UpNext extends StatelessWidget {
  const _UpNext({
    required this.workout,
    required this.rotation,
    required this.onTap,
  });
  final Workout workout;
  final Rotation rotation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final idx = rotation.workoutIds.indexOf(workout.id) + 1;
    return SxCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.surface3,
              borderRadius: BorderRadius.circular(SxRadius.md),
            ),
            child: Icon(Icons.sports_gymnastics, color: c.textBody),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAY $idx OF ${rotation.length}',
                  style: SxText.labelCaps.copyWith(color: c.textBody),
                ),
                Text(
                  workout.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SxText.headlineMd.copyWith(color: c.textHigh),
                ),
                Text(
                  '${workout.exercises.length} exercises · ${workout.totalSets} sets',
                  style: SxText.bodySm.copyWith(color: c.textBody),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: c.textMuted),
        ],
      ),
    );
  }
}

/// Brand header. Local copy of SxBrandBar that drops the status pill on
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
            padding: const EdgeInsets.symmetric(
              horizontal: SxSpace.screenMargin,
            ),
            child: LayoutBuilder(
              builder: (context, box) {
                final showPill =
                    box.maxWidth / MediaQuery.textScalerOf(context).scale(1) >=
                    340;
                return Row(
                  children: [
                    const SxLogo(size: 40, decorative: true),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'StationX',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SxText.headlineMd.copyWith(
                          color: c.textHigh,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (showPill) ...[
                      const SizedBox(width: 12),
                      ListenableBuilder(
                        listenable: context.app,
                        builder: (context, _) => context.app.refreshFailed
                            ? StatusPill(
                                'Offline',
                                dot: true,
                                color: c.textBody,
                              )
                            : const StatusPill('Online', dot: true),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Semantics(
                      button: true,
                      label: 'Profile, $name',
                      excludeSemantics: true,
                      onTap: onAvatarTap,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onAvatarTap,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(child: SxAvatar(name, size: 40)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// "Resume workout": an unfinished session survived (app closed / killed). Resume reopens the
/// logger with everything restored; Discard drops it after a confirmation.
class ResumeWorkoutCard extends StatelessWidget {
  const ResumeWorkoutCard({super.key, required this.draft});
  final WorkoutDraft draft;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    final name = app.workouts.byId(draft.workoutId)?.name ?? draft.workoutName;
    void resume() => AppNav.activeWorkout(
      context,
      draft.workoutId,
      backdate: draft.backdate,
    );
    return SxCard(
      borderColor: c.primaryBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_outline, color: c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume workout',
                      style: SxText.headlineSm.copyWith(color: c.textHigh),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$name · ${draft.doneSets} of ${draft.totalSets} sets done',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SxText.bodySm.copyWith(color: c.textBody),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SxButton(
                  label: 'Resume',
                  icon: Icons.play_arrow,
                  height: 48,
                  onPressed: resume,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SxButton(
                  label: 'Discard',
                  icon: Icons.delete_outline,
                  variant: SxButtonVariant.secondary,
                  height: 48,
                  onPressed: () async {
                    final ok = await showSxConfirm(
                      context,
                      title: 'Discard workout?',
                      message:
                          'Everything logged in this unfinished session will be lost.',
                      confirmLabel: 'Discard',
                      cancelLabel: 'Keep it',
                      destructive: true,
                      icon: Icons.delete_forever,
                    );
                    if (ok) await app.workoutDraft.clear();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Resume cardio": a live cardio session survived the app being closed or killed. Its clock kept
/// running (or stayed paused) exactly as left.
class ResumeCardioCard extends StatelessWidget {
  const ResumeCardioCard({super.key, required this.draft});
  final ActiveCardioDraft draft;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    String name = draft.kind.label;
    for (final a in app.cardio.customActivities) {
      if (a.id == draft.customActivityId) name = a.name;
    }
    return SxCard(
      borderColor: c.primaryBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume cardio',
                      style: SxText.headlineSm.copyWith(color: c.textHigh),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$name · ${Fmt.clock(draft.activeSeconds)}${draft.paused ? ' · paused' : ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SxText.bodySm.copyWith(color: c.textBody),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SxButton(
                  label: 'Resume',
                  icon: Icons.play_arrow,
                  height: 48,
                  onPressed: () => AppNav.activeCardio(
                    context,
                    draft.kind,
                    targetMinutes: draft.targetMinutes,
                    targetKm: draft.targetKm,
                    customActivityId: draft.customActivityId,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SxButton(
                  label: 'Discard',
                  icon: Icons.delete_outline,
                  variant: SxButtonVariant.secondary,
                  height: 48,
                  onPressed: () async {
                    final ok = await showSxConfirm(
                      context,
                      title: 'Discard session?',
                      message:
                          'The time and distance of this unfinished cardio session will be lost.',
                      confirmLabel: 'Discard',
                      cancelLabel: 'Keep it',
                      destructive: true,
                      icon: Icons.delete_forever,
                    );
                    if (ok) await app.cardioDraft.clear();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
