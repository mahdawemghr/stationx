import 'package:flutter/material.dart';

import '../core/theme/sx_colors.dart';
import '../core/theme/sx_theme.dart';
import '../domain/domain.dart';
import '../features/landing/landing_page.dart';
import '../features/shell/main_shell.dart';
import 'app_controller.dart';
import 'app_scope.dart';
import 'session_screens.dart';

class StationXApp extends StatefulWidget {
  const StationXApp({super.key, this.controller});
  final AppController? controller;

  @override
  State<StationXApp> createState() => _StationXAppState();
}

class _StationXAppState extends State<StationXApp> with WidgetsBindingObserver {
  late final AppController _controller = widget.controller ?? AppController();
  final _navKey = GlobalKey<NavigatorState>();
  late SessionPhase _lastPhase = _controller.phase;

  /// The screen that belongs to the account state. Flows that navigate imperatively (login ->
  /// app) replace the whole stack themselves; this decides the root and reacts to the session ending.
  Widget _home(SessionPhase p) => switch (p) {
    SessionPhase.restoring || SessionPhase.loading => const SessionSplash(),
    SessionPhase.signedOut => const LandingPage(),
    SessionPhase.ready => const MainShell(),
    SessionPhase.loadFailed => const LoadFailedScreen(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onSession);
  }

  /// When a signed-in session ends (logout, expired session) from anywhere in the app, drop every
  /// pushed screen and show the landing page, so nothing of the previous user stays on screen.
  void _onSession() {
    final p = _controller.phase;
    final was = _lastPhase;
    _lastPhase = p;
    if (p == SessionPhase.signedOut &&
        (was == SessionPhase.ready || was == SessionPhase.loadFailed)) {
      _navKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LandingPage()),
        (_) => false,
      );
    }
  }

  /// Back in the foreground: re-read the server data (throttled) and finish an expired workout.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onSession);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: Builder(
        builder: (context) {
          final app = AppScope.of(context);
          // Rebuild the theme only when the theme mode changes.
          return ListenableBuilder(
            listenable: app.profile,
            builder: (_, _) => MaterialApp(
              title: 'StationX',
              debugShowCheckedModeBanner: false,
              theme: buildStationXTheme(_colors(app.profile.profile.themeMode)),
              navigatorKey: _navKey,
              home: ListenableBuilder(
                listenable: app,
                builder: (_, _) => _home(app.phase),
              ),
            ),
          );
        },
      ),
    );
  }

  SxColors _colors(SxThemeMode m) => switch (m) {
    SxThemeMode.oled => SxColors.oled,
    // The app is dark-only; "system" resolves to Obsidian dark.
    _ => SxColors.obsidian,
  };
}
