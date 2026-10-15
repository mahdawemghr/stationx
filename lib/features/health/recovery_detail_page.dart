import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'recovery_card.dart';

/// The details behind the Today recovery card: the verdict, last night's stages, the resting
/// heart rate against the user's own normal, why, and the last seven nights.
class RecoveryDetailPage extends StatefulWidget {
  const RecoveryDetailPage({super.key, required this.report});
  final RecoveryReport report;

  @override
  State<RecoveryDetailPage> createState() => _RecoveryDetailPageState();
}

class _RecoveryDetailPageState extends State<RecoveryDetailPage> {
  late RecoveryReport _report = widget.report;

  Future<void> _refresh() async {
    final r = await context.app.healthSync.recoveryReport(force: true);
    if (!mounted || r == null) return;
    setState(() => _report = r);
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    final c = context.sx;
    final n = r.night;
    return SxScaffold(
      topBar: const SxTopBar(title: 'Sleep & recovery', subtitle: 'TODAY'),
      gap: SxSpace.md,
      onRefresh: _refresh,
      children: [
        SxStagger(index: 0, child: _Hero(report: r)),
        if (n != null) SxStagger(index: 1, child: _NightCard(night: n)),
        if (r.verdict != RecoveryVerdict.noData)
          SxStagger(index: 2, child: _RestingCard(report: r)),
        if (r.reasons.isNotEmpty)
          SxStagger(index: 3, child: _WhyCard(reasons: r.reasons)),
        if (r.history.length > 1)
          SxStagger(index: 4, child: _HistoryCard(history: r.history)),
        SxStagger(
          index: 5,
          child: Text(
            'Based only on what your watch recorded, compared with your own recent nights. It is a guide for training, not medical advice.',
            style: SxText.bodySm.copyWith(color: c.textMuted),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.report});
  final RecoveryReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final v = report.verdict;
    final color = verdictColor(c, v);
    return SxCard(
      child: Semantics(
        container: true,
        label: '${verdictTitle(v)}. ${verdictAdvice(v)}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(verdictIcon(v), color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    verdictTitle(v),
                    style: SxText.headlineMd.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              verdictAdvice(v),
              style: SxText.bodyMd.copyWith(color: c.textBody),
            ),
            if (report.quality != null) ...[
              const SizedBox(height: 12),
              SxTag(
                sleepQualityLabel(report.quality!).toUpperCase(),
                color: switch (report.quality!) {
                  SleepQuality.great || SleepQuality.good => c.primary,
                  SleepQuality.fair => c.textHigh,
                  SleepQuality.poor => c.danger,
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NightCard extends StatelessWidget {
  const _NightCard({required this.night});
  final SleepNight night;

  static String _dur(int m) => Fmt.durationShort(m * 60);

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final stages = <(String, int?, Color)>[
      ('Deep', night.deepMinutes, c.primary),
      ('REM', night.remMinutes, c.primary.withValues(alpha: 0.55)),
      ('Light', night.lightMinutes, c.textMuted.withValues(alpha: 0.6)),
      ('Awake', night.awakeMinutes > 0 ? night.awakeMinutes : null, c.danger),
    ];
    final shown = [
      for (final s in stages)
        if (s.$2 != null && s.$2! > 0) s,
    ];
    return SxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAST NIGHT',
            style: SxText.labelCaps.copyWith(color: c.textBody),
          ),
          const SizedBox(height: 8),
          Text(
            '${_dur(night.asleepMinutes)} asleep',
            style: SxText.metricMd.copyWith(color: c.textHigh),
          ),
          const SizedBox(height: 2),
          Text(
            '${Fmt.time(night.bedtime)} to ${Fmt.time(night.wake)} · ${_dur(night.inBedMinutes)} in bed',
            style: SxText.bodySm.copyWith(color: c.textBody),
          ),
          const SizedBox(height: SxSpace.md),
          if (night.hasStages && shown.isNotEmpty) ...[
            Semantics(
              label: [
                for (final s in shown) '${s.$1} ${_dur(s.$2!)}',
              ].join(', '),
              excludeSemantics: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 14,
                  child: Row(
                    children: [
                      for (final s in shown)
                        Expanded(
                          flex: s.$2!,
                          child: ColoredBox(color: s.$3),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: SxSpace.md),
            for (final s in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.$3,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.$1,
                        style: SxText.bodyMd.copyWith(color: c.textBody),
                      ),
                    ),
                    Text(
                      _dur(s.$2!),
                      style: SxText.bodyMd.copyWith(
                        color: c.textHigh,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (night.efficiency != null)
              Text(
                'Sleep efficiency ${(night.efficiency! * 100).round()}%',
                style: SxText.bodySm.copyWith(color: c.textBody),
              ),
          ] else
            Text(
              'Your watch recorded when you slept but not the sleep stages, so deep and REM sleep are not shown.',
              style: SxText.bodySm.copyWith(color: c.textBody),
            ),
        ],
      ),
    );
  }
}

class _RestingCard extends StatelessWidget {
  const _RestingCard({required this.report});
  final RecoveryReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final hr = report.restingHr;
    final delta = report.restingHrDelta;
    return SxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESTING HEART RATE',
            style: SxText.labelCaps.copyWith(color: c.textBody),
          ),
          const SizedBox(height: 8),
          if (hr == null)
            Text(
              'No resting heart rate yet. Turn on "Fill heart rate & calories from my watch" in Profile › Health & workouts so StationX can read your heart rate while you sleep.',
              style: SxText.bodySm.copyWith(color: c.textBody),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$hr', style: SxText.metricMd.copyWith(color: c.textHigh)),
                const SizedBox(width: 6),
                Text('bpm', style: SxText.bodyMd.copyWith(color: c.textBody)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              delta == null
                  ? 'Not enough earlier nights yet to compare with your usual.'
                  : delta == 0
                  ? 'Same as your usual ${report.restingBaseline} bpm.'
                  : delta < 0
                  ? '${-delta} below your usual ${report.restingBaseline} bpm.'
                  : '$delta above your usual ${report.restingBaseline} bpm.',
              style: SxText.bodySm.copyWith(color: c.textBody),
            ),
            const SizedBox(height: 4),
            Text(
              report.restingSource == RestingHrSource.estimated
                  ? 'Estimated from your heart rate while you slept.'
                  : 'Recorded by your watch.',
              style: SxText.bodySm.copyWith(color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  const _WhyCard({required this.reasons});
  final List<RecoveryReason> reasons;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHY', style: SxText.labelCaps.copyWith(color: c.textBody)),
          const SizedBox(height: 8),
          for (final r in reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    switch (r.tone) {
                      ReasonTone.good => Icons.check_circle_outline,
                      ReasonTone.neutral => Icons.info_outline,
                      ReasonTone.bad => Icons.warning_amber_rounded,
                    },
                    size: 20,
                    color: switch (r.tone) {
                      ReasonTone.good => c.primary,
                      ReasonTone.neutral => c.textBody,
                      ReasonTone.bad => c.danger,
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.text,
                      style: SxText.bodyMd.copyWith(color: c.textBody),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});
  final List<NightSummary> history;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    const maxBar = 72.0;
    const top = 600; // 10h fills the bar
    return SxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAST ${history.length} NIGHTS',
            style: SxText.labelCaps.copyWith(color: c.textBody),
          ),
          const SizedBox(height: SxSpace.md),
          Semantics(
            label: [
              for (final h in history)
                '${Fmt.dayName(h.day.weekday)} ${Fmt.durationShort(h.minutes * 60)}',
            ].join(', '),
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final h in history)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          Fmt.durationShort(h.minutes * 60),
                          style: SxText.bodySm.copyWith(
                            color: c.textBody,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: (h.minutes / top).clamp(0.05, 1.0) * maxBar,
                          width: 18,
                          decoration: BoxDecoration(
                            color: h.minutes >= ReadinessEngine.targetMinutes
                                ? c.primary
                                : (h.minutes >= 360
                                      ? c.primary.withValues(alpha: 0.5)
                                      : c.danger.withValues(alpha: 0.7)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Fmt.dayShort(h.day.weekday),
                          style: SxText.bodySm.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: SxSpace.sm),
          Text(
            'Target ${Fmt.durationShort(ReadinessEngine.targetMinutes * 60)} a night.',
            style: SxText.bodySm.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
