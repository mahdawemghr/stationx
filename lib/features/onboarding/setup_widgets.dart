import 'package:flutter/material.dart';

import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';

/// "−  value  +" control with 48dp touch targets.
class SetupStepper extends StatelessWidget {
  const SetupStepper({super.key, required this.label, required this.value, required this.onDec, required this.onInc});
  final String label;
  final String value;
  final VoidCallback? onDec;
  final VoidCallback? onInc;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      container: true,
      label: '$label $value',
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        ExcludeSemantics(child: Text(label.toUpperCase(), style: SxText.labelXs.copyWith(color: c.textBody))),
        IconButton(
          tooltip: 'Decrease $label',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(Icons.remove, color: onDec == null ? c.textMuted : c.textHigh),
          onPressed: onDec,
        ),
        ExcludeSemantics(child: Text(value, style: SxText.metricSm.copyWith(color: c.primary))),
        IconButton(
          tooltip: 'Increase $label',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(Icons.add, color: onInc == null ? c.textMuted : c.textHigh),
          onPressed: onInc,
        ),
      ]),
    );
  }
}

/// Small caps label + optional hint line used for sub-section headings.
class SetupSubHeader extends StatelessWidget {
  const SetupSubHeader(this.label, {super.key, this.hint = ''});
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Padding(
      padding: const EdgeInsets.only(top: SxSpace.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: Text(label.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.primary))),
        if (hint.isNotEmpty) Text(hint, style: SxText.bodySm.copyWith(color: c.textMuted)),
      ]),
    );
  }
}

/// Scrolling column used as each step's body (the flow owns the scaffold).
class SetupList extends StatelessWidget {
  const SetupList({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(SxSpace.screenMargin, SxSpace.sm, SxSpace.screenMargin, SxSpace.lg),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(height: SxSpace.sm),
        itemBuilder: (_, i) => children[i],
      );
}
