import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_colors.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

/// Bottom sheet to create a custom exercise. Persists through
/// [ExerciseRepository.addCustom] and returns the created exercise.
Future<Exercise?> showCreateExerciseSheet(
  BuildContext context, {
  MuscleGroup initialMuscle = MuscleGroup.chest,
}) {
  final repo = context.app.exercises;
  return showSxSheet<Exercise>(
    context,
    builder: (_) => _CreateBody(repo: repo, initialMuscle: initialMuscle),
  );
}

class _CreateBody extends StatefulWidget {
  const _CreateBody({
    required this.repo,
    this.initialMuscle = MuscleGroup.chest,
  });
  final ExerciseRepository repo;
  final MuscleGroup initialMuscle;

  @override
  State<_CreateBody> createState() => _CreateBodyState();
}

/// Default region for a legacy broad [MuscleGroup] (quick path / `initialMuscle`).
MuscleRegion _regionFor(MuscleGroup g) => switch (g) {
  MuscleGroup.chest => MuscleRegion.chest,
  MuscleGroup.back => MuscleRegion.back,
  MuscleGroup.shoulders => MuscleRegion.shoulders,
  MuscleGroup.biceps => MuscleRegion.biceps,
  MuscleGroup.triceps => MuscleRegion.triceps,
  MuscleGroup.legs => MuscleRegion.quadriceps,
  MuscleGroup.core => MuscleRegion.core,
};

class _TargetRow {
  _TargetRow(this.region, {this.role = TargetRole.primary});
  MuscleRegion region;
  Muscle? sub;
  TargetRole role;
  bool noteOpen = false;
  final TextEditingController note = TextEditingController();
  final Key key = UniqueKey();
}

class _CreateBodyState extends State<_CreateBody> {
  final _name = TextEditingController();
  late final List<_TargetRow> _rows = [
    _TargetRow(_regionFor(widget.initialMuscle)),
  ];
  Equipment _equipment = Equipment.dumbbell;
  String? _error;
  String? _musclesError;

  @override
  void dispose() {
    _name.dispose();
    for (final r in _rows) {
      r.note.dispose();
    }
    super.dispose();
  }

  String _key(_TargetRow r) => '${r.region.name}/${r.sub?.name ?? ''}';

  void _addRow() {
    final used = {for (final r in _rows) _key(r)};
    final region = MuscleRegion.values.firstWhere(
      (g) => !used.contains('${g.name}/'),
      orElse: () => MuscleRegion.values.first,
    );
    setState(() {
      _rows.add(_TargetRow(region, role: TargetRole.secondary));
      _musclesError = null;
    });
  }

  void _removeRow(_TargetRow r) => setState(() {
    _rows.remove(r);
    _musclesError = null;
    // The note field may still be in this frame's tree: dispose once it is gone.
    WidgetsBinding.instance.addPostFrameCallback((_) => r.note.dispose());
  });

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Required');
      return;
    }
    if (widget.repo.all.any(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
    )) {
      setState(() => _error = 'Already exists');
      return;
    }
    if (_rows.where((r) => r.role == TargetRole.primary).isEmpty) {
      setState(() => _musclesError = 'Choose at least one primary muscle');
      return;
    }
    final keys = _rows.map(_key).toList();
    if (keys.toSet().length != keys.length) {
      setState(() => _musclesError = 'The same muscle is listed twice');
      return;
    }
    final ex = Exercise.custom(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      equipment: _equipment,
      targets: [
        for (final r in _rows)
          MuscleTarget(
            r.region,
            muscle: r.sub,
            role: r.role,
            emphasis: r.noteOpen && r.note.text.trim().isNotEmpty
                ? r.note.text.trim()
                : null,
          ),
      ],
    );
    await widget.repo.addCustom(ex);
    if (mounted) Navigator.of(context).pop(ex);
  }

  Widget _rowCard(int i, _TargetRow r, SxColors c) {
    return Semantics(
      container: true,
      label: 'Muscle ${i + 1}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface1,
          borderRadius: BorderRadius.circular(SxRadius.md),
          border: Border.all(color: c.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    i == 0 ? 'MUSCLE' : 'MUSCLE ${i + 1}',
                    style: SxText.labelCaps.copyWith(color: c.textBody),
                  ),
                ),
                if (_rows.length > 1)
                  IconButton(
                    tooltip: 'Remove muscle ${i + 1}',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: Icon(Icons.close, color: c.textBody),
                    onPressed: () => _removeRow(r),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: [
                for (final g in MuscleRegion.values)
                  SxChip(
                    label: g.label,
                    selected: g == r.region,
                    onTap: () => setState(() {
                      r.region = g;
                      r.sub = null;
                      _musclesError = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'PART (OPTIONAL)',
              style: SxText.labelCaps.copyWith(color: c.textBody),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: [
                for (final m in r.region.muscles)
                  SxChip(
                    label: m.label,
                    selected: m == r.sub,
                    onTap: () => setState(() {
                      r.sub = r.sub == m ? null : m;
                      _musclesError = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('ROLE', style: SxText.labelCaps.copyWith(color: c.textBody)),
            Wrap(
              spacing: 8,
              children: [
                SxChip(
                  label: 'Primary',
                  selected: r.role == TargetRole.primary,
                  onTap: () => setState(() {
                    r.role = TargetRole.primary;
                    _musclesError = null;
                  }),
                ),
                SxChip(
                  label: 'Assisting',
                  selected: r.role == TargetRole.secondary,
                  onTap: () => setState(() {
                    r.role = TargetRole.secondary;
                    _musclesError = null;
                  }),
                ),
              ],
            ),
            AnimatedSize(
              duration: SxMotion.of(context, SxMotion.short),
              curve: SxMotion.enter,
              alignment: Alignment.topCenter,
              child: r.noteOpen
                  ? SxTextField(
                      label: 'Note (optional)',
                      hint: 'e.g. stretch under load',
                      controller: r.note,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          MuscleTargetCodec.maxEmphasisLength,
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () => setState(() => r.noteOpen = true),
                        child: const Text('Add note'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CUSTOM EXERCISE',
            style: SxText.headlineMd.copyWith(color: c.textHigh),
          ),
          const SizedBox(height: SxSpace.md),
          SxTextField(
            label: 'Name',
            hint: 'e.g. Machine Chest Press',
            controller: _name,
            errorText: _error,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: SxSpace.md),
          Text(
            'EQUIPMENT',
            style: SxText.labelCaps.copyWith(color: c.textBody),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in Equipment.values)
                SxChip(
                  label: e.label,
                  selected: e == _equipment,
                  onTap: () => setState(() => _equipment = e),
                ),
            ],
          ),
          const SizedBox(height: SxSpace.md),
          Text(
            'MUSCLES TRAINED',
            style: SxText.labelCaps.copyWith(color: c.textBody),
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: SxMotion.of(context, SxMotion.short),
            curve: SxMotion.enter,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _rows.length; i++)
                  KeyedSubtree(
                    key: _rows[i].key,
                    child: _rowCard(i, _rows[i], c),
                  ),
              ],
            ),
          ),
          if (_musclesError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _musclesError!,
                  style: SxText.labelUi.copyWith(color: c.danger),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: SxChip(
              label: 'Add muscle',
              icon: Icons.add,
              onTap: _rows.length >= MuscleTargetCodec.maxTargets
                  ? null
                  : _addRow,
            ),
          ),
          const SizedBox(height: SxSpace.lg),
          SxButton(label: 'Save exercise', icon: Icons.check, onPressed: _save),
        ],
      ),
    );
  }
}
