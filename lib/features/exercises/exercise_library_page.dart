import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'create_exercise_sheet.dart';
import 'exercise_widgets.dart';

enum _Mode { all, common, recent }

/// Searchable, filterable exercise catalog. With [pickMode] a tap pops the
/// chosen [Exercise] instead of opening details.
class ExerciseLibraryPage extends StatefulWidget {
  const ExerciseLibraryPage({super.key, this.pickMode = false});
  final bool pickMode;

  @override
  State<ExerciseLibraryPage> createState() => _ExerciseLibraryPageState();
}

class _ExerciseLibraryPageState extends State<ExerciseLibraryPage> {
  /// Exercises logged within this many days count as "Recent".
  static const int recentDays = 60;
  static const Duration searchDebounce = Duration(milliseconds: 150);

  final _searchField = TextEditingController();
  final _search = ExerciseSearch();
  Timer? _debounce;
  String _query = '';
  SectionMuscle? _muscle;

  /// Second-level filter: a [MuscleRegion] (Legs) or a detailed [Muscle] leaf.
  Object? _sub;
  Equipment? _equipment;
  _Mode _mode = _Mode.all;

  // Memoized derived data: the catalog has 400 exercises, so PRs are computed lazily per visible row and
  // only re-computed after the sessions/exercises actually change, never on unrelated rebuilds.
  final Map<String, StrengthPr?> _prCache = {};
  final Map<String, SectionMuscle> _sectionCache = {};
  final Map<SectionMuscle, List<Object>> _subsCache = {};
  Set<String>? _recentCache;
  List<Exercise>? _listCache;
  Object? _listKey;
  AppController? _watched;

  /// Number of PR computations done (exposed for tests).
  @visibleForTesting
  int prComputations = 0;

  void _invalidate() {
    _prCache.clear();
    _sectionCache.clear();
    _subsCache.clear();
    _recentCache = null;
    _listCache = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.app;
    if (!identical(app, _watched)) {
      _watched?.sessions.removeListener(_invalidate);
      _watched?.exercises.removeListener(_invalidate);
      _watched = app..sessions.addListener(_invalidate)..exercises.addListener(_invalidate);
      _invalidate();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _watched?.sessions.removeListener(_invalidate);
    _watched?.exercises.removeListener(_invalidate);
    _searchField.dispose();
    super.dispose();
  }

  StrengthPr? _prOf(Exercise e, List<WorkoutSession> sessions) => _prCache.putIfAbsent(e.id, () {
        prComputations++;
        return PrService.forExercise(e.id, sessions)[PrType.estimated1Rm];
      });

  SectionMuscle _sectionOf(Exercise e) =>
      _sectionCache[e.id] ??= SectionMuscle.of(MuscleProfiles.of(e).primaryRegion);

  Set<String> _recent(List<WorkoutSession> sessions) => _recentCache ??= () {
        final cutoff = DateTime.now().subtract(const Duration(days: recentDays));
        return {
          for (final s in sessions)
            if (!s.workoutDate.isBefore(cutoff))
              for (final l in s.exercises)
                if (l.doneSets.isNotEmpty) l.exerciseId,
        };
      }();

  bool _subMatches(Exercise e) {
    final sub = _sub;
    if (sub == null) return true;
    final targets = MuscleProfiles.of(e).targets;
    return sub is MuscleRegion
        ? targets.any((t) => t.region == sub)
        : targets.any((t) => t.muscle == sub);
  }

  List<Exercise> _filtered(List<Exercise> all, List<WorkoutSession> sessions) {
    final key = (_query, _muscle, _sub, _equipment, _mode);
    if (_listCache != null && _listKey == key) return _listCache!;
    _listKey = key;
    final recent = _mode == _Mode.recent ? _recent(sessions) : const <String>{};
    final base = all.where((e) {
      if (_muscle != null && _sectionOf(e) != _muscle) return false;
      if (_equipment != null && e.equipment != _equipment) return false;
      if (_mode == _Mode.common && !SplitCatalog.isCommon(e.id)) return false;
      if (_mode == _Mode.recent && !recent.contains(e.id)) return false;
      return _subMatches(e);
    });
    // search() returns relevance order for a query and alphabetical order for an empty one.
    return _listCache = _search.search(base, _query);
  }

  /// Second-level chips for the chosen section: the four leg regions, otherwise detailed leaves that have
  /// at least one exercise in the section.
  List<Object> _subs(List<Exercise> all) {
    final g = _muscle;
    if (g == null) return const [];
    return _subsCache[g] ??= () {
      final present = <Object>{};
      for (final e in all) {
        if (_sectionOf(e) != g) continue;
        for (final t in MuscleProfiles.of(e).targets) {
          if (g == SectionMuscle.legs) {
            present.add(t.region);
          } else if (t.muscle != null && g.regions.contains(t.region)) {
            present.add(t.muscle!);
          }
        }
      }
      if (g == SectionMuscle.legs) {
        return <Object>[for (final r in g.regions) if (present.contains(r)) r];
      }
      return <Object>[for (final m in Muscle.values) if (present.contains(m)) m];
    }();
  }

  static String _subLabel(Object o) => o is MuscleRegion ? o.label : (o as Muscle).label;

  int get _activeFilters =>
      (_muscle != null ? 1 : 0) + (_sub != null ? 1 : 0) + (_equipment != null ? 1 : 0) + (_mode != _Mode.all ? 1 : 0);

  void _setQuery(String v) {
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(searchDebounce, () {
      if (mounted) setState(() => _query = v);
    });
  }

  void _clearFilters({bool query = false}) => setState(() {
        _muscle = null;
        _sub = null;
        _equipment = null;
        _mode = _Mode.all;
        if (query) {
          _debounce?.cancel();
          _searchField.clear();
          _query = '';
        }
      });

  Future<void> _create() async {
    final q = _query.trim();
    final created = await showCreateExerciseSheet(
      context,
      initialMuscle: _muscle?.legacy ?? MuscleGroup.chest,
      initialRegion: _muscle?.regions.first,
      initialName: q,
    );
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
        final sessions = app.sessions.sessions;
        final list = _filtered(all, sessions);
        final unit = app.profile.profile.unit;
        final muscleLabels = ['All', ...SectionMuscle.values.map((g) => g.label)];
        final muscleIndex = _muscle == null ? 0 : SectionMuscle.values.indexOf(_muscle!) + 1;
        final subs = _subs(all);
        final subIndex = _sub == null ? 0 : subs.indexOf(_sub!) + 1;
        final eqLabels = ['All Equipment', ...Equipment.values.map((e) => e.label)];
        final eqIndex = _equipment == null ? 0 : Equipment.values.indexOf(_equipment!) + 1;
        final active = _activeFilters;
        final count = '${list.length} ${list.length == 1 ? 'exercise' : 'exercises'}';
        final q = _query.trim();

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
                        SxButton(label: 'Custom', icon: Icons.add, expanded: false, onPressed: _create),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(SxSpace.md, SxSpace.md, SxSpace.md, 0),
                    sliver: SliverToBoxAdapter(
                      child: TextField(
                        controller: _searchField,
                        onChanged: _setQuery,
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
                          suffixIcon: _searchField.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: Icon(Icons.close, color: c.textBody),
                                  onPressed: () {
                                    _debounce?.cancel();
                                    setState(() {
                                      _searchField.clear();
                                      _query = '';
                                    });
                                  }),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(SxRadius.md), borderSide: BorderSide(color: c.hairline)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(SxRadius.md), borderSide: BorderSide(color: c.hairline)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(SxRadius.md), borderSide: BorderSide(color: c.primary)),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: SxSpace.md)),
                  SliverToBoxAdapter(
                    child: SxChipRow(
                      labels: const ['All exercises', 'Common', 'Recent'],
                      selectedIndex: _mode.index,
                      onSelected: (i) => setState(() => _mode = _Mode.values[i]),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(SxSpace.md + 4, SxSpace.md, SxSpace.md, 8),
                      child: Row(children: [
                        Expanded(child: Text('TARGET MUSCLE', style: SxText.labelCaps.copyWith(color: c.textBody))),
                        Text('${SectionMuscle.values.length} zones', style: SxText.bodySm.copyWith(color: c.textBody)),
                      ]),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Semantics(
                      container: true,
                      label: 'Target muscle filter',
                      child: SxChipRow(
                        key: const ValueKey('muscleChips'),
                        labels: muscleLabels,
                        selectedIndex: muscleIndex,
                        onSelected: (i) => setState(() {
                          _muscle = i == 0 ? null : SectionMuscle.values[i - 1];
                          _sub = null;
                        }),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: AnimatedSize(
                      duration: SxMotion.of(context, SxMotion.short),
                      curve: SxMotion.enter,
                      alignment: Alignment.topCenter,
                      child: subs.length > 1
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SxSwap(
                                child: Semantics(
                                  key: ValueKey('sub_${_muscle!.name}'),
                                  container: true,
                                  label: 'Specific ${_muscle!.label.toLowerCase()} muscle filter',
                                  child: SxChipRow(
                                    key: const ValueKey('subMuscleChips'),
                                    labels: ['All ${_muscle!.label.toLowerCase()}', ...subs.map(_subLabel)],
                                    selectedIndex: subIndex < 0 ? 0 : subIndex,
                                    onSelected: (i) => setState(() => _sub = i == 0 ? null : subs[i - 1]),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: Semantics(
                      container: true,
                      label: 'Equipment filter',
                      child: SxChipRow(
                        key: const ValueKey('equipmentChips'),
                        labels: eqLabels,
                        selectedIndex: eqIndex,
                        onSelected: (i) => setState(() => _equipment = i == 0 ? null : Equipment.values[i - 1]),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(SxSpace.md + 4, 4, SxSpace.md, 4),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(children: [
                          Expanded(
                            child: Semantics(
                              liveRegion: true,
                              container: true,
                              child: Text(
                                active == 0 ? count : '$count · $active ${active == 1 ? 'filter' : 'filters'}',
                                key: const ValueKey('resultCount'),
                                style: SxText.labelCaps.copyWith(color: c.textBody),
                              ),
                            ),
                          ),
                          if (active > 0)
                            TextButton(
                              key: const ValueKey('clearFilters'),
                              style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: c.primary),
                              onPressed: _clearFilters,
                              child: const Text('Clear'),
                            ),
                        ]),
                      ),
                    ),
                  ),
                  if (list.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: EmptyState(
                          icon: Icons.search_off,
                          title: 'No exercises found',
                          message: q.isNotEmpty
                              ? 'Nothing matches "$q".'
                              : _mode == _Mode.recent
                                  ? 'Nothing logged in the last $recentDays days.'
                                  : 'Try a different muscle or equipment filter.',
                          actionLabel: q.isNotEmpty ? 'Create custom exercise "$q"' : 'Create custom exercise',
                          onAction: _create,
                          secondaryLabel: 'Clear filters',
                          onSecondary: () => _clearFilters(query: true),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(SxSpace.md, 0, SxSpace.md, SxSpace.lg),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => SxStagger(
                          index: i,
                          enabled: i < SxMotion.staggerCap,
                          child: _ExerciseRow(
                            exercise: list[i],
                            pr: _prOf(list[i], sessions),
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
                Text('1RM: ${Fmt.weight(pr!.value, unit)} ${Fmt.unit(unit)}', style: SxText.labelXs.copyWith(color: c.textBody)),
              ] else
                Text('NOT LOGGED YET', style: SxText.labelXs.copyWith(color: c.textMuted)),
              if (exercise.isCustom) const StatusPill('Custom'),
            ]),
          ]),
        ),
      ]),
    );
  }
}
