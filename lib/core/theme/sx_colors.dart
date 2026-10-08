import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

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
    required this.onAccent,
    required this.positive,
    required this.danger,
    required this.dangerContainer,
    required this.onDanger,
    required this.onDangerSoft,
    required this.scrim,
    required this.edge,
    required this.ink,
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

  /// Text/icon colour on top of the lime accent fill ("rich black" per Stitch).
  final Color onAccent;
  final Color positive;
  final Color danger;
  final Color dangerContainer;

  /// Text/icon colour on [dangerContainer] fills.
  final Color onDanger;

  /// Text/icon colour on top of the light [danger] colour (ColorScheme.onError).
  final Color onDangerSoft;

  /// Modal barrier / dimming overlay.
  final Color scrim;

  /// Faint top-edge highlight on raised surfaces (sheets).
  final Color edge;

  /// Pure black ink (badges on any surface).
  final Color ink;
  final Color textHigh;
  final Color textBody;
  final Color textMuted;

  /// Colour of the Android system navigation bar (matches the bottom nav).
  Color get navBar => surface1;

  /// System UI overlay to apply (status bar transparent, nav bar = [navBar]).
  /// Use from bootstrap/app so the OLED variant follows the theme.
  SystemUiOverlayStyle get systemOverlay => SystemUiOverlayStyle(
    statusBarColor: const Color(0x00000000),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: navBar,
    systemNavigationBarIconBrightness: Brightness.light,
  );

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
    onAccent: Color(0xFF101214),
    positive: Color(0xFF7BF1A8),
    danger: Color(0xFFFFB4AB),
    dangerContainer: Color(0xFF93000A),
    onDanger: Color(0xFFFFDAD6),
    onDangerSoft: Color(0xFF690005),
    scrim: Color(0x99000000),
    edge: Color(0x14FFFFFF),
    ink: Color(0xFF000000),
    textHigh: Color(0xFFFFFFFF),
    textBody: Color(0xFFA6B0BA),
    // Lightened from Stitch's #606A74 (3.3:1) to meet WCAG AA 4.5:1 on every surface tier.
    textMuted: Color(0xFF8B959F),
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
    onAccent: Color(0xFF101214),
    positive: Color(0xFF7BF1A8),
    danger: Color(0xFFFFB4AB),
    dangerContainer: Color(0xFF93000A),
    onDanger: Color(0xFFFFDAD6),
    onDangerSoft: Color(0xFF690005),
    scrim: Color(0x99000000),
    edge: Color(0x14FFFFFF),
    ink: Color(0xFF000000),
    textHigh: Color(0xFFFFFFFF),
    textBody: Color(0xFFA6B0BA),
    // Lightened from Stitch's #606A74 (3.3:1) to meet WCAG AA 4.5:1 on every surface tier.
    textMuted: Color(0xFF8B959F),
  );
}
