import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/theme/sx_colors.dart';

double _lin(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
double _lum(Color c) => 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);
double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// WCAG AA (4.5:1) for every text/icon colour token on every surface it can sit on.
void main() {
  for (final entry in {'obsidian': SxColors.obsidian, 'oled': SxColors.oled}.entries) {
    final c = entry.value;
    final surfaces = {'canvas': c.canvas, 'surface1': c.surface1, 'surface2': c.surface2, 'surface3': c.surface3};
    group('contrast ${entry.key}', () {
      final fg = {'textHigh': c.textHigh, 'textBody': c.textBody, 'textMuted': c.textMuted, 'primary': c.primary, 'positive': c.positive, 'danger': c.danger};
      for (final f in fg.entries) {
        for (final s in surfaces.entries) {
          test('${f.key} on ${s.key} ≥ 4.5', () {
            expect(contrast(f.value, s.value), greaterThanOrEqualTo(4.5), reason: '${f.key} on ${s.key}');
          });
        }
      }
      test('onAccent text on the primary fill ≥ 4.5', () => expect(contrast(c.onAccent, c.primary), greaterThanOrEqualTo(4.5)));
      test('onAccent on pressed primary ≥ 4.5', () => expect(contrast(c.onAccent, c.primaryPressed), greaterThanOrEqualTo(4.5)));
    });
  }
}
