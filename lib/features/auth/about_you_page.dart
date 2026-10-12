import '../../core/utils/remote_ops.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

/// "About you": age, height and weight, asked once right after Create account and before schedule
/// setup. The profile stores centimetres and kilograms; the unit switch only changes how it is typed
/// (and sets [UserProfile.unit]). The account already exists, so Back is the same as Skip.
class AboutYouPage extends StatefulWidget {
  const AboutYouPage({super.key, this.afterSignup = true});

  /// When true, finishing or skipping continues to schedule setup (the sign-up flow).
  final bool afterSignup;

  @override
  State<AboutYouPage> createState() => _AboutYouPageState();
}

class _AboutYouPageState extends State<AboutYouPage> {
  final _age = TextEditingController();
  final _cm = TextEditingController();
  final _ft = TextEditingController();
  final _inch = TextEditingController();
  final _weight = TextEditingController();
  bool _imperial = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_age, _cm, _ft, _inch, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  // Errors show once the person has typed something; the button stays disabled until all are valid.
  String? _live(TextEditingController c, String? Function() validate) =>
      c.text.trim().isEmpty ? null : validate();

  String? get _ageErr => BodyMetrics.validateAge(_age.text);
  String? get _heightErr => _imperial
      ? BodyMetrics.validateHeightImperial(_ft.text, _inch.text)
      : BodyMetrics.validateHeight(_cm.text);
  String? get _weightErr =>
      BodyMetrics.validateWeight(_weight.text, lb: _imperial);
  bool get _valid =>
      _ageErr == null && _heightErr == null && _weightErr == null;

  void _setUnit(int i) {
    final imperial = i == 1;
    if (imperial == _imperial) return;
    // Carry valid entries across so nothing typed is lost.
    final cm = _imperial
        ? null
        : (BodyMetrics.validateHeight(_cm.text) == null
              ? BodyMetrics.parseNumber(_cm.text)
              : null);
    final ftIn =
        _imperial &&
            BodyMetrics.validateHeightImperial(_ft.text, _inch.text) == null
        ? BodyMetrics.cmFromFeetInches(
            BodyMetrics.parseAge(_ft.text)!,
            BodyMetrics.parseNumber(_inch.text) ?? 0,
          )
        : null;
    final w = BodyMetrics.validateWeight(_weight.text, lb: _imperial) == null
        ? BodyMetrics.parseNumber(_weight.text)
        : null;
    final kg = w == null ? null : (_imperial ? BodyMetrics.kgFromLb(w) : w);
    setState(() {
      _imperial = imperial;
      final heightCm = cm ?? ftIn;
      _cm.clear();
      _ft.clear();
      _inch.clear();
      if (heightCm != null) {
        if (imperial) {
          final fi = BodyMetrics.feetInchesFromCm(heightCm);
          _ft.text = '${fi.feet}';
          _inch.text = '${fi.inches}';
        } else {
          _cm.text = _trim(heightCm);
        }
      }
      _weight.clear();
      if (kg != null) {
        _weight.text = _trim(imperial ? BodyMetrics.lbFromKg(kg) : kg);
      }
    });
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

  Future<void> _continue() async {
    if (_busy || !_valid) return;
    setState(() => _busy = true);
    final app = context.app;
    final heightCm = _imperial
        ? BodyMetrics.cmFromFeetInches(
            BodyMetrics.parseAge(_ft.text)!,
            BodyMetrics.parseNumber(_inch.text) ?? 0,
          )
        : BodyMetrics.parseNumber(_cm.text)!;
    final w = BodyMetrics.parseNumber(_weight.text)!;
    final p = app.profile.profile;
    // Stay on this page (fields intact) unless the server confirmed the save.
    final ok = await runRemote(
      context,
      () => app.profile.update(
        p.copyWith(
          age: BodyMetrics.parseAge(_age.text),
          heightCm: heightCm,
          weightKg: _imperial ? BodyMetrics.kgFromLb(w) : w,
          unit: _imperial ? WeightUnit.lb : WeightUnit.kg,
        ),
      ),
      what: 'save your details',
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _busy = false);
      return;
    }
    _next();
  }

  void _next() {
    if (!mounted) return;
    if (widget.afterSignup) {
      AppNav.scheduleSetup(context, afterSignup: true);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  static final _numFormat = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
    LengthLimitingTextInputFormatter(7),
  ];
  static final _wholeFormat = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(3),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    const numberKeys = TextInputType.numberWithOptions(decimal: true);
    final items = <Widget>[
      Text('About you', style: SxText.headlineLg.copyWith(color: c.textHigh)),
      Text(
        'Used for body-weight stats and calorie estimates. It is saved to your account.',
        style: SxText.bodyLg.copyWith(color: c.textBody),
      ),
      SxSegmented(
        labels: const ['Metric (cm, kg)', 'Imperial (ft, in, lb)'],
        index: _imperial ? 1 : 0,
        onChanged: _setUnit,
      ),
      SxTextField(
        label: 'Age',
        controller: _age,
        icon: Icons.cake_outlined,
        hint: 'e.g. 28',
        suffixText: 'years',
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        inputFormatters: _wholeFormat,
        errorText: _live(_age, () => _ageErr),
        onChanged: (_) => setState(() {}),
      ),
      if (_imperial)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SxTextField(
                label: 'Height (ft)',
                controller: _ft,
                icon: Icons.height,
                hint: '5',
                suffixText: 'ft',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                inputFormatters: _wholeFormat,
                errorText: null,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SxTextField(
                label: 'Height (in)',
                controller: _inch,
                hint: '9',
                suffixText: 'in',
                keyboardType: numberKeys,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                inputFormatters: _numFormat,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        )
      else
        SxTextField(
          label: 'Height',
          controller: _cm,
          icon: Icons.height,
          hint: 'e.g. 175',
          suffixText: 'cm',
          keyboardType: numberKeys,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          inputFormatters: _numFormat,
          errorText: _live(_cm, () => _heightErr),
          onChanged: (_) => setState(() {}),
        ),
      if (_imperial &&
          (_ft.text.trim().isNotEmpty || _inch.text.trim().isNotEmpty) &&
          _heightErr != null)
        Semantics(
          liveRegion: true,
          child: Text(
            _heightErr!,
            style: SxText.bodySm.copyWith(color: c.danger),
          ),
        ),
      SxTextField(
        label: 'Weight',
        controller: _weight,
        icon: Icons.monitor_weight_outlined,
        hint: _imperial ? 'e.g. 160' : 'e.g. 72',
        suffixText: _imperial ? 'lb' : 'kg',
        keyboardType: numberKeys,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        inputFormatters: _numFormat,
        errorText: _live(_weight, () => _weightErr),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _continue(),
      ),
      SxButton(
        label: 'Continue',
        icon: Icons.arrow_forward,
        loading: _busy,
        onPressed: (_valid && !_busy) ? _continue : null,
      ),
      Center(
        child: Column(
          children: [
            TextButton(
              onPressed: _busy ? null : _next,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                'Skip for now',
                style: SxText.headlineSm.copyWith(color: c.primary),
              ),
            ),
            Text(
              'You can add this later in Profile.',
              textAlign: TextAlign.center,
              style: SxText.bodySm.copyWith(color: c.textMuted),
            ),
          ],
        ),
      ),
    ];
    return PopScope(
      canPop: false, // the account already exists: Back = Skip
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _next();
      },
      child: SxScaffold(
        topBar: SxTopBar(title: 'About you', onBack: _busy ? null : _next),
        animateIn: true,
        children: items,
      ),
    );
  }
}
