import 'package:flutter/material.dart';

import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'setup_widgets.dart';

/// One plain sentence used on the week step and in the review.
const sequenceNote =
    'Miss a day? You just continue with the next workout. Training and rest days only set your weekly goal; they never choose your next workout.';

/// Default days/week from a preset's text such as "3–6 days / week" (range -> middle, rounded up).
int defaultDaysPerWeek(String text, {required int dayCount}) {
  final nums = [
    for (final m in RegExp(r'\d+').allMatches(text)) int.parse(m.group(0)!),
  ].where((n) => n >= 1 && n <= 7).toList();
  if (nums.length >= 2) return ((nums.first + nums[1] + 1) ~/ 2).clamp(1, 7);
  if (nums.length == 1) return nums.first;
  return dayCount.clamp(3, 4);
}

/// Training days and rest days of a week (always 7 together), asked in every path before Review.
class SetupWeekStep extends StatelessWidget {
  const SetupWeekStep({
    super.key,
    required this.value,
    required this.dayCount,
    required this.onChanged,
  });
  final int value;
  final int dayCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final training = WeekPlan.training(value);
    final rest = WeekPlan.rest(training);
    return SetupList(
      children: [
        Semantics(
          header: true,
          child: Text(
            'Training and rest days',
            style: SxText.headlineLg.copyWith(color: c.textHigh),
          ),
        ),
        Text(
          'Training and rest days always add up to 7. Your program has $dayCount ${dayCount == 1 ? 'workout' : 'workouts'} that repeat in order.',
          style: SxText.bodyMd.copyWith(color: c.textBody),
        ),
        SxCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Training days',
                  style: SxText.headlineSm.copyWith(color: c.textHigh),
                ),
              ),
              SxStepper.int(
                label: 'training days',
                value: training,
                min: WeekPlan.minTraining,
                max: WeekPlan.maxTraining,
                onChanged: (n) => onChanged(WeekPlan.training(n)),
              ),
            ],
          ),
        ),
        SxCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Rest days',
                  style: SxText.headlineSm.copyWith(color: c.textHigh),
                ),
              ),
              SxStepper.int(
                label: 'rest days',
                value: rest,
                min: WeekPlan.daysInWeek - WeekPlan.maxTraining,
                max: WeekPlan.daysInWeek - WeekPlan.minTraining,
                onChanged: (n) => onChanged(WeekPlan.trainingForRest(n)),
              ),
            ],
          ),
        ),
        SxCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sequenceNote,
                  style: SxText.bodyMd.copyWith(color: c.textHigh),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
