import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

/// "Connect your watch": how data gets from a watch to StationX, plus a check that finds the
/// first step that is not working (read-only, last 7 days).
class WatchSetupPage extends StatefulWidget {
  const WatchSetupPage({super.key});

  @override
  State<WatchSetupPage> createState() => _WatchSetupPageState();
}

class _WatchSetupPageState extends State<WatchSetupPage> {
  WatchDiagnosis? _result;
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    final r = await context.app.healthSync.diagnose();
    if (!mounted) return;
    setState(() {
      _result = r;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final p = context.app.healthSync.provider;
    final store = p == HealthProvider.none ? 'your health app' : p.label;
    final ios = p == HealthProvider.appleHealth;
    return SxScaffold(
      topBar: const SxTopBar(title: 'Connect your watch', subtitle: 'HEALTH'),
      gap: SxSpace.md,
      children: [
        SxStagger(
          index: 0,
          child: SxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOW IT WORKS',
                  style: SxText.labelCaps.copyWith(color: c.textBody),
                ),
                const SizedBox(height: 6),
                Text(
                  ios
                      ? 'Your watch saves workouts and heart rate to Apple Health. StationX reads them from there. It never talks to the watch directly.'
                      : 'Your watch saves workouts and heart rate to its own app, which shares them with Health Connect. StationX reads them from Health Connect. It never talks to the watch directly.',
                  style: SxText.bodyMd.copyWith(color: c.textBody),
                ),
              ],
            ),
          ),
        ),
        if (!ios) ...[
          SxStagger(
            index: 1,
            child: _Guide(
              title: 'Galaxy Watch',
              steps: const [
                'Pair the watch with the Galaxy Wearable app and open Samsung Health on the phone.',
                'In Samsung Health open Settings › Connected services › Health Connect and turn on sharing for exercise and heart rate.',
                'Record a workout on the watch, then open Samsung Health once so it syncs.',
                'Back here, turn on the switches in Health & workouts and run the check below.',
              ],
            ),
          ),
          SxStagger(
            index: 2,
            child: _Guide(
              title: 'Garmin, Fitbit, Polar, Huawei and others',
              steps: const [
                'Open the watch\'s own app (for example Garmin Connect or Fitbit).',
                'Find its Health Connect setting and allow it to write exercise and heart rate.',
                'Sync the watch, then turn on the switches in Health & workouts and run the check below.',
              ],
            ),
          ),
        ] else
          SxStagger(
            index: 1,
            child: _Guide(
              title: 'Apple Watch and other watches',
              steps: const [
                'Make sure the watch app you use is allowed to write to Apple Health (Settings › Health › Data Access & Devices).',
                'Turn on the switches in Health & workouts. iOS asks which data to share.',
                'Run the check below.',
              ],
            ),
          ),
        SxStagger(
          index: 3,
          child: SxButton(
            label: 'Check my connection',
            icon: Icons.health_and_safety_outlined,
            loading: _checking,
            onPressed: _checking ? null : _check,
          ),
        ),
        if (_result != null)
          SxStagger(
            index: 4,
            child: _Result(result: _result!, store: store, ios: ios),
          ),
      ],
    );
  }
}

class _Guide extends StatelessWidget {
  const _Guide({required this.title, required this.steps});
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: SxText.bodyLg.copyWith(
              color: c.textHigh,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final (i, s) in steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}.',
                      style: SxText.bodySm.copyWith(color: c.primary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s,
                      style: SxText.bodySm.copyWith(color: c.textBody),
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

class _Result extends StatelessWidget {
  const _Result({required this.result, required this.store, required this.ios});
  final WatchDiagnosis result;
  final String store;
  final bool ios;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final (
      String headline,
      String detail,
      IconData icon,
      Color color,
    ) = switch (result.step) {
      WatchSetupStep.storeMissing => (
        '$store is not available',
        'Install or update $store, then check again.',
        Icons.download_for_offline_outlined,
        c.textHigh,
      ),
      WatchSetupStep.permissions => (
        'StationX is not allowed to read yet',
        'Turn on "Import workouts from other apps" and "Fill heart rate & calories from my watch" in Health & workouts, and allow access. '
            '${ios ? 'Manage access in Settings › Health › Data Access & Devices › StationX.' : 'Or open Health Connect › App permissions › StationX.'}',
        Icons.lock_outline,
        c.textHigh,
      ),
      WatchSetupStep.noRecentData => (
        'Connected, but no recent watch data',
        ios
            ? 'Nothing from the last 7 days. Record a workout on the watch and check that its app is allowed to write to Apple Health.'
            : 'Nothing from the last 7 days. In your watch\'s app (for example Samsung Health) turn on Health Connect sharing, sync the watch, then check again.',
        Icons.sync_problem_outlined,
        c.textHigh,
      ),
      WatchSetupStep.ok => (
        'Everything is connected',
        result.sources.isEmpty
            ? 'StationX found recent data. Use "Import workouts now" in Health & workouts to bring in past workouts.'
            : 'Recent data found from ${result.sources.join(', ')}. Use "Import workouts now" in Health & workouts to bring in past workouts.',
        Icons.check_circle_outline,
        c.primary,
      ),
    };
    return SxCard(
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: SxText.bodyLg.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: SxText.bodySm.copyWith(color: c.textBody),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
