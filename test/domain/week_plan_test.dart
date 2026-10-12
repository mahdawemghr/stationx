import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  test('training + rest always add up to 7', () {
    for (var t = 1; t <= 7; t++) {
      expect(WeekPlan.training(t) + WeekPlan.rest(t), 7);
    }
  });

  test('values outside 1..7 are clamped (older profiles may hold 14)', () {
    expect(WeekPlan.training(14), 7);
    expect(WeekPlan.rest(14), 0);
    expect(WeekPlan.training(0), 1);
    expect(WeekPlan.rest(0), 6);
    expect(WeekPlan.training(-3), 1);
  });

  test('rest days map back to training days', () {
    expect(WeekPlan.trainingForRest(3), 4);
    expect(WeekPlan.trainingForRest(0), 7);
    expect(WeekPlan.trainingForRest(6), 1);
    expect(WeekPlan.trainingForRest(7), 1); // never fewer than one training day
    expect(WeekPlan.trainingForRest(-1), 7);
  });

  test('summary is plural-aware', () {
    expect(WeekPlan.summary(4), '4 training days · 3 rest days');
    expect(WeekPlan.summary(1), '1 training day · 6 rest days');
    expect(WeekPlan.summary(6), '6 training days · 1 rest day');
    expect(WeekPlan.summary(7), '7 training days · 0 rest days');
  });
}
