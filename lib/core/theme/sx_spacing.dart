export 'sx_motion.dart';

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
  static const double xs = 6;
  static const double sm = 4;
  static const double base = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}
