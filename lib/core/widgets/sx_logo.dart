import 'package:flutter/material.dart';

import '../theme/sx_theme.dart';

/// StationX brand mark (from design_reference/kinetic_app_icon…): two slanted
/// chevrons (cyan / violet) around a ring on a near-black squircle. Painted as
/// vector so it stays crisp at any size and needs no asset. Brand colours are
/// fixed (they are the logo, not theme tokens).
class SxLogo extends StatelessWidget {
  const SxLogo({super.key, this.size = 36, this.decorative = false});
  final double size;

  /// True when the app name is already next to the logo (avoids reading it twice).
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(size: Size.square(size), painter: const _LogoPainter());
    if (decorative) return ExcludeSemantics(child: mark);
    return Semantics(image: true, label: 'StationX', child: ExcludeSemantics(child: mark));
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  static const _cyanA = Color(0xFF38F9D7);
  static const _cyan = Color(0xFF00F0FF);
  static const _violetA = Color(0xFFC084FC);
  static const _violet = Color(0xFFA855F7);
  static const _ink = Color(0xFF090A0D);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 512;
    canvas.save();
    canvas.scale(k);
    final tile = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 512, 512), const Radius.circular(114));
    canvas.drawRRect(
        tile,
        Paint()
          ..shader = const RadialGradient(center: Alignment(0, -0.2), radius: 0.6 * 1.6, colors: [Color(0xFF1B1E28), _ink])
              .createShader(const Rect.fromLTWH(0, 0, 512, 512)));
    canvas.drawRRect(
        tile.deflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF252A36));

    Path chevron(double dx) => Path()
      ..moveTo(128 + dx, 340)
      ..lineTo(216 + dx, 172)
      ..lineTo(264 + dx, 172)
      ..lineTo(176 + dx, 340)
      ..close();
    Paint grad(Color a, Color b, double dx) => Paint()
      ..shader = LinearGradient(colors: [a, b]).createShader(Rect.fromLTWH(128 + dx, 172, 256, 168));
    canvas.drawPath(chevron(0), grad(_cyanA, _cyan, 0));
    canvas.drawPath(chevron(120), grad(_violetA, _violet, 120));

    const c = Offset(256, 256);
    canvas.drawCircle(c, 46, Paint()..color = _ink);
    canvas.drawCircle(
        c,
        46,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..shader = const LinearGradient(colors: [_cyanA, _cyan]).createShader(Rect.fromCircle(center: c, radius: 52)));
    canvas.drawCircle(c, 20, Paint()..color = _violet);
    canvas.drawCircle(c, 8, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter o) => false;
}

/// Circle avatar with initials.
class SxAvatar extends StatelessWidget {
  const SxAvatar(this.name, {super.key, this.size = 36});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty ? '?' : parts.take(2).map((p) => p[0].toUpperCase()).join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surface3,
        shape: BoxShape.circle,
        border: Border.all(color: c.primaryBorder),
      ),
      child: Text(initials,
          style: TextStyle(
              fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: size * 0.38, color: c.primary)),
    );
  }
}
