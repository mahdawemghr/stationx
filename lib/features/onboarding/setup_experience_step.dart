import 'package:flutter/material.dart';

import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'setup_widgets.dart';

const _hints = {
  Difficulty.beginner:
      'New to lifting, or coming back. Suggestions avoid advanced exercises unless nothing easier covers a muscle.',
  Difficulty.intermediate:
      'Comfortable with the main lifts. Advanced exercises are suggested only when nothing else fits.',
  Difficulty.advanced: 'Experienced. Suggestions may use every level.',
};

/// Three-way choice of experience level, shared by onboarding and Profile.
class ExperiencePicker extends StatelessWidget {
  const ExperiencePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final Difficulty selected;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SxSegmented(
          labels: [for (final d in Difficulty.values) d.label],
          index: Difficulty.values.indexOf(selected),
          onChanged: (i) => onChanged(Difficulty.values[i]),
        ),
        const SizedBox(height: 8),
        Text(
          _hints[selected]!,
          style: SxText.bodySm.copyWith(color: c.textBody),
        ),
      ],
    );
  }
}

/// Onboarding step: how experienced the user is. Only affects automatic suggestions.
class SetupExperienceStep extends StatelessWidget {
  const SetupExperienceStep({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final Difficulty selected;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SetupList(
      children: [
        Semantics(
          header: true,
          child: Text(
            'Your experience',
            style: SxText.headlineLg.copyWith(color: c.textHigh),
          ),
        ),
        Text(
          'This only shapes the exercises StationX suggests. You can still pick any exercise by hand, and changing it later never changes a program you have saved. Not sure? Keep Intermediate.',
          style: SxText.bodyMd.copyWith(color: c.textBody),
        ),
        ExperiencePicker(selected: selected, onChanged: onChanged),
      ],
    );
  }
}
