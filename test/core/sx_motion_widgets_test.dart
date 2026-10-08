import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/theme/sx_spacing.dart';
import 'package:stationx/core/widgets/widgets.dart';

import '_kit_harness.dart';

double _opacity(WidgetTester t, Finder f) =>
    t.widget<FadeTransition>(find.ancestor(of: f, matching: find.byType(FadeTransition)).first).opacity.value;

void main() {
  group('SxFadeSlideIn', () {
    testWidgets('starts hidden, plays once, ends visible', (t) async {
      await pumpKit(t, const SxFadeSlideIn(delay: Duration(milliseconds: 100), child: Text('hi')));
      expect(_opacity(t, find.text('hi')), 0);
      await t.pump(const Duration(milliseconds: 100));
      expect(_opacity(t, find.text('hi')), 0);
      await t.pump(const Duration(milliseconds: 150));
      expect(_opacity(t, find.text('hi')), inExclusiveRange(0, 1));
      await t.pumpAndSettle();
      expect(_opacity(t, find.text('hi')), 1);
    });

    testWidgets('reduced motion: visible immediately, no offset', (t) async {
      await pumpKit(t, const SxFadeSlideIn(delay: Duration(milliseconds: 100), child: Text('hi')), reduced: true);
      expect(_opacity(t, find.text('hi')), 1);
      expect(t.hasRunningAnimations, isFalse);
    });
  });

  group('SxStagger', () {
    test('delay is index based and capped', () {
      const a = SxStagger(index: 3, child: SizedBox());
      const b = SxStagger(index: 99, child: SizedBox());
      expect(a.delay, SxMotion.stagger * 3);
      expect(b.delay, SxMotion.stagger * SxMotion.staggerCap);
    });

    testWidgets('only plays on first build', (t) async {
      Widget list(String label) => Column(children: [
            for (var i = 0; i < 3; i++) SxStagger(index: i, child: Text('$label$i')),
          ]);
      await pumpKit(t, list('a'));
      expect(_opacity(t, find.text('a2')), 0);
      await t.pumpAndSettle();
      await pumpKit(t, list('a')); // rebuild same tree
      expect(_opacity(t, find.text('a2')), 1);
    });
  });

  group('SxPressable', () {
    testWidgets('scales on press, keeps button semantics, fires tap', (t) async {
      var taps = 0;
      final h = t.ensureSemantics();
      await pumpKit(t, SxPressable(onTap: () => taps++, semanticLabel: 'Go', child: const SizedBox(width: 100, height: 48)));
      final g = await t.startGesture(t.getCenter(find.byType(SxPressable)));
      await t.pump(const Duration(milliseconds: 200));
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.97);
      await g.up();
      await t.pumpAndSettle();
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect(taps, 1);
      expect(t.getSemantics(find.byType(SxPressable)), matchesSemantics(label: 'Go', isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true));
      h.dispose();
    });

    testWidgets('keyboard activation and disabled is not focusable', (t) async {
      var taps = 0;
      await pumpKit(t, SxPressable(onTap: () => taps++, child: const SizedBox(width: 100, height: 48)));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
      await pumpKit(t, SxPressable(enabled: false, onTap: () => taps++, child: const SizedBox(width: 100, height: 48)));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
    });

    testWidgets('reduced motion: no scale', (t) async {
      await pumpKit(t, SxPressable(onTap: () {}, child: const SizedBox(width: 100, height: 48)), reduced: true);
      final g = await t.startGesture(t.getCenter(find.byType(SxPressable)));
      await t.pump();
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await g.up();
    });

    testWidgets('SxButton: 0.97 scale, disabled is semantic-disabled and not focusable', (t) async {
      final h = t.ensureSemantics();
      await pumpKit(t, const SxButton(label: 'Save', onPressed: null));
      expect(t.getSemantics(find.byType(SxButton)), matchesSemantics(label: 'Save', isButton: true, hasEnabledState: true, isEnabled: false));
      var n = 0;
      await pumpKit(t, SxButton(label: 'Save', onPressed: () => n++));
      final g = await t.startGesture(t.getCenter(find.byType(SxButton)));
      await t.pump(const Duration(milliseconds: 200));
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.97);
      await g.up();
      await t.pumpAndSettle();
      expect(n, 1);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      expect(n, 2);
      h.dispose();
    });

    testWidgets('SxCard scales 0.985 and keeps its ripple', (t) async {
      await pumpKit(t, SxCard(onTap: () {}, child: const SizedBox(width: 100, height: 60)));
      expect(find.byType(InkWell), findsOneWidget);
      final g = await t.startGesture(t.getCenter(find.byType(SxCard)));
      await t.pump(const Duration(milliseconds: 200));
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.985);
      await g.up();
      await t.pumpAndSettle();
    });
  });

  group('SxCountUp / SxGrow', () {
    testWidgets('counts from 0 on first build, then from previous', (t) async {
      Widget w(double v) => SxCountUp(value: v);
      await pumpKit(t, w(100));
      expect(find.text('0'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 250));
      final mid = int.parse((t.widget<Text>(find.byType(Text)).data)!);
      expect(mid, inExclusiveRange(0, 100));
      await t.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
      await pumpKit(t, w(200));
      await t.pump(const Duration(milliseconds: 100));
      final mid2 = int.parse((t.widget<Text>(find.byType(Text)).data)!);
      expect(mid2, inExclusiveRange(100, 200));
      await t.pumpAndSettle();
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('reduced motion shows final value at once; custom formatter', (t) async {
      await pumpKit(t, SxCountUp(value: 12.5, formatter: (v) => '${v.toStringAsFixed(1)} kg'), reduced: true);
      expect(find.text('12.5 kg'), findsOneWidget);
      expect(t.hasRunningAnimations, isFalse);
    });
  });

  group('SxSwap / SxStepTransition', () {
    testWidgets('SxSwap crossfades, reduced is instant', (t) async {
      Widget w(String k) => SxSwap(child: Text(k, key: ValueKey(k)));
      await pumpKit(t, w('a'));
      await pumpKit(t, w('b'));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      await t.pumpAndSettle();
      expect(find.text('a'), findsNothing);
      await pumpKit(t, w('c'), reduced: true);
      await t.pumpAndSettle();
      expect(find.text('b'), findsNothing);
    });

    testWidgets('SxStepTransition slides in the direction of travel', (t) async {
      Widget w(int s) => SxStepTransition(step: s, child: Text('step$s'));
      await pumpKit(t, w(0));
      await pumpKit(t, w(1));
      await t.pump(const Duration(milliseconds: 100));
      final fwd = t.widgetList<SlideTransition>(find.byType(SlideTransition)).map((s) => s.position.value.dx).toList();
      expect(fwd.any((d) => d > 0), isTrue); // new step enters from the right
      expect(fwd.any((d) => d < 0), isTrue); // old step leaves to the left
      await t.pumpAndSettle();
      await pumpKit(t, w(0));
      await t.pump(const Duration(milliseconds: 100));
      final back = t.widgetList<SlideTransition>(find.byType(SlideTransition)).map((s) => s.position.value.dx).toList();
      expect(back.any((d) => d < 0), isTrue);
      await t.pumpAndSettle();
    });

    testWidgets('SxStepTransition reduced: no slide', (t) async {
      await pumpKit(t, SxStepTransition(step: 0, child: const Text('a')), reduced: true);
      await pumpKit(t, SxStepTransition(step: 1, child: const Text('b')), reduced: true);
      expect(find.byType(SlideTransition), findsNothing);
    });
  });

  group('SxPop', () {
    testWidgets('pops once when activated, haptic fires, reduced does not scale', (t) async {
      var haptics = 0;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
        if (c.method == 'HapticFeedback.vibrate') haptics++;
        return null;
      });
      addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      Widget w(bool a) => SxPop(active: a, playOnMount: false, haptic: true, child: const SizedBox(width: 20, height: 20));
      await pumpKit(t, w(false));
      expect(haptics, 0);
      await pumpKit(t, w(true));
      await t.pump(const Duration(milliseconds: 60));
      expect(t.widget<ScaleTransition>(find.descendant(of: find.byType(SxPop), matching: find.byType(ScaleTransition))).scale.value, greaterThan(1));
      expect(haptics, 1);
      await t.pumpAndSettle();
      expect(t.widget<ScaleTransition>(find.descendant(of: find.byType(SxPop), matching: find.byType(ScaleTransition))).scale.value, 1);
      await pumpKit(t, w(true)); // no replay
      expect(t.hasRunningAnimations, isFalse);

      await pumpKit(t, w(false), reduced: true);
      await pumpKit(t, w(true), reduced: true);
      await t.pump(const Duration(milliseconds: 60));
      expect(t.widget<ScaleTransition>(find.descendant(of: find.byType(SxPop), matching: find.byType(ScaleTransition))).scale.value, 1);
    });
  });

  testWidgets('SxScaffold animateIn staggers children; default is static; drag dismisses keyboard', (t) async {
    await pumpKit(t, const SizedBox(width: 390, height: 700, child: SxScaffold(animateIn: true, children: [Text('one'), Text('two')])));
    expect(_opacity(t, find.text('two')), 0);
    await t.pumpAndSettle();
    expect(_opacity(t, find.text('two')), 1);
    expect(t.widget<ListView>(find.byType(ListView)).keyboardDismissBehavior, ScrollViewKeyboardDismissBehavior.onDrag);
    await pumpKit(t, const SizedBox(width: 390, height: 700, child: SxScaffold(children: [Text('one')])));
    expect(find.byType(SxStagger), findsNothing);
  });
}
