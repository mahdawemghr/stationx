import 'package:flutter/material.dart';

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

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;
  final _built = <int>{};

  void _go(int i) => setState(() => _index = i);

  static const _pages = <Widget>[TodayPage(), WorkoutsHubPage(), ProgressPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    _built.add(_index);
    return Scaffold(
      backgroundColor: context.sx.canvas,
      body: IndexedStack(
        index: _index,
        children: [for (var i = 0; i < _pages.length; i++) _built.contains(i) ? _pages[i] : const SizedBox.shrink()],
      ),
      bottomNavigationBar: SxBottomNav(index: _index, onChanged: _go),
    );
  }
}
