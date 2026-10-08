import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'cardio_manage_form.dart';
import 'cardio_manage_helpers.dart';

/// Log a cardio session that happened in the past. `workoutDate` is what the
/// user picks; "logged today" (createdAt) is stamped separately on save.
class BackdateCardioPage extends StatefulWidget {
  const BackdateCardioPage({super.key, this.kind, this.date});
  final CardioKind? kind;
  final DateTime? date;

  @override
  State<BackdateCardioPage> createState() => _BackdateCardioPageState();
}

class _BackdateCardioPageState extends State<BackdateCardioPage> {
  late final CardioFormState _form;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final base = widget.date ?? now.subtract(const Duration(days: 1));
    final start = DateTime(base.year, base.month, base.day, 7, 0);
    _form = CardioFormState(
      kind: widget.kind ?? CardioKind.outdoorRun,
      date: start.isAfter(now) ? now : start,
      kmUnit: context.app.profile.profile.cardioDistanceUnitKm,
    );
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.validate() || _saving) return;
    setState(() => _saving = true);
    final id = 'c_${DateTime.now().microsecondsSinceEpoch}';
    // meta defaults to createdAt = now; workoutDate stays the chosen past date.
    final s = _form.build(id: id);
    await context.app.cardio.add(s);
    if (!mounted) return;
    showSxSnack(context, 'Historical cardio logged for ${Fmt.dateMedium(s.workoutDate)}');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return ListenableBuilder(
      listenable: _form,
      builder: (context, _) => SxScaffold(
        topBar: SxTopBar(
          title: 'Backdate Cardio',
          actions: [TextButton(onPressed: _save, child: Text('Save', style: SxText.headlineSm.copyWith(color: c.primary)))],
        ),
        bottom: SxBottomCta(
          label: 'Log historical cardio',
          icon: Icons.check_circle_outline,
          onPressed: _saving ? null : _save,
          caption: 'Saved on the date you chose',
        ),
        children: [
          SxCard(
            color: c.surface2,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                StatusPill('Historical entry', dot: true),
              ]),
              const SizedBox(height: 8),
              Text(
                'Backdated cardio is stored on the date you pick. It adds to cardio totals and goals for that date and never changes your workout rotation.',
                style: SxText.bodySm.copyWith(color: c.textBody),
              ),
            ]),
          ),
          const SectionHeader('Activity modality'),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final k in CardioKind.values.where((k) => k != CardioKind.custom))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SxChip(label: k.label, icon: cardioKindIcon(k), selected: _form.kind == k, onTap: () => _form.setKind(k)),
                  ),
              ],
            ),
          ),
          CardioDateTimeRow(
            form: _form,
            footer: Row(children: [
              Icon(Icons.history, size: 14, color: c.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('LOGGED TODAY (${Fmt.dateMedium(DateTime.now()).toUpperCase()})',
                    style: SxText.labelXs.copyWith(color: c.primary), overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
          CardioMetricsSection(form: _form, title: 'Telemetry Log'),
          CardioBiometricsSection(form: _form),
          CardioContextSection(form: _form),
        ],
      ),
    );
  }
}
