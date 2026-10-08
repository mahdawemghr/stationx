import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/theme/sx_colors.dart';
import 'package:stationx/core/theme/sx_spacing.dart';
import 'package:stationx/core/theme/sx_typography.dart';

import '_kit_harness.dart';

void main() {
  test('motion tokens', () {
    expect(SxMotion.micro, const Duration(milliseconds: 120));
    expect(SxMotion.short, const Duration(milliseconds: 200));
    expect(SxMotion.standard, const Duration(milliseconds: 300));
    expect(SxMotion.emphasis, const Duration(milliseconds: 500));
    expect(SxMotion.stagger, const Duration(milliseconds: 40));
    expect(SxMotion.staggerDelay(3), const Duration(milliseconds: 120));
    expect(SxMotion.staggerDelay(50), SxMotion.stagger * 8);
    expect(SxMotion.enter, Curves.easeOutCubic);
    expect(SxMotion.exit, Curves.easeInCubic);
    expect(SxMotion.overshoot, Curves.easeOutBack);
    expect(SxRadius.xs, 6);
    expect(SxText.labelXs.fontSize, 10);
    expect(SxText.labelSm.fontSize, 12);
  });

  testWidgets('SxMotion.of / reduced honour disableAnimations', (t) async {
    late Duration d;
    late bool r;
    Widget probe() => Builder(builder: (ctx) {
          d = SxMotion.of(ctx, SxMotion.standard);
          r = SxMotion.reduced(ctx);
          return const SizedBox();
        });
    await pumpKit(t, probe());
    expect(d, SxMotion.standard);
    expect(r, isFalse);
    await pumpKit(t, probe(), reduced: true);
    expect(d, Duration.zero);
    expect(r, isTrue);
  });

  test('colour tokens: onDanger / scrim / navBar present in both variants', () {
    for (final c in [SxColors.obsidian, SxColors.oled]) {
      expect(c.onDanger, const Color(0xFFFFDAD6));
      expect(c.scrim.a, lessThan(1));
      expect(c.navBar, c.surface1);
      expect(c.systemOverlay.systemNavigationBarColor, c.surface1);
    }
  });

  test('lib/core never uses the deprecated SxMotion.fast/base/slow unguarded', () {
    final bad = <String>[];
    final re = RegExp(r'SxMotion\.(fast|base|slow)\b');
    for (final f in Directory('lib/core').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('sx_motion.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (re.hasMatch(lines[i]) && !lines[i].contains('SxMotion.of(')) bad.add('${f.path}:${i + 1}');
      }
    }
    expect(bad, isEmpty);
  });
}
