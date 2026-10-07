import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'create_exercise_sheet.dart';
import 'exercise_widgets.dart';
import '../../app/nav.dart';

/// Searchable, filterable exercise catalog. With [pickMode] a tap pops the
/// chosen [Exercise] instead of opening details.
class ExerciseLibraryPage extends StatefulWidget {
  const ExerciseLibraryPage({super.key, this.pickMode = false});
  final bool pickMode;

  @override
  State<ExerciseLibraryPage> createState() => _ExerciseLibraryPageState();
}

class _ExerciseLibraryPageState extends State<ExerciseLibraryPage> {
  final _search = TextEditingController();
  String _query = '';
  MuscleGroup? _muscle;
  Equipment? _equipment;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Exercise e) {
    if (_muscle != null && e.primaryMuscle != _muscle && !e.secondaryMuscles.contains(_muscle)) return false;
    if (_equipment != null && e.equipment != _equipment) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return e.name.toLowerCase().contains(q) ||
        e.primaryMuscle.label.toLowerCase().contains(q) ||
        e.secondaryMuscles.any((m) => m.label.toLowerCase().contains(q)) ||
        e.equipment.label.toLowerCase().contains(q);
  }

  Future<void> _create() async {
    final created = await showCreateExerciseSheet(context);
    if (created != null && mounted) showSxSnack(context, '${created.name} added');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.exercises, app.sessions, app.profile]),
      builder: (context, _) {
        final all = app.exercises.all;
        final list = all.where(_matches).toList()..sort((a, b) => a.name.compareTo(b.name));
        final sessions = app.sessions.sessions;
        final unit = app.profile.profile.unit;
        final prs = <String, StrengthPr>{};
        for (final e in list) {
          final pr = PrService.forExercise(e.id, sessions)[PrType.estimated1Rm];
          if (pr != null) prs[e.id] = pr;
        }
        const muscleLabels = ['All', ...[
          'Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps', 'Legs', 'Core'
        ]];
        final muscleIndex = _muscle == null ? 0 : MuscleGroup.values.indexOf(_muscle!) + 1;
        final eqLabels = ['All Equipment', ...Equipment.values.map((e) => e.label)];
        final eqIndex = _equipment == null ? 0 : Equipment.values.indexOf(_equipment!) + 1;

        return Scaffold(
          backgroundColor: c.canvas,
          appBar: SxTopBar(title: widget.pickMode ? 'Select Exercise' : 'Exercise Library', showLogo: true),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SxSpace.maxContentWidth),
              child: CustomScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(SxSpace.md, SxSpace.md, SxSpace.md, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('EXERCISES', style: SxText.headlineLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.full)),
                                child: Text('${all.length}', style: SxText.metricSm.copyWith(color: c.primary)),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SxButton(label: 'Custom', icon: Icons.add, expanded: false, height: 44, onPressed: _create),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(SxSpace.md, SxSpace.md, SxSpace.md, 0),
                    sliver: SliverToBoxAdapter(
                      child: TextField(
                        controller: _search,
                        onChanged: (v) => setState(() => _query = v),
                        cursorColor: c.primary,
                        style: SxText.bodyLg.copyWith(color: c.textHigh),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: c.surface1,
                          hintText: 'Search exercise or target muscle…',
                          hintStyle: SxText.bodyMd.copyWith(color: c.textMuted),
                          prefixIcon: Icon(Icons.search, color: c.textBody),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: Icon(Icons.close, color: c.textBody),
                                  onPressed: () => setState(() {
                                    _search.clear();
                                    _query = '';
                                  })),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(SxRadius.md), borderSide: BorderSide(color: c.hairline)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(SxRadius.md), borderSide: BorderSide(color: c.hairline)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(SxRadius.md), borderSide: BorderSide(color: c.primary)),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(SxSpace.md + 4, SxSpace.md, SxSpace.md, 8),
                      child: Row(children: [
                        Expanded(child: Text('TARGET MUSCLE', style: SxText.labelCaps.copyWith(color: c.textBody))),
                        Text('${MuscleGroup.values.length} zones', style: SxText.bodySm.copyWith(color: c.textBody)),
                      ]),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SxChipRow(
                      labels: muscleLabels,
                      selectedIndex: muscleIndex,
                      onSelected: (i) => setState(() => _muscle = i == 0 ? null : MuscleGroup.values[i - 1]),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: SxChipRow(
                      labels: eqLabels,
                      selectedIndex: eqIndex,
                      onSelected: (i) => setState(() => _equipment = i == 0 ? null : Equipment.values[i - 1]),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: SxSpace.md)),
                  if (list.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: EmptyState(
                          icon: Icons.search_off,
                          title: 'No exercises found',
                          message: _query.isEmpty ? 'Try a different muscle or equipment filter.' : 'Nothing matches "$_query".',
                          actionLabel: 'Create custom exercise',
                          onAction: _create,
                          secondaryLabel: 'Clear filters',
                          onSecondary: () => setState(() {
                            _search.clear();
                            _query = '';
                            _muscle = null;
                            _equipment = null;
                          }),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(SxSpace.md, 0, SxSpace.md, SxSpace.lg),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ExerciseRow(
                          exercise: list[i],
                          pr: prs[list[i].id],
                          unit: unit,
                          pickMode: widget.pickMode,
                          onTap: () {
                            if (widget.pickMode) {
                              Navigator.of(context).pop(list[i]);
                            } else {
                              AppNav.exerciseDetails(context, list[i].id);
                            }
                          },
                          onHistory: () => AppNav.exerciseHistory(context, list[i].id),
                        ),
                      ),
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

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.pr, required this.unit, required this.pickMode, required this.onTap, required this.onHistory});
  final Exercise exercise;
  final StrengthPr? pr;
  final WeightUnit unit;
  final bool pickMode;
  final VoidCallback onTap;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ExerciseThumb(exercise),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(exercise.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SxText.headlineSm.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
              ),
              if (!pickMode)
                PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: Icon(Icons.more_vert, color: c.textBody, size: 20),
                  color: c.surface3,
                  onSelected: (v) => v == 'history' ? onHistory() : onTap(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'details', child: Text('Details')),
                    PopupMenuItem(value: 'history', child: Text('History & charts')),
                  ],
                ),
            ]),
            const SizedBox(height: 2),
            Text(muscleLine(exercise), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              if (pr != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.base)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.workspace_premium, size: 14, color: c.primary),
                    const SizedBox(width: 6),
                    Text('PR ${Fmt.setLabel(pr!.weightKg, pr!.reps, unit)}', style: SxText.metricSm.copyWith(color: c.primary, fontSize: 12)),
                  ]),
                ),
                Text('1RM: ${Fmt.weight(pr!.value, unit)} ${Fmt.unit(unit)}', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
              ] else
                Text('NOT LOGGED YET', style: SxText.labelCaps.copyWith(color: c.textMuted, fontSize: 10)),
              if (exercise.isCustom) const StatusPill('Custom'),
            ]),
          ]),
        ),
      ]),
    );
  }
}
