import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'cardio_manage_helpers.dart';

/// Define a custom cardio activity: name, category, glyph, tracked metrics and
/// an optional round/rest template. Only fields the session model supports are
/// offered; the interval template is stored on the activity only.
class CreateCustomCardioActivityPage extends StatefulWidget {
  const CreateCustomCardioActivityPage({super.key});

  @override
  State<CreateCustomCardioActivityPage> createState() => _CreateCustomCardioActivityPageState();
}

class _CreateCustomCardioActivityPageState extends State<CreateCustomCardioActivityPage> {
  static const _categories = ['Combat Sport', 'Functional HIIT', 'Field Sports', 'Water / Paddle'];
  static const _optional = <(CardioField, String, String, IconData)>[
    (CardioField.heartRate, 'Heart rate', 'Log an average heart rate you read from a device', Icons.favorite_border),
    (CardioField.calories, 'Calories', 'Log estimated energy burn', Icons.local_fire_department_outlined),
    (CardioField.distance, 'Distance', 'Log distance covered (km / mi)', Icons.straighten),
    (CardioField.resistance, 'Resistance level', 'Log machine resistance', Icons.tune),
    (CardioField.rpe, 'Perceived effort (RPE)', 'Log a 1–10 effort rating', Icons.speed),
  ];

  final _name = TextEditingController();
  String _category = _categories.first;
  String _icon = cardioCustomIcons.keys.first;
  final Set<CardioField> _fields = {CardioField.duration};
  bool _intervals = false;
  int _round = 180, _rest = 60, _rounds = 5;
  bool _showErrors = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _nameError {
    if (!_showErrors) return null;
    final n = _name.text.trim();
    if (n.isEmpty) return 'Name required';
    final dup = context.app.cardio.customActivities.any((a) => a.name.toLowerCase() == n.toLowerCase());
    return dup ? 'Name already used' : null;
  }

  int get _workingSeconds => _rounds * _round + (_rounds > 0 ? (_rounds - 1) * _rest : 0);

  Future<void> _save() async {
    setState(() => _showErrors = true);
    if (_nameError != null) return;
    final a = CustomCardioActivity(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      iconKey: _icon,
      fields: _fields.toList(),
      roundSeconds: _intervals ? _round : null,
      restSeconds: _intervals ? _rest : null,
      rounds: _intervals ? _rounds : null,
    );
    await context.app.cardio.addCustomActivity(a);
    if (!mounted) return;
    showSxSnack(context, '"${a.name}" added to your activities');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxScaffold(
      topBar: const SxTopBar(title: 'Custom Activity'),
      bottom: SxButton(label: 'Save custom activity', icon: Icons.save_outlined, onPressed: _save),
      children: [
        SxCard(
          color: c.surface2,
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(SxRadius.base)),
              child: Icon(Icons.tune, color: c.onPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Define the activity and the metrics you want to log for it.', style: SxText.bodyMd.copyWith(color: c.textHigh))),
          ]),
        ),
        CardioFormLike(
          title: '01 / Activity identity',
          children: [
            SxTextField(label: 'Activity name', controller: _name, hint: 'e.g. Heavy bag rounds', icon: Icons.edit_outlined, errorText: _nameError, onChanged: (_) => setState(() {})),
            const SizedBox(height: SxSpace.md),
            Text('DISCIPLINE CATEGORY', style: SxText.labelCaps.copyWith(color: c.textBody)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final cat in _categories) SxChip(label: cat, selected: _category == cat, onTap: () => setState(() => _category = cat)),
            ]),
            const SizedBox(height: SxSpace.md),
            Text('ICON', style: SxText.labelCaps.copyWith(color: c.textBody)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in cardioCustomIcons.entries)
                Semantics(
                  button: true,
                  selected: _icon == e.key,
                  label: e.key.replaceAll('_', ' '),
                  child: InkWell(
                    onTap: () => setState(() => _icon = e.key),
                    borderRadius: BorderRadius.circular(SxRadius.md),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _icon == e.key ? c.primary : c.surface2,
                        borderRadius: BorderRadius.circular(SxRadius.md),
                        border: Border.all(color: _icon == e.key ? c.primary : c.hairline),
                      ),
                      child: Icon(e.value, color: _icon == e.key ? c.onPrimary : c.textBody),
                    ),
                  ),
                ),
            ]),
          ],
        ),
        CardioFormLike(
          title: '02 / Tracked metrics',
          subtitle: 'Choose what you log for each session of this activity.',
          children: [
            _MetricRow(icon: Icons.timer_outlined, title: 'Duration', desc: 'Always tracked', value: true, locked: true, onChanged: null),
            for (final o in _optional)
              _MetricRow(
                icon: o.$4,
                title: o.$2,
                desc: o.$3,
                value: _fields.contains(o.$1),
                onChanged: (v) => setState(() => v ? _fields.add(o.$1) : _fields.remove(o.$1)),
              ),
            _MetricRow(
              icon: Icons.autorenew,
              title: 'Rounds & intervals',
              desc: 'Saves a work / rest template with the activity',
              value: _intervals,
              onChanged: (v) => setState(() => _intervals = v),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Cadence, GPS and live heart-rate sensors are not available in this build.', style: SxText.bodySm.copyWith(color: c.textMuted)),
            ),
          ],
        ),
        if (_intervals)
          CardioFormLike(
            title: '03 / Round & interval template',
            children: [
              _Stepper(label: 'Round duration', sub: 'Active work cycle', text: Fmt.clock(_round), onMinus: () => setState(() => _round = (_round - 15).clamp(15, 3600)), onPlus: () => setState(() => _round = (_round + 15).clamp(15, 3600))),
              _Stepper(label: 'Rest interval', sub: 'Recovery between rounds', text: Fmt.clock(_rest), onMinus: () => setState(() => _rest = (_rest - 15).clamp(0, 3600)), onPlus: () => setState(() => _rest = (_rest + 15).clamp(0, 3600))),
              _Stepper(label: 'Total rounds', sub: 'Default session target', text: '$_rounds Rnds', onMinus: () => setState(() => _rounds = (_rounds - 1).clamp(1, 99)), onPlus: () => setState(() => _rounds = (_rounds + 1).clamp(1, 99))),
              SxInset(
                child: Row(children: [
                  Icon(Icons.timelapse, size: 18, color: c.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Calculated working time', style: SxText.bodyMd.copyWith(color: c.textHigh))),
                  Text(Fmt.clock(_workingSeconds), style: SxText.metricMd.copyWith(color: c.primary)),
                ]),
              ),
            ],
          ),
      ],
    );
  }
}

/// Section card with a mono "01 / Title" heading.
class CardioFormLike extends StatelessWidget {
  const CardioFormLike({super.key, required this.title, this.subtitle, required this.children});
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: SxText.bodySm.copyWith(color: c.textBody)),
        ],
        const SizedBox(height: SxSpace.md),
        ...children,
      ]),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.icon, required this.title, required this.desc, required this.value, required this.onChanged, this.locked = false});
  final IconData icon;
  final String title;
  final String desc;
  final bool value;
  final bool locked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SxInset(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Row(children: [
          Icon(icon, size: 22, color: c.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: SxText.labelUi.copyWith(color: c.textHigh, fontWeight: FontWeight.w600, fontSize: 14)),
              Text(desc, style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
          if (locked) Padding(padding: const EdgeInsets.only(right: 6), child: Text('LOCK', style: SxText.labelCaps.copyWith(color: c.textMuted, fontSize: 10))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c.onPrimary,
            activeTrackColor: c.primary,
            inactiveThumbColor: c.textBody,
            inactiveTrackColor: c.surface3,
          ),
        ]),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.sub, required this.text, required this.onMinus, required this.onPlus});
  final String label;
  final String sub;
  final String text;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SxInset(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: SxText.labelUi.copyWith(color: c.textHigh, fontWeight: FontWeight.w600, fontSize: 14)),
              Text(sub, style: SxText.bodySm.copyWith(color: c.textBody)),
            ]),
          ),
          SxIconButton(icon: Icons.remove, tooltip: 'Decrease $label', onPressed: onMinus),
          ConstrainedBox(constraints: const BoxConstraints(minWidth: 56), child: Text(text, textAlign: TextAlign.center, style: SxText.metricMd.copyWith(color: c.textHigh))),
          SxIconButton(icon: Icons.add, tooltip: 'Increase $label', onPressed: onPlus),
        ]),
      ),
    );
  }
}
