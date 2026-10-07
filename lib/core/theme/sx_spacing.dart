import 'package:flutter/widgets.dart';

/// 4-pt spacing + radius scale (Stitch tokens).
abstract final class SxSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
  static const double screenMargin = 16;

  /// Content max width on wide screens (tablet/foldable).
  static const double maxContentWidth = 640;
}

abstract final class SxRadius {
  static const double sm = 4;
  static const double base = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}

abstract final class SxMotion {
  /// Zero when the user turned animations off in system accessibility settings.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
}
