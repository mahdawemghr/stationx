import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

/// Average / max heart rate of one finished session, read from the health store (watch).
/// Renders nothing unless "Fill heart rate & calories from my watch" is on. Watch data can arrive
/// minutes after the workout ends, so an empty result offers "Check again" instead of caching.
class HeartRateCard extends StatefulWidget {
  const HeartRateCard({
    super.key,
    required this.sessionKey,
    required this.start,
    required this.durationSeconds,
  });

  /// `WorkoutMapping.cardioKey(id)` / `WorkoutMapping.strengthKey(id)`.
  final String sessionKey;
  final DateTime start;
  final int durationSeconds;

  @override
  State<HeartRateCard> createState() => _HeartRateCardState();
}

class _HeartRateCardState extends State<HeartRateCard> {
  HrStats? _stats;
  bool _loading = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final sync = context.app.healthSync;
    _stats = sync.cachedHeartRate(widget.sessionKey);
    if (_stats == null) _load();
  }

  Future<void> _load() async {
    final sync = context.app.healthSync;
    if (!sync.isEnabled(HealthFeature.enrichCardio) ||
        widget.durationSeconds <= 0) {
      return;
    }
    setState(() => _loading = true);
    final s = await sync.heartRateFor(
      widget.sessionKey,
      widget.start,
      widget.start.add(Duration(seconds: widget.durationSeconds)),
    );
    if (!mounted) return;
    setState(() {
      _stats = s;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.app.healthSync;
    final c = context.sx;
    final stats = _stats;
    if (stats == null && !sync.isEnabled(HealthFeature.enrichCardio)) {
      return const SizedBox.shrink();
    }
    return SxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_border, size: 16, color: c.primary),
              const SizedBox(width: 6),
              Text(
                'HEART RATE',
                style: SxText.labelCaps.copyWith(color: c.textBody),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (stats != null)
            Row(
              children: [
                Expanded(
                  child: _Num(label: 'Average', value: stats.avg),
                ),
                Expanded(
                  child: _Num(label: 'Max', value: stats.max),
                ),
              ],
            )
          else if (_loading)
            Row(
              children: [
                const SxSpinner(size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reading your watch...',
                    style: SxText.bodySm.copyWith(color: c.textBody),
                  ),
                ),
              ],
            )
          else ...[
            Text(
              'No heart rate found for this workout yet. Watch data can take a few minutes to reach ${sync.provider.label}.',
              style: SxText.bodySm.copyWith(color: c.textBody),
            ),
            const SizedBox(height: 8),
            SxButton(
              label: 'Read heart rate again',
              icon: Icons.refresh,
              variant: SxButtonVariant.secondary,
              height: 44,
              onPressed: _load,
            ),
          ],
        ],
      ),
    );
  }
}

class _Num extends StatelessWidget {
  const _Num({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      container: true,
      label: '$label heart rate $value beats per minute',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SxText.bodySm.copyWith(color: c.textBody)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$value',
                style: SxText.metricSm.copyWith(color: c.textHigh),
              ),
              const SizedBox(width: 4),
              Text('bpm', style: SxText.bodySm.copyWith(color: c.textBody)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Latest heart rate during a workout. Polls the health store every 15 s; hides itself when the
/// feature is off or the watch has not written a sample in the last 2 minutes (Health Connect is
/// not a live stream, so this lags the wrist by however often the watch syncs).
class LiveHeartRateChip extends StatefulWidget {
  const LiveHeartRateChip({
    super.key,
    this.interval = const Duration(seconds: 15),
  });
  final Duration interval;

  @override
  State<LiveHeartRateChip> createState() => _LiveHeartRateChipState();
}

class _LiveHeartRateChipState extends State<LiveHeartRateChip> {
  Timer? _timer;
  int? _bpm;
  bool _busy = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!context.app.healthSync.isEnabled(HealthFeature.enrichCardio)) return;
    _poll();
    _timer = Timer.periodic(widget.interval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (_busy) return;
    _busy = true;
    final p = await context.app.healthSync.latestHeartRate();
    _busy = false;
    if (!mounted) return;
    final next = p?.bpm.round();
    if (next != _bpm) setState(() => _bpm = next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bpm = _bpm;
    if (bpm == null) return const SizedBox.shrink();
    final c = context.sx;
    return Semantics(
      label: 'Heart rate $bpm beats per minute',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(SxRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 16, color: c.primary),
            const SizedBox(width: 6),
            Text(
              '$bpm',
              style: SxText.bodyLg.copyWith(
                color: c.textHigh,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            Text('bpm', style: SxText.bodySm.copyWith(color: c.textBody)),
          ],
        ),
      ),
    );
  }
}

/// Average heart rate per day (7 / 14 / 30 days), read on demand, never stored.
class HeartRateTrendCard extends StatefulWidget {
  const HeartRateTrendCard({super.key});

  @override
  State<HeartRateTrendCard> createState() => _HeartRateTrendCardState();
}

class _HeartRateTrendCardState extends State<HeartRateTrendCard> {
  static const _ranges = [7, 14, 30];
  int _days = 7;
  List<HeartRateDay>? _data;
  int _token = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final token = ++_token;
    setState(() => _data = null);
    final d = await context.app.healthSync.heartRateTrend(_days);
    if (!mounted || token != _token) return;
    setState(() => _data = d);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final data = _data;
    return SxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEART RATE TREND',
            style: SxText.labelCaps.copyWith(color: c.textBody),
          ),
          const SizedBox(height: 8),
          SxSegmented(
            labels: [for (final d in _ranges) '$d days'],
            index: _ranges.indexOf(_days),
            onChanged: (i) {
              setState(() => _days = _ranges[i]);
              _load();
            },
          ),
          const SizedBox(height: SxSpace.md),
          if (data == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: SxSpace.lg),
              child: Center(child: SxSpinner(size: 24)),
            )
          else ...[
            _Series(
              title: 'Average',
              values: [for (final d in data) d.average],
            ),
          ],
        ],
      ),
    );
  }
}

class _Series extends StatelessWidget {
  const _Series({required this.title, required this.values});
  final String title;
  final List<double?> values;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final present = [for (final v in values) ?v];
    if (present.isEmpty) {
      return Text(
        '$title: no data in this period',
        style: SxText.bodySm.copyWith(color: c.textBody),
      );
    }
    final avg = present.reduce((a, b) => a + b) / present.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: SxText.bodyMd.copyWith(
                  color: c.textHigh,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${avg.round()} bpm',
              style: SxText.bodyMd.copyWith(color: c.textBody),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (present.length >= 2)
          SxLineChart(
            values: present,
            height: 80,
            semanticLabel:
                '$title heart rate over ${present.length} days, average ${avg.round()} beats per minute',
          )
        else
          Text(
            '${present.first.round()} bpm on one day',
            style: SxText.bodySm.copyWith(color: c.textBody),
          ),
      ],
    );
  }
}
