import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

/// Stat tile whose headline number counts up on first build (and on change).
/// Same layout as [StatTile]; [value] is formatted by [format] on every frame.
class CountStatTile extends StatelessWidget {
  const CountStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.format,
    this.unit,
    this.icon,
    this.accent = false,
    this.height = 112,
    this.caption,
    this.delay = Duration.zero,
  });
  final String label;
  final double value;
  final String Function(double) format;
  final String? unit;
  final IconData? icon;
  final bool accent;
  final double height;
  final String? caption;
  final Duration delay;

  @override
  Widget build(BuildContext context) => StatTile.number(
    label: label,
    value: value,
    formatter: format,
    unit: unit,
    icon: icon,
    accent: accent,
    height: height,
    caption: caption,
    delay: delay,
  );
}
