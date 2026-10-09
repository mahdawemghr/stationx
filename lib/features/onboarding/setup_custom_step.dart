import 'package:flutter/material.dart';

import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import '../../core/theme/sx_colors.dart';
import 'setup_catalog.dart';
import 'setup_widgets.dart';

/// Custom split: name each day and choose its muscles; add, remove and reorder days.
/// Choosing a muscle adds its suggested exercises; clearing it removes that muscle's exercises.
class SetupCustomStep extends StatefulWidget {
  const SetupCustomStep({super.key, required this.days, required this.all, required this.catalog, required this.onChanged});
  final List<SplitDayPlan> days;
  final List<Exercise> all;
  final SetupCatalog catalog;
  final ValueChanged<List<SplitDayPlan>> onChanged;

  @override
  State<SetupCustomStep> createState() => _SetupCustomStepState();
}

class _Entry {
  _Entry(String name, this.muscles, this.exercises) : name = TextEditingController(text: name);
  final TextEditingController name;
  List<SectionMuscle> muscles;
  List<RoutineExercise> exercises;
}

class _SetupCustomStepState extends State<SetupCustomStep> {
  late final List<_Entry> _entries = [for (final d in widget.days) _Entry(d.name, [...d.sectionMuscles], [...d.exercises])];

  @override
  void dispose() {
    for (final e in _entries) {
      e.name.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged([for (final e in _entries) SplitDayPlan(name: e.name.text, sectionMuscles: [...e.muscles], exercises: [...e.exercises])]);
    setState(() {});
  }

  void _toggle(_Entry e, SectionMuscle m) {
    if (e.muscles.contains(m)) {
      final ids = {for (final x in widget.all) if (sectionOf(x) == m) x.id};
      e.muscles = [...e.muscles]..remove(m);
      e.exercises = [for (final x in e.exercises) if (!ids.contains(x.exerciseId)) x];
    } else {
      // Muscles keep the order they were chosen in: that is the order of the day's sections.
      e.muscles = [...e.muscles, m];
      final have = {for (final x in e.exercises) x.exerciseId};
      e.exercises = WorkoutSections.arrange(
        [...e.exercises, for (final x in widget.catalog.suggestSection(m, widget.all)) if (!have.contains(x.exerciseId)) x],
        widget.all,
        muscleOrder: e.muscles,
      );
    }
    _emit();
  }

  void _move(int i, int to) {
    if (to < 0 || to >= _entries.length) return;
    _entries.insert(to, _entries.removeAt(i));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SetupList(children: [
      Text('Build your split', style: SxText.headlineLg.copyWith(color: c.textHigh)),
      Text('Name each day and choose the muscles it trains.', style: SxText.bodyMd.copyWith(color: c.textBody)),
      for (var i = 0; i < _entries.length; i++) _dayCard(c, i),
      SxButton(
        label: 'Add day',
        icon: Icons.add,
        variant: SxButtonVariant.secondary,
        onPressed: _entries.length >= 10
            ? null
            : () {
                _entries.add(_Entry('Day ${_entries.length + 1}', [], []));
                _emit();
              },
      ),
    ]);
  }

  Widget _dayCard(SxColors c, int i) {
    final e = _entries[i];
    return SxCard(
      key: ObjectKey(e),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('DAY ${i + 1}', style: SxText.labelCaps.copyWith(color: c.primary))),
          IconButton(
            tooltip: 'Move day ${i + 1} up',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.arrow_upward),
            onPressed: i == 0 ? null : () => _move(i, i - 1),
          ),
          IconButton(
            tooltip: 'Move day ${i + 1} down',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.arrow_downward),
            onPressed: i == _entries.length - 1 ? null : () => _move(i, i + 1),
          ),
          IconButton(
            tooltip: 'Remove day ${i + 1}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(Icons.delete_outline, color: c.danger),
            onPressed: _entries.length == 1
                ? null
                : () {
                    final removed = _entries.removeAt(i);
                    _emit();
                    // The removed row's field is still in this frame's tree: dispose after it is gone.
                    WidgetsBinding.instance.addPostFrameCallback((_) => removed.name.dispose());
                  },
          ),
        ]),
        SxTextField(label: 'Day name', hint: 'e.g. Push', controller: e.name, onChanged: (_) => _emit()),
        const SizedBox(height: SxSpace.sm),
        Text('MUSCLES', style: SxText.labelCaps.copyWith(color: c.textBody)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in SectionMuscle.values) SxChip(label: m.label, selected: e.muscles.contains(m), onTap: () => _toggle(e, m)),
        ]),
      ]),
    );
  }
}
