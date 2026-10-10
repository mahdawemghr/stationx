import 'package:flutter/material.dart';

import '../../core/theme/sx_motion.dart';
import '../../core/theme/sx_theme.dart';
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

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  late int _index = widget.initialIndex;
  final _built = <int>{};

  /// Drives the short cross-fade of the tab area on a tab change (0.35 -> 1).
  late final AnimationController _fade = AnimationController(vsync: this, duration: SxMotion.short, value: 1);
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
  void dispose() {
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

  static const _pages = <Widget>[TodayPage(), WorkoutsHubPage(), ProgressPage(), ProfilePage()];

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
            children: [for (var i = 0; i < _pages.length; i++) _built.contains(i) ? _pages[i] : const SizedBox.shrink()],
          ),
        ),
      ),
      bottomNavigationBar: SxBottomNav(index: _index, onChanged: _go),
    );
  }
}
