import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/sx_bottom_nav.dart';
import 'package:stationx/features/shell/main_shell.dart';

import '../../helpers/pump.dart';

void main() {
  setUpAll(loadAppFonts);

  int tab(WidgetTester t) => t.widget<SxBottomNav>(find.byType(SxBottomNav)).index;

  testWidgets('swipe left/right moves between tabs and stops at the ends', (t) async {
    await pumpPage(t, const MainShell());
    expect(tab(t), 0);
    await t.fling(find.byType(MainShell), const Offset(-300, 0), 1000);
    await t.pump(const Duration(milliseconds: 500));
    expect(tab(t), 1);
    await t.fling(find.byType(MainShell), const Offset(300, 0), 1000);
    await t.pump(const Duration(milliseconds: 500));
    expect(tab(t), 0);
    await t.fling(find.byType(MainShell), const Offset(300, 0), 1000);
    await t.pump(const Duration(milliseconds: 500));
    expect(tab(t), 0); // no wrap
  });
}
