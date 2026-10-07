import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'swap_exercise_sheet.dart';

/// Routine architecture editor. An unknown [workoutId] opens a *new draft*
/// (used by "New routine"); it is only persisted — and appended to the
/// rotation — when saved.
class WorkoutEditorPage extends StatefulWidget {
  const WorkoutEditorPage({super.key, required this.workoutId});
  final String workoutId;

  @override
  State<WorkoutEditorPage> createState() => _WorkoutEditorPageState();
}

class _WorkoutEditorPageState extends State<WorkoutEditorPage> {
  late final AppController _app = context.app;
  Workout? _original; // null → new draft
  late String _name;
  late List<RoutineExercise> _items;
  late int _rest;
  bool _dirty = false;
  bool _reorderMode = false;
  bool _saving = false;

  bool get _isNew => _original == null;

  @override
  void initState() {
    super.initState();
    final w = _app.workouts.byId(widget.workoutId);
    _original = w;
    _name = w?.name ?? 'New Routine';
    _items = [...?w?.exercises];
    _rest = w?.restSeconds ?? _app.profile.profile.autoRestSeconds;
  }

  void _mutate(VoidCallback f) => setState(() {
        f();
        _dirty = true;
      });

  int get _totalSets => _items.fold(0, (a, e) => a + e.sets);

  Future<bool> _save({required bool pop}) async {
    if (_saving) return false;
    if (_name.trim().isEmpty) {
      showSxSnack(context, 'Give the workout a name', icon: Icons.error_outline);
      return false;
    }
    if (_items.isEmpty) {
      showSxSnack(context, 'Add at least one exercise', icon: Icons.error_outline);
      return false;
    }
    _saving = true;
    final base = _original;
    final w = base == null
        ? Workout(id: widget.workoutId, name: _name.trim(), exercises: _items, restSeconds: _rest)
        : base.copyWith(name: _name.trim(), exercises: _items, restSeconds: _rest);
    await _app.workouts.saveWorkout(w);
    _saving = false;
    if (!mounted) return true;
    _original = _app.workouts.byId(w.id);
    setState(() => _dirty = false);
    showSxSnack(context, 'Workout structure saved', icon: Icons.task_alt);
    if (pop) Navigator.of(context).pop();
    return true;
  }

  Future<void> _confirmDiscard() async {
    final ok = await showSxConfirm(
      context,
      title: 'Discard changes?',
      message: 'Your edits to this workout have not been saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      destructive: true,
      icon: Icons.warning_amber_rounded,
    );
    if (ok && mounted) {
      setState(() => _dirty = false);
      Navigator.of(context).pop();
    }
  }

  Future<void> _rename() async {
    final ctl = TextEditingController(text: _name);
    final res = await showSxSheet<String>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SxTextField(label: 'Workout name', controller: ctl, textInputAction: TextInputAction.done, onSubmitted: (v) => Navigator.pop(ctx, v)),
            const SizedBox(height: SxSpace.md),
            SxButton(label: 'Done', onPressed: () => Navigator.pop(ctx, ctl.text)),
          ],
        ),
      ),
    );
    ctl.dispose();
    if (res != null && res.trim().isNotEmpty && res.trim() != _name) _mutate(() => _name = res.trim());
  }

  Future<void> _addExercise() async {
    final ex = await AppNav.exercisePicker(context);
    if (ex == null || !mounted) return;
    final p = _app.profile.profile;
    _mutate(() => _items.add(RoutineExercise(exerciseId: ex.id, sets: p.defaultSets, repMin: p.defaultRepMin, repMax: p.defaultRepMax)));
  }

  Future<void> _delete(int i) async {
    final name = _app.exercises.byId(_items[i].exerciseId)?.name ?? 'this exercise';
    final ok = await showSxConfirm(context,
        title: 'Remove exercise?', message: '$name will be removed from this workout.', confirmLabel: 'Remove', destructive: true, icon: Icons.delete_outline);
    if (ok && mounted) _mutate(() => _items.removeAt(i));
  }

  void _move(int i, int delta) {
    final j = i + delta;
    if (j < 0 || j >= _items.length) return;
    _mutate(() => _items.insert(j, _items.removeAt(i)));
  }

  Future<void> _editRest() async {
    final v = await showNumericKeypad(context, title: 'Rest between sets', initial: _rest.toDouble(), allowDecimal: false, step: 15, unit: 's', min: 0, max: 600);
    if (v != null && v.round() != _rest) _mutate(() => _rest = v.round());
  }

  void _editExercise(int i) {
    final re = _items[i];
    final ex = _app.exercises.byId(re.exerciseId);
    showSxSheet<void>(
      context,
      builder: (ctx) => _ExerciseSheet(
        name: ex?.name ?? 'Exercise',
        initial: re,
        onChanged: (n) => _mutate(() => _items[i] = n),
        onSwap: ex == null
            ? null
            : () async {
                Navigator.pop(ctx);
                final repl = await showSwapExerciseSheet(
                  context,
                  current: ex,
                  sets: re.sets,
                  repRange: '${re.repMin}-${re.repMax}',
                  slotLabel: 'Slot ${i + 1}/${_items.length} • $_name',
                  excludeIds: {for (final e in _items) e.exerciseId},
                );
                if (repl != null && mounted) _mutate(() => _items[i] = _items[i].copyWith(exerciseId: repl.id));
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final rot = _app.workouts.rotation;
    final idx = _isNew ? -1 : rot.workoutIds.indexOf(widget.workoutId);
    final minutes = (_totalSets * 3).clamp(0, 600);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: SxScaffold(
        topBar: SxTopBar(
          title: _isNew ? 'New Routine' : 'Edit Workout',
          subtitle: 'ROUTINE ARCHITECTURE',
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SxButton(label: 'Quick save', expanded: false, height: 40, radius: SxRadius.full, onPressed: _dirty ? () => _save(pop: false) : null),
            ),
          ],
        ),
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SxButton(label: 'Save workout structure', icon: Icons.check_circle_outline, onPressed: () => _save(pop: true)),
            if (idx >= 0 || _isNew)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  idx >= 0 ? 'Changes will reflect on next Day ${idx + 1} session.' : 'Saving adds this workout to the end of your rotation.',
                  textAlign: TextAlign.center,
                  style: SxText.bodySm.copyWith(color: c.textBody),
                ),
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
                    children: [
                      Expanded(child: Text(_name, style: SxText.headlineLg.copyWith(color: c.textHigh))),
                      SxIconButton(icon: Icons.edit_outlined, tooltip: 'Rename workout', filled: false, onPressed: _rename),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (idx >= 0) StatusPill('${rot.length}-day rotation • day ${idx + 1}', dot: true, color: c.textBody),
                      StatusPill('Est. $minutes min • $_totalSets sets', icon: Icons.timer_outlined, color: c.textBody),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: SxSpace.lg),
            SectionHeader('Movement sequence', trailingText: '${_items.length} ${_items.length == 1 ? 'movement' : 'movements'}'),
            const SizedBox(height: SxSpace.sm),
            if (_items.isEmpty)
              const SxCard(
                child: EmptyState(
                  icon: Icons.playlist_add,
                  title: 'No exercises yet',
                  message: 'Add the first movement for this workout.',
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _items.length,
                onReorderItem: (o, n) => _mutate(() => _items.insert(n, _items.removeAt(o))),
                proxyDecorator: (child, _, anim) => Material(color: Colors.transparent, elevation: 0, child: child),
                itemBuilder: (context, i) {
                  final re = _items[i];
                  final ex = _app.exercises.byId(re.exerciseId);
                  return Padding(
                    key: ValueKey('${re.exerciseId}#$i'),
                    padding: const EdgeInsets.only(bottom: SxSpace.sm),
                    child: _EditorRow(
                      index: i,
                      count: _items.length,
                      re: re,
                      exercise: ex,
                      reorderMode: _reorderMode,
                      onTune: () => _editExercise(i),
                      onDelete: () => _delete(i),
                      onUp: () => _move(i, -1),
                      onDown: () => _move(i, 1),
                      handle: ReorderableDragStartListener(
                        index: i,
                        child: SizedBox(width: 40, height: 48, child: Icon(Icons.drag_handle, color: c.textMuted)),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: SxSpace.xs),
            SxButton(label: 'Add exercise', icon: Icons.add_circle_outline, variant: SxButtonVariant.secondary, onPressed: _addExercise),
            const SizedBox(height: SxSpace.sm),
            Row(
              children: [
                Expanded(
                  child: SxButton(
                    label: _reorderMode ? 'Done' : 'Reorder',
                    icon: Icons.swap_vert,
                    variant: SxButtonVariant.secondary,
                    height: 48,
                    onPressed: _items.length < 2 ? null : () => setState(() => _reorderMode = !_reorderMode),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SxButton(label: 'Rest: ${_rest}s', icon: Icons.hourglass_top, variant: SxButtonVariant.secondary, height: 48, onPressed: _editRest),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorRow extends StatelessWidget {
  const _EditorRow({
    required this.index,
    required this.count,
    required this.re,
    required this.exercise,
    required this.reorderMode,
    required this.onTune,
    required this.onDelete,
    required this.onUp,
    required this.onDown,
    required this.handle,
  });
  final int index;
  final int count;
  final RoutineExercise re;
  final Exercise? exercise;
  final bool reorderMode;
  final VoidCallback onTune;
  final VoidCallback onDelete;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final Widget handle;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final reps = re.repMin == re.repMax ? '${re.repMin}' : '${re.repMin}–${re.repMax}';
    return SxCard(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          handle,
          Text('${index + 1}'.padLeft(2, '0'), style: SxText.metricMd.copyWith(color: c.primary)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise?.name ?? 'Unknown exercise', style: SxText.headlineSm.copyWith(color: c.textHigh), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(
                  '${re.sets} sets × $reps reps${exercise == null ? '' : ' • ${exercise!.equipment.label} • ${exercise!.primaryMuscle.label}'}',
                  style: SxText.bodySm.copyWith(color: c.textBody),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (reorderMode) ...[
            SxIconButton(icon: Icons.keyboard_arrow_up, tooltip: 'Move up', filled: false, onPressed: index == 0 ? null : onUp),
            SxIconButton(icon: Icons.keyboard_arrow_down, tooltip: 'Move down', filled: false, onPressed: index == count - 1 ? null : onDown),
          ] else ...[
            SxIconButton(icon: Icons.tune, tooltip: 'Edit sets and reps', filled: false, onPressed: onTune),
            SxIconButton(icon: Icons.delete_outline, tooltip: 'Remove exercise', filled: false, onPressed: onDelete),
          ],
        ],
      ),
    );
  }
}

class _ExerciseSheet extends StatefulWidget {
  const _ExerciseSheet({required this.name, required this.initial, required this.onChanged, this.onSwap});
  final String name;
  final RoutineExercise initial;
  final ValueChanged<RoutineExercise> onChanged;
  final VoidCallback? onSwap;

  @override
  State<_ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<_ExerciseSheet> {
  late RoutineExercise _re = widget.initial;

  void _set(RoutineExercise n) {
    setState(() => _re = n);
    widget.onChanged(n);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.name, style: SxText.headlineMd.copyWith(color: c.textHigh)),
          Text('Targets for each session', style: SxText.bodySm.copyWith(color: c.textBody)),
          const SizedBox(height: SxSpace.md),
          _Stepper(label: 'Sets', value: _re.sets, min: 1, max: 10, onChanged: (v) => _set(_re.copyWith(sets: v))),
          const SizedBox(height: SxSpace.sm),
          _Stepper(
            label: 'Min reps',
            value: _re.repMin,
            min: 1,
            max: 50,
            onChanged: (v) => _set(_re.copyWith(repMin: v, repMax: v > _re.repMax ? v : _re.repMax)),
          ),
          const SizedBox(height: SxSpace.sm),
          _Stepper(
            label: 'Max reps',
            value: _re.repMax,
            min: 1,
            max: 50,
            onChanged: (v) => _set(_re.copyWith(repMax: v, repMin: v < _re.repMin ? v : _re.repMin)),
          ),
          if (widget.onSwap != null) ...[
            const SizedBox(height: SxSpace.md),
            SxButton(label: 'Smart swap', icon: Icons.swap_horiz, variant: SxButtonVariant.secondary, onPressed: widget.onSwap),
          ],
          const SizedBox(height: SxSpace.sm),
          SxButton(label: 'Done', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.min, required this.max, required this.onChanged});
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxInset(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(child: Text(label.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody))),
          SxIconButton(icon: Icons.remove, tooltip: 'Decrease $label', filled: false, onPressed: value > min ? () => onChanged(value - 1) : null),
          SizedBox(width: 40, child: Text('$value', textAlign: TextAlign.center, style: SxText.metricMd.copyWith(color: c.textHigh))),
          SxIconButton(icon: Icons.add, tooltip: 'Increase $label', filled: false, onPressed: value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }
}
