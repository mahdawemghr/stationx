import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

/// Cardio units + honest sensor status + local data export.
/// Sensors, Health Connect and audio coaching are NOT implemented in this
/// build, so they are shown as unavailable rather than faked.
class CardioSettingsPage extends StatelessWidget {
  const CardioSettingsPage({super.key});

  Future<void> _setUnit(BuildContext context, bool km) async {
    final repo = context.app.profile;
    await repo.update(repo.profile.copyWith(cardioDistanceUnitKm: km));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.profile, app.cardio]),
      builder: (context, _) {
        final c = context.sx;
        final km = app.profile.profile.cardioDistanceUnitKm;
        return SxScaffold(
          topBar: SxTopBar(
            title: 'Cardio Settings',
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await _setUnit(context, true);
                  if (context.mounted) showSxSnack(context, 'Cardio units reset to kilometres');
                },
                icon: Icon(Icons.restart_alt, size: 18, color: c.textBody),
                label: Text('Reset', style: SxText.labelUi.copyWith(color: c.textBody)),
              ),
            ],
          ),
          children: [
            _Section(
              icon: Icons.straighten,
              title: 'Units & formats',
              children: [
                Text('DISTANCE', style: SxText.labelCaps.copyWith(color: c.textBody)),
                const SizedBox(height: 6),
                SxSegmented(labels: const ['Kilometres', 'Miles'], index: km ? 0 : 1, onChanged: (i) => _setUnit(context, i == 0)),
                const SizedBox(height: SxSpace.md),
                _Derived('Speed', km ? 'km/h' : 'mph'),
                _Derived('Pace', km ? 'min / km' : 'min / mi'),
                Text('Speed and pace follow the distance unit. Data is always stored in kilometres.', style: SxText.bodySm.copyWith(color: c.textMuted)),
              ],
            ),
            _Section(
              icon: Icons.sensors,
              title: 'Sensors & integrations',
              children: [
                const _Unavailable(icon: Icons.monitor_heart_outlined, title: 'Heart-rate strap', text: 'Bluetooth heart-rate devices are not supported yet. You can enter an average heart rate manually when you log a session.'),
                const _Unavailable(icon: Icons.watch_outlined, title: 'Health Connect / wearables', text: 'Not connected. Sleep, resting heart rate and workout import will appear here once Health Connect is implemented.'),
                const _Unavailable(icon: Icons.gps_fixed, title: 'GPS tracking', text: 'Routes and live pace from GPS are not available. Enter distance manually.'),
                const _Unavailable(icon: Icons.record_voice_over_outlined, title: 'Audio coaching', text: 'Voice split cues are not available in this build.'),
              ],
            ),
            _Section(
              icon: Icons.folder_zip_outlined,
              title: 'Local data & export',
              children: [
                Text('${app.cardio.sessions.length} cardio session${app.cardio.sessions.length == 1 ? '' : 's'} and ${app.cardio.goals.length} goal${app.cardio.goals.length == 1 ? '' : 's'} stored on this device.',
                    style: SxText.bodyMd.copyWith(color: c.textHigh)),
                const SizedBox(height: SxSpace.md),
                Row(children: [
                  Expanded(child: SxButton(label: 'JSON', icon: Icons.data_object, variant: SxButtonVariant.secondary, height: 44, onPressed: () => _export(context, _json(app.cardio), 'cardio.json'))),
                  const SizedBox(width: 8),
                  Expanded(child: SxButton(label: 'CSV', icon: Icons.table_chart_outlined, variant: SxButtonVariant.secondary, height: 44, onPressed: () => _export(context, _csv(app.cardio.sessions), 'cardio.csv'))),
                ]),
              ],
            ),
          ],
        );
      },
    );
  }

  static String _json(CardioRepository repo) => const JsonEncoder.withIndent('  ').convert({
        'sessions': [
          for (final s in repo.sessions)
            {
              'id': s.id,
              'kind': s.kind.name,
              'workoutDate': s.workoutDate.toIso8601String(),
              'createdAt': s.meta.createdAt.toIso8601String(),
              'durationSeconds': s.durationSeconds,
              'distanceKm': s.distanceKm,
              'speedKmh': s.speedKmh,
              'inclinePct': s.inclinePct,
              'resistance': s.resistance,
              'calories': s.calories,
              'avgHeartRate': s.avgHeartRate,
              'rpe': s.rpe,
              'routeName': s.routeName,
              'notes': s.notes,
            }
        ],
        'goals': [
          for (final g in repo.goals) {'id': g.id, 'title': g.title, 'metric': g.metric.name, 'target': g.target, 'period': g.period.name, 'isPrimary': g.isPrimary}
        ],
      });

  static String _csv(List<CardioSession> sessions) {
    String q(String v) => '"${v.replaceAll('"', '""')}"';
    final b = StringBuffer('workoutDate,createdAt,kind,durationSeconds,distanceKm,calories,avgHeartRate,rpe,routeName,notes\n');
    for (final s in sessions) {
      b.writeln([
        s.workoutDate.toIso8601String(),
        s.meta.createdAt.toIso8601String(),
        s.kind.name,
        s.durationSeconds,
        s.distanceKm ?? '',
        s.calories ?? '',
        s.avgHeartRate ?? '',
        s.rpe ?? '',
        q(s.routeName),
        q(s.notes),
      ].join(','));
    }
    return b.toString();
  }

  Future<void> _export(BuildContext context, String text, String name) {
    return showSxSheet<void>(
      context,
      builder: (ctx) {
        final c = ctx.sx;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.md),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: SxText.headlineMd.copyWith(color: c.textHigh)),
              const SizedBox(height: 4),
              Text('Copy this text to save or share it.', style: SxText.bodySm.copyWith(color: c.textBody)),
              const SizedBox(height: 12),
              Flexible(
                child: SxInset(
                  child: SingleChildScrollView(child: SelectableText(text, style: SxText.metricSm.copyWith(color: c.textBody, fontSize: 11))),
                ),
              ),
              const SizedBox(height: 12),
              SxButton(
                label: 'Copy to clipboard',
                icon: Icons.copy,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    showSxSnack(context, 'Copied $name');
                  }
                },
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.children});
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: c.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: SxText.headlineSm.copyWith(color: c.textHigh))),
        ]),
        const SizedBox(height: SxSpace.md),
        ...children,
      ]),
    );
  }
}

class _Derived extends StatelessWidget {
  const _Derived(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Text(label, style: SxText.bodyMd.copyWith(color: c.textBody))),
        Text(value, style: SxText.metricSm.copyWith(color: c.textHigh)),
      ]),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SxInset(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: c.textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(title, style: SxText.labelUi.copyWith(color: c.textHigh, fontWeight: FontWeight.w600, fontSize: 14)),
                StatusPill('Not available', color: c.textMuted),
              ]),
              const SizedBox(height: 4),
              Text(text, style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
        ]),
      ),
    );
  }
}
