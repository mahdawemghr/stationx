import 'dart:async';

import 'package:flutter/material.dart';

/// Rebuilds only [builder]'s subtree once per second. Used by the cardio block's own stopwatch (the
/// strength logger has no workout or rest timer).
class SecondTicker extends StatefulWidget {
  const SecondTicker({
    super.key,
    required this.builder,
    this.active = true,
    this.onTick,
  });
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
