import 'package:flutter/material.dart';

import '../theme/sx_theme.dart';
import '../theme/sx_typography.dart';

/// Line chart with gradient fade. [values] evenly spaced; optional x labels.
/// Painting is isolated by a RepaintBoundary and only repaints on data change.
class SxLineChart extends StatelessWidget {
  const SxLineChart({
    super.key,
    required this.values,
    this.labels,
    this.height = 160,
    this.color,
    this.highlightLast = true,
    this.minY,
    this.maxY,
  });
  final List<double> values;
  final List<String>? labels;
  final double height;
  final Color? color;
  final bool highlightLast;
  final double? minY;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _LinePainter(values, labels, color ?? c.primary, c.hairline, c.textMuted, highlightLast, minY, maxY),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.v, this.labels, this.color, this.grid, this.labelColor, this.hl, this.minY, this.maxY);
  final List<double> v;
  final List<String>? labels;
  final Color color;
  final Color grid;
  final Color labelColor;
  final bool hl;
  final double? minY;
  final double? maxY;

  @override
  void paint(Canvas canvas, Size size) {
    final labelH = labels == null ? 0.0 : 18.0;
    final area = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16 - labelH);
    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = area.top + area.height * i / 3;
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), gp);
    }
    if (v.isEmpty) return;
    var lo = minY ?? v.reduce((a, b) => a < b ? a : b);
    var hi = maxY ?? v.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 1e-6) {
      hi += 1;
      lo -= 1;
    } else if (minY == null) {
      final pad = (hi - lo) * 0.12;
      lo -= pad;
      hi += pad;
    }
    Offset pt(int i) => Offset(
        v.length == 1 ? area.center.dx : area.left + area.width * i / (v.length - 1),
        area.bottom - area.height * ((v[i] - lo) / (hi - lo)));
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < v.length; i++) {
      final p0 = pt(i - 1), p1 = pt(i);
      final mx = (p0.dx + p1.dx) / 2;
      path.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
    }
    final fill = Path.from(path)
      ..lineTo(pt(v.length - 1).dx, area.bottom)
      ..lineTo(pt(0).dx, area.bottom)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)])
              .createShader(area));
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);
    if (hl) {
      final p = pt(v.length - 1);
      canvas.drawCircle(p, 6, Paint()..color = color.withValues(alpha: 0.25));
      canvas.drawCircle(p, 3.5, Paint()..color = color);
    }
    if (labels != null) {
      for (var i = 0; i < labels!.length && i < v.length; i++) {
        final tp = TextPainter(
          text: TextSpan(text: labels![i], style: SxText.labelCaps.copyWith(fontSize: 9, color: labelColor)),
          textDirection: TextDirection.ltr,
        )..layout();
        final x = (pt(i).dx - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp.paint(canvas, Offset(x, size.height - tp.height));
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter o) => o.v != v || o.color != color || o.labels != labels;
}

/// Simple vertical bar chart. [target] draws a dashed horizontal goal line.
class SxBarChart extends StatelessWidget {
  const SxBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 140,
    this.target,
    this.highlightIndex,
    this.valueLabels,
    this.color,
  });
  final List<double> values;
  final List<String> labels;
  final double height;
  final double? target;
  final int? highlightIndex;
  final List<String>? valueLabels;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final maxV = [...values, target ?? 0, 1.0].reduce((a, b) => a > b ? a : b);
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        child: Stack(children: [
          if (target != null)
            Positioned.fill(
              bottom: 22,
              child: CustomPaint(painter: _TargetLine(target! / maxV, c.textMuted)),
            ),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (valueLabels != null && valueLabels![i].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(valueLabels![i], style: SxText.labelCaps.copyWith(fontSize: 9, color: c.textBody)),
                      ),
                    Flexible(
                      child: LayoutBuilder(
                        builder: (_, cons) => TweenAnimationBuilder<double>(
                          tween: Tween(end: values[i] / maxV),
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOut,
                          builder: (_, f, _) => Container(
                            height: (cons.maxHeight * f).clamp(values[i] > 0 ? 4.0 : 2.0, double.infinity),
                            decoration: BoxDecoration(
                              color: values[i] <= 0
                                  ? c.surface3
                                  : (highlightIndex == null || highlightIndex == i ? (color ?? c.primary) : (color ?? c.primary).withValues(alpha: 0.45)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(labels[i], style: SxText.labelCaps.copyWith(fontSize: 10, color: highlightIndex == i ? c.primary : c.textBody)),
                  ]),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

class _TargetLine extends CustomPainter {
  _TargetLine(this.f, this.color);
  final double f;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * (1 - f);
    final p = Paint()..color = color..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), p);
    }
  }

  @override
  bool shouldRepaint(_TargetLine o) => o.f != f;
}

/// Tiny inline trend line.
class SxSparkline extends StatelessWidget {
  const SxSparkline({super.key, required this.values, this.width = 80, this.height = 28, this.color});
  final List<double> values;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: _LinePainter(values, null, color ?? context.sx.primary, Colors.transparent, Colors.transparent, false, null, null)),
      );
}
