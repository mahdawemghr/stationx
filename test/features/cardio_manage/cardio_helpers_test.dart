import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/cardio/cardio_home_support.dart';
import 'package:stationx/features/cardio/cardio_manage_helpers.dart';

void main() {
  test('cardioWeek boundaries are calendar days (DST-safe), Monday to Monday', () {
    for (final now in [DateTime(2026, 3, 29, 12), DateTime(2026, 10, 25, 12), DateTime(2026, 11, 1, 23, 30)]) {
      for (final off in [-2, -1, 0, 1]) {
        final w = cardioWeek(now, offsetWeeks: off);
        expect(w.from.weekday, DateTime.monday);
        expect(w.from.hour, 0);
        expect(w.to, DateTime(w.from.year, w.from.month, w.from.day + 7));
        expect(w.to.hour, 0);
      }
    }
  });

  test('goalPeriodRange week starts at local midnight Monday and spans 7 calendar days', () {
    final (a, b) = goalPeriodRange(GoalPeriod.week, DateTime(2026, 10, 28, 9), offset: 1);
    expect(a, DateTime(2026, 10, 19));
    expect(b, DateTime(2026, 10, 26));
  });

  test('running-distance goal only counts running kinds', () {
    final g = CardioGoal(id: 'g', title: 'Weekly Running Distance', metric: GoalMetric.distanceKm, target: 20);
    final now = DateTime(2026, 10, 28, 12);
    CardioSession s(String id, CardioKind k, double km) =>
        CardioSession(id: id, kind: k, workoutDate: DateTime(2026, 10, 27, 8), durationSeconds: 1800, distanceKm: km);
    final sessions = [s('r', CardioKind.outdoorRun, 5), s('t', CardioKind.treadmill, 3), s('b', CardioKind.cycling, 30)];
    expect(goalValueForPeriod(g, sessions, now), 8);
    final other = CardioGoal(id: 'h', title: 'Weekly distance', metric: GoalMetric.distanceKm, target: 20);
    expect(goalValueForPeriod(other, sessions, now), 38);
  });
}
