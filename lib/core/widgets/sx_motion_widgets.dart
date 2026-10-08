import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';

/// Light haptic tick; never throws (tests / unsupported platforms).
void sxHaptic() {
  try {
    HapticFeedback.lightImpact().catchError((Object _) {});
  } catch (_) {}
}

/// One-shot fade + upward slide on first build. Skips both under reduced motion.
class SxFadeSlideIn extends StatefulWidget {
  const SxFadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = SxMotion.standard,
    this.dy = 12,
    this.curve = SxMotion.enter,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Initial downward offset in logical pixels (slides up to 0).
  final double dy;
  final Curve curve;

  @override
  State<SxFadeSlideIn> createState() => _SxFadeSlideInState();
}

class _SxFadeSlideInState extends State<SxFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  late Animation<double> _t;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (SxMotion.reduced(context)) {
      _t = const AlwaysStoppedAnimation(1);
      _c.value = 1;
      return;
    }
    final total = widget.delay + widget.duration;
    _c.duration = total;
    final begin = total.inMicroseconds == 0
        ? 0.0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(begin, 1, curve: widget.curve),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _t,
      child: AnimatedBuilder(
        animation: _t,
        child: widget.child,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, widget.dy * (1 - _t.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Index-based staggered entry (only plays on first build of the item).
class SxStagger extends StatelessWidget {
  const SxStagger({
    super.key,
    required this.index,
    required this.child,
    this.cap = SxMotion.staggerCap,
    this.step = SxMotion.stagger,
    this.dy = 12,
    this.duration = SxMotion.standard,
    this.enabled = true,
  });

  final int index;
  final Widget child;
  final int cap;
  final Duration step;
  final double dy;
  final Duration duration;
  final bool enabled;

  Duration get delay => step * (index < 0 ? 0 : (index > cap ? cap : index));

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return SxFadeSlideIn(
      delay: delay,
      dy: dy,
      duration: duration,
      child: child,
    );
  }
}

/// Shared press feedback (scale) + optional tap handling with keyboard / focus support.
///
/// Without [onTap] it is purely visual: it listens to raw pointer events, so an
/// `InkWell` / `GestureDetector` inside keeps working (ripple stays).
/// With [onTap] it also provides a button semantics node, focus ring and
/// Enter/Space activation.
class SxPressable extends StatefulWidget {
  const SxPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = false,
    this.enabled = true,
    this.semanticLabel,
    this.selected,
    this.semantics = true,
    this.excludeChildSemantics = false,
    this.onPressedChanged,
    this.focusRadius = SxRadius.md,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Pressed scale (0.97 buttons / chips, 0.985 cards).
  final double scale;
  final bool haptic;
  final bool enabled;
  final String? semanticLabel;
  final bool? selected;

  /// When false no semantics node is added (caller provides its own).
  final bool semantics;
  final bool excludeChildSemantics;
  final ValueChanged<bool>? onPressedChanged;
  final double focusRadius;
  final HitTestBehavior behavior;

  @override
  State<SxPressable> createState() => _SxPressableState();
}

class _SxPressableState extends State<SxPressable> {
  bool _down = false;
  bool _focused = false;
  Offset? _origin;

  bool get _active => widget.enabled;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    widget.onPressedChanged?.call(v);
  }

  void _activate() {
    if (!widget.enabled) return;
    if (widget.haptic) sxHaptic();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final reduced = SxMotion.reduced(context);
    Widget w = AnimatedScale(
      scale: (_down && _active && !reduced) ? widget.scale : 1,
      duration: SxMotion.of(context, SxMotion.micro),
      curve: SxMotion.enter,
      child: widget.child,
    );
    if (_focused && widget.enabled) {
      w = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.focusRadius),
          border: Border.all(color: c.primary, width: 2),
        ),
        child: w,
      );
    }
    // A disabled pressable still reports button semantics (enabled: false).
    final interactive = widget.onTap != null || widget.onLongPress != null || !widget.enabled;
    if (interactive) {
      w = GestureDetector(
        behavior: widget.behavior,
        onTap: widget.enabled && widget.onTap != null ? _activate : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        child: w,
      );
      w = FocusableActionDetector(
        enabled: widget.enabled,
        mouseCursor: widget.enabled
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: w,
      );
    }
    w = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        if (!widget.enabled) return;
        _origin = e.position;
        _set(true);
        if (widget.haptic && !interactive) sxHaptic();
      },
      onPointerMove: (e) {
        if (_down && _origin != null && (e.position - _origin!).distance > 18) {
          _set(false);
        }
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: w,
    );
    if (interactive && widget.semantics) {
      w = Semantics(
        container: true,
        button: true,
        enabled: widget.enabled,
        selected: widget.selected,
        label: widget.semanticLabel,
        excludeSemantics: widget.excludeChildSemantics,
        onTap: widget.enabled ? widget.onTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        child: w,
      );
    }
    return w;
  }
}

/// Animates a number to [value]: from 0 on first build (when [fromZero]), from
/// the previous value afterwards. Under reduced motion shows the value at once.
class SxCountUp extends StatelessWidget {
  const SxCountUp({
    super.key,
    required this.value,
    this.formatter,
    this.style,
    this.duration = SxMotion.emphasis,
    this.delay = Duration.zero,
    this.fromZero = true,
    this.textAlign,
    this.maxLines = 1,
  });

  final double value;
  final String Function(double)? formatter;
  final TextStyle? style;
  final Duration duration;
  final Duration delay;
  final bool fromZero;
  final TextAlign? textAlign;
  final int? maxLines;

  String _fmt(double v) =>
      formatter != null ? formatter!(v) : v.round().toString();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _fmt(value),
      excludeSemantics: true,
      child: SxGrow(
        value: value,
        duration: duration,
        delay: delay,
        from: fromZero ? 0 : null,
        builder: (_, v) => Text(
          _fmt(v),
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Entry/update tween driver for bars, rings and numbers.
/// First build animates `from` (default 0) -> [value] after [delay]; later value
/// changes animate from the displayed value. No animation under reduced motion.
class SxGrow extends StatefulWidget {
  const SxGrow({
    super.key,
    required this.value,
    required this.builder,
    this.duration = SxMotion.standard,
    this.delay = Duration.zero,
    this.curve = SxMotion.enter,
    this.from = 0,
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  /// Starting value on first build; null = start at [value] (no entry animation).
  final double? from;

  @override
  State<SxGrow> createState() => _SxGrowState();
}

class _SxGrowState extends State<SxGrow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  double _from = 0;
  double _to = 0;
  Curve _curve = Curves.linear;
  bool _started = false;

  double get _current =>
      _from + (_to - _from) * _curve.transform(_c.value.clamp(0.0, 1.0));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _to = widget.value;
    _from = widget.from ?? widget.value;
    if (SxMotion.reduced(context) || _from == _to) {
      _c.value = 1;
      return;
    }
    final total = widget.delay + widget.duration;
    _c.duration = total;
    final b = widget.delay.inMicroseconds / total.inMicroseconds;
    _curve = Interval(b, 1, curve: widget.curve);
    _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(SxGrow old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    final now = _current;
    if (SxMotion.reduced(context)) {
      _from = _to = widget.value;
      _c.value = 1;
      return;
    }
    _from = now;
    _to = widget.value;
    _curve = widget.curve;
    _c.duration = widget.duration;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (ctx, _) => widget.builder(ctx, _current),
  );
}

/// Cross-fade + 4 % scale between children (give the new child a different key).
class SxSwap extends StatelessWidget {
  const SxSwap({
    super.key,
    required this.child,
    this.duration = SxMotion.short,
    this.alignment = Alignment.center,
  });
  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final reduced = SxMotion.reduced(context);
    return AnimatedSwitcher(
      duration: SxMotion.of(context, duration),
      switchInCurve: SxMotion.enter,
      switchOutCurve: SxMotion.exit,
      layoutBuilder: (current, previous) =>
          Stack(alignment: alignment, children: [...previous, ?current]),
      transitionBuilder: (c, a) => reduced
          ? c
          : FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(a),
                child: c,
              ),
            ),
      child: child,
    );
  }
}

/// Direction-aware slide + fade between wizard steps, keyed by [step].
class SxStepTransition extends StatefulWidget {
  const SxStepTransition({
    super.key,
    required this.step,
    required this.child,
    this.duration = SxMotion.standard,
    this.distance = 0.12,
  });
  final int step;
  final Widget child;
  final Duration duration;

  /// Horizontal slide as a fraction of the width.
  final double distance;

  @override
  State<SxStepTransition> createState() => _SxStepTransitionState();
}

class _SxStepTransitionState extends State<SxStepTransition> {
  int _dir = 1;

  @override
  void didUpdateWidget(SxStepTransition old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) _dir = widget.step > old.step ? 1 : -1;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = SxMotion.reduced(context);
    final key = ValueKey<int>(widget.step);
    return AnimatedSwitcher(
      duration: SxMotion.of(context, widget.duration),
      switchInCurve: SxMotion.enter,
      switchOutCurve: SxMotion.exit,
      transitionBuilder: (c, a) {
        if (reduced) return c;
        final incoming = c.key == key;
        final sign = incoming ? _dir : -_dir;
        return FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(sign * widget.distance, 0),
              end: Offset.zero,
            ).animate(a),
            child: c,
          ),
        );
      },
      child: KeyedSubtree(key: key, child: widget.child),
    );
  }
}

/// One-shot emphasis scale pop when [active] turns true (and on mount if
/// [playOnMount]). Optional light haptic. Under reduced motion only the haptic fires.
class SxPop extends StatefulWidget {
  const SxPop({
    super.key,
    required this.child,
    this.active = true,
    this.playOnMount = true,
    this.haptic = false,
    this.peak = 1.15,
    this.duration = SxMotion.standard,
  });
  final Widget child;
  final bool active;
  final bool playOnMount;
  final bool haptic;
  final double peak;
  final Duration duration;

  @override
  State<SxPop> createState() => _SxPopState();
}

class _SxPopState extends State<SxPop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: widget.peak,
      ).chain(CurveTween(curve: SxMotion.enter)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: widget.peak,
        end: 1.0,
      ).chain(CurveTween(curve: SxMotion.overshoot)),
      weight: 60,
    ),
  ]).animate(_c);
  bool _mounted = false;

  void _play() {
    if (widget.haptic) sxHaptic();
    if (!SxMotion.reduced(context)) _c.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mounted) return;
    _mounted = true;
    if (widget.active && widget.playOnMount) _play();
  }

  @override
  void didUpdateWidget(SxPop old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _play();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
