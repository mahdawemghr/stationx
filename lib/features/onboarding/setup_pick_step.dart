import 'package:flutter/material.dart';

import '../../core/theme/sx_motion.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'setup_widgets.dart';

/// Display order of the built-in presets (unknown ids, e.g. test fixtures, keep their order after these).
const _presetOrder = ['full_body', 'upper_lower', 'ppl', 'bro_split'];

List<SplitPreset> orderedPresets(List<SplitPreset> presets) {
  int rank(SplitPreset p) {
    final i = _presetOrder.indexOf(p.id);
    return i < 0 ? _presetOrder.length : i;
  }

  final indexed = [for (var i = 0; i < presets.length; i++) (i, presets[i])];
  indexed.sort((a, b) {
    final r = rank(a.$2).compareTo(rank(b.$2));
    return r != 0 ? r : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// Step 1: choose a preset split (then Quick start or Customize) or build a custom one.
class SetupPickStep extends StatefulWidget {
  const SetupPickStep({super.key, required this.presets, required this.onQuick, required this.onCustomize, required this.onCustom});
  final List<SplitPreset> presets;
  final ValueChanged<SplitPreset> onQuick;
  final ValueChanged<SplitPreset> onCustomize;
  final VoidCallback onCustom;

  @override
  State<SetupPickStep> createState() => _SetupPickStepState();
}

class _SetupPickStepState extends State<SetupPickStep> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SetupList(
      children: [
        Text('How do you train?', style: SxText.headlineLg.copyWith(color: c.textHigh)),
        Text('Pick a split. Quick start sets it up for you; you can still change everything later.',
            style: SxText.bodyMd.copyWith(color: c.textBody)),
        for (final p in orderedPresets(widget.presets))
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Card(
              title: p.name,
              blurb: p.blurb,
              days: p.days.map((d) => d.name).join(' / '),
              meta: p.suggestedDaysPerWeek,
              selected: _selected == p.id,
              onTap: () => setState(() => _selected = _selected == p.id ? null : p.id),
            ),
            AnimatedSize(
              duration: SxMotion.of(context, SxMotion.short),
              curve: SxMotion.enter,
              alignment: Alignment.topCenter,
              child: _selected == p.id
                  ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const SizedBox(height: 8),
                      SxButton(label: 'Quick start', icon: Icons.bolt, onPressed: () => widget.onQuick(p)),
                      const SizedBox(height: 8),
                      SxButton(label: 'Customize exercises', variant: SxButtonVariant.secondary, onPressed: () => widget.onCustomize(p)),
                    ])
                  : const SizedBox(width: double.infinity),
            ),
          ]),
        _Card(
          title: 'Custom',
          blurb: 'Name your days and choose the muscles for each.',
          days: '',
          meta: '',
          icon: Icons.tune,
          onTap: widget.onCustom,
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.blurb, required this.days, required this.meta, required this.onTap, this.icon = Icons.view_week_outlined, this.selected = false});
  final String title;
  final String blurb;
  final String days;
  final String meta;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      button: true,
      label: '$title. $blurb${meta.isEmpty ? '' : ' $meta'}',
      excludeSemantics: true,
      onTap: onTap,
      child: SxCard(
        onTap: onTap,
        borderColor: selected ? c.primary : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: c.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: SxText.headlineMd.copyWith(color: c.textHigh)),
                const SizedBox(height: 2),
                Text(blurb, style: SxText.bodyMd.copyWith(color: c.textBody)),
                if (days.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(days, style: SxText.bodySm.copyWith(color: c.textMuted)),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta, style: SxText.labelCaps.copyWith(color: c.primary)),
                ],
              ]),
            ),
            AnimatedRotation(
              turns: selected ? 0.25 : 0,
              duration: SxMotion.of(context, SxMotion.short),
              child: Icon(Icons.chevron_right, color: selected ? c.primary : c.textMuted),
            ),
          ]),
        ),
      ),
    );
  }
}
