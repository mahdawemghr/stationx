import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/seed/seed_catalog.dart';
import 'package:stationx/domain/domain.dart';

SetLog s(double kg, int reps, {bool done = true, double? rpe}) =>
    SetLog(weightKg: kg, reps: reps, done: done, rpe: rpe);

WorkoutSession sess(
  String id,
  DateTime d,
  Map<String, List<SetLog>> ex, {
  String workoutId = 'w',
  int dur = 0,
  DateTime? created,
}) => WorkoutSession(
  id: id,
  workoutId: workoutId,
  name: id,
  workoutDate: d,
  durationSeconds: dur,
  exercises: [
    for (final e in ex.entries) ExerciseLog(exerciseId: e.key, sets: e.value),
  ],
  meta: created == null ? null : SyncMeta(createdAt: created),
);

/// The pre-refactor inline formulas, copied verbatim, to prove identical output.
double? legacyPct(num? prev, num cur) =>
    prev != null && prev > 0 ? (cur - prev) / prev * 100 : null;

void main() {
  group('PercentChange', () {
    test('null / zero / negative baseline -> null', () {
      expect(PercentChange.of(null, 5), isNull);
      expect(PercentChange.of(0, 5), isNull);
      expect(PercentChange.of(-3, 5), isNull);
      expect(PercentChange.rounded(0, 5), isNull);
    });
    test('golden values', () {
      expect(PercentChange.of(100, 110), closeTo(10, 1e-9));
      expect(PercentChange.of(100, 80), closeTo(-20, 1e-9));
      expect(PercentChange.of(100, 100), 0);
      expect(PercentChange.of(80, 100), 25);
      expect(PercentChange.rounded(3, 4), 33);
      expect(PercentChange.rounded(200, 203), 2); // 1.5 rounds away from zero
      expect(PercentChange.rounded(200, 197), -2);
      expect(PercentChange.rounded(7, 9), 29);
    });
    test('matches the legacy inline formula across a sweep', () {
      for (var p = 1; p <= 60; p += 7) {
        for (var c = 0; c <= 90; c += 3) {
          expect(PercentChange.of(p, c), legacyPct(p, c));
          expect(
            PercentChange.rounded(p.toDouble(), c.toDouble()),
            legacyPct(p, c)!.round(),
          );
        }
      }
      expect(PercentChange.of(62.5, 71.25), legacyPct(62.5, 71.25));
    });
  });

  group('CompletionPercent', () {
    test('edges', () {
      expect(CompletionPercent.of(0, 0), 0);
      expect(CompletionPercent.of(3, 0), 0);
      expect(CompletionPercent.of(3, -1), 0);
      expect(CompletionPercent.of(0, 10), 0);
      expect(CompletionPercent.of(10, 10), 100);
      expect(CompletionPercent.of(1, 3), 33);
      expect(CompletionPercent.of(2, 3), 67);
      expect(CompletionPercent.of(1, 8), 13); // 12.5 -> 13
    });
    test('matches legacy (done*100/total).round()', () {
      for (var t = 1; t <= 30; t++) {
        for (var d = 0; d <= t; d++) {
          expect(CompletionPercent.of(d, t), (d * 100 / t).round());
        }
      }
    });
  });

  group('ProgressService.strengthChanges', () {
    final from = DateTime(2026, 3, 9), to = DateTime(2026, 3, 16);
    final all = [
      // before the window
      sess('a', DateTime(2026, 3, 2), {
        'bench': [s(80, 5)],
        'squat': [s(100, 5)],
        'row': [s(60, 8)],
      }),
      sess('b', DateTime(2026, 3, 9), {
        'bench': [s(84, 5), s(70, 8)],
        'squat': [s(100, 5)],
        'ohp': [s(40, 8)],
      }),
      sess('c', DateTime(2026, 3, 12), {
        'bench': [s(90, 3)],
        'squat': [s(110, 3)],
        'ohp': [s(42, 6)],
        'row': [s(60, 8, done: false)],
      }),
      sess('d', DateTime(2026, 3, 20), {
        'bench': [s(200, 1)],
      }), // after the window
    ];

    test(
      'golden ranking, baseline = latest earlier session, first in-window otherwise',
      () {
        final r = ProgressService.strengthChanges(all, from: from, to: to);
        expect([for (final x in r) x.exerciseId], ['bench', 'squat', 'ohp']);
        expect(
          (r[0].from, r[0].to),
          (80.0, 90.0),
        ); // top set of the latest earlier session
        expect((r[1].from, r[1].to), (100.0, 110.0));
        expect(
          (r[2].from, r[2].to),
          (40.0, 42.0),
        ); // no earlier session -> first in window
        expect(r[0].percent, closeTo(12.5, 1e-9));
        expect(r[0].delta, 10);
        expect(r.map((x) => x.percent.round()), [13, 10, 5]);
      },
    );
    test('limit and no-limit', () {
      expect(
        ProgressService.strengthChanges(all, from: from, to: to, limit: 1),
        hasLength(1),
      );
      expect(
        ProgressService.strengthChanges(all, from: from, to: to, limit: 0),
        hasLength(3),
      );
    });
    test(
      'empty, single session, not-done and equal/decreasing weights give nothing',
      () {
        expect(
          ProgressService.strengthChanges(const [], from: from, to: to),
          isEmpty,
        );
        final one = [
          sess('x', DateTime(2026, 3, 10), {
            'bench': [s(80, 5)],
          }),
        ];
        expect(
          ProgressService.strengthChanges(one, from: from, to: to),
          isEmpty,
        );
        final down = [
          sess('x', DateTime(2026, 3, 2), {
            'bench': [s(90, 5)],
          }),
          sess('y', DateTime(2026, 3, 10), {
            'bench': [s(80, 5)],
          }),
          sess('z', DateTime(2026, 3, 11), {
            'row': [s(0, 10)],
          }), // bodyweight: from 0 -> excluded
        ];
        expect(
          ProgressService.strengthChanges(down, from: from, to: to),
          isEmpty,
        );
      },
    );
    test('window is half-open [from, to)', () {
      final a = [
        sess('x', DateTime(2026, 3, 2), {
          'bench': [s(80, 5)],
        }),
        sess('y', to, {
          'bench': [s(100, 5)],
        }),
      ];
      expect(ProgressService.strengthChanges(a, from: from, to: to), isEmpty);
    });
    test('ties keep a deterministic size and every row ties on percent', () {
      final t = [
        sess('x', DateTime(2026, 3, 2), {
          'a': [s(100, 5)],
          'b': [s(50, 5)],
        }),
        sess('y', DateTime(2026, 3, 10), {
          'a': [s(110, 5)],
          'b': [s(55, 5)],
        }),
      ];
      final r = ProgressService.strengthChanges(t, from: from, to: to);
      expect(r, hasLength(2));
      expect(r.map((e) => e.percent.round()), [10, 10]);
    });
  });

  group('ProgressService.pushPull', () {
    final cat = seedExercises();
    ExerciseLog log(String id, int n) => ExerciseLog(
      exerciseId: id,
      sets: [for (var i = 0; i < n; i++) s(50, 8)],
    );
    WorkoutSession of(List<ExerciseLog> l) => WorkoutSession(
      id: 'p',
      workoutId: 'w',
      name: 'p',
      workoutDate: DateTime(2026, 1, 1),
      exercises: l,
    );

    test('null when one side is missing or no data', () {
      expect(ProgressService.pushPull(const [], cat), isNull);
      expect(
        ProgressService.pushPull([
          of([log('bench_press', 4)]),
        ], cat),
        isNull,
      );
    });
    test('categories use the 0.8 .. 1.25 band (inclusive)', () {
      expect(
        const PushPullBalance(pull: 4, push: 5).category,
        PushPullCategory.balanced,
      ); // 0.8
      expect(
        const PushPullBalance(pull: 5, push: 4).category,
        PushPullCategory.balanced,
      ); // 1.25
      expect(
        const PushPullBalance(pull: 6, push: 4).category,
        PushPullCategory.pullDominant,
      );
      expect(
        const PushPullBalance(pull: 3, push: 5).category,
        PushPullCategory.pushDominant,
      );
      expect(
        const PushPullBalance(pull: 6, push: 4).ratio.toStringAsFixed(1),
        '1.5',
      );
    });
    test('golden from real catalog sets', () {
      final b = ProgressService.pushPull([
        of([
          log('bench_press', 4),
          log('lateral_raise', 3),
          log('barbell_row', 5),
        ]),
      ], cat)!;
      expect((b.pull, b.push), (5, 7));
      expect(b.category, PushPullCategory.pushDominant); // 5/7 = 0.71
    });
  });

  group('ExerciseHistoryService', () {
    final sessions = [
      sess('late', DateTime(2026, 2, 3), {
        'bench': [s(80, 5, rpe: 8), s(85, 3, rpe: 9.5)],
      }, created: DateTime(2026, 2, 4)),
      sess('early', DateTime(2026, 2, 1), {
        'bench': [s(60, 10)],
        'squat': [s(100, 5)],
      }),
      sess('tie2', DateTime(2026, 2, 3), {
        'bench': [s(70, 20)],
      }, created: DateTime(2026, 2, 5)),
      sess('skip', DateTime(2026, 2, 6), {
        'bench': [s(100, 5, done: false)],
      }),
    ];

    test(
      'oldest -> newest, createdAt breaks date ties, undone logs skipped',
      () {
        final st = ExerciseHistoryService.statsFor('bench', sessions);
        expect([for (final x in st) x.session.id], ['early', 'late', 'tie2']);
        expect(ExerciseHistoryService.statsFor('none', sessions), isEmpty);
        expect(ExerciseHistoryService.statsFor('bench', const []), isEmpty);
      },
    );
    test('aggregates', () {
      final st = ExerciseHistoryService.statsFor('bench', sessions);
      expect(st[1].topWeight, 85);
      expect(st[1].topReps, 5);
      expect(st[1].rpe, 9.5);
      expect(st[0].rpe, isNull);
      expect(st[1].volume, 80 * 5 + 85 * 3);
      expect(
        st[1].e1rm,
        closeTo(
          estimateOneRepMax(80, 5) > estimateOneRepMax(85, 3)
              ? estimateOneRepMax(80, 5)
              : estimateOneRepMax(85, 3),
          1e-9,
        ),
      );
      expect(st[1].hasE1rm, isTrue);
      expect(st[2].e1rm, 0); // 20 reps -> no estimate
      expect(st[2].hasE1rm, isFalse);
      expect(ExerciseHistoryService.totalVolume(st), 600 + 655 + 1400);
      expect(ExerciseHistoryService.totalReps(st), 10 + 8 + 20);
      expect(ExerciseHistoryService.totalVolume(const []), 0);
      expect(ExerciseHistoryService.totalReps(const []), 0);
    });
  });

  group('WorkoutStatsService', () {
    final now = DateTime(2026, 4, 10, 15);
    final sessions = [
      // newest first (repository order)
      sess('n', DateTime(2026, 4, 9), {
        'b': [s(100, 10)],
      }, dur: 3600),
      sess('m', DateTime(2026, 3, 20), {
        'b': [s(50, 10)],
      }, dur: 1800),
      sess('o', DateTime(2026, 1, 1), {
        'b': [s(500, 10)],
      }, dur: 0),
      sess(
        'other',
        DateTime(2026, 4, 9),
        {
          'b': [s(999, 10)],
        },
        workoutId: 'z',
        dur: 600,
      ),
    ];
    test('last/sessionsOf', () {
      expect(WorkoutStatsService.lastSessionOf('w', sessions)!.id, 'n');
      expect(WorkoutStatsService.lastSessionOf('nope', sessions), isNull);
      expect(WorkoutStatsService.sessionsOf('w', sessions), hasLength(3));
    });
    test('30-day volume excludes old sessions and other workouts', () {
      expect(
        WorkoutStatsService.recentVolume('w', sessions, now: now),
        1000 + 500,
      );
      expect(WorkoutStatsService.recentVolume('w', const [], now: now), 0);
      expect(
        WorkoutStatsService.recentVolume('w', sessions, days: 100, now: now),
        1000 + 500 + 5000,
      );
    });
    test('average minutes ignores untimed sessions', () {
      expect(
        WorkoutStatsService.averageMinutes('w', sessions),
        45,
      ); // (3600+1800)/2/60
      expect(WorkoutStatsService.averageMinutes('nope', sessions), isNull);
      expect(WorkoutStatsService.averageMinutes('z', sessions), 10);
    });
    test('topSet ties go to more reps', () {
      final x = sess('t', now, {
        'b': [s(100, 3), s(100, 5), s(90, 12), s(120, 1, done: false)],
      });
      expect(WorkoutStatsService.topSet(x, 'b')!.reps, 5);
      expect(WorkoutStatsService.topSet(x, 'nope'), isNull);
    });
    test('daysAgo', () {
      expect(WorkoutStatsService.daysAgo(DateTime(2026, 4, 10, 23), now), 0);
      expect(WorkoutStatsService.daysAgo(DateTime(2026, 4, 9, 1), now), 1);
      expect(WorkoutStatsService.daysAgo(DateTime(2026, 4, 12), now), -2);
    });
  });
}
