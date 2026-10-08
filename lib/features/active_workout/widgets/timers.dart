import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/sx_spacing.dart';
import '../../../core/theme/sx_theme.dart';
import '../../../core/theme/sx_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../active_workout_controller.dart';

/// Rebuilds only [builder]'s subtree once per second. Keeps per-second work
/// out of the page so the workout list never rebuilds because of a clock.
class SecondTicker extends StatefulWidget {
  const SecondTicker({super.key, required this.builder, this.active = true, this.onTick});
  final Widget Function(BuildContext context, DateTime now) builder;
  final bool active;

  /// Called once per second after the clock advanced (side effects belong here, never in [builder]).
  final void Function(DateTime now)? onTick;

  @override
  State<SecondTicker> createState() => _SecondTickerState();
}

class _SecondTickerState extends State<SecondTicker> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SecondTicker old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (widget.active) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
        widget.onTick?.call(_now);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}

/// ELAPSED tile (strength layout).
class ElapsedTile extends StatelessWidget {
  const ElapsedTile({super.key, required this.startedAt, this.dense = false});
  final DateTime startedAt;

  /// Short screens: a 48dp tile instead of 64dp.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      constraints: BoxConstraints(minHeight: dense ? 48 : 64),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 2 : 6),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.circular(SxRadius.lg),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: c.textBody, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ELAPSED',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SxText.labelXs.copyWith(color: c.textBody),
                ),
                SecondTicker(
                  builder: (_, now) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Fmt.clock(now.difference(startedAt).inSeconds),
                      style: SxText.metricLg.copyWith(
                        color: c.textHigh,
                        fontSize: dense ? 22 : 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small elapsed pill (mixed layout header).
class ElapsedPill extends StatelessWidget {
  const ElapsedPill({super.key, required this.startedAt});
  final DateTime startedAt;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(SxRadius.md),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: c.primary),
          const SizedBox(width: 6),
          SecondTicker(
            builder: (_, now) => Text(
              Fmt.clockHms(now.difference(startedAt).inSeconds),
              style: SxText.metricSm.copyWith(
                color: c.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// REST tile: idle shows "--:--"; while resting it only says so, because the pinned [RestChip]
/// in the footer owns the countdown, +30s and SKIP (never two rest UIs).
class RestTile extends StatelessWidget {
  const RestTile({
    super.key,
    required this.controller,
    this.compactWhenIdle = false,
    this.dense = false,
  });
  final ActiveWorkoutController controller;

  /// Short screens: a 48dp tile instead of 64dp.
  final bool dense;

  /// Mixed layout: render nothing (the pinned chip is the only rest UI).
  final bool compactWhenIdle;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return ValueListenableBuilder<RestState?>(
      valueListenable: controller.rest,
      builder: (context, rest, _) {
        if (compactWhenIdle) return const SizedBox.shrink();
        final active = rest != null;
        return AnimatedSize(
          duration: SxMotion.of(context, SxMotion.short),
          alignment: Alignment.topCenter,
          curve: SxMotion.enter,
          child: Container(
            constraints: BoxConstraints(minHeight: dense ? 48 : 64),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 2 : 6),
            decoration: BoxDecoration(
              color: c.surface3,
              borderRadius: BorderRadius.circular(SxRadius.lg),
              border: Border.all(color: active ? c.primaryBorder : c.hairline),
            ),
            child: Row(
              children: [
                Icon(Icons.snooze, color: active ? c.primary : c.textMuted, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'REST',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SxText.labelXs.copyWith(color: active ? c.primary : c.textBody),
                      ),
                      // While resting, the pinned RestChip (footer) owns the countdown, +30s and
                      // SKIP: one rest UI only. The tile just says a rest is running.
                      if (!active)
                        Text('--:--', style: SxText.metricLg.copyWith(color: c.textMuted, fontSize: dense ? 22 : 26))
                      else
                        Semantics(
                          label: 'Rest running. Countdown and skip are at the bottom.',
                          excludeSemantics: true,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('RESTING', style: SxText.metricMd.copyWith(color: c.primary)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.label,
    required this.onTap,
    this.semanticLabel,
  });
  final String label;
  final String? semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      onTap: onTap,
      child: SxPressable(
        semantics: false,
        onTap: onTap,
        scale: 0.94,
        focusRadius: SxRadius.base,
        child: Container(
          constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(SxRadius.base),
            border: Border.all(color: c.hairline),
          ),
          child: Text(
            label,
            style: SxText.labelXs.copyWith(
              color: c.textBody,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact rest countdown pinned above the Finish button: time, +30s and Skip.
class RestChip extends StatelessWidget {
  const RestChip({super.key, required this.controller});
  final ActiveWorkoutController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return ValueListenableBuilder<RestState?>(
      valueListenable: controller.rest,
      builder: (context, rest, _) {
        if (rest == null) return const SizedBox.shrink();
        return SxFadeSlideIn(
          duration: SxMotion.short,
          dy: 8,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: c.surface3,
                borderRadius: BorderRadius.circular(SxRadius.lg),
                border: Border.all(color: c.primaryBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.snooze, color: c.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SecondTicker(
                      builder: (_, now) {
                        final left = rest.endsAt.difference(now).inSeconds;
                        return Semantics(
                          label: left > 0
                              ? 'Rest remaining ${Fmt.clock(left)}'
                              : 'Rest over',
                          excludeSemantics: true,
                          child: Text(
                            left > 0 ? 'REST ${Fmt.clock(left)}' : 'REST OVER',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SxText.metricMd.copyWith(
                              color: left > 0 ? c.primary : c.positive,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _MiniAction(
                    label: '+30s',
                    semanticLabel: 'Add 30 seconds',
                    onTap: () => controller.addRest(30),
                  ),
                  const SizedBox(width: 8),
                  _MiniAction(
                    label: 'SKIP',
                    semanticLabel: 'Skip rest',
                    onTap: controller.skipRest,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
