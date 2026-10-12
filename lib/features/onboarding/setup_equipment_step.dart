import 'package:flutter/material.dart';

import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/equipment_icons.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'setup_widgets.dart';

/// Chips for the equipment the user can train with. Bodyweight is always available, so it is not listed.
class EquipmentPicker extends StatelessWidget {
  const EquipmentPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final Set<Equipment> selected;
  final ValueChanged<Set<Equipment>> onChanged;

  void _toggle(Equipment e) {
    final next = {...selected};
    if (!next.remove(e)) next.add(e);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final all = {...EquipmentAccess.choosable};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final e in EquipmentAccess.choosable)
              SxChip(
                label: e.label,
                icon: equipmentIcon(e),
                selected: selected.contains(e),
                onTap: () => _toggle(e),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            SxChip(
              label: 'Full gym',
              selected: selected.length == all.length,
              onTap: () => onChanged(all),
            ),
            SxChip(
              label: 'Bodyweight only',
              selected: selected.isEmpty,
              onTap: () => onChanged(<Equipment>{}),
            ),
          ],
        ),
      ],
    );
  }
}

/// Onboarding step: which equipment is available. Automatic exercise choices stay inside it.
class SetupEquipmentStep extends StatelessWidget {
  const SetupEquipmentStep({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final Set<Equipment> selected;
  final ValueChanged<Set<Equipment>> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SetupList(
      children: [
        Semantics(
          header: true,
          child: Text(
            'Your equipment',
            style: SxText.headlineLg.copyWith(color: c.textHigh),
          ),
        ),
        Text(
          'Tick what you can use. Suggested exercises only use this, plus bodyweight moves. You can still pick any exercise by hand and change this later in Profile.',
          style: SxText.bodyMd.copyWith(color: c.textBody),
        ),
        EquipmentPicker(selected: selected, onChanged: onChanged),
      ],
    );
  }
}
