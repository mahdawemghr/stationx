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
import 'workout_section_header.dart';

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

  /// Stable identity per row (parallel to [_items]) so rows keep their state and
  /// only genuinely new rows play the entry animation.
  late List<int> _ids;
  int _nextId = 0;
  late final int _initialCount;
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
    // Arrange on read: one block per muscle, main exercises first (see WorkoutSections). Saved as shown.
    _items = WorkoutSections.arrange([...?w?.exercises], _app.exercises.all);
    _ids = [for (var i = 0; i < _items.length; i++) _nextId++];
    _initialCount = _nextId;
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
    final res = await showSxSheet<String>(context, builder: (ctx) => _RenameSheet(initial: _name));
    if (res != null && res.trim().isNotEmpty && res.trim() != _name) _mutate(() => _name = res.trim());
  }

  Future<void> _addExercise() async {
    final ex = await AppNav.exercisePicker(context);
    if (ex == null || !mounted) return;
    final p = _app.profile.profile;
    final re = RoutineExercise(exerciseId: ex.id, sets: p.defaultSets, repMin: p.defaultRepMin, repMax: p.defaultRepMax);
    _mutate(() {
      // Lands in its muscle section (no second header); a new muscle goes after the existing sections.
      final at = WorkoutSections.insertionIndex(_items, re, _app.exercises.all);
      _items.insert(at, re);
      _ids.insert(at, _nextId++);
    });
  }

  /// Re-arranges after a swap (the replacement may belong to another sub-area or muscle) keeping row ids
  /// and the current section order.
  void _rearrange() {
    final cat = _app.exercises.all;
    final order = [for (final s in WorkoutSections.groupContiguous(_items, cat)) s.muscle];
    final arranged = WorkoutSections.arrange(_items, cat, muscleOrder: order);
    final used = <int>{};
    final newItems = <RoutineExercise>[];
    final newIds = <int>[];
    for (final re in arranged) {
      for (var i = 0; i < _items.length; i++) {
        if (!used.contains(i) && identical(_items[i], re)) {
          used.add(i);
          newItems.add(re);
          newIds.add(_ids[i]);
          break;
        }
      }
    }
    if (newItems.length != _items.length) return; // defensive: never lose rows
    _items = newItems;
    _ids = newIds;
  }

  Future<void> _delete(int i) async {
    final name = _app.exercises.byId(_items[i].exerciseId)?.name ?? 'this exercise';
    final ok = await showSxConfirm(
      context,
      title: 'Remove exercise?',
      message: '$name will be removed from this workout.',
      confirmLabel: 'Remove',
      destructive: true,
      icon: Icons.delete_outline,
    );
    if (ok && mounted) {
      _mutate(() {
        _items.removeAt(i);
        _ids.removeAt(i);
      });
    }
  }

  /// Moves one row by [delta], clamped to its muscle section.
  void _move(int i, int delta, _Range range) {
    final j = i + delta;
    if (j < range.start || j > range.end) return;
    _mutate(() {
      _items.insert(j, _items.removeAt(i));
      _ids.insert(j, _ids.removeAt(i));
    });
  }

  Future<void> _editRest() async {
    final v = await showNumericKeypad(
      context,
      title: 'Rest between sets',
      initial: _rest.toDouble(),
      allowDecimal: false,
      step: 15,
      unit: 's',
      min: 0,
      max: 600,
    );
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
                if (repl != null && mounted) {
                  _mutate(() {
                    _items[i] = _items[i].copyWith(exerciseId: repl.id);
                    _rearrange();
                  });
                }
              },
      ),
    );
  }

  /// Flat rows for the reorderable list: section header (only with 2+ sections), sub-headers, exercises.
  List<_Entry> _entries(List<WorkoutSection> sections) {
    final multi = WorkoutSections.showSectionHeaders(sections);
    final out = <_Entry>[];
    var idx = 0;
    for (final s in sections) {
      final range = _Range(idx, idx + s.items.length - 1);
      if (multi) out.add(_Entry.header(s, range));
      for (final g in s.groups) {
        if (WorkoutSubHeader.visible(s, g, multiSection: multi)) out.add(_Entry.sub(g.label!, range));
        for (var j = 0; j < g.items.length; j++) {
          out.add(_Entry.item(idx++, range));
        }
      }
    }
    // Unknown exercises (skipped by the grouping) trail as plain rows with their own range.
    if (idx < _items.length) {
      final range = _Range(idx, _items.length - 1);
      while (idx < _items.length) {
        out.add(_Entry.item(idx++, range));
      }
    }
    return out;
  }

  /// Drag-reorder allowed only inside the dragged row's muscle section; a drop elsewhere snaps to the
  /// nearest valid slot with a short note. [o]/[n] are list-entry indexes (n already adjusted).
  void _onReorder(List<_Entry> entries, int o, int n) {
    final src = entries[o];
    if (!src.isItem) return;
    final range = src.range;
    final rest = [...entries]..removeAt(o);
    // Valid drop positions (in `rest`) span from the section's first row to just after its last row.
    var first = rest.indexWhere((e) => e.isItem && e.item == range.start);
    var last = rest.lastIndexWhere((e) => e.isItem && e.item == range.end);
    if (first < 0) first = 0;
    if (last < 0) last = rest.length - 1;
    // Include a sub-header that directly precedes the first row as part of the section.
    while (first > 0 && !rest[first - 1].isItem && rest[first - 1].range == range && rest[first - 1].section == null) {
      first--;
    }
    final outside = n < first || n > last + 1;
    final nn = n.clamp(first, last + 1);
    var target = rest.take(nn).where((e) => e.isItem).length;
    target = target.clamp(range.start, range.end);
    if (outside) showSxSnack(context, 'Exercises stay inside their muscle section', icon: Icons.info_outline);
    if (target == src.item) return;
    _mutate(() {
      _items.insert(target, _items.removeAt(src.item));
      _ids.insert(target, _ids.removeAt(src.item));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final rot = _app.workouts.rotation;
    final idx = _isNew ? -1 : rot.workoutIds.indexOf(widget.workoutId);
    final minutes = (_totalSets * 3).clamp(0, 600);
    // Live draft: never reordered here (groupContiguous); the list is arranged on open / add / swap.
    final entries = _entries(WorkoutSections.groupContiguous(_items, _app.exercises.all));

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
              child: SxButton(
                label: 'Quick save',
                expanded: false,
                radius: SxRadius.full,
                onPressed: _dirty ? () => _save(pop: false) : null,
              ),
            ),
          ],
        ),
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SxButton(
              label: 'Save workout structure',
              icon: Icons.check_circle_outline,
              onPressed: () => _save(pop: true),
            ),
            if (idx >= 0 || _isNew)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  idx >= 0
                      ? 'Changes will reflect on next Day ${idx + 1} session.'
                      : 'Saving adds this workout to the end of your rotation.',
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
                      Expanded(
                        child: Text(_name, style: SxText.headlineLg.copyWith(color: c.textHigh)),
                      ),
                      SxIconButton(
                        icon: Icons.edit_outlined,
                        tooltip: 'Rename workout',
                        filled: false,
                        onPressed: _rename,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (idx >= 0)
                        StatusPill('${rot.length}-day rotation • day ${idx + 1}', dot: true, color: c.textBody),
                      StatusPill('Est. $minutes min • $_totalSets sets', icon: Icons.timer_outlined, color: c.textBody),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: SxSpace.lg),
            SectionHeader(
              'Movement sequence',
              trailingText: '${_items.length} ${_items.length == 1 ? 'movement' : 'movements'}',
            ),
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
              _MaybeAnimatedSize(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: entries.length,
                  onReorderItem: (o, n) => _onReorder(entries, o, n),
                  // Lifted row: slight scale + soft shadow while dragging.
                  proxyDecorator: (child, _, anim) => AnimatedBuilder(
                    animation: anim,
                    child: child,
                    builder: (context, child) {
                      final t = Curves.easeOut.transform(anim.value);
                      return Transform.scale(
                        scale: SxMotion.reduced(context) ? 1 : 1 + 0.02 * t,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(SxRadius.lg),
                            boxShadow: [
                              BoxShadow(color: context.sx.scrim, blurRadius: 16 * t, offset: Offset(0, 4 * t)),
                            ],
                          ),
                          child: Material(color: Colors.transparent, child: child),
                        ),
                      );
                    },
                  ),
                  itemBuilder: (context, k) {
                    final e = entries[k];
                    if (e.section != null) {
                      return Padding(key: ValueKey('hdr_${e.section!.muscle.name}'), padding: const EdgeInsets.only(bottom: SxSpace.xs), child: WorkoutSectionHeader(section: e.section!));
                    }
                    if (e.subLabel != null) {
                      return Padding(key: ValueKey('sub_$k'), padding: EdgeInsets.zero, child: WorkoutSubHeader(label: e.subLabel!));
                    }
                    final i = e.item;
                    final re = _items[i];
                    final ex = _app.exercises.byId(re.exerciseId);
                    final range = e.range;
                    final row = _EditorRow(
                      index: i,
                      re: re,
                      exercise: ex,
                      reorderMode: _reorderMode,
                      canUp: i > range.start,
                      canDown: i < range.end,
                      onTune: () => _editExercise(i),
                      onDelete: () => _delete(i),
                      onUp: () => _move(i, -1, range),
                      onDown: () => _move(i, 1, range),
                      handle: ReorderableDragStartListener(
                        index: k,
                        child: SizedBox(width: 40, height: 48, child: Icon(Icons.drag_handle, color: c.textMuted)),
                      ),
                    );
                    return Padding(
                      key: ValueKey('row_${_ids[i]}'),
                      padding: const EdgeInsets.only(bottom: SxSpace.sm),
                      // Rows added in this session slide in; existing ones never replay.
                      child: _ids[i] >= _initialCount ? SxFadeSlideIn(dy: 8, child: row) : row,
                    );
                  },
                ),
              ),
            const SizedBox(height: SxSpace.xs),
            SxButton(
              label: 'Add exercise',
              icon: Icons.add_circle_outline,
              variant: SxButtonVariant.secondary,
              onPressed: _addExercise,
            ),
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
                  child: SxButton(
                    label: 'Rest: ${_rest}s',
                    icon: Icons.hourglass_top,
                    variant: SxButtonVariant.secondary,
                    height: 48,
                    onPressed: _editRest,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Inclusive item-index span of one muscle section.
class _Range {
  const _Range(this.start, this.end);
  final int start;
  final int end;
  @override
  bool operator ==(Object o) => o is _Range && o.start == start && o.end == end;
  @override
  int get hashCode => Object.hash(start, end);
}

/// One row of the editor list: a section header, a sub-header or an exercise ([item] = index in the draft).
class _Entry {
  const _Entry.header(WorkoutSection this.section, this.range)
      : subLabel = null,
        item = -1;
  const _Entry.sub(String this.subLabel, this.range)
      : section = null,
        item = -1;
  const _Entry.item(this.item, this.range)
      : section = null,
        subLabel = null;
  final WorkoutSection? section;
  final String? subLabel;
  final int item;
  final _Range range;
  bool get isItem => item >= 0;
}

class _EditorRow extends StatelessWidget {
  const _EditorRow({
    required this.index,
    required this.canUp,
    required this.canDown,
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
  final bool canUp;
  final bool canDown;
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
                Text(
                  exercise?.name ?? 'Unknown exercise',
                  style: SxText.headlineSm.copyWith(color: c.textHigh),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
            SxIconButton(
              icon: Icons.keyboard_arrow_up,
              tooltip: 'Move up',
              filled: false,
              onPressed: canUp ? onUp : null,
            ),
            SxIconButton(
              icon: Icons.keyboard_arrow_down,
              tooltip: 'Move down',
              filled: false,
              onPressed: canDown ? onDown : null,
            ),
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
          _StepRow(
            label: 'Sets',
            value: _re.sets,
            min: 1,
            max: 10,
            onChanged: (v) => _set(_re.copyWith(sets: v)),
          ),
          const SizedBox(height: SxSpace.sm),
          _StepRow(
            label: 'Min reps',
            value: _re.repMin,
            min: 1,
            max: 50,
            onChanged: (v) => _set(_re.copyWith(repMin: v, repMax: v > _re.repMax ? v : _re.repMax)),
          ),
          const SizedBox(height: SxSpace.sm),
          _StepRow(
            label: 'Max reps',
            value: _re.repMax,
            min: 1,
            max: 50,
            onChanged: (v) => _set(_re.copyWith(repMax: v, repMin: v < _re.repMin ? v : _re.repMin)),
          ),
          if (widget.onSwap != null) ...[
            const SizedBox(height: SxSpace.md),
            SxButton(
              label: 'Smart swap',
              icon: Icons.swap_horiz,
              variant: SxButtonVariant.secondary,
              onPressed: widget.onSwap,
            ),
          ],
          const SizedBox(height: SxSpace.sm),
          SxButton(label: 'Done', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

/// Labelled row hosting the shared [SxStepper].
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
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
          Expanded(
            child: Text(label.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody)),
          ),
          SxStepper.int(label: label, value: value, min: min, max: max, longPressRepeat: false, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Rename sheet that owns (and disposes) its controller, so it is never
/// disposed while the sheet is still animating out.
class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.initial});
  final String initial;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final TextEditingController _ctl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SxTextField(
            label: 'Workout name',
            controller: _ctl,
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          const SizedBox(height: SxSpace.md),
          SxButton(label: 'Done', onPressed: () => Navigator.pop(context, _ctl.text)),
        ],
      ),
    );
  }
}

/// AnimatedSize that is a plain pass-through under reduced motion.
class _MaybeAnimatedSize extends StatelessWidget {
  const _MaybeAnimatedSize({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (SxMotion.reduced(context)) return child;
    return AnimatedSize(duration: SxMotion.of(context, SxMotion.short), curve: SxMotion.enter, alignment: Alignment.topCenter, child: child);
  }
}
