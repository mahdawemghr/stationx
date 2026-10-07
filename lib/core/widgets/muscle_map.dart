import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../theme/sx_theme.dart';

enum MuscleView { front, back, both, auto }

/// Stylised front/back body figure that highlights worked muscles: primary in
/// the accent colour, secondary dimmed. Pure vector (CustomPainter): offline,
/// themeable, no assets. It is a diagram, not anatomy art — regions are
/// simplified to the app's [MuscleGroup]s.
///
/// `auto` picks the side that shows the primary muscles best (back/triceps →
/// back, otherwise front).
class MuscleMap extends StatelessWidget {
  const MuscleMap({
    super.key,
    this.primary = const {},
    this.secondary = const {},
    this.height = 120,
    this.view = MuscleView.auto,
  });

  /// Convenience for a single exercise.
  MuscleMap.exercise(Exercise e, {Key? key, double height = 120, MuscleView view = MuscleView.auto})
      : this(key: key, primary: {e.primaryMuscle}, secondary: e.secondaryMuscles.toSet(), height: height, view: view);

  final Set<MuscleGroup> primary;
  final Set<MuscleGroup> secondary;
  final double height;
  final MuscleView view;

  static const _figW = 60.0;
  static const _figH = 130.0;
  static const _gap = 10.0;

  MuscleView get _resolved {
    if (view != MuscleView.auto) return view;
    final backish = primary.where((m) => m == MuscleGroup.back || m == MuscleGroup.triceps).length;
    return backish * 2 >= primary.length && primary.isNotEmpty ? MuscleView.back : MuscleView.front;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final v = _resolved;
    final figs = v == MuscleView.both ? 2 : 1;
    final w = height * (figs * _figW + (figs - 1) * _gap) / _figH;
    return Semantics(
      container: true,
      image: true,
      label: 'Muscle map. Primary: ${primary.map((m) => m.label).join(', ')}'
          '${secondary.isEmpty ? '' : '. Secondary: ${secondary.map((m) => m.label).join(', ')}'}',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size(w, height),
            painter: _MusclePainter(
              primary: primary,
              secondary: secondary,
              view: v,
              base: c.surface3,
              idle: Color.lerp(c.surface3, c.textMuted, 0.28)!,
              line: c.hairline,
              accent: c.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Region {
  const _Region(this.rect, this.group, {this.front = false, this.back = false, this.radius = 3});
  final Rect rect;
  final MuscleGroup? group;
  final bool front;
  final bool back;
  final double radius;
}

// Regions in a 60 × 130 figure space.
const _regions = <_Region>[
  // Shoulders (both sides of the figure, front + back).
  _Region(Rect.fromLTWH(9.5, 19.5, 11, 12), MuscleGroup.shoulders, front: true, back: true, radius: 5.5),
  _Region(Rect.fromLTWH(39.5, 19.5, 11, 12), MuscleGroup.shoulders, front: true, back: true, radius: 5.5),
  // Chest (front).
  _Region(Rect.fromLTWH(19, 21.5, 10.5, 13), MuscleGroup.chest, front: true, radius: 4.5),
  _Region(Rect.fromLTWH(30.5, 21.5, 10.5, 13), MuscleGroup.chest, front: true, radius: 4.5),
  // Core (front).
  _Region(Rect.fromLTWH(23, 35, 14, 24), MuscleGroup.core, front: true, radius: 4),
  // Back: traps, lats, lower back.
  _Region(Rect.fromLTWH(22, 17, 16, 7), MuscleGroup.back, back: true, radius: 3.5),
  _Region(Rect.fromLTWH(18.5, 26, 10.5, 20), MuscleGroup.back, back: true, radius: 4),
  _Region(Rect.fromLTWH(31, 26, 10.5, 20), MuscleGroup.back, back: true, radius: 4),
  _Region(Rect.fromLTWH(24, 47, 12, 11), MuscleGroup.back, back: true, radius: 3.5),
  // Arms: biceps (front) / triceps (back).
  _Region(Rect.fromLTWH(6, 31, 8, 19), MuscleGroup.biceps, front: true, radius: 4),
  _Region(Rect.fromLTWH(46, 31, 8, 19), MuscleGroup.biceps, front: true, radius: 4),
  _Region(Rect.fromLTWH(6, 31, 8, 19), MuscleGroup.triceps, back: true, radius: 4),
  _Region(Rect.fromLTWH(46, 31, 8, 19), MuscleGroup.triceps, back: true, radius: 4),
  // Legs: quads (front), glutes + hamstrings (back), calves (both).
  _Region(Rect.fromLTWH(18.5, 62, 10.5, 36), MuscleGroup.legs, front: true, radius: 5),
  _Region(Rect.fromLTWH(31, 62, 10.5, 36), MuscleGroup.legs, front: true, radius: 5),
  _Region(Rect.fromLTWH(18.5, 58, 22, 12), MuscleGroup.legs, back: true, radius: 5),
  _Region(Rect.fromLTWH(18.5, 72, 10.5, 26), MuscleGroup.legs, back: true, radius: 5),
  _Region(Rect.fromLTWH(31, 72, 10.5, 26), MuscleGroup.legs, back: true, radius: 5),
  _Region(Rect.fromLTWH(19.5, 101, 8.5, 22), MuscleGroup.legs, front: true, back: true, radius: 4),
  _Region(Rect.fromLTWH(32, 101, 8.5, 22), MuscleGroup.legs, front: true, back: true, radius: 4),
  // Non-tracked parts (forearms) are drawn as silhouette only.
  _Region(Rect.fromLTWH(4, 52, 7, 19), null, front: true, back: true, radius: 3.5),
  _Region(Rect.fromLTWH(49, 52, 7, 19), null, front: true, back: true, radius: 3.5),
];

class _MusclePainter extends CustomPainter {
  _MusclePainter({
    required this.primary,
    required this.secondary,
    required this.view,
    required this.base,
    required this.idle,
    required this.line,
    required this.accent,
  });

  final Set<MuscleGroup> primary;
  final Set<MuscleGroup> secondary;
  final MuscleView view;
  final Color base;
  final Color idle;
  final Color line;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / MuscleMap._figH;
    final sides = view == MuscleView.both ? [true, false] : [view == MuscleView.front];
    for (var i = 0; i < sides.length; i++) {
      canvas.save();
      canvas.translate(i * (MuscleMap._figW + MuscleMap._gap) * scale, 0);
      canvas.scale(scale);
      _figure(canvas, front: sides[i]);
      canvas.restore();
    }
  }

  void _figure(Canvas canvas, {required bool front}) {
    final fill = Paint()..color = base;
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    // Silhouette: head, neck, torso block, pelvis.
    canvas.drawCircle(const Offset(30, 8), 6.2, fill);
    canvas.drawCircle(const Offset(30, 8), 6.2, stroke);
    final body = [
      RRect.fromRectAndRadius(const Rect.fromLTWH(27, 13, 6, 6), const Radius.circular(2)),
      RRect.fromRectAndRadius(const Rect.fromLTWH(15, 18, 30, 44), const Radius.circular(8)),
      RRect.fromRectAndRadius(const Rect.fromLTWH(17.5, 56, 25, 16), const Radius.circular(6)),
    ];
    for (final r in body) {
      canvas.drawRRect(r, fill);
      canvas.drawRRect(r, stroke);
    }
    for (final reg in _regions) {
      if (front ? !reg.front : !reg.back) continue;
      final rr = RRect.fromRectAndRadius(reg.rect, Radius.circular(reg.radius));
      final g = reg.group;
      final Color col;
      if (g != null && primary.contains(g)) {
        col = accent;
      } else if (g != null && secondary.contains(g)) {
        col = accent.withValues(alpha: 0.38);
      } else {
        col = idle;
      }
      canvas.drawRRect(rr, Paint()..color = col);
      if (g != null && primary.contains(g)) {
        canvas.drawRRect(rr, Paint()
          ..color = accent.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 1.6));
      }
    }
  }

  @override
  bool shouldRepaint(_MusclePainter o) =>
      o.view != view || o.primary != primary || o.secondary != secondary || o.accent != accent || o.base != base || o.idle != idle;
}
