import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'session_delete_dialog.dart';

/// Edit a logged strength session: sets (weight / reps), add or remove sets and exercises,
/// the date and the notes. Keeps the original `createdAt` (only `updatedAt` moves) and never
/// touches the rotation. Records, volume and progress are derived, so they update by themselves.
class EditSessionPage extends StatelessWidget {
  const EditSessionPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final s = context.app.sessions.byId(sessionId);
    if (s == null) {
      return const SxScaffold(
        topBar: SxTopBar(title: 'Edit workout'),
        body: Center(child: ErrorState(message: 'This session no longer exists.')),
      );
    }
    return _EditForm(session: s);
  }
}

class _EditSet {
  _EditSet({required this.weightKg, required this.reps, this.rpe});
  double weightKg;
  int reps;
  final double? rpe;
}

class _EditExercise {
  _EditExercise(this.exerciseId, this.sets);
  final String exerciseId;
  final List<_EditSet> sets;
}

class _EditForm extends StatefulWidget {
  const _EditForm({required this.session});
  final WorkoutSession session;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final List<_EditExercise> _exercises;
  late DateTime _date = widget.session.workoutDate;
  late final TextEditingController _notes = TextEditingController(text: widget.session.notes);
  bool _dirty = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _exercises = [
      for (final l in widget.session.exercises)
        _EditExercise(l.exerciseId, [
          for (final s in l.doneSets) _EditSet(weightKg: s.weightKg, reps: s.reps, rpe: s.rpe),
        ]),
    ];
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _change(VoidCallback fn) => setState(() {
        fn();
        _dirty = true;
      });

  WeightUnit get _unit => context.app.profile.profile.unit;

  Future<void> _editWeight(_EditSet s) async {
    final unit = _unit;
    final v = await showNumericKeypad(
      context,
      title: 'Weight (${Fmt.unit(unit)})',
      initial: s.weightKg <= 0 ? null : double.parse(Fmt.toDisplayWeight(s.weightKg, unit).toStringAsFixed(2)),
      step: unit == WeightUnit.kg ? 2.5 : 5,
      unit: Fmt.unit(unit),
    );
    if (v != null) _change(() => s.weightKg = Fmt.fromDisplayWeight(v, unit));
  }

  Future<void> _editReps(_EditSet s) async {
    final v = await showNumericKeypad(context, title: 'Reps', initial: s.reps.toDouble(), allowDecimal: false, step: 1, max: 999);
    if (v != null) _change(() => s.reps = v.round());
  }

  void _addSet(_EditExercise e) {
    final last = e.sets.isEmpty ? null : e.sets.last;
    _change(() => e.sets.add(_EditSet(weightKg: last?.weightKg ?? 0, reps: last?.reps ?? 8)));
  }

  Future<void> _addExercise() async {
    final ex = await AppNav.exercisePicker(context);
    if (ex == null || !mounted) return;
    _change(() => _exercises.add(_EditExercise(ex.id, [_EditSet(weightKg: 0, reps: 8)])));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (d == null || !mounted) return;
    _change(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
  }

  WorkoutSession _build() {
    final old = widget.session;
    return WorkoutSession(
      id: old.id,
      workoutId: old.workoutId,
      name: old.name,
      workoutDate: _date,
      durationSeconds: old.durationSeconds,
      cardio: old.cardio,
      notes: _notes.text.trim(),
      meta: old.meta.touched(),
      exercises: [
        for (final e in _exercises)
          if (e.sets.isNotEmpty)
            ExerciseLog(exerciseId: e.exerciseId, sets: [
              for (final s in e.sets) SetLog(weightKg: s.weightKg, reps: s.reps, rpe: s.rpe),
            ]),
      ],
    );
  }

  Future<void> _save() async {
    if (_busy) return;
    final next = _build();
    if (next.exercises.isEmpty && next.cardio == null) {
      showSxSnack(context, 'Add at least one set, or delete the workout', icon: Icons.info_outline);
      return;
    }
    if (_exercises.any((e) => e.sets.any((s) => s.reps <= 0))) {
      showSxSnack(context, 'Every set needs at least 1 rep', icon: Icons.info_outline);
      return;
    }
    setState(() => _busy = true);
    await context.app.sessions.update(next);
    if (!mounted) return;
    showSxSnack(context, 'Workout updated');
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final nav = Navigator.of(context);
    if (!await deleteSessionWithConfirm(context, widget.session)) return;
    nav.pop();
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    return showSxConfirm(
      context,
      title: 'Discard changes?',
      message: 'Your edits to this workout have not been saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      destructive: true,
      icon: Icons.undo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    final unit = _unit;
    final names = {for (final e in app.exercises.all) e.id: e.name};
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmDiscard()) nav.pop();
      },
      child: SxScaffold(
        topBar: SxTopBar(
          title: 'Edit workout',
          subtitle: widget.session.name.toUpperCase(),
          actions: [TextButton(onPressed: _save, child: Text('Save', style: SxText.headlineSm.copyWith(color: c.primary)))],
        ),
        bottom: Row(children: [
          Expanded(child: SxButton(label: 'Save changes', icon: Icons.save_outlined, onPressed: _busy ? null : _save)),
          const SizedBox(width: 8),
          SxIconButton(icon: Icons.delete_outline, tooltip: 'Delete workout', iconColor: c.danger, size: 52, onPressed: _delete),
        ]),
        children: [
          SxCard(
            onTap: _pickDate,
            child: Row(children: [
              Icon(Icons.event, color: c.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DATE', style: SxText.labelXs.copyWith(color: c.textBody)),
                  Text(Fmt.dateLong(_date), style: SxText.headlineSm.copyWith(color: c.textHigh)),
                ]),
              ),
              Icon(Icons.edit_calendar_outlined, color: c.textBody),
            ]),
          ),
          if (_exercises.isEmpty)
            const SxCard(child: EmptyState(icon: Icons.fitness_center, title: 'No exercises', message: 'Add an exercise to this workout.')),
          for (final (i, e) in _exercises.indexed)
            SxCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${i + 1}. ${names[e.exerciseId] ?? e.exerciseId}', style: SxText.headlineSm.copyWith(color: c.textHigh))),
                  SxIconButton(
                    icon: Icons.close,
                    tooltip: 'Remove ${names[e.exerciseId] ?? 'exercise'}',
                    filled: false,
                    iconColor: c.danger,
                    onPressed: () => _change(() => _exercises.removeAt(i)),
                  ),
                ]),
                const SizedBox(height: 4),
                for (final (k, s) in e.sets.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      SizedBox(width: 28, child: Text('${k + 1}', style: SxText.metricSm.copyWith(color: c.textBody))),
                      Expanded(
                        flex: 3,
                        child: _ValueButton(
                          label: 'Set ${k + 1} weight',
                          text: '${_weightText(s.weightKg, unit)} ${Fmt.unit(unit)}',
                          onTap: () => _editWeight(s),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _ValueButton(label: 'Set ${k + 1} reps', text: '${s.reps} reps', onTap: () => _editReps(s)),
                      ),
                      SxIconButton(
                        icon: Icons.remove_circle_outline,
                        tooltip: 'Remove set ${k + 1}',
                        filled: false,
                        iconColor: c.textBody,
                        onPressed: () => _change(() => e.sets.removeAt(k)),
                      ),
                    ]),
                  ),
                SxButton(label: 'Add set', icon: Icons.add, variant: SxButtonVariant.ghost, height: 44, onPressed: () => _addSet(e)),
              ]),
            ),
          SxButton(label: 'Add exercise', icon: Icons.add, variant: SxButtonVariant.secondary, height: 48, onPressed: _addExercise),
          SxTextField(label: 'Notes', controller: _notes, maxLines: 3, hint: 'Optional', onChanged: (_) => _dirty = true),
        ],
      ),
    );
  }
}

class _ValueButton extends StatelessWidget {
  const _ValueButton({required this.label, required this.text, required this.onTap});
  final String label;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      button: true,
      label: '$label, $text',
      child: Material(
        color: c.surface2,
        borderRadius: BorderRadius.circular(SxRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(SxRadius.md),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            child: ExcludeSemantics(child: Text(text, style: SxText.metricSm.copyWith(color: c.textHigh))),
          ),
        ),
      ),
    );
  }
}

String _weightText(double kg, WeightUnit unit) {
  final v = Fmt.toDisplayWeight(kg, unit);
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
