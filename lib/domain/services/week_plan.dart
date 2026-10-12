/// Training days and rest days of a week. They always add up to 7, so changing one changes the other.
/// This is a weekly *goal* only: it does not pin workouts to weekdays and never changes the rotation.
abstract final class WeekPlan {
  static const int daysInWeek = 7;
  static const int minTraining = 1;
  static const int maxTraining = 7;

  /// Training days limited to 1..7 (older profiles may hold larger values).
  static int training(int days) => days.clamp(minTraining, maxTraining);

  /// Rest days that go with [trainingDays].
  static int rest(int trainingDays) => daysInWeek - training(trainingDays);

  /// Training days that go with [restDays] rest days.
  static int trainingForRest(int restDays) => training(daysInWeek - restDays);

  static String _days(int n) => n == 1 ? 'day' : 'days';

  /// "4 training days · 3 rest days".
  static String summary(int trainingDays) {
    final t = training(trainingDays);
    final r = rest(t);
    return '$t training ${_days(t)} · $r rest ${_days(r)}';
  }
}
