import 'package:flutter/material.dart';

/// Font families bundled in assets/fonts (offline-first: no runtime download).
abstract final class SxFonts {
  static const headline = 'SpaceGrotesk';
  static const body = 'Geist';
  static const mono = 'JetBrainsMono';
}

/// Type scale from the Stitch design system. Colour is applied by the theme /
/// call-site (`.copyWith(color: ...)`), not baked in here.
abstract final class SxText {
  static const displayHero = TextStyle(
    fontFamily: SxFonts.headline,
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
  );
  static const headlineLg = TextStyle(
    fontFamily: SxFonts.headline,
    fontSize: 26,
    height: 32 / 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.26,
  );
  static const headlineMd = TextStyle(
    fontFamily: SxFonts.headline,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.22,
  );
  static const headlineSm = TextStyle(
    fontFamily: SxFonts.headline,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
  );
  static const bodyLg = TextStyle(
    fontFamily: SxFonts.body,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.16,
  );
  static const bodyMd = TextStyle(
    fontFamily: SxFonts.body,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );
  static const bodySm = TextStyle(
    fontFamily: SxFonts.body,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.12,
  );
  static const metricXl = TextStyle(
    fontFamily: SxFonts.mono,
    fontSize: 48,
    height: 1,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.9,
  );
  static const metricLg = TextStyle(
    fontFamily: SxFonts.mono,
    fontSize: 32,
    height: 34 / 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.96,
  );
  static const metricMd = TextStyle(
    fontFamily: SxFonts.mono,
    fontSize: 20,
    height: 24 / 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
  static const metricSm = TextStyle(
    fontFamily: SxFonts.mono,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w500,
  );
  static const labelCaps = TextStyle(
    fontFamily: SxFonts.mono,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.88,
  );

  /// 10 sp mono caps (nav labels, tags, chart axes). Smallest text in the app.
  static const labelXs = TextStyle(
    fontFamily: SxFonts.mono,
    fontSize: 10,
    height: 13 / 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
  );

  /// 12 sp mono caps (section headings, captions).
  static const labelSm = TextStyle(
    fontFamily: SxFonts.mono,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.96,
  );
  static const labelUi = TextStyle(
    fontFamily: SxFonts.body,
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w500,
  );
}
