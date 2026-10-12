import 'package:flutter/material.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import '../theme/sx_typography.dart';
import 'sx_motion_widgets.dart';

/// Line chart with gradient fade. [values] evenly spaced; optional x labels.
/// Painting is isolated by a RepaintBoundary. On first build the line is revealed left to right
/// ([SxGrow], clip based: no per-frame path allocations; instant under reduced motion).
class SxLineChart extends StatefulWidget {
  const SxLineChart({
    super.key,
    required this.values,
    this.labels,
    this.height = 160,
    this.color,
    this.highlightLast = true,
    this.minY,
    this.maxY,
    this.semanticLabel,
    this.animate = true,
  });

  /// Spoken summary; a generated one (point count, first/last/min/max) is used when null.
  final String? semanticLabel;
  final List<double> values;
  final List<String>? labels;
  final double height;
  final Color? color;
  final bool highlightLast;
  final double? minY;
  final double? maxY;

  /// Play the grow-in on first build.
  final bool animate;

  @override
  State<SxLineChart> createState() => _SxLineChartState();
}

class _SxLineChartState extends State<SxLineChart> {
  final _PathCache _cache = _PathCache();

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final w = widget;
    return Semantics(
      label: w.semanticLabel ?? _summary(w.values),
      image: true,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox(
          height: w.height,
          width: double.infinity,
          child: SxGrow(
            value: 1,
            from: w.animate ? 0 : 1,
            duration: SxMotion.emphasis,
            builder: (_, t) => CustomPaint(
              painter: _LinePainter(
                w.values,
                w.labels,
                w.color ?? c.primary,
                c.hairline,
                c.textMuted,
                w.highlightLast,
                w.minY,
                w.maxY,
                progress: t,
                cache: _cache,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Geometry of one line chart, recomputed only when the data or size changes.
class _PathCache {
  List<double>? v;
  Size? size;
  double? minY, maxY;
  bool hasLabels = false;
  late Path path;
  late Path fill;
  late Rect area;
  late Offset first;
  late Offset last;
}

class _LinePainter extends CustomPainter {
  _LinePainter(
    this.v,
    this.labels,
    this.color,
    this.grid,
    this.labelColor,
    this.hl,
    this.minY,
    this.maxY, {
    this.progress = 1,
    this.cache,
  });
  final double progress;
  final _PathCache? cache;
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
    final area = Rect.fromLTWH(
      8,
      8,
      size.width - 16,
      size.height - 16 - labelH,
    );
    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = area.top + area.height * i / 3;
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), gp);
    }
    if (v.isEmpty) return;
    final g = _geometry(size, area);
    final t = progress.clamp(0.0, 1.0);
    final full = t >= 1;
    if (!full) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(
          0,
          0,
          g.first.dx + (g.last.dx - g.first.dx) * t,
          size.height,
        ),
      );
    }
    canvas.drawPath(
      g.fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
        ).createShader(area),
    );
    canvas.drawPath(
      g.path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    if (!full) canvas.restore();
    if (hl && t > 0.85) {
      final k = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
      canvas.drawCircle(
        g.last,
        6 * k,
        Paint()..color = color.withValues(alpha: 0.25),
      );
      canvas.drawCircle(g.last, 3.5 * k, Paint()..color = color);
    }
    if (labels != null) {
      for (var i = 0; i < labels!.length && i < v.length; i++) {
        final tp = TextPainter(
          text: TextSpan(
            text: labels![i],
            style: SxText.labelXs.copyWith(color: labelColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final x = (_x(i, area) - tp.width / 2).clamp(
          0.0,
          size.width - tp.width,
        );
        tp.paint(canvas, Offset(x, size.height - tp.height));
      }
    }
  }

  double _x(int i, Rect area) => v.length == 1
      ? area.center.dx
      : area.left + area.width * i / (v.length - 1);

  _PathCache _geometry(Size size, Rect area) {
    final g = cache ?? _PathCache();
    if (cache != null &&
        identical(g.v, v) &&
        g.size == size &&
        g.minY == minY &&
        g.maxY == maxY &&
        g.hasLabels == (labels != null)) {
      return g;
    }
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
      _x(i, area),
      area.bottom - area.height * ((v[i] - lo) / (hi - lo)),
    );
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < v.length; i++) {
      final p0 = pt(i - 1), p1 = pt(i);
      final mx = (p0.dx + p1.dx) / 2;
      path.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
    }
    g
      ..v = v
      ..size = size
      ..minY = minY
      ..maxY = maxY
      ..hasLabels = labels != null
      ..area = area
      ..first = pt(0)
      ..last = pt(v.length - 1)
      ..path = path
      ..fill = (Path.from(path)
        ..lineTo(pt(v.length - 1).dx, area.bottom)
        ..lineTo(pt(0).dx, area.bottom)
        ..close());
    return g;
  }

  @override
  bool shouldRepaint(_LinePainter o) =>
      o.v != v ||
      o.color != color ||
      o.labels != labels ||
      o.progress != progress;
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
    this.semanticLabel,
  });
  final String? semanticLabel;
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
    final spoken =
        semanticLabel ??
        'Bar chart. ${[for (var i = 0; i < values.length; i++) '${labels[i]} ${_n(values[i])}'].join(', ')}'
            '${target == null ? '' : '. Target ${_n(target!)}'}';
    return Semantics(
      label: spoken,
      image: true,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              if (target != null)
                Positioned.fill(
                  bottom: 22,
                  child: CustomPaint(
                    painter: _TargetLine(target! / maxV, c.textMuted),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < values.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (valueLabels != null &&
                                valueLabels![i].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  valueLabels![i],
                                  style: SxText.labelXs.copyWith(
                                    color: c.textBody,
                                  ),
                                ),
                              ),
                            Flexible(
                              child: LayoutBuilder(
                                builder: (_, cons) => SxGrow(
                                  value: values[i] / maxV,
                                  delay: SxMotion.staggerDelay(i),
                                  builder: (_, f) => Container(
                                    height: (cons.maxHeight * f).clamp(
                                      values[i] > 0 ? 4.0 : 2.0,
                                      double.infinity,
                                    ),
                                    decoration: BoxDecoration(
                                      color: values[i] <= 0
                                          ? c.surface3
                                          : (highlightIndex == null ||
                                                    highlightIndex == i
                                                ? (color ?? c.primary)
                                                : (color ?? c.primary)
                                                      .withValues(alpha: 0.45)),
                                      borderRadius: BorderRadius.circular(
                                        SxRadius.sm,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              labels[i],
                              style: SxText.labelXs.copyWith(
                                color: highlightIndex == i
                                    ? c.primary
                                    : c.textBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _n(num v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String _summary(List<double> v) {
  if (v.isEmpty) return 'Line chart with no data';
  final lo = v.reduce((a, b) => a < b ? a : b),
      hi = v.reduce((a, b) => a > b ? a : b);
  return 'Line chart, ${v.length} points, from ${_n(v.first)} to ${_n(v.last)}, low ${_n(lo)}, high ${_n(hi)}';
}

class _TargetLine extends CustomPainter {
  _TargetLine(this.f, this.color);
  final double f;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * (1 - f);
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), p);
    }
  }

  @override
  bool shouldRepaint(_TargetLine o) => o.f != f;
}

/// Tiny inline trend line.
class SxSparkline extends StatelessWidget {
  const SxSparkline({
    super.key,
    required this.values,
    this.width = 80,
    this.height = 28,
    this.color,
  });
  final List<double> values;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: CustomPaint(
      painter: _LinePainter(
        values,
        null,
        color ?? context.sx.primary,
        Colors.transparent,
        Colors.transparent,
        false,
        null,
        null,
      ),
    ),
  );
}
