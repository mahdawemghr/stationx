import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;

import '../../../app/app_scope.dart';
import '../../../app/nav.dart';
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
/// When a slot becomes expanded (e.g. the next exercise opens after the last set) it
/// scrolls into view.
class ExerciseBlock extends StatefulWidget {
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

  /// Test hook: called with the block index on every build of a block.
  @visibleForTesting
  static void Function(int index)? debugOnBuild;

  @override
  State<ExerciseBlock> createState() => _ExerciseBlockState();
}

class _ExerciseBlockState extends State<ExerciseBlock> {
  late bool _wasExpanded = widget.draft.expanded;
  late bool _wasComplete = widget.draft.complete;
  // Latched once the user changed the expansion: from then on the swapped-in card fades in.
  bool _animateSwap = false;

  @override
  Widget build(BuildContext context) {
    // Only this exercise's own edits rebuild the block (see ExerciseDraft.touch).
    return ListenableBuilder(
      listenable: widget.draft,
      builder: (context, _) {
        ExerciseBlock.debugOnBuild?.call(widget.index);
        return _content(context);
      },
    );
  }

  Widget _content(BuildContext context) {
    final d = widget.draft;
    final expanded = d.expanded;
    final justCompleted = d.complete && !_wasComplete;
    if (expanded != _wasExpanded) _animateSwap = true;
    if (expanded && !_wasExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.ensureVisible(
          context,
          duration: SxMotion.of(context, SxMotion.standard),
          alignment: 0.05,
          curve: SxMotion.enter,
        );
      });
    }
    _wasExpanded = expanded;
    _wasComplete = d.complete;
    Widget card = expanded
        ? _Expanded(
            controller: widget.controller,
            draft: d,
            index: widget.index,
            unit: widget.unit,
          )
        : _Collapsed(
            controller: widget.controller,
            draft: d,
            index: widget.index,
            unit: widget.unit,
            celebrate: justCompleted,
          );
    if (_animateSwap) {
      card = SxFadeSlideIn(
        key: ValueKey<bool>(expanded),
        dy: 0,
        duration: SxMotion.short,
        child: card,
      );
    }
    return RepaintBoundary(
      child: AnimatedSize(
        duration: SxMotion.of(context, SxMotion.short),
        curve: SxMotion.enter,
        alignment: Alignment.topCenter,
        child: card,
      ),
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
  if (prev != null) {
    return '$base • Prev: ${Fmt.setLabel(prev.weightKg, prev.reps, unit)}';
  }
  return '$base • ${d.sets.length} sets × ${d.repMin}–${d.repMax}';
}

class _Collapsed extends StatelessWidget {
  const _Collapsed({
    required this.controller,
    required this.draft,
    required this.index,
    required this.unit,
    this.celebrate = false,
  });
  final ActiveWorkoutController controller;
  final ExerciseDraft draft;
  final int index;
  final WeightUnit unit;

  /// The exercise was just finished: its check badge pops once.
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final complete = draft.complete;
    return Semantics(
      button: true,
      label:
          '${draft.exercise.name}, ${draft.doneCount} of ${draft.sets.length} sets',
      child: SxCard(
        onTap: () => controller.toggleExpanded(draft),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _Badge(
              index: index,
              complete: complete,
              active: false,
              pop: celebrate,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.exercise.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SxText.headlineSm.copyWith(color: c.textHigh),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(draft, unit),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SxText.bodySm.copyWith(color: c.textBody),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(SxRadius.base),
              ),
              child: Text(
                complete
                    ? '${draft.doneCount}/${draft.sets.length}'
                    : '${draft.sets.length} SETS',
                style: SxText.labelXs.copyWith(
                  color: complete ? c.positive : c.textBody,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, color: c.textBody),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.index,
    required this.complete,
    required this.active,
    this.pop = false,
  });
  final int index;
  final bool complete;
  final bool active;
  final bool pop;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    if (complete) {
      final badge = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: c.surface2,
          shape: BoxShape.circle,
          border: Border.all(color: c.hairline),
        ),
        child: Icon(Icons.check_circle_outline, size: 20, color: c.positive),
      );
      return pop ? SxPop(child: badge) : badge;
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? c.primary : c.surface2,
        borderRadius: BorderRadius.circular(SxRadius.xs),
      ),
      child: Text(
        '${index + 1}',
        style: SxText.metricSm.copyWith(
          color: active ? c.onPrimary : c.textBody,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Expanded extends StatelessWidget {
  const _Expanded({
    required this.controller,
    required this.draft,
    required this.index,
    required this.unit,
  });
  final ActiveWorkoutController controller;
  final ExerciseDraft draft;
  final int index;
  final WeightUnit unit;

  Future<void> _editWeight(BuildContext context, int i) async {
    final cur = draft.sets[i].weightKg;
    final v = await showNumericKeypad(
      context,
      title: 'Weight (${Fmt.unit(unit)})',
      initial: cur <= 0
          ? null
          : double.parse(Fmt.toDisplayWeight(cur, unit).toStringAsFixed(2)),
      step: unit == WeightUnit.kg ? 2.5 : 5,
      unit: Fmt.unit(unit),
    );
    if (v != null) {
      controller.setWeight(draft, i, Fmt.fromDisplayWeight(v, unit));
    }
  }

  Future<void> _editReps(BuildContext context, int i) async {
    final v = await showNumericKeypad(
      context,
      title: 'Reps',
      initial: draft.sets[i].reps.toDouble(),
      allowDecimal: false,
      step: 1,
      max: 999,
    );
    if (v != null) controller.setReps(draft, i, v.round());
  }

  /// Removes a set; a logged (done) set can be brought back from the snackbar.
  void _removeWithUndo(BuildContext context, int i) {
    final wasDone = draft.sets[i].done;
    final removed = controller.removeSet(draft, i);
    if (removed == null || !wasDone) return;
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text('Set ${i + 1} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => controller.insertSet(draft, i, removed),
        ),
      ),
    );
  }

  Future<void> _swap(BuildContext context) async {
    final app = context.app;
    if (draft.doneCount > 0) {
      final ok = await showSxConfirm(
        context,
        title: 'Replace exercise?',
        message:
            'Sets already logged for ${draft.exercise.name} will be cleared.',
        confirmLabel: 'Replace',
        icon: Icons.swap_horiz,
      );
      if (!ok || !context.mounted) return;
    }
    final replacement = await showSwapExerciseSheet(
      context,
      current: draft.exercise,
      sets: draft.sets.length,
      repRange: '${draft.repMin}-${draft.repMax}',
      slotLabel:
          'Slot ${index + 1}/${controller.drafts.length} • ${controller.workout.name}',
      excludeIds: {for (final d in controller.drafts) d.exercise.id},
    );
    if (replacement != null) {
      controller.replaceExercise(draft, replacement, app.sessions);
    }
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: slot badge, full-width one-line title (full name on long-press / for screen
          // readers), collapse.
          Row(
            children: [
              _Badge(index: index, complete: draft.complete, active: true),
              const SizedBox(width: 10),
              Expanded(
                child: Tooltip(
                  message: ex.name,
                  excludeFromSemantics: true,
                  child: Text(
                    ex.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SxText.headlineMd.copyWith(color: c.textHigh),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _HeaderButton(
                icon: Icons.expand_less,
                tooltip: 'Collapse',
                onTap: () => controller.toggleExpanded(draft),
              ),
            ],
          ),
          // Row 2: muscle / equipment tags and "Last: ..." stacked, with Swap and Info beside them
          // (icon buttons, 48dp, spoken labels).
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SxText.labelXs.copyWith(color: c.textBody),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.history, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            prevTop == null
                                ? 'No previous session'
                                : 'Last: ${Fmt.setLabel(prevTop.weightKg, prevTop.reps, unit)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SxText.bodySm.copyWith(color: c.textBody),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _HeaderButton(
                icon: Icons.swap_horiz,
                tooltip: 'Swap exercise',
                onTap: () => _swap(context),
              ),
              const SizedBox(width: 4),
              _HeaderButton(
                icon: Icons.info_outline,
                tooltip: 'Exercise details',
                onTap: () => AppNav.exerciseDetails(context, ex.id),
              ),
            ],
          ),
          if (draft.recommendation != null &&
              !draft.complete &&
              !draft.suggestionUsed) ...[
            const SizedBox(height: 4),
            SxFadeSlideIn(
              dy: 6,
              duration: SxMotion.short,
              child: _SuggestionChip(
                rec: draft.recommendation!,
                unit: unit,
                onUse: () => controller.useSuggestion(draft),
              ),
            ),
          ],
          const SizedBox(height: 4),
          SetTableHeader(unit: unit),
          for (var i = 0; i < draft.sets.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Semantics(
                // Swipe-to-remove has no screen-reader equivalent, so expose it as a named action.
                customSemanticsActions: {
                  if (draft.sets.length > 1)
                    const CustomSemanticsAction(label: 'Remove set'): () =>
                        _removeWithUndo(context, i),
                },
                child: Dismissible(
                  key: ObjectKey(draft.sets[i]),
                  direction: draft.sets.length > 1
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
                  onDismissed: (_) => _removeWithUndo(context, i),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: c.dangerContainer,
                      borderRadius: BorderRadius.circular(SxRadius.md),
                    ),
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
                    onToggle: () {
                      // Weighted work is never logged at 0 kg: ask for the weight first.
                      if (!controller.toggleSet(draft, i)) {
                        _editWeight(context, i);
                      }
                    },
                    onWeightStep: (dir) =>
                        controller.stepWeight(draft, i, dir, unit),
                    onRepsStep: (dir) => controller.stepReps(draft, i, dir),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TextAction(
                icon: Icons.add_circle_outline,
                label: 'Add Set',
                color: c.primary,
                onTap: () => controller.addSet(draft),
              ),
              if (active > 0)
                _TextAction(
                  icon: Icons.content_copy,
                  label: 'Same as last set',
                  color: c.textBody,
                  onTap: () => controller.sameAsLast(draft, active),
                ),
              _TextAction(
                icon: Icons.tune,
                label: 'Plate Calc',
                color: c.textBody,
                onTap: () {
                  final i = active < 0 ? draft.sets.length - 1 : active;
                  showPlateCalculator(
                    context,
                    targetKg: draft.sets[i].weightKg,
                    unit: unit,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SxRadius.md),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(SxRadius.md),
              border: Border.all(color: c.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(icon, size: 20, color: c.textBody)],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SxRadius.base),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: SxText.bodyMd.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable progression suggestion ("Use 105 x 8"). Content comes from ProgressionService
/// only; nothing is applied until the user taps it. One compact row; tapping the label
/// row expands the reason.
class _SuggestionChip extends StatefulWidget {
  const _SuggestionChip({
    required this.rec,
    required this.unit,
    required this.onUse,
  });
  final ProgressionRecommendation rec;
  final WeightUnit unit;
  final VoidCallback onUse;

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final rec = widget.rec;
    final use = 'Use ${Fmt.weight(rec.weightKg, widget.unit)} × ${rec.repMin}';
    return SxInset(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  container: true,
                  button: true,
                  expanded: _open,
                  label: 'Suggestion. ${rec.reason}',
                  excludeSemantics: true,
                  onTap: () => setState(() => _open = !_open),
                  child: InkWell(
                    onTap: () => setState(() => _open = !_open),
                    borderRadius: BorderRadius.circular(SxRadius.base),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: c.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'SUGGESTION',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SxText.labelXs.copyWith(
                                color: c.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            _open ? Icons.expand_less : Icons.expand_more,
                            color: c.textBody,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: use,
                excludeSemantics: true,
                onTap: widget.onUse,
                child: SxPressable(
                  semantics: false,
                  onTap: widget.onUse,
                  haptic: true,
                  scale: 0.95,
                  focusRadius: SxRadius.base,
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(SxRadius.base),
                      border: Border.all(color: c.primaryBorder),
                    ),
                    child: Text(
                      use,
                      maxLines: 1,
                      style: SxText.labelUi.copyWith(color: c.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: SxMotion.of(context, SxMotion.short),
            curve: SxMotion.enter,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExcludeSemantics(
                      child: Text(
                        rec.reason,
                        style: SxText.bodySm.copyWith(color: c.textBody),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
