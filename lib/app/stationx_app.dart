import 'package:flutter/material.dart';

import '../core/theme/sx_colors.dart';
import '../core/theme/sx_theme.dart';
import '../domain/domain.dart';
import '../features/landing/landing_page.dart';
import '../features/shell/main_shell.dart';
import 'app_controller.dart';
import 'app_scope.dart';

class StationXApp extends StatefulWidget {
  const StationXApp({super.key, this.controller});
  final AppController? controller;

  @override
  State<StationXApp> createState() => _StationXAppState();
}

class _StationXAppState extends State<StationXApp> with WidgetsBindingObserver {
  late final AppController _controller = widget.controller ?? AppController();

  /// Resolved once: returning users go straight to the app, new/signed-out
  /// users to the landing screen. (Changing `home` later would not re-route.)
  late final Widget _home = _controller.signedIn ? const MainShell() : const LandingPage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Pull fresh wearable data when returning to the app (throttled in the repository).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.health.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
            home: _home,
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
