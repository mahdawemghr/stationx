import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'active_cardio_clock.dart';

/// Live cardio session: running + paused states on one page.
/// Time is tracked automatically; distance (and treadmill speed / incline /
/// bike resistance) are entered manually — there is no GPS/sensor layer.
class ActiveCardioPage extends StatefulWidget {
  const ActiveCardioPage({super.key, required this.kind, this.targetMinutes, this.targetKm, this.customActivityId});
  final CardioKind kind;
  final int? targetMinutes;
  final double? targetKm;
  final String? customActivityId;

  @override
  State<ActiveCardioPage> createState() => _ActiveCardioPageState();
}

class _ActiveCardioPageState extends State<ActiveCardioPage> {
  final CardioClock _clock = CardioClock();
  // One 1s heartbeat; only small ValueListenableBuilders rebuild from it.
  final ValueNotifier<int> _tick = ValueNotifier(0);
  Timer? _timer;

  bool _paused = false;
  bool _locked = false;
  bool _finished = false;
  double? _km;
  double? _speed;
  double? _incline;
  int? _resistance;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick.value++);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tick.dispose();
    super.dispose();
  }

  CustomCardioActivity? _custom(CardioRepository repo) {
    for (final a in repo.customActivities) {
      if (a.id == widget.customActivityId) return a;
    }
    return null;
  }

  List<CardioField> _fields(CardioRepository repo) => _custom(repo)?.fields ?? widget.kind.fields;

  bool get _dirty => _clock.activeSeconds > 0 || _km != null;

  Future<void> _confirmDiscard() async {
    if (_locked) return;
    if (!_dirty) {
      _finished = true;
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final ok = await showSxConfirm(context,
        title: 'Discard session?',
        message: 'This session has not been saved. Its time and distance will be lost.',
        confirmLabel: 'Discard',
        cancelLabel: 'Keep going',
        destructive: true,
        icon: Icons.delete_forever);
    if (ok && mounted) {
      _finished = true;
      Navigator.of(context).pop();
    }
  }

  Future<void> _finish() async {
    final repo = context.app.cardio;
    final secs = _clock.activeSeconds;
    if (secs <= 0) {
      showSxSnack(context, 'Nothing recorded yet — keep moving or discard.', icon: Icons.info_outline);
      return;
    }
    _clock.pause();
    final id = 'cardio_${DateTime.now().microsecondsSinceEpoch}';
    final fields = _fields(repo);
    await repo.add(CardioSession(
      id: id,
      kind: widget.kind,
      workoutDate: _clock.startedAt,
      durationSeconds: secs,
      distanceKm: fields.contains(CardioField.distance) ? _km : null,
      speedKmh: fields.contains(CardioField.speed) && widget.kind == CardioKind.treadmill ? _speed : null,
      inclinePct: fields.contains(CardioField.incline) ? _incline : null,
      resistance: fields.contains(CardioField.resistance) ? _resistance : null,
      customActivityId: widget.customActivityId,
    ));
    if (!mounted) return;
    _finished = true;
    AppNav.cardioComplete(context, id);
  }

  void _togglePause() {
    setState(() {
      if (_paused) {
        _clock.resume();
      } else {
        _clock.pause();
      }
      _paused = !_paused;
    });
  }

  Future<void> _editDistance(bool miles) async {
    final cur = _km == null ? null : (miles ? _km! * 0.621371 : _km!);
    final v = await showNumericKeypad(context, title: 'Distance', initial: cur, unit: miles ? 'mi' : 'km', step: 0.1, max: 1000);
    if (v != null && mounted) setState(() => _km = v <= 0 ? null : (miles ? v / 0.621371 : v));
  }

  Future<void> _editSpeed() async {
    final v = await showNumericKeypad(context, title: 'Speed', initial: _speed, unit: 'km/h', step: 0.5, max: 40);
    if (v != null && mounted) setState(() => _speed = v <= 0 ? null : v);
  }

  Future<void> _editIncline() async {
    final v = await showNumericKeypad(context, title: 'Incline', initial: _incline, unit: '%', step: 0.5, max: 30);
    if (v != null && mounted) setState(() => _incline = v <= 0 ? null : v);
  }

  Future<void> _editResistance() async {
    final v = await showNumericKeypad(context, title: 'Resistance level', initial: _resistance?.toDouble(), allowDecimal: false, max: 50);
    if (v != null && mounted) setState(() => _resistance = v <= 0 ? null : v.round());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.cardio, app.profile]),
      builder: (context, _) {
        final miles = !app.profile.profile.cardioDistanceUnitKm;
        final fields = _fields(app.cardio);
        final custom = _custom(app.cardio);
        final name = custom?.name ?? widget.kind.label;
        final hasDistance = fields.contains(CardioField.distance);
        final isTreadmill = widget.kind == CardioKind.treadmill;
        final hasTarget = widget.targetMinutes != null || widget.targetKm != null;

        return PopScope(
          canPop: _finished,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmDiscard();
          },
          child: SxScaffold(
            topBar: SxTopBar(
              title: 'Active Session',
              subtitle: name.toUpperCase(),
              onBack: _confirmDiscard,
              pill: StatusPill(_paused ? 'Paused' : 'Tracking', dot: true, color: _paused ? c.textBody : c.primary),
            ),
            gap: SxSpace.md,
            bottom: _Controls(
              paused: _paused,
              locked: _locked,
              kindLabel: name,
              onTogglePause: _togglePause,
              onFinish: _finish,
              onDiscard: _confirmDiscard,
              onLock: () => setState(() => _locked = true),
              onUnlock: () => setState(() => _locked = false),
            ),
            children: [
              if (_paused)
                _PausedBanner(tick: _tick, clock: _clock)
              else
                _HeroCard(
                  tick: _tick,
                  clock: _clock,
                  label: name,
                  km: hasDistance ? (_km ?? 0) : null,
                  miles: miles,
                  onEditDistance: _locked ? null : () => _editDistance(miles),
                ),
              if (_paused)
                _PausedHero(tick: _tick, clock: _clock, km: hasDistance ? _km : null, miles: miles, kind: widget.kind, fields: fields, onEditDistance: _locked ? null : () => _editDistance(miles)),
              if (hasTarget && !_paused) _GoalCard(tick: _tick, clock: _clock, targetMinutes: widget.targetMinutes, targetKm: widget.targetKm, km: _km ?? 0, miles: miles),
              if (!_paused)
                _MetricGrid(
                  tick: _tick,
                  clock: _clock,
                  km: _km,
                  miles: miles,
                  fields: fields,
                  kind: widget.kind,
                  speed: isTreadmill ? _speed : null,
                  incline: _incline,
                  resistance: _resistance,
                  locked: _locked,
                  onEditSpeed: _editSpeed,
                  onEditIncline: _editIncline,
                  onEditResistance: _editResistance,
                ),
              _SensorNote(hasDistance: hasDistance),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.tick, required this.clock, required this.label, required this.km, required this.miles, required this.onEditDistance});
  final ValueNotifier<int> tick;
  final CardioClock clock;
  final String label;
  final double? km;
  final bool miles;
  final VoidCallback? onEditDistance;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      padding: const EdgeInsets.symmetric(vertical: SxSpace.lg, horizontal: SxSpace.md),
      child: Column(children: [
        Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody, letterSpacing: 1.4)),
        const SizedBox(height: SxSpace.sm),
        ValueListenableBuilder<int>(
          valueListenable: tick,
          builder: (_, _, _) => FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(Fmt.clockHms(clock.activeSeconds), key: const Key('cardio-clock'), style: SxText.metricXl.copyWith(color: c.primary, fontSize: 52)),
          ),
        ),
        if (km != null) ...[
          const SizedBox(height: SxSpace.sm),
          InkWell(
            key: const Key('cardio-distance'),
            onTap: onEditDistance,
            borderRadius: BorderRadius.circular(SxRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text(Fmt.km(km, miles: miles) == '0' ? '0.00' : Fmt.km(km, miles: miles), style: SxText.metricXl.copyWith(color: c.textHigh)),
                  const SizedBox(width: 6),
                  Text(miles ? 'MI' : 'KM', style: SxText.metricMd.copyWith(color: c.textBody)),
                  const SizedBox(width: 8),
                  Icon(Icons.edit, size: 16, color: c.textMuted),
                ]),
              ),
            ),
          ),
          Text('TAP TO UPDATE DISTANCE', style: SxText.labelCaps.copyWith(color: c.textMuted, fontSize: 10)),
        ],
      ]),
    );
  }
}

class _PausedBanner extends StatelessWidget {
  const _PausedBanner({required this.tick, required this.clock});
  final ValueNotifier<int> tick;
  final CardioClock clock;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(SxRadius.md)),
          child: Icon(Icons.pause, color: c.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('WORKOUT PAUSED', style: SxText.headlineSm.copyWith(color: c.textHigh)),
            Text('Tap Resume whenever you are set', style: SxText.bodySm.copyWith(color: c.textBody)),
          ]),
        ),
        const SizedBox(width: 8),
        Icon(Icons.timer_outlined, size: 18, color: c.textBody),
        const SizedBox(width: 4),
        ValueListenableBuilder<int>(
          valueListenable: tick,
          builder: (_, _, _) => Text(Fmt.clock(clock.pausedSeconds), style: SxText.metricSm.copyWith(color: c.textBody)),
        ),
      ]),
    );
  }
}

class _PausedHero extends StatelessWidget {
  const _PausedHero({required this.tick, required this.clock, required this.km, required this.miles, required this.kind, required this.fields, required this.onEditDistance});
  final ValueNotifier<int> tick;
  final CardioClock clock;
  final double? km;
  final bool miles;
  final CardioKind kind;
  final List<CardioField> fields;
  final VoidCallback? onEditDistance;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final secs = clock.activeSeconds;
    final pace = CardioMetrics.paceSecPerKm(secs, km);
    return SxCard(
      child: Column(children: [
        SxInset(
          padding: const EdgeInsets.symmetric(vertical: SxSpace.lg),
          alignment: Alignment.center,
          child: Column(children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.timelapse, size: 14, color: c.textBody),
              const SizedBox(width: 6),
              Text('ACTIVE DURATION', style: SxText.labelCaps.copyWith(color: c.textBody)),
            ]),
            const SizedBox(height: 6),
            FittedBox(child: Text(Fmt.clock(secs), key: const Key('cardio-clock-paused'), style: SxText.metricXl.copyWith(color: c.textHigh, fontSize: 52))),
          ]),
        ),
        if (fields.contains(CardioField.distance)) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: SxInset(
                onTap: onEditDistance,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DISTANCE', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
                  const SizedBox(height: 6),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(km == null ? '—' : Fmt.km(km, miles: miles), style: SxText.metricLg.copyWith(color: c.textHigh))),
                  Text(miles ? 'MILES' : 'KILOMETERS', style: SxText.labelCaps.copyWith(color: c.textMuted, fontSize: 10)),
                ]),
              ),
            ),
            if (fields.contains(CardioField.pace)) ...[
              const SizedBox(width: 8),
              Expanded(
                child: SxInset(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('AVG PACE', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
                    const SizedBox(height: 6),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(Fmt.pace(pace), style: SxText.metricLg.copyWith(color: c.textHigh))),
                    Text('/ KM', style: SxText.labelCaps.copyWith(color: c.textMuted, fontSize: 10)),
                  ]),
                ),
              ),
            ],
          ]),
        ],
      ]),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.tick, required this.clock, required this.targetMinutes, required this.targetKm, required this.km, required this.miles});
  final ValueNotifier<int> tick;
  final CardioClock clock;
  final int? targetMinutes;
  final double? targetKm;
  final double km;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final byTime = targetMinutes != null;
    return SxCard(
      child: ValueListenableBuilder<int>(
        valueListenable: tick,
        builder: (_, _, _) {
          final secs = clock.activeSeconds;
          final total = byTime ? targetMinutes! * 60.0 : targetKm!;
          final done = byTime ? secs.toDouble() : km;
          final pct = total <= 0 ? 0.0 : (done / total);
          final left = (total - done).clamp(0, double.infinity);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.flag_outlined, color: c.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(byTime ? 'GOAL: $targetMinutes MIN' : 'GOAL: ${Fmt.km(targetKm, miles: miles)} ${miles ? 'MI' : 'KM'}',
                    style: SxText.headlineSm.copyWith(color: c.textHigh), overflow: TextOverflow.ellipsis),
              ),
              Text('${(pct * 100).clamp(0, 999).round()}% COMPLETE', style: SxText.labelCaps.copyWith(color: c.primary)),
            ]),
            const SizedBox(height: SxSpace.sm),
            SxLinearMeter(value: pct, height: 8),
            const SizedBox(height: SxSpace.sm),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(byTime ? 'ELAPSED: ${Fmt.clock(secs)}' : 'DONE: ${Fmt.km(km, miles: miles)}', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
              Text(byTime ? 'REMAINING: ${Fmt.clock(left.round())}' : 'REMAINING: ${Fmt.km(left.toDouble(), miles: miles)}',
                  style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
            ]),
          ]);
        },
      ),
    );
  }
}

/// 2-column telemetry tiles that adapt to the activity's fields.
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.tick,
    required this.clock,
    required this.km,
    required this.miles,
    required this.fields,
    required this.kind,
    required this.speed,
    required this.incline,
    required this.resistance,
    required this.locked,
    required this.onEditSpeed,
    required this.onEditIncline,
    required this.onEditResistance,
  });
  final ValueNotifier<int> tick;
  final CardioClock clock;
  final double? km;
  final bool miles;
  final List<CardioField> fields;
  final CardioKind kind;
  final double? speed;
  final double? incline;
  final int? resistance;
  final bool locked;
  final VoidCallback onEditSpeed;
  final VoidCallback onEditIncline;
  final VoidCallback onEditResistance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: tick,
      builder: (context, _, _) {
        final secs = clock.activeSeconds;
        final tiles = <Widget>[];
        if (fields.contains(CardioField.pace)) {
          final p = CardioMetrics.paceSecPerKm(secs, km);
          final shown = p == null ? null : (miles ? p * 1.609344 : p);
          tiles.add(_Tile(label: 'Avg pace', icon: Icons.timer_outlined, value: Fmt.pace(shown), unit: miles ? '/mi' : '/km', caption: km == null ? 'Enter distance' : null));
        }
        if (fields.contains(CardioField.speed)) {
          if (kind == CardioKind.treadmill) {
            tiles.add(_Tile(label: 'Speed', icon: Icons.speed, value: speed == null ? '—' : Fmt.number(speed!), unit: 'km/h', caption: 'Tap to set', onTap: locked ? null : onEditSpeed));
          } else {
            final s = CardioMetrics.speedKmh(secs, km);
            tiles.add(_Tile(label: 'Avg speed', icon: Icons.speed, value: s == null ? '—' : Fmt.number(miles ? s * 0.621371 : s), unit: miles ? 'mph' : 'km/h', caption: km == null ? 'Enter distance' : null));
          }
        }
        if (fields.contains(CardioField.incline)) {
          tiles.add(_Tile(label: 'Incline', icon: Icons.landscape_outlined, value: incline == null ? '—' : Fmt.number(incline!), unit: '%', caption: 'Tap to set', onTap: locked ? null : onEditIncline));
        }
        if (fields.contains(CardioField.resistance)) {
          tiles.add(_Tile(label: 'Resistance', icon: Icons.tune, value: resistance == null ? '—' : '$resistance', unit: 'lvl', caption: 'Tap to set', onTap: locked ? null : onEditResistance));
        }
        if (tiles.isEmpty) return const SizedBox.shrink();
        return LayoutBuilder(builder: (context, cons) {
          const gap = 12.0;
          final w = (cons.maxWidth - gap) / 2;
          return Wrap(spacing: gap, runSpacing: gap, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
        });
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.icon, required this.value, required this.unit, this.caption, this.onTap});
  final String label;
  final IconData icon;
  final String value;
  final String unit;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody))),
          Icon(onTap != null ? Icons.edit : icon, size: 16, color: c.primary),
        ]),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: SxText.metricLg.copyWith(color: c.textHigh)),
            const SizedBox(width: 4),
            Text(unit, style: SxText.bodySm.copyWith(color: c.textBody)),
          ]),
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(caption!.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textMuted, fontSize: 10)),
        ],
      ]),
    );
  }
}

/// Honest replacement for the Stitch GPS/HR/cadence tiles.
class _SensorNote extends StatelessWidget {
  const _SensorNote({required this.hasDistance});
  final bool hasDistance;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxInset(
      child: Row(children: [
        Icon(Icons.sensors_off, size: 18, color: c.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Heart rate, cadence and GPS are not connected. ${hasDistance ? 'Update distance by hand — pace is calculated from it.' : 'Time is tracked automatically.'}',
            style: SxText.bodySm.copyWith(color: c.textBody),
          ),
        ),
      ]),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.paused,
    required this.locked,
    required this.kindLabel,
    required this.onTogglePause,
    required this.onFinish,
    required this.onDiscard,
    required this.onLock,
    required this.onUnlock,
  });
  final bool paused;
  final bool locked;
  final String kindLabel;
  final VoidCallback onTogglePause;
  final VoidCallback onFinish;
  final VoidCallback onDiscard;
  final VoidCallback onLock;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AbsorbPointer(
        absorbing: locked,
        child: Opacity(
          opacity: locked ? 0.45 : 1,
          child: paused
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  SxButton(key: const Key('cardio-resume'), label: 'Resume', icon: Icons.play_arrow, onPressed: onTogglePause),
                  const SizedBox(height: 8),
                  SxButton(key: const Key('cardio-finish'), label: 'Finish & save', icon: Icons.flag_outlined, variant: SxButtonVariant.secondary, height: 48, onPressed: onFinish),
                  TextButton.icon(
                    onPressed: onDiscard,
                    icon: Icon(Icons.delete_outline, size: 18, color: c.danger),
                    label: Text('Discard session (unsaved)', style: SxText.bodyMd.copyWith(color: c.danger)),
                  ),
                ])
              : Row(children: [
                  Expanded(flex: 2, child: SxButton(key: const Key('cardio-pause'), label: 'Pause', icon: Icons.pause, variant: SxButtonVariant.secondary, onPressed: onTogglePause)),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: SxButton(key: const Key('cardio-finish'), label: 'Finish', icon: Icons.stop_circle_outlined, onPressed: onFinish)),
                ]),
        ),
      ),
      const SizedBox(height: 8),
      _LockRow(locked: locked, onLock: onLock, onUnlock: onUnlock),
    ]);
  }
}

/// Tap to lock; hold ~1s to unlock (prevents sweaty accidental touches).
class _LockRow extends StatefulWidget {
  const _LockRow({required this.locked, required this.onLock, required this.onUnlock});
  final bool locked;
  final VoidCallback onLock;
  final VoidCallback onUnlock;

  @override
  State<_LockRow> createState() => _LockRowState();
}

class _LockRowState extends State<_LockRow> with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        widget.onUnlock();
        _hold.reset();
      }
    });

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return GestureDetector(
      key: const Key('cardio-lock'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.locked ? null : widget.onLock,
      onTapDown: widget.locked ? (_) => _hold.forward() : null,
      onTapUp: widget.locked ? (_) => _hold.reverse() : null,
      onTapCancel: widget.locked ? () => _hold.reverse() : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedBuilder(
            animation: _hold,
            builder: (_, _) => SizedBox(
              width: 22,
              height: 22,
              child: Stack(alignment: Alignment.center, children: [
                if (widget.locked) CircularProgressIndicator(value: _hold.value, strokeWidth: 2, color: c.primary, backgroundColor: c.surface3),
                Icon(widget.locked ? Icons.lock : Icons.lock_open, size: 14, color: widget.locked ? c.primary : c.textBody),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(widget.locked ? 'LOCKED • HOLD TO UNLOCK' : 'TAP TO LOCK SCREEN CONTROLS',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: widget.locked ? c.primary : c.textBody, fontSize: 10)),
          ),
        ]),
      ),
    );
  }
}
