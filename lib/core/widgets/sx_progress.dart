import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import 'sx_motion_widgets.dart';

/// Thin linear meter (value 0..1), animates width changes.
class SxLinearMeter extends StatelessWidget {
  const SxLinearMeter({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.trackColor,
    this.semanticLabel,
    this.delay = Duration.zero,
  });

  /// Spoken name for the meter (the percentage is announced as its value).
  final String? semanticLabel;
  final double value;

  /// Entry delay (use SxMotion.staggerDelay(i) in lists).
  final Duration delay;
  final double height;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      label: semanticLabel ?? 'Progress',
      value: '${(value.clamp(0.0, 1.0) * 100).round()} percent',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SxRadius.full),
        child: Container(
          height: height,
          color: trackColor ?? c.surface3,
          alignment: Alignment.centerLeft,
          child: SxGrow(
            value: value.clamp(0.0, 1.0),
            delay: delay,
            builder: (_, v) => FractionallySizedBox(
              widthFactor: v,
              child: Container(color: color ?? c.primary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Segment strip: [filled] of [total] lit (exercise progress).
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.total,
    required this.filled,
    this.height = 4,
    this.semanticLabel,
  });
  final String? semanticLabel;
  final int total;
  final int filled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      label: semanticLabel ?? 'Progress',
      value: '$filled of $total',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: SxMotion.of(context, SxMotion.short),
                height: height,
                decoration: BoxDecoration(
                  color: i < filled ? c.primary : c.surface3,
                  borderRadius: BorderRadius.circular(SxRadius.full),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular progress ring with centre child.
class SxRing extends StatelessWidget {
  const SxRing({
    super.key,
    required this.value,
    this.size = 96,
    this.stroke = 6,
    this.color,
    this.child,
    this.semanticLabel,
    this.delay = Duration.zero,
  });
  final String? semanticLabel;
  final double value;
  final Duration delay;
  final double size;
  final double stroke;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      label: semanticLabel ?? 'Progress',
      value: '${(value.clamp(0.0, 1.0) * 100).round()} percent',
      child: SizedBox(
        width: size,
        height: size,
        child: SxGrow(
          value: value.clamp(0.0, 1.0),
          duration: SxMotion.emphasis,
          delay: delay,
          builder: (_, v) => RepaintBoundary(
            child: CustomPaint(
              painter: _RingPainter(v, stroke, color ?? c.primary, c.surface3),
              child: Center(child: child),
            ),
          ),
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
    final r = Rect.fromCircle(
      center: rect.center,
      radius: (size.shortestSide - stroke) / 2,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = track);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.v != v || o.color != color || o.track != track;
}
