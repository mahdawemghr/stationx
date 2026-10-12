import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_motion.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../profile/profile_page.dart';
import '../progress/progress_page.dart';
import '../today/today_page.dart';
import '../workouts/workouts_hub_page.dart';

/// 4-tab shell. Tab roots are kept alive (IndexedStack) so scroll position and
/// in-progress state survive tab switches. Pushed screens cover the nav bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  /// Switch tab from anywhere below the shell.
  static void switchTab(BuildContext context, int index) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    context.findAncestorStateOfType<_MainShellState>()?._go(index);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int _index = widget.initialIndex;
  final _built = <int>{};

  /// Drives the short cross-fade of the tab area on a tab change (0.35 -> 1).
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: SxMotion.short,
    value: 1,
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.35,
    end: 1,
  ).animate(CurvedAnimation(parent: _fade, curve: SxMotion.enter));

  void _go(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    final d = SxMotion.of(context, SxMotion.short);
    if (d == Duration.zero) {
      _fade.value = 1;
    } else {
      _fade.duration = d;
      _fade.forward(from: 0);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoImport());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoImport();
  }

  /// Opt-in: brings in new watch workouts when the app opens (throttled inside the service).
  Future<void> _autoImport() async {
    if (!mounted) return;
    final sync = context.app.healthSync;
    await sync.autoImport();
    if (!mounted) return;
    final n = sync.takeAutoImportNotice();
    if (n > 0) {
      showSxSnack(
        context,
        n == 1 ? 'Imported 1 new workout' : 'Imported $n new workouts',
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fade.dispose();
    super.dispose();
  }

  /// Fling speed (logical px/s) that counts as a tab swipe; slower drags are ignored.
  static const _swipeVelocity = 300.0;

  /// Swipe left -> next tab, swipe right -> previous tab (no wrap). Horizontal scrollers inside
  /// a page (chip rows, charts) win the gesture arena, so they keep working.
  void _onSwipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < _swipeVelocity) return;
    final dir = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    final next = _index + (v < 0 ? dir : -dir);
    if (next >= 0 && next < _pages.length) _go(next);
  }

  static const _pages = <Widget>[
    TodayPage(),
    WorkoutsHubPage(),
    ProgressPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    _built.add(_index);
    return Scaffold(
      backgroundColor: context.sx.canvas,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _onSwipe,
        child: FadeTransition(
          opacity: _opacity,
          child: IndexedStack(
            index: _index,
            children: [
              for (var i = 0; i < _pages.length; i++)
                _built.contains(i) ? _pages[i] : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _StaleBanner(),
          SxBottomNav(index: _index, onChanged: _go),
        ],
      ),
    );
  }
}

/// Shown when the last background refresh failed: what is on screen may be out of date, and anything
/// the user changes is still confirmed by the server before it is shown as saved.
class _StaleBanner extends StatelessWidget {
  const _StaleBanner();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        if (!app.refreshFailed) return const SizedBox.shrink();
        final c = context.sx;
        return Material(
          color: c.surface2,
          child: InkWell(
            onTap: () => app.refresh(force: true),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.cloud_off_outlined, size: 18, color: c.textBody),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Couldn't refresh. Showing the last loaded data.",
                      style: SxText.bodySm.copyWith(color: c.textHigh),
                    ),
                  ),
                  Text(
                    'Retry',
                    style: SxText.labelUi.copyWith(color: c.primary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
