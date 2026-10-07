import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'exercise_stats.dart';
import 'exercise_widgets.dart';

/// Exercise details: PR / est. 1RM / volume from domain services, muscle
/// profile and execution steps from the catalog.
class ExerciseDetailsPage extends StatelessWidget {
  const ExerciseDetailsPage({super.key, required this.exerciseId});
  final String exerciseId;

  Future<void> _addToRoutine(BuildContext context, Exercise e) async {
    final app = context.app;
    final workouts = app.workouts.workouts;
    final profile = app.profile.profile;
    final picked = await showSxSheet<Workout>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.md),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ADD TO ROUTINE', style: SxText.headlineMd.copyWith(color: ctx.sx.textHigh)),
          const SizedBox(height: 4),
          Text('Choose the workout day that should include ${e.name}.', style: SxText.bodyMd.copyWith(color: ctx.sx.textBody)),
          const SizedBox(height: SxSpace.md),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: workouts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final w = workouts[i];
                final has = w.exercises.any((x) => x.exerciseId == e.id);
                return SxCard(
                  padding: const EdgeInsets.all(14),
                  onTap: has ? null : () => Navigator.pop(ctx, w),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(w.name, style: SxText.headlineSm.copyWith(color: ctx.sx.textHigh)),
                        Text('${w.exercises.length} exercises · ${w.totalSets} sets', style: SxText.bodySm.copyWith(color: ctx.sx.textBody)),
                      ]),
                    ),
                    Icon(has ? Icons.check_circle : Icons.add_circle_outline, color: has ? ctx.sx.textMuted : ctx.sx.primary),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
    if (picked == null || !context.mounted) return;
    await app.workouts.saveWorkout(picked.copyWith(exercises: [
      ...picked.exercises,
      RoutineExercise(exerciseId: e.id, sets: profile.defaultSets, repMin: profile.defaultRepMin, repMax: profile.defaultRepMax),
    ]));
    if (context.mounted) showSxSnack(context, 'Added to ${picked.name}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.exercises, app.sessions, app.profile, app.workouts]),
      builder: (context, _) {
        final ex = app.exercises.byId(exerciseId);
        if (ex == null) {
          return const SxScaffold(
            topBar: SxTopBar(title: 'Exercise Details'),
            children: [ErrorState(message: 'This exercise no longer exists.')],
          );
        }
        final unit = app.profile.profile.unit;
        final u = Fmt.unit(unit);
        final sessions = app.sessions.sessions;
        final prs = PrService.forExercise(ex.id, sessions);
        final stats = statsFor(ex.id, sessions);
        final heaviest = prs[PrType.heaviestWeight];
        final e1rm = prs[PrType.estimated1Rm];
        final totalVolume = stats.fold(0.0, (a, s) => a + s.volume);
        final totalReps = stats.fold(0, (a, s) => a + s.sets.fold(0, (b, x) => b + x.reps));

        return SxScaffold(
          topBar: SxTopBar(title: 'Exercise Details', subtitle: ex.isCustom ? 'CUSTOM EXERCISE' : 'LIBRARY'),
          bottom: Row(children: [
            Expanded(flex: 2, child: SxButton(label: 'History', icon: Icons.insights, variant: SxButtonVariant.secondary, onPressed: () => AppNav.exerciseHistory(context, ex.id))),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: SxButton(label: 'Add to routine', icon: Icons.add_circle_outline, onPressed: () => _addToRoutine(context, ex))),
          ]),
          children: [
            _Hero(exercise: ex),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ex.name, style: SxText.headlineLg.copyWith(color: c.textHigh)),
              if (ex.movementPattern.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(muscleLine(ex), style: SxText.bodyMd.copyWith(color: c.textBody)),
                ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Tag(icon: equipmentIcon(ex.equipment), label: ex.equipment.label),
                if (ex.movementPattern.isNotEmpty) _Tag(icon: Icons.sync_alt, label: ex.movementPattern),
                if (ex.tempo != null) _Tag(icon: Icons.speed, label: 'Tempo ${ex.tempo}'),
              ]),
            ]),
            StretchRow(children: [
              Expanded(
                child: StatTile(
                  label: 'PR',
                  icon: Icons.emoji_events_outlined,
                  value: heaviest == null ? '—' : Fmt.weight(heaviest.value, unit),
                  unit: heaviest == null ? null : u,
                  caption: heaviest == null ? 'Not logged' : '${heaviest.reps} reps',
                  height: 104,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  label: 'Est. 1RM',
                  icon: Icons.calculate_outlined,
                  value: e1rm == null ? '—' : Fmt.weight(e1rm.value, unit),
                  unit: e1rm == null ? null : u,
                  caption: e1rm?.delta == null ? 'Epley estimate' : '+${Fmt.weight(e1rm!.delta!, unit)} vs prev PR',
                  accent: e1rm != null,
                  height: 104,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  label: 'Volume',
                  icon: Icons.equalizer,
                  value: stats.isEmpty ? '—' : Fmt.number(Fmt.toDisplayWeight(totalVolume, unit) / 1000),
                  unit: stats.isEmpty ? null : 't',
                  caption: stats.isEmpty ? 'No sets yet' : '$totalReps total reps',
                  height: 104,
                ),
              ),
            ]),
            if (stats.isEmpty)
              SxCard(
                child: Row(children: [
                  Icon(Icons.info_outline, color: c.textBody),
                  const SizedBox(width: 12),
                  Expanded(child: Text('No sets logged for this exercise yet. Records appear after your first completed workout.', style: SxText.bodyMd.copyWith(color: c.textBody))),
                ]),
              ),
            _MuscleProfile(exercise: ex),
            if (ex.instructions.isNotEmpty) _Protocol(steps: ex.instructions),
            Text('1RM is estimated with the Epley formula (W × (1 + R/30)) — an estimate, not a tested max.',
                style: SxText.bodySm.copyWith(color: c.textMuted)),
          ],
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SxRadius.md),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.primary.withValues(alpha: 0.10), c.surface2]),
            border: Border.all(color: c.hairline),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(equipmentIcon(exercise.equipment), size: 44, color: c.primary),
            const SizedBox(height: 8),
            Text(exercise.primaryMuscle.label.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.primary, letterSpacing: 2)),
          ]),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          StatusPill('Primary ${exercise.primaryMuscle.label}', dot: true),
          for (final m in exercise.secondaryMuscles) StatusPill('${m.label} assist', color: c.textBody),
        ]),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.base), border: Border.all(color: c.hairline)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: c.primary),
        const SizedBox(width: 6),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: SxText.metricSm.copyWith(color: c.textBody, fontSize: 12))),
      ]),
    );
  }
}

class _MuscleProfile extends StatelessWidget {
  const _MuscleProfile({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.accessibility_new, color: c.primary),
          const SizedBox(width: 10),
          Expanded(child: Text('Musculoskeletal Profile', style: SxText.headlineSm.copyWith(color: c.textHigh))),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(exercise.primaryMuscle.label, style: SxText.bodyMd.copyWith(color: c.textHigh))),
          Text('PRIMARY', style: SxText.labelCaps.copyWith(color: c.primary)),
        ]),
        const SizedBox(height: 8),
        const SxLinearMeter(value: 1, height: 8),
        if (exercise.secondaryMuscles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('SECONDARY SYNERGY', style: SxText.labelCaps.copyWith(color: c.positive)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in exercise.secondaryMuscles) _Tag(icon: Icons.circle, label: m.label),
          ]),
        ],
      ]),
    );
  }
}

class _Protocol extends StatelessWidget {
  const _Protocol({required this.steps});
  final List<ExerciseStep> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.format_list_bulleted, color: c.primary),
          const SizedBox(width: 10),
          Expanded(child: Text('Execution Protocol', style: SxText.headlineSm.copyWith(color: c.textHigh))),
          Text('${steps.length} PHASES', style: SxText.labelCaps.copyWith(color: c.textBody)),
        ]),
        const SizedBox(height: 12),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SxInset(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((i + 1).toString().padLeft(2, '0'), style: SxText.metricMd.copyWith(color: c.primary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(steps[i].title, style: SxText.headlineSm.copyWith(color: c.textHigh, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(steps[i].text, style: SxText.bodyMd.copyWith(color: c.textBody)),
                  ]),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}
