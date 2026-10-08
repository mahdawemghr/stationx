import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ByteData;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/app_controller.dart';
import 'package:stationx/app/app_scope.dart';
import 'package:stationx/core/theme/sx_colors.dart';
import 'package:stationx/core/theme/sx_theme.dart';
import 'package:stationx/domain/domain.dart';

/// Where [shot] writes PNGs (a scratch dir outside the repo).
const shotDir = '/tmp/claude-1000/-home-mahdi-Desktop-projects-stationx/339cc30e-0371-4279-bf5e-c9a94eeb7cc4/scratchpad/shots';

/// Fonts declared in pubspec are not auto-loaded by flutter_test; load them.
Future<void> loadAppFonts() async {
  Future<void> load(String family, String path) async {
    final bytes = File(path).readAsBytesSync();
    final l = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
    await l.load();
  }

  await load('SpaceGrotesk', 'assets/fonts/SpaceGrotesk.ttf');
  await load('Geist', 'assets/fonts/Geist.ttf');
  await load('JetBrainsMono', 'assets/fonts/JetBrainsMono.ttf');
  // Material icons
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/home/mahdi/flutter';
  final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final l = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await l.load();
  }
}

/// Pumps `page` inside the real theme + AppScope.
/// [demo] true → seeded demo history; false → empty account.
/// Returns the controller so tests can inspect repositories.
Future<AppController> pumpPage(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool demo = true,
  SxColors colors = SxColors.obsidian,
  HealthRepository? health,
  bool screenReader = false,
  AppController? controller,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final app = controller ?? AppController(health: health);
  if (controller == null && demo) app.startDemo();
  await tester.pumpWidget(AppScope(
    controller: app,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildStationXTheme(colors),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(textScale), accessibleNavigation: screenReader),
        child: RepaintBoundary(key: _boundary, child: child),
      ),
      home: page,
    ),
  ));
  await tester.pump(const Duration(milliseconds: 400));
  return app;
}

final _boundary = GlobalKey();

/// Writes a PNG of the current frame to [shotDir]/[name].png for visual
/// comparison with design_reference/SCREEN/screen.png (view it with Read).
Future<void> shot(WidgetTester tester, String name, {double pixelRatio = 2, String? dir}) async {
  await tester.runAsync(() async {
    final b = _boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: pixelRatio);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final out = dir ?? shotDir;
    Directory(out).createSync(recursive: true);
    File('$out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}
