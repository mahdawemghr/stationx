import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'cardio_activity_templates.dart';
import 'cardio_home_support.dart';
import 'cardio_kind_presentation.dart';

/// Pick a cardio activity, then continue to the prepare screen.
///
/// Browsing (no search): RECENT strip, then compact 64 px rows under section headers.
/// Searching: full cards that also show which alias matched; no result offers
/// "Create custom" and one-tap templates.
class SelectCardioActivityPage extends StatefulWidget {
  const SelectCardioActivityPage({super.key});

  @override
  State<SelectCardioActivityPage> createState() => _SelectCardioActivityPageState();
}

/// One selectable entry: a built-in kind or a user's custom activity.
class _Entry {
  const _Entry.kind(this.kind) : custom = null;
  const _Entry.custom(CustomCardioActivity this.custom) : kind = CardioKind.custom;
  final CardioKind kind;
  final CustomCardioActivity? custom;

  String get name => custom?.name ?? kind.label;
  IconData get icon => custom != null ? cardioIconForKey(custom!.iconKey) : cardioKindIcon(kind);
  String get blurb => custom?.category ?? cardioKindBlurb(kind);
  String get metrics => custom != null ? 'METRICS: ${custom!.fields.map(cardioFieldLabel).join(' • ')}' : cardioMetricsLine(kind);
  List<String> get terms => custom != null ? const [] : cardioSearchTerms(kind);
  Set<CardioGroup> get groups => custom != null ? const {} : cardioGroups(kind);

  void open(BuildContext context) => AppNav.cardioPrepare(context, kind, customActivityId: custom?.id);
}

class _SelectCardioActivityPageState extends State<SelectCardioActivityPage> {
  static const _filters = ['All', 'Outdoor', 'Machines', 'Classes', 'High Intensity', 'Low Impact'];
  static const _groups = [null, CardioGroup.outdoor, CardioGroup.gym, CardioGroup.classes, CardioGroup.highIntensity, CardioGroup.lowImpact];
  final _search = TextEditingController();
  int _filter = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Search hit: whole query in label/terms/blurb, or every word of it somewhere.
  static bool _matches(_Entry e, String q) {
    final label = e.name.toLowerCase();
    final hay = '$label ${e.terms.join(' ')} ${e.blurb.toLowerCase()}';
    if (hay.contains(q)) return true;
    final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.isNotEmpty && words.every(hay.contains);
  }

  /// The alias that matched when the visible label does not contain the query.
  static String? _matchedTerm(_Entry e, String q) {
    if (e.name.toLowerCase().contains(q)) return null;
    for (final t in e.terms) {
      if (t.contains(q)) return t;
    }
    final first = q.split(RegExp(r'\s+')).first;
    for (final t in e.terms) {
      if (t.contains(first)) return t;
    }
    return null;
  }

  /// Up to 4 distinct recently used activities (newest first), custom ones only while they exist.
  List<_Entry> _recents(Iterable<CardioSession> sessions, Iterable<CustomCardioActivity> customs) {
    final out = <_Entry>[];
    final seen = <String>{};
    for (final s in sessions) {
      final id = s.customActivityId;
      final key = id ?? s.kind.name;
      if (!seen.add(key)) continue;
      if (id != null) {
        final a = customs.where((a) => a.id == id);
        if (a.isEmpty) continue;
        out.add(_Entry.custom(a.first));
      } else if (s.kind != CardioKind.custom) {
        out.add(_Entry.kind(s.kind));
      }
      if (out.length == 4) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.cardio, app.profile]),
      builder: (context, _) {
        final sessions = app.cardio.sessions;
        final customs = app.cardio.customActivities;
        final miles = !app.profile.profile.cardioDistanceUnitKm;
        final raw = _search.text.trim();
        final q = raw.toLowerCase();
        final group = _groups[_filter];
        bool inFilter(_Entry e) => group == null ? true : e.groups.contains(group);

        final all = <_Entry>[
          for (final k in CardioKind.values) if (k != CardioKind.custom) _Entry.kind(k),
          for (final a in customs) _Entry.custom(a),
        ];
        final shown = [for (final e in all) if (inFilter(e) && (q.isEmpty || _matches(e, q))) e];
        final searching = q.isNotEmpty;
        final grouped = !searching && group == null;
        final recents = grouped ? _recents(sessions, customs) : const <_Entry>[];

        String? last(_Entry e) => _lastLabel(lastOfKind(sessions, e.kind, customId: e.custom?.id), miles);

        Widget row(_Entry e) => _CompactRow(
              icon: e.icon,
              name: e.name,
              metrics: e.metrics,
              last: last(e),
              onTap: () => e.open(context),
            );

        final body = <Widget>[
          if (recents.isNotEmpty) _RecentStrip(entries: recents, onTap: (e) => e.open(context)),
          if (searching)
            for (final e in shown)
              _ActivityTile(
                icon: e.icon,
                name: e.name,
                blurb: e.blurb,
                metrics: e.metrics,
                matched: _matchedTerm(e, q),
                last: last(e),
                onTap: () => e.open(context),
              )
          else if (grouped) ...[
            for (final section in cardioSections)
              if (section != 'Custom' && shown.any((e) => e.custom == null && cardioSection(e.kind) == section))
                _Section(
                  title: section,
                  children: [for (final e in shown) if (e.custom == null && cardioSection(e.kind) == section) row(e)],
                ),
          ] else
            _Section(title: null, children: [for (final e in shown) row(e)]),
          if (searching && shown.isEmpty) _NoResult(query: raw, onCreate: () => AppNav.createCustomCardio(context, initialName: raw)),
          if (searching && shown.isEmpty)
            for (final t in cardioTemplatesMatching(q)) _TemplateRow(template: t, onTap: () => _useTemplate(t)),
          if (grouped)
            _Section(
              title: 'Custom',
              children: [
                for (final e in shown) if (e.custom != null) row(e),
                _CompactRow(
                  icon: Icons.add_circle_outline,
                  name: 'Custom Cardio Activity',
                  metrics: 'Define your own activity & metrics',
                  accent: true,
                  onTap: () => AppNav.createCustomCardio(context),
                ),
              ],
            ),
          if (searching && shown.isNotEmpty)
            _CompactRow(
              icon: Icons.add_circle_outline,
              name: 'Custom Cardio Activity',
              metrics: 'Define your own activity & metrics',
              accent: true,
              onTap: () => AppNav.createCustomCardio(context, initialName: raw),
            ),
          if (!searching && group != null && shown.isEmpty)
            const EmptyState(icon: Icons.search_off, title: 'No activity found', message: 'Try a different filter, or create a custom activity.'),
          const _SensorLine(),
        ];

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
              textInputAction: TextInputAction.search,
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
            SxChipRow(
              labels: [for (var i = 0; i < _filters.length; i++) i == 0 ? 'All (${all.length})' : _filters[i]],
              selectedIndex: _filter,
              onSelected: (i) => setState(() => _filter = i),
              padding: EdgeInsets.zero,
            ),
            ...body,
          ],
        );
      },
    );
  }

  /// One tap: save the template as a custom activity (reusing an existing one with the same name) and start it.
  Future<void> _useTemplate(CardioActivityTemplate t) async {
    final cardio = context.app.cardio;
    final nav = context;
    final existing = cardio.customActivities.where((a) => a.name.toLowerCase() == t.name.toLowerCase());
    String id;
    if (existing.isNotEmpty) {
      id = existing.first.id;
    } else {
      id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
      await cardio.addCustomActivity(CustomCardioActivity(
        id: id,
        name: t.name,
        category: t.category,
        iconKey: t.iconKey,
        fields: [CardioField.duration, ...t.fields.where((f) => f != CardioField.duration)],
        roundSeconds: t.roundSeconds,
        restSeconds: t.restSeconds,
        rounds: t.rounds,
      ));
    }
    if (!nav.mounted) return;
    await AppNav.cardioPrepare(nav, CardioKind.custom, customActivityId: id);
  }

  String? _lastLabel(CardioSession? s, bool miles) {
    if (s == null) return null;
    final d = s.distanceKm != null ? '${Fmt.km(s.distanceKm, miles: miles)} ${miles ? 'mi' : 'km'}' : Fmt.durationShort(s.durationSeconds);
    return 'LAST: $d';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (title != null)
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title!.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody)),
          ),
        ),
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 8),
        children[i],
      ],
    ]);
  }
}

class _RecentStrip extends StatelessWidget {
  const _RecentStrip({required this.entries, required this.onTap});
  final List<_Entry> entries;
  final void Function(_Entry) onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Column(
      key: const Key('recent-strip'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text('RECENT', style: SxText.labelCaps.copyWith(color: c.textBody)),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => SxChip(label: entries[i].name, icon: entries[i].icon, onTap: () => onTap(entries[i])),
          ),
        ),
      ],
    );
  }
}

/// Browse row: 64 px minimum, icon, name, one-line metrics, LAST at the trailing edge.
class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.icon, required this.name, required this.metrics, required this.onTap, this.last, this.accent = false});
  final IconData icon;
  final String name;
  final String metrics;
  final String? last;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      button: true,
      label: [name, metrics, ?last].join(', '),
      excludeSemantics: true,
      onTap: onTap,
      child: SxCard(
        onTap: onTap,
        radius: SxRadius.md,
        color: accent ? c.surface2 : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: accent ? c.primary : c.surface3, borderRadius: BorderRadius.circular(SxRadius.base)),
              child: Icon(icon, size: 22, color: accent ? c.onAccent : c.textHigh),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.headlineSm.copyWith(color: c.textHigh, fontSize: 16)),
                Text(metrics, maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelXs.copyWith(color: c.textMuted)),
              ]),
            ),
            if (last != null) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 92),
                child: Text(last!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: SxText.labelXs.copyWith(color: c.primary)),
              ),
            ],
            Icon(Icons.chevron_right, color: c.textBody),
          ]),
        ),
      ),
    );
  }
}

/// Search result: full card with blurb and a tiny "matches: alias" hint.
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.name,
    required this.blurb,
    required this.metrics,
    required this.onTap,
    this.matched,
    this.last,
  });
  final IconData icon;
  final String name;
  final String blurb;
  final String metrics;
  final String? matched;
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
              Text(name, style: SxText.headlineSm.copyWith(color: c.textHigh)),
              const SizedBox(height: 2),
              Text(blurb, maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.bodySm.copyWith(color: c.textBody)),
              if (matched != null)
                Text('matches: $matched', maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelXs.copyWith(color: c.primary)),
            ]),
          ),
          Icon(Icons.chevron_right, color: c.textBody),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text(metrics, maxLines: 2, overflow: TextOverflow.ellipsis, style: SxText.labelXs.copyWith(color: c.textMuted))),
          if (last != null) ...[
            const SizedBox(width: 8),
            Text(last!, style: SxText.labelXs.copyWith(color: c.primary)),
          ],
        ]),
      ]),
    );
  }
}

class _NoResult extends StatelessWidget {
  const _NoResult({required this.query, required this.onCreate});
  final String query;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No activity found',
      message: 'Try a different search or filter, or add it yourself.',
      actionLabel: 'Create custom "$query"',
      onAction: onCreate,
    );
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({required this.template, required this.onTap});
  final CardioActivityTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CompactRow(
      icon: cardioIconForKey(template.iconKey),
      name: 'Use "${template.name}" template',
      metrics: 'ONE TAP • ${template.fields.map(cardioFieldLabel).join(' • ')}',
      accent: true,
      onTap: onTap,
    );
  }
}

/// Honest sensor state (StationX has no sensor integration yet), kept to one quiet line.
class _SensorLine extends StatelessWidget {
  const _SensorLine();
  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(children: [
      Icon(Icons.sensors_off, size: 14, color: c.textMuted),
      const SizedBox(width: 6),
      Expanded(
        child: Text('NO SENSORS • ENTER DISTANCE MANUALLY',
            style: SxText.labelXs.copyWith(color: c.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}
