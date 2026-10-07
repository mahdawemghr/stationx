import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';

/// Thin linear meter (value 0..1), animates width changes.
class SxLinearMeter extends StatelessWidget {
  const SxLinearMeter({super.key, required this.value, this.height = 6, this.color, this.trackColor});
  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return ClipRRect(
      borderRadius: BorderRadius.circular(SxRadius.full),
      child: Container(
        height: height,
        color: trackColor ?? c.surface3,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: SxMotion.slow,
          curve: Curves.easeOut,
          builder: (_, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: Container(color: color ?? c.primary),
          ),
        ),
      ),
    );
  }
}

/// Segment strip: [filled] of [total] lit (exercise progress).
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({super.key, required this.total, required this.filled, this.height = 4});
  final int total;
  final int filled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(children: [
      for (var i = 0; i < total; i++) ...[
        if (i > 0) const SizedBox(width: 4),
        Expanded(
          child: AnimatedContainer(
            duration: SxMotion.base,
            height: height,
            decoration: BoxDecoration(
              color: i < filled ? c.primary : c.surface3,
              borderRadius: BorderRadius.circular(SxRadius.full),
            ),
          ),
        ),
      ],
    ]);
  }
}

/// Circular progress ring with centre child.
class SxRing extends StatelessWidget {
  const SxRing({super.key, required this.value, this.size = 96, this.stroke = 6, this.color, this.child});
  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: SxMotion.slow,
        curve: Curves.easeOut,
        builder: (_, v, _) => CustomPaint(
          painter: _RingPainter(v, stroke, color ?? c.primary, c.surface3),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.stroke, this.color, this.track);
  final double v;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = Rect.fromCircle(center: rect.center, radius: (size.shortestSide - stroke) / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = track);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color || o.track != track;
}
