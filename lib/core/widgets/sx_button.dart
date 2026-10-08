import 'package:flutter/material.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import '../theme/sx_typography.dart';
import 'sx_controls.dart';
import 'sx_motion_widgets.dart';

enum SxButtonVariant { primary, secondary, ghost, danger }

/// Primary action pill / secondary / ghost / destructive. Press scales to 0.97 (SxPressable); focusable via keyboard when enabled.
class SxButton extends StatefulWidget {
  const SxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = SxButtonVariant.primary,
    this.expanded = true,
    this.height = 52,
    this.radius = SxRadius.md,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final SxButtonVariant variant;
  final bool expanded;
  final double height;
  final double radius;
  final bool loading;

  @override
  State<SxButton> createState() => _SxButtonState();
}

class _SxButtonState extends State<SxButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final enabled = widget.onPressed != null && !widget.loading;
    late Color bg, fg;
    BorderSide? side;
    switch (widget.variant) {
      case SxButtonVariant.primary:
        bg = _down ? c.primaryPressed : c.primary;
        fg = c.onAccent;
      case SxButtonVariant.secondary:
        bg = c.surface2;
        fg = c.textHigh;
        side = BorderSide(color: _down ? c.primary : c.hairline);
      case SxButtonVariant.ghost:
        bg = _down ? c.surface1 : Colors.transparent;
        fg = c.textBody;
      case SxButtonVariant.danger:
        bg = c.dangerContainer;
        fg = c.onDanger;
    }
    if (!enabled) {
      bg = widget.variant == SxButtonVariant.primary
          ? c.surface3
          : bg.withValues(alpha: 0.5);
      fg = c.textMuted;
    }
    final child = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SxSpinner(size: 18, color: fg)
        else if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: SxText.headlineSm.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontSize: 16,
            ),
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: 20, color: fg),
        ],
      ],
    );
    // Minimum 48dp touch target (Material/WCAG), whatever height the call site asks for.
    final h = widget.height < 48 ? 48.0 : widget.height;
    return SxPressable(
      enabled: enabled,
      scale: 0.97,
      focusRadius: widget.radius,
      semanticLabel: widget.label,
      excludeChildSemantics:
          true, // the visible text is the label; don't announce it twice
      onTap: enabled ? widget.onPressed : null,
      onPressedChanged: (v) => setState(() => _down = v),
      child: AnimatedContainer(
        duration: SxMotion.of(context, SxMotion.micro),
        height: h,
        padding: const EdgeInsets.symmetric(horizontal: SxSpace.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.radius),
          border: side == null ? null : Border.fromBorderSide(side),
        ),
        child: child,
      ),
    );
  }
}

/// 40×40 rounded icon button on surface-2 (Stitch top-bar / quick actions).
class SxIconButton extends StatelessWidget {
  const SxIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 40,
    this.iconColor,
    this.filled = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? iconColor;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      container: true,
      button: true,
      label: tooltip,
      excludeSemantics: true,
      onTap: onPressed,
      child: Tooltip(
        message: tooltip ?? '',
        excludeFromSemantics: true,
        child: Material(
          color: filled ? c.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(SxRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(SxRadius.md),
            onTap: onPressed,
            child: SizedBox(
              width: size < 48 ? 48 : size,
              height: size < 48 ? 48 : size,
              child: Center(
                child: Icon(icon, size: 20, color: iconColor ?? c.textBody),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
