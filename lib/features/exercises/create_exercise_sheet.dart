import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

/// Bottom sheet to create a custom exercise. Persists through
/// [ExerciseRepository.addCustom] and returns the created exercise.
Future<Exercise?> showCreateExerciseSheet(BuildContext context) {
  final repo = context.app.exercises;
  return showSxSheet<Exercise>(context, builder: (_) => _CreateBody(repo: repo));
}

class _CreateBody extends StatefulWidget {
  const _CreateBody({required this.repo});
  final ExerciseRepository repo;

  @override
  State<_CreateBody> createState() => _CreateBodyState();
}

class _CreateBodyState extends State<_CreateBody> {
  final _name = TextEditingController();
  MuscleGroup _muscle = MuscleGroup.chest;
  Equipment _equipment = Equipment.dumbbell;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Required');
      return;
    }
    if (widget.repo.all.any((e) => e.name.toLowerCase() == name.toLowerCase())) {
      setState(() => _error = 'Already exists');
      return;
    }
    final ex = Exercise(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      primaryMuscle: _muscle,
      equipment: _equipment,
      isCustom: true,
    );
    await widget.repo.addCustom(ex);
    if (mounted) Navigator.of(context).pop(ex);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('CUSTOM EXERCISE', style: SxText.headlineMd.copyWith(color: c.textHigh)),
        const SizedBox(height: SxSpace.md),
        SxTextField(label: 'Name', hint: 'e.g. Machine Chest Press', controller: _name, errorText: _error, onChanged: (_) => setState(() => _error = null)),
        const SizedBox(height: SxSpace.md),
        Text('PRIMARY MUSCLE', style: SxText.labelCaps.copyWith(color: c.textBody)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in MuscleGroup.values) SxChip(label: m.label, selected: m == _muscle, onTap: () => setState(() => _muscle = m)),
        ]),
        const SizedBox(height: SxSpace.md),
        Text('EQUIPMENT', style: SxText.labelCaps.copyWith(color: c.textBody)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in Equipment.values) SxChip(label: e.label, selected: e == _equipment, onTap: () => setState(() => _equipment = e)),
        ]),
        const SizedBox(height: SxSpace.lg),
        SxButton(label: 'Save exercise', icon: Icons.check, onPressed: _save),
      ]),
    );
  }
}
