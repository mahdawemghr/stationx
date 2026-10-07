import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/sx_spacing.dart';
import '../../../core/theme/sx_theme.dart';
import '../../../core/theme/sx_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/domain.dart';
import '../../workouts/swap_exercise_sheet.dart';
import '../active_workout_controller.dart';
import 'plate_calc_sheet.dart';
import 'set_row.dart';

/// Exercise slot: compact row when collapsed, full logging card when expanded.
class ExerciseBlock extends StatelessWidget {
  const ExerciseBlock({
    super.key,
    required this.controller,
    required this.draft,
    required this.index,
    required this.unit,
  });

  final ActiveWorkoutController controller;
  final ExerciseDraft draft;
  final int index;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: SxMotion.base,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: draft.expanded ? _Expanded(controller: controller, draft: draft, index: index, unit: unit) : _Collapsed(controller: controller, draft: draft, index: index, unit: unit),
    );
  }
}

String _subtitle(ExerciseDraft d, WeightUnit unit) {
  final ex = d.exercise;
  if (d.complete) {
    final done = d.sets.where((s) => s.done).toList();
    final top = done.isEmpty ? null : done.last;
    return '${done.length} sets${top == null ? '' : ' • ${Fmt.weight(top.weightKg, unit)}${Fmt.unit(unit)} × ${top.reps}'}';
  }
  final prev = d.prevSets.isEmpty ? null : d.prevSets.last;
  final base = ex.primaryMuscle.label;
  if (prev != null) return '$base • Prev: ${Fmt.setLabel(prev.weightKg, prev.reps, unit)}';
  return '$base • ${d.sets.length} sets × ${d.repMin}–${d.repMax}';
}

class _Collapsed extends StatelessWidget {
  const _Collapsed({required this.controller, required this.draft, required this.index, required this.unit});
  final ActiveWorkoutController controller;
  final ExerciseDraft draft;
  final int index;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final complete = draft.complete;
    return Semantics(
      button: true,
      label: '${draft.exercise.name}, ${draft.doneCount} of ${draft.sets.length} sets',
      child: SxCard(
        onTap: () => controller.toggleExpanded(draft),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(children: [
          _Badge(index: index, complete: complete, active: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(draft.exercise.name,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.headlineSm.copyWith(color: c.textHigh)),
              const SizedBox(height: 2),
              Text(_subtitle(draft, unit), maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.base)),
            child: Text(complete ? '${draft.doneCount}/${draft.sets.length}' : '${draft.sets.length} SETS',
                style: SxText.labelCaps.copyWith(color: complete ? c.positive : c.textBody, fontSize: 10)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.expand_more, color: c.textBody),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.index, required this.complete, required this.active});
  final int index;
  final bool complete;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    if (complete) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle, border: Border.all(color: c.hairline)),
        child: Icon(Icons.check_circle_outline, size: 20, color: c.positive),
      );
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? c.primary : c.surface2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('${index + 1}', style: SxText.metricSm.copyWith(color: active ? c.onPrimary : c.textBody, fontWeight: FontWeight.w700)),
    );
  }
}

class _Expanded extends StatelessWidget {
  const _Expanded({required this.controller, required this.draft, required this.index, required this.unit});
  final ActiveWorkoutController controller;
  final ExerciseDraft draft;
  final int index;
  final WeightUnit unit;

  Future<void> _editWeight(BuildContext context, int i) async {
    final cur = draft.sets[i].weightKg;
    final v = await showNumericKeypad(context,
        title: 'Weight (${Fmt.unit(unit)})',
        initial: cur <= 0 ? null : double.parse(Fmt.toDisplayWeight(cur, unit).toStringAsFixed(2)),
        step: unit == WeightUnit.kg ? 2.5 : 5,
        unit: Fmt.unit(unit));
    if (v != null) controller.setWeight(draft, i, Fmt.fromDisplayWeight(v, unit));
  }

  Future<void> _editReps(BuildContext context, int i) async {
    final v = await showNumericKeypad(context,
        title: 'Reps', initial: draft.sets[i].reps.toDouble(), allowDecimal: false, step: 1, max: 999);
    if (v != null) controller.setReps(draft, i, v.round());
  }

  Future<void> _swap(BuildContext context) async {
    final app = context.app;
    if (draft.doneCount > 0) {
      final ok = await showSxConfirm(context,
          title: 'Replace exercise?',
          message: 'Sets already logged for ${draft.exercise.name} will be cleared.',
          confirmLabel: 'Replace',
          icon: Icons.swap_horiz);
      if (!ok || !context.mounted) return;
    }
    final replacement = await showSwapExerciseSheet(
      context,
      current: draft.exercise,
      sets: draft.sets.length,
      repRange: '${draft.repMin}-${draft.repMax}',
      slotLabel: 'Slot ${index + 1}/${controller.drafts.length} • ${controller.workout.name}',
      excludeIds: {for (final d in controller.drafts) d.exercise.id},
    );
    if (replacement != null) controller.replaceExercise(draft, replacement, app.sessions);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final ex = draft.exercise;
    final prevTop = draft.prevSets.isEmpty ? null : draft.prevSets.last;
    final active = draft.activeSetIndex;
    final meta = [
      ex.primaryMuscle.label,
      for (final m in ex.secondaryMuscles.take(2)) m.label,
      ex.equipment.label,
    ].map((e) => e.toUpperCase()).join(' • ');

    return SxCard(
      padding: const EdgeInsets.all(12),
      borderColor: c.hairline,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _Badge(index: index, complete: draft.complete, active: true),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(ex.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.headlineMd.copyWith(color: c.textHigh)),
          ),
          const SizedBox(width: 6),
          _HeaderButton(icon: Icons.swap_horiz, label: 'Swap', onTap: () => _swap(context)),
          const SizedBox(width: 4),
          _HeaderButton(icon: Icons.expand_less, tooltip: 'Collapse', onTap: () => controller.toggleExpanded(draft)),
        ]),
        const SizedBox(height: 6),
        Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
        const SizedBox(height: 12),
        SxInset(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(SxRadius.base), border: Border.all(color: c.hairline)),
              child: Icon(Icons.fitness_center, size: 22, color: c.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TARGET: ${ex.primaryMuscle.label.toUpperCase()}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textHigh, fontSize: 10)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.history, size: 14, color: c.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(prevTop == null ? 'No previous session' : 'Last: ${Fmt.setLabel(prevTop.weightKg, prevTop.reps, unit)}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
                  ),
                ]),
              ]),
            ),
            if (ex.tempo != null) ...[
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('TEMPO', style: SxText.labelCaps.copyWith(color: c.textMuted, fontSize: 9)),
                Text(ex.tempo!, style: SxText.metricSm.copyWith(color: c.primary)),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        SetTableHeader(unit: unit),
        for (var i = 0; i < draft.sets.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Dismissible(
              key: ObjectKey(draft.sets[i]),
              direction: draft.sets.length > 1 ? DismissDirection.endToStart : DismissDirection.none,
              onDismissed: (_) => controller.removeSet(draft, i),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(color: c.dangerContainer, borderRadius: BorderRadius.circular(SxRadius.md)),
                child: Icon(Icons.delete_outline, color: c.danger),
              ),
              child: SetRowView(
                index: i,
                set: draft.sets[i],
                prev: i < draft.prevSets.length ? draft.prevSets[i] : null,
                active: i == active,
                unit: unit,
                onWeight: () => _editWeight(context, i),
                onReps: () => _editReps(context, i),
                onToggle: () => controller.toggleSet(draft, i),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: _TextAction(icon: Icons.add_circle_outline, label: 'Add Set', color: c.primary, onTap: () => controller.addSet(draft)),
          ),
          Expanded(
            child: _TextAction(
              icon: Icons.tune,
              label: 'Plate Calc',
              color: c.textBody,
              alignEnd: true,
              onTap: () {
                final i = active < 0 ? draft.sets.length - 1 : active;
                showPlateCalculator(context, targetKg: draft.sets[i].weightKg, unit: unit);
              },
            ),
          ),
        ]),
        if (draft.recommendation != null && !draft.complete) ...[
          const SizedBox(height: 8),
          _OverloadCard(rec: draft.recommendation!, unit: unit),
        ],
      ]),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap, this.label, this.tooltip});
  final IconData icon;
  final String? label;
  final String? tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      button: true,
      label: label ?? tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SxRadius.md),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 10),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md), border: Border.all(color: c.hairline)),
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 20, color: c.textBody),
            if (label != null) ...[const SizedBox(width: 4), Text(label!, style: SxText.labelUi.copyWith(color: c.textHigh))],
          ]),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.icon, required this.label, required this.color, required this.onTap, this.alignEnd = false});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SxRadius.base),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: SxText.bodyMd.copyWith(color: color, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }
}

/// "Smart Overload" card. Content comes from ProgressionService only.
class _OverloadCard extends StatelessWidget {
  const _OverloadCard({required this.rec, required this.unit});
  final ProgressionRecommendation rec;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final headline = rec.isIncrease
        ? 'Recommended: Increase load to ${Fmt.weight(rec.weightKg, unit)} ${Fmt.unit(unit)} × ${rec.repMin}–${rec.repMax}.'
        : 'Recommended: ${Fmt.weight(rec.weightKg, unit)} ${Fmt.unit(unit)} × ${rec.repMin}–${rec.repMax}.';
    return Semantics(
      container: true,
      label: '$headline ${rec.reason}',
      child: SxInset(
        padding: const EdgeInsets.all(10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(SxRadius.base)),
            child: Icon(Icons.trending_up, color: c.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rec.isIncrease ? 'SMART OVERLOAD' : 'PROGRESSION',
                  style: SxText.labelCaps.copyWith(color: c.primary, fontSize: 10, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('$headline ${rec.reason}', style: SxText.bodyMd.copyWith(color: c.textBody)),
            ]),
          ),
        ]),
      ),
    );
  }
}
