import 'package:flutter/material.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import '../theme/sx_typography.dart';
import 'sx_button.dart';
import 'sx_logo.dart';
import 'sx_motion_widgets.dart';

/// Top bar used on pushed screens: back button, title, optional status pill and
/// trailing actions. Kept as a plain widget (not AppBar) for exact Stitch metrics.
class SxTopBar extends StatelessWidget implements PreferredSizeWidget {
  const SxTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.showBack = true,
    this.actions = const [],
    this.pill,
    this.showLogo = false,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBack;
  final List<Widget> actions;
  final Widget? pill;
  final bool showLogo;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      decoration: BoxDecoration(
        color: c.canvas,
        border: Border(
          bottom: BorderSide(color: c.hairline.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        // Fixed-height bar: cap text scaling so title + subtitle always fit.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  if (showBack)
                    IconButton(
                      tooltip: 'Back',
                      icon: Icon(Icons.arrow_back, color: c.textHigh),
                      onPressed:
                          onBack ?? () => Navigator.of(context).maybePop(),
                    )
                  else
                    const SizedBox(width: 8),
                  if (showLogo) ...[
                    const SxLogo(size: 32, decorative: true),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SxText.headlineSm.copyWith(
                              color: c.textHigh,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SxText.labelXs.copyWith(color: c.textBody),
                          ),
                      ],
                    ),
                  ),
                  if (pill != null) ...[pill!, const SizedBox(width: 8)],
                  ...actions,
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standard screen: canvas background, centered max-width content, scrollable
/// body with 16px margins. Pass [bottom] for a sticky bottom action area.
class SxScaffold extends StatelessWidget {
  const SxScaffold({
    super.key,
    this.topBar,
    this.children,
    this.body,
    this.bottom,
    this.bottomNav,
    this.padding = const EdgeInsets.fromLTRB(
      SxSpace.screenMargin,
      SxSpace.md,
      SxSpace.screenMargin,
      SxSpace.lg,
    ),
    this.gap = SxSpace.md,
    this.controller,
    this.resizeToAvoidBottomInset = true,
    this.onRefresh,
    this.animateIn = false,
  }) : assert(children != null || body != null);

  final PreferredSizeWidget? topBar;

  /// Convenience: vertically stacked children with [gap] between them (lazy list).
  final List<Widget>? children;

  /// Full custom body (must handle its own scrolling).
  final Widget? body;
  final Widget? bottom;
  final Widget? bottomNav;
  final EdgeInsets padding;
  final double gap;
  final ScrollController? controller;
  final bool resizeToAvoidBottomInset;
  final Future<void> Function()? onRefresh;

  /// Wrap the [children] in a first-build [SxStagger] entry.
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    Widget content =
        body ??
        ListView.separated(
          controller: controller,
          padding: padding,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: children!.length,
          separatorBuilder: (_, _) => SizedBox(height: gap),
          itemBuilder: (_, i) => animateIn
              ? SxStagger(index: i, child: children![i])
              : children![i],
        );
    if (onRefresh != null && body == null) {
      content = RefreshIndicator(
        color: c.primary,
        backgroundColor: c.surface3,
        onRefresh: onRefresh!,
        child: content,
      );
    }
    return Scaffold(
      backgroundColor: c.canvas,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: topBar,
      body: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: SxSpace.maxContentWidth,
                ),
                child: content,
              ),
            ),
          ),
          if (bottom != null)
            Container(
              decoration: BoxDecoration(
                color: c.canvas,
                border: Border(top: BorderSide(color: c.hairline)),
              ),
              child: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: SxSpace.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SxSpace.md,
                        12,
                        SxSpace.md,
                        12,
                      ),
                      child: bottom,
                    ),
                  ),
                ),
              ),
            ),
          ?bottomNav,
        ],
      ),
    );
  }
}

/// Header used by tab roots: logo + brand + local pill + avatar.
class SxBrandBar extends StatelessWidget implements PreferredSizeWidget {
  const SxBrandBar({super.key, required this.name, this.onAvatarTap});
  final String name;
  final VoidCallback? onAvatarTap;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SxSpace.screenMargin,
            ),
            child: Row(
              children: [
                const SxLogo(size: 40, decorative: true),
                const SizedBox(width: 12),
                Flexible(
                  flex: 1000,
                  child: Text(
                    'StationX',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SxText.headlineMd.copyWith(
                      color: c.textHigh,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Hide the pill on narrow / large-text layouts instead of overflowing.
                if (MediaQuery.sizeOf(context).width >= 400 &&
                    MediaQuery.textScalerOf(context).scale(1) <= 1.15) ...[
                  const SizedBox(width: 10),
                  _LocalPill(),
                ],
                const Spacer(),
                _AvatarButton(name: name, onTap: onAvatarTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(SxRadius.full),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'LOCAL',
              overflow: TextOverflow.ellipsis,
              style: SxText.labelXs.copyWith(color: c.textBody),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience: primary CTA used in sticky bottom areas.
class SxBottomCta extends StatelessWidget {
  const SxBottomCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.caption,
    this.captionRight,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? caption;
  final String? captionRight;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SxButton(label: label, onPressed: onPressed, icon: icon),
        if (caption != null || captionRight != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (caption != null)
                  Flexible(
                    child: Text(
                      caption!,
                      overflow: TextOverflow.ellipsis,
                      style: SxText.labelXs.copyWith(color: c.textBody),
                    ),
                  ),
                if (captionRight != null)
                  Flexible(
                    child: Text(
                      captionRight!,
                      overflow: TextOverflow.ellipsis,
                      style: SxText.labelXs.copyWith(color: c.primary),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Profile avatar with a 48dp touch target and a spoken label.
class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.name, required this.onTap});
  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: 'Profile, $name',
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(child: SxAvatar(name, size: 40)),
      ),
    ),
  );
}
