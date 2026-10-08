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
import 'workout_section_header.dart';
import 'workout_stats.dart';

/// Workout preview: day header, rotation note, target sequence with last
/// session numbers, start / edit actions.
class WorkoutPreviewPage extends StatelessWidget {
  const WorkoutPreviewPage({super.key, required this.workoutId});
  final String workoutId;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.workouts, app.sessions, app.exercises, app.profile]),
      builder: (context, _) {
        final w = app.workouts.byId(workoutId);
        if (w == null) {
          return const SxScaffold(
            topBar: SxTopBar(title: 'Workout Preview'),
            body: Center(child: ErrorState(message: 'This workout no longer exists. It may have been deleted.')),
          );
        }
        return _Preview(workout: w, app: app);
      },
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.workout, required this.app});
  final Workout workout;
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final WorkoutRepository workouts = app.workouts;
    final SessionRepository sessions = app.sessions;
    final ExerciseRepository exercises = app.exercises;
    final unit = app.profile.profile.unit;
    final c = context.sx;

    final rot = workouts.rotation;
    final idx = rot.workoutIds.indexOf(workout.id);
    final isCurrent = rot.currentWorkoutId == workout.id;
    final muscles = WorkoutStats.muscles(workout, exercises);

    return SxScaffold(
      topBar: SxTopBar(
        title: 'Workout Preview',
        actions: [
          SxIconButton(icon: Icons.tune, tooltip: 'Edit workout structure', filled: false, onPressed: () => AppNav.workoutEditor(context, workout.id)),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SxButton(
            label: 'Start workout',
            icon: Icons.play_arrow,
            onPressed: workout.exercises.isEmpty ? null : () => AppNav.activeWorkout(context, workout.id),
          ),
          const SizedBox(height: 4),
          SxButton(
            label: 'Edit workout structure',
            icon: Icons.tune,
            variant: SxButtonVariant.ghost,
            onPressed: () => AppNav.workoutEditor(context, workout.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(SxSpace.screenMargin, SxSpace.md, SxSpace.screenMargin, SxSpace.lg),
        children: [
          SxCard(
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
                          Text(idx >= 0 ? 'ROTATION • DAY ${idx + 1}' : 'STANDALONE ROUTINE',
                              style: SxText.labelCaps.copyWith(color: c.primary, letterSpacing: 1.2)),
                          const SizedBox(height: 6),
                          Text(workout.name.toUpperCase(), style: SxText.headlineLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            idx >= 0 ? 'Day ${idx + 1} of ${rot.length} • ${rot.length}-Day Rotation' : 'Not part of your rotation',
                            style: SxText.bodyMd.copyWith(color: c.textBody),
                          ),
                        ],
                      ),
                    ),
                    if (idx >= 0) ...[
                      const SizedBox(width: 12),
                      SxInset(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(children: [
                          Text('${idx + 1}'.padLeft(2, '0'), style: SxText.metricMd.copyWith(color: c.primary)),
                          Text('DAY', style: SxText.labelXs.copyWith(color: c.textBody)),
                        ]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: SxSpace.md),
                Row(
                  children: [
                    Expanded(child: _Fact(icon: Icons.format_list_numbered, label: 'Volume', value: '${workout.exercises.length}', unit: 'Ex • ${workout.totalSets} Sets')),
                    const SizedBox(width: 8),
                    Expanded(child: _Fact(icon: Icons.schedule, label: 'Duration', value: '~${workout.estimatedMinutes}', unit: 'min')),
                  ],
                ),
                if (muscles.isNotEmpty) ...[
                  const SizedBox(height: SxSpace.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final m in muscles) _Tag(m.label)],
                  ),
                ],
                const SizedBox(height: SxSpace.md),
                SxInset(
                  color: context.sx.ink.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.published_with_changes, size: 20, color: c.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isCurrent || idx < 0
                              ? 'Rotation advances upon completion. Missed sessions stay queued in sequence.'
                              : 'This is not next in your rotation. Use “Change next” in the Workouts tab to reorder.',
                          style: SxText.bodySm.copyWith(color: c.textBody),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SxSpace.lg),
          const SectionHeader('Target sequence'),
          const SizedBox(height: SxSpace.sm),
          if (workout.exercises.isEmpty)
            SxCard(
              child: EmptyState(
                icon: Icons.playlist_add,
                title: 'No exercises yet',
                message: 'Add exercises to this workout to start training.',
                actionLabel: 'Edit structure',
                onAction: () => AppNav.workoutEditor(context, workout.id),
              ),
            )
          else
            _SectionedSequence(
              sections: WorkoutSections.group(workout.exercises, exercises.all),
              exercises: exercises,
              unit: unit,
              lastSet: (id) => _lastSet(sessions, id),
            ),
        ],
      ),
    );
  }

  SetLog? _lastSet(SessionRepository sessions, String exerciseId) {
    final s = sessions.lastWithExercise(exerciseId);
    return s == null ? null : WorkoutStats.topSet(s, exerciseId);
  }
}

/// Target sequence grouped into muscle sections (grouping comes from [WorkoutSections]; order is
/// the workout's own). Sections can be collapsed; the height change is animated.
class _SectionedSequence extends StatefulWidget {
  const _SectionedSequence({required this.sections, required this.exercises, required this.unit, required this.lastSet});
  final List<WorkoutSection> sections;
  final ExerciseRepository exercises;
  final WeightUnit unit;
  final SetLog? Function(String exerciseId) lastSet;

  @override
  State<_SectionedSequence> createState() => _SectionedSequenceState();
}

class _SectionedSequenceState extends State<_SectionedSequence> {
  final _collapsed = <String>{};

  @override
  Widget build(BuildContext context) {
    final seen = <String, int>{};
    var n = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in widget.sections)
          Builder(builder: (context) {
            final ord = seen.update(s.label, (v) => v + 1, ifAbsent: () => 0);
            final key = '${s.label}#$ord';
            final collapsed = _collapsed.contains(key);
            final first = n;
            n += s.items.length;
            return Column(
              key: ValueKey('section_$key'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WorkoutSectionHeader(
                  section: s,
                  collapsed: collapsed,
                  onToggle: () => setState(() => collapsed ? _collapsed.remove(key) : _collapsed.add(key)),
                ),
                AnimatedSize(
                  duration: SxMotion.of(context, SxMotion.short),
                  curve: SxMotion.enter,
                  alignment: Alignment.topCenter,
                  child: collapsed
                      ? const SizedBox(width: double.infinity)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var j = 0; j < s.items.length; j++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: SxSpace.sm),
                                child: SxStagger(
                                  index: first + j,
                                  child: _SequenceRow(
                                    index: s.startIndex + j,
                                    re: s.items[j],
                                    exercise: widget.exercises.byId(s.items[j].exerciseId),
                                    lastSet: widget.lastSet(s.items[j].exerciseId),
                                    unit: widget.unit,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: SxSpace.xs),
              ],
            );
          }),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value, required this.unit});
  final IconData icon;
  final String label;
  final String value;
  final String unit;

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
                Text(label.toUpperCase(), style: SxText.labelXs.copyWith(color: c.textMuted)),
                Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(value, style: SxText.metricMd.copyWith(color: c.textHigh)),
                    Text(unit, style: SxText.bodySm.copyWith(color: c.textBody)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.base), border: Border.all(color: c.hairline)),
      child: Text(text, style: SxText.metricSm.copyWith(color: c.textBody, fontSize: 12)),
    );
  }
}

class _SequenceRow extends StatelessWidget {
  const _SequenceRow({required this.index, required this.re, required this.exercise, required this.lastSet, required this.unit});
  final int index;
  final RoutineExercise re;
  final Exercise? exercise;
  final SetLog? lastSet;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final name = exercise?.name ?? 'Unknown exercise';
    return SxCard(
      onTap: exercise == null ? null : () => AppNav.exerciseDetails(context, exercise!.id),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.base)),
            child: Text('${index + 1}'.padLeft(2, '0'), style: SxText.metricSm.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: SxText.headlineSm.copyWith(color: c.textHigh), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.repeat, size: 13, color: c.primary),
                      const SizedBox(width: 4),
                      Text(WorkoutStats.setsReps(re), style: SxText.metricSm.copyWith(color: c.primary, fontSize: 12)),
                    ]),
                    if (exercise != null)
                      Text('${exercise!.equipment.label} • ${exercise!.primaryMuscle.label}', style: SxText.bodySm.copyWith(color: c.textBody)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SxInset(
            color: context.sx.ink.withValues(alpha: 0.25),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('LAST SESSION', style: SxText.labelXs.copyWith(color: c.textMuted)),
                const SizedBox(height: 2),
                Text(lastSet == null ? 'No history' : Fmt.setLabel(lastSet!.weightKg, lastSet!.reps, unit),
                    style: SxText.metricSm.copyWith(color: lastSet == null ? c.textMuted : c.textHigh, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
