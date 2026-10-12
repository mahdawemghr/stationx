import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/data/import/gym_tracker_import.dart';
import 'package:stationx/data/import/stationx_backup.dart';

String backupOf(AppController a) => StationXBackup.build(
  exercises: a.exercises.all,
  workouts: a.workouts.workouts,
  rotation: a.workouts.rotation,
  sessions: a.sessions.sessions,
  cardio: a.cardio.sessions,
  goals: a.cardio.goals,
  activities: a.cardio.customActivities,
);

StationXBackupPlan planInto(AppController t, String text) =>
    StationXBackup.plan(
      text,
      exercises: t.exercises,
      workouts: t.workouts,
      sessions: t.sessions,
      cardio: t.cardio,
    );

void main() {
  test('a backup of one account restores completely into another', () async {
    final source = AppController();
    await source.startDemo();
    final text = backupOf(source);
    expect(StationXBackup.looksLikeBackup(text), isTrue);

    final target = AppController(); // empty account
    expect(target.sessions.sessions, isEmpty);
    for (final w in target.workouts.workouts.toList()) {
      await target.workouts.deleteWorkout(w.id);
    }
    expect(target.workouts.rotation.workoutIds, isEmpty);
    final plan = planInto(target, text);
    expect(plan.sessions.length, source.sessions.sessions.length);
    expect(plan.cardio.length, source.cardio.sessions.length);
    expect(plan.workouts.length, source.workouts.workouts.length);

    final r = await StationXBackup.apply(
      plan,
      exercises: target.exercises,
      workouts: target.workouts,
      sessions: target.sessions,
      cardio: target.cardio,
    );
    expect(r.added, plan.total);
    expect(target.sessions.sessions.length, source.sessions.sessions.length);
    expect(target.cardio.sessions.length, source.cardio.sessions.length);
    expect(
      target.workouts.workouts.map((w) => w.id).toSet(),
      source.workouts.workouts.map((w) => w.id).toSet(),
    );
    expect(
      target.workouts.rotation.workoutIds,
      source.workouts.rotation.workoutIds,
    );
    // Dates and set details survive.
    final a = source.sessions.sessions.first;
    final b = target.sessions.byId(a.id)!;
    expect(b.workoutDate.toUtc(), a.workoutDate.toUtc());
    expect(b.exercises.length, a.exercises.length);
    expect(b.exercises.first.sets.length, a.exercises.first.sets.length);
  });

  test('restoring twice (or into the same account) adds nothing', () async {
    final source = AppController();
    await source.startDemo();
    final text = backupOf(source);
    final again = planInto(source, text);
    expect(again.isEmpty, isTrue);
    expect(again.skippedExisting, greaterThan(0));
  });

  test('routines of the backup are appended to existing ones', () async {
    final source = AppController();
    await source.startDemo();
    final target = AppController();
    await target.startDemo();
    final before = target.workouts.rotation.workoutIds.toList();
    // Remove one routine from the target so the backup has something new to add.
    final gone = before.last;
    await target.workouts.deleteWorkout(gone);
    final plan = planInto(target, backupOf(source));
    expect(plan.workouts.map((w) => w.id), contains(gone));
    await StationXBackup.apply(
      plan,
      exercises: target.exercises,
      workouts: target.workouts,
      sessions: target.sessions,
      cardio: target.cardio,
    );
    expect(target.workouts.byId(gone), isNotNull);
    expect(target.workouts.rotation.workoutIds, contains(gone));
  });

  test('bad input is rejected with a friendly problem', () {
    final t = AppController();
    expect(
      () => planInto(t, 'not json'),
      throwsA(
        isA<ImportException>().having(
          (e) => e.problem,
          'problem',
          ImportProblem.notJson,
        ),
      ),
    );
    expect(
      () => planInto(t, '{"format":"gym_tracker_export"}'),
      throwsA(
        isA<ImportException>().having(
          (e) => e.problem,
          'problem',
          ImportProblem.wrongFormat,
        ),
      ),
    );
    expect(
      () => planInto(t, '{"format":"stationx_backup","version":99}'),
      throwsA(
        isA<ImportException>().having(
          (e) => e.problem,
          'problem',
          ImportProblem.unsupportedVersion,
        ),
      ),
    );
  });
}
