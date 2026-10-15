import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/health/health_gateway.dart';
import '../../domain/domain.dart';
import 'health_actions.dart';

enum _Load { loading, ready, off, unsupported, failed }

/// Preview, then import, workouts (cardio and strength) other apps saved in Health Connect / Apple Health.
class HealthImportPage extends StatefulWidget {
  const HealthImportPage({super.key});

  @override
  State<HealthImportPage> createState() => _HealthImportPageState();
}

class _HealthImportPageState extends State<HealthImportPage> {
  static const _periods = [30, 90, 365, HealthImport.maxDays];
  int _days = 30;
  _Load _state = _Load.loading;
  HealthImportPlan? _plan;
  HealthHistoryAccess _history = HealthHistoryAccess.notSupported;
  bool _importing = false;
  bool _started = false;
  int _token = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final token = ++_token;
    final app = context.app;
    final sync = app.healthSync;
    setState(() => _state = _Load.loading);
    _Load next;
    HealthImportPlan? plan;
    try {
      final a = await sync.availability();
      if (a != GatewayAvailability.available) {
        next = _Load.unsupported;
      } else if (!sync.isEnabled(HealthFeature.importWorkouts)) {
        next = _Load.off;
      } else {
        _history = await sync.historyAccess();
        plan = await sync.planImport(
          app.cardio,
          days: _days,
          sessions: app.sessions,
        );
        next = plan == null ? _Load.failed : _Load.ready;
      }
    } catch (_) {
      next = _Load.failed;
    }
    if (!mounted || token != _token) return;
    setState(() {
      _state = next;
      _plan = plan;
    });
  }

  Future<void> _grantHistory() async {
    final ok = await context.app.healthSync.requestHistoryAccess();
    if (!mounted) return;
    if (!ok) {
      showSxSnack(
        context,
        'Older data was not allowed. You can allow it in Health Connect › App permissions › StationX.',
        icon: Icons.info_outline,
      );
    }
    _load();
  }

  Future<void> _import() async {
    final plan = _plan;
    if (plan == null || _importing) return;
    final app = context.app;
    setState(() => _importing = true);
    int added = 0;
    try {
      added = await app.healthSync.applyImport(
        plan,
        app.cardio,
        sessions: app.sessions,
      );
    } catch (_) {
      if (mounted) {
        showSxSnack(
          context,
          'Could not import right now. Try again; anything already imported is skipped.',
          icon: Icons.info_outline,
        );
      }
      if (mounted) setState(() => _importing = false);
      return;
    }
    if (!mounted) return;
    showSxSnack(
      context,
      added == 1 ? 'Imported 1 workout' : 'Imported $added workouts',
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final plan = _plan;
    final count = plan?.count ?? 0;
    final canImport = _state == _Load.ready && count > 0;
    return SxScaffold(
      topBar: const SxTopBar(title: 'Import workouts', subtitle: 'HEALTH'),
      bottom: canImport
          ? SxButton(
              label: 'Import $count ${count == 1 ? 'workout' : 'workouts'}',
              icon: Icons.download_outlined,
              loading: _importing,
              onPressed: _importing ? null : _import,
            )
          : null,
      gap: SxSpace.md,
      children: [
        SxStagger(
          index: 0,
          child: SxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERIOD',
                  style: SxText.labelCaps.copyWith(color: c.textBody),
                ),
                const SizedBox(height: 8),
                SxSegmented(
                  labels: const ['30 days', '90 days', '1 year', 'All'],
                  index: _periods.indexOf(_days).clamp(0, _periods.length - 1),
                  onChanged: (i) {
                    if (_importing) return;
                    setState(() => _days = _periods[i]);
                    _load();
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _history == HealthHistoryAccess.needsGrant
                      ? 'Android only shares about the last 30 days until you allow older data. Importing again never duplicates workouts.'
                      : 'Importing again never duplicates workouts.',
                  style: SxText.bodySm.copyWith(color: c.textBody),
                ),
                if (_history == HealthHistoryAccess.needsGrant) ...[
                  const SizedBox(height: 8),
                  SxButton(
                    label: 'Allow older data',
                    icon: Icons.history,
                    variant: SxButtonVariant.secondary,
                    height: 44,
                    onPressed: _importing ? null : _grantHistory,
                  ),
                ],
              ],
            ),
          ),
        ),
        SxSwap(
          alignment: Alignment.topCenter,
          child: KeyedSubtree(
            key: ValueKey('$_state-${plan?.count}'),
            child: _body(context),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final c = context.sx;
    final sync = context.app.healthSync;
    final name = sync.provider == HealthProvider.none
        ? 'your health app'
        : sync.provider.label;
    switch (_state) {
      case _Load.loading:
        return Semantics(
          liveRegion: true,
          label: 'Looking for workouts',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: SxSpace.xl),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SxSpinner(
                    size: 28,
                    semanticLabel: 'Looking for workouts',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Looking for workouts in $name...',
                    style: SxText.bodyMd.copyWith(color: c.textBody),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      case _Load.unsupported:
        return EmptyState(
          icon: Icons.block,
          title: 'Not available',
          message:
              '$name is not available on this device, so there is nothing to import. StationX keeps working without it.',
        );
      case _Load.off:
        return EmptyState(
          icon: Icons.toggle_off_outlined,
          title: 'Import is off',
          message:
              'Turn on "Import workouts from other apps" in Health & workouts first.',
          actionLabel: 'Turn on',
          onAction: () async {
            final on = await enableHealthFeature(
              context,
              HealthFeature.importWorkouts,
            );
            if (on && mounted) _load();
          },
        );
      case _Load.failed:
        return EmptyState(
          icon: Icons.sync_problem_outlined,
          title: 'Could not read workouts',
          message:
              'StationX could not read from $name. Check that access is allowed, then try again. Open Health Connect › App permissions › StationX.',
          actionLabel: 'Try again',
          onAction: _load,
        );
      case _Load.ready:
        final plan = _plan!;
        if (plan.isEmpty) {
          return Column(
            children: [
              EmptyState(
                icon: Icons.check_circle_outline,
                title: 'Nothing new to import',
                message: _days >= HealthImport.maxDays
                    ? 'No new workouts from other apps were found.'
                    : 'No new workouts from other apps were found in the last $_days days.',
                actionLabel: 'Check again',
                onAction: _load,
              ),
              if (context.app.healthSync.provider ==
                  HealthProvider.healthConnect)
                const _OlderWorkoutsNote(),
              _Counts(plan: plan),
            ],
          );
        }
        return _Preview(plan: plan);
    }
  }
}

/// Why old Samsung workouts may be missing, and the way to keep them. Not something StationX can
/// fix: Samsung Health only writes workouts recorded after sharing was switched on.
class _OlderWorkoutsNote extends StatelessWidget {
  const _OlderWorkoutsNote();

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Padding(
      padding: const EdgeInsets.only(bottom: SxSpace.md),
      child: SxCard(
        child: Text(
          'Missing older workouts? Samsung Health only shares workouts recorded after sharing was switched on and does not copy older ones into Health Connect, so StationX cannot see them. '
          'Check Health Connect › Data and access › Exercise to see which apps provide workouts. '
          'Your older Samsung Health workouts stay in Samsung Health (Settings › Download personal data).',
          style: SxText.bodySm.copyWith(color: c.textBody),
        ),
      ),
    );
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.plan});
  final HealthImportPlan plan;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final rows = <(String, int)>[
      ('New', plan.count),
      ('Already imported', plan.skippedAlreadyImported),
      ('Saved by StationX (skipped)', plan.skippedOwn),
      ('Unsupported type (skipped)', plan.skippedUnsupported),
    ];
    // Which types were skipped, e.g. "Yoga 2 · Other 5", so a missing watch workout is explainable.
    final skippedNames = [
      for (final e in plan.unsupportedTypes.entries)
        '${_prettyType(e.key)} ${e.value}',
    ].join(' · ');
    return SxCard(
      child: Column(
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.$1,
                    style: SxText.bodyMd.copyWith(color: c.textBody),
                  ),
                ),
                Text(
                  '${r.$2}',
                  style: SxText.metricSm.copyWith(
                    color: i == 0 ? c.primary : c.textHigh,
                  ),
                ),
              ],
            ),
          ],
          if (skippedNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Skipped types: $skippedNames',
                style: SxText.bodySm.copyWith(color: c.textBody),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _prettyType(String raw) {
  final words = raw.toLowerCase().split('_').where((w) => w.isNotEmpty);
  final text = words.join(' ');
  return text.isEmpty ? 'Unknown' : text[0].toUpperCase() + text.substring(1);
}

class _Preview extends StatelessWidget {
  const _Preview({required this.plan});
  final HealthImportPlan plan;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final miles = !context.app.profile.profile.cardioDistanceUnitKm;
    final items = <(DateTime, Widget)>[
      for (final s in plan.sessions)
        (s.workoutDate, _SessionTile(session: s, miles: miles)),
      for (final s in plan.strengthSessions)
        (s.workoutDate, _StrengthTile(session: s)),
    ]..sort((a, b) => b.$1.compareTo(a.$1)); // newest first
    final sources = plan.sourceLabels.join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Counts(plan: plan),
        const SizedBox(height: SxSpace.md),
        SectionHeader(
          'Preview${sources.isEmpty ? '' : ' · $sources'}',
          icon: Icons.list_alt_outlined,
        ),
        const SizedBox(height: 8),
        SxCard(
          padding: const EdgeInsets.symmetric(horizontal: SxSpace.md),
          child: Column(
            children: [
              for (final (i, it) in items.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.hairline),
                it.$2,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.miles});
  final CardioSession session;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final parts = <String>[
      Fmt.durationShort(session.durationSeconds),
      if (session.distanceKm != null)
        '${Fmt.km(session.distanceKm, miles: miles)} ${miles ? 'mi' : 'km'}',
      if (session.calories != null) '${session.calories} kcal',
    ];
    final src = RegExp(r'\((.+)\)$').firstMatch(session.notes)?.group(1);
    final when =
        '${Fmt.dateMedium(session.workoutDate)} · ${Fmt.time(session.workoutDate)}';
    final detail = parts.join(' · ');
    return Semantics(
      container: true,
      label:
          '${session.kind.label}, $when, $detail${src == null ? '' : ', from $src'}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.kind.label,
                      style: SxText.bodyLg.copyWith(
                        color: c.textHigh,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      when,
                      style: SxText.bodySm.copyWith(color: c.textBody),
                    ),
                    Text(
                      detail,
                      style: SxText.bodySm.copyWith(color: c.textBody),
                    ),
                  ],
                ),
              ),
              if (src != null) ...[
                const SizedBox(width: 8),
                Flexible(child: SxTag(src)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StrengthTile extends StatelessWidget {
  const _StrengthTile({required this.session});
  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final src = RegExp(r'\((.+?)\)').firstMatch(session.notes)?.group(1);
    final kcal = RegExp(r'(\d+) kcal').firstMatch(session.notes)?.group(1);
    final when =
        '${Fmt.dateMedium(session.workoutDate)} · ${Fmt.time(session.workoutDate)}';
    final detail = [
      Fmt.durationShort(session.durationSeconds),
      if (kcal != null) '$kcal kcal',
    ].join(' · ');
    return Semantics(
      container: true,
      label:
          '${session.name}, $when, $detail${src == null ? '' : ', from $src'}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: SxText.bodyLg.copyWith(
                        color: c.textHigh,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      when,
                      style: SxText.bodySm.copyWith(color: c.textBody),
                    ),
                    Text(
                      detail,
                      style: SxText.bodySm.copyWith(color: c.textBody),
                    ),
                  ],
                ),
              ),
              if (src != null) ...[
                const SizedBox(width: 8),
                Flexible(child: SxTag(src)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
