import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/formatters.dart';
import '../../domain/domain.dart';
import 'cardio_manage_helpers.dart';

/// Create (goal == null) or edit a cardio goal in a bottom sheet.
/// Returns true if something was saved/deleted.
Future<bool> showCardioGoalSheet(BuildContext context, {CardioGoal? goal}) async {
  final r = await showSxSheet<bool>(context, builder: (_) => _GoalSheet(goal: goal, app: context.app));
  return r ?? false;
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({required this.goal, required this.app});
  final CardioGoal? goal;
  final AppController app;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late final _title = TextEditingController(text: widget.goal?.title ?? '');
  late final _target = TextEditingController(text: widget.goal == null ? '' : Fmt.number(widget.goal!.target));
  late GoalMetric _metric = widget.goal?.metric ?? GoalMetric.durationMinutes;
  late GoalPeriod _period = widget.goal?.period ?? GoalPeriod.week;
  late bool _primary = widget.goal?.isPrimary ?? false;
  bool _showErrors = false;

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    super.dispose();
  }

  double? get _targetValue => double.tryParse(_target.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final t = _targetValue;
    setState(() => _showErrors = true);
    if (_title.text.trim().isEmpty || t == null || t <= 0) return;
    final repo = widget.app.cardio;
    final g = widget.goal;
    final saved = g == null
        ? CardioGoal(id: 'g_${DateTime.now().microsecondsSinceEpoch}', title: _title.text.trim(), metric: _metric, target: t, period: _period, isPrimary: _primary)
        : g.copyWith(title: _title.text.trim(), metric: _metric, target: t, period: _period, isPrimary: _primary);
    if (_primary) {
      for (final other in repo.goals.where((x) => x.id != saved.id && x.isPrimary)) {
        await repo.saveGoal(other.copyWith(isPrimary: false));
      }
    }
    await repo.saveGoal(saved);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final g = widget.goal!;
    final ok = await showSxConfirm(context,
        title: 'Delete goal?', message: '"${g.title}" will be removed. Your logged sessions are not affected.', confirmLabel: 'Delete goal', destructive: true, icon: Icons.delete_forever);
    if (!ok || !mounted) return;
    await (widget.app.cardio).deleteGoal(g.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final t = _targetValue;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.goal == null ? 'New cardio goal' : 'Adjust goal', style: SxText.headlineMd.copyWith(color: c.textHigh)),
          const SizedBox(height: SxSpace.md),
          SxTextField(label: 'Goal name', controller: _title, hint: 'e.g. Weekly aerobic duration', errorText: _showErrors && _title.text.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: SxSpace.md),
          Text('MEASURE', style: SxText.labelCaps.copyWith(color: c.textBody)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in GoalMetric.values)
              SxChip(label: goalMetricLabel(m), icon: goalMetricIcon(m), selected: _metric == m, onTap: () => setState(() => _metric = m)),
          ]),
          const SizedBox(height: SxSpace.md),
          SxTextField(
            label: 'Target',
            controller: _target,
            mono: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            suffixText: goalMetricUnit(_metric),
            errorText: _showErrors && (t == null || t <= 0) ? 'Enter a target' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: SxSpace.md),
          Text('PERIOD', style: SxText.labelCaps.copyWith(color: c.textBody)),
          const SizedBox(height: 6),
          SxSegmented(labels: const ['Weekly', 'Monthly'], index: _period.index, onChanged: (i) => setState(() => _period = GoalPeriod.values[i])),
          const SizedBox(height: SxSpace.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: c.onPrimary,
            activeTrackColor: c.primary,
            title: Text('Primary goal', style: SxText.bodyLg.copyWith(color: c.textHigh)),
            subtitle: Text('Shown as the headline target on the goals screen.', style: SxText.bodySm.copyWith(color: c.textBody)),
            value: _primary,
            onChanged: (v) => setState(() => _primary = v),
          ),
          const SizedBox(height: SxSpace.sm),
          SxButton(label: widget.goal == null ? 'Create goal' : 'Save goal', icon: Icons.check, onPressed: _save),
          if (widget.goal != null) ...[
            const SizedBox(height: 8),
            SxButton(label: 'Delete goal', icon: Icons.delete_outline, variant: SxButtonVariant.secondary, height: 44, onPressed: _delete),
          ],
        ]),
      ),
    );
  }
}
