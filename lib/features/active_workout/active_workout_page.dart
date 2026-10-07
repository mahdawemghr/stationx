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
  const ActiveWorkoutPage({super.key, required this.workoutId, this.backdate});
  final String workoutId;
  final DateTime? backdate;

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  ActiveWorkoutController? _ctl;
  bool _init = false;
  bool _allowPop = false;
  bool _saving = false;
  bool _strengthHidden = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final app = AppScope.read(context);
    final w = app.workouts.byId(widget.workoutId);
    if (w != null) {
      _ctl = ActiveWorkoutController(
        workout: w,
        catalog: app.exercises.all,
        sessions: app.sessions,
        profile: app.profile.profile,
      );
    }
  }

  @override
  void dispose() {
    _ctl?.dispose();
    super.dispose();
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
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  Future<void> _finish(AppController app) async {
    final ctl = _ctl!;
    if (_saving) return;
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
    setState(() => _saving = true);
    final date = widget.backdate ?? DateTime.now();
    final session = ctl.buildSession(id: 'ws_${DateTime.now().microsecondsSinceEpoch}', workoutDate: date);
    await app.completion.complete(session, advanceRotation: widget.backdate == null);
    if (!mounted) return;
    setState(() => _allowPop = true);
    AppNav.workoutComplete(context, session.id);
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
        if (!didPop) _confirmDiscard();
      },
      child: ListenableBuilder(
        listenable: ctl,
        builder: (context, _) {
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
          return SxScaffold(
            topBar: SxTopBar(
              title: mixed ? 'Active Session' : 'Active Workout',
              showLogo: true,
              pill: const StatusPill('Live', dot: true),
              actions: [Padding(padding: const EdgeInsets.only(right: 4), child: SxAvatar(app.profile.profile.name, size: 32))],
            ),
            bottom: _Footer(
              controller: ctl,
              saving: _saving,
              mixed: mixed,
              unit: unit,
              onFinish: () => _finish(app),
            ),
            children: [
              if (widget.backdate != null) _BackdateBanner(date: widget.backdate!),
              if (mixed) _MixedHeader(controller: ctl) else _SplitHeader(controller: ctl, onMore: _more),
              if (!mixed) ...[
                _ProgressStrip(controller: ctl),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: ElapsedTile(startedAt: ctl.startedAt)),
                  const SizedBox(width: 8),
                  Expanded(child: RestTile(controller: ctl)),
                ]),
              ] else
                RestTile(controller: ctl, compactWhenIdle: true),
              if (mixed) _StrengthHeader(controller: ctl, hidden: _strengthHidden, onToggle: () => setState(() => _strengthHidden = !_strengthHidden)),
              if (!(mixed && _strengthHidden))
                for (var i = 0; i < ctl.drafts.length; i++)
                  ExerciseBlock(key: ObjectKey(ctl.drafts[i]), controller: ctl, draft: ctl.drafts[i], index: i, unit: unit),
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

class _SplitHeader extends StatelessWidget {
  const _SplitHeader({required this.controller, required this.onMore});
  final ActiveWorkoutController controller;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(children: [
      Expanded(
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: 'CURRENT SPLIT  •  ', style: SxText.labelCaps.copyWith(color: c.primary)),
            TextSpan(text: controller.workout.name.toUpperCase(), style: SxText.headlineSm.copyWith(color: c.textHigh, fontWeight: FontWeight.w700)),
          ]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 8),
      SxIconButton(icon: Icons.more_horiz, tooltip: 'More', onPressed: onMore),
    ]);
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.controller});
  final ActiveWorkoutController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final n = controller.drafts.length;
    final cur = controller.currentIndex + 1;
    final pct = controller.totalSets == 0 ? 0 : (controller.doneSets * 100 / controller.totalSets).round();
    return Column(children: [
      Row(children: [
        Expanded(child: Text('EXERCISE $cur OF $n', style: SxText.labelCaps.copyWith(color: c.textBody))),
        Text('$pct% COMPLETE', style: SxText.labelCaps.copyWith(color: c.textBody)),
      ]),
      const SizedBox(height: 8),
      SegmentedProgress(total: n, filled: controller.completedExercises < n && controller.doneSets > 0 ? controller.completedExercises + 1 : controller.completedExercises),
    ]);
  }
}

class _MixedHeader extends StatelessWidget {
  const _MixedHeader({required this.controller});
  final ActiveWorkoutController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final done = controller.itemsDone, total = controller.itemsTotal;
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
      SxCard(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Icon(Icons.task_alt, color: c.positive, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text('$done / $total items completed', style: SxText.bodyLg.copyWith(color: c.textHigh))),
            Text('${total == 0 ? 0 : (done * 100 / total).round()}%', style: SxText.metricSm.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          SxLinearMeter(value: total == 0 ? 0 : done / total, height: 6),
        ]),
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
          StatusPill('${controller.completedExercises}/${controller.drafts.length} completed', color: c.positive),
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
    final cur = controller.currentIndex;
    final next = [
      for (var i = cur + 1; i < controller.drafts.length; i++)
        if (!controller.drafts[i].complete) controller.drafts[i].exercise.name,
    ].take(3).toList();
    if (next.isEmpty) return const SizedBox.shrink();
    return SxInset(
      padding: const EdgeInsets.all(12),
      child: Text('UP NEXT: ${next.join(', ').toUpperCase()}', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller, required this.saving, required this.mixed, required this.unit, required this.onFinish});
  final ActiveWorkoutController controller;
  final bool saving;
  final bool mixed;
  final WeightUnit unit;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final cardio = controller.cardio;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        if (mixed && cardio != null) ...[
          ListenableBuilder(
            listenable: cardio,
            builder: (_, _) => Semantics(
              button: true,
              label: cardio.running ? 'Pause cardio' : 'Start cardio',
              child: InkWell(
                onTap: cardio.toggle,
                borderRadius: BorderRadius.circular(SxRadius.md),
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
        Expanded(child: SxButton(label: 'Finish workout', icon: Icons.flag, loading: saving, onPressed: onFinish)),
      ]),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(
          child: Text('${controller.remainingSets} OF ${controller.totalSets} SETS REMAINING',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text('CURRENT VOLUME: ${Fmt.volume(controller.volumeKg, u: unit).toUpperCase()}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.primary, fontSize: 10)),
        ),
      ]),
    ]);
  }
}
