import 'package:flutter/material.dart';

import '../core/theme/sx_colors.dart';
import '../core/theme/sx_theme.dart';
import '../domain/domain.dart';
import '../features/landing/landing_page.dart';
import 'app_controller.dart';
import 'app_scope.dart';

class StationXApp extends StatefulWidget {
  const StationXApp({super.key, this.controller});
  final AppController? controller;

  @override
  State<StationXApp> createState() => _StationXAppState();
}

class _StationXAppState extends State<StationXApp> {
  late final AppController _controller = widget.controller ?? AppController();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: Builder(builder: (context) {
        final app = AppScope.of(context);
        // Rebuild the theme only when the theme mode changes.
        return ListenableBuilder(
          listenable: app.profile,
          builder: (_, _) => MaterialApp(
            title: 'StationX',
            debugShowCheckedModeBanner: false,
            theme: buildStationXTheme(_colors(app.profile.profile.themeMode)),
            home: const LandingPage(),
          ),
        );
      }),
    );
  }

  SxColors _colors(SxThemeMode m) => switch (m) {
        SxThemeMode.oled => SxColors.oled,
        // The app is dark-only; "system" resolves to Obsidian dark.
        _ => SxColors.obsidian,
      };
}
