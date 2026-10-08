import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_colors.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

enum _Phase { loading, suggestion, none, done, dismissed }

/// Non-blocking suggestion on the cardio complete page: heart rate / calories from the health
/// store. Renders nothing unless "Fill heart rate & calories" is on. Never auto-applies.
class HealthEnrichmentCard extends StatefulWidget {
  const HealthEnrichmentCard({super.key, required this.sessionId});
  final String sessionId;

  @override
  State<HealthEnrichmentCard> createState() => _HealthEnrichmentCardState();
}

class _HealthEnrichmentCardState extends State<HealthEnrichmentCard> {
  _Phase _phase = _Phase.loading;
  HealthEnrichment? _e;
  bool _started = false;
  int _token = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _check();
  }

  Future<void> _check() async {
    final app = context.app;
    final s = app.cardio.byId(widget.sessionId);
    if (s == null || !app.healthSync.isEnabled(HealthFeature.enrichCardio)) return;
    final token = ++_token;
    setState(() => _phase = _Phase.loading);
    HealthEnrichment? e;
    try {
      e = await app.healthSync.suggestEnrichment(s);
    } catch (_) {
      e = null;
    }
    if (!mounted || token != _token) return;
    setState(() {
      _e = e;
      _phase = e == null ? _Phase.none : _Phase.suggestion;
    });
  }

  Future<void> _apply() async {
    final app = context.app;
    final e = _e;
    final s = app.cardio.byId(widget.sessionId);
    if (e == null || s == null) return;
    final updated = HealthEnrichmentService.apply(s, e);
    await app.cardio.update(updated);
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
    showSxSnack(context, 'Added to your session');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: app.healthSync,
      builder: (context, _) {
        if (!app.healthSync.isEnabled(HealthFeature.enrichCardio) || _phase == _Phase.dismissed || _phase == _Phase.done) {
          return const SizedBox.shrink();
        }
        final c = context.sx;
        return SxCard(
          key: const Key('health-enrichment-card'),
          borderColor: _phase == _Phase.suggestion ? c.primaryBorder : null,
          child: SxSwap(
            alignment: Alignment.topLeft,
            child: KeyedSubtree(key: ValueKey(_phase), child: _content(c)),
          ),
        );
      },
    );
  }

  Widget _content(SxColors c) {
    final provider = context.app.healthSync.provider.label;
    switch (_phase) {
      case _Phase.loading:
        return Semantics(
          liveRegion: true,
          label: 'Checking $provider for heart rate and calories',
          child: Row(children: [
            const SxSpinner(size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text('Checking $provider for heart rate & calories...', style: SxText.bodyMd.copyWith(color: c.textBody))),
          ]),
        );
      case _Phase.none:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nothing from your watch yet', style: SxText.bodyLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Heart rate can take a few minutes to arrive, especially from Samsung Health. You can check again later.',
            style: SxText.bodySm.copyWith(color: c.textBody),
          ),
          const SizedBox(height: SxSpace.sm),
          Row(children: [
            Expanded(child: SxButton(label: 'Check again', icon: Icons.refresh, variant: SxButtonVariant.secondary, height: 48, onPressed: _check)),
            const SizedBox(width: 8),
            Expanded(child: SxButton(label: 'Dismiss', variant: SxButtonVariant.ghost, height: 48, onPressed: () => setState(() => _phase = _Phase.dismissed))),
          ]),
        ]);
      case _Phase.suggestion:
        final e = _e!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.watch_outlined, size: 18, color: c.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Add heart rate & calories from your watch?', style: SxText.bodyLg.copyWith(color: c.textHigh, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: SxSpace.sm),
          Wrap(spacing: 12, runSpacing: 8, children: [
            if (e.avgHeartRate != null) _Value(label: 'Avg heart rate', value: '${e.avgHeartRate}', unit: 'bpm'),
            if (e.calories != null) _Value(label: 'Calories', value: Fmt.thousands(e.calories!), unit: 'kcal'),
          ]),
          const SizedBox(height: 6),
          Text('From $provider. Only empty fields are filled; nothing you typed is changed.', style: SxText.bodySm.copyWith(color: c.textBody)),
          const SizedBox(height: SxSpace.sm),
          Row(children: [
            Expanded(child: SxButton(label: 'Apply', icon: Icons.check, height: 48, onPressed: _apply)),
            const SizedBox(width: 8),
            Expanded(child: SxButton(label: 'Dismiss', variant: SxButtonVariant.secondary, height: 48, onPressed: () => setState(() => _phase = _Phase.dismissed))),
          ]),
        ]);
      case _Phase.done:
      case _Phase.dismissed:
        return const SizedBox.shrink();
    }
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      label: '$label $value $unit',
      excludeSemantics: true,
      child: SxInset(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody)),
          Text('$value $unit', style: SxText.metricSm.copyWith(color: c.textHigh)),
        ]),
      ),
    );
  }
}
