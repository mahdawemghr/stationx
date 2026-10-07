import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'cardio_home_support.dart';

/// Pick a cardio activity, then continue to the prepare screen.
class SelectCardioActivityPage extends StatefulWidget {
  const SelectCardioActivityPage({super.key});

  @override
  State<SelectCardioActivityPage> createState() => _SelectCardioActivityPageState();
}

class _SelectCardioActivityPageState extends State<SelectCardioActivityPage> {
  static const _filters = ['All', 'Outdoor', 'Gym Machine', 'High Intensity', 'Low Impact'];
  static const _groups = [null, CardioGroup.outdoor, CardioGroup.gym, CardioGroup.highIntensity, CardioGroup.lowImpact];
  final _search = TextEditingController();
  int _filter = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    return ListenableBuilder(
      listenable: app.cardio,
      builder: (context, _) {
        final sessions = app.cardio.sessions;
        final recent = sessions.isEmpty ? null : sessions.first;
        final q = _search.text.trim().toLowerCase();
        final group = _groups[_filter];
        bool match(String name, Set<CardioGroup> g) =>
            (q.isEmpty || name.toLowerCase().contains(q)) && (group == null || g.contains(group));
        final kinds = [for (final k in CardioKind.values) if (k != CardioKind.custom && match(k.label, cardioGroups(k))) k];
        final customs = [for (final a in app.cardio.customActivities) if (match(a.name, const {}) && group == null) a];

        return SxScaffold(
          topBar: SxTopBar(
            title: 'Select Activity',
            subtitle: 'CARDIO ENGINE',
            actions: [SxIconButton(icon: Icons.history, tooltip: 'Log past session', onPressed: () => AppNav.backdateCardio(context))],
          ),
          padding: const EdgeInsets.fromLTRB(SxSpace.screenMargin, SxSpace.md, SxSpace.screenMargin, SxSpace.lg),
          gap: 12,
          children: [
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              cursorColor: c.primary,
              style: SxText.bodyLg.copyWith(color: c.textHigh),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.surface1,
                hintText: 'Search cardio activity…',
                hintStyle: SxText.bodyMd.copyWith(color: c.textMuted),
                prefixIcon: Icon(Icons.search, color: c.textMuted),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: Icon(Icons.close, color: c.textMuted),
                        onPressed: () => setState(_search.clear)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(SxRadius.md), borderSide: BorderSide(color: c.hairline)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(SxRadius.md), borderSide: BorderSide(color: c.hairline)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(SxRadius.md), borderSide: BorderSide(color: c.primary)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: SxChipRow(
                labels: [for (var i = 0; i < _filters.length; i++) i == 0 ? 'All (${CardioKind.values.length - 1 + app.cardio.customActivities.length})' : _filters[i]],
                selectedIndex: _filter,
                onSelected: (i) => setState(() => _filter = i),
                padding: EdgeInsets.zero,
              ),
            ),
            const _SensorBanner(),
            if (kinds.isEmpty && customs.isEmpty)
              const EmptyState(icon: Icons.search_off, title: 'No activity found', message: 'Try a different search or filter, or create a custom activity.'),
            for (final k in kinds)
              _ActivityTile(
                icon: cardioKindIcon(k),
                name: k.label,
                blurb: cardioKindBlurb(k),
                metrics: cardioMetricsLine(k),
                recent: recent != null && recent.kind == k && recent.customActivityId == null,
                last: _lastLabel(lastOfKind(sessions, k)),
                onTap: () => AppNav.cardioPrepare(context, k),
              ),
            for (final a in customs)
              _ActivityTile(
                icon: cardioIconForKey(a.iconKey),
                name: a.name,
                blurb: a.category,
                metrics: 'METRICS: ${a.fields.map(cardioFieldLabel).join(' • ')}',
                recent: recent?.customActivityId == a.id,
                last: _lastLabel(lastOfKind(sessions, CardioKind.custom, customId: a.id)),
                onTap: () => AppNav.cardioPrepare(context, CardioKind.custom, customActivityId: a.id),
              ),
            SxCard(
              color: c.surface2,
              onTap: () => AppNav.createCustomCardio(context),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(SxRadius.md)),
                  child: Icon(Icons.add_circle_outline, color: c.onAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Custom Cardio Activity', style: SxText.headlineSm.copyWith(color: c.textHigh)),
                    Text('Define your own activity & metrics', style: SxText.bodySm.copyWith(color: c.textBody)),
                  ]),
                ),
                Icon(Icons.add, color: c.primary),
              ]),
            ),
          ],
        );
      },
    );
  }

  String? _lastLabel(CardioSession? s) {
    if (s == null) return null;
    final d = s.distanceKm != null ? '${Fmt.km(s.distanceKm)} km' : Fmt.durationShort(s.durationSeconds);
    return 'LAST: $d';
  }
}

/// Honest sensor state: StationX has no sensor integration yet.
class _SensorBanner extends StatelessWidget {
  const _SensorBanner();
  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxInset(
      child: Row(children: [
        Icon(Icons.sensors_off, size: 16, color: c.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text('NO SENSORS CONNECTED • ENTER DISTANCE MANUALLY',
              style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.name,
    required this.blurb,
    required this.metrics,
    required this.onTap,
    this.recent = false,
    this.last,
  });
  final IconData icon;
  final String name;
  final String blurb;
  final String metrics;
  final bool recent;
  final String? last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(SxRadius.md)),
            child: Icon(icon, color: c.textHigh),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(name, style: SxText.headlineSm.copyWith(color: c.textHigh)),
                if (recent) const StatusPill('Recent', filled: true),
              ]),
              const SizedBox(height: 2),
              Text(blurb, maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
          Icon(Icons.chevron_right, color: c.textBody),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text(metrics, maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textMuted, fontSize: 10))),
          if (last != null) ...[
            const SizedBox(width: 8),
            Text(last!, style: SxText.labelCaps.copyWith(color: c.primary, fontSize: 10)),
          ],
        ]),
      ]),
    );
  }
}
