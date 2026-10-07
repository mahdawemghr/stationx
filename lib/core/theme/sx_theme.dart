import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'sx_colors.dart';
import 'sx_spacing.dart';
import 'sx_typography.dart';

/// Theme extension carrying [SxColors]; read with `context.sx`.
class SxTheme extends ThemeExtension<SxTheme> {
  const SxTheme(this.colors);
  final SxColors colors;

  @override
  SxTheme copyWith({SxColors? colors}) => SxTheme(colors ?? this.colors);

  @override
  SxTheme lerp(ThemeExtension<SxTheme>? other, double t) =>
      t < 0.5 ? this : (other as SxTheme? ?? this);
}

extension SxContext on BuildContext {
  SxColors get sx => Theme.of(this).extension<SxTheme>()!.colors;
}

ThemeData buildStationXTheme(SxColors c) {
  final scheme = ColorScheme.dark(
    primary: c.primary,
    onPrimary: c.onPrimary,
    secondary: c.textBody,
    surface: c.canvas,
    onSurface: c.textHigh,
    error: c.danger,
    onError: const Color(0xFF690005),
    outline: c.hairline,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.canvas,
    canvasColor: c.canvas,
    fontFamily: SxFonts.body,
    splashFactory: InkRipple.splashFactory,
    dividerColor: c.hairline,
    extensions: [SxTheme(c)],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: c.textHigh, displayColor: c.textHigh),
    appBarTheme: AppBarTheme(
      backgroundColor: c.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: SxText.headlineSm.copyWith(color: c.textHigh),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface3,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: c.surface3,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(SxRadius.xl))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface3,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SxRadius.xl),
          side: BorderSide(color: c.hairline)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.surface3,
      contentTextStyle: SxText.bodyMd.copyWith(color: c.textHigh),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SxRadius.md)),
    ),
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: const FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: const FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
