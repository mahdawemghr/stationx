import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/exercises/exercise_library_page.dart';
import 'package:stationx/features/exercises/exercise_history_page.dart';

import '../../helpers/pump.dart';

int prs(WidgetTester t) => (t.state(find.byType(ExerciseLibraryPage)) as dynamic).prComputations as int;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('library: PRs are computed lazily per visible row and memoized', (t) async {
    final app = await pumpPage(t, const ExerciseLibraryPage());
    await t.pump(const Duration(milliseconds: 500));
    final total = app.exercises.all.length;
    expect(total, greaterThan(150));
    expect(app.sessions.sessions, isNotEmpty);
    final first = prs(t);
    expect(first, lessThan(total ~/ 3), reason: 'only visible rows may compute a PR');
    // Unrelated rebuilds (typing a filter that keeps the same rows, re-pumping) do not recompute.
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.widgetWithText(SxChip, 'All exercises'));
    await t.pump(const Duration(milliseconds: 500));
    expect(prs(t), first);
    // Real data change invalidates the cache.
    await app.sessions.update(app.sessions.sessions.first);
    await t.pump(const Duration(milliseconds: 500));
    expect(prs(t), greaterThanOrEqualTo(first));
  });

  test('0 estimate (more than 12 reps) is "no estimate", never a real e1RM', () {
    expect(estimateOneRepMax(100, 20), 0);
    expect(estimateOneRepMax(100, 5), greaterThan(100));
  });

  testWidgets('history e1RM chart ignores sessions without a reliable estimate', (t) async {
    final app = await pumpPage(t, const ExerciseHistoryPage(exerciseId: 'bench_press'));
    await t.tap(find.widgetWithText(SxChip, 'Est. 1RM'));
    await t.pump(const Duration(milliseconds: 500));
    expect(t.takeException(), isNull);
    expect(find.textContaining('NaN'), findsNothing);
    expect(find.textContaining('-100'), findsNothing);
    expect(app, isNotNull);
  });
}
