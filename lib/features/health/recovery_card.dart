import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_colors.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/health/health_sync_service.dart';
import '../../domain/domain.dart';

/// Plain-language headline for a verdict.
String verdictTitle(RecoveryVerdict v) => switch (v) {
  RecoveryVerdict.ready => "You're ready",
  RecoveryVerdict.takeItEasy => 'Take it easy today',
  RecoveryVerdict.needRest => 'You need rest',
  RecoveryVerdict.noData => 'No sleep recorded yet',
};

/// One sentence of advice under the headline.
String verdictAdvice(RecoveryVerdict v) => switch (v) {
  RecoveryVerdict.ready => 'You recovered well. Train as planned.',
  RecoveryVerdict.takeItEasy =>
    'Recovery is partial. Go lighter or shorter than planned.',
  RecoveryVerdict.needRest =>
    'Sleep or recovery is low. Skip hard training, or keep it very light, and sleep earlier tonight.',
  RecoveryVerdict.noData =>
    'Wear the watch overnight and let its app sync to your health app.',
};

IconData verdictIcon(RecoveryVerdict v) => switch (v) {
  RecoveryVerdict.ready => Icons.bolt,
  RecoveryVerdict.takeItEasy => Icons.self_improvement,
  RecoveryVerdict.needRest => Icons.bedtime_outlined,
  RecoveryVerdict.noData => Icons.nights_stay_outlined,
};

Color verdictColor(SxColors c, RecoveryVerdict v) => switch (v) {
  RecoveryVerdict.ready => c.primary,
  RecoveryVerdict.takeItEasy => c.textHigh,
  RecoveryVerdict.needRest => c.danger,
  RecoveryVerdict.noData => c.textBody,
};

String sleepQualityLabel(SleepQuality q) => switch (q) {
  SleepQuality.great => 'Great sleep',
  SleepQuality.good => 'Good sleep',
  SleepQuality.fair => 'Fair sleep',
  SleepQuality.poor => 'Poor sleep',
};

/// Today: how recovered you are, from last night's sleep and your resting heart rate. Opt-in
/// ([HealthFeature.recovery]); renders nothing while the switch is off. Tap for the details.
class RecoveryCard extends StatefulWidget {
  const RecoveryCard({super.key});

  @override
  State<RecoveryCard> createState() => _RecoveryCardState();
}

class _RecoveryCardState extends State<RecoveryCard> {
  RecoveryReport? _data;
  bool _loaded = false;
  bool _wasEnabled = false;
  int _token = 0;
  HealthSyncService? _sync;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sync = context.app.healthSync;
    if (!identical(sync, _sync)) {
      _sync?.removeListener(_onSync);
      sync.addListener(_onSync);
      _sync = sync;
    }
    _wasEnabled = sync.isEnabled(HealthFeature.recovery);
    if (!_loaded && _wasEnabled) _load();
  }

  @override
  void dispose() {
    _sync?.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    final on = _sync!.isEnabled(HealthFeature.recovery);
    if (on == _wasEnabled) return;
    _wasEnabled = on;
    if (on) {
      _load();
    } else if (mounted) {
      setState(() {
        _data = null;
        _loaded = false;
      });
    }
  }

  Future<void> _load() async {
    final token = ++_token;
    final r = await context.app.healthSync.recoveryReport();
    if (!mounted || token != _token) return;
    setState(() {
      _data = r;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.app.healthSync;
    if (!sync.isEnabled(HealthFeature.recovery) || !_loaded) {
      return const SizedBox.shrink();
    }
    final c = context.sx;
    final d = _data;
    if (d == null) {
      return SxCard(
        child: Text(
          'Could not read ${sync.provider.label}. Check that access is allowed in Profile › Health & workouts.',
          style: SxText.bodySm.copyWith(color: c.textBody),
        ),
      );
    }
    final color = verdictColor(c, d.verdict);
    final tappable = d.verdict != RecoveryVerdict.noData;
    final summary = _summary(d);
    return SxCard(
      onTap: tappable ? () => AppNav.recoveryDetails(context, d) : null,
      child: Semantics(
        button: tappable,
        container: true,
        label:
            'Recovery. ${verdictTitle(d.verdict)}. ${verdictAdvice(d.verdict)} $summary',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(verdictIcon(d.verdict), color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECOVERY',
                    style: SxText.labelCaps.copyWith(color: c.textBody),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    verdictTitle(d.verdict),
                    style: SxText.bodyLg.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.isEmpty ? verdictAdvice(d.verdict) : summary,
                    style: SxText.bodySm.copyWith(color: c.textBody),
                  ),
                ],
              ),
            ),
            if (tappable) Icon(Icons.chevron_right, color: c.textMuted),
          ],
        ),
      ),
    );
  }

  /// "7h 40m asleep · Deep 1h 10m · Resting 56 bpm"
  static String _summary(RecoveryReport d) {
    final n = d.night;
    return [
      if (n != null) '${Fmt.durationShort(n.asleepMinutes * 60)} asleep',
      if (n?.deepMinutes != null)
        'Deep ${Fmt.durationShort(n!.deepMinutes! * 60)}',
      if (d.restingHr != null) 'Resting ${d.restingHr} bpm',
    ].join(' · ');
  }
}
