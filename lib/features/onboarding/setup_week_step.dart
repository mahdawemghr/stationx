import 'package:flutter/material.dart';

import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import 'setup_widgets.dart';

/// One plain sentence used on the week step and in the review.
const sequenceNote = 'Miss a day? You just continue with the next workout. Days per week only sets your weekly goal.';

/// Default days/week from a preset's text such as "3–6 days / week" (range -> middle, rounded up).
int defaultDaysPerWeek(String text, {required int dayCount}) {
  final nums = [for (final m in RegExp(r'\d+').allMatches(text)) int.parse(m.group(0)!)].where((n) => n >= 1 && n <= 7).toList();
  if (nums.length >= 2) return ((nums.first + nums[1] + 1) ~/ 2).clamp(1, 7);
  if (nums.length == 1) return nums.first;
  return dayCount.clamp(3, 4);
}

/// "How many days a week?" 1-7, asked in every path before Review.
class SetupWeekStep extends StatelessWidget {
  const SetupWeekStep({super.key, required this.value, required this.dayCount, required this.onChanged});
  final int value;
  final int dayCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SetupList(children: [
      Semantics(header: true, child: Text('How many days a week?', style: SxText.headlineLg.copyWith(color: c.textHigh))),
      Text('This is your weekly goal. Your program has $dayCount ${dayCount == 1 ? 'workout' : 'workouts'} that repeat in order.',
          style: SxText.bodyMd.copyWith(color: c.textBody)),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var n = 1; n <= 7; n++)
          Semantics(
            label: '$n ${n == 1 ? 'day' : 'days'} a week',
            selected: n == value,
            button: true,
            excludeSemantics: true,
            onTap: () => onChanged(n),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: SxChip(label: '$n', selected: n == value, onTap: () => onChanged(n)),
            ),
          ),
      ]),
      SxCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: c.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(sequenceNote, style: SxText.bodyMd.copyWith(color: c.textHigh))),
        ]),
      ),
    ]);
  }
}
