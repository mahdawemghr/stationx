import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/theme/sx_colors.dart';
import 'package:stationx/core/theme/sx_theme.dart';

final _theme = buildStationXTheme(SxColors.obsidian);

/// Pumps [child] under the StationX theme with optional reduced motion / size.
Future<void> pumpKit(
  WidgetTester t,
  Widget child, {
  bool reduced = false,
  Size size = const Size(390, 800),
  double dpr = 1,
  double textScale = 1,
}) async {
  t.view.physicalSize = size * dpr;
  t.view.devicePixelRatio = dpr;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: _theme,
    builder: (ctx, c) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(
        disableAnimations: reduced,
        textScaler: TextScaler.linear(textScale),
      ),
      child: c!,
    ),
    home: Scaffold(body: Align(alignment: Alignment.topLeft, child: child)),
  ));
}
