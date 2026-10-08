import 'package:flutter/widgets.dart';

/// Central motion tokens. Every animation in the app should take its duration
/// from here and pass it through [SxMotion.of] so "remove animations" is honoured.
abstract final class SxMotion {
  /// Zero when the user turned animations off in system accessibility settings.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;

  /// True when the user turned animations off (no slides / scales / count-ups).
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  // Durations.
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration emphasis = Duration(milliseconds: 500);

  /// Delay between consecutive items of a staggered entry; at most [staggerCap] steps.
  static const Duration stagger = Duration(milliseconds: 40);
  static const int staggerCap = 8;

  /// Delay for the [index]-th item of a staggered list (capped at [staggerCap] steps).
  static Duration staggerDelay(int index, {int cap = staggerCap}) =>
      stagger * (index < 0 ? 0 : (index > cap ? cap : index));

  // Curves.
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  /// Overshooting curve for emphasis (pops, PR celebrations).
  static const Curve overshoot = Curves.easeOutBack;

  @Deprecated(
    'Use SxMotion.micro / short and wrap in SxMotion.of(context, ...)',
  )
  static const Duration fast = Duration(milliseconds: 150);
  @Deprecated('Use SxMotion.short and wrap in SxMotion.of(context, ...)')
  static const Duration base = Duration(milliseconds: 220);
  @Deprecated('Use SxMotion.standard and wrap in SxMotion.of(context, ...)')
  static const Duration slow = Duration(milliseconds: 320);
}

/// Curve aliases matching the roadmap names.
abstract final class SxCurves {
  static const Curve enter = SxMotion.enter;
  static const Curve exit = SxMotion.exit;
  static const Curve emphasis = SxMotion.overshoot;
}
