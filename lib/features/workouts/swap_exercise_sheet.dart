import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'equipment_icons.dart';

/// Smart Swap bottom sheet. Alternatives are ranked by [SmartSwapService]
/// (primary muscle, movement pattern, secondary overlap, equipment) and the
/// match % shown is the computed score. Resolves to the chosen replacement, or
/// null when dismissed.
Future<Exercise?> showSwapExerciseSheet(
  BuildContext context, {
  required Exercise current,
  int sets = 3,
  String repRange = '8-12',
  String? slotLabel,
  Set<String> excludeIds = const {},
}) {
  final catalog = context.app.exercises.all;
  return showSxSheet<Exercise>(
    context,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.9,
      child: SwapExerciseBody(
        current: current,
        catalog: catalog,
        sets: sets,
        repRange: repRange,
        slotLabel: slotLabel,
        excludeIds: excludeIds,
        onClose: () => Navigator.pop(ctx),
        onReplace: (e) => Navigator.pop(ctx, e),
      ),
    ),
  );
}

enum _EquipFilter {
  cables('Cables', {Equipment.cable}),
  free('Free Weights', {Equipment.dumbbell, Equipment.barbell}),
  machines('Machines', {Equipment.machine}),
  bodyweight('Bodyweight', {Equipment.bodyweight});

  const _EquipFilter(this.label, this.equipment);
  final String label;
  final Set<Equipment> equipment;
}

/// Sheet content, exposed for widget tests.
class SwapExerciseBody extends StatefulWidget {
  const SwapExerciseBody({
    super.key,
    required this.current,
    required this.catalog,
    required this.sets,
    required this.repRange,
    required this.onClose,
    required this.onReplace,
    this.slotLabel,
    this.excludeIds = const {},
  });

  final Exercise current;
  final List<Exercise> catalog;
  final int sets;
  final String repRange;
  final String? slotLabel;
  final Set<String> excludeIds;
  final VoidCallback onClose;
  final ValueChanged<Exercise> onReplace;

  @override
  State<SwapExerciseBody> createState() => _SwapExerciseBodyState();
}

class _SwapExerciseBodyState extends State<SwapExerciseBody> {
  final Set<_EquipFilter> _filters = {};
  String? _selectedId;

  List<SwapCandidate> get _alts {
    final allowed = _filters.isEmpty ? null : {for (final f in _filters) ...f.equipment};
    return SmartSwapService.alternatives(
      current: widget.current,
      catalog: widget.catalog,
      allowedEquipment: allowed,
      excludeIds: widget.excludeIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final alts = _alts;
    // Keep the selection valid; default to the best match.
    final selected = alts.where((a) => a.exercise.id == _selectedId).firstOrNull ?? (alts.isEmpty ? null : alts.first);
    final cur = widget.current;
    final secondary = cur.secondaryMuscles.map((m) => m.label).join(', ');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(SxSpace.md, 4, SxSpace.md, SxSpace.sm),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md)),
                child: Icon(Icons.swap_horiz, color: c.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Swap Exercise', style: SxText.headlineMd.copyWith(color: c.textHigh)),
                    Text('Match mechanics & preserve strain', style: SxText.bodySm.copyWith(color: c.textBody)),
                  ],
                ),
              ),
              SxIconButton(icon: Icons.close, tooltip: 'Close', onPressed: widget.onClose),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(SxSpace.md, 0, SxSpace.md, SxSpace.md),
            children: [
              SxCard(
                color: c.surface2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const StatusPill('Current target', dot: true),
                        const SizedBox(width: 8),
                        if (widget.slotLabel != null)
                          Expanded(child: Text(widget.slotLabel!, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.metricSm.copyWith(color: c.textBody, fontSize: 12))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _EquipTile(cur.equipment, size: 56),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cur.name, style: SxText.headlineMd.copyWith(color: c.textHigh)),
                              Text(
                                'Primary: ${cur.primaryMuscle.label}${secondary.isEmpty ? '' : ' • Secondary: $secondary'}',
                                style: SxText.bodySm.copyWith(color: c.textBody),
                              ),
                              const SizedBox(height: 6),
                              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                                _MonoTag(cur.equipment.label),
                                Text('${widget.sets} sets • ${widget.repRange} reps', style: SxText.metricSm.copyWith(color: c.textBody, fontSize: 12)),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SxSpace.sm),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    SxChip(label: 'Target: ${cur.primaryMuscle.label}', selected: true, icon: Icons.check),
                    for (final f in _EquipFilter.values) ...[
                      const SizedBox(width: 8),
                      SxChip(
                        label: f.label,
                        icon: _filters.contains(f) ? Icons.check : null,
                        selected: _filters.contains(f),
                        onTap: () => setState(() => _filters.contains(f) ? _filters.remove(f) : _filters.add(f)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: SxSpace.sm),
              SxInset(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Icon(Icons.sync, size: 20, color: c.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Preserves workout order, target rep ranges, and historical volume calculation.',
                        style: SxText.bodySm.copyWith(color: c.textBody)),
                  ),
                ]),
              ),
              const SizedBox(height: SxSpace.md),
              SectionHeader('Recommended alternatives', trailingText: '${alts.length} available'),
              const SizedBox(height: SxSpace.sm),
              if (alts.isEmpty)
                const EmptyState(
                  icon: Icons.search_off,
                  title: 'No alternatives',
                  message: 'Nothing in your library matches this muscle with the selected equipment. Clear a filter to see more.',
                )
              else
                for (final a in alts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: SxSpace.sm),
                    child: _AltCard(
                      candidate: a,
                      selected: a.exercise.id == selected?.exercise.id,
                      onTap: () => setState(() => _selectedId = a.exercise.id),
                    ),
                  ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(color: c.surface3, border: Border(top: BorderSide(color: c.hairline))),
          padding: const EdgeInsets.fromLTRB(SxSpace.md, 10, SxSpace.md, SxSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Icon(Icons.info_outline, size: 16, color: c.primary),
                const SizedBox(width: 6),
                Expanded(child: Text('Replaces all ${widget.sets} set targets', maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textHigh))),
                if (selected != null)
                  Flexible(child: Text(selected.exercise.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.metricSm.copyWith(color: c.textBody, fontSize: 12))),
              ]),
              const SizedBox(height: 10),
              SxButton(
                label: 'Replace exercise',
                trailingIcon: Icons.arrow_forward,
                onPressed: selected == null ? null : () => widget.onReplace(selected.exercise),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AltCard extends StatelessWidget {
  const _AltCard({required this.candidate, required this.selected, required this.onTap});
  final SwapCandidate candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final e = candidate.exercise;
    return Semantics(
      button: true,
      selected: selected,
      label: '${e.name}, ${candidate.matchPercent} percent match',
      child: SxCard(
        onTap: onTap,
        color: selected ? c.surface2 : c.surface1,
        borderColor: selected ? c.primaryBorder : c.hairline,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EquipTile(e.equipment),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name, style: SxText.headlineSm.copyWith(color: c.textHigh)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    StatusPill('${candidate.matchPercent}% match', icon: Icons.verified_outlined, color: selected ? c.primary : c.textBody),
                    _MonoTag(e.equipment.label),
                  ]),
                  const SizedBox(height: 6),
                  Text(candidate.reason, style: SxText.bodySm.copyWith(color: c.textBody)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: SxMotion.fast,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? c.primary : c.surface3,
                shape: BoxShape.circle,
              ),
              child: selected ? const Icon(Icons.check, size: 18, color: Color(0xFF101214)) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipTile extends StatelessWidget {
  const _EquipTile(this.equipment, {this.size = 48});
  final Equipment equipment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(SxRadius.md), border: Border.all(color: c.hairline)),
      child: Icon(equipmentIcon(equipment), color: c.primary, size: size * 0.5),
    );
  }
}

class _MonoTag extends StatelessWidget {
  const _MonoTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(SxRadius.sm)),
      child: Text(text, style: SxText.metricSm.copyWith(color: c.textBody, fontSize: 11)),
    );
  }
}
