import 'package:flutter/foundation.dart' show ValueListenable;
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
import '../../data/device/device_services.dart';
import 'active_workout_controller.dart';
import 'widgets/cardio_block.dart';
import 'widgets/exercise_block.dart';
import 'widgets/timers.dart';

/// Live workout logger. Strength-only layout, or the mixed layout (strength
/// section + cardio block) when the workout has / gains a cardio block.
///
/// [backdate] set → the session is stored with that `workoutDate` and the
/// rotation is NOT advanced (it is a past entry). `createdAt` is always "now".
class ActiveWorkoutPage extends StatefulWidget {
  const ActiveWorkoutPage({super.key, required this.workoutId, this.backdate, this.clock});
  final String workoutId;
  final DateTime? backdate;

  /// Test hook: clock for the elapsed time (and so for the maximum-length check).
  @visibleForTesting
  final DateTime Function()? clock;

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> with WidgetsBindingObserver {
  ActiveWorkoutController? _ctl;
  AppController? _app;
  bool _init = false;
  bool _allowPop = false;
  final ValueNotifier<bool> _saving = ValueNotifier(false);
  bool _rotationDone = false;
  bool _strengthHidden = false;
  String? _sessionId;
  KeepAwake? _keepAwake;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A restored workout may already be past the limit.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExpiry());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final app = AppScope.read(context);
    _app = app;
    final draft = app.workoutDraft.current;
    final sameDraft = draft != null && draft.workoutId == widget.workoutId && draft.backdate == widget.backdate;
    // A draft for a workout that was deleted meanwhile is rebuilt from its own snapshot.
    final w = app.workouts.byId(widget.workoutId) ?? (sameDraft ? workoutFromDraft(draft) : null);
    if (w != null) {
      _ctl = ActiveWorkoutController(
        workout: w,
        catalog: app.exercises.all,
        sessions: app.sessions,
        profile: app.profile.profile,
        feedback: app.feedback,
        draftStore: app.workoutDraft,
        restoreFrom: sameDraft ? draft : null,
        backdate: widget.backdate,
        clock: widget.clock,
      );
      _keepAwake = app.keepAwake..enable();
      if (draft != null && !sameDraft) {
        // Another unfinished workout exists: never overwrite it silently.
        _ctl!.persistEnabled = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _resolveConflict(draft));
      }
    }
  }

  Future<void> _resolveConflict(WorkoutDraft old) async {
    if (!mounted) return;
    final discard = await showSxConfirm(
      context,
      title: 'Unfinished workout',
      message: '${old.workoutName} is still in progress (${old.doneSets} sets logged). Starting this workout discards it.',
      confirmLabel: 'Discard and start',
      cancelLabel: 'Resume it',
      destructive: true,
      icon: Icons.history,
    );
    if (!mounted) return;
    if (discard) {
      await _app!.workoutDraft.clear();
      _ctl?.persistEnabled = true;
    } else {
      setState(() => _allowPop = true);
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => ActiveWorkoutPage(workoutId: old.workoutId, backdate: old.backdate),
      ));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _ctl?.flushDraft();
    } else {
      _checkExpiry();
    }
  }

  // ── maximum workout length (hard cap) ──
  bool _ending = false;

  /// Cheap check driven by the existing 1 s elapsed ticker and by app resume (no extra timer).
  void _checkExpiry() {
    final ctl = _ctl, app = _app;
    if (ctl == null || app == null || _ending || _saving.value || !ctl.persistEnabled) return;
    final max = app.maxWorkoutDuration;
    if (max == null || ctl.elapsedSeconds < max.inSeconds) return;
    _autoEnd(app, ctl, max);
  }

  Future<void> _autoEnd(AppController app, ActiveWorkoutController ctl, Duration max) async {
    _ending = true;
    try {
      // The SAME path as a kill + restart: persist the draft, then let the app end it.
      await ctl.flushDraft();
      final r = await app.autoEndExpiredWorkout(now: ctl.now());
      await ctl.discardDraft();
      if (!mounted) return;
      if (r != null && r.savedSession && r.sessionId != null) {
        setState(() => _allowPop = true);
        AppNav.workoutComplete(context, r.sessionId!);
        return;
      }
      showSxSnack(
        context,
        r == null
            ? 'Your workout ended automatically after ${WorkoutLimit.label(max.inMinutes)}. Nothing was logged, so nothing was saved.'
            : autoEndMessage(r),
        icon: Icons.timer_off_outlined,
      );
      _leave();
    } catch (_) {
      _ending = false; // the ticker retries on the next second
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keepAwake?.disable();
    _ctl?.dispose();
    _saving.dispose();
    super.dispose();
  }

  void _leave() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  Future<void> _confirmDiscard() async {
    final ok = await showSxConfirm(
      context,
      title: 'Discard workout?',
      message: 'Everything logged in this session will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep training',
      destructive: true,
      icon: Icons.delete_forever,
    );
    if (!ok || !mounted) return;
    await _ctl?.discardDraft();
    if (mounted) _leave();
  }

  /// Back with nothing logged leaves silently; otherwise ask first.
  Future<void> _onBack() async {
    final ctl = _ctl;
    if (ctl == null || !ctl.hasLoggedAnything) {
      await ctl?.discardDraft();
      if (mounted) _leave();
      return;
    }
    await _confirmDiscard();
  }

  Future<void> _finish(AppController app) async {
    final ctl = _ctl!;
    if (_saving.value) return;
    if (!ctl.hasLoggedAnything) {
      showSxSnack(context, 'Log at least one set before finishing.', icon: Icons.info_outline);
      return;
    }
    if (ctl.remainingSets > 0) {
      final ok = await showSxConfirm(
        context,
        title: 'Finish workout?',
        message: '${ctl.remainingSets} set${ctl.remainingSets == 1 ? '' : 's'} not logged. Only completed sets are saved.',
        confirmLabel: 'Finish',
        cancelLabel: 'Keep going',
        icon: Icons.flag,
      );
      if (!ok || !mounted) return;
    }
    _saving.value = true;
    // One id per finish attempt chain, so a retry can never save the session twice.
    final id = _sessionId ??= 'ws_${DateTime.now().microsecondsSinceEpoch}';
    var saved = false;
    try {
      final date = widget.backdate ?? DateTime.now();
      final advance = widget.backdate == null;
      final session = ctl.buildSession(id: id, workoutDate: date);
      if (app.sessions.byId(id) == null) {
        await app.completion.complete(session, advanceRotation: advance);
        _rotationDone = true;
      } else if (advance && !_rotationDone) {
        // A previous attempt saved the session but failed to move the rotation:
        // apply the same rule WorkoutCompletion uses, exactly once.
        await _advanceRotationFor(app, session.workoutId);
        _rotationDone = true;
      }
      saved = true;
      await ctl.discardDraft();
      if (!mounted) return;
      setState(() => _allowPop = true);
      AppNav.workoutComplete(context, id);
    } catch (_) {
      if (mounted) {
        showSxSnack(context, "Couldn't save. Your sets are still here. Try again.", icon: Icons.error_outline);
      }
    } finally {
      if (mounted && !saved) _saving.value = false;
    }
  }

  /// Retry path: the session is already saved but the rotation did not move. Applies the
  /// domain rule (RotationService.afterCompleting, the same one WorkoutCompletion uses) once.
  Future<void> _advanceRotationFor(AppController app, String workoutId) async {
    final rot = app.workouts.rotation;
    if (rot.length == 0) return;
    final next = RotationService.afterCompleting(rot, workoutId);
    if (next.currentIndex != rot.currentIndex) await app.workouts.setRotation(next);
  }

  Future<void> _addCardio() async {
    final k = await showCardioKindPicker(context);
    if (k != null) _ctl!.addCardio(k);
  }

  Future<void> _more() async {
    final c = context.sx;
    final choice = await showSxSheet<String>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_ctl!.cardio == null)
            ListTile(
              minTileHeight: 52,
              leading: Icon(Icons.directions_run, color: c.primary),
              title: Text('Add cardio block', style: SxText.bodyLg.copyWith(color: c.textHigh)),
              onTap: () => Navigator.pop(ctx, 'cardio'),
            ),
          ListTile(
            minTileHeight: 52,
            leading: Icon(Icons.delete_outline, color: c.danger),
            title: Text('Discard workout', style: SxText.bodyLg.copyWith(color: c.danger)),
            onTap: () => Navigator.pop(ctx, 'discard'),
          ),
        ]),
      ),
    );
    if (choice == 'cardio') await _addCardio();
    if (choice == 'discard') await _confirmDiscard();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final ctl = _ctl;
    if (ctl == null) {
      return const SxScaffold(
        topBar: SxTopBar(title: 'Active Workout'),
        body: Center(child: ErrorState(message: 'This workout no longer exists.')),
      );
    }
    final hasCardioOnly = ctl.drafts.isEmpty && ctl.cardio == null;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      // The shell only rebuilds when the structure changes (cardio block added /
      // removed). Every other edit is picked up by the small widgets below that
      // listen to the controller (summary) or to one exercise draft (block).
      child: ValueListenableBuilder<int>(
        valueListenable: ctl.layout,
        builder: (context, _, _) {
          final unit = app.profile.profile.unit;
          final mixed = ctl.isMixed;
          if (hasCardioOnly) {
            return SxScaffold(
              topBar: const SxTopBar(title: 'Active Workout'),
              body: Center(
                child: EmptyState(
                  icon: Icons.fitness_center,
                  title: 'No exercises',
                  message: '${ctl.workout.name} has no exercises yet. Add some in the workout editor.',
                  actionLabel: 'Edit workout',
                  onAction: () => AppNav.workoutEditor(context, ctl.workout.id),
                ),
              ),
            );
          }
          // Narrow phones (≤ ~375dp): drop the logo + avatar so the title never truncates.
          final wide = MediaQuery.sizeOf(context).width >= 400;
          // Short phones (≤ ~640dp tall): tighter gaps and 48dp timer tiles.
          final dense = MediaQuery.sizeOf(context).height < 640;
          final narrow = MediaQuery.sizeOf(context).width < 340;
          return SxScaffold(
            topBar: SxTopBar(
              title: mixed ? 'Active Session' : 'Active Workout',
              showLogo: wide,
              // The split name lives in the bar (was its own 2-line header row).
              subtitle: mixed ? null : ctl.workout.name.toUpperCase(),
              pill: narrow ? null : const StatusPill('Live', dot: true),
              actions: [
                if (!mixed) SxIconButton(icon: Icons.more_horiz, tooltip: 'More', size: 48, onPressed: _more),
                if (wide) Padding(padding: const EdgeInsets.only(right: 4), child: SxAvatar(app.profile.profile.name, size: 32)),
              ],
            ),
            bottom: _Footer(
              controller: ctl,
              saving: _saving,
              mixed: mixed,
              dense: dense,
              unit: unit,
              onFinish: () => _finish(app),
            ),
            // Tight gaps: the first set rows must be visible without scrolling on a small phone.
            padding: const EdgeInsets.fromLTRB(SxSpace.screenMargin, SxSpace.sm, SxSpace.screenMargin, SxSpace.md),
            gap: dense ? SxSpace.xs : SxSpace.sm,
            children: [
              if (widget.backdate != null) _BackdateBanner(date: widget.backdate!),
              if (mixed) _MixedHeader(controller: ctl),
              if (!mixed) ...[
                _ProgressStrip(controller: ctl),
                Column(children: [
                  _LimitWatch(controller: ctl, max: app.maxWorkoutDuration, onTick: _checkExpiry),
                  RepaintBoundary(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: ElapsedTile(startedAt: ctl.startedAt, dense: dense)),
                      const SizedBox(width: 8),
                      Expanded(child: RestTile(controller: ctl, dense: dense)),
                    ]),
                  ),
                ]),
              ] else
                Column(children: [
                  _LimitWatch(controller: ctl, max: app.maxWorkoutDuration, onTick: _checkExpiry),
                  RestTile(controller: ctl, compactWhenIdle: true),
                ]),
              if (mixed) _StrengthHeader(controller: ctl, hidden: _strengthHidden, onToggle: () => setState(() => _strengthHidden = !_strengthHidden)),
              if (!(mixed && _strengthHidden))
                for (final section in ctl.sections) ...[
                  // One muscle in the whole workout: a header would only repeat the title.
                  if (ctl.sections.length > 1 && section.label.isNotEmpty) MuscleSectionHeader(section: section),
                  for (var k = 0; k < section.drafts.length; k++)
                    ExerciseBlock(
                      key: ObjectKey(section.drafts[k]),
                      controller: ctl,
                      draft: section.drafts[k],
                      index: section.startIndex + k,
                      unit: unit,
                    ),
                ],
              if (!mixed) _UpNext(controller: ctl),
              if (mixed) _CardioHeader(draft: ctl.cardio!),
              if (ctl.cardio != null)
                CardioBlock(draft: ctl.cardio!, useKm: app.profile.profile.cardioDistanceUnitKm, onRemove: ctl.removeCardio)
              else
                SxButton(
                  label: 'Add cardio block',
                  icon: Icons.add_circle_outline,
                  variant: SxButtonVariant.secondary,
                  height: 48,
                  onPressed: _addCardio,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Muscle section header: label, exercises done/total, sets done/total. Rebuilds only when
/// one of its own exercises changes; a finished section is dimmed and shows a check.
class MuscleSectionHeader extends StatelessWidget {
  const MuscleSectionHeader({super.key, required this.section});
  final DraftSection section;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return ListenableBuilder(
      listenable: Listenable.merge(section.drafts),
      builder: (context, _) {
        final done = section.complete;
        final ex = '${section.exercisesDone}/${section.drafts.length}';
        final sets = '${section.setsDone}/${section.setsTotal}';
        final tone = done ? c.textMuted : c.textBody;
        return Semantics(
          header: true,
          label: '${section.label}, $ex exercises, $sets sets done',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              SizedBox(
                width: 18,
                child: done ? Icon(Icons.check, size: 16, color: c.positive) : null,
              ),
              Expanded(
                child: Text(
                  section.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SxText.labelCaps.copyWith(color: done ? c.textMuted : c.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text('$ex EX  •  $sets SETS', maxLines: 1, style: SxText.labelXs.copyWith(color: tone)),
            ]),
          ),
        );
      },
    );
  }
}

/// Message shared by the logger snackbar, Today and the complete page.
String autoEndMessage(AutoEndResult r) {
  final head = 'Your workout ended automatically after ${WorkoutLimit.label(r.endedAfter.inMinutes)}';
  if (!r.savedSession) return '$head. Nothing was logged, so nothing was saved.';
  return '$head. ${r.setsLogged} set${r.setsLogged == 1 ? '' : 's'} saved.';
}

/// Drives the maximum-length check (1 s ticker, only while a limit is on) and shows a quiet
/// heads-up during the last 15 minutes. Takes no vertical space otherwise.
class _LimitWatch extends StatelessWidget {
  const _LimitWatch({required this.controller, required this.max, required this.onTick});
  final ActiveWorkoutController controller;
  final Duration? max;
  final VoidCallback onTick;

  static const _warn = Duration(minutes: 15);

  @override
  Widget build(BuildContext context) {
    final max = this.max;
    if (max == null) return const SizedBox.shrink();
    final c = context.sx;
    return SecondTicker(
      onTick: (_) => onTick(),
      builder: (context, _) {
        final left = max - Duration(seconds: controller.elapsedSeconds);
        if (left > _warn || left <= Duration.zero) return const SizedBox.shrink();
        final mins = (left.inSeconds / 60).ceil();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Semantics(
            liveRegion: true,
            child: SxInset(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                Icon(Icons.timer_outlined, size: 18, color: c.textBody),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Workout will end automatically in $mins min',
                      style: SxText.bodySm.copyWith(color: c.textBody)),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _BackdateBanner extends StatelessWidget {
  const _BackdateBanner({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxInset(
      color: c.primarySoft,
      borderColor: c.primaryBorder,
      child: Row(children: [
        Icon(Icons.history, color: c.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Backdated entry for ${Fmt.dateMedium(date)}. The rotation will not advance.',
              style: SxText.bodySm.copyWith(color: c.textHigh)),
        ),
      ]),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.controller});
  final ActiveWorkoutController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final n = controller.drafts.length;
        final cur = controller.currentIndex + 1;
        final pct = controller.totalSets == 0 ? 0 : (controller.doneSets * 100 / controller.totalSets).round();
        final filled = controller.completedExercises < n && controller.doneSets > 0
            ? controller.completedExercises + 1
            : controller.completedExercises;
        // One row: caption, segmented strip, percentage.
        return Semantics(
          container: true,
          label: 'Exercise $cur of $n, $pct percent complete',
          excludeSemantics: true,
          child: Row(children: [
            Text('EX $cur/$n', maxLines: 1, style: SxText.labelCaps.copyWith(color: c.textBody)),
            const SizedBox(width: 10),
            Expanded(child: SegmentedProgress(total: n, filled: filled)),
            const SizedBox(width: 10),
            SxCountUp(
              value: pct.toDouble(),
              fromZero: false,
              duration: SxMotion.short,
              formatter: (v) => '${v.round()}%',
              style: SxText.labelCaps.copyWith(color: c.textBody),
            ),
          ]),
        );
      },
    );
  }
}

class _MixedHeader extends StatelessWidget {
  const _MixedHeader({required this.controller});
  final ActiveWorkoutController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c.positive, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text('${controller.workout.name.toUpperCase()} + CARDIO',
              maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.primary)),
        ),
        const SizedBox(width: 8),
        ElapsedPill(startedAt: controller.startedAt),
      ]),
      const SizedBox(height: 10),
      ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final done = controller.itemsDone, total = controller.itemsTotal;
          final pct = total == 0 ? 0 : (done * 100 / total).round();
          return SxCard(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(children: [
                Icon(Icons.task_alt, color: c.positive, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text('$done / $total items completed', style: SxText.bodyLg.copyWith(color: c.textHigh))),
                SxCountUp(
                  value: pct.toDouble(),
                  fromZero: false,
                  duration: SxMotion.short,
                  formatter: (v) => '${v.round()}%',
                  style: SxText.metricSm.copyWith(color: c.primary, fontWeight: FontWeight.w700),
                ),
              ]),
              const SizedBox(height: 10),
              SxLinearMeter(value: total == 0 ? 0 : done / total, height: 6),
            ]),
          );
        },
      ),
    ]);
  }
}

class _StrengthHeader extends StatelessWidget {
  const _StrengthHeader({required this.controller, required this.hidden, required this.onToggle});
  final ActiveWorkoutController controller;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(children: [
      Expanded(
        child: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('STRENGTH SECTION', style: SxText.headlineSm.copyWith(color: c.textBody, fontWeight: FontWeight.w600)),
          ListenableBuilder(
            listenable: controller,
            builder: (_, _) => StatusPill('${controller.completedExercises}/${controller.drafts.length} completed', color: c.positive),
          ),
        ]),
      ),
      InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(SxRadius.base),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(hidden ? 'Show' : 'Hide', style: SxText.bodyMd.copyWith(color: c.textHigh)),
            Icon(hidden ? Icons.expand_more : Icons.expand_less, size: 20, color: c.textHigh),
          ]),
        ),
      ),
    ]);
  }
}

class _CardioHeader extends StatelessWidget {
  const _CardioHeader({required this.draft});
  final CardioDraft draft;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(children: [
      Flexible(child: Text('CARDIO FINISHER', style: SxText.headlineMd.copyWith(color: c.primary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 8),
      ListenableBuilder(
        listenable: draft,
        builder: (_, _) => StatusPill(draft.running ? 'Active now' : (draft.complete ? 'Done' : 'Up next'), filled: draft.running, color: draft.running ? c.primary : c.textBody),
      ),
    ]);
  }
}

class _UpNext extends StatelessWidget {
  const _UpNext({required this.controller});
  final ActiveWorkoutController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final cur = controller.currentIndex;
        final next = [
          for (var i = cur + 1; i < controller.drafts.length; i++)
            if (!controller.drafts[i].complete) controller.drafts[i].exercise.name,
        ].take(3).toList();
        if (next.isEmpty) return const SizedBox.shrink();
        return SxInset(
          padding: const EdgeInsets.all(12),
          child: Text('UP NEXT: ${next.join(', ').toUpperCase()}', style: SxText.labelXs.copyWith(color: c.textBody)),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller, required this.saving, required this.mixed, required this.dense, required this.unit, required this.onFinish});
  final ActiveWorkoutController controller;
  final ValueListenable<bool> saving;
  final bool mixed;
  final bool dense;
  final WeightUnit unit;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final cardio = controller.cardio;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      RestChip(controller: controller),
      Row(children: [
        if (mixed && cardio != null) ...[
          ListenableBuilder(
            listenable: cardio,
            builder: (_, _) => Semantics(
              button: true,
              label: cardio.running ? 'Pause cardio' : 'Start cardio',
              child: SxPressable(
                semantics: false,
                onTap: cardio.toggle,
                focusRadius: SxRadius.md,
                child: Container(
                  width: 56,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(SxRadius.md),
                    border: Border.all(color: c.hairline),
                  ),
                  child: Icon(cardio.running ? Icons.pause : Icons.play_arrow, color: c.textHigh),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: saving,
            builder: (_, busy, _) => SxButton(label: 'Finish workout', icon: Icons.flag, height: dense ? 48 : 52, loading: busy, onPressed: onFinish),
          ),
        ),
      ]),
      SizedBox(height: dense ? 4 : 8),
      ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
            child: Text('${controller.remainingSets} OF ${controller.totalSets} SETS REMAINING',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelXs.copyWith(color: c.textBody)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text('CURRENT VOLUME: ${Fmt.volume(controller.volumeKg, u: unit).toUpperCase()}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelXs.copyWith(color: c.primary)),
          ),
        ]),
      ),
    ]);
  }
}
