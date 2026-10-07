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
  const SecondTicker({super.key, required this.builder, this.active = true});
  final Widget Function(BuildContext context, DateTime now) builder;
  final bool active;

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
        if (mounted) setState(() => _now = DateTime.now());
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
  const ElapsedTile({super.key, required this.startedAt});
  final DateTime startedAt;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: c.surface1, borderRadius: BorderRadius.circular(SxRadius.lg), border: Border.all(color: c.hairline)),
      child: Row(children: [
        Icon(Icons.timer_outlined, color: c.textBody, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('ELAPSED', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
            SecondTicker(
              builder: (_, now) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(Fmt.clock(now.difference(startedAt).inSeconds),
                    style: SxText.metricLg.copyWith(color: c.textHigh, fontSize: 28)),
              ),
            ),
          ]),
        ),
      ]),
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
          color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md), border: Border.all(color: c.hairline)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_outlined, size: 16, color: c.primary),
        const SizedBox(width: 6),
        SecondTicker(
          builder: (_, now) => Text(Fmt.clockHms(now.difference(startedAt).inSeconds),
              style: SxText.metricSm.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

/// REST tile: idle shows "--:--"; running shows the countdown, SKIP and +30s.
class RestTile extends StatelessWidget {
  const RestTile({super.key, required this.controller, this.compactWhenIdle = false});
  final ActiveWorkoutController controller;

  /// Mixed layout: render nothing while no rest is running.
  final bool compactWhenIdle;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return ValueListenableBuilder<RestState?>(
      valueListenable: controller.rest,
      builder: (context, rest, _) {
        if (rest == null && compactWhenIdle) return const SizedBox.shrink();
        final active = rest != null;
        return AnimatedSize(
          duration: SxMotion.of(context, SxMotion.base),
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.surface3,
              borderRadius: BorderRadius.circular(SxRadius.lg),
              border: Border.all(color: active ? c.primaryBorder : c.hairline),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Icon(Icons.snooze, color: active ? c.primary : c.textMuted, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('REST', style: SxText.labelCaps.copyWith(color: active ? c.primary : c.textBody, fontSize: 10)),
                    if (!active)
                      Text('--:--', style: SxText.metricLg.copyWith(color: c.textMuted, fontSize: 28))
                    else
                      SecondTicker(
                        builder: (_, now) {
                          final left = rest.endsAt.difference(now).inSeconds;
                          final frac = rest.totalSeconds == 0 ? 0.0 : (left / rest.totalSeconds).clamp(0.0, 1.0);
                          return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            // Spoken on focus only; a once-only live region announces the end (below).
                            Semantics(
                              label: left > 0 ? 'Rest remaining ${Fmt.clock(left)}' : 'Rest over',
                              excludeSemantics: true,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(left > 0 ? Fmt.clock(left) : 'GO',
                                    style: SxText.metricLg.copyWith(color: left > 0 ? c.primary : c.positive, fontSize: 28)),
                              ),
                            ),
                            // Live region: empty while resting, becomes text exactly once when the rest
                            // ends, so TalkBack announces it once instead of every second.
                            Semantics(
                              liveRegion: true,
                              label: left <= 0 ? 'Rest over. Start your next set.' : '',
                              child: const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(height: 3, child: SxLinearMeter(value: frac, height: 3, semanticLabel: 'Rest')),
                          ]);
                        },
                      ),
                  ]),
                ),
              ]),
              if (active) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: _MiniAction(label: '+30s', semanticLabel: 'Add 30 seconds', onTap: () => controller.addRest(30))),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniAction(label: 'SKIP', semanticLabel: 'Skip rest', onTap: controller.skipRest)),
                ]),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.label, required this.onTap, this.semanticLabel});
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SxRadius.base),
        child: Container(
          constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.base), border: Border.all(color: c.hairline)),
          child: Text(label, style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
