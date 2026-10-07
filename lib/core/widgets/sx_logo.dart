import 'package:flutter/material.dart';

import '../theme/sx_theme.dart';

/// StationX mark: rounded square with a lime bolt (stand-in until the launcher
/// icon from design_reference/kinetic_app_icon… is exported to an asset).
class SxLogo extends StatelessWidget {
  const SxLogo({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: c.hairline),
      ),
      child: Icon(Icons.bolt, size: size * 0.62, color: c.primary),
    );
  }
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
