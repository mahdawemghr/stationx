import 'package:flutter/material.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import '../theme/sx_typography.dart';
import 'sx_button.dart';

/// Empty-state block: icon, title, message, optional actions.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.eyebrow,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Padding(
      padding: const EdgeInsets.all(SxSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.xl), border: Border.all(color: c.hairline)),
            child: Icon(icon, size: 32, color: c.primary),
          ),
          const SizedBox(height: SxSpace.md),
          if (eyebrow != null) ...[
            Text(eyebrow!.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.primary)),
            const SizedBox(height: 6),
          ],
          Text(title, textAlign: TextAlign.center, style: SxText.headlineMd.copyWith(color: c.textHigh)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: SxText.bodyMd.copyWith(color: c.textBody)),
          if (actionLabel != null) ...[
            const SizedBox(height: SxSpace.lg),
            SxButton(label: actionLabel!, onPressed: onAction),
          ],
          if (secondaryLabel != null) ...[
            const SizedBox(height: 8),
            SxButton(label: secondaryLabel!, onPressed: onSecondary, variant: SxButtonVariant.ghost),
          ],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.message = 'Something went wrong.', this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.error_outline,
        title: 'Unable to load',
        message: message,
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
      );
}

/// Pulsing skeleton block for loading placeholders (single shared controller).
class SxSkeleton extends StatefulWidget {
  const SxSkeleton({super.key, this.height = 72, this.width, this.radius = SxRadius.lg});
  final double height;
  final double? width;
  final double radius;

  @override
  State<SxSkeleton> createState() => _SxSkeletonState();
}

class _SxSkeletonState extends State<SxSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Color.lerp(c.surface1, c.surface3, _ctl.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class LoadingList extends StatelessWidget {
  const LoadingList({super.key, this.count = 4, this.itemHeight = 88});
  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(SxSpace.screenMargin),
        child: Column(children: [
          for (var i = 0; i < count; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: SxSkeleton(height: itemHeight)),
        ]),
      );
}

/// Confirmation dialog. Returns true when confirmed.
Future<bool> showSxConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
  Widget? preview,
}) async {
  final c = context.sx;
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(SxSpace.lg),
      // Scrolls when text is large or the screen is short, instead of overflowing.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SxSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: (destructive ? c.dangerContainer : c.primarySoft).withValues(alpha: destructive ? 0.6 : 1),
                    borderRadius: BorderRadius.circular(SxRadius.md)),
                child: Icon(icon, color: destructive ? c.danger : c.primary),
              ),
            if (icon != null) const SizedBox(height: SxSpace.md),
            Text(title.toUpperCase(), style: SxText.headlineMd.copyWith(color: c.textHigh)),
            const SizedBox(height: 8),
            Text(message, style: SxText.bodyMd.copyWith(color: c.textBody)),
            if (preview != null) ...[const SizedBox(height: SxSpace.md), preview],
            const SizedBox(height: SxSpace.lg),
            Row(children: [
              Expanded(child: SxButton(label: cancelLabel, variant: SxButtonVariant.secondary, onPressed: () => Navigator.pop(ctx, false))),
              const SizedBox(width: 12),
              Expanded(
                  child: SxButton(
                      label: confirmLabel,
                      variant: destructive ? SxButtonVariant.danger : SxButtonVariant.primary,
                      onPressed: () => Navigator.pop(ctx, true))),
            ]),
          ],
        ),
      ),
    ),
  );
  return res ?? false;
}

void showSxSnack(BuildContext context, String message, {IconData icon = Icons.check_circle}) {
  final c = context.sx;
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    duration: const Duration(seconds: 2),
    content: Row(children: [
      Icon(icon, size: 18, color: c.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(message)),
    ]),
  ));
}
