import 'package:flutter/material.dart';

/// StationX colour tokens, extracted from the Stitch "Kinetic Obsidian"
/// design system (see docs/STATIONX_UI_IMPLEMENTATION_ROADMAP.md §D).
/// Screens must use these tokens instead of raw hex values.
class SxColors {
  const SxColors({
    required this.canvas,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.hairline,
    required this.primary,
    required this.onPrimary,
    required this.primaryPressed,
    required this.positive,
    required this.danger,
    required this.dangerContainer,
    required this.textHigh,
    required this.textBody,
    required this.textMuted,
  });

  final Color canvas;
  final Color surface1;
  final Color surface2;
  final Color surface3;
  final Color hairline;
  final Color primary;
  final Color onPrimary;
  final Color primaryPressed;
  final Color positive;
  final Color danger;
  final Color dangerContainer;
  final Color textHigh;
  final Color textBody;
  final Color textMuted;

  /// Primary at low alpha — used for tinted fills / selected borders.
  Color get primarySoft => primary.withValues(alpha: 0.12);
  Color get primaryBorder => primary.withValues(alpha: 0.4);

  static const obsidian = SxColors(
    canvas: Color(0xFF121416),
    surface1: Color(0xFF1A1C1E),
    surface2: Color(0xFF1E2022),
    surface3: Color(0xFF282A2C),
    hairline: Color(0xFF2A3036),
    primary: Color(0xFFB8F000),
    onPrimary: Color(0xFF273500),
    primaryPressed: Color(0xFFA2D400),
    positive: Color(0xFF7BF1A8),
    danger: Color(0xFFFFB4AB),
    dangerContainer: Color(0xFF93000A),
    textHigh: Color(0xFFFFFFFF),
    textBody: Color(0xFFA6B0BA),
    textMuted: Color(0xFF606A74),
  );

  /// True-black variant for OLED panels (Profile › Interface Theme › OLED).
  static const oled = SxColors(
    canvas: Color(0xFF000000),
    surface1: Color(0xFF111315),
    surface2: Color(0xFF181B1E),
    surface3: Color(0xFF22262A),
    hairline: Color(0xFF2A3036),
    primary: Color(0xFFB8F000),
    onPrimary: Color(0xFF273500),
    primaryPressed: Color(0xFFA2D400),
    positive: Color(0xFF7BF1A8),
    danger: Color(0xFFFFB4AB),
    dangerContainer: Color(0xFF93000A),
    textHigh: Color(0xFFFFFFFF),
    textBody: Color(0xFFA6B0BA),
    textMuted: Color(0xFF606A74),
  );
}
