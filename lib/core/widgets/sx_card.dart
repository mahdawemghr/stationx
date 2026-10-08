import 'package:flutter/material.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import 'sx_motion_widgets.dart';

/// Level-1 surface: card with hairline border, 16 radius.
class SxCard extends StatelessWidget {
  const SxCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SxSpace.md),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = SxRadius.lg,
    this.margin,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final shape = BorderRadius.circular(radius);
    Widget w = Ink(
      decoration: BoxDecoration(
        color: color ?? c.surface1,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? c.hairline),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap != null) {
      w = InkWell(onTap: onTap, borderRadius: shape, child: w);
    }
    w = Material(
      type: MaterialType.transparency,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      borderRadius: shape,
      child: w,
    );
    if (onTap != null) {
      w = SxPressable(scale: 0.985, focusRadius: radius, child: w);
    }
    return margin == null ? w : Padding(padding: margin!, child: w);
  }
}

/// Level-2 inset cell (inputs wells, nested tiles). 8 radius.
class SxInset extends StatelessWidget {
  const SxInset({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.color,
    this.borderColor,
    this.radius = SxRadius.base,
    this.onTap,
    this.alignment,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final shape = BorderRadius.circular(radius);
    Widget w = Ink(
      decoration: BoxDecoration(
        color: color ?? c.surface2,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? c.hairline),
      ),
      child: Container(alignment: alignment, padding: padding, child: child),
    );
    if (onTap != null) w = InkWell(onTap: onTap, borderRadius: shape, child: w);
    w = Material(
      type: MaterialType.transparency,
      borderRadius: shape,
      child: w,
    );
    return onTap == null
        ? w
        : SxPressable(scale: 0.985, focusRadius: radius, child: w);
  }
}
