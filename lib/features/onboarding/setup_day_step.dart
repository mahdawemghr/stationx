import 'package:flutter/material.dart';

import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import '../exercises/create_exercise_sheet.dart';
import 'setup_catalog.dart';
import 'setup_coverage.dart';
import 'setup_widgets.dart';

/// Step 2 (one page per day): per muscle, sub-sections of exercises to tick. A pinned bar shows how much
/// each muscle of the day is targeted so far; search, equipment and "ticked only" filters narrow the lists,
/// and a search also finds exercises of muscles that are not (yet) part of this day.
class SetupDayStep extends StatefulWidget {
  const SetupDayStep({
    super.key,
    required this.day,
    required this.all,
    required this.catalog,
    required this.profile,
    required this.onChanged,
  });
  final SplitDayPlan day;
  final List<Exercise> all;
  final SetupCatalog catalog;
  final UserProfile profile;
  final ValueChanged<SplitDayPlan> onChanged;

  @override
  State<SetupDayStep> createState() => _SetupDayStepState();
}

class _SetupDayStepState extends State<SetupDayStep> {
  SplitDayPlan get day => widget.day;
  List<Exercise> get all => widget.all;
  SetupCatalog get catalog => widget.catalog;
  UserProfile get profile => widget.profile;
  ValueChanged<SplitDayPlan> get onChanged => widget.onChanged;

  final _search = TextEditingController();
  String _query = '';
  Equipment? _equipment;
  bool _tickedOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Exercise e) {
    if (_equipment != null && e.equipment != _equipment) return false;
    if (_tickedOnly && _indexOf(e.id) < 0) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return e.name.toLowerCase().contains(q) ||
        e.equipment.label.toLowerCase().contains(q) ||
        e.primaryMuscle.label.toLowerCase().contains(q) ||
        e.secondaryMuscles.any((m) => m.label.toLowerCase().contains(q));
  }

  int get _filters =>
      (_equipment != null ? 1 : 0) +
      (_tickedOnly ? 1 : 0) +
      (_query.trim().isEmpty ? 0 : 1);

  int _indexOf(String id) =>
      day.exercises.indexWhere((e) => e.exerciseId == id);

  RoutineExercise _fresh(String id) => RoutineExercise(
    exerciseId: id,
    sets: profile.defaultSets,
    repMin: profile.defaultRepMin,
    repMax: profile.defaultRepMax,
  );

  /// Inserts at the canonical spot (end of its sub-area), then re-arranges in the day's muscle order, so
  /// the list is always what [ScheduleBuilder.save] will write.
  List<RoutineExercise> _with(
    List<RoutineExercise> list,
    RoutineExercise re, [
    List<SectionMuscle>? order,
  ]) {
    final out = [...list]
      ..insert(WorkoutSections.insertionIndex(list, re, all), re);
    return WorkoutSections.arrange(
      out,
      all,
      muscleOrder: order ?? day.sectionMuscles,
    );
  }

  void _toggle(Exercise e) {
    final i = _indexOf(e.id);
    if (i >= 0) {
      onChanged(day.copyWith(exercises: [...day.exercises]..removeAt(i)));
    } else {
      final sm = sectionOf(e);
      if (day.sectionMuscles.contains(sm)) {
        onChanged(day.copyWith(exercises: _with(day.exercises, _fresh(e.id))));
      } else {
        // Picked through search from a muscle this day does not train yet: the day gains that muscle.
        final muscles = [...day.sectionMuscles, sm];
        onChanged(
          day.copyWith(
            sectionMuscles: muscles,
            exercises: _with(day.exercises, _fresh(e.id), muscles),
          ),
        );
      }
    }
  }

  void _update(String id, RoutineExercise Function(RoutineExercise) f) {
    onChanged(
      day.copyWith(
        exercises: [
          for (final e in day.exercises) e.exerciseId == id ? f(e) : e,
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, SectionMuscle m) async {
    final ex = await showCreateExerciseSheet(
      context,
      initialMuscle: m.legacy,
      initialRegion: m.regions.first,
    );
    if (ex == null) return;
    final sm = sectionOf(ex);
    final muscles = day.sectionMuscles.contains(sm)
        ? day.sectionMuscles
        : [...day.sectionMuscles, sm];
    onChanged(
      day.copyWith(
        sectionMuscles: muscles,
        exercises: _with(day.exercises, _fresh(ex.id), muscles),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final byId = {for (final e in all) e.id: e};
    final shown = <String>{};
    final children = <Widget>[
      Text(day.name, style: SxText.headlineLg.copyWith(color: c.textHigh)),
      Text(
        '${day.exercises.length} exercises · ${day.totalSets} sets · ~${day.estimatedMinutes} min',
        style: SxText.bodySm.copyWith(color: c.textBody),
      ),
      Text(
        'Main exercises first, then the separate parts of each muscle. Small tags show the other muscles an exercise also works.',
        style: SxText.bodySm.copyWith(color: c.textMuted),
      ),
    ];
    children.add(_filterBar(context));
    if (day.sectionMuscles.isEmpty) {
      children.add(
        Text(
          'No muscles on this day. Go back to choose some.',
          style: SxText.bodyMd.copyWith(color: c.textBody),
        ),
      );
    }
    final muscles = day.sectionMuscles;
    final showHeaders = muscles.length >= 2;
    for (final m in muscles) {
      if (showHeaders) {
        children.add(
          Semantics(
            header: true,
            child: Text(
              m.label,
              style: SxText.headlineMd.copyWith(color: c.textHigh),
            ),
          ),
        );
      }
      final groups = [
        for (final g in catalog.groupedSection(m, all))
          (
            label: g.label,
            hint: g.hint,
            exercises: [
              for (final e in g.exercises)
                if (_matches(e)) e,
            ],
          ),
      ].where((g) => g.exercises.isNotEmpty).toList();
      if (groups.isEmpty && _filters == 0) {
        children.add(
          Text(
            'No exercises listed yet. Add your own.',
            style: SxText.bodySm.copyWith(color: c.textMuted),
          ),
        );
      }
      for (final g in groups) {
        if (g.label != null) {
          children.add(SetupSubHeader(g.label!, hint: g.hint));
        }
        for (final e in g.exercises) {
          shown.add(e.id);
          children.add(_tile(context, e));
        }
      }
      children.add(
        SxButton(
          label: 'Add ${m.label.toLowerCase()} exercise',
          icon: Icons.add,
          variant: SxButtonVariant.secondary,
          onPressed: () => _add(context, m),
        ),
      );
    }
    final extra = [
      for (final re in day.exercises)
        if (!shown.contains(re.exerciseId) &&
            byId[re.exerciseId] != null &&
            _matches(byId[re.exerciseId]!))
          byId[re.exerciseId]!,
    ];
    if (extra.isNotEmpty) {
      children.add(const SetupSubHeader('Also in this day'));
      for (final e in extra) {
        children.add(_tile(context, e));
      }
    }
    // A search also reaches the rest of the library (muscles this day does not train yet).
    if (_query.trim().isNotEmpty) {
      final inDay = {for (final m in muscles) m};
      final more = [
        for (final e in all)
          if (!shown.contains(e.id) &&
              !extra.any((x) => x.id == e.id) &&
              !inDay.contains(sectionOf(e)) &&
              _matches(e))
            e,
      ].take(25).toList();
      if (more.isNotEmpty) {
        children.add(
          const SetupSubHeader(
            'More results',
            hint: 'Other muscles. Ticking one adds that muscle to this day.',
          ),
        );
        for (final e in more) {
          children.add(_tile(context, e));
        }
      }
    }
    if (_filters > 0 && !children.any((w) => w is SxCard)) {
      children.add(
        Text(
          'Nothing matches. Clear the search or filters.',
          style: SxText.bodyMd.copyWith(color: c.textBody),
        ),
      );
    }
    return Column(
      children: [
        SetupDayCoverageBar(day: day, catalog: all),
        Expanded(child: SetupList(children: children)),
      ],
    );
  }

  Widget _filterBar(BuildContext context) {
    final c = context.sx;
    final used = {for (final e in all) e.equipment}..removeWhere((e) => false);
    final equipment = [
      for (final e in Equipment.values)
        if (used.contains(e)) e,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          cursorColor: c.primary,
          style: SxText.bodyLg.copyWith(color: c.textHigh),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: c.surface1,
            hintText: 'Search exercise, muscle or equipment…',
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
                    }),
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SxRadius.md),
              borderSide: BorderSide(color: c.hairline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SxRadius.md),
              borderSide: BorderSide(color: c.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SxRadius.md),
              borderSide: BorderSide(color: c.primary),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SxChip(
                label: 'Ticked only',
                selected: _tickedOnly,
                icon: _tickedOnly ? Icons.check : null,
                onTap: () => setState(() => _tickedOnly = !_tickedOnly),
              ),
              for (final e in equipment) ...[
                const SizedBox(width: 8),
                SxChip(
                  label: e.label,
                  selected: _equipment == e,
                  onTap: () =>
                      setState(() => _equipment = _equipment == e ? null : e),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, Exercise e) {
    final c = context.sx;
    final i = _indexOf(e.id);
    final ticked = i >= 0;
    final re = ticked ? day.exercises[i] : null;
    final reason = catalog.reasonFor(e.id);
    return SxCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      borderColor: ticked ? c.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            checked: ticked,
            label:
                '${e.name}, ${e.equipment.label}${e.secondaryMuscles.isEmpty ? '' : ', also works ${e.secondaryMuscles.take(4).map((m) => m.label).join(', ')}'}${reason == null ? '' : ', $reason'}',
            excludeSemantics: true,
            onTap: () => _toggle(e),
            child: InkWell(
              onTap: () => _toggle(e),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    // Visual only: the row's InkWell/Semantics above own the tap and the checked state.
                    ExcludeSemantics(
                      child: IgnorePointer(
                        child: SxCheck(
                          checked: ticked,
                          onChanged: null,
                          size: 24,
                          haptic: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: SxText.bodyLg.copyWith(color: c.textHigh),
                            ),
                            Text(
                              e.equipment.label,
                              style: SxText.bodySm.copyWith(color: c.textMuted),
                            ),
                            if (e.secondaryMuscles.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    for (final m in e.secondaryMuscles.take(4))
                                      _MuscleTag(m.label),
                                  ],
                                ),
                              ),
                            if (reason != null)
                              Text(
                                reason,
                                style: SxText.bodySm.copyWith(
                                  color: c.textBody,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: SxMotion.of(context, SxMotion.short),
            curve: SxMotion.enter,
            alignment: Alignment.topCenter,
            child: re == null
                ? const SizedBox(width: double.infinity)
                : Wrap(
                    spacing: 8,
                    children: [
                      SetupStepper(
                        label: 'Sets',
                        value: '${re.sets}',
                        onDec: re.sets > 1
                            ? () => _update(
                                e.id,
                                (r) => r.copyWith(sets: r.sets - 1),
                              )
                            : null,
                        onInc: re.sets < 10
                            ? () => _update(
                                e.id,
                                (r) => r.copyWith(sets: r.sets + 1),
                              )
                            : null,
                      ),
                      SetupStepper(
                        label: 'Reps',
                        value: '${re.repMin}–${re.repMax}',
                        onDec: re.repMin > 1
                            ? () => _update(
                                e.id,
                                (r) => r.copyWith(
                                  repMin: r.repMin - 1,
                                  repMax: r.repMax - 1,
                                ),
                              )
                            : null,
                        onInc: re.repMax < 50
                            ? () => _update(
                                e.id,
                                (r) => r.copyWith(
                                  repMin: r.repMin + 1,
                                  repMax: r.repMax + 1,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MuscleTag extends StatelessWidget {
  const _MuscleTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(SxRadius.sm),
        border: Border.all(color: c.hairline),
      ),
      child: Text(label, style: SxText.bodySm.copyWith(color: c.textBody)),
    );
  }
}
