import 'package:flutter/material.dart';

import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';

/// Top bar shared by Login / Register: back, logo + brand, caps label, avatar.
class AuthTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AuthTopBar({super.key, required this.label});
  final String label;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      color: c.canvas,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            IconButton(tooltip: 'Back', icon: Icon(Icons.arrow_back, color: c.textHigh), onPressed: () => Navigator.of(context).maybePop()),
            const SxLogo(size: 36, decorative: true),
            const SizedBox(width: 16),
            Expanded(child: Text('StationX', maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.headlineSm.copyWith(color: c.textHigh, fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            Flexible(child: Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody))),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
              child: Icon(Icons.person_outline, color: c.onAccent, size: 22),
            ),
            const SizedBox(width: SxSpace.md),
          ]),
        ),
      ),
    );
  }
}

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
bool isValidEmail(String v) => _emailRe.hasMatch(v.trim());

/// Password rules shown on Register: min 8 chars, an uppercase letter, a digit.
List<bool> passwordRules(String p) => [p.length >= 8, RegExp(r'[A-Z]').hasMatch(p), RegExp(r'\d').hasMatch(p)];

/// Visibility toggle used as a text-field trailing widget.
class VisibilityToggle extends StatelessWidget {
  const VisibilityToggle({super.key, required this.visible, required this.onToggle});
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: visible ? 'Hide password' : 'Show password',
        icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: context.sx.textBody),
        onPressed: onToggle,
      );
}
