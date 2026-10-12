/// Relative change between two values, as a percentage.
///
/// Rules (identical to the formulas the screens used to inline):
///  * `(current - previous) / previous * 100`;
///  * `null` when [previous] is null, zero or negative (no meaningful baseline),
///    so callers simply hide the delta;
///  * [rounded] uses Dart's `double.round()` (half away from zero) - the value
///    the UI shows as "+12%".
abstract final class PercentChange {
  /// Unrounded percent change, or null when there is no positive baseline.
  static double? of(num? previous, num current) {
    if (previous == null || previous <= 0) return null;
    return (current - previous) / previous * 100;
  }

  /// [of] rounded to a whole percent.
  static int? rounded(num? previous, num current) =>
      of(previous, current)?.round();
}

/// "Done out of total" as a whole percent (0 when [total] is zero or less).
abstract final class CompletionPercent {
  static int of(num done, num total) =>
      total <= 0 ? 0 : (done * 100 / total).round();
}
