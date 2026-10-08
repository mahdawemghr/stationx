import 'package:flutter/material.dart';
import 'cardio_pace.dart';
import 'package:flutter/services.dart';

import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'cardio_manage_helpers.dart';

/// Editable cardio session state shared by Edit and Backdate. Fields shown are
/// driven by [CardioKind.fields]; pace/speed are always derived, never typed.
class CardioFormState extends ChangeNotifier {
  CardioFormState({required this.kind, required this.date, required this.kmUnit, CardioSession? from, this.custom}) {
    final s = from;
    _existingDistanceKm = s?.distanceKm;
    if (s != null) {
      final d = s.durationSeconds;
      hours.text = d ~/ 3600 == 0 ? '' : '${d ~/ 3600}';
      minutes.text = d == 0 ? '' : '${(d % 3600) ~/ 60}';
      seconds.text = d == 0 ? '' : '${d % 60}';
      if (s.distanceKm != null) distance.text = Fmt.number(kmUnit ? s.distanceKm! : s.distanceKm! / 1.609344, decimals: 2);
      if (s.speedKmh != null) speed.text = Fmt.number(s.speedKmh!, decimals: 1);
      if (s.inclinePct != null) incline.text = Fmt.number(s.inclinePct!, decimals: 1);
      if (s.resistance != null) resistance.text = '${s.resistance}';
      if (s.calories != null) calories.text = '${s.calories}';
      if (s.avgHeartRate != null) heartRate.text = '${s.avgHeartRate}';
      route.text = s.routeName;
      notes.text = s.notes;
      rpe = s.rpe;
    }
    for (final c in _all) {
      c.addListener(notifyListeners);
    }
  }

  CardioKind kind;

  /// The user's custom activity this session belongs to (null for built-in kinds).
  final CustomCardioActivity? custom;
  double? _existingDistanceKm;

  /// Input fields this session exposes; a custom session that already has a
  /// distance keeps the field so editing never hides and erases it.
  List<CardioField> get fields =>
      CardioFieldResolver.fieldsFor(kind, custom: custom, existingDistanceKm: _existingDistanceKm);
  bool get hasDistance => fields.contains(CardioField.distance);
  DateTime date;
  bool kmUnit;
  double? rpe;
  bool showErrors = false;

  final hours = TextEditingController();
  final minutes = TextEditingController();
  final seconds = TextEditingController();
  final distance = TextEditingController();
  final speed = TextEditingController();
  final incline = TextEditingController();
  final resistance = TextEditingController();
  final calories = TextEditingController();
  final heartRate = TextEditingController();
  final route = TextEditingController();
  final notes = TextEditingController();

  List<TextEditingController> get _all =>
      [hours, minutes, seconds, distance, speed, incline, resistance, calories, heartRate, route, notes];

  static double? _d(String t) => t.trim().isEmpty ? null : double.tryParse(t.trim().replaceAll(',', '.'));
  static int? _i(String t) => t.trim().isEmpty ? null : int.tryParse(t.trim());

  int get durationSeconds => (_i(hours.text) ?? 0) * 3600 + (_i(minutes.text) ?? 0) * 60 + (_i(seconds.text) ?? 0);

  /// Distance entered, converted to km.
  double? get distanceKm {
    final v = _d(distance.text);
    if (v == null || !hasDistance) return null;
    return kmUnit ? v : v * 1.609344;
  }

  double? get paceSecPerKm => CardioMetrics.paceSecPerKm(durationSeconds, distanceKm);
  double? get derivedSpeedKmh => CardioMetrics.speedKmh(durationSeconds, distanceKm);

  void setKind(CardioKind k) {
    kind = k;
    notifyListeners();
  }

  void setDate(DateTime d) {
    date = d;
    notifyListeners();
  }

  void setUnit(bool km) {
    if (km == kmUnit) return;
    final v = _d(distance.text);
    if (v != null) distance.text = Fmt.number(km ? v * 1.609344 : v / 1.609344, decimals: 2);
    kmUnit = km;
    notifyListeners();
  }

  void setRpe(double? v) {
    rpe = v;
    notifyListeners();
  }

  String? get durationError => showErrors && durationSeconds <= 0 ? 'Duration required' : null;

  String? get dateError => date.isAfter(DateTime.now()) ? 'Cannot be in the future' : null;

  bool validate() {
    showErrors = true;
    notifyListeners();
    return durationSeconds > 0 && dateError == null;
  }

  /// Builds the session. Optional fields not shown for [kind] are dropped.
  CardioSession build({required String id, SyncMeta? meta, String? customActivityId}) {
    final f = fields;
    final dist = distanceKm;
    final spd = f.contains(CardioField.speed) && kind == CardioKind.treadmill ? _d(speed.text) : null;
    return CardioSession(
      id: id,
      kind: kind,
      workoutDate: date,
      durationSeconds: durationSeconds,
      distanceKm: dist,
      speedKmh: spd,
      inclinePct: f.contains(CardioField.incline) ? _d(incline.text) : null,
      resistance: f.contains(CardioField.resistance) ? _i(resistance.text) : null,
      calories: _i(calories.text),
      avgHeartRate: _i(heartRate.text),
      rpe: rpe,
      routeName: route.text.trim(),
      notes: notes.text.trim(),
      customActivityId: customActivityId,
      meta: meta,
    );
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.removeListener(notifyListeners);
      c.dispose();
    }
    super.dispose();
  }
}

final _decimal = FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));
final _digits = FilteringTextInputFormatter.digitsOnly;

Future<DateTime?> pickCardioDate(BuildContext context, DateTime initial) async {
  final now = DateTime.now();
  final d = await showDatePicker(
    context: context,
    initialDate: initial.isAfter(now) ? now : initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(now.year, now.month, now.day),
  );
  if (d == null) return null;
  return DateTime(d.year, d.month, d.day, initial.hour, initial.minute);
}

Future<DateTime?> pickCardioTime(BuildContext context, DateTime initial) async {
  final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute));
  if (t == null) return null;
  return DateTime(initial.year, initial.month, initial.day, t.hour, t.minute);
}

/// Small caps card title used by the form sections.
class CardioFormCard extends StatelessWidget {
  const CardioFormCard({super.key, required this.title, this.icon, this.trailing, required this.children});
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[Icon(icon, size: 20, color: c.primary), const SizedBox(width: 8)],
          Expanded(child: Text(title, style: SxText.headlineSm.copyWith(color: c.textHigh), overflow: TextOverflow.ellipsis)),
          ?trailing,
        ]),
        const SizedBox(height: SxSpace.md),
        ...children,
      ]),
    );
  }
}

class CardioUnitToggle extends StatelessWidget {
  const CardioUnitToggle({super.key, required this.km, required this.onChanged});
  final bool km;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    Widget seg(String label, bool value) => SxPressable(
          onTap: () => onChanged(value),
          selected: km == value,
          semanticLabel: value ? 'Kilometers' : 'Miles',
          excludeChildSemantics: true,
          focusRadius: SxRadius.sm,
          child: AnimatedContainer(
            duration: SxMotion.of(context, SxMotion.micro),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: km == value ? c.primary : Colors.transparent, borderRadius: BorderRadius.circular(SxRadius.sm)),
            child: Text(label, style: SxText.labelCaps.copyWith(color: km == value ? c.onAccent : c.textBody, fontWeight: FontWeight.w700)),
          ),
        );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.base), border: Border.all(color: c.hairline)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg('KM', true), seg('MI', false)]),
    );
  }
}

/// Duration / distance / speed / incline / resistance + derived pace tile.
class CardioMetricsSection extends StatelessWidget {
  const CardioMetricsSection({super.key, required this.form, this.title = 'Core Metrics'});
  final CardioFormState form;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final units = CardioUnits(form.kmUnit);
    final f = form.fields;
    final err = form.durationError;
    return CardioFormCard(
      title: title,
      icon: Icons.speed,
      trailing: form.hasDistance ? CardioUnitToggle(km: form.kmUnit, onChanged: form.setUnit) : null,
      children: [
        Text('DURATION (HH : MM : SS)', style: SxText.labelCaps.copyWith(color: c.textBody)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _numBox('Hours', form.hours, _digits, maxLen: 2)),
          const SizedBox(width: 8),
          Expanded(child: _numBox('Min', form.minutes, _digits, maxLen: 2)),
          const SizedBox(width: 8),
          Expanded(child: _numBox('Sec', form.seconds, _digits, maxLen: 2)),
        ]),
        AnimatedSize(
          duration: SxMotion.of(context, SxMotion.short),
          alignment: Alignment.topLeft,
          child: err == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(err.toUpperCase(), style: SxText.labelXs.copyWith(color: c.danger)),
                ),
        ),
        if (form.hasDistance) ...[
          const SizedBox(height: SxSpace.md),
          SxTextField(
            label: 'Distance covered',
            controller: form.distance,
            mono: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimal],
            suffixText: units.distanceUnit.toUpperCase(),
            hint: '0.00',
          ),
        ],
        if (form.kind == CardioKind.treadmill && f.contains(CardioField.speed)) ...[
          const SizedBox(height: SxSpace.md),
          SxTextField(
            label: 'Belt speed',
            controller: form.speed,
            mono: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimal],
            suffixText: 'KM/H',
            hint: form.derivedSpeedKmh == null ? '0.0' : Fmt.number(form.derivedSpeedKmh!, decimals: 1),
          ),
        ],
        if (f.contains(CardioField.incline)) ...[
          const SizedBox(height: SxSpace.md),
          SxTextField(
            label: 'Incline',
            controller: form.incline,
            mono: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimal],
            suffixText: '%',
            hint: '0.0',
          ),
        ],
        if (f.contains(CardioField.resistance)) ...[
          const SizedBox(height: SxSpace.md),
          SxTextField(
            label: 'Resistance level',
            controller: form.resistance,
            mono: true,
            keyboardType: TextInputType.number,
            inputFormatters: [_digits],
            hint: '0',
          ),
        ],
        const SizedBox(height: SxSpace.md),
        _DerivedTile(form: form, units: units),
      ],
    );
  }

  Widget _numBox(String label, TextEditingController ctl, TextInputFormatter fmt, {int maxLen = 2}) =>
      SxTextField(label: label, controller: ctl, mono: true, textAlign: TextAlign.center, keyboardType: TextInputType.number, inputFormatters: [fmt, LengthLimitingTextInputFormatter(maxLen)], hint: '0');
}

class _DerivedTile extends StatelessWidget {
  const _DerivedTile({required this.form, required this.units});
  final CardioFormState form;
  final CardioUnits units;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final showsPace = CardioPace.has(form.kind);
    final showsSpeed = !showsPace && form.hasDistance;
    if (!showsPace && !showsSpeed) return const SizedBox.shrink();
    final label = showsPace ? 'Calculated avg pace' : 'Calculated avg speed';
    final value = showsPace ? CardioPace.text(form.kind, form.paceSecPerKm, miles: !units.km) : units.speedText(form.derivedSpeedKmh);
    final unit = showsPace ? CardioPace.unit(form.kind, miles: !units.km) : units.speedUnit;
    return SxInset(
      color: c.canvas,
      child: Row(children: [
        Icon(Icons.speed, color: c.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(label.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody), maxLines: 2, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        MetricValue(value, unit: unit, style: SxText.metricLg, color: c.primary),
      ]),
    );
  }
}

/// Calories, average HR and effort slider (all optional, manual).
class CardioBiometricsSection extends StatelessWidget {
  const CardioBiometricsSection({super.key, required this.form});
  final CardioFormState form;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final rpe = form.rpe;
    return CardioFormCard(
      title: 'Biometrics & Effort',
      icon: Icons.monitor_heart_outlined,
      trailing: StatusPill('Optional', color: context.sx.textBody),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: SxTextField(label: 'Energy burn', controller: form.calories, mono: true, keyboardType: TextInputType.number, inputFormatters: [_digits], suffixText: 'KCAL', hint: '—'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SxTextField(label: 'Avg heart rate', controller: form.heartRate, mono: true, keyboardType: TextInputType.number, inputFormatters: [_digits], suffixText: 'BPM', hint: '—'),
          ),
        ]),
        const SizedBox(height: SxSpace.md),
        Row(children: [
          Expanded(child: Text('PERCEIVED EFFORT (RPE)', style: SxText.labelCaps.copyWith(color: c.textBody))),
          Text(rpe == null ? 'Not set' : Fmt.number(rpe), style: SxText.metricMd.copyWith(color: rpe == null ? c.textMuted : c.primary)),
          if (rpe != null) Text(' / 10', style: SxText.bodySm.copyWith(color: c.textBody)),
          if (rpe != null)
            SxIconButton(icon: Icons.close, tooltip: 'Clear effort', filled: false, iconColor: c.textMuted, onPressed: () => form.setRpe(null)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: c.primary,
            inactiveTrackColor: c.surface3,
            thumbColor: c.primary,
            overlayColor: c.primary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(value: rpe ?? 1, min: 1, max: 10, divisions: 18, label: rpe == null ? null : Fmt.number(rpe), onChanged: form.setRpe),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('1 Recovery', style: SxText.bodySm.copyWith(color: c.textMuted)),
          Text('10 Maximal', style: SxText.bodySm.copyWith(color: c.textMuted)),
        ]),
      ],
    );
  }
}

/// Route name (kinds that travel a course) + notes.
class CardioContextSection extends StatelessWidget {
  const CardioContextSection({super.key, required this.form});
  final CardioFormState form;

  @override
  Widget build(BuildContext context) {
    final showRoute = form.fields.contains(CardioField.pace) || form.kind == CardioKind.cycling;
    return CardioFormCard(
      title: 'Context & Notes',
      icon: Icons.explore_outlined,
      children: [
        if (showRoute) ...[
          SxTextField(label: 'Route / waypoint name', controller: form.route, icon: Icons.place_outlined, hint: 'e.g. Riverside loop'),
          const SizedBox(height: SxSpace.md),
        ],
        SxTextField(label: 'Session notes', controller: form.notes, maxLines: 3, hint: 'How did it feel?'),
      ],
    );
  }
}

/// Tappable date / time cards.
class CardioDateTimeRow extends StatelessWidget {
  const CardioDateTimeRow({super.key, required this.form, this.dateLabel = 'Workout date', this.footer});
  final CardioFormState form;
  final String dateLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final d = form.date;
    final err = form.dateError;
    Widget tile(String label, String value, String sub, IconData icon, VoidCallback onTap) => SxCard(
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(label.toUpperCase(), style: SxText.labelCaps.copyWith(color: c.textBody))),
              Icon(icon, size: 18, color: c.primary),
            ]),
            const SizedBox(height: 8),
            Text(value, style: SxText.headlineMd.copyWith(color: c.textHigh), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(sub, style: SxText.bodySm.copyWith(color: c.textBody), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        );
    final dateTile = tile(dateLabel, Fmt.dateMedium(d), Fmt.dayName(d.weekday), Icons.calendar_today_outlined, () async {
      final p = await pickCardioDate(context, form.date);
      if (p != null) form.setDate(p);
    });
    final timeTile = tile('Start time', Fmt.time(d), err ?? 'Tap to change', Icons.schedule, () async {
      final p = await pickCardioTime(context, form.date);
      if (p != null) form.setDate(p);
    });
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(
        builder: (context, cons) => cons.maxWidth >= 340 && MediaQuery.textScalerOf(context).scale(1) <= 1.15
            ? IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: dateTile),
                  const SizedBox(width: 12),
                  Expanded(child: timeTile),
                ]),
              )
            : Column(children: [dateTile, const SizedBox(height: 12), timeTile]),
      ),
      if (err != null)
        Padding(padding: const EdgeInsets.only(top: 6), child: Text(err.toUpperCase(), style: SxText.labelXs.copyWith(color: c.danger))),
      if (footer != null) Padding(padding: const EdgeInsets.only(top: 8), child: footer),
    ]);
  }
}
